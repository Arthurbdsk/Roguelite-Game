"""Publish an already signed channel through gh's external credential store."""
import subprocess,json,base64,sys
from pathlib import Path
repo='repos/Arthurbdsk/Roguelite-Game';branch='codex/release-channel'
def gh(*args):return subprocess.run(['gh',*args],capture_output=True,text=True)
ref=gh('api',repo+'/git/ref/heads/'+branch)
if ref.returncode:
 info=gh('api',repo);info.check_returncode();default=json.loads(info.stdout)['default_branch']
 head=gh('api',repo+'/git/ref/heads/'+default);head.check_returncode();sha=json.loads(head.stdout)['object']['sha']
 created=gh('api',repo+'/git/refs','-X','POST','-f','ref=refs/heads/'+branch,'-f','sha='+sha);created.check_returncode()
current=gh('api',repo+'/contents/stable.json?ref='+branch)
body={'branch':branch,'message':'Publish signed update channel','content':base64.b64encode(Path(sys.argv[1]).read_bytes()).decode()}
if current.returncode==0:body['sha']=json.loads(current.stdout)['sha']
request=Path(sys.argv[1]).with_suffix('.request.json');request.write_text(json.dumps(body))
result=gh('api',repo+'/contents/stable.json','-X','PUT','--input',str(request));result.check_returncode()
print('Published signed update channel')
