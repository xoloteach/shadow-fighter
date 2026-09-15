# Shadow Fighter: Dusk Duel

An original 2D silhouette martial-arts fighting game built in Godot 4 and GDScript.

Inspired by the atmospheric aesthetic of classic side-view silhouette martial-arts duels, **Shadow Fighter: Dusk Duel** is a 100% original standalone fighting game prototype featuring procedurally articulated silhouette characters, dynamic cloth physics, an atmospheric dusk mountain arena, responsive combat systems, enemy AI, procedural sound synthesis, and WebAssembly export support for GitHub Pages.

---

## Version 3: Bell of Twilight Campaign

V3 expands the duel prototype into an original single-player progression campaign:

- **Dojo hub** for campaign, training, armory, shop, and profile access.
- **Three original chapters**: *The Broken Bell*, *Lanterns in the Rain*, and *Ashes of the Banner*, culminating in Warden Guro, Madame Lin, and General Kurozuka.
- **Progression**: versioned local save, XP/level curve, Monshu currency, campaign unlocks, combat record, and 5-slot inventory.
- **Equipment**: melee, armor, helmet, ranged, and special-art slots with ownership, upgrades, effective stat calculations, and distinct silhouette equipment visuals.
- **Modes**: sequential tournaments, challenge-rule fights, elite/boss routes, a passive training dummy, and a six-wave survival gauntlet with 18% between-wave recovery.
- **Refined AI**: explicit passive/defensive/aggressive/tactical/boss profiles, neutral input resets, attack cooldowns, controlled defensive reactions, and profile-specific decision timing.
- **Challenge rules**: no jump, no block, heavy-hit armor, amplified knockback, floor burn, and sudden death are enforced by combat modifiers.
- **Blender asset pipeline**: offline Blender 4.0.2 renders remain the source for 2D sprite content. V3 includes original boss portrait renders under `assets/blender/v3/`; gameplay remains 2D Godot physics.

## Key Features

- **Viewport & Rendering**:
  - Native 1280×720 canvas resolution
  - Compatibility renderer (`gl_compatibility` / WebGL)
  - 60 FPS physics and update loop
  - Responsive canvas layout (`canvas_items` / `expand`) adapting smoothly to widescreen desktop displays and mobile phone screens.

- **Original Silhouette Characters**:
  - Characters constructed entirely from Godot 2D primitives (`Polygon2D`, `Line2D`, and custom vector drawing) with rim lighting accents.
  - **Player (Kage - Shadow Ronin)**: Athletic silhouette with glowing cyan eye slits, martial headband, and a multi-segmented headband ribbon tail with Verlet cloth physics responding dynamically to velocity and wind.
  - **AI Opponent (Oni - Crimson Wraith)**: Menacing horned kabuto mask silhouette, glowing ruby eye slits, and flowing crimson sash tails.

- **Combat System & Mechanics**:
  - **Locomotion**: Walk forward, defensive walk backward, jump (with aerial physics and air attacks), crouch (lowering hurtbox beneath high strikes).
  - **Punch Attacks**:
    - *Lead Jab (Punch 1)*: Quick setup strike (8 DMG, short recovery).
    - *Straight Cross (Punch 2)*: Solid torso strike (12 DMG).
    - *Spinning Backfist (Punch 3)*: Heavy combo finisher with high knockback (18 DMG).
    - *Low Gut Jab*: Fast poke from crouching posture (7 DMG).
    - *Downward Hammer Fist*: Airborne diving punch (10 DMG).
  - **Kick Attacks**:
    - *Snap Kick (Kick 1)*: Medium-range poke (11 DMG).
    - *Roundhouse High Kick (Kick 2)*: Powerful head strike (17 DMG).
    - *Low Leg Sweep (Crouch Kick)*: Slides along the floor; unblocked hits trip the opponent into a knockdown state (14 DMG).
    - *Flying Side Kick*: Airborne forward dive kick (15 DMG).
  - **Combos**:
    - Intuitive strike canceling (e.g. Jab → Cross → Heavy Finisher, or Punch → Roundhouse).
    - Dynamic combo counter on screen with bouncy text and color escalation ("2 HITS!", "3 HITS COMBO!", "5 HITS!").
  - **Hitboxes & Hurtboxes**:
    - Dedicated High, Mid, and Low hurtboxes.
    - Hitboxes match the exact position of extending limbs and active attack windows.
    - Automatic facing and knockback impulse vectors.
  - **Defensive Guard / Blocking**:
    - Hold the block action or walk backward while facing the enemy to enter guard.
    - Blocks reduce damage by over 80% (chip damage only), eliminate knockdown, negate heavy hit stun, and trigger defensive visual barrier sparks and clank SFX.
  - **Hit Reactions & FX**:
    - Dynamic attack slash arcs, directional hit sparks, white hit flashes, and landing dust puffs.
    - Screen shake on heavy strikes and K.O.

- **Tactical Enemy AI**:
  - Distance-based decision state machine (Far, Mid, Close).
  - Approaches when out of reach, uses long pokes (kicks) at mid-range, executes punch/kick combos when openings occur.
  - Human-like reaction delay to incoming player attacks (blocks or crouches under strikes).
  - Backs away to reset spacing and increases defensive guard when health drops below 35%.

- **Match Flow & UI**:
  - Top HUD with dual-layer health bars (bright health fill + animated red damage trail), fighter names, and round win orbs.
  - 99-second countdown timer.
  - Center animated announcements: "ROUND 1", "FIGHT!", "K.O.!", "ROUND OVER", "TIME UP!".
  - Best-of-3 rounds match structure.
  - Game Over summary screen displaying winner, rounds score, total hits landed, max combo, and match duration.
  - Responsive "PLAY AGAIN" / Rematch button and instant keyboard restart.

- **Controls**:
  - **Keyboard (Desktop)**:
    - `A` / `D` or `Left` / `Right Arrow`: Move
    - `W` / `Up Arrow` / `Space`: Jump
    - `S` / `Down Arrow`: Crouch
    - `J` / `Z`: Punch
    - `K` / `X`: Kick
    - `L` / `C` / `Shift`: Block
    - `R` / `Enter`: Restart Match / Rematch
  - **Mobile Touch Controls**:
    - Touch-only circular virtual joystick with an 8-direction dead zone and crisp full-speed fighting-game movement.
    - Separate multi-touch-safe `PUNCH`, `KICK`, and `BLOCK` buttons; desktop keyboard controls are unchanged.

- **100% Procedural Synthesized Audio**:
  - No copyrighted external audio files.
  - All sound effects (whooshes, punch thuds, heavy kick impacts, block clangs, jump whooshes, temple bell gong, KO boom, and UI clicks) are mathematically generated using 16-bit PCM `AudioStreamWAV` synthesis.

---

## Project Structure

```
shadow-fighter/
├── project.godot               # Engine configuration (1280x720, gl_compatibility, 60 FPS)
├── export_presets.cfg          # Web export configuration (single-threaded for GitHub Pages)
├── assets/
│   └── ui/
│       └── icon.svg            # Custom vector icon
├── scenes/
│   ├── main.tscn               # Main scene: Arena, Fighters, Camera, UI, Sound
│   ├── arena.tscn              # Atmospheric dusk arena with parallax and boundaries
│   ├── fighter.tscn            # Base fighter node with body physics, hurtboxes, hitbox
│   ├── ui.tscn                 # Top HUD, combo display, touch controls, match modal
│   └── effects/
│       ├── hit_spark.tscn      # Slash impact sparks
│       └── dust_puff.tscn      # Jump/landing dust
├── scripts/
│   ├── main.gd                 # Scene coordinator and effect instantiator
│   ├── arena.gd                # Procedural dusk sky, mountains, pagodas, mist & petals
│   ├── fighter.gd              # Fighter physics, states, combos, health & damage handling
│   ├── fighter_visuals.gd      # Silhouette character rendering & Verlet ribbon physics
│   ├── ai_controller.gd        # Opponent decision AI (spacing, combos, defense)
│   ├── hitbox.gd               # Damage, knockback, stun and hit detection
│   ├── hurtbox.gd              # Zone hurtbox component
│   ├── stage_camera.gd         # Dynamic camera tracking midpoint, zoom, and screen shake
│   ├── combat_manager.gd       # Round timer, score, K.O. rules and match state
│   ├── hud.gd                  # UI logic, health damage trails, announcements & touch
│   └── sound_generator.gd      # 16-bit PCM procedural audio synthesizer
└── web/
    ├── index.html              # Web build entry point
    ├── index.js                # WebAssembly loader
    ├── index.pck               # Packed game data
    ├── index.wasm              # WebAssembly binary
    └── *.worklet.js            # Web audio worklets
```

---

## Testing & Headless Verification

Run headless execution tests with Godot:

```bash
cd ~/shadow-fighter
godot --headless --path . --quit-after 5
```

The game initializes, runs the physics loop, loads all assets, and exits cleanly with exit code `0`.

---

## Building & Web Export

To re-export the Web build:

```bash
cd ~/shadow-fighter
godot --headless --path . --export-release "Web" web/index.html
```

### GitHub Pages Deployment

The Web export is configured with `variant/thread_support=false` to use Godot's single-threaded WebAssembly runtime. This allows the game to run immediately on GitHub Pages without requiring custom `Cross-Origin-Opener-Policy` (COOP) and `Cross-Origin-Embedder-Policy` (COEP) server headers.

To deploy on GitHub Pages:
1. Commit all files including the `web/` folder.
2. In GitHub repository settings, set GitHub Pages source to deploy from the `/web` folder of your `main` branch (or via a GitHub Actions workflow).
3. Open your GitHub Pages URL to play directly in any modern desktop or mobile browser.
