class_name Fighter
extends CharacterBody2D

signal health_changed(current: float, max_hp: float)
signal hit_taken(damage: float, is_blocked: bool, hit_pos: Vector2)
signal combo_updated(hits: int)
signal state_changed(new_state: String)
signal defeated()

@export var is_player: bool = true
@export var fighter_name: String = "KAGE"
@export var max_health: float = 100.0
@export var walk_speed: float = 250.0
@export var back_walk_speed: float = 175.0
@export var jump_velocity: float = -620.0
@export var gravity: float = 1800.0

var current_health: float = 100.0
var opponent: Fighter = null
var facing_direction: float = 1.0 # 1.0 = right, -1.0 = left

var current_state: String = "idle"
var state_timer: float = 0.0

# Attack frame data
var attack_duration: float = 0.0
var attack_startup: float = 0.0
var attack_active_start: float = 0.0
var attack_active_end: float = 0.0
var can_combo_cancel: bool = false
var current_attack_name: String = ""

# Input abstraction (shared between player and AI)
var input_dir: Vector2 = Vector2.ZERO
var input_punch_pressed: bool = false
var input_kick_pressed: bool = false
var input_block_held: bool = false

# Virtual touch input overrides
var touch_dir: Vector2 = Vector2.ZERO
var touch_punch: bool = false
var touch_kick: bool = false
var touch_block: bool = false

# Hit reaction tracking for animations
var last_hit_zone: String = "mid"
var last_hit_heavy: bool = false

# Combat tracking
var combo_count: int = 0
var combo_reset_timer: float = 0.0
var is_invulnerable: bool = false
var is_active_match: bool = true

# V3 Equipment & Scaling Stats
var weapon_id: String = "fists_bare"
var armor_id: String = "gi_novice"
var helmet_id: String = "headband_novice"
var attack_multiplier: float = 1.0
var defense_multiplier: float = 1.0
var head_defense_multiplier: float = 1.0
var reach_multiplier: float = 1.0
var speed_multiplier: float = 1.0
var special_meter: float = 0.0
var max_special_meter: float = 100.0

# Per-match challenge modifiers, configured by CombatManager.
var rules_allow_jump: bool = true
var rules_allow_block: bool = true
var incoming_damage_multiplier: float = 1.0
var outgoing_knockback_multiplier: float = 1.0
var heavy_hits_only: bool = false

@onready var visuals: FighterVisuals = $Visuals
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox_high: Hurtbox = $HurtboxHigh
@onready var hurtbox_mid: Hurtbox = $HurtboxMid
@onready var hurtbox_low: Hurtbox = $HurtboxLow
@onready var body_col: CollisionShape2D = $BodyCollision

# Sounds generator reference
var sound_gen: Node = null

func _ready() -> void:
	current_health = max_health
	visuals.setup_style(is_player)
	visuals.facing = facing_direction

	# Set collision layers
	# Player hurtbox layer 2, Hitbox layer 4 masks 3
	# AI hurtbox layer 3, Hitbox layer 5 masks 2
	if is_player:
		hurtbox_high.collision_layer = 1 << 1 # layer 2
		hurtbox_mid.collision_layer = 1 << 1
		hurtbox_low.collision_layer = 1 << 1
		hitbox.collision_layer = 1 << 3 # layer 4
		hitbox.collision_mask = 1 << 2  # layer 3 (enemy hurtbox)
	else:
		hurtbox_high.collision_layer = 1 << 2 # layer 3
		hurtbox_mid.collision_layer = 1 << 2
		hurtbox_low.collision_layer = 1 << 2
		hitbox.collision_layer = 1 << 4 # layer 5
		hitbox.collision_mask = 1 << 1  # layer 2 (player hurtbox)

	hitbox.attacker = self
	hitbox.hit_landed.connect(_on_hitbox_landed)

	# Locate sound generator autoload or scene node
	sound_gen = get_tree().root.find_child("SoundGenerator", true, false)

func reset_match(start_pos: Vector2, start_facing: float) -> void:
	global_position = start_pos
	velocity = Vector2.ZERO
	facing_direction = start_facing
	current_health = max_health
	current_state = "idle"
	state_timer = 0.0
	combo_count = 0
	is_invulnerable = false
	is_active_match = true
	hitbox.deactivate()
	health_changed.emit(current_health, max_health)

func prepare_for_survival_wave(start_pos: Vector2, start_facing: float, recovery_ratio: float) -> void:
	# Keep earned damage between waves while giving a small, visible recovery window.
	global_position = start_pos
	velocity = Vector2.ZERO
	facing_direction = start_facing
	current_health = minf(max_health, current_health + max_health * recovery_ratio)
	current_state = "idle"
	state_timer = 0.0
	combo_count = 0
	is_invulnerable = false
	is_active_match = false
	hitbox.deactivate()
	health_changed.emit(current_health, max_health)

func _physics_process(delta: float) -> void:
	if not is_active_match and current_state != "knockdown" and current_state != "dead" and current_state != "victory":
		_change_state("idle")
		velocity = Vector2.ZERO
		move_and_slide()
		visuals.update_visuals(delta, self)
		return

	state_timer += delta

	# Combo reset timer
	if combo_reset_timer > 0.0:
		combo_reset_timer -= delta
		if combo_reset_timer <= 0.0:
			combo_count = 0
			combo_updated.emit(0)

	# Read inputs if player
	if is_player and is_active_match:
		_gather_player_inputs()

	# Face opponent when allowed
	if opponent and is_on_floor() and not _is_attacking_state() and current_state != "hit_stun" and current_state != "knockdown" and current_state != "dead":
		var to_opp = opponent.global_position.x - global_position.x
		if abs(to_opp) > 15.0:
			facing_direction = 1.0 if to_opp > 0 else -1.0
	visuals.facing = facing_direction

	# State execution
	match current_state:
		"idle":
			_process_idle_state(delta)
		"walk_forward", "walk_backward":
			_process_walk_state(delta)
		"crouch":
			_process_crouch_state(delta)
		"jump":
			_process_jump_state(delta)
		"land":
			_process_land_state(delta)
		"block":
			_process_block_state(delta)
		"dodge":
			_process_dodge_state(delta)
		"punch_1", "punch_2", "punch_3", "kick_1", "kick_2", "crouch_punch", "crouch_kick", "jump_punch", "jump_kick":
			_process_attack_state(delta)
		"hit_stun":
			_process_hit_stun_state(delta)
		"knockdown":
			_process_knockdown_state(delta)
		"get_up":
			_process_get_up_state(delta)
		"dead":
			_process_dead_state(delta)
		"victory":
			_process_victory_state(delta)

	# Apply gravity if airborne
	if not is_on_floor() and current_state != "dead":
		velocity.y += gravity * delta

	# Soft body push separation so fighters do not clip or overlap
	if opponent and is_on_floor():
		var dx = global_position.x - opponent.global_position.x
		if abs(dx) < 38.0 and abs(global_position.y - opponent.global_position.y) < 60.0:
			var push_dir = signf(dx) if abs(dx) > 0.5 else (1.0 if is_player else -1.0)
			velocity.x += push_dir * 140.0

	move_and_slide()

	# Update visuals
	visuals.update_visuals(delta, self)

	# Clear one-frame press buffers
	input_punch_pressed = false
	input_kick_pressed = false
	touch_punch = false
	touch_kick = false

func _gather_player_inputs() -> void:
	input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1.0
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1.0
	if Input.is_action_pressed("jump"):
		input_dir.y -= 1.0
	if Input.is_action_pressed("crouch"):
		input_dir.y += 1.0

	# Merge touch directional inputs
	if touch_dir != Vector2.ZERO:
		input_dir = touch_dir

	input_punch_pressed = Input.is_action_just_pressed("punch") or touch_punch
	input_kick_pressed = Input.is_action_just_pressed("kick") or touch_kick
	input_block_held = (Input.is_action_pressed("block") or touch_block) and rules_allow_block

func _process_idle_state(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)

	# Priority 1: Check attacks
	if _check_attack_inputs():
		return

	# Priority 2: Check block
	# Holding block key OR walking backwards while opponent is close triggers block
	var walking_back = (input_dir.x != 0.0 and signf(input_dir.x) != facing_direction)
	if rules_allow_block and (input_block_held or (walking_back and opponent and abs(opponent.global_position.x - global_position.x) < 220.0)):
		_change_state("block")
		return

	# Priority 3: Jump
	if rules_allow_jump and input_dir.y < -0.3 and is_on_floor():
		velocity.y = jump_velocity
		velocity.x = input_dir.x * walk_speed * 0.8
		_play_sound("jump", 1.0, 0.6)
		_change_state("jump")
		return

	# Priority 4: Crouch
	if input_dir.y > 0.3 and is_on_floor():
		_change_state("crouch")
		return

	# Priority 5: Movement
	if input_dir.x != 0.0:
		var moving_forward = (signf(input_dir.x) == facing_direction)
		_change_state("walk_forward" if moving_forward else "walk_backward")
		return

func _process_walk_state(delta: float) -> void:
	# Check attacks
	if _check_attack_inputs():
		return

	# Check jump
	if rules_allow_jump and input_dir.y < -0.3 and is_on_floor():
		velocity.y = jump_velocity
		velocity.x = input_dir.x * walk_speed
		_play_sound("jump", 1.0, 0.6)
		_change_state("jump")
		return

	# Check crouch
	if input_dir.y > 0.3 and is_on_floor():
		_change_state("crouch")
		return

	# Check block
	var walking_back = (input_dir.x != 0.0 and signf(input_dir.x) != facing_direction)
	if rules_allow_block and (input_block_held or (walking_back and opponent and abs(opponent.global_position.x - global_position.x) < 220.0)):
		_change_state("block")
		return

	# Movement continuation
	if input_dir.x == 0.0:
		_change_state("idle")
		return

	var moving_forward = (signf(input_dir.x) == facing_direction)
	var speed = walk_speed if moving_forward else back_walk_speed
	velocity.x = input_dir.x * speed

	var desired_state = "walk_forward" if moving_forward else "walk_backward"
	if current_state != desired_state:
		_change_state(desired_state)

func _process_crouch_state(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 1600.0 * delta)

	# Crouch attacks
	if input_punch_pressed:
		_start_attack("crouch_punch")
		return
	if input_kick_pressed:
		_start_attack("crouch_kick")
		return

	# Stand up if down not held
	if input_dir.y <= 0.3:
		_change_state("idle")

func _process_jump_state(delta: float) -> void:
	# Aerial attacks
	if input_punch_pressed:
		_start_attack("jump_punch")
		return
	if input_kick_pressed:
		_start_attack("jump_kick")
		return

	# Land on floor
	if is_on_floor() and state_timer > 0.08:
		_play_sound("land", 1.0, 0.5)
		_change_state("land")

func _process_land_state(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)
	if _check_attack_inputs():
		return
	if state_timer >= 0.12:
		_change_state("idle")

func _process_dodge_state(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	if state_timer >= 0.25:
		is_invulnerable = false
		_change_state("idle")

func _process_block_state(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 1500.0 * delta)

	# Exit block if button released
	var walking_back = (input_dir.x != 0.0 and signf(input_dir.x) != facing_direction)
	if not input_block_held and not walking_back:
		_change_state("idle")
		return

	# Counter attack from block
	if _check_attack_inputs():
		return

func _process_attack_state(delta: float) -> void:
	# Air attack physics
	if not is_on_floor():
		# Maintain horizontal inertia in air
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
	else:
		# Ground friction during attack
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)

	# Hitbox active window
	if state_timer >= attack_active_start and state_timer <= attack_active_end:
		if not hitbox.is_active:
			_position_hitbox_for_attack(current_attack_name)
			hitbox.activate()
			visuals.trigger_attack_trail()
	elif state_timer > attack_active_end:
		if hitbox.is_active:
			hitbox.deactivate()

	# Combo chaining window
	if can_combo_cancel and state_timer >= attack_active_start + 0.05:
		if _check_combo_chain():
			return

	# Attack completed
	if state_timer >= attack_duration:
		hitbox.deactivate()
		if is_on_floor():
			_change_state("idle")
		else:
			_change_state("jump")

func _process_hit_stun_state(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 1000.0 * delta)
	if state_timer >= attack_duration:
		_change_state("idle")

func _process_knockdown_state(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	if state_timer >= 0.50:
		_change_state("get_up")

func _process_get_up_state(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	if state_timer >= 0.45:
		is_invulnerable = false
		_change_state("idle")

func _process_dead_state(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)

func _process_victory_state(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)

func _check_attack_inputs() -> bool:
	if input_punch_pressed:
		_start_attack("punch_1")
		return true
	if input_kick_pressed:
		_start_attack("kick_1")
		return true
	return false

func _check_combo_chain() -> bool:
	match current_attack_name:
		"punch_1": # jab
			if input_punch_pressed:
				_start_attack("punch_2") # jab -> cross
				return true
			if input_kick_pressed:
				_start_attack("kick_2") # jab -> roundhouse
				return true
		"punch_2": # cross
			if input_punch_pressed:
				_start_attack("punch_3") # cross -> hook
				return true
			if input_kick_pressed:
				_start_attack("kick_1") # cross -> side kick
				return true
		"crouch_kick": # low kick
			if input_punch_pressed:
				_start_attack("punch_2") # low kick -> cross
				return true
		"kick_1": # side kick
			if input_kick_pressed:
				_start_attack("kick_2") # side kick -> roundhouse
				return true
	return false

func _start_attack(attack_name: String) -> void:
	current_attack_name = attack_name
	_change_state(attack_name)

	# Configure attack timing & hitbox properties
	match attack_name:
		"punch_1":
			attack_duration = 0.24
			attack_startup = 0.05
			attack_active_start = 0.06
			attack_active_end = 0.16
			can_combo_cancel = true

			hitbox.damage = 8.0
			hitbox.chip_damage = 1.5
			hitbox.knockback = Vector2(170 * facing_direction, -50)
			hitbox.hit_stun = 0.22
			hitbox.attack_type = "mid"
			hitbox.hit_sound = "hit_light"
			hitbox.is_sweep = false
			hitbox.heavy_hit = false
			_play_sound("whoosh_light", 1.2, 0.6)
			velocity.x = 80.0 * facing_direction # slight strike lunge

		"punch_2":
			attack_duration = 0.29
			attack_startup = 0.06
			attack_active_start = 0.07
			attack_active_end = 0.18
			can_combo_cancel = true

			hitbox.damage = 12.0
			hitbox.chip_damage = 2.0
			hitbox.knockback = Vector2(250 * facing_direction, -70)
			hitbox.hit_stun = 0.26
			hitbox.attack_type = "mid"
			hitbox.hit_sound = "hit_light"
			hitbox.is_sweep = false
			hitbox.heavy_hit = false
			_play_sound("whoosh_light", 1.0, 0.7)
			velocity.x = 120.0 * facing_direction

		"punch_3":
			attack_duration = 0.38
			attack_startup = 0.08
			attack_active_start = 0.10
			attack_active_end = 0.24
			can_combo_cancel = false

			hitbox.damage = 18.0
			hitbox.chip_damage = 3.5
			hitbox.knockback = Vector2(380 * facing_direction, -160)
			hitbox.hit_stun = 0.36
			hitbox.attack_type = "high"
			hitbox.hit_sound = "hit_heavy"
			hitbox.is_sweep = false
			hitbox.heavy_hit = true
			_play_sound("whoosh_heavy", 1.1, 0.85)
			velocity.x = 160.0 * facing_direction

		"kick_1":
			attack_duration = 0.31
			attack_startup = 0.07
			attack_active_start = 0.08
			attack_active_end = 0.20
			can_combo_cancel = true

			hitbox.damage = 11.0
			hitbox.chip_damage = 2.0
			hitbox.knockback = Vector2(210 * facing_direction, -60)
			hitbox.hit_stun = 0.25
			hitbox.attack_type = "mid"
			hitbox.hit_sound = "hit_light"
			hitbox.is_sweep = false
			hitbox.heavy_hit = false
			_play_sound("whoosh_heavy", 1.2, 0.7)
			velocity.x = 90.0 * facing_direction

		"kick_2":
			attack_duration = 0.39
			attack_startup = 0.09
			attack_active_start = 0.11
			attack_active_end = 0.25
			can_combo_cancel = false

			hitbox.damage = 17.0
			hitbox.chip_damage = 3.5
			hitbox.knockback = Vector2(360 * facing_direction, -150)
			hitbox.hit_stun = 0.34
			hitbox.attack_type = "high"
			hitbox.hit_sound = "hit_heavy"
			hitbox.is_sweep = false
			hitbox.heavy_hit = true
			_play_sound("whoosh_heavy", 0.95, 0.9)
			velocity.x = 130.0 * facing_direction

		"crouch_punch":
			attack_duration = 0.32
			attack_startup = 0.08
			attack_active_start = 0.11
			attack_active_end = 0.22
			can_combo_cancel = false

			hitbox.damage = 18.0
			hitbox.chip_damage = 3.5
			hitbox.knockback = Vector2(200 * facing_direction, -220)
			hitbox.hit_stun = 0.38
			hitbox.attack_type = "mid"
			hitbox.hit_sound = "hit_heavy"
			hitbox.is_sweep = false
			hitbox.heavy_hit = true
			_play_sound("whoosh_heavy", 1.1, 0.8)
			velocity.x = 100.0 * facing_direction

		"crouch_kick":
			attack_duration = 0.38
			attack_startup = 0.08
			attack_active_start = 0.09
			attack_active_end = 0.23
			can_combo_cancel = false

			hitbox.damage = 14.0
			hitbox.chip_damage = 2.5
			hitbox.knockback = Vector2(230 * facing_direction, -190)
			hitbox.hit_stun = 0.40
			hitbox.attack_type = "low"
			hitbox.hit_sound = "hit_heavy"
			hitbox.is_sweep = true
			hitbox.heavy_hit = true
			_play_sound("sweep", 1.0, 0.8)
			velocity.x = 150.0 * facing_direction

		"jump_punch":
			attack_duration = 0.30
			attack_startup = 0.05
			attack_active_start = 0.06
			attack_active_end = 0.22
			can_combo_cancel = false

			hitbox.damage = 10.0
			hitbox.chip_damage = 2.0
			hitbox.knockback = Vector2(190 * facing_direction, 80)
			hitbox.hit_stun = 0.24
			hitbox.attack_type = "high"
			hitbox.hit_sound = "hit_light"
			hitbox.is_sweep = false
			hitbox.heavy_hit = false
			_play_sound("whoosh_light", 1.1, 0.6)

		"jump_kick":
			attack_duration = 0.34
			attack_startup = 0.06
			attack_active_start = 0.07
			attack_active_end = 0.24
			can_combo_cancel = false

			hitbox.damage = 15.0
			hitbox.chip_damage = 3.0
			hitbox.knockback = Vector2(280 * facing_direction, 60)
			hitbox.hit_stun = 0.30
			hitbox.attack_type = "mid"
			hitbox.hit_sound = "hit_heavy"
			hitbox.is_sweep = false
			hitbox.heavy_hit = true
			_play_sound("whoosh_heavy", 1.0, 0.8)

	# Apply equipment speed and damage scaling
	hitbox.damage *= attack_multiplier
	hitbox.chip_damage *= attack_multiplier
	hitbox.knockback *= outgoing_knockback_multiplier
	attack_duration /= speed_multiplier
	attack_active_start /= speed_multiplier
	attack_active_end /= speed_multiplier

func _position_hitbox_for_attack(attack_name: String) -> void:
	var shape = hitbox.collision_shape.shape as CircleShape2D
	if not shape:
		shape = CircleShape2D.new()
		hitbox.collision_shape.shape = shape

	var r = reach_multiplier
	match attack_name:
		"punch_1":
			hitbox.position = Vector2(53 * facing_direction * r, -105)
			shape.radius = 26.0 * r
		"punch_2":
			hitbox.position = Vector2(65 * facing_direction * r, -103)
			shape.radius = 29.0 * r
		"punch_3":
			hitbox.position = Vector2(55 * facing_direction * r, -115)
			shape.radius = 31.0 * r
		"kick_1":
			hitbox.position = Vector2(70 * facing_direction * r, -84)
			shape.radius = 31.0 * r
		"kick_2":
			hitbox.position = Vector2(67 * facing_direction * r, -115)
			shape.radius = 33.0 * r
		"crouch_punch":
			hitbox.position = Vector2(41 * facing_direction * r, -115)
			shape.radius = 31.0 * r
		"crouch_kick":
			hitbox.position = Vector2(70 * facing_direction * r, -12)
			shape.radius = 29.0 * r
		"jump_punch":
			hitbox.position = Vector2(50 * facing_direction * r, -72)
			shape.radius = 29.0 * r
		"jump_kick":
			hitbox.position = Vector2(62 * facing_direction * r, -58)
			shape.radius = 31.0 * r

func apply_loadout(stats: Dictionary) -> void:
	max_health = stats.get("max_health", 100.0)
	current_health = max_health
	attack_multiplier = stats.get("attack_power", 10.0) / 10.0
	defense_multiplier = 1.0 / (1.0 + float(stats.get("defense", 10.0)) * 0.015)
	head_defense_multiplier = 1.0 / (1.0 + float(stats.get("head_defense", 8.0)) * 0.018)
	reach_multiplier = stats.get("reach_mult", 1.0)
	speed_multiplier = stats.get("speed_mult", 1.0)

	weapon_id = stats.get("weapon_id", "fists_bare")
	armor_id = stats.get("armor_id", "gi_novice")
	helmet_id = stats.get("helmet_id", "headband_novice")

	if visuals:
		visuals.set_equipment_visuals(stats.get("weapon_type", "katana"), armor_id, helmet_id)
	health_changed.emit(current_health, max_health)

func take_environment_damage(amount: float) -> void:
	if not is_active_match or current_health <= 0.0:
		return
	current_health = maxf(current_health - amount * incoming_damage_multiplier, 0.0)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		_die()

func _on_hitbox_landed(target: Node2D, is_blocked: bool) -> void:
	if not is_blocked:
		combo_count += 1
		combo_reset_timer = 1.3
		combo_updated.emit(combo_count)

func receive_hit(h: Hitbox, hit_zone: String) -> bool:
	if not is_active_match or is_invulnerable or current_health <= 0.0:
		return false

	# Determine if hit is coming from the front
	var attacker_dir = signf(h.attacker.global_position.x - global_position.x)
	var is_facing_attacker = (attacker_dir == facing_direction)

	# Check blocking conditions:
	# 1. Manually holding block OR walking backward away from attacker
	# 2. Must be facing the attack
	# 3. Low sweep cannot be blocked while standing; high attacks cannot be blocked while crouching
	var can_block = rules_allow_block and is_facing_attacker and is_on_floor()
	var is_trying_to_block = input_block_held or (input_dir.x != 0.0 and signf(input_dir.x) != facing_direction) or current_state == "block"

	var is_blocked = false
	if can_block and is_trying_to_block:
		if h.is_sweep and current_state != "crouch":
			# Overhead/sweep bypasses standing guard
			is_blocked = false
		else:
			is_blocked = true

	# Deactivate attacker's hitbox for this hit
	hitbox.deactivate()

	if is_blocked:
		# Blocked hit
		last_hit_zone = hit_zone
		last_hit_heavy = false
		var dmg = h.chip_damage * defense_multiplier
		current_health = maxf(current_health - dmg, 1.0) # cannot die from chip damage
		health_changed.emit(current_health, max_health)

		# Reduced knockback and brief block stun
		velocity.x = h.knockback.x * 0.35
		visuals.trigger_block_flash()
		_play_sound("block", 1.0 + randf_range(-0.1, 0.1), 0.8)
		hit_taken.emit(dmg, true, global_position + Vector2(20 * facing_direction, -60))
		return true
	else:
		# Clean hit
		last_hit_zone = hit_zone
		last_hit_heavy = h.heavy_hit
		var def_mult = defense_multiplier
		if hit_zone == "high":
			def_mult *= head_defense_multiplier
		var rule_damage_mult := incoming_damage_multiplier
		if heavy_hits_only and not h.heavy_hit:
			rule_damage_mult *= 0.20
		var dmg = h.damage * def_mult * rule_damage_mult
		current_health = maxf(current_health - dmg, 0.0)
		health_changed.emit(current_health, max_health)

		# Cancel any active attack
		hitbox.deactivate()

		# Play hit sound
		_play_sound(h.hit_sound, randf_range(0.9, 1.1), 1.0)
		visuals.trigger_hit_flash(Color(1.0, 0.2, 0.2) if h.heavy_hit else Color.WHITE)
		hit_taken.emit(dmg, false, global_position + Vector2(0, -60))

		if current_health <= 0.0:
			_die()
			return false

		# Knockdown check
		if h.is_sweep or (h.heavy_hit and current_health < 25.0):
			is_invulnerable = true
			velocity = Vector2(h.knockback.x * 0.8, -250.0)
			_change_state("knockdown")
		else:
			# Hit stun & knockback
			velocity = h.knockback
			attack_duration = h.hit_stun
			_change_state("hit_stun")

		return false

func _die() -> void:
	is_active_match = false
	is_invulnerable = true
	hitbox.deactivate()
	_change_state("dead")
	_play_sound("ko_impact", 1.0, 1.0)
	defeated.emit()

func trigger_victory() -> void:
	is_active_match = false
	hitbox.deactivate()
	_change_state("victory")

func _change_state(new_state: String) -> void:
	current_state = new_state
	state_timer = 0.0
	state_changed.emit(new_state)

func _is_attacking_state() -> bool:
	return current_state.begins_with("punch") or current_state.begins_with("kick") or current_state.ends_with("punch") or current_state.ends_with("kick")

func get_attack_progress() -> float:
	if attack_duration <= 0.001:
		return 0.0
	return clampf(state_timer / attack_duration, 0.0, 1.0)

func _play_sound(sname: String, pitch: float = 1.0, vol: float = 1.0) -> void:
	if sound_gen and sound_gen.has_method("play"):
		sound_gen.play(sname, pitch, vol)
