class_name FighterVisuals
extends Node2D

@export var is_player: bool = true

# Silhouette styling colors
const COLOR_BODY = Color(0.06, 0.06, 0.09, 1.0)
const COLOR_RIM = Color(0.16, 0.17, 0.24, 0.8)
const COLOR_JOINT = Color(0.04, 0.04, 0.07, 1.0)

var eye_color: Color
var accent_color: Color
var trail_color: Color

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
const RIBBON_SEGMENTS = 6
const SEGMENT_LENGTH = 7.0

# Current calculated limb coordinates (relative to fighter origin)
var hip_pos: Vector2 = Vector2(0, -58)
var shoulder_pos: Vector2 = Vector2(0, -92)
var head_pos: Vector2 = Vector2(0, -108)

var arm_f_elbow: Vector2 = Vector2(10, -78)
var arm_f_fist: Vector2 = Vector2(22, -84)

var arm_b_elbow: Vector2 = Vector2(-12, -76)
var arm_b_fist: Vector2 = Vector2(-4, -86)

var leg_f_knee: Vector2 = Vector2(10, -32)
var leg_f_foot: Vector2 = Vector2(14, 0)

var leg_b_knee: Vector2 = Vector2(-14, -30)
var leg_b_foot: Vector2 = Vector2(-16, 0)

func _ready() -> void:
	if is_player:
		eye_color = Color(0.15, 0.95, 1.0, 1.0)
		accent_color = Color(0.0, 0.8, 1.0, 0.9)
		trail_color = Color(0.2, 0.9, 1.0, 0.5)
	else:
		eye_color = Color(1.0, 0.2, 0.3, 1.0)
		accent_color = Color(0.9, 0.15, 0.2, 0.9)
		trail_color = Color(1.0, 0.25, 0.3, 0.5)
	
	# Initialize ribbon physics points
	ribbon_points.clear()
	ribbon_prev_points.clear()
	var start_pt = head_pos + Vector2(-10, 0)
	for i in range(RIBBON_SEGMENTS):
		var pt = start_pt - Vector2(i * SEGMENT_LENGTH, 0)
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
		trail_alpha -= delta * 4.0
	
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
	# Store trail arc based on active attack
	var f = arm_f_fist
	if current_pose.begins_with("kick") or current_pose == "crouch_kick" or current_pose == "jump_kick":
		f = leg_f_foot
	
	trail_points.append(f + Vector2(-25 * facing, -15))
	trail_points.append(f + Vector2(-10 * facing, -20))
	trail_points.append(f + Vector2(10 * facing, 0))
	trail_points.append(f + Vector2(-5 * facing, 15))

func get_strike_point() -> Vector2:
	if current_pose.begins_with("kick") or current_pose == "crouch_kick" or current_pose == "jump_kick":
		return leg_f_foot
	return arm_f_fist

func _solve_pose(fighter: CharacterBody2D) -> void:
	var state = fighter.current_state
	current_pose = state
	var t = pose_time
	var vel = fighter.velocity
	
	# Base default martial arts stance
	hip_pos = Vector2(0, -58)
	shoulder_pos = Vector2(0, -92)
	head_pos = Vector2(0, -108)
	
	match state:
		"idle":
			var breath = sin(t * 3.5) * 2.0
			hip_pos.y += breath * 0.5
			shoulder_pos.y += breath
			head_pos.y += breath
			
			# Lead guard (front arm)
			arm_f_elbow = shoulder_pos + Vector2(14 * facing, 14)
			arm_f_fist = arm_f_elbow + Vector2(12 * facing, -12)
			
			# Rear guard (back arm protecting chin)
			arm_b_elbow = shoulder_pos + Vector2(-10 * facing, 18)
			arm_b_fist = arm_b_elbow + Vector2(8 * facing, -16)
			
			# Braced martial stance legs
			leg_f_knee = hip_pos + Vector2(12 * facing, 26)
			leg_f_foot = Vector2(16 * facing, 0)
			
			leg_b_knee = hip_pos + Vector2(-12 * facing, 26)
			leg_b_foot = Vector2(-18 * facing, 0)
		
		"walk_forward":
			var cycle = walk_cycle
			var stride = sin(cycle)
			var bob = abs(sin(cycle * 2.0)) * 3.0
			
			hip_pos.y += -bob
			shoulder_pos.y += -bob
			head_pos.y += -bob
			# Slight forward lean
			shoulder_pos.x += 4 * facing
			head_pos.x += 6 * facing
			
			# Moving legs
			leg_f_knee = hip_pos + Vector2(stride * 18 * facing, 24)
			leg_f_foot = Vector2(stride * 26 * facing, 0)
			
			leg_b_knee = hip_pos + Vector2(-stride * 18 * facing, 24)
			leg_b_foot = Vector2(-stride * 26 * facing, 0)
			
			# Pumping guard
			arm_f_elbow = shoulder_pos + Vector2(12 * facing - stride * 4, 16)
			arm_f_fist = arm_f_elbow + Vector2(10 * facing, -10 + stride * 4)
			
			arm_b_elbow = shoulder_pos + Vector2(-10 * facing + stride * 4, 16)
			arm_b_fist = arm_b_elbow + Vector2(8 * facing, -14 - stride * 4)
		
		"walk_backward":
			var cycle = walk_cycle
			var stride = sin(cycle)
			var bob = abs(sin(cycle * 2.0)) * 2.5
			
			hip_pos.y += -bob
			shoulder_pos.y += -bob
			head_pos.y += -bob
			# Defensive lean backward
			shoulder_pos.x -= 4 * facing
			head_pos.x -= 5 * facing
			
			# Shuffling legs
			leg_f_knee = hip_pos + Vector2(-stride * 14 * facing, 24)
			leg_f_foot = Vector2(-stride * 22 * facing, 0)
			
			leg_b_knee = hip_pos + Vector2(stride * 14 * facing, 24)
			leg_b_foot = Vector2(stride * 22 * facing, 0)
			
			# Higher, closer defensive guard
			arm_f_elbow = shoulder_pos + Vector2(10 * facing, 12)
			arm_f_fist = arm_f_elbow + Vector2(6 * facing, -16)
			
			arm_b_elbow = shoulder_pos + Vector2(-6 * facing, 14)
			arm_b_fist = arm_b_elbow + Vector2(4 * facing, -18)
		
		"crouch":
			hip_pos = Vector2(0, -36)
			shoulder_pos = Vector2(4 * facing, -64)
			head_pos = Vector2(8 * facing, -80)
			
			# Crouched guard
			arm_f_elbow = shoulder_pos + Vector2(10 * facing, 10)
			arm_f_fist = arm_f_elbow + Vector2(8 * facing, -8)
			
			arm_b_elbow = shoulder_pos + Vector2(-8 * facing, 12)
			arm_b_fist = arm_b_elbow + Vector2(6 * facing, -10)
			
			# Deep bent knees
			leg_f_knee = Vector2(18 * facing, -18)
			leg_f_foot = Vector2(22 * facing, 0)
			
			leg_b_knee = Vector2(-16 * facing, -18)
			leg_b_foot = Vector2(-20 * facing, 0)
		
		"jump":
			var vy = vel.y
			if vy < 0: # Ascending
				hip_pos = Vector2(0, -56)
				shoulder_pos = Vector2(2 * facing, -88)
				head_pos = Vector2(2 * facing, -104)
				
				# Tucked knees for dynamic jump
				leg_f_knee = hip_pos + Vector2(12 * facing, 16)
				leg_f_foot = hip_pos + Vector2(16 * facing, 32)
				
				leg_b_knee = hip_pos + Vector2(-10 * facing, 18)
				leg_b_foot = hip_pos + Vector2(-8 * facing, 34)
				
				# Arms raised for momentum
				arm_f_elbow = shoulder_pos + Vector2(14 * facing, -12)
				arm_f_fist = arm_f_elbow + Vector2(8 * facing, -16)
				arm_b_elbow = shoulder_pos + Vector2(-10 * facing, -10)
				arm_b_fist = arm_b_elbow + Vector2(-6 * facing, -14)
			else: # Falling
				hip_pos = Vector2(0, -58)
				shoulder_pos = Vector2(0, -90)
				head_pos = Vector2(0, -106)
				
				# Legs preparing for impact
				leg_f_knee = hip_pos + Vector2(10 * facing, 26)
				leg_f_foot = hip_pos + Vector2(14 * facing, 52)
				
				leg_b_knee = hip_pos + Vector2(-10 * facing, 26)
				leg_b_foot = hip_pos + Vector2(-14 * facing, 52)
				
				arm_f_elbow = shoulder_pos + Vector2(16 * facing, 12)
				arm_f_fist = arm_f_elbow + Vector2(12 * facing, 4)
				arm_b_elbow = shoulder_pos + Vector2(-12 * facing, 14)
				arm_b_fist = arm_b_elbow + Vector2(-10 * facing, 6)
		
		"block":
			# Solid braced defensive pose
			hip_pos = Vector2(-4 * facing, -54)
			shoulder_pos = Vector2(-6 * facing, -88)
			head_pos = Vector2(-8 * facing, -104)
			
			# Crossed arms high guard
			arm_f_elbow = shoulder_pos + Vector2(16 * facing, 8)
			arm_f_fist = shoulder_pos + Vector2(8 * facing, -14)
			
			arm_b_elbow = shoulder_pos + Vector2(12 * facing, 12)
			arm_b_fist = shoulder_pos + Vector2(10 * facing, -12)
			
			# Braced wide stance
			leg_f_knee = hip_pos + Vector2(16 * facing, 26)
			leg_f_foot = Vector2(24 * facing, 0)
			
			leg_b_knee = hip_pos + Vector2(-18 * facing, 26)
			leg_b_foot = Vector2(-28 * facing, 0)
		
		"punch_1": # Lead Jab
			var progress = fighter.get_attack_progress()
			var reach = sin(progress * PI)
			
			shoulder_pos.x += 10 * reach * facing
			head_pos.x += 8 * reach * facing
			
			# Lead fist snaps forward straight
			arm_f_elbow = shoulder_pos + Vector2(24 * reach * facing, 2)
			arm_f_fist = shoulder_pos + Vector2((22 + 34 * reach) * facing, -2)
			
			# Rear fist guards chin
			arm_b_elbow = shoulder_pos + Vector2(-12 * facing, 16)
			arm_b_fist = shoulder_pos + Vector2(-2 * facing, -8)
			
			leg_f_knee = hip_pos + Vector2(14 * facing, 26)
			leg_f_foot = Vector2(18 * facing, 0)
			leg_b_knee = hip_pos + Vector2(-12 * facing, 26)
			leg_b_foot = Vector2(-18 * facing, 0)
		
		"punch_2": # Straight Cross
			var progress = fighter.get_attack_progress()
			var reach = sin(progress * PI)
			
			hip_pos.x += 8 * reach * facing
			shoulder_pos.x += 16 * reach * facing
			head_pos.x += 12 * reach * facing
			
			# Rear fist drives through with torso rotation
			arm_b_elbow = shoulder_pos + Vector2(28 * reach * facing, 4)
			arm_b_fist = shoulder_pos + Vector2((24 + 40 * reach) * facing, 0)
			
			# Lead arm recoils slightly
			arm_f_elbow = shoulder_pos + Vector2(8 * facing, 14)
			arm_f_fist = shoulder_pos + Vector2(4 * facing, -10)
			
			# Back leg drives into the floor
			leg_f_knee = hip_pos + Vector2(18 * facing, 28)
			leg_f_foot = Vector2(24 * facing, 0)
			leg_b_knee = hip_pos + Vector2(-8 * facing, 26)
			leg_b_foot = Vector2(-14 * facing, 0)
		
		"punch_3": # Spinning Backfist Combo Finisher
			var progress = fighter.get_attack_progress()
			var reach = sin(progress * PI)
			
			hip_pos.x += 14 * reach * facing
			shoulder_pos.x += 20 * reach * facing
			head_pos.x += 16 * reach * facing
			
			# High arcing backfist strike
			arm_f_elbow = shoulder_pos + Vector2(26 * reach * facing, -10 * reach)
			arm_f_fist = shoulder_pos + Vector2((26 + 46 * reach) * facing, -14 * reach)
			
			arm_b_elbow = shoulder_pos + Vector2(-8 * facing, 18)
			arm_b_fist = shoulder_pos + Vector2(-2 * facing, -4)
			
			leg_f_knee = hip_pos + Vector2(20 * facing, 28)
			leg_f_foot = Vector2(28 * facing, 0)
			leg_b_knee = hip_pos + Vector2(-10 * facing, 26)
			leg_b_foot = Vector2(-16 * facing, 0)
		
		"crouch_punch": # Low Gut Jab
			var progress = fighter.get_attack_progress()
			var reach = sin(progress * PI)
			
			hip_pos = Vector2(4 * reach * facing, -36)
			shoulder_pos = Vector2(10 * reach * facing, -62)
			head_pos = Vector2(12 * reach * facing, -78)
			
			# Low straight punch
			arm_f_elbow = shoulder_pos + Vector2(22 * reach * facing, 6)
			arm_f_fist = shoulder_pos + Vector2((18 + 36 * reach) * facing, 8)
			
			arm_b_elbow = shoulder_pos + Vector2(-8 * facing, 10)
			arm_b_fist = shoulder_pos + Vector2(4 * facing, -10)
			
			leg_f_knee = Vector2(18 * facing, -18)
			leg_f_foot = Vector2(22 * facing, 0)
			leg_b_knee = Vector2(-16 * facing, -18)
			leg_b_foot = Vector2(-20 * facing, 0)
		
		"jump_punch": # Aerial Downward Strike
			var progress = fighter.get_attack_progress()
			var reach = sin(progress * PI)
			
			hip_pos = Vector2(4 * reach * facing, -56)
			shoulder_pos = Vector2(8 * reach * facing, -88)
			head_pos = Vector2(8 * reach * facing, -104)
			
			arm_f_elbow = shoulder_pos + Vector2(20 * reach * facing, 14)
			arm_f_fist = shoulder_pos + Vector2((22 + 32 * reach) * facing, 28 * reach)
			
			arm_b_elbow = shoulder_pos + Vector2(-10 * facing, -10)
			arm_b_fist = shoulder_pos + Vector2(-6 * facing, -14)
			
			leg_f_knee = hip_pos + Vector2(8 * facing, 24)
			leg_f_foot = hip_pos + Vector2(12 * facing, 46)
			leg_b_knee = hip_pos + Vector2(-12 * facing, 20)
			leg_b_foot = hip_pos + Vector2(-16 * facing, 42)
		
		"kick_1": # Snap Kick
			var progress = fighter.get_attack_progress()
			var reach = sin(progress * PI)
			
			# Torso leans back slightly for balance
			hip_pos.x -= 6 * reach * facing
			shoulder_pos.x -= 14 * reach * facing
			head_pos.x -= 16 * reach * facing
			
			# Front leg snaps forward high
			leg_f_knee = hip_pos + Vector2(24 * reach * facing, -10 * reach)
			leg_f_foot = hip_pos + Vector2((26 + 48 * reach) * facing, -14 * reach)
			
			# Back leg firmly planted
			leg_b_knee = hip_pos + Vector2(-8 * facing, 30)
			leg_b_foot = Vector2(-14 * facing, 0)
			
			# Defensive guard during kick
			arm_f_elbow = shoulder_pos + Vector2(10 * facing, 14)
			arm_f_fist = arm_f_elbow + Vector2(6 * facing, -12)
			arm_b_elbow = shoulder_pos + Vector2(-12 * facing, 16)
			arm_b_fist = arm_b_elbow + Vector2(8 * facing, -14)
		
		"kick_2": # Roundhouse High Kick
			var progress = fighter.get_attack_progress()
			var reach = sin(progress * PI)
			
			hip_pos.x += 6 * reach * facing
			shoulder_pos.x -= 10 * reach * facing
			head_pos.x -= 12 * reach * facing
			
			# Powerful arcing high roundhouse kick
			leg_f_knee = hip_pos + Vector2(28 * reach * facing, -20 * reach)
			leg_f_foot = hip_pos + Vector2((30 + 54 * reach) * facing, -28 * reach)
			
			leg_b_knee = hip_pos + Vector2(-6 * facing, 30)
			leg_b_foot = Vector2(-12 * facing, 0)
			
			arm_f_elbow = shoulder_pos + Vector2(14 * facing, 12)
			arm_f_fist = arm_f_elbow + Vector2(8 * facing, -10)
			arm_b_elbow = shoulder_pos + Vector2(-16 * facing, 18)
			arm_b_fist = arm_b_elbow + Vector2(-6 * facing, 6)
		
		"crouch_kick": # Low Leg Sweep
			var progress = fighter.get_attack_progress()
			var reach = sin(progress * PI)
			
			hip_pos = Vector2(8 * reach * facing, -28)
			shoulder_pos = Vector2(0, -54)
			head_pos = Vector2(-4 * facing, -68)
			
			# Leg sweeps across floor
			leg_f_knee = Vector2(24 * reach * facing, -10)
			leg_f_foot = Vector2((28 + 52 * reach) * facing, -2)
			
			leg_b_knee = Vector2(-16 * facing, -12)
			leg_b_foot = Vector2(-22 * facing, 0)
			
			# Hand touches ground for balance
			arm_f_elbow = shoulder_pos + Vector2(-8 * facing, 22)
			arm_f_fist = shoulder_pos + Vector2(-12 * facing, 42)
			arm_b_elbow = shoulder_pos + Vector2(12 * facing, 16)
			arm_b_fist = shoulder_pos + Vector2(16 * facing, 4)
		
		"jump_kick": # Flying Side Kick
			var progress = fighter.get_attack_progress()
			var reach = clampf(sin(progress * PI) * 1.3, 0.0, 1.0)
			
			hip_pos = Vector2(6 * reach * facing, -54)
			shoulder_pos = Vector2(-10 * reach * facing, -78)
			head_pos = Vector2(-12 * reach * facing, -92)
			
			# Flying kick angled forward-downward
			leg_f_knee = hip_pos + Vector2(30 * reach * facing, 4)
			leg_f_foot = hip_pos + Vector2((32 + 48 * reach) * facing, 12)
			
			# Tucked trailing leg
			leg_b_knee = hip_pos + Vector2(-14 * facing, 12)
			leg_b_foot = hip_pos + Vector2(-20 * facing, 24)
			
			arm_f_elbow = shoulder_pos + Vector2(18 * facing, 6)
			arm_f_fist = arm_f_elbow + Vector2(12 * facing, -4)
			arm_b_elbow = shoulder_pos + Vector2(-16 * facing, 10)
			arm_b_fist = arm_b_elbow + Vector2(-8 * facing, 4)
		
		"hit_stun":
			# Recoil backward from impact
			var intensity = clampf(t * 5.0, 0.0, 1.0)
			var recoil = (1.0 - intensity) * 16.0
			
			hip_pos.x -= recoil * 0.5 * facing
			shoulder_pos.x -= recoil * 1.2 * facing
			head_pos.x -= recoil * 1.6 * facing
			
			# Head flinches back
			head_pos.y -= 4
			
			# Flailing arms
			arm_f_elbow = shoulder_pos + Vector2(-4 * facing, 16)
			arm_f_fist = shoulder_pos + Vector2(-8 * facing, 32)
			arm_b_elbow = shoulder_pos + Vector2(-18 * facing, 14)
			arm_b_fist = shoulder_pos + Vector2(-24 * facing, 28)
			
			leg_f_knee = hip_pos + Vector2(10 * facing, 28)
			leg_f_foot = Vector2(14 * facing, 0)
			leg_b_knee = hip_pos + Vector2(-16 * facing, 26)
			leg_b_foot = Vector2(-22 * facing, 0)
		
		"knockdown":
			# Collapsed on ground
			var fall_progress = clampf(t * 3.5, 0.0, 1.0)
			hip_pos = Vector2(-20 * fall_progress * facing, lerpf(-58.0, -12.0, fall_progress))
			shoulder_pos = Vector2(-45 * fall_progress * facing, lerpf(-92.0, -16.0, fall_progress))
			head_pos = Vector2(-60 * fall_progress * facing, lerpf(-108.0, -16.0, fall_progress))
			
			leg_f_knee = Vector2(-8 * facing, -12)
			leg_f_foot = Vector2(12 * facing, -4)
			leg_b_knee = Vector2(-28 * facing, -10)
			leg_b_foot = Vector2(-18 * facing, -2)
			
			arm_f_elbow = shoulder_pos + Vector2(12 * facing, 6)
			arm_f_fist = shoulder_pos + Vector2(24 * facing, 10)
			arm_b_elbow = shoulder_pos + Vector2(-8 * facing, 8)
			arm_b_fist = shoulder_pos + Vector2(-18 * facing, 12)
		
		"dead":
			# Defeated prone silhouette
			hip_pos = Vector2(-25 * facing, -12)
			shoulder_pos = Vector2(-55 * facing, -15)
			head_pos = Vector2(-72 * facing, -14)
			
			leg_f_knee = Vector2(-12 * facing, -10)
			leg_f_foot = Vector2(10 * facing, -4)
			leg_b_knee = Vector2(-32 * facing, -8)
			leg_b_foot = Vector2(-22 * facing, -2)
			
			arm_f_elbow = shoulder_pos + Vector2(14 * facing, 6)
			arm_f_fist = shoulder_pos + Vector2(26 * facing, 8)
			arm_b_elbow = shoulder_pos + Vector2(-6 * facing, 6)
			arm_b_fist = shoulder_pos + Vector2(-16 * facing, 10)
		
		"victory":
			# Proud martial salute stance
			hip_pos = Vector2(0, -60)
			shoulder_pos = Vector2(0, -96)
			head_pos = Vector2(0, -114)
			
			# Traditional martial fist-in-palm salute
			arm_f_elbow = shoulder_pos + Vector2(14 * facing, 12)
			arm_f_fist = shoulder_pos + Vector2(6 * facing, -4) # open palm
			
			arm_b_elbow = shoulder_pos + Vector2(-10 * facing, 12)
			arm_b_fist = shoulder_pos + Vector2(4 * facing, -4) # clenched fist
			
			leg_f_knee = hip_pos + Vector2(10 * facing, 28)
			leg_f_foot = Vector2(14 * facing, 0)
			leg_b_knee = hip_pos + Vector2(-10 * facing, 28)
			leg_b_foot = Vector2(-14 * facing, 0)

func _update_ribbon_physics(delta: float, fighter: CharacterBody2D) -> void:
	if ribbon_points.is_empty():
		return
	
	# Headband or sash anchor
	var anchor: Vector2
	if is_player:
		anchor = head_pos + Vector2(-10 * facing, 2)
	else:
		anchor = hip_pos + Vector2(-12 * facing, 0)
	
	ribbon_points[0] = anchor
	
	var gravity = Vector2(-facing * 80.0, 120.0) # wind blowing away from facing direction
	# Add fighter velocity drag
	gravity -= fighter.velocity * 0.4
	
	for i in range(1, RIBBON_SEGMENTS):
		var cur = ribbon_points[i]
		var prev = ribbon_prev_points[i]
		var vel = (cur - prev) * 0.88 # dampening
		
		ribbon_prev_points[i] = cur
		ribbon_points[i] = cur + vel + gravity * (delta * delta)
	
	# Relax distance constraints
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
	
	# 1. Back Arm
	_draw_limb(shoulder_pos, arm_b_elbow, arm_b_fist, 6.0, 5.0, cur_body_color)
	
	# 2. Back Leg
	_draw_leg(hip_pos + Vector2(-6 * facing, 0), leg_b_knee, leg_b_foot, 8.0, 6.0, cur_body_color)
	
	# 3. Torso / Waist
	_draw_torso(cur_body_color)
	
	# 4. Ribbon Tails (Headband for Player, Sash for AI)
	_draw_ribbon()
	
	# 5. Head & Accessories
	_draw_head(cur_body_color)
	
	# 6. Front Leg
	_draw_leg(hip_pos + Vector2(6 * facing, 0), leg_f_knee, leg_f_foot, 8.5, 6.5, cur_body_color)
	
	# 7. Front Arm
	_draw_limb(shoulder_pos, arm_f_elbow, arm_f_fist, 6.5, 5.5, cur_body_color)
	
	# 8. Attack Trail
	if trail_alpha > 0.01 and trail_points.size() >= 3:
		var c = trail_color
		c.a *= trail_alpha
		draw_polyline(trail_points, c, 10.0, true)
		var c_inner = Color(1, 1, 1, 0.8 * trail_alpha)
		draw_polyline(trail_points, c_inner, 3.0, true)
	
	# 9. Block Barrier Pulse
	if block_pulse > 0.01:
		var bp_color = Color(0.2, 0.8, 1.0, block_pulse * 0.6)
		var center = (shoulder_pos + arm_f_fist) * 0.5 + Vector2(10 * facing, 0)
		draw_arc(center, 28.0, -PI * 0.45, PI * 0.45, 16, bp_color, 4.0, true)
		draw_arc(center, 34.0, -PI * 0.35, PI * 0.35, 12, Color(1, 1, 1, block_pulse * 0.8), 2.0, true)

func _draw_limb(p_start: Vector2, p_mid: Vector2, p_end: Vector2, w1: float, w2: float, col: Color) -> void:
	# Upper segment
	draw_line(p_start, p_mid, col, w1, true)
	draw_circle(p_start, w1 * 0.5, col)
	draw_circle(p_mid, w1 * 0.5, col)
	# Forearm segment
	draw_line(p_mid, p_end, col, w2, true)
	# Hand / Fist
	draw_circle(p_end, w2 * 0.7, col)
	
	# Subtle rim highlight
	if flash_timer <= 0.0:
		draw_line(p_start + Vector2(-1 * facing, 0), p_mid + Vector2(-1 * facing, 0), COLOR_RIM, 1.5, true)

func _draw_leg(p_start: Vector2, p_mid: Vector2, p_end: Vector2, w1: float, w2: float, col: Color) -> void:
	draw_line(p_start, p_mid, col, w1, true)
	draw_circle(p_start, w1 * 0.5, col)
	draw_circle(p_mid, w1 * 0.5, col)
	draw_line(p_mid, p_end, col, w2, true)
	# Foot / Shoe
	var foot_front = p_end + Vector2(12 * facing, 0)
	var foot_back = p_end + Vector2(-4 * facing, 0)
	draw_line(foot_back, foot_front, col, w2 * 0.8, true)
	
	if flash_timer <= 0.0:
		draw_line(p_start + Vector2(-1 * facing, 0), p_mid + Vector2(-1 * facing, 0), COLOR_RIM, 1.5, true)

func _draw_torso(col: Color) -> void:
	# Stylized trapezoid torso
	var pts = PackedVector2Array([
		shoulder_pos + Vector2(-12 * facing, 0),
		shoulder_pos + Vector2(12 * facing, 0),
		hip_pos + Vector2(9 * facing, 0),
		hip_pos + Vector2(-9 * facing, 0)
	])
	draw_colored_polygon(pts, col)
	
	# Waist belt / sash
	var belt_y = hip_pos.y - 6
	draw_line(Vector2(-10 * facing, belt_y), Vector2(10 * facing, belt_y), accent_color, 4.0, true)
	draw_circle(Vector2(2 * facing, belt_y), 3.5, accent_color)

func _draw_head(col: Color) -> void:
	# Head silhouette
	draw_circle(head_pos, 11.5, col)
	
	# Neck connection
	draw_line(shoulder_pos + Vector2(0, -2), head_pos, col, 8.0, true)
	
	if is_player:
		# Player: Ninja / Ronin headband
		var band_y = head_pos.y - 1
		draw_line(head_pos + Vector2(-12 * facing, 0), head_pos + Vector2(11 * facing, -1), accent_color, 3.5, true)
		# Glowing eye slit
		var eye_center = head_pos + Vector2(6 * facing, 0)
		draw_line(eye_center - Vector2(3 * facing, 0), eye_center + Vector2(4 * facing, 0), eye_color, 2.5, true)
		draw_circle(eye_center + Vector2(1 * facing, 0), 1.5, Color.WHITE)
	else:
		# AI Opponent: Demonic Horned Mask / Kabuto Crest
		var horn_l = head_pos + Vector2(-6 * facing, -11)
		var horn_l_tip = head_pos + Vector2(-11 * facing, -24)
		var horn_r = head_pos + Vector2(4 * facing, -11)
		var horn_r_tip = head_pos + Vector2(12 * facing, -22)
		
		draw_line(horn_l, horn_l_tip, col, 4.0, true)
		draw_line(horn_r, horn_r_tip, col, 4.0, true)
		
		# Glowing crimson mask slit eyes
		var eye_center = head_pos + Vector2(5 * facing, 0)
		draw_line(eye_center - Vector2(4 * facing, -1), eye_center + Vector2(4 * facing, 1), eye_color, 2.5, true)
		draw_circle(eye_center, 1.8, Color(1, 0.9, 0.9))

func _draw_ribbon() -> void:
	if ribbon_points.size() < 2:
		return
	
	var r_color = accent_color
	draw_polyline(ribbon_points, r_color, 3.0, true)
	
	# A second slightly offset ribbon tail for rich flowing fabric feel
	var secondary_pts: Array[Vector2] = []
	for i in range(ribbon_points.size()):
		secondary_pts.append(ribbon_points[i] + Vector2(0, 3 + i * 0.6))
	draw_polyline(secondary_pts, r_color * 0.85, 2.2, true)
