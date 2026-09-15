class_name StageCamera
extends Camera2D

@export var target_p1: Fighter
@export var target_p2: Fighter

@export var min_zoom: float = 0.78
@export var max_zoom: float = 0.98
@export var base_y: float = 370.0

var shake_intensity: float = 0.0
var shake_decay: float = 8.0

func _process(delta: float) -> void:
	# Process screen shake
	if shake_intensity > 0.0:
		shake_intensity = maxf(shake_intensity - shake_decay * delta, 0.0)
		offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		offset = Vector2.ZERO
	
	if target_p1 == null or target_p2 == null:
		return
	
	# Calculate midpoint
	var mid_x = (target_p1.global_position.x + target_p2.global_position.x) * 0.5
	# Clamp camera within arena limits
	var target_x = clampf(mid_x, -160.0, 160.0)
	
	global_position.x = lerpf(global_position.x, target_x, delta * 5.0)
	global_position.y = base_y
	
	# Calculate distance for dynamic zoom
	var dist = abs(target_p1.global_position.x - target_p2.global_position.x)
	var t = clampf((dist - 160.0) / 520.0, 0.0, 1.0)
	var desired_zoom = lerpf(max_zoom, min_zoom, t)
	zoom = zoom.lerp(Vector2(desired_zoom, desired_zoom), delta * 4.0)

func add_shake(intensity: float) -> void:
	shake_intensity = maxf(shake_intensity, intensity)
