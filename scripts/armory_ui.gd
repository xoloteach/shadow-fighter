class_name ArmoryUI
extends Control

signal return_to_dojo()
signal loadout_changed()

var current_slot: String = "melee"

@onready var btn_back: Button = $TopHeader/BtnBack
@onready var btn_slot_melee: Button = $SlotTabs/BtnMelee
@onready var btn_slot_armor: Button = $SlotTabs/BtnArmor
@onready var btn_slot_helmet: Button = $SlotTabs/BtnHelmet
@onready var btn_slot_ranged: Button = $SlotTabs/BtnRanged
@onready var btn_slot_special: Button = $SlotTabs/BtnSpecial

@onready var items_container: VBoxContainer = $ItemsList/Scroll/VBox
@onready var label_details_name: Label = $ItemDetails/Panel/VBox/ItemName
@onready var label_details_stats: Label = $ItemDetails/Panel/VBox/StatsLabel
@onready var label_details_passive: Label = $ItemDetails/Panel/VBox/PassiveLabel
@onready var btn_equip: Button = $ItemDetails/Panel/VBox/BtnEquip

var selected_item_id: String = ""

func _ready() -> void:
	btn_back.pressed.connect(func(): return_to_dojo.emit())
	btn_slot_melee.pressed.connect(func(): _select_slot("melee"))
	btn_slot_armor.pressed.connect(func(): _select_slot("armor"))
	btn_slot_helmet.pressed.connect(func(): _select_slot("helmet"))
	btn_slot_ranged.pressed.connect(func(): _select_slot("ranged"))
	btn_slot_special.pressed.connect(func(): _select_slot("special"))
	btn_equip.pressed.connect(_on_equip_pressed)

func open_armory() -> void:
	visible = true
	_select_slot("melee")

func _select_slot(slot: String) -> void:
	current_slot = slot
	btn_slot_melee.modulate = Color(1.2, 1.2, 1.2) if slot == "melee" else Color(0.7, 0.7, 0.7)
	btn_slot_armor.modulate = Color(1.2, 1.2, 1.2) if slot == "armor" else Color(0.7, 0.7, 0.7)
	btn_slot_helmet.modulate = Color(1.2, 1.2, 1.2) if slot == "helmet" else Color(0.7, 0.7, 0.7)
	btn_slot_ranged.modulate = Color(1.2, 1.2, 1.2) if slot == "ranged" else Color(0.7, 0.7, 0.7)
	btn_slot_special.modulate = Color(1.2, 1.2, 1.2) if slot == "special" else Color(0.7, 0.7, 0.7)
	_populate_owned_items()

func _populate_owned_items() -> void:
	for c in items_container.get_children():
		c.queue_free()
	
	var owned_ids: Array = SaveData.data.get("inventory", {}).get("owned", [])
	var equipped_id = SaveData.get_equipped_item(current_slot)
	
	var cat_key = "weapons" if current_slot == "melee" else (current_slot + "s" if current_slot != "special" else "special")
	var catalog_items: Array = Progression.equipment_catalog.get(cat_key, [])
	
	var found_first = false
	for it in catalog_items:
		var i_id: String = it.get("id", "")
		if owned_ids.has(i_id):
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(0, 48)
			var is_eq = (i_id == equipped_id)
			var upg = SaveData.get_upgrade_level(i_id)
			var upg_str = " +%d" % upg if upg > 0 else ""
			btn.text = "%s%s%s" % [it.get("name", "Item"), upg_str, " [EQUIPPED]" if is_eq else ""]
			if is_eq:
				btn.modulate = Color(0.3, 0.9, 1.0)
			
			btn.pressed.connect(func(): _select_item_for_preview(it))
			items_container.add_child(btn)
			
			if not found_first or is_eq:
				_select_item_for_preview(it)
				found_first = true

func _select_item_for_preview(it: Dictionary) -> void:
	selected_item_id = it.get("id", "")
	var upg = SaveData.get_upgrade_level(selected_item_id)
	var upg_str = " (Level %d/5)" % upg if upg > 0 else ""
	label_details_name.text = "%s%s - %s" % [it.get("name", ""), upg_str, it.get("rarity", "Common")]
	
	var stats_text = ""
	if current_slot == "melee":
		var base_dmg = float(it.get("base_damage", 10.0))
		var cur_dmg = base_dmg * (1.0 + 0.22 * upg)
		stats_text = "Damage: %.1f | Speed: %.2fx | Reach: %.2fx" % [cur_dmg, it.get("speed_mult", 1.0), it.get("reach_mult", 1.0)]
	elif current_slot == "armor":
		var def = float(it.get("defense", 10.0)) * (1.0 + 0.20 * upg)
		stats_text = "Defense: %.0f | Bonus Health: +%.0f HP" % [def, it.get("health_bonus", 0.0)]
	elif current_slot == "helmet":
		var def = float(it.get("head_defense", 8.0)) * (1.0 + 0.20 * upg)
		stats_text = "Head Defense: %.0f" % def
	elif current_slot == "ranged":
		stats_text = "Throw Damage: %.0f | Cooldown: %.1fs" % [it.get("damage", 15.0), it.get("cooldown", 8.0)]
	elif current_slot == "special":
		stats_text = "Spirit Art Damage: %.0f | Cost: 100 Meter" % it.get("damage", 40.0)
	
	label_details_stats.text = stats_text
	label_details_passive.text = "Trait: %s\n%s" % [it.get("passive", "None"), it.get("description", "")]
	
	var equipped_id = SaveData.get_equipped_item(current_slot)
	if selected_item_id == equipped_id:
		btn_equip.text = "EQUIPPED"
		btn_equip.disabled = true
	else:
		btn_equip.text = "EQUIP ITEM"
		btn_equip.disabled = false

func _on_equip_pressed() -> void:
	if selected_item_id != "":
		SaveData.equip_item(current_slot, selected_item_id)
		loadout_changed.emit()
		_populate_owned_items()
