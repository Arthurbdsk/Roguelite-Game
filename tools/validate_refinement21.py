"""PC-only validation of the 0.21 refinements. Never touches Android."""
from pathlib import Path
import subprocess,os,json,sys
r=Path(__file__).resolve().parents[1]; out=r/'build/refinement21';out.mkdir(parents=True,exist_ok=True)
godot=Path.home()/'Downloads/Godot_v4.7.2-stable_win64_console.exe'
tests=sys.argv[1:] or ['refinement21','rune21','garlic21','variants21','presentation21','adjustments18','weapons16','limits7','permanent_data9','permanent_effects9','network_foundation','network_backpressure','spatial14','devourer','slimes','holy_water','water12','soldier20','orc20','death21','visual19']
results=[]
for name in tests:
 cmd=[str(godot),*([] if name in ['soldier20','orc20','death21','visual19'] else ['--headless']),'--path',str(r),'--quit-after','3000','--script',f'tests/{name}.gd','--','--self-test','--profile-slot=refinement21_'+name]
 try:
  p=subprocess.run(cmd,cwd=r,env={**os.environ,'HORDAS_CAPTURE_DIR':str(out)},capture_output=True,text=True,encoding='utf8',errors='replace',timeout=75)
  log=p.stdout+p.stderr;(out/(name+'.log')).write_text(log,encoding='utf8');ok=p.returncode==0 and '_PASS' in log and not any(x in log for x in ['SCRIPT ERROR','ERROR:','FAIL'])
 except subprocess.TimeoutExpired as e:
  ok=False;log='Timed out\n'+str(e.stdout or '')+str(e.stderr or '');(out/(name+'.log')).write_text(log,encoding='utf8')
 results.append({'test':name,'passed':ok});print(name,'PASS' if ok else 'FAIL',flush=True)
 if not ok:print(log[-2000:],flush=True)
(out/'results.json').write_text(json.dumps(results,indent=2),encoding='utf8')
raise SystemExit(0 if all(x['passed'] for x in results) else 1)
