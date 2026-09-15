class_name DustPuff
extends Node2D

var lifetime: float = 0.35
var time: float = 0.0
var puffs: Array[Dictionary] = []

func _ready() -> void:
	for i in range(5):
		puffs.append({
			"offset": Vector2(randf_range(-18.0, 18.0), randf_range(-3.0, 3.0)),
			"vel": Vector2(randf_range(-30.0, 30.0), randf_range(-20.0, -5.0)),
			"radius": randf_range(4.0, 8.0)
		})

func _process(delta: float) -> void:
	time += delta
	if time >= lifetime:
		queue_free()
		return
	
	for p in puffs:
		p.offset += p.vel * delta
	
	queue_redraw()

func _draw() -> void:
	var progress = time / lifetime
	var alpha = (1.0 - progress) * 0.35
	var col = Color(0.6, 0.55, 0.5, alpha)
	
	for p in puffs:
		var r = p.radius * (1.0 + progress * 0.8)
		draw_circle(p.offset, r, col)
