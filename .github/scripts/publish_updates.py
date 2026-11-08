import os,json,base64,hashlib,subprocess,urllib.request,pathlib,tempfile
repo=os.environ['GH_REPO']; branch='codex/release-channel'
request=json.loads(pathlib.Path('release-request.json').read_text())
source=request['source'].rstrip('/')
assert source.startswith('https://') and source.endswith('.trycloudflare.com')
work=pathlib.Path(tempfile.mkdtemp())
def download(url,path):
 with urllib.request.urlopen(url,timeout=90) as response,path.open('wb') as output:
  while chunk:=response.read(1048576):output.write(chunk)
download(source+'/stable.json',work/'stable.json')
envelope=json.loads((work/'stable.json').read_text())
raw=base64.b64decode(envelope['payload']); signature=base64.b64decode(envelope['signature'])
(work/'payload').write_bytes(raw);(work/'signature').write_bytes(signature)
subprocess.run(['openssl','dgst','-sha256','-verify','update-public.pem','-signature',str(work/'signature'),str(work/'payload')],check=True)
manifest=json.loads(raw);assert manifest['schema']==1
for platform in request['platforms']:
 record=manifest['platforms'][platform];assert record['platform']==platform
 name=record['url'].rsplit('/',1)[1];assert name==os.path.basename(name) and '..' not in name
 tag='update-'+platform+'-'+record['version']
 expected='https://github.com/'+repo+'/releases/download/'+tag+'/'+name
 assert record['url']==expected
 artifact=work/name;download(source+'/'+name,artifact)
 assert artifact.stat().st_size==record['size'] and hashlib.sha256(artifact.read_bytes()).hexdigest()==record['sha256']
 notes=work/(platform+'.txt');notes.write_text(record['notes'])
 exists=subprocess.run(['gh','release','view',tag],capture_output=True).returncode==0
 if exists:
  existing=work/('existing-'+platform);existing.mkdir()
  subprocess.run(['gh','release','download',tag,'--pattern',name,'--dir',str(existing)],check=True)
  assert hashlib.sha256((existing/name).read_bytes()).hexdigest()==record['sha256'],'Version is immutable; choose a new version'
 else:subprocess.run(['gh','release','create',tag,str(artifact),'--title',record['version'],'--notes-file',str(notes)],check=True)
result=subprocess.run(['gh','api','repos/'+repo+'/contents/stable.json?ref='+branch],capture_output=True,text=True)
body={'branch':branch,'message':'Promote authenticated game update channel','content':base64.b64encode((work/'stable.json').read_bytes()).decode()}
if result.returncode==0:body['sha']=json.loads(result.stdout)['sha']
(work/'put.json').write_text(json.dumps(body))
subprocess.run(['gh','api','repos/'+repo+'/contents/stable.json','-X','PUT','--input',str(work/'put.json')],check=True)
print('SIGNED_CHANNEL_PUBLISHED')
