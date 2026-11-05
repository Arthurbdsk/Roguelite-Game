"""Build/run windowed release stress: 420 enemies, 320 arrows, 120 pools, four builds."""
from pathlib import Path
import argparse, shutil, subprocess
import benchmark14
ROOT=Path(__file__).resolve().parents[1]
GODOT=Path.home()/'Downloads/Godot_v4.7.2-stable_win64_console.exe'
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--build-only',action='store_true')
parser.add_argument('--run-only',action='store_true')
args=parser.parse_args()
if not args.run_only:
    for tag,source in [('before',ROOT/'build/baseline14-source'),('after',ROOT)]:
        dest=ROOT/f'build/stress14-source-{tag}'
        dest.mkdir(parents=True,exist_ok=True)
        for directory in ['assets','scripts','data','scenes']:
            shutil.copytree(source/directory,dest/directory,dirs_exist_ok=True)
        for name in ['project.godot','export_presets.cfg']:
            shutil.copy2(source/name,dest/name)
        preset=dest/'export_presets.cfg'
        preset.write_text(preset.read_text(encoding='utf8').replace('res://tools/.cache/windows_release_x86_64.exe',str(ROOT/'tools/.cache/windows_release_x86_64.exe').replace('\\','/')),encoding='utf8')
        script=(ROOT/'scripts/diagnostics/benchmark14.gd').read_text(encoding='utf8')
        script=script.replace('["initial","four_builds","boss_necro","king_225","siege","infinite30"]','["stress420"]')
        script=script.replace('scenario>0','true').replace('(12 if scenario==0 else 225)','420').replace('"infinite30"','"stress420"')
        script=script.replace(' age=0;samples.clear()', ' if g.enemies.size()!=420:push_error("Stress fixture did not create all 420 enemies");get_tree().quit(2);return\n age=0;samples.clear()')
        script=script.replace(' g.perf_us.clear()', ''' for actor in g.coop.actors.values():
  for pool in actor.weapon_system.ground.pools:pool.duration=100
 for i in maxi(0,320-g.enemy_projectiles.arrows.size()):g.enemy_projectiles.fire(Vector2(900,630)+Vector2.from_angle(i*TAU/320)*180,Vector2.from_angle(i*TAU/320+PI),g.enemy_data.skeleton_archer)
 g.perf_us.clear()''')
        # Keep the fixture's exact population; the ordinary director is benchmarked separately.
        script=script.replace('if scenarios[scenario]=="stress420":g.director.phase="active";g.director.debt=60','if scenarios[scenario]=="stress420":g.director.phase="complete"')
        (dest/'scripts/diagnostics').mkdir(exist_ok=True)
        (dest/'scripts/diagnostics/benchmark14.gd').write_text(script,encoding='utf8')
        (dest/'network.cfg').write_text('[relay]\nurl=""\n',encoding='utf8')
        with (ROOT/f'test_output/stress14-build-{tag}.log').open('w',encoding='utf8') as log:
            subprocess.run([str(GODOT),'--headless','--editor','--path',str(dest),'--import','--quit'],check=True,stdout=log,stderr=log)
            subprocess.run([str(GODOT),'--headless','--path',str(dest),'--export-release','Windows Desktop',str(ROOT/f'build/stress14-{tag}.exe')],check=True,stdout=log,stderr=log)
        print('Built stress',tag,flush=True)
if not args.build_only:
    benchmark14.run(ROOT/'build/stress14-before.exe','stress_before')
    benchmark14.run(ROOT/'build/stress14-after.exe','stress_after')
