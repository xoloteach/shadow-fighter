# Version 3 QA Report — Bell of Twilight Campaign

**Build:** Godot 4.7.2 Web export, compatibility renderer, single-threaded WebAssembly  
**Branch:** `v3-progression`

## Result: PASS

| Area | Validation | Result |
|---|---|---|
| Script/scene load | `godot --headless --path . --quit-after 4` | PASS |
| Web build | `godot --headless --export-release "Web" web/index.html` | PASS |
| V3 UI flow | `qa/test_v3_full.js`: dojo, armory, shop, training, profile, map, preview, combat, rewards, mobile | PASS, 0 browser errors |
| Economy/progression | `qa/test_progression_simulation.js`: catalog parsing, XP, currency, purchase, upgrade, chapter unlock, serialization | PASS |
| Survival | `qa/test_survival_mode.js`: launch, preview, Wave 1/6 setup | PASS, 0 browser errors |
| Character framing | `qa/test_scale_viewports.js`: 1920×1080, 1366×768, 1280×800, 932×430, 740×360 | PASS |
| Blender assets | `blender -b -P blender/scripts/render_v3_bosses.py` | PASS; three original boss portraits rendered |

## Visual evidence

- `qa/screenshots/v3-dojo.png`
- `qa/screenshots/v3-armory.png`
- `qa/screenshots/v3-shop.png`
- `qa/screenshots/v3-training.png`
- `qa/screenshots/v3-map.png`
- `qa/screenshots/v3-fight-preview.png`
- `qa/screenshots/v3-combat.png`
- `qa/screenshots/v3-rewards.png`
- `qa/screenshots/v3-mobile-landscape.png`
- `qa/screenshots/v3-survival-preview.png`
- `qa/screenshots/v3-survival-wave-1.png`

## Notes

- Survival is a six-wave, 55-second-per-wave gauntlet. Player HP carries between waves with an 18% max-HP recovery; enemy health and attack scale per wave.
- Challenge modifiers are applied at match start. Floor burn applies periodic environmental damage to both fighters.
- AI profiles clear stale input each decision and use per-profile timing, guard, retreat, anti-air, and combo behavior.
- GitHub Pages deployment is pending the V3 branch merge/push and `gh-pages` export publish.
