"""Sequential PC-only validation. Isolated profiles; no Android operations."""
from pathlib import Path
import json, os, subprocess, sys
root = Path(__file__).resolve().parents[1]
out = root / 'build/bestiary25'
out.mkdir(parents=True, exist_ok=True)
godot = Path.home() / 'Downloads/Godot_v4.7.2-stable_win64_console.exe'
ordered = ['design25', 'bestiary_data25', 'bestiary_ui25', 'multiplayer25', 'frequency24', 'projectiles24', 'arrow_render24', 'wand24', 'axe24', 'scale24', 'health_fire24', 'art24']
regressions = ['refinement21', 'rune21', 'garlic21', 'variants21', 'presentation21', 'adjustments18', 'weapons16', 'limits7', 'permanent_data9', 'permanent_effects9', 'permanent_coop9', 'network_foundation', 'network_backpressure', 'spatial14', 'devourer', 'slimes', 'holy_water', 'water12', 'soldier20', 'orc20', 'death22', 'art22', 'special_enemies', 'body_collision13', 'events13', 'campaign13', 'two_phase_boss', 'coop_bosses']
rendered = {'design25', 'bestiary_ui25', 'arrow_render24', 'scale24', 'art24', 'soldier20', 'orc20', 'death22', 'art22'}
results = []
for name in sys.argv[1:] or ordered + regressions:
    command = [str(godot), *([] if name in rendered else ['--headless']), '--path', str(root), '--quit-after', '3000', '--script', f'tests/{name}.gd', '--', '--self-test', f'--profile-slot=audit24_{name}']
    try:
        p = subprocess.run(command, cwd=root, env={**os.environ, 'HORDAS_CAPTURE_DIR': str(out)}, capture_output=True, text=True, encoding='utf8', errors='replace', timeout=75)
        log = p.stdout + p.stderr
        ok = p.returncode == 0 and '_PASS' in log and not any(s in log for s in ['SCRIPT ERROR', 'ERROR:', 'FAIL'])
    except subprocess.TimeoutExpired:
        log, ok = 'TIMEOUT', False
    (out / (name + '.log')).write_text(log, encoding='utf8')
    results.append({'test': name, 'passed': ok, 'evidence': [line for line in log.splitlines() if '_PASS' in line or 'FAIL' in line]})
    print(name, 'PASS' if ok else 'FAIL', flush=True)
    if not ok:
        print(log[-2500:], flush=True)
        break
(out / 'validation.json').write_text(json.dumps(results, indent=2), encoding='utf8')
raise SystemExit(0 if results and all(r['passed'] for r in results) else 1)
