"""Explicit Android preview validation. Does not run in the PC pipeline."""
from pathlib import Path
import argparse,subprocess,os,json
root=Path(__file__).resolve().parents[2];out=root/'build/update25';out.mkdir(parents=True,exist_ok=True)
parser=argparse.ArgumentParser();parser.add_argument('--android-request',action='store_true');args=parser.parse_args();assert args.android_request
assert subprocess.check_output(['git','branch','--show-current'],cwd=root,text=True).strip()=='codex/android-mobile'
godot=Path.home()/'Downloads/Godot_v4.7.2-stable_win64_console.exe'
results=[]
for name in ['mobile_touch','mobile_keyboard','mobile_lifecycle','mobile_ui','bestiary_data25','multiplayer25','network_foundation','permanent_coop9']:
    p=subprocess.run([str(godot),'--path',str(root),'--quit-after','3000','--script',f'tests/{name}.gd','--','--self-test','--mobile-preview',f'--profile-slot=mobile25_{name}'],env={**os.environ,'HORDAS_CAPTURE_DIR':str(out)},cwd=root,capture_output=True,text=True,encoding='utf8',errors='replace',timeout=80)
    log=p.stdout+p.stderr;(out/(name+'.log')).write_text(log,encoding='utf8')
    ok=p.returncode==0 and '_PASS' in log and not any(s in log for s in ['SCRIPT ERROR','ERROR:','FAIL'])
    results.append({'test':name,'passed':ok});print(name,'PASS' if ok else 'FAIL',flush=True)
    if not ok:print(log[-4000:],flush=True);break
(out/'preview-validation.json').write_text(json.dumps(results,indent=2))
raise SystemExit(0 if all(x['passed'] for x in results) else 1)
