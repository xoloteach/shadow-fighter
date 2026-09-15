class_name RewardsModalUI
extends Control

signal continue_pressed()

@onready var label_title: Label = $Panel/VBox/TitleLabel
@onready var label_coins: Label = $Panel/VBox/CoinsLabel
@onready var label_xp: Label = $Panel/VBox/XpLabel
@onready var label_levelup: Label = $Panel/VBox/LevelUpLabel
@onready var btn_continue: Button = $Panel/VBox/BtnContinue

func _ready() -> void:
	btn_continue.pressed.connect(func(): continue_pressed.emit())
	visible = false

func show_rewards(won: bool, coins: int, xp: int, leveled_up: bool, new_lvl: int) -> void:
	visible = true
	label_title.text = "VICTORY" if won else "DEFEAT"
	label_title.modulate = Color(0.2, 0.95, 1.0) if won else Color(1.0, 0.25, 0.3)
	
	if won:
		label_coins.text = "+%d MONSHU COINS" % coins
		label_xp.text = "+%d EXPERIENCE" % xp
		if leveled_up:
			label_levelup.visible = true
			label_levelup.text = "LEVEL UP! REACHED LEVEL %d" % new_lvl
		else:
			label_levelup.visible = false
	else:
		label_coins.text = "+%d MONSHU (Consolation)" % int(coins * 0.25)
		label_xp.text = "+%d XP (Training)" % int(xp * 0.25)
		label_levelup.visible = false
