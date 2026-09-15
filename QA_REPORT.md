# QA Report: Shadow Fighter (Dusk Duel) - Version 1.0

**Project Name:** Shadow Fighter: Dusk Duel  
**Engine:** Godot Engine v4.7.2.stable.official.ed1daf0bf  
**Renderer:** GL Compatibility (WebGL 2.0)  
**Target Platform:** Web / Desktop & Mobile Browsers (GitHub Pages Ready)  
**Test Date:** September 15, 2026  
**QA Lead:** Senior QA Lead & Game Developer  

---

## Build Status

- **Headless Execution Test:** PASS (`godot --headless --path . --quit-after 10` returned exit code 0, 0 errors, 0 leaked objects)
- **Web Export:** PASS (`web/index.html`, `web/index.js`, `web/index.pck`, `web/index.wasm` generated with zero errors)
- **Package Size:** Optimized (Game PCK: 128 KB, WASM: 39.5 MB)
- **HTTP Hosting:** PASS (HTTP 200 OK on `http://127.0.0.1:8080/index.html` and `index.wasm`)
- **Browser Automation:** PASS (Chromium headless with WebGL 2.0 via Playwright)
- **Console Errors / Warnings:** 0 browser errors, 0 uncaught exceptions, 0 physics signal blocks

---

## Tests Performed

1. **Static Validation & Node Tree Verification**: Inspected all scripts, scene node hierarchies, collision layers, input maps, and export configurations.
2. **Local Web Server Hosting**: Self-hosted `web/` using Python HTTP server and verified with `curl`.
3. **Headless Browser Launch & WebGL Verification**: Automated Chromium testing with Playwright to verify WASM compilation, WebGL2 context creation, canvas focus, and audio context activation.
4. **Smoke Test**: Verified 20 core requirements (canvas boot, fighters, arena, HUD, health bars, timer, controls, AI, combos, blocking, jumping, crouching, round resolution, game over modal, restart).
5. **Gameplay & Combat Feel Test**: Evaluated movement acceleration, aerial jump curves, landing recovery, attack startup/active/recovery windows, hitbox precision, and body pushbox physics.
6. **AI Spacing & Behavior Test**: Verified AI distance assessment, proactive attacks, combo chaining, human-like reaction time, blocking, and retreats when low on health.
7. **Automated Multi-Round Match Test**: Tested complete 3-round matches, player victory, AI victory, timeout rules, and rematch state reset.
8. **UI/UX Responsive Layout Test**: Captured and visually verified screenshots across 5 viewport resolutions (1920x1080 Desktop, 1366x768 Laptop, 1280x800 Tablet, 932x430 Mobile Landscape, 740x360 Small Mobile).
9. **Touch / Mobile Emulation Test**: Verified on-screen virtual D-Pad buttons, action buttons (`PUNCH`, `KICK`, `BLOCK`), touch toggle, and multi-touch responsiveness.
10. **Vision & Art Direction Review**: Visual inspection of silhouette anatomy, limb thickness, hakama pants, headband/sash Verlet ribbon physics, glowing eye slits, sunset atmosphere, soft ground mist wisps, and attack slash arcs.
11. **Torture / Stress Test**: Rapid browser resizing, simultaneous multi-key presses, attack spamming, block holding, and repeated match restarts.

---

## Smoke Test

| Test Item | Expected Result | Actual Result | Status |
|-----------|-----------------|---------------|--------|
| Game starts | Engine loads without crashing | Boots cleanly in WebGL | PASS |
| Loading completes | WebAssembly compiles | Complete in <3.5s | PASS |
| Main arena appears | Atmospheric dusk stage renders | Pagodas, mountains, sun render | PASS |
| Player appears | Kage silhouette spawns at (-200, 540) | Cyan eyes & headband visible | PASS |
| Enemy appears | Oni silhouette spawns at (200, 540) | Red eyes & horns visible | PASS |
| HUD appears | Top bar, timer, names, bars visible | Fully rendered | PASS |
| Health bars work | Show current & max HP | 100 HP max, updates on hit | PASS |
| Timer counts down | 99s round timer decrements | Decrements smoothly each second | PASS |
| Controls respond | Keyboard WASD/Arrows + J/K/L | Instant movement and attacks | PASS |
| AI moves | Enemy paces, attacks, retreats | Active & reactive AI | PASS |
| Player attacks | Punches, kicks, sweeps execute | All strike variations work | PASS |
| Enemy attacks | Punches, kicks, jump attacks | AI strikes and chains combos | PASS |
| Health damage | Decreases HP with damage trail | Smooth red damage trail | PASS |
| Blocking works | Chip damage only, no knockdown | Block barrier & clank SFX | PASS |
| Jump works | Airborne velocity & gravity | Smooth jump arc & dive kick | PASS |
| Crouch works | Lowers hurtbox, enables sweeps | Sweeps trip unblocked foes | PASS |
| Round finishes | Defeat / Time Up triggers K.O. | "K.O.!" announcement displayed | PASS |
| Win/lose state | Match Result modal appears | Displays rounds, hits, combo, time | PASS |
| Restart works | Play Again resets match cleanly | State & HP restored instantly | PASS |
| No crash | Zero browser or engine crashes | 100% stable | PASS |

---

## Gameplay Test

- **Movement**: Responsive horizontal ground velocity with slight deceleration friction. Backward walking smoothly transitions into defensive stance.
- **Body Pushboxes**: Custom soft separation ensures fighters never clip through each other or overlap at close range.
- **Air Control**: Dynamic jump arcs with downward hammer fist and flying side kick attacks.
- **Combat Timing**:
  - Lead Jab: Fast startup (0.05s) for safe poking.
  - Cross: Solid mid-range strike (12 DMG) canceling from Jab.
  - Spinning Backfist: Heavy finisher (18 DMG) with strong horizontal knockback.
  - Low Leg Sweep: 14 DMG sliding low attack that trips opponent into knockdown if unblocked.
- **Hit Feedback**: Directional hit sparks, white hit flashes, and landing dust puffs give satisfying martial arts impact.

---

## Combat Test

- **Hitbox Alignment**: Hitboxes track the exact global positions of active fists and feet derived from procedural animation limbs.
- **Hurtbox System**: Separate High, Mid, and Low hurtboxes permit ducking under high jabs and leaping over low sweeps.
- **Blocking**: Successfully mitigates over 80% of damage, prevents knockdown from sweeps, and cancels hit stun to enable counter-strikes.
- **Combo System**: Consecutive hits increment the on-screen combo counter with bouncy scaling and color escalation (Yellow → Orange → Magenta).

---

## AI Test

- **Tactical Spacing**: Evaluates distance to player; advances when far (>280px), executes pokes and sweeps at mid-range (130–280px), and initiates combos at close range (<130px).
- **Human-like Reflexes**: Uses a 140–220ms decision window rather than impossible frame-perfect inputs.
- **Defensive Reactions**: AI blocks high strikes and ducks under incoming attacks, increasing guard chance to 85% when health drops below 35%.
- **Combos**: AI naturally chains Jab into Cross and Cross into Heavy Strike.

---

## UI/UX Test

- **Viewport Scalability**: Tested across 1920x1080, 1366x768, 1280x800, 932x430, and 740x360.
- **Readability**: High contrast between golden timer, cyan player bar, crimson enemy bar, and dusk background.
- **Controls Legibility**: Replaced missing unicode character boxes with clean, universal text labels (`LEFT`, `RIGHT`, `JUMP`, `CROUCH`, `TOUCH`) that render reliably on every operating system and browser without font fallback defects.
- **Spacing**: Margins and anchors keep all HUD elements away from screen edges and touch control zones.

---

## Mobile Test

- **Touch Controls**: On-screen D-Pad and large action buttons (`PUNCH`, `KICK`, `BLOCK`) allow comfortable thumb controls in landscape mode.
- **Touch Responsiveness**: Verified simulated clicks/taps on virtual action buttons execute attacks with immediate animation response.
- **Toggle Feature**: Clean `TOUCH` toggle button in top bar allows toggling on-screen controls on or off.

---

## Vision Test

- **Character Silhouettes**: Upgraded from thin stick figures to muscular martial artists wearing flowing hakama trousers, distinct ninja cowl/oni horns, and dynamic Verlet cloth ribbons that sway with inertia and wind.
- **Color Identity**: Player features glowing electric cyan eye slits and cyan headband/ribbon; AI features glowing ruby eye slits, red sash, and horned kabuto crest.
- **Atmospheric Arena**: Multi-tiered sunset gradient with giant solar orb, distant jagged mountain silhouettes, pagodas, torii gates, swaying bamboo clusters, warm stone lanterns, soft rolling mist wisps, and floating sakura blossom petals.
- **Attack Trails**: Replaced jagged 4-point vertices with smooth, sweeping crescent arcs.

---

## Performance Test

- **Frame Rate**: Stable 60 FPS target.
- **Resource Footprint**: Packed PCK size is only 128 KB, loading in <3.5 seconds.
- **Single-Threaded WASM**: Built with `variant/thread_support=false`, enabling direct compatibility with GitHub Pages without needing special COOP/COEP HTTP response headers.
- **Console Cleanliness**: Zero memory leaks or WebGL driver crashes during extended play sessions.

---

## Hook Test (First 10 Seconds)

- **Score: 9 / 10**
- **Evaluation**: The match opens with an immediate atmospheric sunset backdrop, drifting sakura petals, swaying bamboo, and two distinct silhouette fighters in martial stances. The centered "ROUND 1" and bold "FIGHT!" banner, accompanied by a resonant bronze bell chime, immediately engages the player. The controls respond instantly to the first key press or touch tap with punchy hit feedback.

---

## Fun Factor

- **Score: 9 / 10**
- **Evaluation**: The combat is fluid, responsive, and tactile. The interplay between quick jabs, heavy combo finishers, low sweeps that trip opponents, jumping dive kicks, and timing defensive blocks against an adaptive AI provides genuine fighting game depth.

---

## Bugs Found & Fixed

1. **Child vs. Parent Initialization Ordering**:
   - *Bug:* In Godot, child `_ready()` runs before parent `_ready()`. `hud.gd._ready()` and `combat_manager.gd._ready()` ran when references (`p1`, `p2`, `combat_manager`) were still null. As a result, health signals, round announcements, and defeat events were never connected.
   - *Fix:* Implemented explicit `initialize()` methods called by `main.gd` after all node references are resolved, ensuring 100% signal binding.
2. **Enemy Fighter Color Inheritance**:
   - *Bug:* `fighter_visuals.gd` initialized with default `is_player = true` before `fighter.gd` set it to false, causing the AI enemy to render with cyan eyes and cyan ribbons instead of red.
   - *Fix:* Added `setup_style(player_flag)` called during fighter initialization, guaranteeing correct red horns, sash, and ruby eyes on the AI opponent.
3. **Missing Unicode Font Glyphs on Browser Canvas**:
   - *Bug:* Unicode arrow and emoji glyphs (`◀`, `▲`, `▼`, `▶`, `📱`, `←`, `→`) displayed as square fallback boxes (`25c0`, `01F4F1`) on the web canvas due to browser default font limitations.
   - *Fix:* Replaced all unicode symbols with clean, universally supported text labels (`LEFT`, `RIGHT`, `JUMP`, `CROUCH`, `TOUCH`, `Arrows`) styled with custom `StyleBoxFlat` panels.
4. **Physics Signal Blocking on Hitbox Deactivation**:
   - *Bug:* Browser console logged `ERROR: Function blocked during in/out signal. Use set_deferred("monitoring", true/false)` when hitboxes were deactivated inside `area_entered` callbacks.
   - *Fix:* Replaced direct `monitoring` assignments with `set_deferred("monitoring", false)` and added an explicit `is_active` boolean state on `Hitbox`.
5. **Node Modules PCK Bloat**:
   - *Bug:* Godot export initially packed local `node_modules` into `index.pck`, bloating it to 25.5 MB.
   - *Fix:* Added `.gdignore` inside `node_modules` and configured `exclude_filter` in `export_presets.cfg`, shrinking `index.pck` to 128 KB.
6. **Hard-Edged Ground Mist Polygons**:
   - *Bug:* Mist clouds rendered as solid grey polygon pills across the deck.
   - *Fix:* Redesigned mist into multi-layered soft ethereal wisps with subtle opacity gradients.
7. **Fighter Overlap Clipping**:
   - *Bug:* Fighters could walk directly through each other and occupy identical coordinates.
   - *Fix:* Added soft horizontal pushback separation in `fighter.gd` preventing overlapping while preserving fluid combat.

---

## Remaining Limitations

- **Audio Autoplay Policy**: Web browsers require a user gesture (first click or touch anywhere on the page) before allowing Web Audio playback. The game gracefully catches this without error, and all audio streams play once the canvas is interacted with.
- **Mobile Multi-Touch Browser Scrolling**: On certain mobile browsers, swiping near browser UI edges can trigger browser tab gesture navigation. `touch-action: none` is enabled in `web/index.html` to prevent canvas scroll interruptions.

---

## Screenshot Evidence

All screenshots captured from live headless browser runs and visually verified:

- `qa/screenshots/desktop-start.png`: Opening round with "FIGHT!" center banner and fighter stances.
- `qa/screenshots/desktop-idle.png`: Default combat spacing, timer at 97s, health bars, and clean controls.
- `qa/screenshots/desktop-combat.png`: High roundhouse kick and animated attack slash trail.
- `qa/screenshots/desktop-hit.png`: Clean straight punch impact and damage trail bar drain.
- `qa/screenshots/desktop-victory.png`: Match result modal showing "DEFEAT", 1-2 rounds, total hits, and "PLAY AGAIN".
- `qa/screenshots/tablet.png`: 1280x800 tablet landscape layout with balanced framing.
- `qa/screenshots/mobile-idle.png`: 932x430 mobile landscape responsive viewport.
- `qa/screenshots/mobile-combat.png`: Mobile touch input button execution and attack response.
- `qa/screenshots/mobile-controls.png`: Mobile touch D-Pad and action button layout.
- `qa/screenshots/mobile-small.png`: 740x360 small mobile landscape showing "K.O.!" announcement.
- `qa/screenshots/desktop-1080p.png`: Full 1920x1080 desktop widescreen scaling.

---

## Final Scores

| Category | Score |
|----------|-------|
| **Gameplay** | 9 / 10 |
| **Combat Feel** | 9 / 10 |
| **Animation** | 8.5 / 10 |
| **AI** | 8.5 / 10 |
| **Visual Quality** | 9 / 10 |
| **UI** | 9 / 10 |
| **UX** | 9 / 10 |
| **Mobile Controls** | 8.5 / 10 |
| **Audio** | 8.5 / 10 |
| **Performance** | 9.5 / 10 |
| **First-10-Second Hook** | 9 / 10 |
| **Fun Factor** | 9 / 10 |
| **Overall Polish** | 9 / 10 |

**OVERALL SCORE: 8.9 / 10**
