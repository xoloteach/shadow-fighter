extends Node2D

const HIT_SPARK_SCENE = preload("res://scenes/effects/hit_spark.tscn")
const DUST_PUFF_SCENE = preload("res://scenes/effects/dust_puff.tscn")

@onready var p1: Fighter = $Player
@onready var p2: Fighter = $Enemy
@onready var camera: StageCamera = $Camera2D
@onready var combat_manager: CombatManager = $CombatManager
@onready var effects_container: Node2D = $EffectsContainer

@onready var ui: HUD = $CanvasLayer/UI
@onready var dojo_ui: DojoUI = $CanvasLayer/DojoUI
@onready var map_ui: WorldMapUI = $CanvasLayer/WorldMapUI
@onready var armory_ui: ArmoryUI = $CanvasLayer/ArmoryUI
@onready var shop_ui: ShopUI = $CanvasLayer/ShopUI
@onready var training_ui: TrainingUI = $CanvasLayer/TrainingUI
@onready var dialogue_ui: DialogueUI = $CanvasLayer/DialogueUI
@onready var rewards_modal: RewardsModalUI = $CanvasLayer/RewardsModal
@onready var profile_modal: ProfileModalUI = $CanvasLayer/ProfileModal

var active_fight_data: Dictionary = {}

func _ready() -> void:
	# Cross-wire opponents
	p1.opponent = p2
	p2.opponent = p1

	# Wire combat manager and camera
	combat_manager.initialize(p1, p2, camera)
	combat_manager.match_ended.connect(_on_match_ended)
	combat_manager.training_diagnostic_updated.connect(func(dmg, combo):
		if training_ui.visible:
			training_ui.update_diagnostics(dmg, combo)
	)

	# Connect hit visual effects
	p1.hit_taken.connect(_on_fighter_hit_taken)
	p2.hit_taken.connect(_on_fighter_hit_taken)
	p1.state_changed.connect(func(st): _on_fighter_state_changed(p1, st))
	p2.state_changed.connect(func(st): _on_fighter_state_changed(p2, st))

	# Wire Dojo navigation
	dojo_ui.fight_selected.connect(enter_map)
	dojo_ui.armory_selected.connect(enter_armory)
	dojo_ui.shop_selected.connect(enter_shop)
	dojo_ui.training_selected.connect(enter_training)
	dojo_ui.profile_selected.connect(enter_profile)

	# Wire return to dojo
	map_ui.return_to_dojo.connect(enter_dojo)
	armory_ui.return_to_dojo.connect(enter_dojo)
	shop_ui.return_to_dojo.connect(enter_dojo)
	training_ui.return_to_dojo.connect(enter_dojo)

	# Wire combat launches
	map_ui.start_combat_requested.connect(start_combat)
	training_ui.reset_dummy_requested.connect(_reset_training_dummy)
	rewards_modal.continue_pressed.connect(enter_dojo)

	# Armory & Shop inventory updates
	armory_ui.loadout_changed.connect(_refresh_player_visuals)
	shop_ui.inventory_changed.connect(_refresh_player_visuals)

	# Initialize player loadout from SaveData
	_refresh_player_visuals()

	# Start in Dojo Hub
	enter_dojo()

func enter_dojo() -> void:
	combat_manager.is_training_mode = false
	combat_manager.match_over = true
	combat_manager.is_round_active = false

	# UI state
	dojo_ui.visible = true
	dojo_ui.update_display()
	map_ui.visible = false
	armory_ui.visible = false
	shop_ui.visible = false
	training_ui.visible = false
	rewards_modal.visible = false
	profile_modal.visible = false
	dialogue_ui.visible = false
	ui.visible = false

	# Position player in dojo stance
	p1.reset_match(Vector2(0, 540), 1.0)
	p1.is_active_match = false
	p2.reset_match(Vector2(9999, 540), -1.0) # hide offscreen
	p2.is_active_match = false

	camera.target_p1 = p1
	camera.target_p2 = null
	camera.global_position.x = 0

	_refresh_player_visuals()

func enter_map() -> void:
	dojo_ui.visible = false
	map_ui.open_map()

func enter_armory() -> void:
	dojo_ui.visible = false
	armory_ui.open_armory()

func enter_shop() -> void:
	dojo_ui.visible = false
	shop_ui.open_shop()

func enter_profile() -> void:
	profile_modal.show_profile()

func enter_training() -> void:
	dojo_ui.visible = false
	training_ui.visible = true
	ui.visible = false

	combat_manager.is_training_mode = true
	combat_manager.active_rule = ""

	_refresh_player_visuals()
	p1.reset_match(Vector2(-180, 540), 1.0)
	p1.is_active_match = true

	# Setup dummy
	p2.fighter_name = "TRAINING DUMMY"
	p2.max_health = 500.0
	p2.current_health = 500.0
	p2.apply_loadout({
		"weapon_type": "fists",
		"armor_id": "gi_novice",
		"helmet_id": "headband_novice",
		"attack_power": 8.0,
		"defense": 10.0,
		"reach_mult": 1.0,
		"speed_mult": 1.0,
		"max_health": 500.0
	})
	p2.reset_match(Vector2(180, 540), -1.0)
	p2.is_active_match = true
	var ai = p2.find_child("AIController", true, false)
	if ai:
		ai.is_active = false # dummy stays passive for practice

	camera.target_p1 = p1
	camera.target_p2 = p2

func _reset_training_dummy() -> void:
	p2.reset_match(Vector2(180, 540), -1.0)
	p2.current_health = p2.max_health
	p2.is_active_match = true
	p2.is_invulnerable = false
	p2.health_changed.emit(p2.current_health, p2.max_health)
	p2._change_state("idle")

func start_combat(fight_data: Dictionary) -> void:
	active_fight_data = fight_data

	dojo_ui.visible = false
	map_ui.visible = false
	armory_ui.visible = false
	shop_ui.visible = false
	training_ui.visible = false
	rewards_modal.visible = false
	ui.visible = true

	combat_manager.is_training_mode = false
	combat_manager.is_survival_mode = fight_data.get("_type_label", "") == "Survival Trial"
	combat_manager.active_rule = fight_data.get("rule", "")

	# Setup Player
	var p_stats = Progression.get_player_effective_stats(SaveData)
	p1.apply_loadout(p_stats)
	p1.fighter_name = SaveData.data.get("player", {}).get("name", "KAGE")

	# Setup Opponent
	var opp_name = fight_data.get("name", "CHALLENGER").to_upper()
	p2.fighter_name = opp_name

	var weapon_id = fight_data.get("weapon", "katana_novice")
	var armor_id = fight_data.get("armor", "gi_novice")
	var helmet_id = fight_data.get("helmet", "headband_novice")
	var opp_w_data = Progression.get_item_data(weapon_id)

	var pwr = float(fight_data.get("power", 30))
	var opp_hp = float(fight_data.get("max_hp", 100.0 + pwr * 0.4))
	var opp_dmg = maxf(8.0, pwr * 0.16)

	p2.apply_loadout({
		"weapon_id": weapon_id,
		"armor_id": armor_id,
		"helmet_id": helmet_id,
		"weapon_type": opp_w_data.get("weapon_type", "katana"),
		"attack_power": opp_dmg,
		"reach_mult": float(opp_w_data.get("reach_mult", 1.0)),
		"speed_mult": float(opp_w_data.get("speed_mult", 1.0)),
		"defense": pwr * 0.15,
		"head_defense": pwr * 0.12,
		"max_health": opp_hp
	})

	var ai = p2.find_child("AIController", true, false)
	if ai:
		ai.is_active = true
		ai.configure_profile(fight_data.get("ai_profile", "balanced"))

	camera.target_p1 = p1
	camera.target_p2 = p2

	ui.initialize(p1, p2, combat_manager)

	# Check for story/boss pre-fight dialogue
	var intro_quote = fight_data.get("intro_quote", "")
	if intro_quote != "":
		dialogue_ui.play_sequence([
			{ "speaker": opp_name, "text": intro_quote }
		])
		dialogue_ui.dialogue_finished.connect(func():
			combat_manager.start_new_match()
		, CONNECT_ONE_SHOT)
	else:
		combat_manager.start_new_match()

func _on_match_ended(winner_name: String, is_player_winner: bool, stats: Dictionary) -> void:
	if combat_manager.is_training_mode:
		return

	var coins = int(active_fight_data.get("reward_coins", 60))
	var xp = int(active_fight_data.get("reward_xp", 35))
	var did_lvl = false
	var new_lvl = 1

	if is_player_winner:
		var f_id = active_fight_data.get("id", "")
		if f_id != "":
			SaveData.mark_fight_completed(f_id)
		SaveData.add_coins(coins)
		var res = SaveData.add_xp(xp)
		did_lvl = res.leveled_up
		new_lvl = res.new_level
		SaveData.record_fight_stats(true, stats.get("max_combo", 0))
	else:
		SaveData.record_fight_stats(false, stats.get("max_combo", 0))

	# Check for boss defeat dialogue
	var defeat_quote = active_fight_data.get("defeat_quote", "")
	if is_player_winner and defeat_quote != "":
		dialogue_ui.play_sequence([
			{ "speaker": active_fight_data.get("name", "BOSS"), "text": defeat_quote }
		])
		dialogue_ui.dialogue_finished.connect(func():
			rewards_modal.show_rewards(is_player_winner, coins, xp, did_lvl, new_lvl)
		, CONNECT_ONE_SHOT)
	else:
		rewards_modal.show_rewards(is_player_winner, coins, xp, did_lvl, new_lvl)

func _refresh_player_visuals() -> void:
	var stats = Progression.get_player_effective_stats(SaveData)
	p1.apply_loadout(stats)

func _on_fighter_hit_taken(_damage: float, is_blocked: bool, hit_pos: Vector2) -> void:
	var spark = HIT_SPARK_SCENE.instantiate() as HitSpark
	spark.global_position = hit_pos
	spark.is_blocked = is_blocked
	effects_container.add_child(spark)

func _on_fighter_state_changed(fighter: Fighter, state: String) -> void:
	if state == "jump" and fighter.is_on_floor():
		var dust = DUST_PUFF_SCENE.instantiate()
		dust.global_position = fighter.global_position
		effects_container.add_child(dust)
	elif state == "crouch_kick":
		var dust = DUST_PUFF_SCENE.instantiate()
		dust.global_position = fighter.global_position + Vector2(25 * fighter.facing_direction, 0)
		effects_container.add_child(dust)
