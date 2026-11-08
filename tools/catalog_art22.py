"""Build comparison pages from actual before/after atlases, no new drawing."""
from pathlib import Path
import json
from PIL import Image,ImageDraw,ImageFont
r=Path(__file__).resolve().parents[1];out=r/'docs/art22';out.mkdir(parents=True,exist_ok=True)
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',17)
small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',13)
rows=[('Morcego','hound.png',4,'bat'),('Necromante','v08/necromancer.png',16,'necromancer'),('Espadachim','skeleton_sword.png',6,'skeleton_sword'),('Arqueiro','skeleton_archer.png',6,'skeleton_archer'),('Esqueleto com armadura','skeleton_sword.png',6,'skeleton_armored'),('Orc com armadura','tiny_rpg/orc.png',34,'orc_armored'),('Orc de elite','tiny_rpg/orc.png',34,'orc_elite'),('Orc montado','v08/beast.png',16,'orc_mounted'),('Slime grande','slime_large.png',4,'slime_large'),('Slime Rei','v13/slime_king.png',8,'slime_king')]
defs=json.loads((r/'data/original_characters22.json').read_text())
canvas=Image.new('RGB',(1080,80+len(rows)*126),(24,32,42));draw=ImageDraw.Draw(canvas)
draw.text((20,12),'Atlas anterior e arte original nova, ampliados 2x com nearest',font=font,fill='white')
draw.text((20,45),'Personagem',font=small,fill='#d4c090');draw.text((230,45),'Anterior',font=small,fill='#d4c090');draw.text((390,45),'Novo',font=small,fill='#d4c090');draw.text((540,45),'Movimento / ataque / dano / morte',font=small,fill='#d4c090')
for i,(name,path,count,kind) in enumerate(rows):
 y=80+i*126;draw.line((15,y-5,1065,y-5),fill='#566170');draw.text((20,y+30),name,font=small,fill='white')
 old=Image.open(r/'assets'/path).convert('RGBA');old=old.crop((0,0,old.width//count,old.height))
 d=defs['original_'+kind];atlas=Image.open(r/d['texture'].removeprefix('res://')).convert('RGBA');cw,ch=d['cell']
 frames=[old]+[atlas.crop((f*cw,0,(f+1)*cw,ch)) for f in [0,5,10,17,23]]
 for x,frame in zip([235,390,545,675,805,935],frames):
  frame=frame.resize((frame.width*2,frame.height*2),Image.Resampling.NEAREST)
  canvas.paste(frame,(x+(120-frame.width)//2,y+100-frame.height),frame)
canvas.save(out/'comparacao-atlases.png')
# A review contact sheet at 4x, showing all real frames with clip names.
for kind,d in defs.items():
 im=Image.open(r/d['texture'].removeprefix('res://')).convert('RGBA');cw,ch=d['cell'];scale=4
 page=Image.new('RGB',(4*cw*scale+160,6*ch*scale+40),(24,32,42));dr=ImageDraw.Draw(page);dr.text((12,8),kind,font=font,fill='white')
 for row,label in enumerate(['Espera','Movimento','Ataque','Conjuração / extra','Dano','Morte']):
  dr.text((8,40+row*ch*scale+ch*2),label,font=small,fill='#d4c090')
  for col in range(4):
   f=row*4+col;cell=im.crop((f*cw,0,(f+1)*cw,ch)).resize((cw*scale,ch*scale),Image.Resampling.NEAREST)
   page.paste(cell,(160+col*cw*scale,40+row*ch*scale),cell)
 page.save(out/(kind+'.png'))
print(out)
