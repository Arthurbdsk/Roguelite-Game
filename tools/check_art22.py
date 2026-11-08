import subprocess,re,json
from pathlib import Path
allowed={'title','texture','frames','visual_family'}
for name in ['hound','necromancer','beast','skeleton_sword','skeleton_archer','slime_large','slime_small']:
 file='data/enemies/'+name+'.tres'
 old=subprocess.check_output(['git','show','091d93f1:'+file]).decode('utf8')
 new=Path(file).read_text(encoding='utf8')
 def fields(s):return {k:v for k,v in re.findall(r'^([a-z_]+) = (.+)$',s,re.M) if k not in allowed}
 assert fields(old)==fields(new),name
old=json.loads(subprocess.check_output(['git','show','091d93f1:data/variants21.json']).decode('utf8'));new=json.loads(Path('data/variants21.json').read_text(encoding='utf8'))
for key in old:
 assert {k:v for k,v in old[key].items() if k!='sprite_pending'}=={k:v for k,v in new[key].items() if k!='visual_family'}
print('ART22_GAMEPLAY_DATA_PRESERVED all base attributes and variant budgets unchanged')
