class_name HUD
extends Control

signal restart_requested()

var p1: Fighter
var p2: Fighter
var combat_manager: CombatManager

# UI Element references
@onready var p1_health_bar: ProgressBar = $TopBar/P1Container/HealthBar
@onready var p1_damage_trail: ProgressBar = $TopBar/P1Container/HealthBar/DamageTrail
@onready var p1_name_label: Label = $TopBar/P1Container/Header/NameLabel
@onready var p1_hp_label: Label = $TopBar/P1Container/Header/HpLabel
@onready var p1_round_1: ColorRect = $TopBar/P1Container/Rounds/Round1
@onready var p1_round_2: ColorRect = $TopBar/P1Container/Rounds/Round2

@onready var p2_health_bar: ProgressBar = $TopBar/P2Container/HealthBar
@onready var p2_damage_trail: ProgressBar = $TopBar/P2Container/HealthBar/DamageTrail
@onready var p2_name_label: Label = $TopBar/P2Container/Header/NameLabel
@onready var p2_hp_label: Label = $TopBar/P2Container/Header/HpLabel
@onready var p2_round_1: ColorRect = $TopBar/P2Container/Rounds/Round1
@onready var p2_round_2: ColorRect = $TopBar/P2Container/Rounds/Round2

@onready var timer_label: Label = $TopBar/TimerPanel/TimerLabel
@onready var announcement_label: Label = $CenterContainer/AnnouncementPanel/VBox/MainLabel
@onready var sub_announcement_label: Label = $CenterContainer/AnnouncementPanel/VBox/SubLabel
@onready var announcement_panel: PanelContainer = $CenterContainer/AnnouncementPanel

@onready var combo_panel: Control = $ComboPanel
@onready var combo_hits_label: Label = $ComboPanel/HitsLabel
@onready var combo_text_label: Label = $ComboPanel/TextLabel

@onready var game_over_modal: Control = $GameOverModal
@onready var result_title: Label = $GameOverModal/Panel/VBox/TitleLabel
@onready var stat_rounds: Label = $GameOverModal/Panel/VBox/StatsContainer/RoundsLabel
@onready var stat_hits: Label = $GameOverModal/Panel/VBox/StatsContainer/HitsLabel
@onready var stat_combo: Label = $GameOverModal/Panel/VBox/StatsContainer/ComboLabel
@onready var stat_time: Label = $GameOverModal/Panel/VBox/StatsContainer/TimeLabel
@onready var restart_button: Button = $GameOverModal/Panel/VBox/RestartButton

@onready var touch_controls: Control = $TouchControls
@onready var touch_toggle_button: Button = $TopBar/TouchToggleBtn

# Smooth health bar damage trail variables
var p1_trail_target: float = 100.0
var p2_trail_target: float = 100.0

var sound_gen: Node

func _ready() -> void:
	sound_gen = get_tree().root.find_child("SoundGenerator", true, false)
	announcement_panel.modulate.a = 0.0
	combo_panel.modulate.a = 0.0
	game_over_modal.visible = false
	
	restart_button.pressed.connect(_on_restart_pressed)
	# Keyboard remains the desktop control scheme. Touch controls are enabled only
	# on a device that advertises touch capability, avoiding a mouse-like joystick.
	var has_touch := DisplayServer.is_touchscreen_available()
	touch_controls.visible = has_touch
	touch_toggle_button.visible = false

func initialize(p1_ref: Fighter, p2_ref: Fighter, cm_ref: CombatManager) -> void:
	p1 = p1_ref
	p2 = p2_ref
	combat_manager = cm_ref
	
	if p1:
		p1.health_changed.connect(_on_p1_health_changed)
		p1.combo_updated.connect(_on_combo_updated)
		p1_name_label.text = p1.fighter_name
		_on_p1_health_changed(p1.current_health, p1.max_health)
	
	if p2:
		p2.health_changed.connect(_on_p2_health_changed)
		p2_name_label.text = p2.fighter_name
		_on_p2_health_changed(p2.current_health, p2.max_health)
	
	if combat_manager:
		combat_manager.timer_updated.connect(_on_timer_updated)
		combat_manager.announcement_shown.connect(_on_announcement_shown)
		combat_manager.match_ended.connect(_on_match_ended)
	
	_setup_touch_inputs()

func _process(delta: float) -> void:
	# Ease damage trails
	if p1_damage_trail.value > p1_trail_target:
		p1_damage_trail.value = move_toward(p1_damage_trail.value, p1_trail_target, delta * 35.0)
	else:
		p1_damage_trail.value = p1_trail_target
		
	if p2_damage_trail.value > p2_trail_target:
		p2_damage_trail.value = move_toward(p2_damage_trail.value, p2_trail_target, delta * 35.0)
	else:
		p2_damage_trail.value = p2_trail_target
	
	# Check keyboard shortcut for restart
	if Input.is_action_just_pressed("restart"):
		_on_restart_pressed()

func _on_p1_health_changed(hp: float, max_hp: float) -> void:
	p1_health_bar.max_value = max_hp
	p1_damage_trail.max_value = max_hp
	p1_health_bar.value = hp
	p1_trail_target = hp
	p1_hp_label.text = str(int(ceil(hp))) + " HP"
	
	if hp < 25.0:
		p1_hp_label.modulate = Color(1.0, 0.3, 0.3)
	else:
		p1_hp_label.modulate = Color(0.3, 0.9, 1.0)

func _on_p2_health_changed(hp: float, max_hp: float) -> void:
	p2_health_bar.max_value = max_hp
	p2_damage_trail.max_value = max_hp
	p2_health_bar.value = hp
	p2_trail_target = hp
	p2_hp_label.text = str(int(ceil(hp))) + " HP"
	
	if hp < 25.0:
		p2_hp_label.modulate = Color(1.0, 0.3, 0.3)
	else:
		p2_hp_label.modulate = Color(1.0, 0.5, 0.4)

func _on_timer_updated(seconds: int) -> void:
	timer_label.text = "%02d" % seconds
	if seconds <= 10:
		timer_label.modulate = Color(1.0, 0.25, 0.25)
	else:
		timer_label.modulate = Color(1.0, 0.88, 0.3)

func _on_announcement_shown(main_txt: String, sub_txt: String) -> void:
	if main_txt.is_empty() and sub_txt.is_empty():
		var tween = create_tween()
		tween.tween_property(announcement_panel, "modulate:a", 0.0, 0.25)
		return
	
	announcement_label.text = main_txt
	sub_announcement_label.text = sub_txt
	sub_announcement_label.visible = not sub_txt.is_empty()
	
	announcement_panel.modulate.a = 1.0
	announcement_panel.scale = Vector2(1.25, 1.25)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(announcement_panel, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_combo_updated(hits: int) -> void:
	if hits < 2:
		var tween = create_tween()
		tween.tween_property(combo_panel, "modulate:a", 0.0, 0.2)
		return
	
	combo_hits_label.text = str(hits)
	combo_text_label.text = "HITS COMBO!" if hits >= 3 else "HITS!"
	
	if hits >= 5:
		combo_hits_label.modulate = Color(1.0, 0.2, 0.6)
	elif hits >= 3:
		combo_hits_label.modulate = Color(1.0, 0.55, 0.1)
	else:
		combo_hits_label.modulate = Color(1.0, 0.9, 0.2)
	
	combo_panel.modulate.a = 1.0
	combo_panel.scale = Vector2(1.35, 1.35)
	var tween = create_tween()
	tween.tween_property(combo_panel, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func update_round_orbs(p1_wins: int, p2_wins: int) -> void:
	var win_color = Color(1.0, 0.85, 0.2, 1.0)
	var unearned_color = Color(0.2, 0.2, 0.25, 0.6)
	
	p1_round_1.color = win_color if p1_wins >= 1 else unearned_color
	p1_round_2.color = win_color if p1_wins >= 2 else unearned_color
	
	p2_round_1.color = win_color if p2_wins >= 1 else unearned_color
	p2_round_2.color = win_color if p2_wins >= 2 else unearned_color

func _on_match_ended(winner_name: String, is_player_win: bool, stats: Dictionary) -> void:
	update_round_orbs(stats.get("p1_rounds", 0), stats.get("p2_rounds", 0))
	
	result_title.text = "VICTORY" if is_player_win else "DEFEAT"
	result_title.modulate = Color(0.2, 0.9, 1.0) if is_player_win else Color(1.0, 0.25, 0.3)
	
	stat_rounds.text = "Rounds: " + str(stats.get("p1_rounds", 0)) + " - " + str(stats.get("p2_rounds", 0))
	stat_hits.text = "Total Hits Landed: " + str(stats.get("total_hits", 0))
	stat_combo.text = "Max Combo: " + str(stats.get("max_combo", 0)) + " Hits"
	stat_time.text = "Match Time: " + str(stats.get("match_time", 0)) + "s"
	
	game_over_modal.visible = true
	game_over_modal.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(game_over_modal, "modulate:a", 1.0, 0.4)
	
	if sound_gen and sound_gen.has_method("play"):
		sound_gen.play("round_bell", 1.2 if is_player_win else 0.8, 1.0)

func _on_restart_pressed() -> void:
	if sound_gen and sound_gen.has_method("play"):
		sound_gen.play("ui_click", 1.0, 0.8)
	
	game_over_modal.visible = false
	announcement_panel.modulate.a = 0.0
	combo_panel.modulate.a = 0.0
	update_round_orbs(0, 0)
	
	restart_requested.emit()

func _on_touch_toggle_pressed() -> void:
	touch_controls.visible = not touch_controls.visible

func _setup_touch_inputs() -> void:
	var joystick = $TouchControls/Joystick as FightJoystick
	if joystick and p1:
		joystick.direction_changed.connect(func(dir: Vector2, _octant: String):
			p1.touch_dir = dir
		)
	
	var btn_punch = $TouchControls/Actions/BtnPunch as Button
	var btn_kick = $TouchControls/Actions/BtnKick as Button
	var btn_block = $TouchControls/Actions/BtnBlock as Button
	
	if btn_punch and p1:
		btn_punch.button_down.connect(func(): p1.touch_punch = true)
	if btn_kick and p1:
		btn_kick.button_down.connect(func(): p1.touch_kick = true)
	if btn_block and p1:
		btn_block.button_down.connect(func(): p1.touch_block = true)
		btn_block.button_up.connect(func(): p1.touch_block = false)
