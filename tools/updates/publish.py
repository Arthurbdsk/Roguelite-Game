"""Prepare signed independent release channels; publish requires explicit --publish."""
from pathlib import Path
import argparse,json,time,hashlib,base64,subprocess
import urllib.request,urllib.error
from cryptography.hazmat.primitives import serialization,hashes
from cryptography.hazmat.primitives.asymmetric import padding
p=argparse.ArgumentParser();p.add_argument('--artifact',required=True);p.add_argument('--metadata',required=True);p.add_argument('--platform',choices=['pc','android'],required=True);p.add_argument('--notes',required=True);p.add_argument('--previous');p.add_argument('--publish',action='store_true');p.add_argument('--online-required',action='store_true');a=p.parse_args()
root=Path(__file__).resolve().parents[2];artifact=Path(a.artifact).resolve();meta=json.loads(Path(a.metadata).read_text());key=serialization.load_pem_private_key((Path.home()/'.hordas-updates/private.pem').read_bytes(),None)
if meta.get('sha256')!=hashlib.sha256(artifact.read_bytes()).hexdigest():raise SystemExit('Artifact does not match its export metadata')
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
if not identity:identity=json.loads((root/'data/gameplay_manifest.json').read_text())['compatibility_id']
tag='update-'+a.platform+'-'+version
url='https://github.com/Arthurbdsk/Roguelite-Game/releases/download/'+tag+'/'+artifact.name
data['platforms'][a.platform]={'version':version,'platform':a.platform,'size':artifact.stat().st_size,'sha256':hashlib.sha256(artifact.read_bytes()).hexdigest(),'url':url,'notes':Path(a.notes).read_text(encoding='utf-8'),'compatibility':identity,'protocol':2,'online_required':a.online_required}
payload=json.dumps(data,ensure_ascii=False,separators=(',',':')).encode();e={'payload':base64.b64encode(payload).decode(),'signature':base64.b64encode(key.sign(payload,padding.PKCS1v15(),hashes.SHA256())).decode()}
out=root/'build/updates';out.mkdir(exist_ok=True);(out/'stable.json').write_text(json.dumps(e))
if a.publish:
 subprocess.run(['gh','auth','status'],check=True)
 subprocess.run(['gh','release','create',tag,str(artifact),'--repo','Arthurbdsk/Roguelite-Game','--title',version,'--notes-file',a.notes],check=True)
 subprocess.run(['python',str(root/'tools/updates/promote.py'),str(out/'stable.json')],check=True)
print(out/'stable.json')
