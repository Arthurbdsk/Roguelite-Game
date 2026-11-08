"""Prepare signed independent release channels; publish requires explicit --publish."""
from pathlib import Path
import argparse,json,time,hashlib,base64,subprocess
import urllib.request,urllib.error
from cryptography.hazmat.primitives import serialization,hashes
from cryptography.hazmat.primitives.asymmetric import padding
p=argparse.ArgumentParser();p.add_argument('--artifact',required=True);p.add_argument('--metadata',required=True);p.add_argument('--platform',choices=['pc','android'],required=True);p.add_argument('--notes',required=True);p.add_argument('--previous');p.add_argument('--publish',action='store_true');p.add_argument('--online-required',action='store_true');a=p.parse_args()
root=Path(__file__).resolve().parents[2];artifact=Path(a.artifact).resolve();meta=json.loads(Path(a.metadata).read_text());key=serialization.load_pem_private_key((Path.home()/'.hordas-updates/private.pem').read_bytes(),None)
if meta.get('sha256')!=hashlib.sha256(artifact.read_bytes()).hexdigest():raise SystemExit('Artifact does not match its export metadata')
if a.platform=='pc':
 import ctypes
 from ctypes import wintypes
 v=ctypes.windll.version
 v.GetFileVersionInfoSizeW.argtypes=[wintypes.LPCWSTR,ctypes.POINTER(wintypes.DWORD)]
 size=v.GetFileVersionInfoSizeW(str(artifact),None);assert size>0,'Windows version metadata missing'
 buffer=ctypes.create_string_buffer(size)
 v.GetFileVersionInfoW.argtypes=[wintypes.LPCWSTR,wintypes.DWORD,wintypes.DWORD,ctypes.c_void_p]
 assert v.GetFileVersionInfoW(str(artifact),0,size,buffer)
 pointer=ctypes.c_void_p();length=wintypes.UINT()
 v.VerQueryValueW.argtypes=[ctypes.c_void_p,wintypes.LPCWSTR,ctypes.POINTER(ctypes.c_void_p),ctypes.POINTER(wintypes.UINT)]
 assert v.VerQueryValueW(buffer,'\\',ctypes.byref(pointer),ctypes.byref(length)) and length.value>=52
 fixed=ctypes.cast(pointer,ctypes.POINTER(ctypes.c_uint32));ms,ls=fixed[4],fixed[5]
 actual=f'{ms>>16}.{ms&65535}.{ls>>16}'
 assert actual==meta['game_version'],'Export metadata disagrees with executable version'
else:
 import os,re,zipfile
 with zipfile.ZipFile(artifact) as archive:
  embedded=json.loads(archive.read('assets/data/gameplay_manifest.json'))
  assert embedded['compatibility_id']==meta['compatibility_id'],'APK gameplay identity mismatch'
 toolchain=Path.home()/'AppData/Local/HordasAndroidToolchain'
 badging=subprocess.check_output([str(toolchain/'sdk/build-tools/35.0.1/aapt.exe'),'dump','badging',str(artifact)],text=True,encoding='utf-8')
 package=re.search(r"package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'",badging)
 assert package and package[1]=='com.socialy.hordas.android' and int(package[2])==meta['android_version_code'] and package[3]==meta['mobile_version'],'APK identity/version mismatch'
 env={**os.environ,'JAVA_HOME':str(next((toolchain/'java').iterdir()))}
 signature=subprocess.check_output([str(toolchain/'sdk/build-tools/35.0.1/apksigner.bat'),'verify','--print-certs',str(artifact)],env=env,text=True)
 assert 'a2d917b419ab3da9572b72f1e0c825b56b800ef6ef011ed4108591b396449c05' in signature,'Original Android signature required'
data={'schema':1,'expires':int(time.time())+90*86400,'platforms':{}}
if a.publish and not a.previous:
 try:
  previous=urllib.request.urlopen('https://raw.githubusercontent.com/Arthurbdsk/Roguelite-Game/codex/release-channel/stable.json',timeout=20).read()
  cached=root/'build/previous-update.json';cached.write_bytes(previous);a.previous=str(cached)
 except urllib.error.HTTPError as error:
  if error.code!=404:raise
if a.previous:
 e=json.loads(Path(a.previous).read_text());payload=base64.b64decode(e['payload']);key.public_key().verify(base64.b64decode(e['signature']),payload,padding.PKCS1v15(),hashes.SHA256());data['platforms']=json.loads(payload)['platforms']
version=meta.get('mobile_version',meta.get('game_version'));identity=meta.get('compatibility_id')
if not identity:raise SystemExit('Re-export with embedded-content identity metadata before publishing')
tag='update-'+a.platform+'-'+version
url='https://github.com/Arthurbdsk/Roguelite-Game/releases/download/'+tag+'/'+artifact.name
data['platforms'][a.platform]={'version':version,'platform':a.platform,'size':artifact.stat().st_size,'sha256':hashlib.sha256(artifact.read_bytes()).hexdigest(),'url':url,'notes':Path(a.notes).read_text(encoding='utf-8'),'compatibility':identity,'protocol':2,'online_required':a.online_required}
for platform,record in data['platforms'].items():
 record['compatible_versions']=' / '.join(('PC' if name=='pc' else 'Android')+' '+other['version'] for name,other in data['platforms'].items() if other['compatibility']==record['compatibility'])
payload=json.dumps(data,ensure_ascii=False,separators=(',',':')).encode();e={'payload':base64.b64encode(payload).decode(),'signature':base64.b64encode(key.sign(payload,padding.PKCS1v15(),hashes.SHA256())).decode()}
out=root/'build/updates';out.mkdir(exist_ok=True);(out/'stable.json').write_text(json.dumps(e))
if a.publish:
 subprocess.run(['gh','auth','status'],check=True)
 subprocess.run(['gh','release','create',tag,str(artifact),'--repo','Arthurbdsk/Roguelite-Game','--title',version,'--notes-file',a.notes],check=True)
 subprocess.run(['python',str(root/'tools/updates/promote.py'),str(out/'stable.json')],check=True)
print(out/'stable.json')
