# Shadow Fighter V3 — Complete Architecture & Systems Design

## 1. Executive Summary & V3 Scope
Version 3 elevates *Shadow Fighter* from an arena prototype into an expansive, narrative-driven 2D martial-arts progression game. 
- **Offline 3D Blender Pipeline retained**: All characters, weapons, and armor variants are rendered to optimized 2D sprite atlases.
- **Enhanced Scale**: Both fighters are scaled up by exactly **1.2x (+20%)** with ground pivots, hitboxes, hurtboxes, cameras, and collision boundaries recalibrated.
- **Dojo Hub & Menus**: Seamless hub offering Dojo Training, World Map, Equipment Armory, Merchant Shop, Fighter Profile, and Settings.
- **3 Epic Original Chapters**: "The Broken Bell", "Lanterns in the Rain", and "Ashes of the Banner".
- **3 Unique Chapter Bosses + 12 Bodyguards/Elites + 24 Tournament Challengers**.
- **Comprehensive Equipment System**: 5 slots (Melee Weapon, Armor, Helmet, Ranged, Special Technique) with visual changes on the fighter.
- **Multi-Track Combat**: Story nodes, Tournament ladder, Challenges with custom rules, and multi-wave Survival.
- **Persistent Save Engine**: Versioned local/Web storage retaining coins, equipment, upgrades, chapter progress, and statistics.

---

## 2. Character Scale & Framing Recalibration (+20% / 1.2x)

### 2.1 Spatial Parameters
- **Fighter Sprite Scale**: V2 was scaled at `Vector2(0.9, 0.9)` procedural / `Vector2(1.0, 1.0)` blender. In V3, visual scale becomes `Vector2(1.20, 1.20)`.
- **Fighter Collision Capsule**:
  - Height: Increased from $108\text{px}$ to $130\text{px}$.
  - Radius: Increased from $20\text{px}$ to $24\text{px}$.
  - Position: Adjusted relative to ground pivot $(0, -65)$.
- **Combat Hitbox / Hurtbox Dimensions**:
  - Head hurtbox radius: $14\text{px} \to 17\text{px}$, center $(0, -112)$.
  - Body hurtbox height: $44\text{px} \to 53\text{px}$, center $(0, -66)$.
  - Leg hurtbox height: $36\text{px} \to 43\text{px}$, center $(0, -22)$.
  - Attack hitboxes: Reach and extents scaled by $1.20$ to maintain authentic visual-physical alignment.
- **Camera Zoom & Framing**:
  - Camera zoom baseline: Adjusted from `Vector2(1.0, 1.0)` to `Vector2(0.92, 0.92)` so that fighters dominate the screen with clear silhouette details while maintaining tactical combat space.
  - Stage floor: Fixed at $Y = 560$, giving natural clearance above the bottom help/virtual controls bar.

---

## 3. World & Narrative Bible

### 3.1 Lore
Across the provinces of Yamashiro, the ancient *Bell of Twilight* once rang at sundown, purifying corrupted spiritual energy. When warlord **Lord Kurozuka** fractured the Bell into Obsidian Shards, darkness bled into mortal clans. 
Our silent protagonist, **Kage**, an exiled warrior bound by the Dusk Ribbon, embarks on a pilgrimage to reclaim the shards and silence the corrupt warlords.

### 3.2 The Three Chapters
1. **Chapter 1: The Broken Bell**
   - **Location**: Mount Toran & The Highland Monastery.
   - **Atmosphere**: Rustling maple leaves, twilight sun, ruined bell towers.
   - **Mentor**: Grandmaster Toran (The Blind Bellkeeper).
   - **Boss**: **Warden Guro (The Iron Cleaver)** — Heavy, armored monk wielding a cleaving temple spade. Unstoppable hyper-armor on windup.
   - **Elites**: Swift Crow, Iron Boar, Mist Viper, Red Heron.
2. **Chapter 2: Lanterns in the Rain**
   - **Location**: Kawagishi Canal District & The Floating Pavilion.
   - **Atmosphere**: Steady nocturnal rain, glowing paper lanterns, rippling reflection puddles.
   - **Merchant/Ally**: Aoi (Silk Artisan & Blade Forger).
   - **Boss**: **Madame Lin (The Rain Weaver)** — Graceful duel wielding Twin Crescent Kama with rapid multi-hit flurries and throwing rain daggers.
   - **Elites**: Shadow Carp, River Reed, Ghost Crane, Drowning Willow.
3. **Chapter 3: Ashes of the Banner**
   - **Location**: Smoldering Bastion & The Obsidian Citadel.
   - **Atmosphere**: Ash drifts, burning battlements, war drum silhouettes.
   - **Boss**: **General Kurozuka (The Ash Sovereign)** — Heavy Odachi swordmaster with devastating sweeping ground quakes and dusk chi shockwaves.
   - **Elites**: Ash Hound, Cinder Vanguard, Black Banner, Flame Fang.

---

## 4. Equipment System Architecture

### 4.1 Equipment Slots
1. **Melee / Primary**: Dictates weapon style, basic damage, combo reach, attack speed, and sound profile.
   - *Fists / Bare Hands* (Speed: Fast, Range: Short, Mobility: High)
   - *Twin Daggers* (Speed: Very Fast, Range: Short-Mid, Multi-hit)
   - *Curved Katana* (Speed: Balanced, Range: Medium, Precision)
   - *Iron Cestus* (Speed: Fast, Range: Short, High Stun)
   - *Kama Sickles* (Speed: Fast, Range: Medium, Bleed/Hook)
   - *Heavy Guandao* (Speed: Slower, Range: Long, Heavy Knocks)
   - *Obsidian Nodachi* (Speed: Moderate, Range: Very Long, Massive Cut)
2. **Armor**: Governs body defense, max HP multiplier, and physical resistance.
3. **Helmet**: Governs head defense, critical damage mitigation, and focus generation.
4. **Ranged (Secondary)**: Unlocked at Chapter 2. Consumable throwing darts, kunai, or smoke bombs.
5. **Special Technique**: Unlocked at Chapter 3. Energy-meter art (e.g. *Dusk Dash*, *Shadow Eruption*, *Spirit Parry*).

### 4.2 Upgrade Tiers & Rarity
- **Rarity**:
  - `Common` (Slate gray outline)
  - `Refined` (Steel cyan outline, +15% base stats)
  - `Rare` (Amber gold outline, +30% base stats, 1 passive trait)
  - `Masterwork` (Obsidian violet outline, +50% base stats, enhanced passive trait)
- **Upgrades**: Each item can be upgraded up to Level 5 using Monshu coins.

---

## 5. UI / UX Navigation Flow

```
                  [ TITLE / SAVE LOAD ]
                            │
                            ▼
                        [ DOJO ] ◄──────────────┐
       ┌───────────┬────────┴─────────┬─────────┴─────────┐
       ▼           ▼                  ▼                   ▼
    [ MAP ]   [ ARMORY ]           [ SHOP ]          [ TRAINING ]
       │      (Equip/Stats)    (Buy/Upgrade)       (Dummy/Moves)
       ▼
 [ FIGHT PREVIEW ]
 (Opponent / Rules / Difficulty)
       │
       ▼
 [ COMBAT ARENA ]
       │
       ▼
[ VICTORY / REWARDS ] ──► (XP, Coins, Level Up Modal) ──┘
```

---

## 6. Save State Schema (Version 3)
```json
{
  "save_version": 3,
  "player": {
    "name": "Kage",
    "level": 1,
    "xp": 0,
    "coins": 250,
    "shards": 0,
    "stats": { "wins": 0, "losses": 0, "total_fights": 0, "max_combo": 0 }
  },
  "progression": {
    "current_chapter": 1,
    "completed_fights": [],
    "unlocked_features": ["melee", "armor", "helmet"]
  },
  "inventory": {
    "equipped": {
      "melee": "katana_novice",
      "armor": "gi_novice",
      "helmet": "headband_novice",
      "ranged": "",
      "special": ""
    },
    "owned": ["katana_novice", "gi_novice", "headband_novice"],
    "upgrades": {
      "katana_novice": 0,
      "gi_novice": 0,
      "headband_novice": 0
    }
  },
  "settings": {
    "sfx_volume": 1.0,
    "music_volume": 0.8,
    "touch_enabled": true
  }
}
```
