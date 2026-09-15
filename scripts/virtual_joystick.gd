class_name FightJoystick
extends Control

signal direction_changed(dir: Vector2, octant: String)

@export var radius: float = 65.0
@export var knob_radius: float = 28.0
@export var dead_zone: float = 0.16
@export var full_threshold: float = 0.75

var knob_offset: Vector2 = Vector2.ZERO
var target_knob_offset: Vector2 = Vector2.ZERO
var current_dir: Vector2 = Vector2.ZERO
var current_octant: String = "NEUTRAL"
var last_angle: float = 0.0

var is_pressed: bool = false
var touch_id: int = -1

# Visual colors (dark translucent martial aesthetic)
const COLOR_BASE_BG = Color(0.04, 0.05, 0.09, 0.45)
const COLOR_BASE_BORDER = Color(0.25, 0.35, 0.50, 0.55)
const COLOR_BASE_ACTIVE = Color(0.10, 0.75, 1.0, 0.70)
const COLOR_KNOB_BG = Color(0.08, 0.10, 0.16, 0.85)
const COLOR_KNOB_BORDER = Color(0.35, 0.45, 0.65, 0.70)
const COLOR_KNOB_ACTIVE = Color(0.20, 0.90, 1.0, 0.95)
const COLOR_TICKS = Color(0.40, 0.50, 0.70, 0.30)

func _ready() -> void:
	# Receive raw touches in _input so a second finger on an action button never
	# interrupts this control's tracked finger.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(radius * 2.5, radius * 2.5)

func _process(delta: float) -> void:
	if not is_pressed:
		knob_offset = knob_offset.lerp(Vector2.ZERO, delta * 28.0)
		if knob_offset.length_squared() < 0.5:
			knob_offset = Vector2.ZERO
		queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1 and get_global_rect().grow(32.0).has_point(event.position):
			touch_id = event.index
			is_pressed = true
			_update_touch_position(_to_local_position(event.position))
		elif not event.pressed and event.index == touch_id:
			_release_touch()
	elif event is InputEventScreenDrag and event.index == touch_id:
		_update_touch_position(_to_local_position(event.position))

func _to_local_position(viewport_position: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * viewport_position

func _update_touch_position(pos: Vector2) -> void:
	var center = size * 0.5
	var delta = pos - center
	var dist = delta.length()
	
	# Clamp knob to outer radius
	if dist > radius:
		knob_offset = delta.normalized() * radius
	else:
		knob_offset = delta
	
	var norm_dist = dist / radius
	if norm_dist < dead_zone:
		_set_direction(Vector2.ZERO, "NEUTRAL")
	else:
		# Calculate angle and resolve 8-direction octant with hysteresis
		var angle = delta.angle() # [-PI, PI]
		var octant_data = _resolve_octant(angle)
		_set_direction(octant_data.dir, octant_data.name)
	
	queue_redraw()

func _release_touch() -> void:
	touch_id = -1
	is_pressed = false
	_set_direction(Vector2.ZERO, "NEUTRAL")
	queue_redraw()

func _resolve_octant(ang: float) -> Dictionary:
	# Hold the previous octant for an extra ~5.7 degrees past a boundary.
	# This prevents diagonal flicker when a thumb sits near a sector edge.
	var candidate: Dictionary = _raw_octant(ang)
	if current_octant != "NEUTRAL" and candidate.name != current_octant:
		var angular_change = absf(wrapf(ang - last_angle, -PI, PI))
		if angular_change < PI / 8.0 + 0.10:
			return {"dir": current_dir, "name": current_octant}
	last_angle = ang
	return candidate

func _raw_octant(ang: float) -> Dictionary:
	# 8-direction sector matching:
	# RIGHT: [-PI/8, PI/8]
	# DOWN-RIGHT: [PI/8, 3PI/8]
	# DOWN: [3PI/8, 5PI/8]
	# DOWN-LEFT: [5PI/8, 7PI/8]
	# LEFT: [7PI/8, PI] or [-PI, -7PI/8]
	# UP-LEFT: [-7PI/8, -5PI/8]
	# UP: [-5PI/8, -3PI/8]
	# UP-RIGHT: [-3PI/8, -PI/8]
	var pi_8 = PI / 8.0
	
	if ang >= -pi_8 and ang < pi_8:
		return {"dir": Vector2(1, 0), "name": "RIGHT"}
	elif ang >= pi_8 and ang < 3.0 * pi_8:
		return {"dir": Vector2(1, 1), "name": "DOWN_RIGHT"}
	elif ang >= 3.0 * pi_8 and ang < 5.0 * pi_8:
		return {"dir": Vector2(0, 1), "name": "DOWN"}
	elif ang >= 5.0 * pi_8 and ang < 7.0 * pi_8:
		return {"dir": Vector2(-1, 1), "name": "DOWN_LEFT"}
	elif ang >= 7.0 * pi_8 or ang < -7.0 * pi_8:
		return {"dir": Vector2(-1, 0), "name": "LEFT"}
	elif ang >= -7.0 * pi_8 and ang < -5.0 * pi_8:
		return {"dir": Vector2(-1, -1), "name": "UP_LEFT"}
	elif ang >= -5.0 * pi_8 and ang < -3.0 * pi_8:
		return {"dir": Vector2(0, -1), "name": "UP"}
	else:
		return {"dir": Vector2(1, -1), "name": "UP_RIGHT"}

func _set_direction(new_dir: Vector2, octant_name: String) -> void:
	if current_dir != new_dir:
		current_dir = new_dir
		current_octant = octant_name
		direction_changed.emit(current_dir, current_octant)

func _draw() -> void:
	var center = size * 0.5
	
	# 1. Outer base disc
	draw_circle(center, radius, COLOR_BASE_BG)
	
	# 2. Outer border ring
	var border_col = COLOR_BASE_ACTIVE if is_pressed else COLOR_BASE_BORDER
	draw_arc(center, radius, 0, TAU, 36, border_col, 2.5, true)
	
	# 3. Directional tick marks at 8 cardinal & diagonal angles
	for i in range(8):
		var a = i * (PI / 4.0)
		var p1 = center + Vector2(cos(a), sin(a)) * (radius - 8.0)
		var p2 = center + Vector2(cos(a), sin(a)) * (radius - 2.0)
		draw_line(p1, p2, COLOR_TICKS, 1.5, true)
	
	# 4. Dead-zone inner guide (subtle)
	draw_arc(center, radius * dead_zone, 0, TAU, 20, Color(0.3, 0.4, 0.6, 0.2), 1.0, true)
	
	# 5. Movable thumb knob
	var knob_center = center + knob_offset
	draw_circle(knob_center, knob_radius, COLOR_KNOB_BG)
	
	var knob_rim = COLOR_KNOB_ACTIVE if is_pressed else COLOR_KNOB_BORDER
	draw_arc(knob_center, knob_radius, 0, TAU, 28, knob_rim, 2.0, true)
	draw_circle(knob_center, 4.0, knob_rim)
	
	# Optional subtle connecting tether line if dragged far
	if is_pressed and knob_offset.length() > radius * 0.3:
		draw_line(center, knob_center, Color(0.2, 0.8, 1.0, 0.25), 1.5, true)
