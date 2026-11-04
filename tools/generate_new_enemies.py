from pathlib import Path
from PIL import Image,ImageDraw
p=Path('assets');p.mkdir(exist_ok=True)
for kind in ['necromancer','beast','plague','shadow']:
 w,h=(64,64) if kind=='beast' else (32,48)
 sheet=Image.new('RGBA',(w*6,h))
 for f in range(6):
  im=Image.new('RGBA',(w,h));d=ImageDraw.Draw(im);b=[0,1,0,-1,0,1][f];cx=w//2
  if kind=='beast':
   d.polygon([(20,58),(21,25),(27,18),(37,18),(44,28),(45,57),(37,60),(34,42),(29,42),(27,60)],fill='#101b28')
   for x in [21,43]:
    d.line([(32,26),(x,16),(x-3,5)],fill='#172c39',width=3);d.line([(x,13),(x-9 if x<32 else x+9,8)],fill='#172c39',width=2)
   d.rectangle((25,23+b,39,35+b),fill='#203743');d.point((28,27+b),fill='#ef9c6a');d.point((36,27+b),fill='#ef9c6a')
   d.line([(23,31),(15,44+b),(13,51+b)],fill='#182b36',width=6);d.line([(41,31),(49,44-b),(51,51-b)],fill='#182b36',width=6)
   for y in range(32,53,4):d.line((24,y,39,y+3),fill='#263f49')
  else:
   col={'necromancer':'#711e30','plague':'#292437','shadow':'#11121c'}[kind]
   d.polygon([(cx-7,15+b),(cx+7,15+b),(cx+11,h-6),(cx+4,h-4),(cx+1,h-1),(cx-2,h-5),(cx-9,h-3)],fill=col)
   d.ellipse((cx-7,5+b,cx+7,23+b),fill=col);d.rectangle((cx-4,11+b,cx+4,19+b),fill='#0d0f14')
   d.line((cx-6,23+b,cx-12,30+(0 if f==4 else b)),fill=col,width=5);d.line((cx+5,23+b,cx+11,29-b),fill=col,width=5)
   if kind=='necromancer':
    d.rectangle((cx-4,12+b,cx+4,18+b),fill='#ae8555');d.rectangle((cx-3,14+b,cx-2,16+b),fill='#100d11');d.rectangle((cx+2,14+b,cx+3,16+b),fill='#100d11')
    d.line((3,14,7,38),fill='#7d5835',width=2);d.polygon([(1,14),(2,6-f%3),(5,2),(8,11),(6,17)],fill='#ea912c');d.line((4,8,5,14),fill='#f8d768',width=2)
    d.rectangle((cx-2,19+b,cx+2,20+b),fill='#ae8555');d.point((cx,19+b),fill='#100d11')
    d.line((cx-3,26,cx-1,42),fill='#a7353d',width=2)
    d.line((cx+7,27,cx+11,29-b),fill='#ae8555',width=2)
    d.line((cx-7,21,cx-4,31),fill='#8d2c39',width=1)
   if kind=='plague':
    d.polygon([(3,9+b),(11,7+b),(17,2+b),(22,10+b),(29,13+b),(9,13+b)],fill='#211a30')
    d.polygon([(13,15+b),(7,18+b),(4,25+b),(16,21+b)],fill='#dfd292');d.point((16,15+b),fill='#08090d')
    d.rectangle((25,21-b,30,30-b),fill='#b0b85d');d.rectangle((27,23-b,28,28-b),fill='#eeecad');d.line((3,24,4,43),fill='#79644e',width=2)
   if kind=='shadow':
    d.rectangle((cx-4,14+b,cx-3,15+b),fill='#f1efcd');d.rectangle((cx+2,14+b,cx+3,15+b),fill='#f1efcd')
    for x in [6,11,19,24]:d.line((x,31,x+(f%3-1)*2,h-1-(x%3)),fill='#151824',width=2)
  sheet.alpha_composite(im,(f*w,0))
 sheet.save(p/(kind+'.png'))
