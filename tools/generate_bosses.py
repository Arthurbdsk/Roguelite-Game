"""Original hard-pixel bosses for Brasafria. Pillow, native resolution, no blur."""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / 'assets'
C = {'ink':'#0b1014','iron':'#243035','metal':'#465357','edge':'#7c8580',
     'bone':'#d7c9a1','light':'#eee0b8','rust':'#b65f42','warm':'#e89358',
     'red0':'#38212b','red1':'#65323a','red2':'#9a4845','gold':'#dfb969',
     'skin0':'#382b35','skin1':'#67454a','skin2':'#a26958',
     'cold':'#83c4bd','purple':'#ad8eac'}

def make_sheet(name, width, height, frames, painter):
    atlas = Image.new('RGBA',(width*frames,height))
    for frame in range(frames):
        im = Image.new('RGBA',(width,height)); painter(ImageDraw.Draw(im),frame)
        atlas.alpha_composite(im,(frame*width,0))
    atlas.save(OUT/name)

def executioner(d,f):
    y = int(f in (1,3)); dead = f>=6
    if dead:y=10 if f==6 else 20
    def poly(p,c):d.polygon([(x,min(63,a+y)) for x,a in p],fill=C[c])
    def rect(b,c):d.rectangle((b[0],min(63,b[1]+y),b[2],min(63,b[3]+y)),fill=C[c])
    def line(p,c,w=1):d.line([(x,min(63,a+y)) for x,a in p],fill=C[c],width=w)
    poly([(12,20),(24,16),(34,21),(39,49),(31,57),(25,53),(16,58),(7,51)],'ink')
    poly([(13,23),(23,18),(32,23),(36,48),(30,54),(24,49),(16,55),(10,49)],'red0')
    poly([(14,25),(19,26),(16,48),(12,51)],'red1')
    poly([(31,26),(34,46),(30,52),(28,42)],'red2')
    # Heavy boots, broad plated torso, leather belt and rusted chain.
    for x,shift in ((17,int(f==1)*2),(27,int(f==3)*2)):
        rect((x,46,x+5,58-shift),'ink');rect((x-2,56-shift,x+6,61-shift),'iron')
        line([(x,47),(x+1,54-shift)],'edge',2)
    poly([(12,24),(22,20),(33,24),(32,43),(26,49),(16,45)],'ink')
    poly([(14,25),(22,22),(31,26),(29,42),(24,46),(17,42)],'metal')
    poly([(15,26),(21,23),(21,39),(17,41)],'edge')
    line([(23,25),(27,38),(24,44)],'iron',3)
    rect((15,42,31,45),'red0');rect((22,42,25,45),'gold')
    poly([(6,24),(12,20),(17,24),(15,31),(8,32),(4,28)],'ink')
    poly([(7,24),(12,22),(15,25),(13,29),(8,30)],'metal')
    line([(7,25),(12,23),(14,25)],'edge')
    line([(9,31),(7,40),(10,45)],'ink',7);line([(9,32),(8,39),(11,43)],'metal',4)
    for a in range(33,46,4):rect((6,a,8,a+1),'gold')
    poly([(30,23),(36,25),(38,32),(33,33),(29,28)],'ink')
    line([(34,29),(37,37),(39,41)],'metal',5)
    # Executioner's hood with a closed iron death mask.
    poly([(17,6),(23,3),(30,8),(33,20),(29,25),(15,24),(12,19)],'ink')
    poly([(18,7),(23,5),(28,9),(30,20),(27,23),(16,22),(15,18)],'red0')
    poly([(18,10),(26,10),(29,15),(27,21),(20,23),(17,18)],'metal')
    line([(18,11),(22,10),(22,19)],'edge')
    rect((18,14,27,16),'ink');rect((19,15,21,15),'warm');rect((25,15,26,15),'warm')
    line([(22,18),(25,18),(25,21)],'iron')
    # Cleaver changes posture for windup, rush and death.
    if f==4:
        line([(35,29),(31,15),(27,4)],'ink',5);line([(35,29),(27,4)],'rust',2)
        poly([(26,2),(38,3),(44,12),(32,14)],'ink')
        poly([(28,3),(37,4),(42,11),(32,12)],'edge')
        line([(31,11),(41,10)],'bone',2)
    elif dead:
        line([(15,35),(43,42)],'rust',3);poly([(37,34),(47,35),(46,45),(34,42)],'edge')
    else:
        line([(39,29),(37,56)],'ink',5);line([(39,29),(37,56)],'rust',2)
        poly([(37,22),(46,23),(46,43),(39,48),(36,43)],'ink')
        poly([(38,24),(44,25),(44,41),(39,45),(38,41)],'metal')
        line([(44,26),(44,41),(39,45)],'bone',2)

def demon(d,f):
    y=int(f in (1,3)); dead=f>=10
    if dead:y=10 if f==10 else 23
    def poly(p,c):d.polygon([(x,min(95,a+y)) for x,a in p],fill=C[c])
    def rect(b,c):d.rectangle((b[0],min(95,b[1]+y),b[2],min(95,b[3]+y)),fill=C[c])
    def line(p,c,w=1):d.line([(x,min(95,a+y)) for x,a in p],fill=C[c],width=w)
    # Asymmetric torn wings create a recognizable broad silhouette.
    poly([(32,31),(16,13),(5,6),(10,32),(4,44),(16,41),(17,55),(29,49),(35,61)],'ink')
    poly([(30,33),(16,17),(9,12),(14,31),(9,40),(19,36),(20,49),(29,44),(33,55)],'red0')
    line([(31,36),(17,21),(14,18),(20,35),(22,45)],'red1',2)
    poly([(64,29),(80,10),(91,6),(85,30),(93,45),(80,40),(79,56),(67,48),(61,60)],'ink')
    poly([(66,32),(80,15),(87,12),(81,31),(88,40),(77,35),(76,50),(67,43),(64,54)],'red1')
    line([(65,36),(80,20),(78,35),(75,44)],'red2',2)
    # Hooves, long thighs and tail.
    line([(57,68),(70,77),(78,72),(84,78)],'ink',6)
    line([(57,68),(70,75),(78,70),(84,78)],'skin1',3)
    poly([(82,74),(88,81),(80,79)],'rust')
    for x,step in [(37,int(f==1)*3),(54,int(f==3)*3)]:
        poly([(x,65),(x+9,66),(x+6,78-step),(x+10,88-step),(x+6,94-step),(x-4,92-step),(x-2,82-step)],'ink')
        poly([(x+1,68),(x+7,68),(x+3,79-step),(x+7,87-step),(x+2,91-step),(x-1,88-step)],'skin1')
        poly([(x-3,88-step),(x+7,87-step),(x+9,93-step),(x-4,93-step)],'iron')
        line([(x,90-step),(x+5,89-step)],'edge')
    poly([(34,31),(47,25),(62,30),(70,46),(62,69),(49,77),(34,68),(28,47)],'ink')
    poly([(35,34),(47,29),(60,33),(65,46),(59,66),(49,72),(37,65),(32,47)],'skin0')
    poly([(36,35),(44,32),(46,46),(40,51),(34,46)],'skin1')
    poly([(50,31),(59,35),(63,45),(55,50),(49,46)],'skin1')
    line([(46,34),(47,58),(50,67)],'skin2',2)
    for a in (50,56,62):line([(38,a),(44,a+2),(48,a+1),(53,a+2),(59,a-1)],'skin1',2)
    # Cracked coal heart and a pale waist ring.
    poly([(45,39),(50,38),(54,44),(49,50),(44,45)],'red0')
    line([(49,40),(47,44),(51,46)],'warm',2)
    line([(36,67),(43,70),(49,68),(57,70),(61,65)],'bone',2)
    # Shoulder spikes and claws. Casting poses have different raised hands.
    for side in (-1,1):
        sx=48+side*20
        poly([(sx-5,32),(sx+2,29),(sx+side*8,37),(sx+side*10,49),(sx+side*16,59),(sx+side*13,67),(sx+side*5,62),(sx,50)],'ink')
        poly([(sx-3,34),(sx+1,32),(sx+side*5,38),(sx+side*6,49),(sx+side*13,59),(sx+side*10,62),(sx+side*3,55)],'skin1')
        poly([(sx-4,32),(sx-2,23),(sx+2,31)],'bone')
        poly([(sx+2,34),(sx+side*10,28),(sx+side*7,38)],'bone')
        for a in range(3):line([(sx+side*(10+a*2),60),(sx+side*(13+a*2),67)],'bone',2)
    # Crown-like split horns and a jaw with visible teeth.
    poly([(37,17),(42,11),(55,11),(62,18),(59,32),(52,38),(42,36),(35,27)],'ink')
    poly([(39,18),(44,13),(54,14),(59,20),(56,30),(50,35),(43,33),(38,26)],'skin1')
    poly([(40,14),(30,9),(28,1),(34,4),(38,8),(43,11)],'ink')
    poly([(40,13),(33,8),(31,3),(35,5),(39,9)],'bone')
    poly([(54,13),(66,8),(68,0),(62,4),(58,8),(52,11)],'ink')
    poly([(55,12),(64,7),(65,3),(61,5),(57,9)],'bone')
    line([(40,21),(45,23)],'ink',3);line([(51,23),(57,20)],'ink',3)
    line([(41,21),(45,22)],'warm');line([(52,22),(56,20)],'warm')
    poly([(43,28),(48,26),(55,27),(53,32),(46,33)],'ink')
    line([(44,28),(53,28)],'bone');line([(46,32),(52,31)],'bone')
    if f in (4,6,7,8,9) and not dead:
        col={4:'warm',6:'gold',7:'cold',8:'purple',9:'rust'}[f]
        for x in (20,76):
            rect((x-4,48,x+4,55),col);rect((x-1,45,x+1,57),'light')
        if f==6:line([(16,44),(22,38),(18,34),(25,27)],col,2)
        if f==7:
            for x in (19,77):line([(x-7,50),(x+7,50)],col);line([(x,43),(x,57)],col)
        if f==8:
            line([(29,76),(48,84),(68,76)],col,2)
    if dead:
        line([(34,44),(47,51),(59,43)],'rust',2)
        for x,a in ((28,38),(63,53),(39,71),(57,66)):rect((x,a,x+2,a+3),'warm')

make_sheet('executioner.png',48,64,8,executioner)
make_sheet('demon.png',96,96,12,demon)
print('executioner: 8 frames 48x64; demon: 12 frames 96x96')
