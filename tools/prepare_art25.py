from pathlib import Path
import json
path=Path(__file__).resolve().parents[1]/'data/original_characters22.json'
data=json.loads(path.read_text())
data['original_shadow']['clips']['cast']=dict(data['original_shadow']['clips']['appear'])
data['original_executioner']['clips']['cast']=dict(data['original_executioner']['clips']['phase'])
path.write_text(json.dumps(data,indent=1)+'\n',encoding='utf8')
