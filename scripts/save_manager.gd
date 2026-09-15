class_name SaveManager
extends Node

const SAVE_PATH = "user://shadow_save_v3.json"
const CURRENT_VERSION = 3

signal save_loaded()
signal save_updated()

var data: Dictionary = {}

func _ready() -> void:
	load_game()

func get_default_save() -> Dictionary:
	return {
		"save_version": CURRENT_VERSION,
		"player": {
			"name": "KAGE",
			"level": 1,
			"xp": 0,
			"coins": 200,
			"shards": 0,
			"stats": {
				"wins": 0,
				"losses": 0,
				"total_fights": 0,
				"max_combo": 0
			}
		},
		"progression": {
			"current_chapter": 1,
			"completed_fights": [],
			"unlocked_features": ["melee", "armor", "helmet"]
		},
		"inventory": {
			"equipped": {
				"melee": "fists_bare",
				"armor": "gi_novice",
				"helmet": "headband_novice",
				"ranged": "",
				"special": ""
			},
			"owned": ["fists_bare", "gi_novice", "headband_novice"],
			"upgrades": {
				"fists_bare": 0,
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

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		data = get_default_save()
		save_game()
		save_loaded.emit()
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		data = get_default_save()
		save_loaded.emit()
		return
	
	var json_str = file.get_as_text()
	var json = JSON.new()
	var err = json.parse(json_str)
	if err == OK and json.data is Dictionary:
		data = json.data
		_migrate_save()
	else:
		data = get_default_save()
		save_game()
	
	save_loaded.emit()

func save_game() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_str = JSON.stringify(data, "\t")
		file.store_string(json_str)
		file.close()
	save_updated.emit()

func _migrate_save() -> void:
	var ver = data.get("save_version", 1)
	if ver < CURRENT_VERSION:
		# Migrate older version structure safely without losing player progress
		data["save_version"] = CURRENT_VERSION
		var defaults = get_default_save()
		for key in defaults.keys():
			if not data.has(key):
				data[key] = defaults[key]
		save_game()

func add_coins(amount: int) -> void:
	var current = data.get("player", {}).get("coins", 0)
	data["player"]["coins"] = max(0, current + amount)
	save_game()

func add_xp(amount: int) -> Dictionary:
	var player = data.get("player", {})
	var current_xp = player.get("xp", 0) + amount
	var current_level = player.get("level", 1)
	var did_level_up = false
	
	# XP Threshold curve: 120 * Level^1.45
	var next_threshold = get_xp_for_level(current_level + 1)
	while current_xp >= next_threshold and current_level < 15:
		current_level += 1
		did_level_up = true
		next_threshold = get_xp_for_level(current_level + 1)
		_check_level_unlocks(current_level)
	
	player["xp"] = current_xp
	player["level"] = current_level
	save_game()
	
	return {"leveled_up": did_level_up, "new_level": current_level, "total_xp": current_xp}

func get_xp_for_level(lvl: int) -> int:
	if lvl <= 1:
		return 0
	return int(round(120.0 * pow(float(lvl - 1), 1.45)))

func _check_level_unlocks(lvl: int) -> void:
	var unlocked = data["progression"]["unlocked_features"]
	if lvl >= 5 and not unlocked.has("ranged"):
		unlocked.append("ranged")
	if lvl >= 9 and not unlocked.has("special"):
		unlocked.append("special")

func is_fight_completed(fight_id: String) -> bool:
	var list: Array = data.get("progression", {}).get("completed_fights", [])
	return list.has(fight_id)

func mark_fight_completed(fight_id: String) -> void:
	var list: Array = data["progression"]["completed_fights"]
	if not list.has(fight_id):
		list.append(fight_id)
		save_game()

func is_item_owned(item_id: String) -> bool:
	var owned: Array = data.get("inventory", {}).get("owned", [])
	return owned.has(item_id)

func buy_item(item: Dictionary) -> bool:
	var price: int = int(item.get("price", 0))
	var player_coins: int = int(data["player"]["coins"])
	if player_coins < price:
		return false
	
	data["player"]["coins"] -= price
	var item_id: String = item["id"]
	if not data["inventory"]["owned"].has(item_id):
		data["inventory"]["owned"].append(item_id)
	data["inventory"]["upgrades"][item_id] = 0
	save_game()
	return true

func equip_item(slot: String, item_id: String) -> void:
	data["inventory"]["equipped"][slot] = item_id
	save_game()

func upgrade_item(item_id: String, cost: int) -> bool:
	var coins = data["player"]["coins"]
	if coins < cost:
		return false
	var current_upg: int = data["inventory"]["upgrades"].get(item_id, 0)
	if current_upg >= 5:
		return false
	data["player"]["coins"] -= cost
	data["inventory"]["upgrades"][item_id] = current_upg + 1
	save_game()
	return true

func get_equipped_item(slot: String) -> String:
	return data.get("inventory", {}).get("equipped", {}).get(slot, "")

func get_upgrade_level(item_id: String) -> int:
	return int(data.get("inventory", {}).get("upgrades", {}).get(item_id, 0))

func record_fight_stats(won: bool, combo: int) -> void:
	var stats = data["player"]["stats"]
	stats["total_fights"] = stats.get("total_fights", 0) + 1
	if won:
		stats["wins"] = stats.get("wins", 0) + 1
	else:
		stats["losses"] = stats.get("losses", 0) + 1
	if combo > stats.get("max_combo", 0):
		stats["max_combo"] = combo
	save_game()
