"""Import only selected, owned Tiny RPG sheets; never invent absent characters.

Full sheets are used because the split Soldier files include a baked shadow,
even in the folder named without shadows. Fixed crops retain source pivots.
PNG outputs stay local: Zerie permits game use, not standalone re-upload.
"""
from pathlib import Path
from PIL import Image,ImageDraw
import argparse,json,hashlib
ROOT=Path(__file__).resolve().parents[1]
DEFAULT=Path.home()/'Downloads/Tiny RPG Character Asset Pack 01 v2.0 -Free Soldier&Orc'
CONFIG={
 'soldier':{'source':'Soldier','counts':[6,8,6,6,9,4,4],'names':['idle','walk','sword','sword2','bow','hurt','death'],'pivot':[50,60]},
 'orc':{'source':'Orc','counts':[6,8,6,6,4,4],'names':['idle','walk','attack','attack2','hurt','death'],'pivot':[52,57]},
}
def main():
 p=argparse.ArgumentParser();p.add_argument('--source',type=Path,default=DEFAULT);p.add_argument('--kind',choices=CONFIG,required=True);a=p.parse_args()
 c=CONFIG[a.kind];who=c['source'];src=a.source/'Characters(100x100 split)'/who/who/(who+'.png')
 if not src.is_file():raise SystemExit('Missing official sheet: '+str(src))
 im=Image.open(src).convert('RGBA');dest=ROOT/'assets/tiny_rpg';dest.mkdir(exist_ok=True)
 cell=(112,80);crop=(22,28,78,68);total=sum(c['counts']);atlas=Image.new('RGBA',(cell[0]*total,cell[1]));clips={};index=0;bounds=[]
 for row,(count,name) in enumerate(zip(c['counts'],c['names'])):
  clips[name]={'start':index,'count':count}
  for n in range(count):
   frame=im.crop((n*100,row*100,(n+1)*100,(row+1)*100));b=frame.getbbox()
   if b and (b[0]<crop[0] or b[1]<crop[1] or b[2]>crop[2] or b[3]>crop[3]):raise SystemExit('Crop would cut '+name+' '+str(n))
   bounds.append(b);frame=frame.crop(crop).resize(cell,Image.Resampling.NEAREST);atlas.paste(frame,(index*cell[0],0));index+=1
 atlas.save(dest/(a.kind+'.png'))
 data_path=ROOT/'data/tiny_characters.json';data=json.loads(data_path.read_text(encoding='utf8')) if data_path.exists() else {}
 pivot=[(c['pivot'][0]-crop[0])*2,(c['pivot'][1]-crop[1])*2]
 data[a.kind]={'texture':f'res://assets/tiny_rpg/{a.kind}.png','frames':total,'cell':cell,'offset':[cell[0]/2-pivot[0],cell[1]/2-pivot[1]],'clips':clips,'source':str(src.relative_to(a.source)),'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'shadow':False,'scale':2,'source_frame':[100,100],'crop':crop}
 data_path.write_text(json.dumps(data,indent=2)+'\n',encoding='utf8')
 out=ROOT/'build/tiny_rpg_catalog';out.mkdir(parents=True,exist_ok=True)
 preview=Image.new('RGB',(9*120,len(clips)*100),'#203047');draw=ImageDraw.Draw(preview)
 for row,(name,clip) in enumerate(clips.items()):
  for n in range(clip['count']):
   i=clip['start']+n;frame=atlas.crop((i*cell[0],0,(i+1)*cell[0],cell[1]));preview.paste(frame,(n*120,row*100),frame);draw.text((n*120,row*100+82),name+' #'+str(n),fill='white')
 preview.save(out/(a.kind+'-imported.png'))
 print(a.kind,total,'frames',cell,'pivot',pivot,'offset',data[a.kind]['offset'])
if __name__=='__main__':main()
