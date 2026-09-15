"""Automated transparent orthographic rendering for all 25 fighter animations. Blender 4.0.2."""
import bpy, sys, argparse, json
from pathlib import Path

root = Path(__file__).resolve().parents[2]
blend_path = root / 'blender/scenes/fighter.blend'

# Configuration table for every animation
ANIM_SPECS = {
    'idle': {
        'times': [i * (1.0 / 16) for i in range(16)],
        'duration': 1.0,
        'loop': True,
        'events': {}
    },
    'walk_forward': {
        'times': [i * (0.60 / 8) for i in range(8)],
        'duration': 0.60,
        'loop': True,
        'events': {'sound_event': 'footstep', 'movement_speed': 250.0}
    },
    'walk_backward': {
        'times': [i * (0.60 / 8) for i in range(8)],
        'duration': 0.60,
        'loop': True,
        'events': {'movement_speed': -175.0}
    },
    'crouch': {
        'times': [0.0, 0.06, 0.13, 0.20],
        'duration': 0.20,
        'loop': False,
        'events': {}
    },
    'jump_start': {
        'times': [0.0, 0.06, 0.12],
        'duration': 0.12,
        'loop': False,
        'events': {'sound_event': 'jump'}
    },
    'jump_air': {
        'times': [0.0, 0.08, 0.16, 0.25],
        'duration': 0.25,
        'loop': False,
        'events': {}
    },
    'fall': {
        'times': [0.0, 0.08, 0.16, 0.25],
        'duration': 0.25,
        'loop': False,
        'events': {}
    },
    'land': {
        'times': [0.0, 0.04, 0.08, 0.12],
        'duration': 0.12,
        'loop': False,
        'events': {'sound_event': 'land'}
    },
    'jab': {
        'times': [0.0, 0.03, 0.06, 0.12, 0.1667, 0.20],
        'duration': 0.24,
        'loop': False,
        'events': {
            'attack_state': 'punch_1',
            'startup_start': 0.0,
            'hitbox_on': 0.06,
            'hitbox_off': 0.16,
            'impact_frame': 2,
            'movement_impulse': 80.0,
            'sound_event': 'whoosh_light',
            'hit_sound': 'hit_light',
            'damage': 8.0,
            'chip_damage': 1.5,
            'knockback': [170.0, -50.0],
            'hit_stun': 0.22,
            'attack_type': 'mid',
            'trail_event': True,
            'recovery_start': 0.16,
            'animation_end': 0.24,
            'can_combo_cancel': True
        }
    },
    'cross': {
        'times': [0.0, 0.04, 0.08, 0.14, 0.20, 0.28],
        'duration': 0.28,
        'loop': False,
        'events': {
            'attack_state': 'punch_2',
            'startup_start': 0.0,
            'hitbox_on': 0.08,
            'hitbox_off': 0.18,
            'impact_frame': 2,
            'movement_impulse': 120.0,
            'sound_event': 'whoosh_light',
            'hit_sound': 'hit_light',
            'damage': 12.0,
            'chip_damage': 2.0,
            'knockback': [250.0, -70.0],
            'hit_stun': 0.26,
            'attack_type': 'mid',
            'trail_event': True,
            'recovery_start': 0.18,
            'animation_end': 0.28,
            'can_combo_cancel': True
        }
    },
    'hook': {
        'times': [0.0, 0.05, 0.10, 0.16, 0.22, 0.30],
        'duration': 0.30,
        'loop': False,
        'events': {
            'attack_state': 'punch_3',
            'startup_start': 0.0,
            'hitbox_on': 0.10,
            'hitbox_off': 0.20,
            'impact_frame': 2,
            'movement_impulse': 140.0,
            'sound_event': 'whoosh_heavy',
            'hit_sound': 'hit_heavy',
            'damage': 16.0,
            'chip_damage': 3.0,
            'knockback': [340.0, -130.0],
            'hit_stun': 0.34,
            'attack_type': 'high',
            'heavy_hit': True,
            'trail_event': True,
            'recovery_start': 0.20,
            'animation_end': 0.30,
            'can_combo_cancel': False
        }
    },
    'uppercut': {
        'times': [0.0, 0.05, 0.11, 0.17, 0.24, 0.32],
        'duration': 0.32,
        'loop': False,
        'events': {
            'attack_state': 'crouch_punch',
            'startup_start': 0.0,
            'hitbox_on': 0.11,
            'hitbox_off': 0.22,
            'impact_frame': 2,
            'movement_impulse': 100.0,
            'sound_event': 'whoosh_heavy',
            'hit_sound': 'hit_heavy',
            'damage': 18.0,
            'chip_damage': 3.5,
            'knockback': [200.0, -220.0],
            'hit_stun': 0.38,
            'attack_type': 'mid',
            'heavy_hit': True,
            'trail_event': True,
            'recovery_start': 0.22,
            'animation_end': 0.32,
            'can_combo_cancel': False
        }
    },
    'roundhouse_kick': {
        'times': [0.0, 0.06, 0.12, 0.18, 0.24, 0.30, 0.36],
        'duration': 0.36,
        'loop': False,
        'events': {
            'attack_state': 'kick_2',
            'startup_start': 0.0,
            'hitbox_on': 0.12,
            'hitbox_off': 0.24,
            'impact_frame': 3,
            'movement_impulse': 130.0,
            'sound_event': 'whoosh_heavy',
            'hit_sound': 'hit_heavy',
            'damage': 17.0,
            'chip_damage': 3.5,
            'knockback': [360.0, -150.0],
            'hit_stun': 0.35,
            'attack_type': 'high',
            'heavy_hit': True,
            'trail_event': True,
            'recovery_start': 0.24,
            'animation_end': 0.36,
            'can_combo_cancel': False
        }
    },
    'low_kick': {
        'times': [0.0, 0.04, 0.08, 0.14, 0.22, 0.30],
        'duration': 0.30,
        'loop': False,
        'events': {
            'attack_state': 'crouch_kick',
            'startup_start': 0.0,
            'hitbox_on': 0.08,
            'hitbox_off': 0.20,
            'impact_frame': 2,
            'movement_impulse': 150.0,
            'sound_event': 'sweep',
            'hit_sound': 'hit_heavy',
            'damage': 14.0,
            'chip_damage': 2.5,
            'knockback': [230.0, -190.0],
            'hit_stun': 0.40,
            'attack_type': 'low',
            'is_sweep': True,
            'heavy_hit': True,
            'trail_event': True,
            'recovery_start': 0.20,
            'animation_end': 0.30,
            'can_combo_cancel': True
        }
    },
    'side_kick': {
        'times': [0.0, 0.05, 0.10, 0.17, 0.25, 0.34],
        'duration': 0.34,
        'loop': False,
        'events': {
            'attack_state': 'kick_1',
            'startup_start': 0.0,
            'hitbox_on': 0.10,
            'hitbox_off': 0.22,
            'impact_frame': 2,
            'movement_impulse': 110.0,
            'sound_event': 'whoosh_heavy',
            'hit_sound': 'hit_light',
            'damage': 13.0,
            'chip_damage': 2.5,
            'knockback': [280.0, -80.0],
            'hit_stun': 0.28,
            'attack_type': 'mid',
            'trail_event': True,
            'recovery_start': 0.22,
            'animation_end': 0.34,
            'can_combo_cancel': True
        }
    },
    'block_high': {
        'times': [0.0, 0.06, 0.13, 0.20],
        'duration': 0.20,
        'loop': False,
        'events': {'block_zone': 'high', 'sound_event': 'block'}
    },
    'block_mid': {
        'times': [0.0, 0.06, 0.13, 0.20],
        'duration': 0.20,
        'loop': False,
        'events': {'block_zone': 'mid', 'sound_event': 'block'}
    },
    'block_low': {
        'times': [0.0, 0.06, 0.13, 0.20],
        'duration': 0.20,
        'loop': False,
        'events': {'block_zone': 'low', 'sound_event': 'block'}
    },
    'dodge_back': {
        'times': [0.0, 0.06, 0.12, 0.18, 0.25],
        'duration': 0.25,
        'loop': False,
        'events': {'movement_impulse': -180.0}
    },
    'hit_head': {
        'times': [0.0, 0.04, 0.09, 0.15, 0.22],
        'duration': 0.22,
        'loop': False,
        'events': {'hit_zone': 'high'}
    },
    'hit_body': {
        'times': [0.0, 0.04, 0.09, 0.15, 0.22],
        'duration': 0.22,
        'loop': False,
        'events': {'hit_zone': 'mid'}
    },
    'hit_leg': {
        'times': [0.0, 0.04, 0.08, 0.14, 0.20],
        'duration': 0.20,
        'loop': False,
        'events': {'hit_zone': 'low'}
    },
    'heavy_hit': {
        'times': [0.0, 0.05, 0.11, 0.18, 0.24, 0.28],
        'duration': 0.28,
        'loop': False,
        'events': {'heavy': True}
    },
    'knockdown': {
        'times': [0.0, 0.08, 0.16, 0.25, 0.35, 0.45, 0.50],
        'duration': 0.50,
        'loop': False,
        'events': {'sound_event': 'ko_impact'}
    },
    'get_up': {
        'times': [0.0, 0.09, 0.18, 0.27, 0.36, 0.45],
        'duration': 0.45,
        'loop': False,
        'events': {}
    }
}

p = argparse.ArgumentParser()
p.add_argument('--animation', default='all')
args = p.parse_args(sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else [])

rig = bpy.data.objects['Dusk_Original_Rig']
scene = bpy.context.scene

targets = list(ANIM_SPECS.keys()) if args.animation == 'all' else [args.animation]
print(f"Starting batch render for {len(targets)} animation(s)...")

for idx, name in enumerate(targets):
    if name not in ANIM_SPECS or name not in bpy.data.actions:
        print(f"Skipping unknown animation: {name}")
        continue
    
    spec = ANIM_SPECS[name]
    output = root / 'blender/renders' / name
    output.mkdir(parents=True, exist_ok=True)
    
    # Clean previous frames for this animation safely
    for old in output.glob(name + '_????.png'):
        old.unlink()
    
    times = spec['times']
    duration = spec['duration']
    rig.animation_data.action = bpy.data.actions[name]
    
    # Reset pose before running animation
    for pb in rig.pose.bones:
        pb.location = (0, 0, 0)
        pb.rotation_euler = (0, 0, 0)
    
    for i, t in enumerate(times):
        frame = 1 + t * 100
        scene.frame_set(int(frame), subframe=frame - int(frame))
        filepath = output / f"{name}_{i + 1:04}.png"
        scene.render.filepath = str(filepath)
        bpy.ops.render.render(write_still=True)
        assert filepath.stat().st_size > 0
    
    data = {
        'animation': name,
        'times': times,
        'duration': duration,
        'loop': spec['loop'],
        'pivot': [128, 296],
        'game_scale': 0.625,
        'events': spec['events']
    }
    (output / 'timing.json').write_text(json.dumps(data, indent=2))
    print(f"[{idx+1}/{len(targets)}] RENDERED {name} ({len(times)} frames, {duration}s)")

print("ALL ANIMATIONS RENDERED SUCCESSFULLY!")
