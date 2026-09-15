"""Author all core movement, attack, defense, and reaction animations for Dusk_Original_Rig. Blender 4.0.2."""
import bpy, math
from mathutils import Vector
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
blend_path = ROOT / 'blender/scenes/fighter.blend'

bpy.ops.wm.open_mainfile(filepath=str(blend_path))
rig = bpy.data.objects['Dusk_Original_Rig']

def get_or_create_action(name):
    if name in bpy.data.actions:
        bpy.data.actions.remove(bpy.data.actions[name])
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    return action

def reset_pose():
    for pb in rig.pose.bones:
        pb.location = (0, 0, 0)
        pb.rotation_mode = 'XYZ'
        pb.rotation_euler = (0, 0, 0)

def key_bone(bone_name, prop, val, frame):
    pb = rig.pose.bones[bone_name]
    setattr(pb, prop, val)
    pb.keyframe_insert(prop, frame=frame)

anim_defs = {}

# 1. walk_forward (0.60s loop)
def pose_walk_forward(f, t):
    c = f * 2.0 * math.pi
    stride = math.sin(c)
    lift_f = max(0.0, math.sin(c)) * 0.05
    lift_b = max(0.0, -math.sin(c)) * 0.05
    bob = -abs(math.sin(c * 2.0)) * 0.02
    
    key_bone('pelvis', 'location', (stride * 0.02, bob, 0), 1 + t * 100)
    key_bone('chest', 'rotation_euler', (0, 0.04, stride * 0.08), 1 + t * 100)
    key_bone('foot_IK_front', 'location', (stride * 0.12, lift_f, 0), 1 + t * 100)
    key_bone('foot_IK_back', 'location', (-stride * 0.12, lift_b, 0), 1 + t * 100)
    key_bone('hand_IK_front', 'location', (-stride * 0.08, -stride * 0.03, 0), 1 + t * 100)
    key_bone('hand_IK_back', 'location', (stride * 0.08, stride * 0.03, 0), 1 + t * 100)

anim_defs['walk_forward'] = {'duration': 0.60, 'times': [i * (0.60 / 8) for i in range(8)], 'builder': pose_walk_forward}

# 2. walk_backward (0.60s loop)
def pose_walk_backward(f, t):
    c = f * 2.0 * math.pi
    stride = math.sin(c)
    lift_f = max(0.0, -math.sin(c)) * 0.04
    lift_b = max(0.0, math.sin(c)) * 0.04
    bob = -abs(math.sin(c * 2.0)) * 0.015
    
    key_bone('pelvis', 'location', (-stride * 0.015, bob, 0), 1 + t * 100)
    key_bone('chest', 'rotation_euler', (0, -0.04, -stride * 0.06), 1 + t * 100)
    key_bone('foot_IK_front', 'location', (-stride * 0.09, lift_f, 0), 1 + t * 100)
    key_bone('foot_IK_back', 'location', (stride * 0.09, lift_b, 0), 1 + t * 100)
    key_bone('hand_IK_front', 'location', (0.02, 0.04, 0), 1 + t * 100)
    key_bone('hand_IK_back', 'location', (-0.02, 0.03, 0), 1 + t * 100)

anim_defs['walk_backward'] = {'duration': 0.60, 'times': [i * (0.60 / 8) for i in range(8)], 'builder': pose_walk_backward}

# 3. crouch (0.20s transition)
def pose_crouch(f, t):
    depth = math.sin(f * math.pi * 0.5)
    drop = -0.22 * depth
    key_bone('pelvis', 'location', (0.04 * depth, drop, 0), 1 + t * 100)
    key_bone('chest', 'rotation_euler', (0, 0.12 * depth, 0), 1 + t * 100)
    key_bone('foot_IK_front', 'location', (0.05 * depth, 0, 0), 1 + t * 100)
    key_bone('foot_IK_back', 'location', (-0.05 * depth, 0, 0), 1 + t * 100)
    key_bone('hand_IK_front', 'location', (0.02, drop * 0.8, 0), 1 + t * 100)
    key_bone('hand_IK_back', 'location', (-0.02, drop * 0.8, 0), 1 + t * 100)

anim_defs['crouch'] = {'duration': 0.20, 'times': [0.0, 0.06, 0.13, 0.20], 'builder': pose_crouch}

# 4. jump_start (0.12s compression)
def pose_jump_start(f, t):
    depth = math.sin(f * math.pi)
    drop = -0.12 * depth
    key_bone('pelvis', 'location', (0, drop, 0), 1 + t * 100)
    key_bone('chest', 'rotation_euler', (0, 0.08 * depth, 0), 1 + t * 100)
    key_bone('hand_IK_front', 'location', (-0.06 * depth, drop - 0.06 * depth, 0), 1 + t * 100)
    key_bone('hand_IK_back', 'location', (-0.08 * depth, drop - 0.06 * depth, 0), 1 + t * 100)

anim_defs['jump_start'] = {'duration': 0.12, 'times': [0.0, 0.06, 0.12], 'builder': pose_jump_start}

# 5. jump_air (0.25s tuck/apex)
def pose_jump_air(f, t):
    tuck = math.sin(f * math.pi * 0.5)
    key_bone('pelvis', 'location', (0.02, 0.05 * tuck, 0), 1 + t * 100)
    key_bone('chest', 'rotation_euler', (0, 0.06, 0), 1 + t * 100)
    key_bone('foot_IK_front', 'location', (0.03, 0.16 * tuck, 0), 1 + t * 100)
    key_bone('foot_IK_back', 'location', (-0.02, 0.18 * tuck, 0), 1 + t * 100)
    key_bone('hand_IK_front', 'location', (0.05, 0.08, 0), 1 + t * 100)
    key_bone('hand_IK_back', 'location', (-0.02, 0.06, 0), 1 + t * 100)

anim_defs['jump_air'] = {'duration': 0.25, 'times': [0.0, 0.08, 0.16, 0.25], 'builder': pose_jump_air}

# 6. fall (0.25s downward descent)
def pose_fall(f, t):
    key_bone('pelvis', 'location', (0, -0.02, 0), 1 + t * 100)
    key_bone('chest', 'rotation_euler', (0, 0.02, 0), 1 + t * 100)
    key_bone('foot_IK_front', 'location', (0.04, 0.06 * (1.0 - f * 0.5), 0), 1 + t * 100)
    key_bone('foot_IK_back', 'location', (-0.04, 0.06 * (1.0 - f * 0.5), 0), 1 + t * 100)
    key_bone('hand_IK_front', 'location', (0.04, -0.02, 0), 1 + t * 100)
    key_bone('hand_IK_back', 'location', (-0.04, -0.02, 0), 1 + t * 100)

anim_defs['fall'] = {'duration': 0.25, 'times': [0.0, 0.08, 0.16, 0.25], 'builder': pose_fall}

# 7. land (0.12s ground contact)
def pose_land(f, t):
    depth = math.sin(f * math.pi)
    drop = -0.10 * depth
    key_bone('pelvis', 'location', (0, drop, 0), 1 + t * 100)
    key_bone('chest', 'rotation_euler', (0, 0.06 * depth, 0), 1 + t * 100)
    key_bone('hand_IK_front', 'location', (0, drop, 0), 1 + t * 100)
    key_bone('hand_IK_back', 'location', (0, drop, 0), 1 + t * 100)

anim_defs['land'] = {'duration': 0.12, 'times': [0.0, 0.04, 0.08, 0.12], 'builder': pose_land}

# 8. cross (0.28s rear straight punch)
def pose_cross(f, t):
    if f < 0.2:
        p = f / 0.2
        reach = -0.05 * p
        twist = 0.08 * p
    elif f < 0.6:
        p = (f - 0.2) / 0.4
        reach = -0.05 + 0.47 * math.sin(p * math.pi * 0.5)
        twist = 0.08 - 0.35 * math.sin(p * math.pi * 0.5)
    else:
        p = (f - 0.6) / 0.4
        reach = 0.42 * (1.0 - p)
        twist = -0.27 * (1.0 - p)
    
    key_bone('pelvis', 'location', (reach * 0.08, 0, 0), 1 + t * 100)
    key_bone('chest', 'rotation_euler', (0, reach * 0.12, twist), 1 + t * 100)
    key_bone('hand_IK_back', 'location', (reach, -0.02 if reach > 0.20 else 0, 0), 1 + t * 100)
    key_bone('hand_IK_front', 'location', (-0.08 * (reach / 0.42), 0.02, 0), 1 + t * 100)

anim_defs['cross'] = {'duration': 0.28, 'times': [0.0, 0.04, 0.08, 0.14, 0.20, 0.28], 'builder': pose_cross}

# 9. hook (0.30s lead horizontal hook)
def pose_hook(f, t):
    if f < 0.25:
        reach = -0.06 * (f / 0.25)
        lift = 0.0
    elif f < 0.65:
        p = (f - 0.25) / 0.40
        reach = -0.06 + 0.38 * math.sin(p * math.pi * 0.5)
        lift = 0.08 * math.sin(p * math.pi * 0.5)
    else:
        p = (f - 0.65) / 0.35
        reach = 0.32 * (1.0 - p)
        lift = 0.08 * (1.0 - p)
    
    twist = reach * 0.45
    key_bone('pelvis', 'location', (reach * 0.06, 0, 0), 1 + t * 100)
    key_bone('chest', 'rotation_euler', (0, 0.08, twist), 1 + t * 100)
    key_bone('hand_IK_front', 'location', (reach, lift, 0), 1 + t * 100)
    key_bone('hand_IK_back', 'location', (-0.04, 0.04, 0), 1 + t * 100)

anim_defs['hook'] = {'duration': 0.30, 'times': [0.0, 0.05, 0.10, 0.16, 0.22, 0.30], 'builder': pose_hook}

# 10. uppercut (0.32s rising vertical punch)
def pose_uppercut(f, t):
    if f < 0.25:
        p = f / 0.25
        dip = -0.10 * p
        drive = 0.0
    elif f < 0.65:
        p = (f - 0.25) / 0.40
        dip = -0.10 + 0.15 * p
        drive = 0.38 * math.sin(p * math.pi * 0.5)
    else:
        p = (f - 0.65) / 0.35
        dip = 0.05 * (1.0 - p)
        drive = 0.38 * (1.0 - p)
    
    key_bone('pelvis', 'location', (drive * 0.05, dip, 0), 1 + t * 100)
    key_bone('chest', 'rotation_euler', (0, -0.12 * (drive / 0.38), -0.20), 1 + t * 100)
    key_bone('hand_IK_back', 'location', (drive * 0.55, drive, 0), 1 + t * 100)
    key_bone('hand_IK_front', 'location', (-0.04, 0.02, 0), 1 + t * 100)

anim_defs['uppercut'] = {'duration': 0.32, 'times': [0.0, 0.05, 0.11, 0.17, 0.24, 0.32], 'builder': pose_uppercut}

# 11. roundhouse_kick (0.36s high circular kick)
def pose_roundhouse(f, t):
    if f < 0.25:
        p = f / 0.25
        reach = 0.12 * p
        lift = 0.32 * p
        lean = -0.10 * p
    elif f < 0.60:
        p = (f - 0.25) / 0.35
        reach = 0.12 + 0.35 * math.sin(p * math.pi * 0.5)
        lift = 0.32 + 0.13 * math.sin(p * math.pi * 0.5)
        lean = -0.10 - 0.18 * math.sin(p * math.pi * 0.5)
    else:
        p = (f - 0.60) / 0.40
        reach = 0.47 * (1.0 - p)
        lift = 0.45 * (1.0 - p)
        lean = -0.28 * (1.0 - p)
    
    key_bone('pelvis', 'location', (reach * 0.06, lift * 0.10, 0), 1 + t * 100)
    key_bone('chest', 'rotation_euler', (0, lean, reach * 0.35), 1 + t * 100)
    key_bone('foot_IK_front', 'location', (reach, lift, 0), 1 + t * 100)
    key_bone('hand_IK_front', 'location', (-0.08, 0.04, 0), 1 + t * 100)
    key_bone('hand_IK_back', 'location', (-0.10, -0.04, 0), 1 + t * 100)

anim_defs['roundhouse_kick'] = {'duration': 0.36, 'times': [0.0, 0.06, 0.12, 0.18, 0.24, 0.30, 0.36], 'builder': pose_roundhouse}

# 12. low_kick (0.30s low calf sweep)
def pose_low_kick(f, t):
    if f < 0.25:
        p = f / 0.25
        reach = 0.06 * p
        drop = -0.08 * p
    elif f < 0.60:
        p = (f - 0.25) / 0.35
        reach = 0.06 + 0.32 * math.sin(p * math.pi * 0.5)
        drop = -0.08 - 0.04 * math.sin(p * math.pi * 0.5)
    else:
        p = (f - 0.60) / 0.40
        reach = 0.38 * (1.0 - p)
        drop = -0.12 * (1.0 - p)
    
    key_bone('pelvis', 'location', (reach * 0.05, drop, 0), 1 + t * 100)
    key_bone('chest', 'rotation_euler', (0, 0.08, reach * 0.22), 1 + t * 100)
    key_bone('foot_IK_front', 'location', (reach, -0.01, 0), 1 + t * 100)
    key_bone('hand_IK_front', 'location', (0.02, drop, 0), 1 + t * 100)

anim_defs['low_kick'] = {'duration': 0.30, 'times': [0.0, 0.04, 0.08, 0.14, 0.22, 0.30], 'builder': pose_low_kick}

# 13. side_kick (0.34s linear heel thrust)
def pose_side_kick(f, t):
    if f < 0.25:
        p = f / 0.25
        chamber = -0.08 * p
        lift = 0.26 * p
        lean = -0.10 * p
    elif f < 0.60:
        p = (f - 0.25) / 0.35
        chamber = -0.08 + 0.50 * math.sin(p * math.pi * 0.5)
        lift = 0.26 - 0.02 * math.sin(p * math.pi * 0.5)
        lean = -0.10 - 0.16 * math.sin(p * math.pi * 0.5)
    else:
        p = (f - 0.60) / 0.40
        chamber = 0.42 * (1.0 - p)
        lift = 0.24 * (1.0 - p)
        lean = -0.26 * (1.0 - p)
    
    key_bone('pelvis', 'location', (chamber * 0.06, 0.02, 0), 1 + t * 100)
    key_bone('chest', 'rotation_euler', (0, lean, chamber * 0.25), 1 + t * 100)
    key_bone('foot_IK_front', 'location', (chamber, lift, 0), 1 + t * 100)
    key_bone('hand_IK_front', 'location', (-0.10, 0.06, 0), 1 + t * 100)

anim_defs['side_kick'] = {'duration': 0.34, 'times': [0.0, 0.05, 0.10, 0.17, 0.25, 0.34], 'builder': pose_side_kick}

# 14. block_high (0.20s head shield)
def pose_block_high(f, t):
    p = math.sin(f * math.pi * 0.5)
    key_bone('chest', 'rotation_euler', (0, -0.05 * p, 0), 1 + t * 100)
    key_bone('hand_IK_front', 'location', (-0.05 * p, 0.18 * p, 0), 1 + t * 100)
    key_bone('hand_IK_back', 'location', (0.05 * p, 0.20 * p, 0), 1 + t * 100)

anim_defs['block_high'] = {'duration': 0.20, 'times': [0.0, 0.06, 0.13, 0.20], 'builder': pose_block_high}

# 15. block_mid (0.20s crossed chest guard)
def pose_block_mid(f, t):
    p = math.sin(f * math.pi * 0.5)
    key_bone('chest', 'rotation_euler', (0, -0.06 * p, 0), 1 + t * 100)
    key_bone('hand_IK_front', 'location', (-0.09 * p, 0.05 * p, 0), 1 + t * 100)
    key_bone('hand_IK_back', 'location', (0.07 * p, 0.05 * p, 0), 1 + t * 100)

anim_defs['block_mid'] = {'duration': 0.20, 'times': [0.0, 0.06, 0.13, 0.20], 'builder': pose_block_mid}

# 16. block_low (0.20s parry low sweep)
def pose_block_low(f, t):
    p = math.sin(f * math.pi * 0.5)
    key_bone('pelvis', 'location', (0, -0.14 * p, 0), 1 + t * 100)
    key_bone('chest', 'rotation_euler', (0, 0.12 * p, 0), 1 + t * 100)
    key_bone('hand_IK_front', 'location', (0.08 * p, -0.32 * p, 0), 1 + t * 100)
    key_bone('hand_IK_back', 'location', (-0.02 * p, -0.04 * p, 0), 1 + t * 100)

anim_defs['block_low'] = {'duration': 0.20, 'times': [0.0, 0.06, 0.13, 0.20], 'builder': pose_block_low}

# 17. dodge_back (0.25s slip back)
def pose_dodge_back(f, t):
    p = math.sin(f * math.pi)
    key_bone('pelvis', 'location', (-0.12 * p, -0.02 * p, 0), 1 + t * 100)
    key_bone('chest', 'rotation_euler', (0, -0.26 * p, 0), 1 + t * 100)
    key_bone('head', 'rotation_euler', (0, -0.16 * p, 0), 1 + t * 100)
    key_bone('hand_IK_front', 'location', (-0.08 * p, 0.05 * p, 0), 1 + t * 100)

anim_defs['dodge_back'] = {'duration': 0.25, 'times': [0.0, 0.06, 0.12, 0.18, 0.25], 'builder': pose_dodge_back}

# 18. hit_head (0.22s head snap back)
def pose_hit_head(f, t):
    p = math.sin(f * math.pi)
    key_bone('head', 'rotation_euler', (0, -0.38 * p, 0), 1 + t * 100)
    key_bone('chest', 'rotation_euler', (0, -0.20 * p, 0), 1 + t * 100)
    key_bone('pelvis', 'location', (-0.08 * p, 0, 0), 1 + t * 100)
    key_bone('hand_IK_front', 'location', (-0.10 * p, -0.10 * p, 0), 1 + t * 100)

anim_defs['hit_head'] = {'duration': 0.22, 'times': [0.0, 0.04, 0.09, 0.15, 0.22], 'builder': pose_hit_head}

# 19. hit_body (0.22s gut recoil)
def pose_hit_body(f, t):
    p = math.sin(f * math.pi)
    key_bone('chest', 'rotation_euler', (0, 0.26 * p, 0), 1 + t * 100)
    key_bone('head', 'rotation_euler', (0, 0.18 * p, 0), 1 + t * 100)
    key_bone('pelvis', 'location', (-0.10 * p, -0.05 * p, 0), 1 + t * 100)
    key_bone('hand_IK_front', 'location', (-0.06 * p, -0.14 * p, 0), 1 + t * 100)

anim_defs['hit_body'] = {'duration': 0.22, 'times': [0.0, 0.04, 0.09, 0.15, 0.22], 'builder': pose_hit_body}

# 20. hit_leg (0.20s leg sweep reaction)
def pose_hit_leg(f, t):
    p = math.sin(f * math.pi)
    key_bone('pelvis', 'location', (-0.08 * p, -0.10 * p, 0), 1 + t * 100)
    key_bone('foot_IK_front', 'location', (-0.10 * p, 0.05 * p, 0), 1 + t * 100)
    key_bone('chest', 'rotation_euler', (0, 0.12 * p, 0), 1 + t * 100)

anim_defs['hit_leg'] = {'duration': 0.20, 'times': [0.0, 0.04, 0.08, 0.14, 0.20], 'builder': pose_hit_leg}

# 21. heavy_hit (0.28s violent stagger)
def pose_heavy_hit(f, t):
    p = math.sin(f * math.pi)
    key_bone('pelvis', 'location', (-0.18 * p, -0.06 * p, 0), 1 + t * 100)
    key_bone('chest', 'rotation_euler', (0, -0.32 * p, 0.12 * p), 1 + t * 100)
    key_bone('head', 'rotation_euler', (0, -0.28 * p, 0), 1 + t * 100)
    key_bone('hand_IK_front', 'location', (-0.16 * p, 0.14 * p, 0), 1 + t * 100)
    key_bone('hand_IK_back', 'location', (-0.18 * p, -0.12 * p, 0), 1 + t * 100)

anim_defs['heavy_hit'] = {'duration': 0.28, 'times': [0.0, 0.05, 0.11, 0.18, 0.24, 0.28], 'builder': pose_heavy_hit}

# 22. knockdown (0.50s falling flat onto mat)
def pose_knockdown(f, t):
    p = min(1.0, f * 1.5)
    fall_tilt = math.radians(88.0) * p
    key_bone('root', 'rotation_euler', (0, 0, fall_tilt), 1 + t * 100)
    key_bone('root', 'location', (0.45 * p, 0.15 * p, 0), 1 + t * 100)

anim_defs['knockdown'] = {'duration': 0.50, 'times': [0.0, 0.08, 0.16, 0.25, 0.35, 0.45, 0.50], 'builder': pose_knockdown}

# 23. get_up (0.45s rising from mat)
def pose_get_up(f, t):
    p = 1.0 - f
    fall_tilt = math.radians(88.0) * p
    key_bone('root', 'rotation_euler', (0, 0, fall_tilt), 1 + t * 100)
    key_bone('root', 'location', (0.45 * p, 0.15 * p, 0), 1 + t * 100)

anim_defs['get_up'] = {'duration': 0.45, 'times': [0.0, 0.09, 0.18, 0.27, 0.36, 0.45], 'builder': pose_get_up}

print(f"Authoring refined actions onto Dusk_Original_Rig...")
for name, data in anim_defs.items():
    action = get_or_create_action(name)
    rig.animation_data_create()
    rig.animation_data.action = action
    reset_pose()
    
    times = data['times']
    duration = data['duration']
    for t in times:
        f = t / duration
        data['builder'](f, t)
    
    for fc in action.fcurves:
        for k in fc.keyframe_points:
            k.interpolation = 'BEZIER'
            k.handle_left_type = k.handle_right_type = 'AUTO_CLAMPED'

rig.animation_data.action = bpy.data.actions['idle']
reset_pose()
bpy.context.scene.frame_set(1)

bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
print("SUCCESS: Updated actions in fighter.blend!")
