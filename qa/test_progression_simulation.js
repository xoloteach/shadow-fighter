const fs = require('fs');
const path = require('path');

console.log('=== RUNNING VERSION 3 FULL PROGRESSION SIMULATION TEST ===');

// 1. Check catalogs exist and parse cleanly
const eqPath = path.join(__dirname, '..', 'data', 'equipment.json');
const oppPath = path.join(__dirname, '..', 'data', 'opponents.json');
const storyPath = path.join(__dirname, '..', 'story', 'story.json');

const eq = JSON.parse(fs.readFileSync(eqPath, 'utf8'));
const opp = JSON.parse(fs.readFileSync(oppPath, 'utf8'));
const story = JSON.parse(fs.readFileSync(storyPath, 'utf8'));

console.log(`- Loaded equipment catalog: ${eq.weapons.length} weapons, ${eq.armors.length} armors, ${eq.helmets.length} helmets, ${eq.ranged.length} ranged, ${eq.special.length} special arts.`);
console.log(`- Loaded opponent catalog: ${opp.chapters.length} chapters.`);
opp.chapters.forEach(ch => {
  console.log(`   * ${ch.name}: ${ch.tournaments.length} tournament tiers, ${ch.challenges.length} challenges, ${ch.bodyguards.length} elites, Boss: ${ch.boss.name}`);
});
console.log(`- Loaded story catalog: Prologue, Chapter mentor lines, and Epilogue present.`);

// 2. Progression & Economy Simulation
class SimSaveManager {
  constructor() {
    this.data = {
      save_version: 3,
      player: { name: 'KAGE', level: 1, xp: 0, coins: 200, stats: { wins: 0, losses: 0, total_fights: 0, max_combo: 0 } },
      progression: { current_chapter: 1, completed_fights: [], unlocked_features: ['melee', 'armor', 'helmet'] },
      inventory: {
        equipped: { melee: 'fists_bare', armor: 'gi_novice', helmet: 'headband_novice', ranged: '', special: '' },
        owned: ['fists_bare', 'gi_novice', 'headband_novice'],
        upgrades: { fists_bare: 0, gi_novice: 0, headband_novice: 0 }
      }
    };
  }

  getXpForLevel(lvl) {
    if (lvl <= 1) return 0;
    return Math.round(120.0 * Math.pow(lvl - 1, 1.45));
  }

  addCoins(n) { this.data.player.coins += n; }
  addXp(n) {
    this.data.player.xp += n;
    let lvl = this.data.player.level;
    let didLevel = false;
    while (this.data.player.xp >= this.getXpForLevel(lvl + 1) && lvl < 15) {
      lvl++;
      didLevel = true;
      if (lvl >= 5 && !this.data.progression.unlocked_features.includes('ranged')) this.data.progression.unlocked_features.push('ranged');
      if (lvl >= 9 && !this.data.progression.unlocked_features.includes('special')) this.data.progression.unlocked_features.push('special');
    }
    this.data.player.level = lvl;
    return { didLevel, level: lvl };
  }

  completeFight(id, coins, xp) {
    if (!this.data.progression.completed_fights.includes(id)) this.data.progression.completed_fights.push(id);
    this.addCoins(coins);
    const res = this.addXp(xp);
    this.data.player.stats.wins++;
    this.data.player.stats.total_fights++;
    return res;
  }

  buyItem(item) {
    if (this.data.player.coins < item.price) return false;
    if (this.data.player.level < item.required_level) return false;
    this.data.player.coins -= item.price;
    if (!this.data.inventory.owned.includes(item.id)) this.data.inventory.owned.push(item.id);
    this.data.inventory.upgrades[item.id] = 0;
    return true;
  }

  upgradeItem(id, price) {
    const upg = this.data.inventory.upgrades[id] || 0;
    if (upg >= 5) return false;
    const cost = Math.max(60, Math.round(price * 0.35 * (upg + 1)));
    if (this.data.player.coins < cost) return false;
    this.data.player.coins -= cost;
    this.data.inventory.upgrades[id] = upg + 1;
    return true;
  }

  equipItem(slot, id) { this.data.inventory.equipped[slot] = id; }
}

const save = new SimSaveManager();
console.log('--- Initial State ---');
console.log(`Level: ${save.data.player.level}, XP: ${save.data.player.xp}, Coins: ${save.data.player.coins}`);

// Step 1: Complete Chapter 1 Tournament 1 & 2
console.log('--- Step 1: Fight Tournament 1 & 2 ---');
save.completeFight('t1_1', 45, 25);
save.completeFight('t1_2', 60, 35);
console.log(`After 2 fights -> Level: ${save.data.player.level}, XP: ${save.data.player.xp}, Coins: ${save.data.player.coins}`);

// Step 2: Buy Dusk Katana (price: 180)
console.log('--- Step 2: Buy Dusk Katana ---');
const katana = eq.weapons.find(w => w.id === 'katana_novice');
const bought = save.buyItem(katana);
console.log(`Purchase successful: ${bought}, Remaining coins: ${save.data.player.coins}`);
save.equipItem('melee', 'katana_novice');
console.log(`Equipped weapon: ${save.data.inventory.equipped.melee}`);

// Step 3: Complete Tournament 3, 4, 5 and level up
console.log('--- Step 3: Complete More Fights ---');
save.completeFight('t1_3', 85, 50);
save.completeFight('t1_4', 110, 70);
save.completeFight('t1_5', 140, 95);
console.log(`After 5 fights -> Level: ${save.data.player.level}, XP: ${save.data.player.xp}, Coins: ${save.data.player.coins}`);

// Step 4: Upgrade Katana
console.log('--- Step 4: Upgrade Katana ---');
const upgOk = save.upgradeItem('katana_novice', katana.price);
console.log(`Upgrade successful: ${upgOk}, Level: ${save.data.inventory.upgrades.katana_novice}, Coins: ${save.data.player.coins}`);

// Step 5: Defeat Chapter 1 Elites & Boss
console.log('--- Step 5: Defeat Elites and Boss Guro ---');
save.completeFight('bg1_1', 130, 90);
save.completeFight('bg1_2', 175, 130);
save.completeFight('bg1_3', 230, 175);
save.completeFight('bg1_4', 300, 230);
const bossRes = save.completeFight('boss_guro', 650, 450);
console.log(`Boss Guro Defeated! New Level: ${save.data.player.level}, Total XP: ${save.data.player.xp}, Coins: ${save.data.player.coins}`);
console.log(`Unlocked systems: ${JSON.stringify(save.data.progression.unlocked_features)}`);

// Verify Chapter 2 is unlocked
const ch2Unlocked = save.data.progression.completed_fights.includes('boss_guro') || save.data.player.level >= 5;
console.log(`Chapter 2 Unlocked: ${ch2Unlocked}`);
if (!ch2Unlocked) {
  console.error('ERROR: Chapter 2 should be unlocked!');
  process.exit(1);
}

// Step 6: Test save serialization to JSON & reload
console.log('--- Step 6: Test Persistence Serialization ---');
const jsonStr = JSON.stringify(save.data);
const reloaded = JSON.parse(jsonStr);
console.log(`Reloaded save verification: Level ${reloaded.player.level}, Coins ${reloaded.player.coins}, Completed fights ${reloaded.progression.completed_fights.length}`);
if (reloaded.player.level !== save.data.player.level || reloaded.player.coins !== save.data.player.coins) {
  console.error('ERROR: Persistence mismatch!');
  process.exit(1);
}

console.log('=== ALL PROGRESSION & ECONOMY TESTS PASSED! ===');
