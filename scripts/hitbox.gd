class_name Hitbox
extends Area2D

signal hit_landed(target: Node2D, is_blocked: bool)

@export var damage: float = 10.0
@export var chip_damage: float = 2.0
@export var knockback: Vector2 = Vector2(240, -100)
@export var hit_stun: float = 0.22
@export var attack_type: String = "mid" # "high", "mid", "low"
@export var hit_sound: String = "hit_light"
@export var is_sweep: bool = false
@export var heavy_hit: bool = false

var attacker: CharacterBody2D
var already_hit: Array[Node2D] = []

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	monitoring = true
	monitorable = true
	area_entered.connect(_on_area_entered)
	deactivate()

func activate() -> void:
	already_hit.clear()
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	monitoring = true

func deactivate() -> void:
	already_hit.clear()
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	monitoring = false

func _on_area_entered(other_area: Area2D) -> void:
	if not monitoring or (collision_shape and collision_shape.disabled):
		return
	if other_area is Hurtbox:
		var target_fighter = other_area.fighter
		if target_fighter == null or target_fighter == attacker:
			return
		if already_hit.has(target_fighter):
			return
		
		already_hit.append(target_fighter)
		var is_blocked = other_area.take_hit(self)
		hit_landed.emit(target_fighter, is_blocked)
