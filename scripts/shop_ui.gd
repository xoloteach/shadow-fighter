class_name ShopUI
extends Control

signal return_to_dojo()
signal inventory_changed()

var current_slot: String = "melee"

@onready var btn_back: Button = $TopHeader/BtnBack
@onready var label_coins: Label = $TopHeader/Currency/CoinsLabel

@onready var btn_cat_melee: Button = $CategoryTabs/BtnMelee
@onready var btn_cat_armor: Button = $CategoryTabs/BtnArmor
@onready var btn_cat_helmet: Button = $CategoryTabs/BtnHelmet
@onready var btn_cat_ranged: Button = $CategoryTabs/BtnRanged
@onready var btn_cat_special: Button = $CategoryTabs/BtnSpecial

@onready var items_container: VBoxContainer = $ScrollContainer/ItemsList
@onready var label_status_msg: Label = $StatusLabel

func _ready() -> void:
	btn_back.pressed.connect(func(): return_to_dojo.emit())
	btn_cat_melee.pressed.connect(func(): _select_category("melee"))
	btn_cat_armor.pressed.connect(func(): _select_category("armor"))
	btn_cat_helmet.pressed.connect(func(): _select_category("helmet"))
	btn_cat_ranged.pressed.connect(func(): _select_category("ranged"))
	btn_cat_special.pressed.connect(func(): _select_category("special"))
	label_status_msg.text = ""

func open_shop() -> void:
	visible = true
	_select_category(current_slot)

func _select_category(slot: String) -> void:
	current_slot = slot
	btn_cat_melee.modulate = Color(1.2, 1.2, 1.2) if slot == "melee" else Color(0.7, 0.7, 0.7)
	btn_cat_armor.modulate = Color(1.2, 1.2, 1.2) if slot == "armor" else Color(0.7, 0.7, 0.7)
	btn_cat_helmet.modulate = Color(1.2, 1.2, 1.2) if slot == "helmet" else Color(0.7, 0.7, 0.7)
	btn_cat_ranged.modulate = Color(1.2, 1.2, 1.2) if slot == "ranged" else Color(0.7, 0.7, 0.7)
	btn_cat_special.modulate = Color(1.2, 1.2, 1.2) if slot == "special" else Color(0.7, 0.7, 0.7)
	_populate_shop_items()

func _populate_shop_items() -> void:
	for c in items_container.get_children():
		c.queue_free()
	
	var coins = int(SaveData.data.get("player", {}).get("coins", 0))
	var player_lvl = int(SaveData.data.get("player", {}).get("level", 1))
	label_coins.text = "%d MONSHU" % coins
	
	var cat_key = "weapons" if current_slot == "melee" else (current_slot + "s" if current_slot != "special" else "special")
	var catalog_items: Array = Progression.equipment_catalog.get(cat_key, [])
	var equipped_id = SaveData.get_equipped_item(current_slot)
	
	for it in catalog_items:
		var i_id: String = it.get("id", "")
		var is_owned = SaveData.is_item_owned(i_id)
		var is_equipped = (i_id == equipped_id)
		var req_lvl = int(it.get("required_level", 1))
		var price = int(it.get("price", 100))
		var upg = SaveData.get_upgrade_level(i_id)
		
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 70)
		
		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_theme_constant_override("separation", 16)
		card.add_child(hbox)
		
		# Info VBox
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var title = Label.new()
		var upg_tag = " (+%d)" % upg if upg > 0 else ""
		title.text = "%s%s [%s]" % [it.get("name", "Item"), upg_tag, it.get("rarity", "Common")]
		title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3) if is_owned else Color(0.9, 0.9, 0.9))
		vbox.add_child(title)
		
		var sub = Label.new()
		sub.add_theme_font_size_override("font_size", 12)
		sub.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
		sub.text = it.get("passive", it.get("description", ""))
		vbox.add_child(sub)
		hbox.add_child(vbox)
		
		# Action Button
		if not is_owned:
			var btn_buy = Button.new()
			btn_buy.custom_minimum_size = Vector2(140, 44)
			btn_buy.text = "BUY (%d)" % price
			if player_lvl < req_lvl:
				btn_buy.text = "REQ LV. %d" % req_lvl
				btn_buy.disabled = true
			elif coins < price:
				btn_buy.disabled = true
			btn_buy.pressed.connect(func(): _buy_item(it))
			hbox.add_child(btn_buy)
		else:
			# Upgrade button if not maxed
			if upg < 5:
				var upg_cost = int(max(60, price * 0.35 * (upg + 1)))
				var btn_upg = Button.new()
				btn_upg.custom_minimum_size = Vector2(130, 44)
				btn_upg.text = "UPGRADE (%d)" % upg_cost
				if coins < upg_cost:
					btn_upg.disabled = true
				btn_upg.pressed.connect(func(): _upgrade_item(i_id, upg_cost))
				hbox.add_child(btn_upg)
			
			# Equip button
			var btn_eq = Button.new()
			btn_eq.custom_minimum_size = Vector2(100, 44)
			btn_eq.text = "EQUIPPED" if is_equipped else "EQUIP"
			btn_eq.disabled = is_equipped
			btn_eq.pressed.connect(func(): _equip_item(i_id))
			hbox.add_child(btn_eq)
		
		items_container.add_child(card)

func _buy_item(it: Dictionary) -> void:
	if SaveData.buy_item(it):
		_show_status("Purchased %s!" % it.get("name", "item"))
		inventory_changed.emit()
		_populate_shop_items()
	else:
		_show_status("Not enough Monshu coins!")

func _upgrade_item(item_id: String, cost: int) -> void:
	if SaveData.upgrade_item(item_id, cost):
		_show_status("Item upgraded successfully!")
		inventory_changed.emit()
		_populate_shop_items()
	else:
		_show_status("Upgrade failed: Insufficient funds!")

func _equip_item(item_id: String) -> void:
	SaveData.equip_item(current_slot, item_id)
	_show_status("Equipped!")
	inventory_changed.emit()
	_populate_shop_items()

func _show_status(msg: String) -> void:
	label_status_msg.text = msg
	var tw = create_tween()
	label_status_msg.modulate.a = 1.0
	tw.tween_property(label_status_msg, "modulate:a", 0.0, 2.5)
