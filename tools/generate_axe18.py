"""Original editable 32px double axe based on Arthur's supplied blue axe reference."""
from pathlib import Path
from PIL import Image, ImageDraw
out=Path('assets/v18');out.mkdir(parents=True,exist_ok=True)
im=Image.new('RGBA',(32,32));d=ImageDraw.Draw(im)
ink='#1b2428'
d.polygon([(14,1),(17,1),(17,8),(21,8),(24,5),(24,1),(27,2),(28,6),(30,9),(30,18),(28,22),(24,24),(24,20),(20,15),(18,15),(18,30),(16,32),(13,30),(13,15),(11,15),(7,20),(7,24),(3,22),(1,18),(1,9),(3,6),(4,2),(7,1),(7,5),(11,8),(14,8)],fill=ink)
left=[(5,3),(6,3),(6,7),(10,10),(13,11),(13,14),(10,14),(6,18),(6,22),(3,20),(2,17),(2,10),(4,7)]
d.polygon(left,fill='#e5ede9');d.polygon([(6,6),(6,9),(10,11),(12,12),(12,14),(9,15),(5,19),(5,22),(3,19),(3,11)],fill='#60b7d6')
d.polygon([(6,9),(10,11),(12,12),(12,14),(9,15),(5,18),(4,15),(4,12)],fill='#1386ae')
d.polygon([(31-x,y) for x,y in left],fill='#e5ede9')
d.polygon([(25,6),(25,9),(21,11),(19,12),(19,14),(22,15),(26,19),(26,22),(28,19),(28,11)],fill='#60b7d6')
d.polygon([(25,9),(21,11),(19,12),(19,14),(22,15),(26,18),(27,15),(27,12)],fill='#1386ae')
d.rectangle((15,3,16,7),fill='#1189b5');d.rectangle((15,10,16,12),fill='#9b4a51')
d.rectangle((15,14,16,27),fill='#a75b3d');d.line((15,15,15,26),fill='#cd9262')
d.rectangle((14,23,17,24),fill='#d29346');d.rectangle((15,27,16,29),fill='#bc6555')
im.save(out/'axe.png')
print('AXE18_RGBA_32_PASS')
