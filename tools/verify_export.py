"""Exercise the shipped embedded PCK with the matching Godot editor runtime.

The editor's --script runner executes an external harness against --main-pack.
The exported release itself is separately checked by export_windows.py --smoke.
All test profiles are isolated from the player's save.
"""
from pathlib import Path
import argparse
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
markers = {name: name.upper() + '_PASS' for name in ['hordes_gold', 'skills_bosses', 'network_foundation', 'network_backpressure', 'coop_bosses', 'special_enemies', 'lightning', 'clock', 'crown', 'two_phase_boss', 'boss_patterns', 'devourer', 'slimes', 'lodo', 'holy_water', 'difficulty_v2', 'progression8', 'limits7', 'permanent_data9', 'permanent_effects9', 'permanent_coop9', 'idle_font10', 'campaign10', 'guardian10', 'horror10', 'true10', 'explosion10', 'ice10']}
parser.add_argument('--suite', choices=list(markers), default='campaign10')
parser.add_argument('--target', type=Path, default=root / 'build' / 'Hordas-0.15.0' / 'Hordas-0.15.0.exe')
args = parser.parse_args()
target = args.target.resolve()
log = root / 'test_output' / f'export_{args.suite}.log'
godot = Path.home() / 'Downloads' / 'Godot_v4.7.2-stable_win64_console.exe'
result = subprocess.run([
    str(godot), *([] if args.suite in ['guardian10','horror10','true10','explosion10','ice10'] else ['--headless']), '--main-pack', str(target), '--script', str(root / 'tests' / f'{args.suite}.gd'),
    '--log-file', str(log), '--', '--self-test',
], cwd=target.parent, capture_output=True, text=True, timeout=90)
output = result.stdout + result.stderr
if log.exists():
    output += log.read_text(encoding='utf-8')
print(output[-4000:])
marker = {'slimes':'SLIME_PASS','lodo':'LODO_PASS','holy_water':'WATER_PASS','difficulty_v2':'DIFFICULTY_PASS'}.get(args.suite, markers[args.suite])
if result.returncode or marker not in output or 'ERROR:' in output or 'FAIL:' in output:
    sys.exit(result.returncode or 1)
print(f'PACKED_GAME_VERIFIED: embedded PCK, matching editor runtime, {args.suite}, isolated saves')
