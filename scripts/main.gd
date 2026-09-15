extends Node2D

const HIT_SPARK_SCENE = preload("res://scenes/effects/hit_spark.tscn")
const DUST_PUFF_SCENE = preload("res://scenes/effects/dust_puff.tscn")

@onready var p1: Fighter = $Player
@onready var p2: Fighter = $Enemy
@onready var camera: StageCamera = $Camera2D
@onready var combat_manager: CombatManager = $CombatManager
@onready var ui: HUD = $CanvasLayer/UI
@onready var effects_container: Node2D = $EffectsContainer

func _ready() -> void:
	# Cross-wire opponents
	p1.opponent = p2
	p2.opponent = p1
	
	# Configure camera
	camera.target_p1 = p1
	camera.target_p2 = p2
	
	# Wire combat manager and UI
	combat_manager.p1 = p1
	combat_manager.p2 = p2
	combat_manager.camera = camera
	
	ui.p1 = p1
	ui.p2 = p2
	ui.combat_manager = combat_manager
	ui.restart_requested.connect(_on_restart)
	
	# Connect hit effects
	p1.hit_taken.connect(_on_fighter_hit_taken)
	p2.hit_taken.connect(_on_fighter_hit_taken)
	
	p1.state_changed.connect(func(st): _on_fighter_state_changed(p1, st))
	p2.state_changed.connect(func(st): _on_fighter_state_changed(p2, st))
	
	# Start match
	combat_manager.start_new_match()

func _on_fighter_hit_taken(damage: float, is_blocked: bool, hit_pos: Vector2) -> void:
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

func _on_restart() -> void:
	combat_manager.start_new_match()
