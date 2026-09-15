class_name Arena
extends Node2D

# Atmospheric silhouette arena with multi-layered parallax scenery,
# dynamic drifting cherry blossom petals, lantern flickers, and rolling mist.

@export var arena_width: float = 1200.0 # bounds: -600 to +600
@export var floor_y: float = 540.0

var time: float = 0.0

# Petals simulation
const PETAL_COUNT = 36
var petals: Array[Dictionary] = []

# Mist layers
const MIST_COUNT = 8
var mist_clouds: Array[Dictionary] = []

func _ready() -> void:
	# Initialize drifting sakura petals
	for i in range(PETAL_COUNT):
		petals.append({
			"pos": Vector2(randf_range(-700.0, 700.0), randf_range(100.0, 560.0)),
			"speed": randf_range(40.0, 90.0),
			"sway_speed": randf_range(1.5, 3.5),
			"sway_amt": randf_range(20.0, 45.0),
			"size": randf_range(3.0, 6.5),
			"rot": randf() * TAU,
			"rot_speed": randf_range(-2.0, 2.0),
			"alpha": randf_range(0.35, 0.75)
		})
	
	# Initialize rolling mist clouds
	for i in range(MIST_COUNT):
		mist_clouds.append({
			"pos": Vector2(randf_range(-700.0, 700.0), floor_y - randf_range(10.0, 45.0)),
			"radius_x": randf_range(70.0, 140.0),
			"radius_y": randf_range(18.0, 35.0),
			"speed": randf_range(15.0, 35.0),
			"alpha": randf_range(0.06, 0.14)
		})

func _process(delta: float) -> void:
	time += delta
	
	# Animate drifting petals
	for p in petals:
		p.pos.x += p.speed * delta
		p.pos.y += (p.speed * 0.4) * delta + sin(time * p.sway_speed) * 0.4
		p.rot += p.rot_speed * delta
		
		# Wrap around arena
		if p.pos.x > 750.0:
			p.pos.x = -750.0
			p.pos.y = randf_range(100.0, 500.0)
		if p.pos.y > floor_y:
			p.pos.y = randf_range(100.0, 250.0)
			p.pos.x = randf_range(-700.0, 400.0)
	
	# Animate rolling mist
	for m in mist_clouds:
		m.pos.x += m.speed * delta
		if m.pos.x > 750.0:
			m.pos.x = -750.0
	
	queue_redraw()

func _draw() -> void:
	var vp_left = -800.0
	var vp_right = 800.0
	var vp_width = vp_right - vp_left
	
	# 1. Sky Gradient (Vertical Sunset Sky)
	var sky_steps = 14
	var step_h = 720.0 / sky_steps
	var sky_colors = [
		Color("#0b0816"), # Deep Indigo midnight top
		Color("#140d24"),
		Color("#22102f"),
		Color("#38133b"),
		Color("#521741"),
		Color("#741d40"),
		Color("#982638"), # Crimson dusk
		Color("#ba382f"),
		Color("#d65427"), # Fiery orange
		Color("#ea7824"),
		Color("#f89d2c"), # Sunset amber
		Color("#ffc244"),
		Color("#ffd868"),
		Color("#ffe590")  # Horizon gold glow
	]
	
	for i in range(sky_steps):
		var y_top = -100.0 + i * step_h
		var c1 = sky_colors[mini(i, sky_colors.size() - 1)]
		var c2 = sky_colors[mini(i + 1, sky_colors.size() - 1)]
		
		var rect_pts = PackedVector2Array([
			Vector2(vp_left, y_top),
			Vector2(vp_right, y_top),
			Vector2(vp_right, y_top + step_h + 1),
			Vector2(vp_left, y_top + step_h + 1)
		])
		var col_arr = PackedColorArray([c1, c1, c2, c2])
		draw_polygon(rect_pts, col_arr)
	
	# 2. Giant Glowing Sun / Moon setting on the horizon
	var sun_pos = Vector2(0, 360)
	draw_circle(sun_pos, 160.0, Color(1.0, 0.45, 0.2, 0.12))
	draw_circle(sun_pos, 110.0, Color(1.0, 0.6, 0.25, 0.25))
	draw_circle(sun_pos, 75.0, Color(1.0, 0.78, 0.4, 0.5))
	draw_circle(sun_pos, 52.0, Color(1.0, 0.95, 0.75, 0.95))
	
	# 3. Distant Mountains Silhouette
	var mtn_col = Color("#1e142c")
	var mtn_pts = PackedVector2Array([
		Vector2(vp_left, 560),
		Vector2(-700, 390),
		Vector2(-520, 440),
		Vector2(-360, 340),
		Vector2(-200, 430),
		Vector2(-60, 360),
		Vector2(110, 410),
		Vector2(290, 320),
		Vector2(460, 420),
		Vector2(640, 350),
		Vector2(vp_right, 410),
		Vector2(vp_right, 560)
	])
	draw_colored_polygon(mtn_pts, mtn_col)
	
	# 4. Midground Pagoda & Temple Architecture Silhouette
	var mid_col = Color("#120d1c")
	_draw_temple_pagoda(Vector2(-380, floor_y), mid_col)
	_draw_torii_gate(Vector2(360, floor_y), mid_col)
	
	# Swaying Bamboo grove & stylized bonsai silhouettes
	_draw_bamboo_cluster(Vector2(-540, floor_y), mid_col)
	_draw_bamboo_cluster(Vector2(530, floor_y), mid_col)
	_draw_pine_tree(Vector2(-220, floor_y), mid_col)
	_draw_pine_tree(Vector2(200, floor_y), mid_col)
	
	# 5. Foreground Platform / Dojo Deck
	var fg_deck_col = Color("#070609")
	var deck_pts = PackedVector2Array([
		Vector2(vp_left, floor_y),
		Vector2(vp_right, floor_y),
		Vector2(vp_right, 740),
		Vector2(vp_left, 740)
	])
	draw_colored_polygon(deck_pts, fg_deck_col)
	
	# Deck edge highlight & wooden plank trims
	draw_line(Vector2(vp_left, floor_y), Vector2(vp_right, floor_y), Color("#241c30"), 3.0)
	draw_line(Vector2(vp_left, floor_y + 6), Vector2(vp_right, floor_y + 6), Color("#13101c"), 2.0)
	
	# Planks / Stone seams
	for x_seam in range(-600, 601, 80):
		draw_line(Vector2(x_seam, floor_y), Vector2(x_seam, 720), Color("#040306"), 2.0)
	
	# 6. Stone Lanterns with flickering flame glow
	_draw_stone_lantern(Vector2(-430, floor_y), fg_deck_col)
	_draw_stone_lantern(Vector2(430, floor_y), fg_deck_col)
	
	# 7. Drifting Rolling Mist
	for m in mist_clouds:
		var col = Color(0.85, 0.75, 0.8, m.alpha)
		# Draw oval mist
		var pts = PackedVector2Array()
		for a in range(16):
			var ang = (float(a) / 16.0) * TAU
			pts.append(m.pos + Vector2(cos(ang) * m.radius_x, sin(ang) * m.radius_y))
		draw_colored_polygon(pts, col)
	
	# 8. Drifting Sakura Blossom Petals
	for p in petals:
		var c = Color(0.95, 0.25, 0.45, p.alpha)
		_draw_sakura_petal(p.pos, p.size, p.rot, c)

func _draw_temple_pagoda(base: Vector2, col: Color) -> void:
	# 3-tiered pagoda silhouette
	var tier_heights = [60.0, 52.0, 44.0]
	var cur_y = base.y
	var widths = [130.0, 100.0, 75.0]
	
	for i in range(3):
		var w = widths[i]
		var h = tier_heights[i]
		# Roof with curved upward eaves
		var roof_pts = PackedVector2Array([
			Vector2(base.x - w * 0.5 - 16, cur_y - h + 10),
			Vector2(base.x - w * 0.35, cur_y - h),
			Vector2(base.x, cur_y - h - 14),
			Vector2(base.x + w * 0.35, cur_y - h),
			Vector2(base.x + w * 0.5 + 16, cur_y - h + 10),
			Vector2(base.x + w * 0.4, cur_y - h + 14),
			Vector2(base.x - w * 0.4, cur_y - h + 14)
		])
		draw_colored_polygon(roof_pts, col)
		
		# Pagoda walls
		var wall_pts = PackedVector2Array([
			Vector2(base.x - w * 0.3, cur_y - h + 14),
			Vector2(base.x + w * 0.3, cur_y - h + 14),
			Vector2(base.x + w * 0.3, cur_y),
			Vector2(base.x - w * 0.3, cur_y)
		])
		draw_colored_polygon(wall_pts, col)
		cur_y -= h - 6
	
	# Pagoda spire / finial
	draw_line(Vector2(base.x, cur_y - 12), Vector2(base.x, cur_y - 45), col, 3.0)

func _draw_torii_gate(base: Vector2, col: Color) -> void:
	var gw = 120.0
	var gh = 130.0
	# Pillars
	draw_line(Vector2(base.x - gw * 0.35, base.y), Vector2(base.x - gw * 0.32, base.y - gh), col, 9.0)
	draw_line(Vector2(base.x + gw * 0.35, base.y), Vector2(base.x + gw * 0.32, base.y - gh), col, 9.0)
	# Bottom lintel (nuki)
	draw_line(Vector2(base.x - gw * 0.48, base.y - gh * 0.75), Vector2(base.x + gw * 0.48, base.y - gh * 0.75), col, 6.0)
	# Top curved crossbeam (kasagi)
	var top_beam = PackedVector2Array([
		Vector2(base.x - gw * 0.62, base.y - gh - 8),
		Vector2(base.x, base.y - gh - 16),
		Vector2(base.x + gw * 0.62, base.y - gh - 8),
		Vector2(base.x + gw * 0.58, base.y - gh),
		Vector2(base.x, base.y - gh - 8),
		Vector2(base.x - gw * 0.58, base.y - gh)
	])
	draw_colored_polygon(top_beam, col)

func _draw_stone_lantern(pos: Vector2, col: Color) -> void:
	# Base pedestal
	draw_line(pos + Vector2(-16, 0), pos + Vector2(16, 0), col, 6.0)
	draw_line(pos + Vector2(-8, -6), pos + Vector2(8, -6), col, 10.0)
	# Post
	draw_line(pos + Vector2(0, -6), pos + Vector2(0, -42), col, 10.0)
	# Platform under light chamber
	draw_line(pos + Vector2(-18, -44), pos + Vector2(18, -44), col, 6.0)
	# Light chamber
	var chamber = PackedVector2Array([
		pos + Vector2(-12, -46),
		pos + Vector2(12, -46),
		pos + Vector2(10, -64),
		pos + Vector2(-10, -64)
	])
	draw_colored_polygon(chamber, col)
	
	# Lantern roof (kasa)
	var roof = PackedVector2Array([
		pos + Vector2(-22, -62),
		pos + Vector2(0, -74),
		pos + Vector2(22, -62),
		pos + Vector2(16, -65),
		pos + Vector2(0, -71),
		pos + Vector2(-16, -65)
	])
	draw_colored_polygon(roof, col)
	draw_circle(pos + Vector2(0, -76), 3.0, col)
	
	# Flickering fire glow inside chamber
	var flicker = 0.8 + sin(time * 8.0 + pos.x) * 0.15 + cos(time * 15.0) * 0.05
	var fire_center = pos + Vector2(0, -55)
	draw_circle(fire_center, 18.0 * flicker, Color(1.0, 0.55, 0.1, 0.22 * flicker))
	draw_circle(fire_center, 8.0 * flicker, Color(1.0, 0.85, 0.3, 0.65 * flicker))
	draw_circle(fire_center, 3.5 * flicker, Color(1.0, 1.0, 0.8, 0.95))

func _draw_bamboo_cluster(pos: Vector2, col: Color) -> void:
	for i in range(5):
		var x_off = (i - 2) * 12.0
		var h = 100.0 + (i % 3) * 30.0
		var sway = sin(time * 1.8 + i) * 3.0
		var p1 = pos + Vector2(x_off, 0)
		var p2 = pos + Vector2(x_off + sway, -h)
		draw_line(p1, p2, col, 4.0)
		# Bamboo leaves
		draw_line(p2, p2 + Vector2(-12, -8), col, 2.0)
		draw_line(p2, p2 + Vector2(10, -10), col, 2.0)

func _draw_pine_tree(pos: Vector2, col: Color) -> void:
	var trunk_top = pos + Vector2(sin(time * 0.8) * 2.0, -85.0)
	draw_line(pos, trunk_top, col, 6.0)
	# Tiered needle foliage clusters
	for tier in range(3):
		var y_tier = pos.y - 45 - tier * 20
		var sway = sin(time * 1.2 + tier) * 2.0
		draw_circle(Vector2(pos.x - 14 + sway, y_tier), 12.0, col)
		draw_circle(Vector2(pos.x + 16 + sway, y_tier - 4), 14.0, col)
		draw_circle(Vector2(pos.x + sway, y_tier - 10), 16.0, col)

func _draw_sakura_petal(pos: Vector2, sz: float, rot: float, col: Color) -> void:
	var pts = PackedVector2Array([
		pos + Vector2(0, -sz * 1.4).rotated(rot),
		pos + Vector2(sz * 0.7, 0).rotated(rot),
		pos + Vector2(0, sz * 1.4).rotated(rot),
		pos + Vector2(-sz * 0.7, 0).rotated(rot)
	])
	draw_colored_polygon(pts, col)
