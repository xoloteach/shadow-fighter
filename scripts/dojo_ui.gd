class_name DojoUI
extends Control

signal fight_selected()
signal armory_selected()
signal shop_selected()
signal training_selected()
signal profile_selected()

@onready var label_level: Label = $TopBar/PlayerInfo/LevelLabel
@onready var label_name: Label = $TopBar/PlayerInfo/NameLabel
@onready var xp_bar: ProgressBar = $TopBar/PlayerInfo/XpBar
@onready var label_coins: Label = $TopBar/Currency/CoinsLabel

@onready var btn_fight: Button = $BottomNav/BtnFight
@onready var btn_armory: Button = $BottomNav/BtnArmory
@onready var btn_shop: Button = $BottomNav/BtnShop
@onready var btn_training: Button = $BottomNav/BtnTraining
@onready var btn_profile: Button = $BottomNav/BtnProfile

func _ready() -> void:
	btn_fight.pressed.connect(func(): fight_selected.emit())
	btn_armory.pressed.connect(func(): armory_selected.emit())
	btn_shop.pressed.connect(func(): shop_selected.emit())
	btn_training.pressed.connect(func(): training_selected.emit())
	btn_profile.pressed.connect(func(): profile_selected.emit())
	update_display()

func update_display() -> void:
	if not is_instance_valid(SaveData):
		return
	var player = SaveData.data.get("player", {})
	var lvl = int(player.get("level", 1))
	var xp = int(player.get("xp", 0))
	var coins = int(player.get("coins", 0))
	
	if label_level:
		label_level.text = "LV. %d" % lvl
	if label_name:
		label_name.text = str(player.get("name", "KAGE"))
	if label_coins:
		label_coins.text = "%d MONSHU" % coins
	
	if xp_bar:
		var cur_threshold = SaveData.get_xp_for_level(lvl)
		var next_threshold = SaveData.get_xp_for_level(lvl + 1)
		var range_xp = max(1, next_threshold - cur_threshold)
		var progress_xp = clamp(xp - cur_threshold, 0, range_xp)
		xp_bar.max_value = range_xp
		xp_bar.value = progress_xp
