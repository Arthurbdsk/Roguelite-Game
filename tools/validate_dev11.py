from pathlib import Path
import subprocess,sys
packed=next((a.split("=",1)[1] for a in sys.argv[1:] if a.startswith("--packed=")),None)
requested=[a for a in sys.argv[1:] if not a.startswith("--packed=")]
root=Path(__file__).resolve().parents[1]
godot=Path.home()/'Downloads/Godot_v4.7.2-stable_win64.exe'
failed=[]
for suite in requested or ['dev_sandbox11','dev_encounters13','dev_attacks13','dev_panel11','dev_survival13']:
 try:
  r=subprocess.run([str(godot),*([] if suite in ['dev_panel11','render_balance12','fields12','render_patterns12','load_balance12','render_survival13','load_survival13'] else ['--headless']),*(['--main-pack',str(Path(packed).resolve())] if packed else ['--path',str(root)]),'--script',str(root/'tests'/f'{suite}.gd'),'--log-file',str(root/'test_output'/f'11-{suite}.log'),'--','--self-test'],capture_output=True,text=True,encoding='utf-8',timeout=45,cwd=Path(packed).resolve().parent if packed else root)
  out=r.stdout+r.stderr
  print(out[-6000:],flush=True)
  if r.returncode or 'ERROR:' in out or 'FAIL' in out or 'PASS' not in out:failed.append(suite)
 except subprocess.TimeoutExpired:failed.append(suite);print(suite+' TIMEOUT',flush=True)
print('DEV11_VALIDATION_PASS' if not failed else str(failed),flush=True)
sys.exit(bool(failed))
