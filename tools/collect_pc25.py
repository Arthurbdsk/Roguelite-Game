from pathlib import Path
import ast,json
root=Path(__file__).resolve().parents[1]
tree=ast.parse((root/'tools/validate_pc25.py').read_text())
groups={}
for node in tree.body:
 if isinstance(node,ast.Assign) and isinstance(node.targets[0],ast.Name) and node.targets[0].id in ['ordered','regressions']:groups[node.targets[0].id]=ast.literal_eval(node.value)
rows=[]
for name in groups['ordered']+groups['regressions']:
 path=root/'build/bestiary25'/(name+'.log');text=path.read_text(encoding='utf8')
 passed='_PASS' in text and not any(s in text for s in ['SCRIPT ERROR','ERROR:','FAIL'])
 rows.append({'test':name,'passed':passed,'evidence':[s for s in text.splitlines() if '_PASS' in s]})
 if not passed:raise SystemExit('Validation incomplete: '+name)
out=root/'docs/pc25';out.mkdir(parents=True,exist_ok=True)
(out/'validation.json').write_text(json.dumps(rows,indent=2)+'\n')
print('PC25_COLLECT_PASS',len(rows),'suites')
