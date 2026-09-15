class_name AIController
extends Node

@export var fighter: Fighter
@export var difficulty: float = 1.0 # 0.8 = relaxed, 1.0 = normal, 1.2 = aggressive

var opponent: Fighter
var decision_timer: float = 0.0
var decision_interval: float = 0.18

# Current AI intent
var intent_action: String = "neutral"
var intent_duration: float = 0.0

func _ready() -> void:
	if fighter == null:
		var p = get_parent()
		if p is Fighter:
			fighter = p

func _physics_process(delta: float) -> void:
	if fighter == null or not fighter.is_active_match or fighter.current_health <= 0.0:
		return
	
	if opponent == null:
		opponent = fighter.opponent
		if opponent == null:
			return
	
	decision_timer -= delta
	intent_duration -= delta
	
	if decision_timer <= 0.0:
		_make_decision()
		decision_timer = randf_range(0.14, 0.22) / difficulty
	
	# Handle combo chaining during attacks
	if fighter.can_combo_cancel:
		_handle_ai_combo_chaining()

func _make_decision() -> void:
	var dist_x = opponent.global_position.x - fighter.global_position.x
	var abs_dist = abs(dist_x)
	var dir_to_player = signf(dist_x)
	var is_low_hp = (fighter.current_health < fighter.max_health * 0.35)
	
	# Check if player is currently attacking
	var opp_attacking = opponent._is_attacking_state()
	
	# Anti-air reaction: if opponent is jumping towards AI in close/mid range, execute anti-air uppercut!
	if not opponent.is_on_floor() and abs_dist < 160.0 and fighter.is_on_floor():
		if randf() < 0.65:
			fighter.input_dir = Vector2(0.0, 1.0) # crouch
			fighter.input_punch_pressed = true    # uppercut anti-air
			return
	
	# Defensive reaction logic
	if opp_attacking and abs_dist < 150.0:
		var block_chance = 0.65 if not is_low_hp else 0.85
		if randf() < block_chance:
			# Match guard to attack type: crouch if opponent is sweeping!
			var opp_atk = opponent.current_attack_name
			if opp_atk == "crouch_kick":
				fighter.input_dir = Vector2(0.0, 1.0) # crouch block
			else:
				fighter.input_dir = Vector2.ZERO
			fighter.input_block_held = true
			fighter.input_punch_pressed = false
			fighter.input_kick_pressed = false
			return
	
	# Reset block
	fighter.input_block_held = false
	
	# Distance-based behavior
	if abs_dist > 280.0:
		# Far range: close the distance
		if randf() < 0.82:
			fighter.input_dir = Vector2(dir_to_player, 0.0)
		else:
			# Jump forward
			fighter.input_dir = Vector2(dir_to_player, -1.0)
	
	elif abs_dist > 130.0:
		# Mid range: spacing, pokes, jump kicks, or closing in
		var roll = randf()
		if roll < 0.40:
			# Advance into strike range
			fighter.input_dir = Vector2(dir_to_player, 0.0)
		elif roll < 0.65:
			# Long poke with kick 1
			fighter.input_dir = Vector2.ZERO
			fighter.input_kick_pressed = true
		elif roll < 0.80:
			# Low sweep approach
			fighter.input_dir = Vector2(0.0, 1.0) # crouch
			fighter.input_kick_pressed = true
		elif roll < 0.90:
			# Jump kick dive
			fighter.input_dir = Vector2(dir_to_player, -1.0)
			fighter.input_kick_pressed = true
		else:
			# Step back / bait
			fighter.input_dir = Vector2(-dir_to_player, 0.0)
	
	else:
		# Close range: rapid strikes, combos, guard
		var roll = randf()
		if roll < 0.45:
			# Initiate punch combo
			fighter.input_dir = Vector2.ZERO
			fighter.input_punch_pressed = true
		elif roll < 0.70:
			# Initiate kick combo
			fighter.input_dir = Vector2.ZERO
			fighter.input_kick_pressed = true
		elif roll < 0.82:
			# Crouch gut punch or sweep
			fighter.input_dir = Vector2(0.0, 1.0)
			if randf() < 0.5:
				fighter.input_punch_pressed = true
			else:
				fighter.input_kick_pressed = true
		elif roll < 0.92:
			# Step back defensively
			fighter.input_dir = Vector2(-dir_to_player, 0.0)
		else:
			# Hold guard
			fighter.input_dir = Vector2.ZERO
			fighter.input_block_held = true

func _handle_ai_combo_chaining() -> void:
	match fighter.current_attack_name:
		"punch_1":
			if randf() < 0.75:
				fighter.input_punch_pressed = true # jab -> cross
			elif randf() < 0.45:
				fighter.input_kick_pressed = true  # jab -> roundhouse
		"punch_2":
			if randf() < 0.65:
				fighter.input_punch_pressed = true # cross -> hook
			elif randf() < 0.50:
				fighter.input_kick_pressed = true  # cross -> side kick
		"crouch_kick":
			if randf() < 0.60:
				fighter.input_punch_pressed = true # low sweep -> cross
		"kick_1":
			if randf() < 0.70:
				fighter.input_kick_pressed = true  # side kick -> roundhouse
