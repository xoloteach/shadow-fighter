class_name ProgressionManager
extends Node

static var instance: ProgressionManager

var equipment_catalog: Dictionary = {}
var opponents_catalog: Dictionary = {}
var story_catalog: Dictionary = {}

# Active combat configuration
var current_fight_data: Dictionary = {}
var is_survival_mode: bool = false
var survival_round: int = 1
var survival_max_rounds: int = 6
var survival_carry_hp: float = 100.0

func _init() -> void:
	instance = self
	_load_catalogs()

func _load_catalogs() -> void:
	equipment_catalog = _load_json("res://data/equipment.json")
	opponents_catalog = _load_json("res://data/opponents.json")
	story_catalog = _load_json("res://story/story.json")

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		return {}
	var json = JSON.new()
	var err = json.parse(f.get_as_text())
	if err == OK and json.data is Dictionary:
		return json.data
	return {}

func get_item_data(item_id: String) -> Dictionary:
	for cat in ["weapons", "armors", "helmets", "ranged", "special"]:
		var items: Array = equipment_catalog.get(cat, [])
		for it in items:
			if it.get("id", "") == item_id:
				return it
	return {}

func get_player_power(save: SaveManager) -> int:
	var power: float = 10.0 # base unarmed
	var equipped = save.data.get("inventory", {}).get("equipped", {})
	
	# Melee
	var weapon_id = equipped.get("melee", "")
	if weapon_id != "":
		var w = get_item_data(weapon_id)
		var upg = save.get_upgrade_level(weapon_id)
		var base_dmg = float(w.get("base_damage", 10.0))
		power += base_dmg * (1.0 + 0.22 * upg) * 3.5
	
	# Armor
	var armor_id = equipped.get("armor", "")
	if armor_id != "":
		var a = get_item_data(armor_id)
		var upg = save.get_upgrade_level(armor_id)
		var def = float(a.get("defense", 10.0))
		power += def * (1.0 + 0.20 * upg) * 1.5
	
	# Helmet
	var helm_id = equipped.get("helmet", "")
	if helm_id != "":
		var h = get_item_data(helm_id)
		var upg = save.get_upgrade_level(helm_id)
		var def = float(h.get("head_defense", 8.0))
		power += def * (1.0 + 0.20 * upg) * 1.2
	
	return int(round(power))

func get_difficulty(player_power: int, opponent_power: int) -> Dictionary:
	var delta = opponent_power - player_power
	if delta <= -15:
		return {"label": "EASY", "color": Color(0.2, 0.9, 0.4), "delta": delta}
	elif delta <= 12:
		return {"label": "FAIR", "color": Color(0.2, 0.85, 1.0), "delta": delta}
	elif delta <= 38:
		return {"label": "TOUGH", "color": Color(1.0, 0.65, 0.15), "delta": delta}
	else:
		return {"label": "BRUTAL", "color": Color(1.0, 0.2, 0.3), "delta": delta}

func get_player_effective_stats(save: SaveManager) -> Dictionary:
	var equipped = save.data.get("inventory", {}).get("equipped", {})
	var weapon_id = equipped.get("melee", "")
	var weapon_data = get_item_data(weapon_id)
	var w_upg = save.get_upgrade_level(weapon_id)
	
	var base_dmg = float(weapon_data.get("base_damage", 10.0))
	var effective_dmg = base_dmg * (1.0 + 0.22 * w_upg)
	
	var armor_id = equipped.get("armor", "")
	var armor_data = get_item_data(armor_id)
	var a_upg = save.get_upgrade_level(armor_id)
	var effective_def = float(armor_data.get("defense", 10.0)) * (1.0 + 0.20 * a_upg)
	var bonus_hp = float(armor_data.get("health_bonus", 0.0))
	
	var helm_id = equipped.get("helmet", "")
	var helm_data = get_item_data(helm_id)
	var h_upg = save.get_upgrade_level(helm_id)
	var effective_hdef = float(helm_data.get("head_defense", 8.0)) * (1.0 + 0.20 * h_upg)
	
	return {
		"weapon_type": weapon_data.get("weapon_type", "katana"),
		"attack_power": effective_dmg,
		"reach_mult": float(weapon_data.get("reach_mult", 1.0)),
		"speed_mult": float(weapon_data.get("speed_mult", 1.0)),
		"defense": effective_def,
		"head_defense": effective_hdef,
		"max_health": 100.0 + bonus_hp,
		"passive": weapon_data.get("passive", "")
	}
