"""Original ART-1.0 assets informed by the two approved prototype boards."""
from pathlib import Path
from random import Random
from PIL import Image, ImageDraw

OUT = Path(__file__).parent / 'expedition'
OUT.mkdir(exist_ok=True)
INK, NIGHT, STEEL, SLATE, MIST, BONE = '#07141F', '#102738', '#244454', '#49616B', '#829499', '#DFE8D5'
FLESH, ROSE, CYAN, AMBER, RED, VIOLET = '#492C42', '#9C626C', '#57E4CE', '#FFC46B', '#FF526D', '#A58ADC'

def plate(d, box):
    x,y,w,h = box
    d.rectangle((x,y,x+w,y+h), fill=INK)
    d.polygon([(x,y+5),(x+5,y),(x+w,y),(x+w,y+h),(x,y+h)], fill=STEEL)
    d.line((x+4,y+4,x+w-3,y+4), fill=MIST)
    d.line((x+w-2,y+6,x+w-2,y+h-2), fill=NIGHT, width=3)
    for u,v in [(x+5,y+9),(x+w-6,y+h-5)]: d.rectangle((u,v,u+2,v+2), fill=SLATE)

def tube(d, points, flesh=True, width=7):
    d.line(points, fill=INK, width=width+4, joint='curve')
    d.line(points, fill=FLESH if flesh else STEEL, width=width, joint='curve')
    d.line([(x-1,y-2) for x,y in points], fill=ROSE if flesh else SLATE, width=2, joint='curve')

def heart(d, x,y, scale=1):
    pts=[(-13,-5),(-10,-14),(-3,-16),(2,-10),(8,-17),(16,-12),(19,-3),(15,10),(5,23),(-5,15)]
    p=[(x+a*scale,y+b*scale) for a,b in pts]
    d.polygon(p,fill=INK)
    d.polygon([(x+a*scale*.85,y+b*scale*.85) for a,b in pts],fill=FLESH)
    d.line([(x-6*scale,y-9*scale),(x+1*scale,y-3*scale),(x+4*scale,y+16*scale)],fill=ROSE,width=max(1,2*scale))
    d.line([(x+11*scale,y-8*scale),(x+7*scale,y+4*scale)],fill=RED,width=scale)

def environment(name, variant):
    rng=Random(90+variant)
    im=Image.new('RGB',(640,360),INK); d=ImageDraw.Draw(im)
    d.polygon([(75,95),(105,61),(538,61),(565,94),(565,301),(538,320),(100,320),(75,296)],fill=NIGHT)
    d.rectangle((103,132,536,298),fill=STEEL)
    for y in range(132,298,28):
        for x in range(103,534,36):
            c=SLATE if rng.random()<.12 else STEEL
            d.rectangle((x+1,y+1,min(x+34,535),min(y+26,297)),fill=c,outline=NIGHT)
            d.line((x+3,y+3,min(x+30,533),y+3),fill=STEEL)
    for x in range(101,537,54):
        plate(d,(x,61,49,67))
        d.rectangle((x+8,74,x+41,112),fill=NIGHT)
        for v in range(80,108,7): d.line((x+14,v,x+35,v),fill=STEEL)
    for x in [76,548]:
        plate(d,(x,121,18,174))
        for y in [142,214,280]: d.rectangle((x+6,y,x+10,y+5),fill=AMBER)
    for y in [143,294]:
        d.line((111,y,527,y),fill=NIGHT,width=2)
    for x in range(112,531,17): d.line((x,303,x+7,303),fill=AMBER,width=2)
    # Exposed organs stay above the walk plane; paths retain quiet broad masses.
    for x in [157,477]:
        tube(d,[(x,47),(x,90),(x+18,104),(x+18,124)],True,9)
    if variant in [0,1,2,3]:
        plate(d,(245,54,148,69))
        if variant==0:
            for i in range(5):
                d.ellipse((278+i*5,60+i*5,362-i*5,116-i*5),fill=FLESH,outline=ROSE)
            d.ellipse((307,78,336,110),fill=INK)
        elif variant==1:
            for x in [265,324]:
                plate(d,(x,67,45,51)); tube(d,[(x+12,51),(x+12,81),(x+32,97)],True,8)
                d.rectangle((x+8,105,x+36,108),fill=AMBER)
        else:
            heart(d,320,76,2)
            for x in [258,380]: tube(d,[(320,59),(x,51),(x,111)],True,6)
    if variant==4:
        for x in [273,326]:
            d.polygon([(x,62),(x-24,74),(x-28,112),(x-13,120),(x+14,110),(x+17,70)],fill=FLESH,outline=ROSE)
        tube(d,[(320,46),(320,80),(280,98)],False)
        tube(d,[(320,80),(348,98)],False)
    if variant==5:
        plate(d,(253,52,134,77)); d.rectangle((266,62,374,116),fill=INK)
        for x in [278,309,340,368]: tube(d,[(x,44),(x,94),(320,119)],True,5)
        plate(d,(149,155,43,30)); plate(d,(453,155,43,30))
        tube(d,[(320,121),(320,149),(320,180)],False,10)
    if variant!=5:
        plate(d,(479,94,42,39)); d.rectangle((490,102,510,132),fill=INK)
        d.rectangle((494,114,506,119),fill=AMBER)
    # Differentiated floor hardware marks each encounter without adding blind collision.
    if variant==1:
        for x,y in [(186,230),(392,251)]:
            d.rectangle((x,y,x+58,y+12),fill=NIGHT)
            for dx in range(3,56,8): d.line((x+dx,y+2,x+dx,y+10),fill=SLATE)
    if variant==2:
        for x in [176,462]: tube(d,[(x,125),(x,172),(x-13,191)],True,5)
    im.save(OUT/(name+'.png'))

def creatures():
    for kind in ['husk','worker','sentinel']:
        im=Image.new('RGBA',(192,64)); d=ImageDraw.Draw(im)
        for f in range(3):
            x=f*64; y=3 if f==1 else 0
            if kind=='husk':
                for a,b in [(10,49),(39,48)]:
                    d.line((x+a,38+y,x+a-5,51+y,x+b,53+y),fill=ROSE,width=3)
                d.polygon([(x+10,33+y),(x+18,23+y),(x+39,24+y),(x+47,35+y),(x+34,43+y),(x+12,40+y)],fill=FLESH,outline=INK)
                d.polygon([(x+9,31+y),(x+17,25+y),(x+25,29+y),(x+24,37+y),(x+7,38+y)],fill=SLATE)
                d.rectangle((x+10,31+y,x+13,33+y),fill=RED)
                tube(d,[(x+29,28+y),(x+36,15+y),(x+44,18+y),(x+46,9+y)],True,3)
                for a in [28,35,42]: d.rectangle((x+a,29+y,x+a+3,32+y),fill=VIOLET)
            elif kind=='worker':
                d.line((x+25,41,x+22,55),fill=SLATE,width=6); d.line((x+35,41,x+39,55),fill=SLATE,width=6)
                d.rectangle((x+20,53,x+26,56),fill=INK); d.rectangle((x+36,53,x+43,56),fill=INK)
                d.polygon([(x+24,19+y),(x+36,20+y),(x+40,42),(x+20,42)],fill=SLATE,outline=INK)
                d.rectangle((x+26,11+y,x+35,20+y),fill=BONE)
                d.rectangle((x+22,8+y,x+38,13+y),fill=STEEL); d.line((x+20,14+y,x+40,14+y),fill=MIST,width=2)
                d.line((x+22,25+y,x+14,37+y),fill=ROSE,width=4)
                d.line((x+14,37+y,x+8,45+y),fill=MIST,width=3)
                tube(d,[(x+35,18+y),(x+43,24+y),(x+38,33+y)],True,4)
                d.rectangle((x+28,27+y,x+30,30+y),fill=RED)
            else:
                for a in [20,40]: d.line((x+a,36+y,x+a,52),fill=ROSE,width=5)
                d.polygon([(x+25,15+y),(x+40,18+y),(x+44,41+y),(x+24,46+y),(x+16,31+y)],fill=STEEL,outline=INK)
                d.line((x+28,18+y,x+40,23+y),fill=MIST,width=2)
                d.rectangle((x+27,24+y,x+37,28+y),fill=RED)
                d.polygon([(x+8,24+y),(x+19,21+y),(x+22,45+y),(x+9,47+y)],fill=SLATE,outline=INK)
                d.line((x+9,30+y,x+18,28+y),fill=AMBER,width=2)
                tube(d,[(x+37,18+y),(x+44,13+y),(x+51,29+y),(x+48,40+y)],True,4)
        im.save(OUT/(kind+'.png'))

def weapons():
    for kind in ['arc','probe','nailer']:
        im=Image.new('RGBA',(64,32)); d=ImageDraw.Draw(im)
        if kind=='arc':
            plate(d,(10,11,26,9)); d.rectangle((4,14,13,17),fill=MIST)
            d.polygon([(34,10),(55,8),(59,11),(55,17),(35,18)],fill=CYAN,outline=INK)
            d.line((36,11,53,10,56,12),fill=BONE,width=1)
            tube(d,[(11,18),(12,25),(23,26),(26,20)],True,3)
        elif kind=='probe':
            plate(d,(3,12,44,6)); d.line((13,10,39,10),fill=MIST,width=2)
            d.polygon([(46,10),(62,15),(46,19)],fill=ROSE,outline=INK)
            d.line((47,14,58,15),fill=BONE)
            tube(d,[(8,20),(16,25),(27,25),(32,19)],True,2)
        else:
            plate(d,(7,8,36,14)); d.rectangle((15,21,22,29),fill=SLATE)
            d.rectangle((43,12,57,17),fill=MIST); d.line((12,10,37,10),fill=AMBER,width=2)
            tube(d,[(10,21),(8,26),(29,26),(34,21)],True,2)
        im.save(OUT/('weapon-'+kind+'.png'))
    im=Image.new('RGBA',(48,48)); d=ImageDraw.Draw(im); heart(d,23,19); im.save(OUT/'heart.png')
    for kind in ['plating','capacitor']:
        im=Image.new('RGBA',(64,32)); d=ImageDraw.Draw(im)
        if kind=='plating':
            d.polygon([(17,3),(45,3),(42,22),(31,29),(20,22)],fill=SLATE,outline=INK)
            d.line((21,6,41,6,38,20,31,25),fill=MIST,width=2)
            d.rectangle((27,9,34,15),fill=CYAN)
        else:
            plate(d,(20,4,24,23)); d.rectangle((25,8,38,22),fill=NIGHT)
            for y in [10,15,20]: d.line((26,y,37,y),fill=CYAN,width=2)
            for x in [15,47]: d.line((x,9,x,24),fill=MIST,width=3)
        im.save(OUT/('gear-'+kind+'.png'))

for name,v in [('field0',0),('field1',1),('field2',2),('boss',3),('preview',4),('hub',5)]: environment(name,v)
creatures(); weapons()
