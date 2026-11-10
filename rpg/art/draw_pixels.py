"""Draw ART-1.0 source pixels. Godot loads the committed PNGs directly."""
from pathlib import Path
from random import Random
from PIL import Image, ImageDraw

OUT = Path(__file__).parent
INK, NIGHT, STEEL, SLATE, MIST, BONE, SOOT, BRASS, FLESH, ROSE, TEAL, CYAN, RUST, AMBER, RED, VIOLET = (
    '#07141F', '#102738', '#244454', '#49616B', '#829499', '#DFE8D5', '#493B37', '#897451',
    '#492C42', '#9C626C', '#237C83', '#57E4CE', '#AA693A', '#FFC46B', '#FF526D', '#A58ADC')


def poly(d, points, color):
    d.polygon(points, fill=color)


def slab(d, x, y, w, h):
    d.rectangle((x, y, x+w, y+h), fill=INK)
    poly(d, [(x+1,y+5),(x+8,y),(x+w,y),(x+w-5,y+5)], SLATE)
    d.rectangle((x+2,y+6,x+w-3,y+h-2), fill=STEEL)
    d.line((x+3,y+h-4,x+w-5,y+h-4), fill=NIGHT)
    for bolt in (x+6, x+w-7):
        d.rectangle((bolt,y+9,bolt+2,y+10), fill=MIST)
        d.point((bolt,y+h-7),fill=INK)


def pipe(d, points, tone, edge, width=7):
    d.line(points, fill=INK, width=width+4, joint='curve')
    d.line(points, fill=tone, width=width, joint='curve')
    d.line([(x,y-2) for x,y in points], fill=edge, width=2, joint='curve')


def doorway(d, x):
    poly(d,[(x-38,143),(x-38,91),(x-25,75),(x+24,75),(x+38,91),(x+38,143)], INK)
    poly(d,[(x-33,141),(x-33,92),(x-21,80),(x+22,80),(x+34,93),(x+34,141)], STEEL)
    poly(d,[(x-26,142),(x-26,96),(x-17,87),(x+18,87),(x+27,96),(x+27,142)], NIGHT)
    d.line([(x-34,125),(x-34,93),(x-22,81),(x+20,81)], fill=MIST,width=2)
    for side in (-1,1):
        x2=x+side*32
        d.rectangle((x2-2,107,x2+2,128),fill=INK)
        d.rectangle((x2-1,109,x2+1,120),fill=BRASS)


def factory(name, room, changed=False):
    rng = Random(17+room)
    im = Image.new('RGB', (640,360), INK)
    d = ImageDraw.Draw(im)
    poly(d,[(74,103),(98,75),(542,75),(567,103),(574,295),(548,320),(92,320),(66,296)],NIGHT)
    # Repeat stamped steel floor panels and keep the center comparatively quiet.
    d.rectangle((99,130,540,297), fill=STEEL)
    for y in range(130,297,32):
        for x in range(99-(16 if y%64==2 else 0),541,32):
            a,b = max(x,99),min(x+30,540)
            c = min(y+30,297)
            if a >= b:
                continue
            d.rectangle((a,y,b,c), fill=rng.choice([STEEL,STEEL,STEEL,SLATE]), outline=NIGHT)
            d.line((a+1,y+1,b-1,y+1),fill=STEEL)
            for _ in range(rng.randrange(3)):
                u,v=rng.randint(a,b),rng.randint(y,c)
                d.line((u,v,min(u+rng.randrange(1,5),b),v),fill=STEEL)
            if b-a>12:
                d.point((a+3,y+3),fill=MIST)
    # Floor falloff under the back wall, with a hard ledge and distinct surface.
    d.rectangle((90,117,551,137),fill=NIGHT)
    d.line((102,138,538,138), fill=STEEL,width=2)
    for x in range(99,540,48):
        slab(d,x,70,45,57)
        d.rectangle((x+11,83,min(x+31,542),105),fill=NIGHT)
        for o in (0,4,8):
            d.line((x+14,91+o,x+28,91+o),fill=STEEL)
    d.rectangle((87,63,553,71),fill=STEEL)
    d.line((105,63,530,63),fill=MIST)
    pipe(d,[(62,113),(80,113),(92,101),(92,64),(114,42),(534,42),(553,61),(553,103),(564,114),(578,114)], STEEL, SLATE, 11)
    pipe(d,[(88,122),(107,104),(107,55),(123,39),(490,39),(514,63),(514,70)], SOOT, BRASS, 5)
    for x in (138,215,291,370,448,504):
        slab(d,x,35,12,15)
        d.line((x+2,53,x+9,53),fill=BRASS)
    for x in (52,556):
        slab(d,x,124,32,159)
        for y in range(142,269,17):
            d.rectangle((x+7,y,x+23,y+9),fill=NIGHT)
            d.line((x+8,y+1,x+22,y+1),fill=SLATE)
        pipe(d,[(x+10,125),(x+26,141),(x+26,268),(x+17,277)], STEEL, SLATE, 5)
    # Small interrupted safety markings and paired floor lanterns.
    for x in range(99,540,14):
        d.line((x,298,x+6,298),fill=BRASS,width=2)
    for x in (95,545):
        for y in (151,224,283):
            d.rectangle((x-3,y,x+3,y+8),fill=INK)
            d.rectangle((x-1,y+2,x+1,y+5),fill=AMBER)
    if room == 0:
        doorway(d,171)
        doorway(d,463)
        for x,y in [(298,244),(298,220),(298,196),(407,204),(435,185),(446,166)]:
            d.line((x,y,x+10,y),fill=BRASS,width=3)
        slab(d,250,74,130,45)
        for x in range(264,365,16):
            d.rectangle((x,87,x+10,103),fill=NIGHT)
            d.line((x+2,96,x+7,96),fill=TEAL)
        if changed:
            pipe(d,[(172,80),(186,65),(215,65),(226,52),(305,52),(322,70),(322,85)],FLESH,ROSE,6)
            for x,y in [(197,66),(232,53),(276,53),(315,65)]:
                d.ellipse((x-4,y-3,x+6,y+4),fill=FLESH)
                d.point((x+1,y-1),fill=VIOLET)
    elif room == 1:
        for x in (228,395):
            slab(d,x,78,18,87)
            pipe(d,[(x+8,61),(x+8,151)],SOOT,BRASS,5)
        for x in (151,484):
            slab(d,x-22,104,43,23)
            d.rectangle((x-10,114,x+10,118),fill=TEAL)
        for x in range(246,397,18):
            d.line((x,152,x+6,145),fill=BRASS,width=2)
    else:
        slab(d,221,72,193,45)
        for k,x in enumerate((237,277,317,357)):
            d.rectangle((x,84,x+24,111),fill=FLESH)
            pipe(d,[(x+12,103),(x+12,126),(288+k*16,151)],FLESH,ROSE,5)
            d.rectangle((x+9,93,x+15,100),fill=VIOLET)
        pipe(d,[(111,111),(137,92),(137,61),(164,44),(441,44),(470,72),(470,108),(520,137)],FLESH,ROSE,8)
        for x in (210,302,394,470):
            d.ellipse((x-7,40,x+9,51),fill=FLESH)
            d.line((x-2,46,x+5,46),fill=VIOLET)
    # Near silhouettes bookend the view without hiding the walkable floor.
    for x,y in [(35,292),(93,316),(502,318),(555,292)]:
        slab(d,x,y,56,27)
        d.rectangle((x+10,y+11,x+44,y+14),fill=NIGHT)
    for x in range(114,535,38):
        d.rectangle((x,313,x+4,328),fill=STEEL)
    pipe(d,[(101,323),(537,323)],NIGHT,STEEL,5)
    im.save(OUT/name)


def worker(d, x, y, face, frame):
    # 32x48 sprite cell, 24x40 body with feet anchored at (16,44).
    step = [0, 2, 3, 0, -2, -3][frame]
    bob = abs(step)//2
    def r(rect, c):
        a,b,e,f=rect
        d.rectangle((x+a,y+b-bob,x+e,y+f-bob),fill=c)
    def p(points,c):
        poly(d,[(x+a,y+b-bob) for a,b in points],c)
    r((9,29,14,42+step), NIGHT)
    r((17,29,22,42-step), NIGHT)
    r((9,41+step,14,43+step), INK)
    r((17,41-step,22,43-step), INK)
    p([(8,15),(12,12),(20,12),(25,16),(27,29),(22,35),(8,34),(5,28)],INK)
    p([(9,16),(13,13),(20,14),(24,17),(25,28),(21,32),(9,32),(7,27)],MIST)
    p([(9,18),(13,16),(13,31),(9,31),(7,27)],SLATE)
    p([(19,15),(23,17),(24,27),(21,30),(18,29)],STEEL)
    r((12,4,21,12),INK)
    r((12,5,20,8),BRASS)
    r((11,7,21,8),SLATE)
    r((13,9,20,13),BRASS if face != 0 else SOOT)
    if face != 0:
        r((14 if face != 3 else 19,10,15 if face != 3 else 20,10),INK)
    if face in (1,2):
        r((8,21,12,30),SOOT)
        r((9,22,11,23),BRASS)
    else:
        r((21,21,26,29),SOOT)
        r((21,22,24,23),BRASS)
    r((11,17,12,23),INK)
    r((11,17,12,20),CYAN)
    r((14,16,16,17),BONE)
    if face == 0:
        r((13,23,19,26),STEEL)
        r((13,23,15,24),BONE)


def press():
    im = Image.new('RGBA',(96,96))
    d = ImageDraw.Draw(im)
    poly(d,[(9,72),(9,25),(22,15),(63,15),(79,24),(88,49),(88,74),(74,87),(18,87)],INK)
    slab(d,13,26,68,52)
    slab(d,19,15,45,20)
    slab(d,63,23,18,49)
    for x in (24,32,40,48,56):
        d.rectangle((x,19,x+3,25),fill=NIGHT)
    pipe(d,[(17,64),(21,57),(21,36),(27,30),(53,30),(63,39),(63,72)],SOOT,BRASS,5)
    slab(d,25,48,36,29)
    d.rectangle((30,56,55,69),fill=NIGHT)
    d.rectangle((33,59,52,65),fill=TEAL)
    d.line((34,59,48,59),fill=MIST)
    for x in (18,72):
        slab(d,x-4,72,15,14)
        d.rectangle((x,78,x+7,81),fill=BRASS)
    im.save(OUT/'press.png')


factory('intake.png',0)
factory('intake-return.png',0,True)
factory('press-hall.png',1)
factory('bypass.png',2)
atlas=Image.new('RGBA',(192,192))
atlas_draw=ImageDraw.Draw(atlas)
for direction in range(4):
    for pose in range(6):
        worker(atlas_draw,pose*32,direction*48,direction,pose)
atlas.save(OUT/'worker.png')
press()
