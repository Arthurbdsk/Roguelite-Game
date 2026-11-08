from pathlib import Path
import subprocess,os,hashlib,json,zipfile,argparse,re
root=Path(__file__).resolve().parents[2];base=Path.home()/'AppData/Local/HordasAndroidToolchain';out=root/'build/update25';out.mkdir(parents=True,exist_ok=True)
parser=argparse.ArgumentParser();parser.add_argument('--android-request',action='store_true');args=parser.parse_args();assert args.android_request
adb=base/'sdk/platform-tools/adb.exe';env={**os.environ,'JAVA_HOME':str(next((base/'java').iterdir()))}
def run(command,allow=False):
    result=subprocess.run([str(x) for x in command],capture_output=True,timeout=90)
    if result.returncode and not allow:raise RuntimeError(result.stderr.decode(errors='replace'))
    return result
def certificate(apk):
    r=subprocess.run([str(base/'sdk/build-tools/35.0.1/apksigner.bat'),'verify','--print-certs',str(apk)],env=env,capture_output=True,text=True,timeout=60)
    assert r.returncode==0
    return next(line.split(': ',1)[1] for line in r.stdout.splitlines() if 'certificate SHA-256 digest:' in line)
old=root/'build/Hordas-Android-0.25.0-2.apk';new=root/'build/Hordas-Android-0.25.1-3.apk'
assert certificate(old)==certificate(new),'Update signing certificate changed'
with zipfile.ZipFile(new) as z:
    manifest=json.loads(z.read('assets/data/gameplay_manifest.json'))
    assert manifest['compatibility_id']==json.loads((root/'data/gameplay_manifest.json').read_text())['compatibility_id']
    assert not any('crossplay25_qa' in name or '/scripts/mobile/qa.gd' in name or '/scripts/dev/' in name for name in z.namelist()),'QA/DEV code in public package'
run([adb,'wait-for-device']);run([adb,'shell','am','force-stop','com.socialy.hordas.android'])
package=run([adb,'shell','dumpsys','package','com.socialy.hordas.android']).stdout.decode(errors='replace')
old_code=int(re.search(r'versionCode=(\d+)',package).group(1))
profile='/data/user/0/com.socialy.hordas.android/files/profile.json'
before=run([adb,'shell','cat',profile],allow=True)
if before.returncode and b'Permission denied' in before.stderr:raise RuntimeError('ADB cannot read the profile; save preservation is not verified')
before_bytes=before.stdout if before.returncode==0 else None
if before_bytes is not None:(out/'profile-before.json').write_bytes(before_bytes)
installed=run([adb,'install','-r',new]);assert b'Success' in installed.stdout
after=run([adb,'shell','cat',profile],allow=True)
assert before_bytes is None or before_bytes==after.stdout,'Installation changed private profile bytes'
if before_bytes is not None:(out/'profile-after-install.json').write_bytes(after.stdout)
run([adb,'shell','monkey','-p','com.socialy.hordas.android','-c','android.intent.category.LAUNCHER','1'])
report={'certificate_preserved':True,'certificate_sha256':certificate(new),'old_version_code':old_code,'old_profile_existed':before_bytes is not None,'profile_bytes_unchanged_after_install':before_bytes is not None and before_bytes==after.stdout,'profile_before_sha256':hashlib.sha256(before_bytes).hexdigest() if before_bytes else None,'application_id':'com.socialy.hordas.android','version_code':3,'compatibility_id':manifest['compatibility_id'],'public_qa_dev_excluded':True}
(out/'update-verification.json').write_text(json.dumps(report,indent=2));print('ANDROID_UPDATE25_PASS',json.dumps(report))
