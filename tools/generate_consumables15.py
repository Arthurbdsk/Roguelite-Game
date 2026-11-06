"""Original 32px pickup icons in the project's existing pixel-art pipeline."""
from pathlib import Path
from PIL import Image, ImageDraw
out=Path('assets/v15');out.mkdir(exist_ok=True)
for kind in ['cleanse','food','gold_bag','xp_magnet','stopwatch']:
 im=Image.new('RGBA',(32,32));d=ImageDraw.Draw(im)
 if kind=='cleanse':
  for box in [(12,1,19,10),(12,21,19,30),(1,12,10,19),(21,12,30,19)]:
   d.rectangle(box,fill='#67451f');d.rectangle(tuple(v+(1 if i<2 else -1) for i,v in enumerate(box)),fill='#deb44e')
  d.polygon([(10,6),(21,6),(26,12),(26,21),(20,26),(10,26),(5,20),(5,12)],fill='#56371d',outline='#eac65d')
  d.polygon([(11,8),(20,8),(24,13),(24,20),(19,24),(11,24),(7,19),(7,13)],fill='#13532e')
  d.polygon([(12,10),(20,9),(22,14),(21,20),(16,22),(11,18)],fill='#25c979');d.line([(12,11),(12,16),(15,18)],fill='#a2ffe2',width=2)
 elif kind=='food':
  d.polygon([(3,27),(3,23),(8,20),(10,21),(17,14),(21,18),(13,25),(10,25),(8,29)],fill='#33232a')
  d.polygon([(4,25),(8,22),(11,23),(9,27),(7,28)],fill='#f6e7bd')
  d.polygon([(11,11),(16,6),(23,4),(28,8),(29,14),(25,21),(18,24),(12,20),(9,17)],fill='#70371e')
  d.polygon([(12,12),(17,7),(23,6),(26,9),(27,14),(23,20),(18,22),(13,18)],fill='#e88d23');d.rectangle((17,9,21,11),fill='#ffd566');d.rectangle((14,13,17,16),fill='#ffc344');d.rectangle((23,14,25,17),fill='#ba4d20')
 elif kind=='gold_bag':
  d.polygon([(5,6),(10,3),(23,3),(28,7),(23,12),(28,22),(27,27),(22,30),(8,29),(3,25),(4,20),(9,12)],fill='#42271d')
  d.polygon([(8,7),(12,5),(23,5),(25,8),(20,12),(25,21),(24,27),(8,26),(6,23),(12,13)],fill='#a86b34')
  d.polygon([(10,17),(14,15),(12,23),(9,24)],fill='#ce924d');d.line((8,12,23,12),fill='#e2c476',width=2)
  for x,y in [(10,6),(17,5),(21,8)]:d.rectangle((x,y,x+5,y+3),fill='#ffd356');d.line((x,y,x+3,y),fill='#fff0a8')
 elif kind=='xp_magnet':
  d.polygon([(3,4),(11,4),(11,19),(14,23),(18,23),(21,19),(21,4),(29,4),(29,22),(25,28),(20,31),(11,31),(5,27),(2,21)],fill='#281f2a')
  d.polygon([(4,6),(9,6),(9,20),(13,25),(19,25),(23,20),(23,6),(27,6),(27,22),(23,27),(19,29),(12,29),(6,25),(4,20)],fill='#bb3d25')
  d.rectangle((4,6,9,13),fill='#c6e3e7');d.rectangle((23,6,27,13),fill='#c6e3e7');d.line([(6,15),(6,21),(12,27)],fill='#ec7440',width=2)
 else:
  d.rectangle((13,2,18,5),fill='#dbb45e');d.rectangle((9,4,22,7),fill='#7f602f')
  d.polygon([(9,7),(23,7),(29,14),(29,24),(23,30),(8,30),(2,24),(2,14)],fill='#62451e',outline='#e6c46a')
  d.polygon([(10,9),(21,9),(26,15),(26,23),(21,27),(10,27),(5,22),(5,15)],fill='#d6bf85')
  for x,y in [(15,11),(23,18),(15,25),(7,18)]:d.rectangle((x,y,x+1,y+1),fill='#6a4828')
  d.line([(15,13),(15,19),(21,22)],fill='#594023',width=2);d.line((7,14,11,10),fill='#fff1ba',width=1)
 im.save(out/(kind+'.png'))
print('Five original RGBA icons generated at 32x32.')
