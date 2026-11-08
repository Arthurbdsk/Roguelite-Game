"""Manual Android export. Never called by PC build, test or release scripts."""
from pathlib import Path
import argparse, hashlib, json, os, subprocess, sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from gameplay_manifest import check
ROOT=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--android-request',action='store_true',help='Explicit Android work, required')
parser.add_argument('--qa',action='store_true',help='Isolated QA package, never the public delivery')
args=parser.parse_args()
if not args.android_request:raise SystemExit('Android is frozen by default. An explicit Android request and --android-request are required.')
branch=subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip()
if branch!='codex/android-mobile':raise SystemExit('Use the isolated codex/android-mobile worktree.')
check(ROOT)
private=Path.home()/'.android/hordas-signing/signing.json'
if not private.exists():raise SystemExit('Original signing configuration required outside the repository. Do not regenerate an update key.')
signing=json.loads(private.read_text(encoding='utf8'))
if not Path(signing['keystore']).is_file():raise SystemExit('Original keystore is missing. Restore the same key before exporting.')
env={**os.environ,'GODOT_ANDROID_KEYSTORE_RELEASE_PATH':signing['keystore'],'GODOT_ANDROID_KEYSTORE_RELEASE_USER':signing['alias'],'GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD':signing['password']}
base=Path.home()/'AppData/Local/HordasAndroidToolchain'
java=next((base/'java').iterdir());env['JAVA_HOME']=str(java)
build_info=json.loads((ROOT/'data/mobile_build.json').read_text(encoding='utf8'))
target=ROOT/'build'/('Hordas-Android-'+build_info['base_pc_version']+'-'+str(build_info['android_version_code'])+('-QA' if args.qa else '')+'.apk')
target.parent.mkdir(exist_ok=True)
godot=Path.home()/'Downloads/Godot_v4.7.2-stable_win64_console.exe'
for p in ['assets/tiny_rpg/soldier.png','assets/tiny_rpg/orc.png','assets/fonts/AurusenthialGothic.ttf']:
 if not (ROOT/p).is_file():raise SystemExit('Missing locally licensed asset: '+p)
r=subprocess.run([str(godot),'--headless','--path',str(ROOT),'--export-release','Android QA' if args.qa else 'Android Public',str(target)],cwd=ROOT,env=env,capture_output=True,text=True,encoding='utf8',errors='replace')
log=(r.stdout+r.stderr).replace(signing['password'],'[REDACTED]')
(ROOT/'build'/('android-export-qa.log' if args.qa else 'android-export.log')).write_text(log,encoding='utf8')
if r.returncode or not target.exists() or "ERROR:" in log:
 print(log[-7000:]);raise SystemExit('Android export failed')
verify=subprocess.run([str(base/'sdk/build-tools/35.0.1/apksigner.bat'),'verify','--verbose','--print-certs',str(target)],env=env,capture_output=True,text=True,encoding='utf8',errors='replace')
if verify.returncode:raise SystemExit('APK signature verification failed: '+verify.stderr)
(ROOT/'build'/('android-signature-qa.txt' if args.qa else 'android-signature.txt')).write_text(verify.stdout,encoding='utf8')
meta=json.loads((ROOT/'data/mobile_build.json').read_text(encoding='utf8'))
meta.update({'file':target.name,'source_commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'size_bytes':target.stat().st_size,'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'qa':args.qa,'signature_verified':True,'application_id':'com.socialy.hordas.qa' if args.qa else 'com.socialy.hordas.android'})
target.with_suffix('.json').write_text(json.dumps(meta,indent=2),encoding='utf8')
print(json.dumps(meta,indent=2))
