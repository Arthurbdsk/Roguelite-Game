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
parser.add_argument('--suite', choices=['hordes_gold', 'skills_bosses'], default='skills_bosses')
args = parser.parse_args()
target = root / 'build' / 'Brasafria-0.3.0.exe'
log = root / 'test_output' / f'export_{args.suite}.log'
godot = Path.home() / 'Downloads' / 'Godot_v4.7.2-stable_win64_console.exe'
result = subprocess.run([
    str(godot), '--headless', '--main-pack', str(target), '--script', str(root / 'tests' / f'{args.suite}.gd'),
    '--log-file', str(log), '--', '--self-test',
], cwd=target.parent, capture_output=True, text=True, timeout=90)
output = result.stdout + result.stderr
if log.exists():
    output += log.read_text(encoding='utf-8')
print(output[-4000:])
marker = 'SKILLS_BOSSES_PASS' if args.suite == 'skills_bosses' else 'HORDES_GOLD_PASS'
if result.returncode or marker not in output or 'ERROR:' in output or 'FAIL:' in output:
    sys.exit(result.returncode or 1)
print(f'PACKED_GAME_VERIFIED: embedded PCK, matching editor runtime, {args.suite}, isolated saves')
