"""Union trim per animation, fixed pivot, 2px gutters; deterministic <=2048 atlases."""
from pathlib import Path
from PIL import Image, ImageDraw
import json, math
root=Path(__file__).resolve().parents[1]
out=root/'assets/blender'; out.mkdir(parents=True,exist_ok=True)
qa=root/'qa/blender'; qa.mkdir(parents=True,exist_ok=True)
library={}
for name in ['idle','jab']:
    source=root/'blender/renders'/name
    meta=json.loads((source/'timing.json').read_text())
    frames=[Image.open(p).convert('RGBA') for p in sorted(source.glob(name+'_????.png'))]
    bounds=[im.getchannel('A').getbbox() for im in frames]; assert all(bounds)
    box=(min(b[0] for b in bounds)-2,min(b[1] for b in bounds)-2,max(b[2] for b in bounds)+2,max(b[3] for b in bounds)+2)
    assert box[0]>=0 and box[1]>=0 and box[2]<=320 and box[3]<=320, 'Camera clipping'
    w,h=box[2]-box[0],box[3]-box[1]; cols=min(8,2048//(w+4)); rows=math.ceil(len(frames)/cols)
    atlas=Image.new('RGBA',(cols*(w+4),rows*(h+4)))
    rects=[]
    preview=Image.new('RGB',(cols*220,rows*290),(105,112,133)); draw=ImageDraw.Draw(preview)
    for i,im in enumerate(frames):
        x=(i%cols)*(w+4)+2; y=(i//cols)*(h+4)+2
        crop=im.crop(box); atlas.paste(crop,(x,y)); rects.append([x,y,w,h])
        crop.thumbnail((210,250)); px=(i%cols)*220; py=(i//cols)*290
        preview.paste(crop,(px+5,py+25),crop)
        draw.text((px+5,py+5),f'{name} {meta["times"][i]:.3f}s',fill='white')
    assert max(atlas.size)<=2048
    atlas.save(out/f'{name}.png',optimize=True)
    atlas.save(root/f'blender/spritesheets/{name}.png',optimize=True)
    preview.save(qa/f'{name}-contact.png')
    meta.update({'texture':f'res://assets/blender/{name}.png','rects':rects,'pivot':[meta['pivot'][0]-box[0],meta['pivot'][1]-box[1]],'atlas_size':list(atlas.size)})
    library[name]=meta
(out/'library.json').write_text(json.dumps(library,indent=2))
print(json.dumps({n:{'atlas':d['atlas_size'],'frames':len(d['rects'])} for n,d in library.items()},indent=2))
