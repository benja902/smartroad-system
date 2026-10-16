from pathlib import Path
import subprocess,tempfile,shutil
ROOT=Path(__file__).resolve().parent
profile=Path(tempfile.mkdtemp(prefix='urbes-motion-gate-')).resolve()
temp_root=Path(tempfile.gettempdir()).resolve()
assert profile.parent==temp_root and profile.name.startswith('urbes-motion-gate-')
try:
    print('Rendering vehicle turn gate...',flush=True)
    result=subprocess.run(['C:/Program Files/Google/Chrome/Application/chrome.exe','--headless','--no-sandbox','--disable-gpu','--disable-background-networking','--disable-extensions','--no-first-run','--no-default-browser-check',f'--user-data-dir={profile}','--virtual-time-budget=1500','--window-size=1560,1430','--hide-scrollbars',f'--screenshot={ROOT / "turn-contact.png"}',(ROOT/'index.html').as_uri()+'?film=1'],capture_output=True,timeout=35)
    assert (ROOT/'turn-contact.png').exists(),result.stderr[-500:]
    print('Vehicle contact sheet exported.',flush=True)
finally:
    assert profile.parent==temp_root and profile.name.startswith('urbes-motion-gate-')
    shutil.rmtree(profile)
