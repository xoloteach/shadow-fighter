class_name WorldMapUI
extends Control

signal return_to_dojo()
signal start_combat_requested(fight_data: Dictionary)

var current_chapter_idx: int = 1
var current_mode: String = "tournament" # "tournament", "challenges", "bodyguards", "survival"
var selected_fight: Dictionary = {}

@onready var btn_back: Button = $TopHeader/BtnBack
@onready var btn_ch1: Button = $ChapterTabs/BtnCh1
@onready var btn_ch2: Button = $ChapterTabs/BtnCh2
@onready var btn_ch3: Button = $ChapterTabs/BtnCh3

@onready var btn_tab_tourney: Button = $ModeTabs/BtnTourney
@onready var btn_tab_challenges: Button = $ModeTabs/BtnChallenges
@onready var btn_tab_boss: Button = $ModeTabs/BtnBoss
@onready var btn_tab_survival: Button = $ModeTabs/BtnSurvival

@onready var fights_container: VBoxContainer = $ScrollContainer/FightsList
@onready var modal_preview: Control = $FightPreviewModal
@onready var preview_title: Label = $FightPreviewModal/Panel/VBox/TitleLabel
@onready var preview_desc: Label = $FightPreviewModal/Panel/VBox/DescLabel
@onready var preview_difficulty: Label = $FightPreviewModal/Panel/VBox/DifficultyLabel
@onready var preview_rewards: Label = $FightPreviewModal/Panel/VBox/RewardsLabel
@onready var preview_portrait: TextureRect = $FightPreviewModal/Panel/VBox/BossPortrait
@onready var btn_launch_fight: Button = $FightPreviewModal/Panel/VBox/Buttons/BtnLaunch
@onready var btn_cancel_preview: Button = $FightPreviewModal/Panel/VBox/Buttons/BtnCancel

func _ready() -> void:
	btn_back.pressed.connect(func(): return_to_dojo.emit())
	btn_ch1.pressed.connect(func(): _select_chapter(1))
	btn_ch2.pressed.connect(func(): _select_chapter(2))
	btn_ch3.pressed.connect(func(): _select_chapter(3))
	
	btn_tab_tourney.pressed.connect(func(): _select_mode("tournament"))
	btn_tab_challenges.pressed.connect(func(): _select_mode("challenges"))
	btn_tab_boss.pressed.connect(func(): _select_mode("bodyguards"))
	btn_tab_survival.pressed.connect(func(): _select_mode("survival"))
	
	btn_launch_fight.pressed.connect(_on_launch_fight_pressed)
	btn_cancel_preview.pressed.connect(func(): modal_preview.visible = false)
	modal_preview.visible = false

func open_map() -> void:
	visible = true
	modal_preview.visible = false
	_select_chapter(current_chapter_idx)

func _select_chapter(idx: int) -> void:
	# Check unlock requirements
	if idx == 2 and not (SaveData.is_fight_completed("boss_guro") or SaveData.data["player"]["level"] >= 5):
		return
	if idx == 3 and not (SaveData.is_fight_completed("boss_lin") or SaveData.data["player"]["level"] >= 9):
		return
	
	current_chapter_idx = idx
	_update_chapter_buttons()
	_populate_fights_list()

func _update_chapter_buttons() -> void:
	btn_ch1.modulate = Color(1.2, 1.2, 1.2) if current_chapter_idx == 1 else Color(0.7, 0.7, 0.7)
	btn_ch2.modulate = Color(1.2, 1.2, 1.2) if current_chapter_idx == 2 else Color(0.7, 0.7, 0.7)
	btn_ch3.modulate = Color(1.2, 1.2, 1.2) if current_chapter_idx == 3 else Color(0.7, 0.7, 0.7)
	
	var ch2_unlocked = SaveData.is_fight_completed("boss_guro") or SaveData.data["player"]["level"] >= 5
	var ch3_unlocked = SaveData.is_fight_completed("boss_lin") or SaveData.data["player"]["level"] >= 9
	btn_ch2.disabled = not ch2_unlocked
	btn_ch3.disabled = not ch3_unlocked

func _select_mode(mode: String) -> void:
	current_mode = mode
	btn_tab_tourney.modulate = Color(1.2, 1.2, 1.2) if mode == "tournament" else Color(0.7, 0.7, 0.7)
	btn_tab_challenges.modulate = Color(1.2, 1.2, 1.2) if mode == "challenges" else Color(0.7, 0.7, 0.7)
	btn_tab_boss.modulate = Color(1.2, 1.2, 1.2) if mode == "bodyguards" else Color(0.7, 0.7, 0.7)
	btn_tab_survival.modulate = Color(1.2, 1.2, 1.2) if mode == "survival" else Color(0.7, 0.7, 0.7)
	_populate_fights_list()

func _populate_fights_list() -> void:
	for c in fights_container.get_children():
		c.queue_free()
	
	var chapters: Array = Progression.opponents_catalog.get("chapters", [])
	var ch_data = {}
	for ch in chapters:
		if ch.get("id", 1) == current_chapter_idx:
			ch_data = ch
			break
	
	if ch_data.is_empty():
		return
	
	match current_mode:
		"tournament":
			var list: Array = ch_data.get("tournaments", [])
			var prev_won = true
			for f in list:
				var f_id = f.get("id", "")
				var completed = SaveData.is_fight_completed(f_id)
				var is_available = prev_won or completed
				_create_fight_card(f, "Tournament", is_available, completed)
				prev_won = completed
				
		"challenges":
			var list: Array = ch_data.get("challenges", [])
			for f in list:
				var f_id = f.get("id", "")
				var completed = SaveData.is_fight_completed(f_id)
				_create_fight_card(f, "Challenge", true, completed)
				
		"bodyguards":
			var bgs: Array = ch_data.get("bodyguards", [])
			var all_bgs_defeated = true
			var prev_bg_won = true
			for bg in bgs:
				var bg_id = bg.get("id", "")
				var completed = SaveData.is_fight_completed(bg_id)
				var is_available = prev_bg_won or completed
				_create_fight_card(bg, "Elite Bodyguard", is_available, completed)
				if not completed:
					all_bgs_defeated = false
				prev_bg_won = completed
			
			# Boss node
			var boss = ch_data.get("boss", {})
			if not boss.is_empty():
				var boss_id = boss.get("id", "")
				var boss_completed = SaveData.is_fight_completed(boss_id)
				_create_fight_card(boss, "CHAPTER BOSS", all_bgs_defeated, boss_completed)
				
		"survival":
			# Survival endurance node
			var surv_data = {
				"id": "survival_ch%d" % current_chapter_idx,
				"name": "Chapter %d Survival Trial" % current_chapter_idx,
				"power": current_chapter_idx * 75,
				"reward_coins": current_chapter_idx * 350,
				"reward_xp": current_chapter_idx * 200,
				"rule_desc": "Defeat 6 consecutive opponents with partial recovery between rounds!"
			}
			_create_fight_card(surv_data, "Survival Trial", true, false)

func _create_fight_card(f_data: Dictionary, type_label: String, is_available: bool, is_completed: bool) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 52)
	
	var name_str = f_data.get("name", "Opponent")
	var pwr = int(f_data.get("power", 20))
	var status = " [COMPLETED]" if is_completed else (" [LOCKED]" if not is_available else "")
	btn.text = "%s - %s (PWR %d)%s" % [type_label, name_str, pwr, status]
	
	if is_completed:
		btn.modulate = Color(0.6, 0.9, 0.6)
	elif not is_available:
		btn.modulate = Color(0.5, 0.5, 0.5)
		btn.disabled = true
	else:
		btn.modulate = Color(1.0, 1.0, 1.0)
	
	btn.pressed.connect(func(): _open_preview_modal(f_data, type_label))
	fights_container.add_child(btn)

func _open_preview_modal(f_data: Dictionary, type_label: String) -> void:
	selected_fight = f_data
	selected_fight["_type_label"] = type_label
	
	var name_str = f_data.get("name", "Challenger")
	var pwr = int(f_data.get("power", 20))
	preview_title.text = "%s: %s" % [type_label.to_upper(), name_str]
	
	var desc = f_data.get("rule_desc", f_data.get("special_mechanic", "Standard 3-round tournament rules."))
	preview_desc.text = desc
	
	var player_pwr = Progression.get_player_power(SaveData)
	var diff = Progression.get_difficulty(player_pwr, pwr)
	preview_difficulty.text = "Difficulty: %s (Your Power: %d vs %d)" % [diff.label, player_pwr, pwr]
	preview_difficulty.modulate = diff.color
	
	var coins = int(f_data.get("reward_coins", 50))
	var xp = int(f_data.get("reward_xp", 30))
	preview_rewards.text = "Victory Rewards: +%d Monshu, +%d XP" % [coins, xp]
	var boss_portraits := {
		"boss_guro": "res://assets/blender/v3/boss_guro.png",
		"boss_lin": "res://assets/blender/v3/boss_lin.png",
		"boss_kurozuka": "res://assets/blender/v3/boss_kurozuka.png"
	}
	var portrait_path: String = boss_portraits.get(f_data.get("id", ""), "")
	preview_portrait.visible = not portrait_path.is_empty()
	if not portrait_path.is_empty():
		preview_portrait.texture = load(portrait_path)
	
	modal_preview.visible = true

func _on_launch_fight_pressed() -> void:
	modal_preview.visible = false
	start_combat_requested.emit(selected_fight)
