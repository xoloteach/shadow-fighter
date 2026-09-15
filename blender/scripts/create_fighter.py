"""Original segmented, armature-deformed silhouette fighter. Blender 4.0.2."""
import bpy, math
from mathutils import Vector
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.render.engine = 'BLENDER_EEVEE'
scene.eevee.taa_render_samples = 32
scene.render.resolution_x = scene.render.resolution_y = 320
scene.render.resolution_percentage = 100
scene.render.film_transparent = True
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'
scene.view_settings.view_transform = 'Standard'
scene.render.fps = 100

def material(name, color):
    m = bpy.data.materials.new(name); m.use_nodes = True
    n = m.node_tree.nodes; n.clear()
    out = n.new('ShaderNodeOutputMaterial'); emission = n.new('ShaderNodeEmission')
    emission.inputs[0].default_value = (*color, 1)
    m.node_tree.links.new(emission.outputs[0], out.inputs[0]); return m
body = material('Obsidian ink', (.005, .006, .012))
rim = material('Indigo cloth', (.014, .017, .027))
accent = material('Glacier woven belt', (.0, .58, .8))
# X right, Z up, camera along +Y. All coordinates in meters (100 Godot px/m).
bpy.ops.object.armature_add()
rig = bpy.context.object; rig.name = 'Dusk_Original_Rig'
bpy.ops.object.mode_set(mode='EDIT'); rig.data.edit_bones.remove(rig.data.edit_bones[0])
def bone(name, head, tail, parent=None, deform=True):
    b = rig.data.edit_bones.new(name); b.head=head; b.tail=tail; b.use_deform=deform
    if parent: b.parent=rig.data.edit_bones[parent]
    return b
bone('root',(0,0,0),(0,0,.15),deform=False)
bone('pelvis',(0,0,.57),(0,0,.68),'root')
bone('spine',(0,0,.68),(0,0,.82),'pelvis')
bone('chest',(0,0,.82),(0,0,.99),'spine')
bone('neck',(0,0,.99),(.015,0,1.08),'chest')
bone('head',(.015,0,1.08),(.015,0,1.24),'neck')
for side,y,x in [('front',-.065,.035),('back',.065,-.035)]:
    bone('shoulder_'+side,(0,0,.97),(x,y,.97),'chest')
    elbow=(.16 if side=='front' else -.16,y,.80)
    hand=(.28 if side=='front' else .015,y,.99)
    bone('upper_arm_'+side,(x,y,.97),elbow,'shoulder_'+side)
    bone('forearm_'+side,elbow,hand,'upper_arm_'+side)
    bone('hand_'+side,hand,(hand[0]+.065,y,hand[2]),'forearm_'+side)
    knee=(.16 if side=='front' else -.18,y,.31)
    ankle=(.20 if side=='front' else -.23,y,.045)
    bone('thigh_'+side,(x,y,.60),knee,'pelvis')
    bone('shin_'+side,knee,ankle,'thigh_'+side)
    bone('foot_'+side,ankle,(ankle[0]+.11,y,.035),'shin_'+side)
    bone('hand_IK_'+side,hand,(hand[0],y,hand[2]+.10),'root',False)
    bone('foot_IK_'+side,ankle,(ankle[0],y,ankle[2]+.1),'root',False)
bpy.ops.object.mode_set(mode='OBJECT')
for side in ['front','back']:
    for limb,target in [('forearm','hand'),('shin','foot')]:
        c=rig.pose.bones[limb+'_'+side].constraints.new('IK')
        c.target=rig; c.subtarget=target+'_IK_'+side; c.chain_count=2; c.use_stretch=False
# Rounded overlapping volumes with explicit weights: no disconnected geometry under articulation.
def ellipsoid(name, center, scale, bone_name, mat, direction=None):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, location=center)
    obj=bpy.context.object; obj.name=name
    if direction: obj.rotation_mode='QUATERNION'; obj.rotation_quaternion=Vector(direction).to_track_quat('Z','Y')
    obj.scale=scale; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    obj.data.materials.append(mat)
    for p in obj.data.polygons: p.use_smooth=True
    group=obj.vertex_groups.new(name=bone_name); group.add(list(range(len(obj.data.vertices))),1,'REPLACE')
    mod=obj.modifiers.new('Rig deformation','ARMATURE'); mod.object=rig
    return obj
for name in ['pelvis','spine','chest','neck','head']:
    b=rig.data.bones[name]; center=(b.head_local+b.tail_local)/2
    widths={'pelvis':(.115,.09),'spine':(.095,.08),'chest':(.125,.095),'neck':(.047,.048),'head':(.088,.076)}
    rx,ry=widths[name]
    ellipsoid(name,center,(rx,ry,b.length*.68),name,body)
# Profile nose / chin reads as a human head, not a featureless ball.
ellipsoid('nose',(.101,-.01,1.17),(.028,.043,.025),'head',body)
for side in ['back','front']:
    for part,width in [('upper_arm',.047),('forearm',.040),('hand',.046),('thigh',.074),('shin',.043),('foot',.042)]:
        name=part+'_'+side; b=rig.data.bones[name]; d=b.tail_local-b.head_local
        ellipsoid(name,(b.head_local+b.tail_local)/2,(width,width,b.length/2+width*.55),name,body,d)
    for part in ['forearm','shin']:
        b=rig.data.bones[part+'_'+side]
        ellipsoid('joint_'+part+'_'+side,b.head_local,(.044,.044,.044),part+'_'+side,body)
ellipsoid('belt',(0,-.005,.655),(.12,.10,.023),'pelvis',accent)
ellipsoid('headband',(.015,0,1.195),(.091,.079,.016),'head',accent)
# Small original diagonal gi lapel.
ellipsoid('lapel',(.035,-.096,.84),(.014,.012,.125),'chest',rim,(-.35,0,1))
# Camera remains invariant across all actions.
bpy.ops.object.camera_add(location=(.20,-6,.85))
cam=bpy.context.object; cam.name='Locked_Side_Orthographic'
cam.rotation_euler=(Vector((.20,0,.85))-cam.location).to_track_quat('-Z','Y').to_euler()
cam.data.type='ORTHO'; cam.data.ortho_scale=2.0; scene.camera=cam
# Actions are keyed at 100 Hz only as a time coordinate; rendering samples sparse authored poses.
for name in ['idle','jab']:
    action=bpy.data.actions.new(name); rig.animation_data_create(); rig.animation_data.action=action
    for pb in rig.pose.bones: pb.location=(0,0,0); pb.rotation_mode='XYZ'; pb.rotation_euler=(0,0,0)
    times=[0,.25,.5,.75,1] if name=='idle' else [0,.03,.06,.11,.16,.20,.24]
    for t in times:
        breath=math.sin(t*2*math.pi)*.008 if name=='idle' else 0
        reach=0 if name=='idle' else {0:0,.03:-.035,.06:.22,.11:.23,.16:.22,.20:.08,.24:0}[t]
        # IK hand target translation is in the target bone's local axes (local Y = world Z).
        hand=rig.pose.bones['hand_IK_front']; hand.location=(reach, -.11 if reach>.15 else 0, 0)
        hand.keyframe_insert('location',frame=1+t*100)
        chest=rig.pose.bones['chest']; chest.rotation_euler[1]=-.015 if reach<0 else reach*.07
        chest.keyframe_insert('rotation_euler',frame=1+t*100)
        pelvis=rig.pose.bones['pelvis']; pelvis.location=(reach*.025,breath,0)
        pelvis.keyframe_insert('location',frame=1+t*100)
    for fc in action.fcurves:
        for k in fc.keyframe_points: k.interpolation='BEZIER'; k.handle_left_type=k.handle_right_type='AUTO_CLAMPED'
    action.use_fake_user=True
rig.animation_data.action=bpy.data.actions['idle']
scene.frame_set(1)
path=ROOT/'blender/scenes/fighter.blend'; path.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(path))
print('CREATED original rig:',len(rig.data.bones),'bones; actions idle, jab')
