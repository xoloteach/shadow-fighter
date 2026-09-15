class_name HitSpark
extends Node2D

var spark_color: Color = Color(1.0, 0.85, 0.2)
var is_blocked: bool = false
var lifetime: float = 0.22
var time: float = 0.0

var spark_lines: Array[Vector2] = []
var spark_lengths: Array[float] = []

func _ready() -> void:
	if is_blocked:
		spark_color = Color(0.4, 0.85, 1.0)
	
	# Generate 8-12 radial spark bursts
	var count = 8 if is_blocked else 12
	for i in range(count):
		var ang = randf() * TAU
		var len = randf_range(16.0, 36.0) if not is_blocked else randf_range(10.0, 22.0)
		spark_lines.append(Vector2.from_angle(ang))
		spark_lengths.append(len)

func _process(delta: float) -> void:
	time += delta
	if time >= lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var progress = time / lifetime
	var alpha = 1.0 - progress
	
	# Central burst flash
	var burst_radius = (1.0 - progress) * (18.0 if not is_blocked else 12.0)
	var col = spark_color
	col.a = alpha * 0.9
	draw_circle(Vector2.ZERO, burst_radius, col)
	draw_circle(Vector2.ZERO, burst_radius * 0.5, Color(1, 1, 1, alpha))
	
	# Flying sparks / needles
	for i in range(spark_lines.size()):
		var dir = spark_lines[i]
		var max_len = spark_lengths[i]
		var start_dist = progress * max_len * 0.5
		var end_dist = progress * max_len
		var p1 = dir * start_dist
		var p2 = dir * end_dist
		var line_col = spark_color
		line_col.a = alpha
		draw_line(p1, p2, line_col, 2.5 * (1.0 - progress), true)
