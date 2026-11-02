"""Brasafria: deterministic, editable pixel art. Run with Python + Pillow.

All geometry is authored at native pixel resolution. No filtering or antialiasing.
Spritesheets have four horizontal frames. Assets are original to this project.
"""
from pathlib import Path
import math
import random
import urllib.request
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets'
OUT.mkdir(exist_ok=True)
(OUT / 'icons').mkdir(exist_ok=True)

P = {
    'ink': '#0b1014', 'night': '#11191c', 'deep': '#172226',
    'stone0': '#202c30', 'stone1': '#2b373b', 'stone2': '#39464a',
    'stone3': '#505c5d', 'stone4': '#6b7470', 'stone5': '#92988a',
    'moss0': '#29382f', 'moss1': '#424c3a', 'moss2': '#5b6446',
    'bone0': '#7d7965', 'bone1': '#aca487', 'bone2': '#d7c9a1',
    'bone3': '#eee0b8', 'red0': '#40232b', 'red1': '#6b3039',
    'red2': '#9a4845', 'rust': '#b65f42', 'flame': '#e89358',
    'gold': '#dfb969', 'cold0': '#375a5d', 'cold1': '#5f9691',
    'cold2': '#83c4bd', 'cold3': '#c5e6d4', 'violet0': '#2a2639',
    'violet1': '#4a3d5c', 'violet2': '#72617e', 'eye': '#e89161',
}

def color(v):
    return P.get(v, v)

class Art:
    def __init__(self, size, bg=(0, 0, 0, 0)):
        self.im = Image.new('RGBA', size, bg)
        self.d = ImageDraw.Draw(self.im)
    def rect(self, xy, c): self.d.rectangle(xy, fill=color(c))
    def poly(self, pts, c): self.d.polygon(pts, fill=color(c))
    def line(self, pts, c, width=1): self.d.line(pts, fill=color(c), width=width)
    def dot(self, xy, c): self.d.point(xy, fill=color(c))
    def ellipse(self, xy, c): self.d.ellipse(xy, fill=color(c))
    def save(self, name): self.im.save(OUT / name)

def shifted_draw(art, offset):
    """Frame offsets are applied by compositing a temporary native-size drawing."""
    return art

def sheet(name, w, h, painter):
    result = Image.new('RGBA', (w*4,h), (0,0,0,0))
    for f in range(4):
        a = Art((w,h))
        painter(a,f)
        result.alpha_composite(a.im,(f*w,0))
    result.save(OUT/name)

def player(a,f):
    y = 1 if f in (1,3) else 0
    # cape silhouette, split hem, controlled highlights
    a.poly([(7,10+y),(17,10+y),(20,27),(15,29),(12,26),(7,29),(3,27)],'ink')
    a.poly([(7,12+y),(16,12+y),(18,26),(15,27),(12,24),(7,27),(5,26)],'red0')
    a.poly([(7,14+y),(10,14+y),(9,25),(6,27)],'red1')
    a.poly([(15,14+y),(17,24),(15,26),(13,20)],'red2')
    # articulated gait
    a.rect((9,23,11,29-(f==1)),'ink'); a.rect((13,23,15,29-(f==3)),'ink')
    a.rect((8,28-(f==1),11,30-(f==1)),'stone1')
    a.rect((13,28-(f==3),16,30-(f==3)),'stone2')
    a.rect((9,23,10,27),'stone3');a.rect((14,23,15,27),'stone3')
    # breastplate and shoulders
    a.poly([(7,13+y),(11,11+y),(16,13+y),(17,20+y),(14,24+y),(9,23+y),(7,20+y)],'ink')
    a.poly([(8,14+y),(11,12+y),(15,14+y),(15,21+y),(12,23+y),(9,21+y)],'stone3')
    a.poly([(8,14+y),(11,13+y),(11,20+y),(9,21+y)],'bone1')
    a.rect((12,15+y,14,18+y),'stone2')
    a.rect((9,21+y,15,22+y),'red0'); a.rect((11,21+y,12,22+y),'gold')
    a.poly([(4,14+y),(7,12+y),(9,14+y),(8,17+y),(4,17+y)],'ink')
    a.poly([(5,14+y),(7,13+y),(8,14+y),(7,16+y),(5,16+y)],'bone2')
    a.poly([(15,13+y),(18,14+y),(19,18+y),(16,18+y)],'ink')
    a.rect((16,14+y,17,16+y),'bone1')
    # shield, left silhouette
    a.poly([(3,17+y),(8,16+y),(9,23+y),(6,27+y),(3,24+y)],'ink')
    a.poly([(4,18+y),(7,17+y),(8,23+y),(6,25+y),(4,23+y)],'stone3')
    a.line([(5,18+y),(6,23+y)],'bone1')
    # sword diagonal near right arm
    a.line([(18,22+y),(21,12+y)],'ink',3)
    a.line([(18,22+y),(21,12+y)],'bone1')
    a.line([(18,21+y),(20,15+y)],'bone3')
    a.line([(16,22+y),(20,23+y)],'gold');a.dot((18,24+y),'rust')
    # head helmet, crest, eye slit
    a.poly([(8,4+y),(13,2+y),(17,6+y),(17,12+y),(13,15+y),(8,12+y)],'ink')
    a.poly([(9,5+y),(13,3+y),(16,6+y),(16,11+y),(13,13+y),(9,11+y)],'bone0')
    a.poly([(9,5+y),(12,4+y),(13,7+y),(9,8+y)],'bone2')
    a.poly([(13,4+y),(15,6+y),(15,8+y),(13,7+y)],'bone1')
    a.rect((9,8+y,16,9+y),'ink');a.rect((10,8+y,12,8+y),'cold2')
    a.rect((14,8+y,15,8+y),'cold1');a.line([(13,9+y),(13,12+y)],'bone2')
    a.poly([(12,2+y),(12,0),(15,1),(16,5+y),(14,4+y)],'red1')

def ghoul(a,f):
    y = f%2
    a.poly([(7,14+y),(15,13+y),(18,23+y),(15,26),(9,25),(6,23)],'ink')
    a.poly([(8,15+y),(14,14+y),(16,23),(13,25),(9,23)],'red0')
    a.rect((9,17+y,13,22+y),'moss0');a.line([(10,18+y),(13,19+y)],'bone0')
    a.line([(8,15+y),(5,20+y),(3,20+y)],'ink',3)
    a.line([(8,15+y),(5,19+y),(3,20+y)],'moss2')
    a.line([(15,15+y),(19,17+y),(21,15+y)],'ink',3)
    a.line([(15,15+y),(19,17+y),(21,15+y)],'moss1')
    a.line([(9,24),(8-(f==1),29),(5,30)],'ink',3)
    a.line([(14,24),(15+(f==3),29),(18,30)],'ink',3)
    a.line([(9,24),(8-(f==1),28)],'moss1')
    a.line([(14,24),(15+(f==3),29)],'moss1')
    a.poly([(7,5+y),(11,2+y),(16,4+y),(18,8+y),(16,13+y),(11,15+y),(7,11+y)],'ink')
    a.poly([(8,5+y),(11,3+y),(15,5+y),(16,9+y),(14,13+y),(10,12+y),(8,10+y)],'moss1')
    a.poly([(9,5+y),(12,4+y),(13,7+y),(10,8+y)],'moss2')
    a.rect((9,8+y,10,9+y),'eye'); a.rect((14,7+y,15,8+y),'eye')
    a.poly([(11,10+y),(14,10+y),(13,13+y),(11,12+y)],'ink')
    a.dot((12,11+y),'bone1');a.dot((14,11+y),'bone2')

def hound(a,f):
    y=f%2
    a.poly([(3,8+y),(7,6+y),(13,8+y),(18,5+y),(22,8+y),(22,13+y),(17,15+y),(14,14+y),(9,17+y),(4,14+y)],'ink')
    a.poly([(4,9+y),(8,7+y),(13,9+y),(17,7+y),(21,9+y),(20,12+y),(16,14+y),(12,13+y),(8,15+y),(5,13+y)],'violet1')
    a.poly([(5,9+y),(8,8+y),(13,10+y),(12,12+y),(6,11+y)],'violet2')
    a.poly([(15,8+y),(15,3+y),(18,6+y),(20,2+y),(21,8+y)],'ink')
    a.poly([(16,7+y),(16,5+y),(18,7+y)],'violet2')
    a.rect((18,9+y,20,9+y),'eye');a.rect((21,11+y,23,12+y),'ink')
    a.dot((20,13+y),'bone2')
    # curling tail
    a.line([(5,10+y),(1,6+y),(1,3+y),(4,2+y)],'ink',3)
    a.line([(4,9+y),(2,6+y),(2,3+y)],'violet1')
    for x,flip in [(6,False),(10,True),(16,False),(19,True)]:
        step=2 if (f%2==int(flip)) else -1
        a.line([(x,14),(x+step,19+y),(x+step+2,20+y)],'ink',2)
        a.dot((x+step,18+y),'violet2')

def guard(a,f):
    y=f%2
    a.poly([(7,13+y),(23,13+y),(27,31),(22,35),(17,32),(10,35),(5,31)],'ink')
    a.poly([(8,14+y),(21,14+y),(24,31),(21,32),(16,30),(11,33),(7,30)],'violet0')
    a.rect((11,29,14,37-(f==1)),'ink');a.rect((19,29,22,37-(f==3)),'ink')
    a.rect((9,36-(f==1),14,38-(f==1)),'stone2');a.rect((19,36-(f==3),24,38-(f==3)),'stone2')
    a.poly([(8,14+y),(15,11+y),(24,15+y),(23,27+y),(17,31+y),(10,27+y)],'ink')
    a.poly([(10,15+y),(15,13+y),(22,16+y),(21,26+y),(17,29+y),(11,26+y)],'stone2')
    a.poly([(10,15+y),(14,14+y),(14,25+y),(11,26+y)],'stone4')
    a.line([(16,16+y),(18,26+y)],'bone0');a.line([(11,19+y),(21,20+y)],'stone1')
    a.poly([(6,13+y),(11,12+y),(13,15+y),(10,19+y),(5,18+y)],'ink')
    a.poly([(7,14+y),(10,13+y),(11,15+y),(9,17+y),(6,17+y)],'bone0')
    a.poly([(22,14+y),(27,13+y),(29,18+y),(24,20+y)],'ink')
    a.poly([(23,15+y),(26,14+y),(27,17+y),(24,18+y)],'bone1')
    # massive shield
    a.poly([(2,19+y),(10,18+y),(13,22+y),(11,31+y),(6,35+y),(1,30+y)],'ink')
    a.poly([(3,20+y),(9,19+y),(11,22+y),(9,30+y),(6,32+y),(3,29+y)],'stone3')
    a.line([(6,21+y),(6,30+y)],'rust',2);a.line([(4,24+y),(9,24+y)],'bone1')
    # mace
    a.line([(25,25+y),(28,10+y)],'ink',3);a.line([(26,24+y),(28,10+y)],'bone0')
    a.poly([(25,7+y),(28,5+y),(31,8+y),(31,12+y),(28,14+y),(25,11+y)],'ink')
    a.rect((26,8+y,30,11+y),'stone3');a.rect((27,7+y,28,12+y),'bone1')
    a.poly([(11,3+y),(19,2+y),(23,6+y),(22,13+y),(17,16+y),(11,12+y)],'ink')
    a.poly([(12,4+y),(19,3+y),(21,6+y),(20,12+y),(17,14+y),(12,11+y)],'stone3')
    a.poly([(13,4+y),(17,4+y),(17,7+y),(12,7+y)],'bone1')
    a.rect((12,8+y,21,10+y),'ink');a.rect((14,8+y,16,9+y),'eye');a.rect((19,8+y,20,9+y),'eye')
    a.rect((17,10+y,18,13+y),'stone5');a.poly([(12,3+y),(10,0),(15,2+y)],'bone0')

def boss(a,f):
    y=f%2
    # long torn spectral mantle
    a.poly([(18,21+y),(40,20+y),(47,32),(50,51),(44,49),(45,60),(34,57),(30,62),(22,56),(13,59),(15,47),(9,49),(13,34)],'ink')
    a.poly([(19,22+y),(39,22+y),(44,34),(46,49),(40,47),(41,56),(34,53),(29,58),(23,52),(17,55),(19,43),(14,46),(16,34)],'cold0')
    a.poly([(19,25),(24,26),(23,48),(19,52),(20,40),(17,42)],'cold1')
    a.poly([(36,25),(41,33),(43,46),(38,43),(36,53),(34,49)],'cold1')
    # torso iron and bone
    a.poly([(20,22+y),(30,18+y),(41,23+y),(40,39+y),(33,46+y),(24,41+y),(20,34+y)],'ink')
    a.poly([(22,23+y),(30,21+y),(38,24+y),(37,37+y),(32,42+y),(25,38+y),(23,32+y)],'stone2')
    a.poly([(22,23+y),(28,22+y),(28,35+y),(25,37+y),(23,31+y)],'stone4')
    a.line([(30,24+y),(30,37+y)],'bone1',2)
    for j in range(3):
        a.line([(25,27+j*4+y),(29,29+j*4+y),(35,26+j*4+y)],'bone0')
    a.poly([(28,31+y),(31,29+y),(34,32+y),(31,36+y)],'cold2')
    a.dot((31,32+y),'cold3')
    # angular pauldrons
    a.poly([(12,23+y),(16,16+y),(24,20+y),(25,25+y),(21,29+y),(13,28+y)],'ink')
    a.poly([(14,23+y),(17,18+y),(22,21+y),(23,24+y),(20,26+y),(15,26+y)],'bone0')
    a.line([(16,22+y),(18,19+y),(21,22+y)],'bone2')
    a.poly([(37,20+y),(45,18+y),(50,24+y),(47,30+y),(40,29+y)],'ink')
    a.poly([(39,22+y),(44,20+y),(47,24+y),(45,27+y),(41,27+y)],'stone4')
    # left claw
    a.line([(16,28+y),(13,38+y),(17,43+y)],'ink',5)
    a.line([(16,29+y),(14,37+y),(17,41+y)],'stone3',3)
    a.line([(17,40+y),(14,45+y),(13,43+y)],'bone1')
    a.line([(18,40+y),(18,46+y),(16,45+y)],'bone2')
    # enormous sword on right
    a.line([(45,38+y),(53,14+y)],'ink',5)
    a.poly([(47,34+y),(51,15+y),(56,8+y),(55,20+y),(49,35+y)],'ink')
    a.poly([(49,31+y),(52,16+y),(55,11+y),(53,21+y)],'bone1')
    a.line([(51,26+y),(54,14+y)],'cold2')
    a.line([(42,35+y),(51,39+y)],'bone0',2)
    a.line([(46,38+y),(44,44+y)],'rust',2)
    a.line([(44,29+y),(45,36+y)],'stone4',3)
    # skull crown and antlers
    a.poly([(23,8+y),(30,4+y),(39,7+y),(41,14+y),(37,22+y),(30,25+y),(23,19+y)],'ink')
    a.poly([(25,9+y),(30,6+y),(37,8+y),(39,13+y),(35,20+y),(30,22+y),(25,18+y)],'bone0')
    a.poly([(26,9+y),(30,7+y),(33,9+y),(32,13+y),(26,14+y)],'bone2')
    a.poly([(34,9+y),(37,10+y),(38,13+y),(34,13+y)],'bone1')
    a.poly([(25,14+y),(30,13+y),(30,16+y),(26,17+y)],'ink')
    a.poly([(33,13+y),(38,14+y),(36,17+y),(33,16+y)],'ink')
    a.line([(26,15+y),(29,14+y)],'cold2');a.line([(34,14+y),(37,15+y)],'cold2')
    a.poly([(31,15+y),(29,19+y),(33,19+y)],'ink')
    a.line([(27,20+y),(35,20+y)],'bone2')
    a.rect((29,20+y,29,22+y),'ink');a.rect((33,20+y,33,22+y),'ink')
    a.line([(25,10+y),(19,6+y),(18,1)],'ink',4)
    a.line([(25,9+y),(20,5+y),(19,1)],'bone1',2)
    a.line([(37,9+y),(43,5+y),(44,0)],'ink',4)
    a.line([(38,8+y),(42,4+y),(43,0)],'bone2',2)
    a.line([(21,6+y),(15,5+y),(14,2)],'bone0')
    a.line([(42,5+y),(48,4+y),(49,1)],'bone0')

sheet('player.png',24,32,player)
sheet('ghoul.png',24,32,ghoul)
sheet('hound.png',24,24,hound)
sheet('guard.png',32,40,guard)
sheet('boss.png',64,64,boss)

# Sixteen interchangeable courtyard tiles, no high-contrast repeated border.
atlas=Art((128,128), P['stone0'])
for n in range(16):
    rng=random.Random(720+n)
    x0=(n%4)*32;y0=(n//4)*32
    tile=Art((32,32),P['stone0'])
    for y in range(0,32,8):
        offset=0 if (y//8)%2 else -8
        for x in range(offset,32,16):
            tile.rect((x+1,y+1,x+15,y+7),rng.choice(['#263236','#293539','#253135','#283437']))
            tile.line([(x+2,y+1),(x+13,y+1)],'#303c3e')
            if rng.random()<.55:
                tile.line([(x+2,y+7),(x+13,y+7)],'#1d292d')
    for _ in range(12):
        x,y=rng.randrange(32),rng.randrange(32)
        tile.dot((x,y),rng.choice(['#33403f','#202b2e','#2d3a37']))
    if n in (2,5,9,12):
        x,y=rng.randrange(6,23),rng.randrange(6,23)
        tile.line([(x-4,y-5),(x,y-2),(x-1,y+2),(x+4,y+4)],'#182326')
        tile.line([(x,y-2),(x+4,y-4)],'#182326')
    if n in (3,6,7,10,13,15):
        for _ in range(13):
            x,y=rng.randrange(4,28),rng.randrange(4,28)
            tile.rect((x,y,x+rng.randrange(1,3),y+1),rng.choice(['#344231','#3b4834','#303e30']))
    atlas.im.alpha_composite(tile.im,(x0,y0))
atlas.save('tiles.png')

# Physical obstacles have unmistakable bases. Visual tops may overhang their feet.
a=Art((32,48))
a.ellipse((1,36,30,46),(0,0,0,85))
a.poly([(4,35),(25,35),(29,40),(25,44),(5,44),(1,40)],'ink')
a.poly([(5,34),(24,34),(27,39),(24,41),(5,41),(3,39)],'stone3')
a.rect((7,12,24,36),'ink');a.rect((9,12,22,35),'stone2')
a.rect((9,13,12,34),'stone4');a.rect((20,13,22,34),'stone1')
a.line([(15,12),(15,34)],'stone3');a.line([(9,23),(22,23)],'ink')
a.poly([(5,5),(25,5),(27,11),(23,15),(7,15),(4,11)],'ink')
a.poly([(6,6),(24,6),(25,10),(22,12),(8,12),(6,10)],'stone4')
a.poly([(8,1),(20,1),(24,5),(7,5)],'stone2')
a.line([(8,2),(18,2)],'stone5');a.poly([(17,2),(15,7),(19,9),(16,12)],'ink')
a.poly([(6,35),(10,33),(13,35),(10,37),(5,37)],'moss1')
a.dot((9,33),'moss2');a.line([(23,27),(24,33)],'moss1')
a.save('pillar.png')

a=Art((24,24))
a.ellipse((1,17,22,23),(0,0,0,80))
a.poly([(4,9),(7,4),(16,3),(20,7),(20,19),(4,20)],'ink')
a.poly([(5,9),(8,5),(15,4),(18,7),(18,18),(5,19)],'stone3')
a.poly([(6,9),(8,6),(11,5),(11,17),(6,18)],'stone4')
a.line([(8,11),(15,10)],'stone1',2);a.line([(12,8),(12,15)],'stone1',2)
a.line([(16,5),(14,8),(16,10),(15,13)],'ink')
a.rect((3,19,20,20),'moss0');a.dot((6,19),'moss2');a.dot((17,18),'moss1')
a.save('grave.png')

a=Art((24,32))
a.ellipse((3,25,21,31),(0,0,0,80))
a.poly([(6,25),(18,25),(20,28),(17,30),(6,30),(4,28)],'ink')
a.poly([(7,25),(17,25),(18,27),(16,28),(7,28),(6,27)],'stone3')
a.rect((9,20,14,26),'ink');a.rect((10,20,12,25),'stone4')
a.poly([(3,14),(20,14),(18,21),(6,21)],'ink')
a.poly([(5,15),(18,15),(16,19),(7,19)],'stone3')
a.line([(5,15),(18,15)],'bone0')
a.poly([(6,14),(5,10),(9,11),(8,6),(12,1),(13,8),(17,5),(16,10),(19,10),(17,14)],'red1')
a.poly([(8,14),(7,11),(10,12),(10,7),(12,4),(13,10),(15,9),(16,14)],'rust')
a.poly([(10,14),(10,11),(12,8),(13,12),(14,14)],'gold')
a.dot((11,4),'flame');a.dot((16,2),'rust');a.save('brazier.png')

def icon(name,painter):
    a=Art((16,16));painter(a);a.save('icons/'+name+'.png')

def sword_icon(a):
    a.poly([(3,13),(2,11),(5,8),(10,3),(14,1),(13,5),(8,10),(5,12)],'ink')
    a.poly([(6,8),(11,3),(13,2),(12,5),(7,10)],'bone2')
    a.line([(7,8),(12,3)],'bone3');a.line([(3,8),(7,12)],'gold',2)
    a.line([(4,11),(2,13)],'red2',2);a.dot((1,14),'gold')
def bolt_icon(a):
    a.line([(3,13),(12,4)],'ink',3);a.line([(3,12),(11,4)],'bone1')
    a.poly([(9,4),(14,1),(12,6)],'bone3');a.line([(2,10),(2,14),(6,14)],'rust')
    a.line([(4,5),(10,11)],'gold');a.line([(4,5),(8,4),(11,7),(10,11)],'red1')
def orbit_icon(a):
    a.ellipse((1,2,14,13),'cold0');a.ellipse((3,4,12,11),(0,0,0,0))
    a.poly([(8,1),(12,4),(10,8),(6,7),(5,4)],'ink')
    a.poly([(8,2),(11,4),(9,6),(7,6),(6,4)],'rust');a.dot((8,3),'gold')
    a.rect((2,10,5,13),'cold1');a.dot((3,10),'cold3')
def boots_icon(a):
    a.poly([(3,2),(8,2),(8,9),(12,10),(13,13),(3,13)],'ink')
    a.rect((4,3,7,10),'stone4');a.rect((4,10,10,12),'stone3')
    a.rect((4,4,7,5),'bone1');a.line([(4,13),(12,13)],'rust')
def magnet_icon(a):
    a.ellipse((2,1,13,14),'ink');a.ellipse((4,3,11,12),'cold1')
    a.rect((5,2,10,9),(0,0,0,0));a.rect((3,3,5,6),'bone2');a.rect((10,3,12,6),'bone2')
    a.line([(5,10),(6,12),(9,12),(10,10)],'cold2')
def heart_icon(a):
    a.poly([(1,4),(4,1),(7,3),(8,4),(11,1),(14,4),(14,8),(8,14),(1,8)],'ink')
    a.poly([(2,4),(4,2),(7,4),(8,6),(11,2),(13,4),(13,7),(8,12),(2,7)],'red1')
    a.poly([(3,4),(4,3),(6,4),(6,6),(3,6)],'rust')
def ward_icon(a):
    a.poly([(2,2),(8,0),(14,2),(13,10),(8,15),(3,10)],'ink')
    a.poly([(3,3),(8,2),(12,3),(11,9),(8,13),(4,9)],'bone1')
    a.poly([(5,4),(8,3),(10,4),(10,8),(8,11),(5,8)],'stone2')
    a.line([(8,4),(8,9)],'cold2');a.line([(6,6),(10,6)],'cold2')
def crown_icon(a):
    a.poly([(1,4),(5,7),(8,1),(11,7),(15,4),(13,13),(3,13)],'ink')
    a.poly([(2,5),(5,9),(8,3),(11,9),(14,5),(12,11),(4,11)],'gold')
    a.rect((4,12,12,13),'bone0');a.dot((8,9),'rust');a.dot((8,2),'bone3')
for name, fn in [('sword',sword_icon),('bolt',bolt_icon),('orbit',orbit_icon),('boots',boots_icon),('magnet',magnet_icon),('heart',heart_icon),('ward',ward_icon),('crown',crown_icon)]: icon(name,fn)

# Experience shard and reward coin, spare UI assets.
a=Art((10,12));a.poly([(5,0),(9,5),(5,11),(0,6)],'ink');a.poly([(5,1),(8,5),(5,9),(2,6)],'cold1');a.poly([(5,2),(5,7),(3,5)],'cold3');a.save('xp.png')
a=Art((12,12));a.ellipse((1,1,10,10),'ink');a.ellipse((2,1,9,9),'bone0');a.ellipse((3,2,8,8),'gold');a.line([(5,3),(5,7)],'bone3');a.dot((7,7),'rust');a.save('seal.png')

# Native-resolution illustrated fortress. Intended as title/hub background, not UI.
a=Art((256,160),P['night'])
rng=random.Random(44)
for y in range(160):
    c=(14+int(y*.03),22+int(y*.035),27+int(y*.035),255)
    a.line([(0,y),(255,y)],c)
# pale moon behind the left tower, small star field
a.ellipse((163,8,199,44),'stone1');a.ellipse((166,10,196,41),'stone2')
a.ellipse((171,12,198,39),'deep')
for _ in range(40):
    x,y=rng.randrange(256),rng.randrange(8,70)
    if rng.random()<.6:a.dot((x,y),'stone3')
# mountain layers and dead tree silhouettes
a.poly([(0,76),(23,56),(44,62),(71,40),(92,65),(121,53),(151,70),(180,43),(216,64),(242,49),(255,67),(255,125),(0,125)],'#182328')
a.poly([(0,95),(25,78),(60,88),(82,73),(113,94),(145,74),(176,85),(203,71),(255,91),(255,132),(0,132)],'#1d2a2e')
for x,yy in [(15,100),(237,91),(224,110)]:
    a.line([(x,yy+20),(x+1,yy-24)],'ink',3)
    a.line([(x+1,yy-5),(x-8,yy-14),(x-12,yy-15)],'ink',2)
    a.line([(x+1,yy-10),(x+11,yy-20),(x+13,yy-28)],'ink',2)
    a.line([(x+1,yy-19),(x-4,yy-27)],'ink')

def brick_wall(x0,y0,x1,y1,c='stone1',seed=0):
    rr=random.Random(seed)
    a.rect((x0,y0,x1,y1),c)
    for y in range(y0+2,y1,6):
        a.line([(x0,y),(x1,y)],'stone0')
        off=(y//6%2)*6
        for x in range(x0+off,x1,12):
            a.line([(x,y),(x,y+5)],'stone0')
            if rr.random()<.3:a.line([(x+1,y+1),(min(x+8,x1),y+1)],'stone2')

# Broken rear keep.
brick_wall(84,48,173,114,seed=2)
a.poly([(84,48),(84,39),(92,39),(92,45),(102,45),(102,35),(109,35),(111,43),(122,40),(130,49),(141,44),(148,45),(148,36),(157,36),(158,44),(166,44),(166,38),(173,38),(173,53)],'stone1')
a.line([(87,48),(96,48),(102,45)],'stone3')
a.poly([(118,48),(124,42),(130,49),(126,59),(130,64),(124,69),(126,77)],'ink')
# Keep windows.
for x in [95,144,159]:
    a.rect((x,60,x+5,75),'ink');a.poly([(x,60),(x+2,56),(x+5,60)],'ink')
    a.rect((x+2,62,x+3,72),'cold0')
# high left tower, right broken tower
brick_wall(52,36,82,117,seed=7)
a.rect((49,34,85,40),'stone2');a.line([(50,34),(84,34)],'stone4')
for x in [50,63,77]:a.rect((x,26,x+7,35),'stone2');a.line([(x,26),(x+6,26)],'stone4')
a.rect((50,41,54,111),'stone3');a.rect((78,41,82,114),'stone0')
a.rect((62,51,67,66),'ink');a.poly([(62,51),(64,47),(67,51)],'ink');a.line([(64,52),(64,62)],'cold1')
a.rect((63,79,68,91),'ink')
brick_wall(177,54,205,119,seed=3)
a.poly([(175,55),(175,47),(181,47),(182,40),(189,45),(189,50),(197,48),(198,40),(205,40),(207,55)],'stone2')
a.line([(178,55),(184,55),(187,52)],'stone4');a.rect((178,56,181,112),'stone3')
a.rect((188,67,193,82),'ink');a.poly([(188,67),(190,63),(193,67)],'ink')
# low curtain walls and projecting buttresses
brick_wall(29,88,105,124,seed=4);brick_wall(151,88,224,124,seed=5)
for x in range(29,101,15):a.rect((x,82,x+7,90),'stone2')
for x in range(151,223,15):a.rect((x,82,x+7,90),'stone2')
for x in [36,86,165,212]:
    a.poly([(x,91),(x+5,91),(x+9,125),(x-3,125)],'stone0')
    a.line([(x,92),(x-2,122)],'stone3')
# arch entrance, segmented stones and cold inner darkness
brick_wall(104,77,152,126,seed=8)
a.poly([(112,126),(112,97),(116,87),(125,82),(134,82),(143,88),(146,97),(146,126)],'ink')
a.poly([(117,125),(117,98),(121,91),(128,88),(136,91),(141,99),(141,125)],'deep')
a.poly([(121,125),(121,100),(126,94),(132,95),(136,101),(136,125)],'#101b21')
for pts in [[(111,96),(115,87),(119,90),(116,98)],[(116,86),(125,80),(127,85),(120,90)],[(126,80),(135,81),(134,86),(128,86)],[(136,82),(144,88),(141,92),(135,88)],[(144,90),(148,98),(143,99),(141,94)]]:
    a.poly(pts,'stone3')
a.rect((110,100,115,123),'stone3');a.rect((144,100,148,123),'stone2')
for x in range(120,138,4):a.line([(x,99),(x,118)],'stone0')
a.line([(119,105),(138,105)],'stone0');a.line([(119,116),(138,116)],'stone0')
# standards, cloth tattered
for x in [94,159]:
    a.line([(x,67),(x,104)],'bone0')
    a.poly([(x+1,68),(x+9,68),(x+9,88),(x+6,86),(x+3,90),(x+1,85)],'red0')
    a.line([(x+2,70),(x+7,70)],'red2');a.line([(x+4,73),(x+4,83)],'rust')
    a.line([(x+2,77),(x+6,77)],'rust')
# foreground yard and road
a.poly([(0,125),(90,119),(113,124),(144,124),(181,119),(255,126),(255,159),(0,159)],'#1c282a')
a.poly([(116,125),(141,125),(163,159),(88,159)],'stone1')
for y in range(128,160,7):
    t=(y-125)/34;x0=int(116-28*t);x1=int(141+22*t)
    a.line([(x0,y),(x1,y)],'stone0')
    for x in range(x0+5,x1,14):a.line([(x,y),(x-1,y+6)],'stone0')
for _ in range(150):
    x,y=rng.randrange(256),rng.randrange(123,160)
    if x<90 or x>163:
        a.dot((x,y),rng.choice(['#24322f','#2e3b32','#344131','#152224']))
for x,y in [(34,131),(65,142),(190,132),(211,148),(82,128)]:
    a.poly([(x,y),(x+5,y-3),(x+9,y),(x+7,y+3),(x+1,y+3)],'ink')
    a.poly([(x+1,y),(x+5,y-2),(x+8,y),(x+6,y+1),(x+2,y+1)],'stone2')
# braziers either side entrance, sparse warm color.
for x in [101,153]:
    a.line([(x,122),(x,110)],'ink',3);a.line([(x,113),(x+1,121)],'stone4')
    a.poly([(x-4,108),(x+4,108),(x+2,112),(x-2,112)],'stone3')
    a.poly([(x-3,107),(x-2,103),(x,105),(x+1,99),(x+3,104),(x+2,108)],'rust')
    a.poly([(x-1,108),(x,104),(x+1,106),(x+1,108)],'gold')
# subtle overgrowth on the ruined wall.
for x,y in [(47,101),(79,89),(170,105),(201,92),(218,115)]:
    a.line([(x,y),(x+2,y+8),(x,y+13)],'moss0',2)
    for dy in (2,5,9):a.line([(x+1,y+dy),(x-2,y+dy-1)],'moss1')
a.save('fortress.png')

# App icon: cold brazier crest, hard-edged at 64 px.
a=Art((64,64),P['night'])
a.poly([(8,7),(32,1),(55,7),(52,42),(32,61),(11,42)],'ink')
a.poly([(11,9),(32,4),(52,9),(49,40),(32,57),(14,40)],'bone0')
a.poly([(14,12),(32,8),(49,12),(46,38),(32,52),(17,38)],'stone0')
a.poly([(22,31),(20,24),(27,26),(26,15),(33,9),(35,22),(42,18),(40,27),(44,29),(39,35),(26,35)],'cold0')
a.poly([(26,31),(25,26),(30,28),(29,19),(33,14),(34,26),(38,24),(37,32)],'cold2')
a.poly([(29,32),(31,24),(34,29),(34,33)],'cold3')
a.poly([(21,34),(43,34),(40,40),(24,40)],'bone0');a.rect((30,40,34,47),'bone1')
a.line([(24,36),(40,36)],'bone2');a.line([(27,48),(37,48)],'bone0')
a.save('icon.png')

# Font is vendored once; regeneration is deterministic/offline afterwards.
for filename,url in [
    ('font.ttf','https://raw.githubusercontent.com/google/fonts/main/ofl/pixelifysans/PixelifySans%5Bwght%5D.ttf'),
    ('OFL.txt','https://raw.githubusercontent.com/google/fonts/main/ofl/pixelifysans/OFL.txt'),
]:
    path=OUT/filename
    if not path.exists():
        try: urllib.request.urlretrieve(url,path)
        except Exception as exc: print('Optional font fetch failed:',exc)

manifest = [
    '# Assets de Brasafria', '',
    'Arte original gerada em tools/generate_assets.py com Pillow. Sem antialiasing.',
    'Filtro de importação: Nearest. Todas as spritesheets têm 4 quadros horizontais.', '',
    '| Arquivo | Quadro | Uso |', '| --- | --- | --- |',
    '| player.png | 24x32 | Sentinela, caminhada frontal |',
    '| ghoul.png | 24x32 | Perseguidor comum |',
    '| hound.png | 24x24 | Fera rápida |',
    '| guard.png | 32x40 | Guarda resistente |',
    '| boss.png | 64x64 | Cavaleiro espectral |',
    '| tiles.png | 32x32, atlas 4x4 | Piso, 16 variantes |',
    '| pillar.png | 32x48 | Pilar sólido, base nos 12 pixels inferiores |',
    '| grave.png | 24x24 | Lápide sólida |',
    '| brazier.png | 24x32 | Braseiro decorativo |',
    '| fortress.png | 256x160 | Ilustração de cenário para título/base |',
    '| icons/*.png | 16x16 | Oito ícones de armas e passivas |',
    '| xp.png | 10x12 | Fragmento de experiência |',
    '| seal.png | 12x12 | Selo |',
    '| icon.png | 64x64 | Ícone do aplicativo |', '',
    'Frames 0/2 correspondem ao repouso; frames 1/3 alternam apoio dos pés e deslocamento de 1 pixel.',
    'Pontos de origem recomendados: meio da base de cada quadro, com 2 pixels de margem.',
    'Pixelify Sans: copyright The Pixelify Sans Project Authors. Licença em OFL.txt.',
    'Fonte: https://github.com/google/fonts/tree/main/ofl/pixelifysans', '',
    'Arte provisória funcional. Animações direcionais, ataques próprios e animação de morte são acabamento futuro.',
]
(OUT/'README.md').write_text('\n'.join(manifest)+'\n',encoding='utf-8')
for path in sorted(OUT.rglob('*.png')):
    with Image.open(path) as im: print(path.relative_to(ROOT),im.size)
