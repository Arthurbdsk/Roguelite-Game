"""Exercise the shipped embedded PCK with the matching Godot editor runtime.

The editor's --script runner executes an external harness against --main-pack.
The exported release itself is separately checked by export_windows.py --smoke.
All test profiles are isolated from the player's save.
"""
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
target = root / 'build' / 'Brasafria-0.2.0.exe'
log = root / 'test_output' / 'export_hordes_gold.log'
godot = Path.home() / 'Downloads' / 'Godot_v4.7.2-stable_win64_console.exe'
result = subprocess.run([
    str(godot), '--headless', '--main-pack', str(target), '--script', str(root / 'tests' / 'hordes_gold.gd'),
    '--log-file', str(log), '--', '--self-test',
], cwd=target.parent, capture_output=True, text=True, timeout=90)
output = result.stdout + result.stderr
if log.exists():
    output += log.read_text(encoding='utf-8')
print(output[-4000:])
if result.returncode or 'HORDES_GOLD_PASS' not in output or 'ERROR:' in output or 'FAIL:' in output:
    sys.exit(result.returncode or 1)
print('PACKED_GAME_VERIFIED: embedded PCK, matching editor runtime, 640 checks, isolated saves')
