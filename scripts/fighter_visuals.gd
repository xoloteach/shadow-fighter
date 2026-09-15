class_name FighterVisuals
extends Node2D

@export var is_player: bool = true

# Silhouette styling colors
const COLOR_BODY = Color(0.05, 0.05, 0.08, 1.0)
const COLOR_RIM = Color(0.20, 0.22, 0.32, 0.8)
const COLOR_GI_TRIM = Color(0.09, 0.09, 0.14, 1.0)

var eye_color: Color = Color(0.15, 0.95, 1.0, 1.0)
var accent_color: Color = Color(0.0, 0.8, 1.0, 0.9)
var trail_color: Color = Color(0.2, 0.9, 1.0, 0.5)

# Visual state variables
var current_pose: String = "idle"
var pose_time: float = 0.0
var walk_cycle: float = 0.0
var facing: float = 1.0 # 1.0 = right, -1.0 = left

# Flash on hit
var flash_timer: float = 0.0
var flash_color: Color = Color.WHITE

# Block barrier pulse
var block_pulse: float = 0.0

# Attack slash trail
var trail_points: Array[Vector2] = []
var trail_alpha: float = 0.0

# Verlet cloth ribbon (headband for player, sash for AI)
var ribbon_points: Array[Vector2] = []
var ribbon_prev_points: Array[Vector2] = []
const RIBBON_SEGMENTS = 7
const SEGMENT_LENGTH = 8.0

# Current calculated limb coordinates (relative to fighter origin)
var hip_pos: Vector2 = Vector2(0, -58)
var shoulder_pos: Vector2 = Vector2(0, -96)
var head_pos: Vector2 = Vector2(0, -114)

var arm_f_elbow: Vector2 = Vector2(14, -80)
var arm_f_fist: Vector2 = Vector2(26, -86)

var arm_b_elbow: Vector2 = Vector2(-12, -78)
var arm_b_fist: Vector2 = Vector2(-2, -88)

var leg_f_knee: Vector2 = Vector2(14, -30)
var leg_f_foot: Vector2 = Vector2(18, 0)

var leg_b_knee: Vector2 = Vector2(-14, -28)
var leg_b_foot: Vector2 = Vector2(-18, 0)

func _ready() -> void:
	setup_style(is_player)

func setup_style(player_flag: bool) -> void:
	is_player = player_flag
	if is_player:
		eye_color = Color(0.1, 0.95, 1.0, 1.0)
		accent_color = Color(0.0, 0.8, 1.0, 0.95)
		trail_color = Color(0.2, 0.9, 1.0, 0.6)
	else:
		eye_color = Color(1.0, 0.18, 0.28, 1.0)
		accent_color = Color(0.95, 0.15, 0.25, 0.95)
		trail_color = Color(1.0, 0.25, 0.35, 0.6)
	
	# Initialize ribbon physics points
	ribbon_points.clear()
	ribbon_prev_points.clear()
	var start_pt = head_pos + Vector2(-12 * facing, 0)
	if not is_player:
		start_pt = hip_pos + Vector2(-14 * facing, 0)
	
	for i in range(RIBBON_SEGMENTS):
		var pt = start_pt - Vector2(i * SEGMENT_LENGTH * facing, 0)
		ribbon_points.append(pt)
		ribbon_prev_points.append(pt)

func update_visuals(delta: float, fighter: CharacterBody2D) -> void:
	pose_time += delta
	walk_cycle += delta * 9.0
	
	if flash_timer > 0.0:
		flash_timer -= delta
	if block_pulse > 0.0:
		block_pulse -= delta * 3.0
	if trail_alpha > 0.0:
		trail_alpha -= delta * 3.5
	
	_solve_pose(fighter)
	_update_ribbon_physics(delta, fighter)
	queue_redraw()

func trigger_hit_flash(color: Color = Color.WHITE) -> void:
	flash_timer = 0.09
	flash_color = color

func trigger_block_flash() -> void:
	block_pulse = 1.0

func trigger_attack_trail() -> void:
	trail_alpha = 1.0
	trail_points.clear()
	var f = arm_f_fist
	var is_kick = current_pose.begins_with("kick") or current_pose == "crouch_kick" or current_pose == "jump_kick"
	if is_kick:
		f = leg_f_foot
	
	# Generate a smooth sweeping crescent arc (8 points)
	var radius = 42.0 if is_kick else 32.0
	var base_ang = -0.6 if facing > 0 else PI + 0.6
	var sweep_ang = 1.8 if facing > 0 else -1.8
	
	for i in range(8):
		var frac = float(i) / 7.0
		var a = base_ang + sweep_ang * frac
		var pt = f + Vector2(cos(a) * radius, sin(a) * (radius * 0.7))
		trail_points.append(pt)

func get_strike_point() -> Vector2:
	var is_kick = current_pose.begins_with("kick") or current_pose == "crouch_kick" or current_pose == "jump_kick"
	if is_kick:
		return leg_f_foot
	return arm_f_fist

func _solve_pose(fighter: CharacterBody2D) -> void:
	var state = fighter.current_state
	current_pose = state
	var t = pose_time
	var vel = fighter.velocity
	
	# Base default posture
	hip_pos = Vector2(0, -58)
	shoulder_pos = Vector2(0, -96)
	head_pos = Vector2(0, -114)
	
	match state:
		"idle":
			var breath = sin(t * 3.5) * 2.2
			hip_pos.y += breath * 0.5
			shoulder_pos.y += breath
			head_pos.y += breath
			
			# Athletic martial guard
			arm_f_elbow = shoulder_pos + Vector2(16 * facing, 14)
			arm_f_fist = arm_f_elbow + Vector2(14 * facing, -14)
			
			arm_b_elbow = shoulder_pos + Vector2(-12 * facing, 16)
			arm_b_fist = arm_b_elbow + Vector2(10 * facing, -16)
			
			# Grounded martial stance
			leg_f_knee = hip_pos + Vector2(14 * facing, 28)
			leg_f_foot = Vector2(18 * facing, 0)
			
			leg_b_knee = hip_pos + Vector2(-14 * facing, 28)
			leg_b_foot = Vector2(-22 * facing, 0)
		
		"walk_forward":
			var cycle = walk_cycle
			var stride = sin(cycle)
			var bob = abs(sin(cycle * 2.0)) * 3.0
			
			hip_pos.y += -bob
			shoulder_pos.y += -bob
			head_pos.y += -bob
			shoulder_pos.x += 6 * facing
			head_pos.x += 8 * facing
			
			leg_f_knee = hip_pos + Vector2(stride * 22 * facing, 26)
			leg_f_foot = Vector2(stride * 32 * facing, 0)
			
			leg_b_knee = hip_pos + Vector2(-stride * 22 * facing, 26)
			leg_b_foot = Vector2(-stride * 32 * facing, 0)
			
			arm_f_elbow = shoulder_pos + Vector2(14 * facing - stride * 6, 16)
			arm_f_fist = arm_f_elbow + Vector2(12 * facing, -10 + stride * 6)
			
			arm_b_elbow = shoulder_pos + Vector2(-12 * facing + stride * 6, 16)
			arm_b_fist = arm_b_elbow + Vector2(10 * facing, -14 - stride * 6)
		
		"walk_backward":
			var cycle = walk_cycle
			var stride = sin(cycle)
			var bob = abs(sin(cycle * 2.0)) * 2.5
			
			hip_pos.y += -bob
			shoulder_pos.y += -bob
			head_pos.y += -bob
			shoulder_pos.x -= 6 * facing
			head_pos.x -= 8 * facing
			
			leg_f_knee = hip_pos + Vector2(-stride * 16 * facing, 26)
			leg_f_foot = Vector2(-stride * 26 * facing, 0)
			
			leg_b_knee = hip_pos + Vector2(stride * 16 * facing, 26)
			leg_b_foot = Vector2(stride * 26 * facing, 0)
			
			arm_f_elbow = shoulder_pos + Vector2(12 * facing, 12)
			arm_f_fist = arm_f_elbow + Vector2(8 * facing, -18)
			
			arm_b_elbow = shoulder_pos + Vector2(-8 * facing, 14)
			arm_b_fist = arm_b_elbow + Vector2(6 * facing, -20)
		
		"crouch":
			hip_pos = Vector2(0, -36)
			shoulder_pos = Vector2(6 * facing, -66)
			head_pos = Vector2(10 * facing, -84)
			
			arm_f_elbow = shoulder_pos + Vector2(12 * facing, 12)
			arm_f_fist = arm_f_elbow + Vector2(10 * facing, -8)
			
			arm_b_elbow = shoulder_pos + Vector2(-10 * facing, 14)
			arm_b_fist = arm_b_elbow + Vector2(8 * facing, -10)
			
			leg_f_knee = Vector2(22 * facing, -18)
			leg_f_foot = Vector2(26 * facing, 0)
			
			leg_b_knee = Vector2(-20 * facing, -18)
			leg_b_foot = Vector2(-24 * facing, 0)
		
		"jump":
			var vy = vel.y
			if vy < 0:
				hip_pos = Vector2(0, -56)
				shoulder_pos = Vector2(2 * facing, -90)
				head_pos = Vector2(2 * facing, -108)
				
				leg_f_knee = hip_pos + Vector2(14 * facing, 18)
				leg_f_foot = hip_pos + Vector2(18 * facing, 36)
				leg_b_knee = hip_pos + Vector2(-12 * facing, 20)
				leg_b_foot = hip_pos + Vector2(-10 * facing, 38)
				
				arm_f_elbow = shoulder_pos + Vector2(16 * facing, -14)
				arm_f_fist = arm_f_elbow + Vector2(10 * facing, -18)
				arm_b_elbow = shoulder_pos + Vector2(-12 * facing, -12)
				arm_b_fist = arm_b_elbow + Vector2(-8 * facing, -16)
			else:
				hip_pos = Vector2(0, -58)
				shoulder_pos = Vector2(0, -94)
				head_pos = Vector2(0, -112)
				
				leg_f_knee = hip_pos + Vector2(12 * facing, 28)
				leg_f_foot = hip_pos + Vector2(16 * facing, 56)
				leg_b_knee = hip_pos + Vector2(-12 * facing, 28)
				leg_b_foot = hip_pos + Vector2(-16 * facing, 56)
				
				arm_f_elbow = shoulder_pos + Vector2(18 * facing, 14)
				arm_f_fist = arm_f_elbow + Vector2(14 * facing, 6)
				arm_b_elbow = shoulder_pos + Vector2(-14 * facing, 16)
				arm_b_fist = arm_b_elbow + Vector2(-12 * facing, 8)
		
		"block":
			hip_pos = Vector2(-6 * facing, -54)
			shoulder_pos = Vector2(-8 * facing, -92)
			head_pos = Vector2(-10 * facing, -110)
			
			arm_f_elbow = shoulder_pos + Vector2(18 * facing, 8)
			arm_f_fist = shoulder_pos + Vector2(10 * facing, -16)
			
			arm_b_elbow = shoulder_pos + Vector2(14 * facing, 14)
			arm_b_fist = shoulder_pos + Vector2(12 * facing, -14)
			
			leg_f_knee = hip_pos + Vector2(18 * facing, 28)
			leg_f_foot = Vector2(28 * facing, 0)
			leg_b_knee = hip_pos + Vector2(-20 * facing, 28)
			leg_b_foot = Vector2(-32 * facing, 0)
		
		"punch_1":
			var progress = fighter.get_attack_progress()
			var reach = sin(progress * PI)
			
			shoulder_pos.x += 12 * reach * facing
			head_pos.x += 10 * reach * facing
			
			arm_f_elbow = shoulder_pos + Vector2(26 * reach * facing, 2)
			arm_f_fist = shoulder_pos + Vector2((24 + 40 * reach) * facing, -4)
			
			arm_b_elbow = shoulder_pos + Vector2(-14 * facing, 16)
			arm_b_fist = shoulder_pos + Vector2(-2 * facing, -8)
			
			leg_f_knee = hip_pos + Vector2(16 * facing, 28)
			leg_f_foot = Vector2(22 * facing, 0)
			leg_b_knee = hip_pos + Vector2(-14 * facing, 28)
			leg_b_foot = Vector2(-20 * facing, 0)
		
		"punch_2":
			var progress = fighter.get_attack_progress()
			var reach = sin(progress * PI)
			
			hip_pos.x += 10 * reach * facing
			shoulder_pos.x += 18 * reach * facing
			head_pos.x += 14 * reach * facing
			
			arm_b_elbow = shoulder_pos + Vector2(30 * reach * facing, 4)
			arm_b_fist = shoulder_pos + Vector2((26 + 46 * reach) * facing, 0)
			
			arm_f_elbow = shoulder_pos + Vector2(8 * facing, 14)
			arm_f_fist = shoulder_pos + Vector2(4 * facing, -10)
			
			leg_f_knee = hip_pos + Vector2(20 * facing, 30)
			leg_f_foot = Vector2(28 * facing, 0)
			leg_b_knee = hip_pos + Vector2(-10 * facing, 28)
			leg_b_foot = Vector2(-16 * facing, 0)
		
		"punch_3":
			var progress = fighter.get_attack_progress()
			var reach = sin(progress * PI)
			
			hip_pos.x += 16 * reach * facing
			shoulder_pos.x += 24 * reach * facing
			head_pos.x += 18 * reach * facing
			
			arm_f_elbow = shoulder_pos + Vector2(30 * reach * facing, -12 * reach)
			arm_f_fist = shoulder_pos + Vector2((30 + 52 * reach) * facing, -16 * reach)
			
			arm_b_elbow = shoulder_pos + Vector2(-10 * facing, 18)
			arm_b_fist = shoulder_pos + Vector2(-4 * facing, -4)
			
			leg_f_knee = hip_pos + Vector2(22 * facing, 30)
			leg_f_foot = Vector2(32 * facing, 0)
			leg_b_knee = hip_pos + Vector2(-12 * facing, 28)
			leg_b_foot = Vector2(-18 * facing, 0)
		
		"crouch_punch":
			var progress = fighter.get_attack_progress()
			var reach = sin(progress * PI)
			
			hip_pos = Vector2(4 * reach * facing, -36)
			shoulder_pos = Vector2(12 * reach * facing, -64)
			head_pos = Vector2(14 * reach * facing, -82)
			
			arm_f_elbow = shoulder_pos + Vector2(24 * reach * facing, 6)
			arm_f_fist = shoulder_pos + Vector2((20 + 42 * reach) * facing, 8)
			
			arm_b_elbow = shoulder_pos + Vector2(-10 * facing, 12)
			arm_b_fist = shoulder_pos + Vector2(4 * facing, -10)
			
			leg_f_knee = Vector2(22 * facing, -18)
			leg_f_foot = Vector2(26 * facing, 0)
			leg_b_knee = Vector2(-20 * facing, -18)
			leg_b_foot = Vector2(-24 * facing, 0)
		
		"jump_punch":
			var progress = fighter.get_attack_progress()
			var reach = sin(progress * PI)
			
			hip_pos = Vector2(4 * reach * facing, -56)
			shoulder_pos = Vector2(10 * reach * facing, -90)
			head_pos = Vector2(10 * reach * facing, -108)
			
			arm_f_elbow = shoulder_pos + Vector2(22 * reach * facing, 14)
			arm_f_fist = shoulder_pos + Vector2((24 + 36 * reach) * facing, 30 * reach)
			
			arm_b_elbow = shoulder_pos + Vector2(-12 * facing, -10)
			arm_b_fist = shoulder_pos + Vector2(-8 * facing, -14)
			
			leg_f_knee = hip_pos + Vector2(10 * facing, 26)
			leg_f_foot = hip_pos + Vector2(14 * facing, 50)
			leg_b_knee = hip_pos + Vector2(-14 * facing, 22)
			leg_b_foot = hip_pos + Vector2(-18 * facing, 46)
		
		"kick_1":
			var progress = fighter.get_attack_progress()
			var reach = sin(progress * PI)
			
			hip_pos.x -= 8 * reach * facing
			shoulder_pos.x -= 16 * reach * facing
			head_pos.x -= 18 * reach * facing
			
			leg_f_knee = hip_pos + Vector2(26 * reach * facing, -12 * reach)
			leg_f_foot = hip_pos + Vector2((28 + 56 * reach) * facing, -16 * reach)
			
			leg_b_knee = hip_pos + Vector2(-10 * facing, 32)
			leg_b_foot = Vector2(-16 * facing, 0)
			
			arm_f_elbow = shoulder_pos + Vector2(12 * facing, 14)
			arm_f_fist = arm_f_elbow + Vector2(8 * facing, -12)
			arm_b_elbow = shoulder_pos + Vector2(-14 * facing, 16)
			arm_b_fist = arm_b_elbow + Vector2(10 * facing, -14)
		
		"kick_2":
			var progress = fighter.get_attack_progress()
			var reach = sin(progress * PI)
			
			hip_pos.x += 8 * reach * facing
			shoulder_pos.x -= 12 * reach * facing
			head_pos.x -= 14 * reach * facing
			
			leg_f_knee = hip_pos + Vector2(30 * reach * facing, -24 * reach)
			leg_f_foot = hip_pos + Vector2((34 + 62 * reach) * facing, -32 * reach)
			
			leg_b_knee = hip_pos + Vector2(-8 * facing, 32)
			leg_b_foot = Vector2(-14 * facing, 0)
			
			arm_f_elbow = shoulder_pos + Vector2(16 * facing, 12)
			arm_f_fist = arm_f_elbow + Vector2(10 * facing, -10)
			arm_b_elbow = shoulder_pos + Vector2(-18 * facing, 18)
			arm_b_fist = arm_b_elbow + Vector2(-8 * facing, 6)
		
		"crouch_kick":
			var progress = fighter.get_attack_progress()
			var reach = sin(progress * PI)
			
			hip_pos = Vector2(10 * reach * facing, -28)
			shoulder_pos = Vector2(2 * facing, -56)
			head_pos = Vector2(-4 * facing, -72)
			
			leg_f_knee = Vector2(26 * reach * facing, -10)
			leg_f_foot = Vector2((32 + 58 * reach) * facing, -2)
			
			leg_b_knee = Vector2(-18 * facing, -12)
			leg_b_foot = Vector2(-26 * facing, 0)
			
			arm_f_elbow = shoulder_pos + Vector2(-10 * facing, 24)
			arm_f_fist = shoulder_pos + Vector2(-14 * facing, 44)
			arm_b_elbow = shoulder_pos + Vector2(14 * facing, 16)
			arm_b_fist = shoulder_pos + Vector2(18 * facing, 4)
		
		"jump_kick":
			var progress = fighter.get_attack_progress()
			var reach = clampf(sin(progress * PI) * 1.3, 0.0, 1.0)
			
			hip_pos = Vector2(8 * reach * facing, -54)
			shoulder_pos = Vector2(-12 * reach * facing, -82)
			head_pos = Vector2(-14 * reach * facing, -96)
			
			leg_f_knee = hip_pos + Vector2(32 * reach * facing, 4)
			leg_f_foot = hip_pos + Vector2((36 + 54 * reach) * facing, 12)
			
			leg_b_knee = hip_pos + Vector2(-16 * facing, 12)
			leg_b_foot = hip_pos + Vector2(-22 * facing, 26)
			
			arm_f_elbow = shoulder_pos + Vector2(20 * facing, 6)
			arm_f_fist = arm_f_elbow + Vector2(14 * facing, -4)
			arm_b_elbow = shoulder_pos + Vector2(-18 * facing, 10)
			arm_b_fist = arm_b_elbow + Vector2(-10 * facing, 4)
		
		"hit_stun":
			var intensity = clampf(t * 5.0, 0.0, 1.0)
			var recoil = (1.0 - intensity) * 18.0
			
			hip_pos.x -= recoil * 0.5 * facing
			shoulder_pos.x -= recoil * 1.3 * facing
			head_pos.x -= recoil * 1.7 * facing
			head_pos.y -= 4
			
			arm_f_elbow = shoulder_pos + Vector2(-4 * facing, 18)
			arm_f_fist = shoulder_pos + Vector2(-8 * facing, 36)
			arm_b_elbow = shoulder_pos + Vector2(-20 * facing, 16)
			arm_b_fist = shoulder_pos + Vector2(-26 * facing, 30)
			
			leg_f_knee = hip_pos + Vector2(12 * facing, 30)
			leg_f_foot = Vector2(16 * facing, 0)
			leg_b_knee = hip_pos + Vector2(-18 * facing, 28)
			leg_b_foot = Vector2(-26 * facing, 0)
		
		"knockdown":
			var fall_progress = clampf(t * 3.5, 0.0, 1.0)
			hip_pos = Vector2(-22 * fall_progress * facing, lerpf(-58.0, -12.0, fall_progress))
			shoulder_pos = Vector2(-48 * fall_progress * facing, lerpf(-96.0, -16.0, fall_progress))
			head_pos = Vector2(-65 * fall_progress * facing, lerpf(-114.0, -16.0, fall_progress))
			
			leg_f_knee = Vector2(-8 * facing, -12)
			leg_f_foot = Vector2(14 * facing, -4)
			leg_b_knee = Vector2(-30 * facing, -10)
			leg_b_foot = Vector2(-20 * facing, -2)
			
			arm_f_elbow = shoulder_pos + Vector2(14 * facing, 6)
			arm_f_fist = shoulder_pos + Vector2(26 * facing, 10)
			arm_b_elbow = shoulder_pos + Vector2(-8 * facing, 8)
			arm_b_fist = shoulder_pos + Vector2(-18 * facing, 12)
		
		"dead":
			hip_pos = Vector2(-28 * facing, -12)
			shoulder_pos = Vector2(-58 * facing, -15)
			head_pos = Vector2(-76 * facing, -14)
			
			leg_f_knee = Vector2(-14 * facing, -10)
			leg_f_foot = Vector2(10 * facing, -4)
			leg_b_knee = Vector2(-34 * facing, -8)
			leg_b_foot = Vector2(-24 * facing, -2)
			
			arm_f_elbow = shoulder_pos + Vector2(14 * facing, 6)
			arm_f_fist = shoulder_pos + Vector2(28 * facing, 8)
			arm_b_elbow = shoulder_pos + Vector2(-6 * facing, 6)
			arm_b_fist = shoulder_pos + Vector2(-18 * facing, 10)
		
		"victory":
			hip_pos = Vector2(0, -60)
			shoulder_pos = Vector2(0, -98)
			head_pos = Vector2(0, -116)
			
			arm_f_elbow = shoulder_pos + Vector2(16 * facing, 12)
			arm_f_fist = shoulder_pos + Vector2(6 * facing, -6)
			
			arm_b_elbow = shoulder_pos + Vector2(-12 * facing, 12)
			arm_b_fist = shoulder_pos + Vector2(4 * facing, -6)
			
			leg_f_knee = hip_pos + Vector2(12 * facing, 30)
			leg_f_foot = Vector2(16 * facing, 0)
			leg_b_knee = hip_pos + Vector2(-12 * facing, 30)
			leg_b_foot = Vector2(-16 * facing, 0)

func _update_ribbon_physics(delta: float, fighter: CharacterBody2D) -> void:
	if ribbon_points.is_empty():
		return
	
	var anchor: Vector2
	if is_player:
		anchor = head_pos + Vector2(-12 * facing, 2)
	else:
		anchor = hip_pos + Vector2(-14 * facing, 0)
	
	ribbon_points[0] = anchor
	
	var gravity = Vector2(-facing * 100.0, 110.0)
	gravity -= fighter.velocity * 0.35
	
	for i in range(1, RIBBON_SEGMENTS):
		var cur = ribbon_points[i]
		var prev = ribbon_prev_points[i]
		var vel = (cur - prev) * 0.86
		
		ribbon_prev_points[i] = cur
		ribbon_points[i] = cur + vel + gravity * (delta * delta)
	
	for iter in range(3):
		ribbon_points[0] = anchor
		for i in range(RIBBON_SEGMENTS - 1):
			var p1 = ribbon_points[i]
			var p2 = ribbon_points[i + 1]
			var delta_vec = p2 - p1
			var dist = delta_vec.length()
			if dist > 0.001:
				var diff = (dist - SEGMENT_LENGTH) / dist
				if i == 0:
					ribbon_points[i + 1] -= delta_vec * diff
				else:
					ribbon_points[i] += delta_vec * (diff * 0.5)
					ribbon_points[i + 1] -= delta_vec * (diff * 0.5)

func _draw() -> void:
	var cur_body_color = COLOR_BODY
	if flash_timer > 0.0:
		cur_body_color = flash_color
	
	# Ground contact shadow
	var shadow_col = Color(0.02, 0.02, 0.04, 0.5)
	draw_circle(Vector2(0, 0), 28.0, shadow_col)
	
	# 1. Back Arm
	_draw_muscled_arm(shoulder_pos + Vector2(-4 * facing, 0), arm_b_elbow, arm_b_fist, cur_body_color, false)
	
	# 2. Back Leg (Martial Arts Hakama Pants)
	_draw_hakama_leg(hip_pos + Vector2(-8 * facing, 0), leg_b_knee, leg_b_foot, cur_body_color)
	
	# 3. Torso (Tapered Gi with Belt)
	_draw_torso(cur_body_color)
	
	# 4. Ribbon Tails (Headband for Player, Sash for Oni)
	_draw_ribbon()
	
	# 5. Head & Eyes & Mask
	_draw_head(cur_body_color)
	
	# 6. Front Leg
	_draw_hakama_leg(hip_pos + Vector2(8 * facing, 0), leg_f_knee, leg_f_foot, cur_body_color)
	
	# 7. Front Arm
	_draw_muscled_arm(shoulder_pos + Vector2(4 * facing, 0), arm_f_elbow, arm_f_fist, cur_body_color, true)
	
	# 8. Attack Trail
	if trail_alpha > 0.01 and trail_points.size() >= 3:
		var c = trail_color
		c.a *= trail_alpha
		draw_polyline(trail_points, c, 12.0, true)
		var c_core = Color(1.0, 1.0, 1.0, 0.9 * trail_alpha)
		draw_polyline(trail_points, c_core, 4.0, true)
	
	# 9. Block Barrier Pulse
	if block_pulse > 0.01:
		var bp_color = Color(0.2, 0.85, 1.0, block_pulse * 0.65)
		var center = (shoulder_pos + arm_f_fist) * 0.5 + Vector2(12 * facing, 0)
		draw_arc(center, 32.0, -PI * 0.45, PI * 0.45, 20, bp_color, 5.0, true)
		draw_arc(center, 40.0, -PI * 0.35, PI * 0.35, 16, Color(1, 1, 1, block_pulse * 0.85), 2.5, true)

func _draw_muscled_arm(p_start: Vector2, p_mid: Vector2, p_end: Vector2, col: Color, is_front: bool) -> void:
	var w1 = 9.0 if is_front else 8.0
	var w2 = 7.5 if is_front else 6.5
	# Bicep
	draw_line(p_start, p_mid, col, w1, true)
	draw_circle(p_start, w1 * 0.55, col)
	draw_circle(p_mid, w1 * 0.5, col)
	# Forearm with wrist-wrap taper
	draw_line(p_mid, p_end, col, w2, true)
	# Clenched fist
	draw_circle(p_end, w2 * 0.8, col)
	
	if flash_timer <= 0.0:
		draw_line(p_start + Vector2(-1.5 * facing, 0), p_mid + Vector2(-1.5 * facing, 0), COLOR_RIM, 1.8, true)

func _draw_hakama_leg(p_start: Vector2, p_mid: Vector2, p_end: Vector2, col: Color) -> void:
	# Wide flowing martial arts pants polygon for thigh
	var thigh_pts = PackedVector2Array([
		p_start + Vector2(-10 * facing, 0),
		p_start + Vector2(10 * facing, 0),
		p_mid + Vector2(8 * facing, 0),
		p_mid + Vector2(-8 * facing, 0)
	])
	draw_colored_polygon(thigh_pts, col)
	
	# Calf segment
	draw_line(p_mid, p_end, col, 9.0, true)
	draw_circle(p_mid, 5.0, col)
	
	# Martial arts shoe / tabi
	var foot_front = p_end + Vector2(14 * facing, 1)
	var foot_back = p_end + Vector2(-6 * facing, 1)
	draw_line(foot_back, foot_front, col, 7.0, true)
	
	if flash_timer <= 0.0:
		draw_line(p_start + Vector2(-2 * facing, 0), p_mid + Vector2(-2 * facing, 0), COLOR_RIM, 1.8, true)

func _draw_torso(col: Color) -> void:
	# Powerful athletic torso polygon
	var pts = PackedVector2Array([
		shoulder_pos + Vector2(-16 * facing, 2),
		shoulder_pos + Vector2(16 * facing, 2),
		hip_pos + Vector2(11 * facing, -2),
		hip_pos + Vector2(-11 * facing, -2)
	])
	draw_colored_polygon(pts, col)
	
	# Martial arts gi collar / trim
	draw_line(shoulder_pos + Vector2(-10 * facing, 2), hip_pos + Vector2(3 * facing, -6), COLOR_GI_TRIM, 3.5, true)
	draw_line(shoulder_pos + Vector2(10 * facing, 2), hip_pos + Vector2(-3 * facing, -6), COLOR_GI_TRIM, 3.5, true)
	
	# Obi / Martial belt sash
	var belt_y = hip_pos.y - 6
	draw_line(Vector2(-13 * facing, belt_y), Vector2(13 * facing, belt_y), accent_color, 5.0, true)
	draw_circle(Vector2(2 * facing, belt_y), 4.5, accent_color)

func _draw_head(col: Color) -> void:
	# Neck
	draw_line(shoulder_pos + Vector2(0, -2), head_pos, col, 9.0, true)
	
	# Head oval
	draw_circle(head_pos, 12.5, col)
	
	if is_player:
		# Ninja headband
		draw_line(head_pos + Vector2(-13 * facing, -1), head_pos + Vector2(13 * facing, -1), accent_color, 4.0, true)
		# Glowing cyan eye slit
		var eye_center = head_pos + Vector2(6 * facing, 0)
		draw_line(eye_center - Vector2(4 * facing, 0), eye_center + Vector2(4 * facing, 0), eye_color, 3.0, true)
		draw_circle(eye_center + Vector2(1 * facing, 0), 1.8, Color.WHITE)
	else:
		# Oni Horned Mask / Kabuto
		var horn_l_base = head_pos + Vector2(-7 * facing, -11)
		var horn_l_tip = head_pos + Vector2(-14 * facing, -26)
		var horn_r_base = head_pos + Vector2(5 * facing, -11)
		var horn_r_tip = head_pos + Vector2(14 * facing, -25)
		
		draw_line(horn_l_base, horn_l_tip, col, 5.0, true)
		draw_line(horn_r_base, horn_r_tip, col, 5.0, true)
		draw_line(horn_l_base + Vector2(2 * facing, 0), horn_l_tip, accent_color, 2.0, true)
		draw_line(horn_r_base - Vector2(2 * facing, 0), horn_r_tip, accent_color, 2.0, true)
		
		# Glowing ruby eye slit
		var eye_center = head_pos + Vector2(6 * facing, 1)
		draw_line(eye_center - Vector2(5 * facing, -1), eye_center + Vector2(5 * facing, 1), eye_color, 3.0, true)
		draw_circle(eye_center, 2.0, Color(1, 0.9, 0.9))

func _draw_ribbon() -> void:
	if ribbon_points.size() < 2:
		return
	
	var r_color = accent_color
	draw_polyline(ribbon_points, r_color, 3.5, true)
	
	var secondary_pts: Array[Vector2] = []
	for i in range(ribbon_points.size()):
		secondary_pts.append(ribbon_points[i] + Vector2(0, 3 + i * 0.7))
	draw_polyline(secondary_pts, r_color * 0.85, 2.5, true)
