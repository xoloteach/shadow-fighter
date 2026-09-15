# Shadow Fighter V3 — Progression Research & Systems Study

## 1. High-Level Progression Reference: Classic 2D Fighting Progression Games

Classic martial-arts progression fighters (such as *Shadow Fight 2*) achieve enduring engagement through a tight, clear, repeating loop:
1. **Dojo / Hub**: The tactile home base where the player inspects their fighter, equips gear, and tests techniques against a dummy.
2. **Campaign / World Map**: A chapter-based node map depicting territorial progression across distinct thematic provinces.
3. **Multi-Track Combat Progression**:
   - **Story & Bodyguards/Elites**: Fixed narrative checkpoints gating the regional Boss.
   - **Tournament / Progression Ladder**: Sequential tier fights providing predictable XP and primary currency.
   - **Challenges**: Rule-altering modifiers (hot floor, time attack, no kicking, invisible enemy, reversed controls) teaching combat versatility.
   - **Survival**: Consecutive enemy waves carrying over fractional health for high-efficiency currency farming.
   - **Duels**: Timed/optional side-bouts with randomized equipment.
4. **Gear & Economy Loop**:
   - Primary weapon dictates basic strikes, reach, speed, and recovery.
   - Armor and Helmets boost body and head effective health / defense.
   - Upgrades (levels 1–5 per chapter tier) keep equipment relevant before forcing tier progression.
   - Difficulty estimates (*Easy, Fair, Tough, Brutal*) reflect the mathematical delta between player equipment rating and opponent stats.

---

## 2. Comparative Systems Mapping: Reference vs. Original Implementation

| System Component | Genre Reference (Shadow Fight 2) | Shadow Fighter V3 Original Design |
|---|---|---|
| **World & Lore** | Gates of Shadows, Demon warlords (Lynx, Hermit, Butcher) | **The Shattered Seal of Dusk**: An ancient covenant between dusk spirits and mortal warrior clans. Corrupted wardens seek to harness twilight chi. |
| **Protagonist & Mentor** | Shadow (silhouetted warrior) & Sensei | **Kage (Wandering Blade)**, guided by **Grandmaster Toran (Blind Bellkeeper)** and artisan **Aoi (Weaponsmith)**. |
| **Faction / Foes** | The Ninja Assassin Order, Hermit's Disciples | **The Eclipse Syndicate**: Obsidian Blades, Rain Dancers, and Ashbound Guard. |
| **Chapter 1** | Hero's Rebirth / Act I (Forest / Ninja Clan) | **Chapter 1: "The Broken Bell"** (Highland Monastery & Mist Valley). |
| **Chapter 2** | Secret Path / Act II (Riverside / Bamboo School) | **Chapter 2: "Lanterns in the Rain"** (Canal District & Pavilion of Whispers). |
| **Chapter 3** | Trail of Blood / Act III (Sunken City / Warlord) | **Chapter 3: "Ashes of the Banner"** (Fortress Citadel & Smoldering Bastion). |
| **Equipment Slots** | Weapon, Armor, Helm, Ranged, Magic | **Melee (Primary Weapon)**, **Armor (Robes/Cuirass)**, **Helmet (Cowl/Mask)**, **Ranged (Thrown Darts/Bombs)**, **Spirit Technique (Dusk Arts)**. |
| **Combat Input** | Virtual joystick + 2 buttons (Punch, Kick) | **8-direction virtual analog joystick + Punch, Kick, Block** (independent block button with high/mid/low directional guard). |
| **Hit Stun & Stances** | Head, body stuns, ragdoll knockdown | **Precise 4-zone hit reactions** (head, body, leg, heavy), knockdown to rising recovery animation. |
| **Economy** | Coins + Gems (freemium mobile model) | **Monshu (Silver Coins)** as core earned currency + **Obsidian Seals (Chapter Trophies)** earned strictly via bosses/elites. Zero paywalls. |
| **Save Persistence** | Cloud / mobile accounts with cooldown timers | **Zero timers / instant instant offline HTML5 localStorage / JSON save system**. |

---

## 3. Progression Curve & Economy Mathematics

### 3.1 Level & XP Curve
$$XP(L) = 120 \times L^{1.45}$$
- Level 1: 0 XP (Start)
- Level 2: 120 XP (Unlocked after early Chapter 1 fights)
- Level 3: 310 XP
- Level 4: 560 XP
- Level 5: 860 XP (Chapter 1 Boss threshold)
- Level 6: 1220 XP (Chapter 2 start)
- Level 7: 1630 XP
- Level 8: 2090 XP
- Level 9: 2600 XP (Chapter 2 Boss threshold)
- Level 10: 3160 XP (Chapter 3 start)
- Level 11: 3770 XP
- Level 12: 4430 XP (Chapter 3 Boss threshold)

### 3.2 Equipment Power Rating Formula
$$\text{Gear Power} = \text{Base Stat} \times (1.0 + 0.22 \times \text{Upgrade Level})$$
- Attack Rating: Governs damage dealt per hit.
- Defense Rating: Governs damage mitigation and block resilience.
- Difficulty Delta:
  $$\Delta = \text{Opponent Rating} - \text{Player Rating}$$
  - $\Delta \le -15$: **EASY** (Green)
  - $-15 < \Delta \le 10$: **FAIR** (Cyan)
  - $10 < \Delta \le 35$: **TOUGH** (Orange)
  - $\Delta > 35$: **BRUTAL** (Red)

---

## 4. Fight Types Architecture
1. **Story Fights (Camp)**: Fixed narrative ladder against distinct opponents; awards high XP and unlocks chapter milestones.
2. **Tournament**: 8–10 sequential tiered opponents per chapter; primary source of coins and equipment unlock readiness.
3. **Challenges**: Modifiers that test player mastery (e.g., *No Jumping*, *Bleed on Hit*, *Ring Out Threat*, *Blinding Mist*).
4. **Survival**: 6–8 consecutive opponents with partial HP recovery (+25% HP between rounds); scaling coin payouts.
5. **Dojo Training**: Unrestricted practice against an adaptable wooden puppet / dummy with real-time frame/damage diagnostics.
