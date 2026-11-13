"""Index original animation/module PNGs. This writes metadata only, never image pixels."""
from pathlib import Path
from PIL import Image
import json
ROOT = Path(__file__).parent / 'modular'
textures, regions, clips, metadata = [], [], [], {}

def cells(file, columns, rows):
    image = Image.open(ROOT/file).convert('RGBA')
    result=[]
    for row in range(rows):
        line=[]
        for col in range(columns):
            x0,y0 = round(col*image.width/columns),round(row*image.height/rows)
            x1,y1 = round((col+1)*image.width/columns),round((row+1)*image.height/rows)
            bounds=image.getchannel('A').crop((x0,y0,x1,y1)).point(lambda a:255 if a>=128 else 0).getbbox()
            assert bounds, (file,row,col)
            x,y,w,h=bounds[0]+x0,bounds[1]+y0,bounds[2]-bounds[0],bounds[3]-bounds[1]
            line.append({'region':[x,y,w,h], 'origin':[(x0+x1)/2-x,h], 'cell':[x0,y0,x1-x0,y1-y0]})
        result.append(line)
    return result

for file, columns, rows, names in [('09-walk.png',6,2,['walk-front','walk-back']),('09-actions.png',4,4,['arc','ranged','dash','death'])]:
    sheet_id='walk' if columns==6 else 'actions'
    textures.append(f'[ext_resource type="Texture2D" path="res://art/modular/{file}" id="{sheet_id}"]')
    grid=cells(file,columns,rows)
    height=max(frame['region'][3] for row in grid for frame in row)
    grips=[[(.75,.46)]*6,[(.72,.46)]*6] if columns==6 else [[(.37,.64),(.69,.48),(.85,.29),(.65,.40)],[(.65,.66),(.63,.38),(.58,.41),(.65,.40)],[(.73,.68),(.73,.56),(.74,.68),(.65,.40)],[(.69,.49),(.79,.72),(.63,.85),(.50,.92)]]
    for row,name in enumerate(names):
        entries=[]
        metadata[name]=[]
        for col,frame in enumerate(grid[row]):
            x,y,w,h=frame['region'];x0,y0,cw,ch=frame.pop('cell')
            frame['scale']=48/height
            gx,gy=grips[row][col]
            frame['grip']=[x0+gx*cw-x,y0+gy*ch-y]
            metadata[name].append(frame)
            key=f'{name}_{col}'.replace('-','_')
            regions.append(f'[sub_resource type="AtlasTexture" id="{key}"]\natlas = ExtResource("{sheet_id}")\nregion = Rect2({x},{y},{w},{h})\nfilter_clip = true')
            entries.append(f'{{"duration":1.0,"texture":SubResource("{key}")}}')
        clips.append('{"frames":['+','.join(entries)+f'],"loop":{str(name.startswith("walk")).lower()},"name":&"{name}","speed":12.0'+'}')
(ROOT/'09.tres').write_text('\n\n'.join(['[gd_resource type="SpriteFrames" format=3]',*textures,*regions,'[resource]\nanimations = ['+',\n'.join(clips)+']'])+'\n',encoding='utf8')
(ROOT/'09.json').write_text(json.dumps(metadata,indent=2)+'\n',encoding='utf8')
module_names=['floor','hatch','wall-open','wall-vent','column','conduit','elbow','rail','armor','piston','heart-cage','lamp']
module_data={}
for name,frame in zip(module_names,[f for row in cells('factory-kit.png',4,3) for f in row]):
    x,y,w,h=frame['region'];module_data[name]=frame['region']
    (ROOT/(name+'.tres')).write_text(f'[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n[ext_resource type="Texture2D" path="res://art/modular/factory-kit.png" id="1"]\n\n[resource]\natlas = ExtResource("1")\nregion = Rect2({x},{y},{w},{h})\nfilter_clip = true\n',encoding='utf8')
(ROOT/'modules.json').write_text(json.dumps(module_data,indent=2)+'\n',encoding='utf8')
enemy_metadata={}
for kind,box in [('husk',(54,38)),('worker',(40,48)),('sentinel',(64,67))]:
    frames=[frame for row in cells(kind+'-motion.png',4,3) for frame in row]
    scale=min(box[0]/max(f['region'][2] for f in frames),box[1]/max(f['region'][3] for f in frames))
    subresources=[];entries=[]
    for i,frame in enumerate(frames):
        frame.pop('cell');frame['scale']=scale
        x,y,w,h=frame['region']
        subresources.append(f'[sub_resource type="AtlasTexture" id="frame_{i}"]\natlas = ExtResource("1")\nregion = Rect2({x},{y},{w},{h})\nfilter_clip = true')
        entries.append(f'{{"duration":1.0,"texture":SubResource("frame_{i}")}}')
    (ROOT/(kind+'.tres')).write_text('\n\n'.join(['[gd_resource type="SpriteFrames" format=3]',f'[ext_resource type="Texture2D" path="res://art/modular/{kind}-motion.png" id="1"]',*subresources,'[resource]\nanimations = [{"frames":['+','.join(entries)+'],"loop":false,"name":&"body","speed":12.0}]'])+'\n',encoding='utf8')
    enemy_metadata[kind]=frames
(ROOT/'creatures.json').write_text(json.dumps(enemy_metadata,indent=2)+'\n',encoding='utf8')
print('Indexed 64 character/enemy frames and 12 independent construction modules.')
