class_name AIController
extends Node

@export var fighter: Fighter
@export var difficulty: float = 1.0

var opponent: Fighter
var is_active: bool = true
var profile: String = "balanced"
var decision_timer: float = 0.0
var decision_interval: float = 0.20
var attack_cooldown: float = 0.0
var retreat_bias: float = 0.15
var block_bias: float = 0.50
var anti_air_bias: float = 0.45

func _ready() -> void:
	if fighter == null:
		var parent := get_parent()
		if parent is Fighter:
			fighter = parent

func configure_profile(profile_name: String) -> void:
	profile = profile_name
	match profile_name:
		"passive":
			difficulty = 0.78
			decision_interval = 0.28
			retreat_bias = 0.38
			block_bias = 0.60
			anti_air_bias = 0.28
		"defensive":
			difficulty = 0.92
			decision_interval = 0.22
			retreat_bias = 0.32
			block_bias = 0.76
			anti_air_bias = 0.55
		"aggressive":
			difficulty = 1.12
			decision_interval = 0.16
			retreat_bias = 0.06
			block_bias = 0.40
			anti_air_bias = 0.58
		"tactical":
			difficulty = 1.05
			decision_interval = 0.18
			retreat_bias = 0.22
			block_bias = 0.68
			anti_air_bias = 0.70
		"boss_guro":
			difficulty = 1.08
			decision_interval = 0.16
			retreat_bias = 0.04
			block_bias = 0.64
			anti_air_bias = 0.72
		"boss_lin":
			difficulty = 1.18
			decision_interval = 0.14
			retreat_bias = 0.34
			block_bias = 0.56
			anti_air_bias = 0.76
		"boss_kurozuka":
			difficulty = 1.22
			decision_interval = 0.13
			retreat_bias = 0.10
			block_bias = 0.70
			anti_air_bias = 0.80
		_:
			difficulty = 1.0
			decision_interval = 0.20
			retreat_bias = 0.15
			block_bias = 0.50
			anti_air_bias = 0.45

func _physics_process(delta: float) -> void:
	if fighter == null or not is_active or not fighter.is_active_match or fighter.current_health <= 0.0:
		return
	if opponent == null:
		opponent = fighter.opponent
		if opponent == null:
			return

	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	decision_timer -= delta
	if decision_timer <= 0.0:
		_make_decision()
		decision_timer = decision_interval / maxf(difficulty, 0.1)

	if fighter.can_combo_cancel:
		_handle_combo_chain()

func _clear_inputs() -> void:
	fighter.input_dir = Vector2.ZERO
	fighter.input_punch_pressed = false
	fighter.input_kick_pressed = false
	fighter.input_block_held = false

func _make_decision() -> void:
	# A new decision always starts neutral: this removes stale directions/guard holds.
	_clear_inputs()
	if fighter._is_attacking_state() or fighter.current_state in ["hit_stun", "knockdown", "get_up", "dead"]:
		return

	var distance_x := opponent.global_position.x - fighter.global_position.x
	var distance := absf(distance_x)
	var toward := signf(distance_x)
	var strike_range := 120.0 * fighter.reach_multiplier
	var opponent_attacking := opponent._is_attacking_state()
	var low_health := fighter.current_health < fighter.max_health * 0.35

	# Anti-air has a narrowly defined response window so it feels reactive rather than random.
	if not opponent.is_on_floor() and distance < 155.0 and fighter.is_on_floor() and randf() < anti_air_bias:
		fighter.input_dir = Vector2(0.0, 1.0)
		fighter.input_punch_pressed = true
		attack_cooldown = 0.24
		return

	# Guard an approaching active attack, then return to neutral on the next decision.
	if opponent_attacking and distance < strike_range * 1.35:
		var guard_chance := block_bias + (0.16 if low_health else 0.0)
		if randf() < guard_chance:
			fighter.input_dir = Vector2(0.0, 1.0) if opponent.current_attack_name == "crouch_kick" else Vector2.ZERO
			fighter.input_block_held = true
			return

	if distance > 250.0:
		fighter.input_dir = Vector2(toward, 0.0)
		return

	if distance > strike_range * 1.20:
		if randf() < retreat_bias:
			fighter.input_dir = Vector2(-toward, 0.0)
		elif randf() < 0.76:
			fighter.input_dir = Vector2(toward, 0.0)
		else:
			fighter.input_kick_pressed = true
			attack_cooldown = 0.20
		return

	# At range, choose one committed option; an attack cooldown prevents input spam/slop.
	if attack_cooldown > 0.0:
		if randf() < retreat_bias:
			fighter.input_dir = Vector2(-toward, 0.0)
		return
	var roll := randf()
	if roll < 0.42:
		fighter.input_punch_pressed = true
	elif roll < 0.68:
		fighter.input_kick_pressed = true
	elif roll < 0.82:
		fighter.input_dir = Vector2(0.0, 1.0)
		fighter.input_kick_pressed = true
	elif roll < 0.92:
		fighter.input_dir = Vector2(-toward, 0.0)
	else:
		fighter.input_block_held = true
	attack_cooldown = 0.26 / maxf(difficulty, 0.1)

func _handle_combo_chain() -> void:
	if attack_cooldown > 0.0:
		return
	var chain_chance := 0.48 + (0.18 if profile in ["aggressive", "boss_lin", "boss_kurozuka"] else 0.0)
	match fighter.current_attack_name:
		"punch_1", "punch_2":
			if randf() < chain_chance:
				fighter.input_punch_pressed = true
		"kick_1":
			if randf() < chain_chance:
				fighter.input_kick_pressed = true
		"crouch_kick":
			if randf() < chain_chance * 0.70:
				fighter.input_punch_pressed = true
