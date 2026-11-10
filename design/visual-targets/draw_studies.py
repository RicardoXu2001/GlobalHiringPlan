"""Original composition diagrams. No reference pixels or production assets used."""
from pathlib import Path
import hashlib
from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent
P = ['#07141F','#102738','#244454','#49616B','#829499','#DFE8D5',
     '#493B37','#897451','#492C42','#9C626C','#237C83','#57E4CE',
     '#AA693A','#FFC46B','#FF526D','#A58ADC']
font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 12)
big = ImageFont.truetype('C:/Windows/Fonts/consolab.ttf', 22)

def box(d, rect, c, outline=None, width=1):
    d.rectangle(rect, fill=P[c] if c is not None else None,
                outline=P[outline] if outline is not None else None, width=width)

def label(d, xy, text, c=5, large=False):
    d.text(xy, text, font=big if large else font, fill=P[c])

def worker(d,x,y):
    box(d,(x-12,y+1,x+13,y+5),0)
    box(d,(x-7,y-13,x-2,y),0); box(d,(x+3,y-13,x+8,y),0)
    d.polygon([(x-8,y-29),(x+7,y-29),(x+11,y-11),(x-10,y-11)], fill=P[4])
    box(d,(x-6,y-39,x+5,y-30),0); box(d,(x-5,y-36,x+4,y-30),7)
    box(d,(x-7,y-40,x+5,y-37),3); box(d,(x+7,y-24,x+13,y-14),6)
    box(d,(x-6,y-26,x-4,y-20),11); box(d,(x-3,y-28,x+1,y-23),5)

def machine(d,x,y,organic=False):
    # Offset press: two separate supports, horizontal supply stack, no reference gate.
    box(d,(x,y,x+128,y+98),0)
    box(d,(x+9,y+8,x+29,y+88),2); box(d,(x+101,y+18,x+116,y+98),2)
    for j in range(3):
        yy=y+14+j*22
        box(d,(x+25,yy,x+109,yy+14),3,4)
        box(d,(x+39,yy+4,x+85,yy+10),8 if organic else 1)
        box(d,(x+88,yy+4,x+96,yy+10),15 if organic else 10)
    box(d,(x+47,y+78,x+89,y+87),7)
    if organic:
        for k in range(3):
            d.line([(x+48+k*11,y+32),(x+41+k*12,y+65),(x+54+k*9,y+95)], fill=P[9],width=3)

def room():
    im=Image.new('RGB',(640,360),P[0]); d=ImageDraw.Draw(im)
    box(d,(52,50,598,312),1)
    box(d,(80,118,568,304),3)
    for y in (160,208,256,302): d.line((80,y,568,y),fill=P[2])
    for x in (80,176,272,368,464,568): d.line((x,118,x,304),fill=P[2])
    for x in (68,564):
        box(d,(x,66,x+13,300),0); box(d,(x+2,66,x+6,300),2)
    for x in (112,220,330,440):
        box(d,(x,64,x+58,104),2); box(d,(x+5,70,x+53,91),1)
        d.line((x+6,98,x+48,98),fill=P[4])
    return im,d

im,d=room()
box(d,(0,0,330,359),0)
label(d,(36,78),'BOSS & COMPANY',large=True)
label(d,(38,112),'INDUSTRIAL / ORGANIC / PIXEL',4)
for y,t in [(176,'CONTINUE'),(208,'NEW RUN'),(240,'SETTINGS')]:
    label(d,(54,y),t,11 if y==176 else 4)
d.line([(44,175),(38,175),(38,191),(44,191)],fill=P[11],width=2)
machine(d,392,124,True); worker(d,370,280)
for x in (360,410,460): box(d,(x,298,x+12,300),13)
label(d,(36,320),'01  TITLE / MENU PROTECTION',4)
im.save(OUT/'01-title.png')

im,d=room()
machine(d,412,92)
box(d,(282,60,344,125),0); box(d,(288,60,338,64),13)
for y in (140,180,220):
    box(d,(296,y,300,y+8),13); box(d,(332,y,336,y+8),13)
box(d,(392,196,422,228),0,4); box(d,(397,201,417,212),10)
box(d,(401,203,413,209),11)
d.line([(389,193),(385,193),(385,231),(389,231)],fill=P[11],width=2)
worker(d,316,264)
box(d,(100,208,230,268),2); box(d,(108,214,222,252),1)
for x in (119,151,183): box(d,(x,218,x+14,246),7)
box(d,(16,14,230,42),0); label(d,(25,22),'OBJECTIVE / NEXT ROUTE',5)
box(d,(441,14,624,42),0); label(d,(449,22),'NOTICE RESERVE',4)
box(d,(16,322,246,348),0); label(d,(25,329),'PLAYER STATE RESERVE',4)
label(d,(380,274),'INTERACTION',11); label(d,(286,77),'ROUTE',13)
im.save(OUT/'02-exploration.png')

im,d=room()
machine(d,368,74,True)
# Teethed threat boundary as a diagram of reserved readability, not a combat design.
d.polygon([(303,196),(451,196),(502,285),(252,285)],fill=P[8])
for x in range(273,440,20): d.line((x,278,x+32,238),fill=P[9],width=1)
d.line([(303,196),(451,196),(502,285),(252,285),(303,196)],fill=P[14],width=2)
for x in range(272,482,24): d.line((x,285,x+5,291,x+10,285),fill=P[14],width=2)
worker(d,223,271)
for x,y in [(326,183),(482,181),(450,300)]:
    box(d,(x,y,x+4,y+4),5); box(d,(x+8,y+5,x+10,y+7),13)
box(d,(318,152,480,176),0); label(d,(327,158),'INTENT RESERVE',5)
box(d,(16,14,240,42),0); label(d,(25,22),'OBJECTIVE RESERVE',4)
box(d,(16,322,246,348),0); label(d,(25,329),'PLAYER STATE RESERVE',4)
label(d,(88,284),'PLAYER CLEAR',5)
im.save(OUT/'03-pressure.png')

board=Image.new('RGB',(1328,924),P[0]); b=ImageDraw.Draw(board)
label(b,(24,18),'ART-1.0 / COMPOSITION STUDIES',large=True)
label(b,(24,50),'640 x 360 WORLD GRID / ORIGINAL DIAGRAMS / NOT PRODUCTION ART',4)
for i,name in enumerate(['01-title.png','02-exploration.png','03-pressure.png']):
    x,y=[(16,90),(672,90),(16,474)][i]
    board.paste(Image.open(OUT/name),(x,y))
label(b,(696,492),'LOCKED PALETTE',large=True)
for i,c in enumerate(P):
    x=696+(i%4)*148; y=548+(i//4)*70
    b.rectangle((x,y,x+126,y+32),fill=c,outline=P[4])
    label(b,(x,y+38),c,5)
label(b,(696,850),'CYAN: USE / AMBER: ROUTE',11)
label(b,(696,874),'RED: THREAT / VIOLET: ANOMALY',5)
board.save(OUT/'art-direction-board.png')
manifest=[]
for p in sorted(OUT.glob('*.png')):
    manifest.append(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.name)
(OUT/'SHA256SUMS.txt').write_text('\n'.join(manifest)+'\n',encoding='utf-8')
print('Created 3 composition studies, palette board, and hashes.')
