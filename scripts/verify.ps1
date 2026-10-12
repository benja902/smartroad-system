param(
  [ValidateSet('bridge', 'flutter', 'rules', 'all')]
  [string]$Component = 'bridge',
  [string[]]$TestPath = @(),
  [switch]$Emulator
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$config = Join-Path $root 'firebase.emulator.json'
$logDir = Join-Path ([IO.Path]::GetTempPath()) 'smartroad-verify'
[IO.Directory]::CreateDirectory($logDir) | Out-Null
$results = [System.Collections.Generic.List[object]]::new()

if ($Component -eq 'all' -and ($TestPath.Count -gt 0 -or $Emulator)) {
  throw '-TestPath y -Emulator no se combinan con -Component all.'
}
if ($Component -eq 'rules' -and $Emulator) {
  throw 'Las pruebas de reglas siempre utilizan Database Emulator; omite -Emulator.'
}

function Confirm-TestPaths([string]$folder, [string]$extension) {
  $prefix = (Join-Path $root $folder).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
  foreach ($path in $TestPath) {
    $full = (Resolve-Path -LiteralPath (Join-Path $root $path)).Path
    if (-not $full.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -or
        -not $full.EndsWith($extension, [StringComparison]::OrdinalIgnoreCase) -or
        $path -match '[\s"''`;&|<>]') {
      throw "Ruta de prueba fuera de $folder o no admitida: $path"
    }
  }
}

if ($TestPath.Count -gt 0) {
  switch ($Component) {
    'bridge' { Confirm-TestPaths 'bridge/test' '.test.js' }
    'flutter' { Confirm-TestPaths 'test' '.dart' }
    'rules' { Confirm-TestPaths 'test/rtdb_rules' '.test.mjs' }
  }
}

function Invoke-Check([string]$name, [string]$exe, [string[]]$arguments) {
  $log = Join-Path $logDir ("{0}-{1:yyyyMMdd-HHmmss-fff}.log" -f $name, (Get-Date))
  $caseCount = 0
  $lastProgress = [DateTime]::UtcNow
  Write-Host "Iniciando $name ..."
  try {
    & $exe @arguments 2>&1 | ForEach-Object {
      $line = [string]$_
      [IO.File]::AppendAllText($log, $line + [Environment]::NewLine)
      if ($line -match '^(✔|00:\d\d \+\d+)' ) {
        $caseCount++
        if ($caseCount % 10 -eq 0) { Write-Host "${name}: $caseCount resultados" }
      } elseif ($line -match '^(✖|FAIL|Error:|error -|\s*ℹ (tests|pass|fail|skipped)|.*All tests passed|.*No issues found)') {
        Write-Host "${name}: $line"
      }
      if (([DateTime]::UtcNow - $lastProgress).TotalSeconds -ge 30) {
        Write-Host "${name}: en curso ($caseCount resultados); detalle: $log"
        $lastProgress = [DateTime]::UtcNow
      }
    }
    $code = $LASTEXITCODE
  } catch {
    [IO.File]::AppendAllText($log, $_.ToString() + [Environment]::NewLine)
    $code = 1
  }
  if ($null -eq $code) { $code = 1 }
  $state = if ($code -eq 0) { 'OK' } else { 'FALLÓ' }
  Write-Host "${name}: $state (código $code); detalle: $log"
  $results.Add([pscustomobject]@{ Name = $name; ExitCode = [int]$code; Log = $log })
}

function Use-LocalJava {
  $javaLine = (& java -version 2>&1 | Select-Object -First 1).ToString()
  if ($javaLine -match 'version "(\d+)' -and [int]$Matches[1] -ge 21) { return }
  $jbr = 'C:\Program Files\Android\Android Studio\jbr'
  if (-not (Test-Path -LiteralPath (Join-Path $jbr 'bin\java.exe'))) {
    throw 'Database Emulator requiere Java 21 o superior (JAVA_HOME o Android Studio JBR).'
  }
  $env:JAVA_HOME = $jbr
  $env:PATH = (Join-Path $jbr 'bin') + [IO.Path]::PathSeparator + $env:PATH
}

function Invoke-DatabaseCheck([string]$name, [string]$project, [string]$command) {
  Use-LocalJava
  $env:FIREBASE_CLI_DISABLE_UPDATE_CHECK = 'true'
  $env:DEBUG = ''
  # Keep CLI state separate from any personal Firebase login.
  $env:XDG_CONFIG_HOME = Join-Path $logDir 'firebase-cli-config'
  [IO.Directory]::CreateDirectory($env:XDG_CONFIG_HOME) | Out-Null
  Invoke-Check $name 'firebase.cmd' @(
    'emulators:exec', '--non-interactive', '--only', 'database',
    '--project', $project, '--config', $config, $command
  )
}

function Invoke-Bridge([bool]$withEmulator) {
  if ($TestPath.Count -eq 0) {
    $command = 'npm --prefix bridge test'
    if (-not $withEmulator) { Invoke-Check 'bridge' 'npm.cmd' @('--prefix', 'bridge', 'test'); return }
  } else {
    $command = 'node --test --test-reporter=spec --test-concurrency=1 ' + ($TestPath -join ' ')
    if (-not $withEmulator) {
      Invoke-Check 'bridge-dirigido' 'node.exe' (@('--test', '--test-reporter=spec', '--test-concurrency=1') + $TestPath)
      return
    }
  }
  Invoke-DatabaseCheck 'bridge-emulator' 'demo-smartroad-bridge' $command
}

function Invoke-Flutter {
  $paths = if ($TestPath.Count -gt 0) { $TestPath } else { @('test') }
  Invoke-Check 'flutter' 'flutter.bat' (@('test', '--no-pub', '-r', 'expanded') + $paths)
}

function Invoke-Rules {
  $command = if ($TestPath.Count -eq 0) {
    'npm --prefix test/rtdb_rules test'
  } else {
    'node --test --test-reporter=spec --test-concurrency=1 --test-timeout=30000 ' + ($TestPath -join ' ')
  }
  Invoke-DatabaseCheck 'rules-emulator' 'demo-smartroad-rules' $command
}

Push-Location $root
try {
  switch ($Component) {
    'bridge' { Invoke-Bridge ([bool]$Emulator) }
    'flutter' { Invoke-Flutter }
    'rules' { Invoke-Rules }
    'all' {
      Invoke-Bridge $true
      Invoke-Flutter
      Invoke-Rules
      Invoke-Check 'flutter-analyze' 'flutter.bat' @('analyze', '--no-pub', 'lib', 'test')
    }
  }
} finally {
  Pop-Location
}

Write-Host 'Resumen:'
foreach ($result in $results) {
  $state = if ($result.ExitCode -eq 0) { 'OK' } else { 'FALLÓ' }
  Write-Host "  $($result.Name): $state ($($result.ExitCode))"
}
if (@($results | Where-Object ExitCode -ne 0).Count -gt 0) { exit 1 }
exit 0
