class_name Hurtbox
extends Area2D

@export var zone: String = "mid" # "high", "mid", "low"
var fighter: CharacterBody2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	monitoring = true
	monitorable = true
	if fighter == null:
		var p = get_parent()
		while p:
			if p is CharacterBody2D:
				fighter = p
				break
			p = p.get_parent()

func take_hit(hitbox: Hitbox) -> bool:
	if fighter and fighter.has_method("receive_hit"):
		return fighter.receive_hit(hitbox, zone)
	return false
