"""Export local review pages with installed Chrome; ephemeral verified temp profiles."""
from pathlib import Path
import subprocess
import tempfile
import shutil
import time
import json

ROOT=Path(__file__).resolve().parent
BROWSER=Path('C:/Program Files/Google/Chrome/Application/chrome.exe')
BOARDS=[('comparison',1560,1150),('directions',1050,1150),('storyboard',1560,850),('heading',1560,700)]

def main():
    results=[]
    for name,width,height in BOARDS:
        profile=Path(tempfile.mkdtemp(prefix='urbes-composition-v2-')).resolve()
        temp_root=Path(tempfile.gettempdir()).resolve()
        assert profile.parent==temp_root and profile.name.startswith('urbes-composition-v2-')
        dest=ROOT/f'{name}.png'
        args=[str(BROWSER),'--headless','--no-sandbox','--disable-gpu','--no-first-run','--no-default-browser-check','--disable-extensions','--disable-background-networking','--disable-component-update','--disable-sync','--force-device-scale-factor=1',f'--user-data-dir={profile}','--hide-scrollbars','--virtual-time-budget=1500',f'--window-size={width},{height}',f'--screenshot={dest}',(ROOT/f'{name}.html').as_uri()]
        print(f'Rendering {name}...',flush=True)
        try:
            result=subprocess.run(args,capture_output=True,timeout=35)
            for _ in range(30):
                if dest.exists(): break
                time.sleep(.1)
            assert dest.exists(),f'No render: {name}; returncode={result.returncode}'
            results.append({'board':name,'width':width,'height':height,'bytes':dest.stat().st_size,'returncode':result.returncode})
            print(f'Exported {name}: {dest.stat().st_size} bytes',flush=True)
        finally:
            # Only this exact newly-created temp profile can be removed.
            if profile.parent!=temp_root or not profile.name.startswith('urbes-composition-v2-'):
                raise ValueError('Unexpected cleanup target')
            try: shutil.rmtree(profile)
            except OSError: print('Temporary profile cleanup incomplete; no project cache created.',flush=True)
    (ROOT/'render-validation.json').write_text(json.dumps(results,indent=2),encoding='utf-8')

if __name__=='__main__': main()
