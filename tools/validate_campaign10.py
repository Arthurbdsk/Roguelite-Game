"""Current campaign regressions. Each process uses an isolated test profile."""
from pathlib import Path
import subprocess
import sys
root=Path(__file__).resolve().parents[1]
godot=Path.home()/'Downloads/Godot_v4.7.2-stable_win64.exe'
suites=sys.argv[1:] or ['idle_font10','campaign10','horror10','guardian10','true10','ice10','explosion10','hazards10','two_phase_boss','boss_patterns','animation8','progression8','limits7','new_weapon7','permanent_data9','permanent_effects9','permanent_coop9','network_foundation','network_backpressure','devourer','slimes','lodo','holy_water','lightning','clock']
failed=[]
for suite in suites:
 try:
  r=subprocess.run([str(godot),*([] if suite in ['horror10','guardian10','true10','ice10','explosion10'] else ['--headless']),'--path',str(root),'--script',f'res://tests/{suite}.gd','--log-file',str(root/'test_output'/f'10-regression-{suite}.log'),'--','--self-test'],cwd=root,capture_output=True,text=True,encoding='utf-8',timeout=80)
  out=r.stdout+r.stderr
  lines=[s for s in out.splitlines() if 'PASS' in s or 'FAIL' in s or 'ERROR:' in s]
  print(suite+': '+(' | '.join(lines)),flush=True)
  if r.returncode or 'ERROR:' in out or 'FAIL' in out or 'PASS' not in out:failed.append(suite)
 except subprocess.TimeoutExpired:failed.append(suite);print(suite+': TIMEOUT',flush=True)
print('CAMPAIGN_REGRESSION_PASS' if not failed else 'CAMPAIGN_REGRESSION_FAIL '+str(failed),flush=True)
sys.exit(bool(failed))
