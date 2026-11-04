from PIL import Image,ImageDraw
from pathlib import Path
import random,math
p=Path('assets/effects')
im=Image.new('RGBA',(48*8,96))
for f in range(8):
 d=ImageDraw.Draw(im);rng=random.Random(55+f);ox=f*48
 points=[(ox+24,0)]
 for y in range(10,84,10):points.append((ox+24+rng.randint(-9,9),y))
 points.append((ox+24,84))
 d.line(points,fill='#2759a2',width=6);d.line(points,fill='#71c5ff',width=4);d.line(points,fill='#eeffff',width=2)
 for i in [2,4,6]:
  x,y=points[i];end=(x+(-1 if i%4 else 1)*rng.randint(8,15),y+10)
  d.line([(x,y),end,(end[0]+2,end[1]+7)],fill='#8ad9ff',width=2)
 for i in range(14):
  a=rng.random()*math.tau;r=3+f*1.4+rng.random()*3;x=ox+24+int(math.cos(a)*r);y=84+int(math.sin(a)*r*.6)
  d.rectangle((x,y,x+1,y+1),fill='#d8fcff' if i%2 else '#5ba7f0')
im.save(p/'lightning.png')
im=Image.new('RGBA',(32*6,16))
for f in range(6):
 d=ImageDraw.Draw(im);ox=f*32
 d.rectangle((ox,4,ox+31,12),fill='#966b22');d.rectangle((ox,5,ox+31,11),fill='#f1c451');d.rectangle((ox,7,ox+31,9),fill='#fffce0')
 for x in range(2,32,8):
  y=2 if (x+f)%3 else 13;d.rectangle((ox+x,y,ox+x+1,y+1),fill='#ffe7a0')
im.save(p/'clock_beam.png')
