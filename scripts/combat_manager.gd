class_name CombatManager
extends Node

signal match_state_changed(state: String)
signal timer_updated(time_left: int)
signal announcement_shown(text: String, subtext: String)
signal match_ended(winner_name: String, is_player_winner: bool, stats: Dictionary)
signal training_diagnostic_updated(last_dmg: float, combo_hits: int)
signal survival_wave_changed(current_wave: int, total_waves: int)

@export var p1: Fighter
@export var p2: Fighter
@export var camera: StageCamera

const ROUND_TIME_LIMIT = 99.0
const ROUNDS_TO_WIN = 2

var current_round: int = 1
var round_timer: float = ROUND_TIME_LIMIT
var is_round_active: bool = false
var match_over: bool = false

var is_training_mode: bool = false
var active_rule: String = ""
var is_survival_mode: bool = false
var survival_wave: int = 1
var survival_max_waves: int = 6
const SURVIVAL_RECOVERY_RATIO := 0.18
var survival_base_enemy_health: float = 100.0
var survival_base_enemy_attack: float = 1.0

var p1_round_wins: int = 0
var p2_round_wins: int = 0

# Match statistics
var p1_total_hits: int = 0
var p1_max_combo: int = 0
var total_match_time: float = 0.0
var environment_tick: float = 1.0

var sound_gen: Node
var hud: HUD

func _ready() -> void:
	sound_gen = get_tree().root.find_child("SoundGenerator", true, false)

func initialize(p1_ref: Fighter, p2_ref: Fighter, camera_ref: StageCamera) -> void:
	p1 = p1_ref
	p2 = p2_ref
	camera = camera_ref

	if p1:
		if not p1.defeated.is_connected(_on_p1_defeated):
			p1.defeated.connect(_on_p1_defeated)
		if not p1.combo_updated.is_connected(_on_p1_combo_updated):
			p1.combo_updated.connect(_on_p1_combo_updated)
		if not p1.hit_taken.is_connected(_on_p1_hit_taken):
			p1.hit_taken.connect(_on_p1_hit_taken)

	if p2:
		if not p2.defeated.is_connected(_on_p2_defeated):
			p2.defeated.connect(_on_p2_defeated)
		if not p2.hit_taken.is_connected(_on_p2_hit_taken):
			p2.hit_taken.connect(_on_p2_hit_taken)

func start_new_match() -> void:
	p1_round_wins = 0
	p2_round_wins = 0
	current_round = 1
	p1_total_hits = 0
	p1_max_combo = 0
	total_match_time = 0.0
	match_over = false
	environment_tick = 1.0
	_apply_active_rule()

	if is_survival_mode:
		survival_wave = 1
		survival_base_enemy_health = p2.max_health if p2 else 100.0
		survival_base_enemy_attack = p2.attack_multiplier if p2 else 1.0
		_start_survival_wave()
	else:
		_start_round(current_round)

func _process(delta: float) -> void:
	if not is_round_active or match_over:
		return

	total_match_time += delta
	if active_rule == "floor_burn":
		environment_tick -= delta
		if environment_tick <= 0.0:
			environment_tick = 1.0
			if p1:
				p1.take_environment_damage(3.0)
			if p2:
				p2.take_environment_damage(3.0)
	round_timer -= delta

	var displayed_time = maxi(int(round_timer), 0)
	timer_updated.emit(displayed_time)

	if round_timer <= 0.0:
		_on_timeout()

func _apply_active_rule() -> void:
	for fighter in [p1, p2]:
		if fighter:
			fighter.rules_allow_jump = true
			fighter.rules_allow_block = true
			fighter.incoming_damage_multiplier = 1.0
			fighter.outgoing_knockback_multiplier = 1.0
			fighter.heavy_hits_only = false
	match active_rule:
		"no_jump":
			if p1: p1.rules_allow_jump = false
			if p2: p2.rules_allow_jump = false
		"no_block":
			if p1: p1.rules_allow_block = false
			if p2: p2.rules_allow_block = false
		"heavy_hits_only", "heavy_armor":
			if p2: p2.heavy_hits_only = true
		"high_knockback":
			if p1: p1.outgoing_knockback_multiplier = 2.0
			if p2: p2.outgoing_knockback_multiplier = 2.0
		"sudden_death":
			if p1: p1.incoming_damage_multiplier = 2.0
			if p2: p2.incoming_damage_multiplier = 2.0

func _start_round(round_num: int) -> void:
	is_round_active = false
	if is_training_mode:
		round_timer = 999.0
	elif active_rule == "fast_timer":
		round_timer = 30.0
	else:
		round_timer = ROUND_TIME_LIMIT
	timer_updated.emit(int(round_timer))

	if p1:
		p1.reset_match(Vector2(-200.0, 540.0), 1.0)
		p1.is_active_match = false
	if p2:
		p2.reset_match(Vector2(200.0, 540.0), -1.0)
		p2.is_active_match = false

	var round_title = "ROUND " + str(round_num)
	if p1_round_wins == ROUNDS_TO_WIN - 1 and p2_round_wins == ROUNDS_TO_WIN - 1:
		round_title = "FINAL ROUND"

	announcement_shown.emit(round_title, "GET READY")
	_play_sound("round_bell", 1.0, 0.9)

	# Start countdown timer
	get_tree().create_timer(1.2).timeout.connect(func():
		if match_over:
			return
		announcement_shown.emit("FIGHT!", "")
		_play_sound("whoosh_heavy", 1.3, 0.8)
		if p1:
			p1.is_active_match = true
		if p2:
			p2.is_active_match = true
		is_round_active = true

		get_tree().create_timer(0.9).timeout.connect(func():
			if is_round_active:
				announcement_shown.emit("", "")
		)
	)

func _on_p1_defeated() -> void:
	if not is_round_active:
		return
	is_round_active = false
	if is_survival_mode:
		_finish_survival(false)
		return
	p2_round_wins += 1
	_resolve_round_end(p2, p1, false)

func _on_p2_defeated() -> void:
	if is_training_mode:
		get_tree().create_timer(0.8).timeout.connect(func():
			if is_training_mode and p2:
				p2.current_health = p2.max_health
				p2.is_active_match = true
				p2.is_invulnerable = false
				p2.health_changed.emit(p2.current_health, p2.max_health)
				p2._change_state("idle")
		)
		return

	if not is_round_active:
		return
	is_round_active = false
	if is_survival_mode:
		_resolve_survival_wave()
		return
	p1_round_wins += 1
	_resolve_round_end(p1, p2, true)

func _on_timeout() -> void:
	if not is_round_active:
		return
	is_round_active = false
	if p1:
		p1.is_active_match = false
	if p2:
		p2.is_active_match = false

	_play_sound("round_bell", 0.9, 1.0)

	if p1 and p2:
		if is_survival_mode:
			_finish_survival(false)
		elif p1.current_health > p2.current_health:
			p1_round_wins += 1
			_resolve_round_end(p1, p2, true)
		elif p2.current_health > p1.current_health:
			p2_round_wins += 1
			_resolve_round_end(p2, p1, false)
		else:
			p1_round_wins += 1
			p2_round_wins += 1
			_resolve_round_end(null, null, false)

func _start_survival_wave() -> void:
	is_round_active = false
	round_timer = 55.0
	timer_updated.emit(int(round_timer))
	survival_wave_changed.emit(survival_wave, survival_max_waves)
	if p1:
		if survival_wave == 1:
			p1.reset_match(Vector2(-200.0, 540.0), 1.0)
		else:
			p1.prepare_for_survival_wave(Vector2(-200.0, 540.0), 1.0, SURVIVAL_RECOVERY_RATIO)
	if p2:
		var wave_scale := 1.0 + 0.14 * float(survival_wave - 1)
		p2.max_health = survival_base_enemy_health * wave_scale
		p2.attack_multiplier = survival_base_enemy_attack * (1.0 + 0.10 * float(survival_wave - 1))
		p2.fighter_name = "WAVE %d OPPONENT" % survival_wave
		p2.reset_match(Vector2(200.0, 540.0), -1.0)
		p2.is_active_match = false
	announcement_shown.emit("WAVE %d / %d" % [survival_wave, survival_max_waves], "SURVIVE THE GAUNTLET")
	_play_sound("round_bell", 1.08, 0.9)
	get_tree().create_timer(1.2).timeout.connect(func():
		if match_over:
			return
		announcement_shown.emit("FIGHT!", "")
		if p1:
			p1.is_active_match = true
		if p2:
			p2.is_active_match = true
		is_round_active = true
		get_tree().create_timer(0.9).timeout.connect(func():
			if is_round_active:
				announcement_shown.emit("", "")
		)
	)

func _resolve_survival_wave() -> void:
	if camera:
		camera.add_shake(12.0)
	if p1:
		p1.trigger_victory()
	announcement_shown.emit("WAVE CLEARED", "+18% VITALITY")
	if survival_wave >= survival_max_waves:
		get_tree().create_timer(1.8).timeout.connect(func(): _finish_survival(true))
		return
	survival_wave += 1
	get_tree().create_timer(2.0).timeout.connect(func():
		if not match_over:
			_start_survival_wave()
	)

func _finish_survival(player_won: bool) -> void:
	if match_over:
		return
	match_over = true
	is_round_active = false
	if p1:
		p1.is_active_match = false
	if p2:
		p2.is_active_match = false
	var winner_name := p1.fighter_name if player_won else p2.fighter_name
	var stats := {
		"total_hits": p1_total_hits,
		"max_combo": p1_max_combo,
		"match_time": int(total_match_time),
		"p1_rounds": survival_wave if player_won else survival_wave - 1,
		"p2_rounds": 0,
		"survival_waves": survival_wave
	}
	match_ended.emit(winner_name, player_won, stats)

func _resolve_round_end(winner: Fighter, loser: Fighter, is_player_win: bool) -> void:
	if camera:
		camera.add_shake(14.0)

	if winner:
		winner.trigger_victory()

	var ko_text = "K.O.!" if (loser and loser.current_health <= 0.0) else "TIME UP!"
	announcement_shown.emit(ko_text, "ROUND OVER")

	get_tree().create_timer(2.2).timeout.connect(func():
		# Check if match is won
		if p1_round_wins >= ROUNDS_TO_WIN or p2_round_wins >= ROUNDS_TO_WIN:
			match_over = true
			var match_winner_name = p1.fighter_name if p1_round_wins >= ROUNDS_TO_WIN else p2.fighter_name
			var player_won = (p1_round_wins >= ROUNDS_TO_WIN)

			var stats = {
				"total_hits": p1_total_hits,
				"max_combo": p1_max_combo,
				"match_time": int(total_match_time),
				"p1_rounds": p1_round_wins,
				"p2_rounds": p2_round_wins
			}
			match_ended.emit(match_winner_name, player_won, stats)
		else:
			current_round += 1
			_start_round(current_round)
	)

func _on_p1_combo_updated(hits: int) -> void:
	if hits > p1_max_combo:
		p1_max_combo = hits
	if is_training_mode:
		training_diagnostic_updated.emit(0.0, hits)

func _on_p1_hit_taken(_damage: float, is_blocked: bool, _pos: Vector2) -> void:
	if camera:
		camera.add_shake(3.0 if is_blocked else 7.0)

func _on_p2_hit_taken(damage: float, is_blocked: bool, _pos: Vector2) -> void:
	if not is_blocked:
		p1_total_hits += 1
		if is_training_mode:
			training_diagnostic_updated.emit(damage, p1_max_combo)
	if camera:
		camera.add_shake(3.0 if is_blocked else 9.0)

func _play_sound(sname: String, pitch: float = 1.0, vol: float = 1.0) -> void:
	if sound_gen and sound_gen.has_method("play"):
		sound_gen.play(sname, pitch, vol)
