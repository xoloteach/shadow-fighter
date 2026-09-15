# Project State: Shadow Fighter - Version 2.0.0

## Overview
**Shadow Fighter: Dusk Duel (Version 2.0.0)** is an original 2D side-view silhouette martial-arts fighting game built with Godot 4 (GL Compatibility / WebGL 2.0) and an automated headless Blender 4.0.2 animation/art production pipeline.

---

## Architecture & Pipeline

```
[Blender 4.0.2 Headless]
  -> Armature: Dusk_Original_Rig (22-bone martial-arts rig with 2-bone IK on limbs)
  -> 25 Authored Actions (Movement, Attacks, Defenses, Reactions, Knockdown, Recovery)
  -> Orthographic Locked Camera (Side-on fighting perspective, transparent background)
  -> Automated Render Script (blender/scripts/render_animation.py)
  -> Sprite Packing Tool (tools/pack_sprites.py)
       -> Cropped & Packed 2D Sprite Atlases (assets/blender/*.png)
       -> Authoritative Metadata & Events (assets/blender/library.json)
       -> QA Contact Sheets (qa/blender/milestone2/*-contact.png)

[Godot 4.7.2 2D Runtime]
  -> FighterVisuals (scripts/fighter_visuals.gd):
       - Dynamic atlas slice rendering with calibrated ground pivot (y = 0)
       - Horizontal mirroring compensation on facing inversion
       - Procedural cloth Verlet ribbon simulation
       - Crescent slash trails, hit flashes, block pulses
       - Seamless procedural fallback architecture (use_blender_sprites toggle)
  -> Fighter Combat Machine (scripts/fighter.gd):
       - Authoritative startup, active, and recovery windows
       - Hitbox & hurtbox synchronization
       - Intentional combo chains:
           * Jab -> Cross (Punch 1 -> Punch 2)
           * Jab -> Cross -> Hook (Punch 1 -> Punch 2 -> Punch 3)
           * Jab -> Roundhouse (Punch 1 -> Kick 2)
           * Low Kick -> Cross (Crouch Kick -> Punch 2)
           * Cross -> Side Kick (Punch 2 -> Kick 1)
       - Knockdown and get-up recovery
       - Reactive hit stuns (Head, Body, Leg, Heavy)
       - High, Mid, and Low directional blocking
  -> AI Controller (scripts/ai_controller.gd):
       - Distance evaluation and range-based attack selection
       - Anti-air uppercut reactions against jumping foes
       - Predictive and reactive high/low blocking
       - Natural human-like reaction window (140-220ms)

[Web Release / GitHub Pages]
  -> Single-threaded WebAssembly (variant/thread_support=false)
  -> 1.69 MB game PCK containing all 25 animation atlases
  -> Total web directory: 40.6 MB (instant load, 60 FPS target)
  -> Deployed from clean gh-pages branch root with .nojekyll
```

---

## Animation Library (25 Actions)

1. `idle`: 16 frames, 1.00s breathing loop
2. `walk_forward`: 8 frames, 0.60s forward stepping cycle
3. `walk_backward`: 8 frames, 0.60s guarded retreat
4. `crouch`: 4 frames, 0.20s ducking stance
5. `jump_start`: 3 frames, 0.12s compression anticipation
6. `jump_air`: 4 frames, 0.25s rising tuck
7. `fall`: 4 frames, 0.25s descending drop
8. `land`: 3 frames, 0.12s ground contact compression
9. `jab`: 6 frames, 0.24s fast lead punch (active: 0.06-0.16s)
10. `cross`: 6 frames, 0.28s powerful rear punch (active: 0.08-0.18s)
11. `hook`: 6 frames, 0.30s heavy horizontal curved strike (active: 0.10-0.20s)
12. `uppercut`: 6 frames, 0.32s rising vertical anti-air punch (active: 0.11-0.22s)
13. `roundhouse_kick`: 7 frames, 0.36s high circular head kick (active: 0.12-0.24s)
14. `low_kick`: 6 frames, 0.30s low calf sweep tripping unblocked foes (active: 0.08-0.20s)
15. `side_kick`: 6 frames, 0.34s linear heel thrust (active: 0.10-0.22s)
16. `block_high`: 4 frames, 0.20s raised temple/head shield
17. `block_mid`: 4 frames, 0.20s crossed chest guard
18. `block_low`: 4 frames, 0.20s dropped low guard
19. `dodge_back`: 5 frames, 0.25s backward sway slip
20. `hit_head`: 5 frames, 0.22s snap-back recoil
21. `hit_body`: 5 frames, 0.22s gut fold recoil
22. `hit_leg`: 4 frames, 0.20s low sweep buckle
23. `heavy_hit`: 6 frames, 0.28s violent stagger
24. `knockdown`: 7 frames, 0.50s sweeping fall flat onto mat
25. `get_up`: 6 frames, 0.45s rising roll back into stance

---

## Known Commands

- **Build Rig**: `blender -b --python blender/scripts/create_all_animations.py`
- **Render Animations**: `blender -b blender/scenes/fighter.blend --python blender/scripts/render_animation.py -- --animation all`
- **Pack Sprites**: `python3 tools/pack_sprites.py`
- **Godot Headless Check**: `GODOT_SILENCE_ROOT_WARNING=1 godot --headless --path . --quit-after 10`
- **Godot Export Web**: `GODOT_SILENCE_ROOT_WARNING=1 godot --headless --path . --export-release "Web" web/index.html`
- **Run Browser QA**: `NODE_PATH=/root/shadow-fighter/node_modules node qa/test_v2_suite.js`

---

## Limitations

- Browser Web Audio policy requires one user interaction before audio starts (caught cleanly without error).
