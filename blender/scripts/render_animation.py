"""blender -b blender/scenes/fighter.blend --python ... -- --animation jab"""
import bpy, sys, argparse, json
from pathlib import Path
root=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser(); p.add_argument('--animation',choices=['idle','jab','all'],default='all')
a=p.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
rig=bpy.data.objects['Dusk_Original_Rig']; scene=bpy.context.scene
for name in (['idle','jab'] if a.animation=='all' else [a.animation]):
    output=root/'blender/renders'/name; output.mkdir(parents=True,exist_ok=True)
    # Only delete this generator's named frames, never recursively delete user directories.
    for old in output.glob(name+'_????.png'): old.unlink()
    times=[i/16 for i in range(16)] if name=='idle' else [0,.03,.06,.12,1/6,.20]
    duration=1.0 if name=='idle' else .24
    rig.animation_data.action=bpy.data.actions[name]
    for pb in rig.pose.bones: pb.location=(0,0,0); pb.rotation_euler=(0,0,0)
    for i,t in enumerate(times):
        frame=1+t*100; scene.frame_set(int(frame),subframe=frame-int(frame))
        scene.render.filepath=str(output/f'{name}_{i+1:04}.png')
        bpy.ops.render.render(write_still=True)
        assert Path(scene.render.filepath).stat().st_size>0
    data={'animation':name,'times':times,'duration':duration,'loop':name=='idle','pivot':[128,296], 'game_scale':.625,
          'combat':{} if name=='idle' else {'state':'punch_1','startup':.06,'active_end':.16,'recovery_end':.24}}
    (output/'timing.json').write_text(json.dumps(data,indent=2))
    print('RENDERED',name,len(times),'transparent frames')
