"""Rebuild 0.13.0 with the same benchmark/instrumentation, without optimizations."""
from pathlib import Path
import io, subprocess, zipfile
ROOT=Path(__file__).resolve().parents[1]
DEST=ROOT/'build/baseline14-source'
GODOT=Path.home()/'Downloads/Godot_v4.7.2-stable_win64_console.exe'
COMMIT='ce9e026'
DEST.mkdir(parents=True,exist_ok=True)
archive=subprocess.check_output(['git','archive','--format=zip',COMMIT],cwd=ROOT)
zipfile.ZipFile(io.BytesIO(archive)).extractall(DEST)
subprocess.run(['git','apply','--directory=build/baseline14-source','tools/baseline14.patch'],cwd=ROOT,check=True)
(DEST/'scripts/diagnostics').mkdir(exist_ok=True)
(DEST/'scripts/diagnostics/benchmark14.gd').write_bytes((ROOT/'scripts/diagnostics/benchmark14.gd').read_bytes())
subprocess.run(['python','tools/export_windows.py','--template-only'],cwd=ROOT,check=True)
preset=DEST/'export_presets.cfg'
preset.write_text(preset.read_text(encoding='utf8').replace('res://tools/.cache/windows_release_x86_64.exe',str(ROOT/'tools/.cache/windows_release_x86_64.exe').replace('\\','/')),encoding='utf8')
(DEST/'network.cfg').write_text('[relay]\nurl=""\n',encoding='utf8')
subprocess.run([str(GODOT),'--headless','--editor','--path',str(DEST),'--import','--quit'],check=True)
subprocess.run([str(GODOT),'--headless','--path',str(DEST),'--export-release','Windows Desktop',str(ROOT/'build/baseline14.exe')],check=True)
print('Baseline: commit',COMMIT,'plus measurement-only tools/baseline14.patch')
