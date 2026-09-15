class_name CombatManager
extends Node

signal match_state_changed(state: String)
signal timer_updated(time_left: int)
signal announcement_shown(text: String, subtext: String)
signal match_ended(winner_name: String, is_player_winner: bool, stats: Dictionary)

@export var p1: Fighter
@export var p2: Fighter
@export var camera: StageCamera

const ROUND_TIME_LIMIT = 99.0
const ROUNDS_TO_WIN = 2

var current_round: int = 1
var round_timer: float = ROUND_TIME_LIMIT
var is_round_active: bool = false
var match_over: bool = false

var p1_round_wins: int = 0
var p2_round_wins: int = 0

# Match statistics
var p1_total_hits: int = 0
var p1_max_combo: int = 0
var total_match_time: float = 0.0

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
	
	_start_round(current_round)

func _process(delta: float) -> void:
	if not is_round_active or match_over:
		return
	
	total_match_time += delta
	round_timer -= delta
	
	var displayed_time = maxi(int(round_timer), 0)
	timer_updated.emit(displayed_time)
	
	if round_timer <= 0.0:
		_on_timeout()

func _start_round(round_num: int) -> void:
	is_round_active = false
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
	p2_round_wins += 1
	_resolve_round_end(p2, p1, false)

func _on_p2_defeated() -> void:
	if not is_round_active:
		return
	is_round_active = false
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
		if p1.current_health > p2.current_health:
			p1_round_wins += 1
			_resolve_round_end(p1, p2, true)
		elif p2.current_health > p1.current_health:
			p2_round_wins += 1
			_resolve_round_end(p2, p1, false)
		else:
			p1_round_wins += 1
			p2_round_wins += 1
			_resolve_round_end(null, null, false)

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

func _on_p1_hit_taken(_damage: float, is_blocked: bool, _pos: Vector2) -> void:
	if camera:
		camera.add_shake(3.0 if is_blocked else 7.0)

func _on_p2_hit_taken(_damage: float, is_blocked: bool, _pos: Vector2) -> void:
	if not is_blocked:
		p1_total_hits += 1
	if camera:
		camera.add_shake(3.0 if is_blocked else 9.0)

func _play_sound(sname: String, pitch: float = 1.0, vol: float = 1.0) -> void:
	if sound_gen and sound_gen.has_method("play"):
		sound_gen.play(sname, pitch, vol)
