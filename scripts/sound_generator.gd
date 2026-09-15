extends Node

# Procedural Sound Generator for 2D Silhouette Martial-Arts Fighter
# Produces 100% original dynamic synthetic sound effects using AudioStreamWAV

const SAMPLE_RATE = 22050

var sounds: Dictionary = {}
var player_pool: Array[AudioStreamPlayer] = []
const POOL_SIZE = 12
var current_player_idx = 0
var sfx_volume: float = 0.85
var sfx_muted: bool = false

func _ready() -> void:
	# Create pooled audio players
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		player_pool.append(p)
	
	_generate_all_sounds()

func _exit_tree() -> void:
	for p in player_pool:
		if p and is_instance_valid(p):
			p.stop()
			p.stream = null
	sounds.clear()

func _generate_all_sounds() -> void:
	sounds["whoosh_light"] = _gen_whoosh(0.12, 400.0, 150.0)
	sounds["whoosh_heavy"] = _gen_whoosh(0.22, 280.0, 80.0)
	sounds["hit_light"] = _gen_hit(0.14, 220.0, 60.0, 0.6)
	sounds["hit_heavy"] = _gen_hit(0.26, 160.0, 45.0, 0.9)
	sounds["block"] = _gen_block(0.16, 900.0, 300.0)
	sounds["sweep"] = _gen_whoosh(0.25, 200.0, 60.0)
	sounds["jump"] = _gen_jump(0.18)
	sounds["land"] = _gen_land(0.12)
	sounds["round_bell"] = _gen_bell(1.8, 440.0)
	sounds["ko_impact"] = _gen_ko(2.2)
	sounds["ui_click"] = _gen_click(0.06)

func play(sound_name: String, pitch_scale: float = 1.0, volume_scale: float = 1.0) -> void:
	if sfx_muted or DisplayServer.get_name() == "headless":
		return
	if not sounds.has(sound_name):
		return
	
	var player = player_pool[current_player_idx]
	current_player_idx = (current_player_idx + 1) % POOL_SIZE
	
	player.stream = sounds[sound_name]
	player.pitch_scale = clampf(pitch_scale, 0.5, 2.0)
	var db = linear_to_db(clampf(sfx_volume * volume_scale, 0.001, 1.5))
	player.volume_db = db
	player.play()

# Generate whoosh (aerodynamic strike swing)
func _gen_whoosh(duration: float, start_freq: float, end_freq: float) -> AudioStreamWAV:
	var total_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(total_samples * 2)
	
	var phase = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		# Smooth curved envelope: quick ramp up, smooth trail off
		var env = sin(t * PI)
		var freq = lerpf(start_freq, end_freq, t)
		phase += 2.0 * PI * freq / SAMPLE_RATE
		
		# Combine tone with subtle noise turbulence
		var noise = (randf() * 2.0 - 1.0) * 0.4
		var tone = sin(phase) * 0.6
		var sample_val = (tone + noise) * env * 0.7
		var int_val = int(clampf(sample_val, -1.0, 1.0) * 30000.0)
		bytes.encode_s16(i * 2, int_val)
	
	return _make_stream(bytes)

# Generate punch/kick impact thud
func _gen_hit(duration: float, start_freq: float, end_freq: float, noise_amt: float) -> AudioStreamWAV:
	var total_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(total_samples * 2)
	
	var phase = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		# Sharp explosive attack, steep exponential decay
		var env = exp(-7.0 * t)
		var freq = lerpf(start_freq, end_freq, pow(t, 0.5))
		phase += 2.0 * PI * freq / SAMPLE_RATE
		
		var noise = (randf() * 2.0 - 1.0) * noise_amt
		var sub = sin(phase) * (1.0 - noise_amt)
		var clip = (sub + noise) * env
		# Soft clip / saturation for beefy martial arts punch feel
		clip = tanh(clip * 1.6)
		var int_val = int(clampf(clip, -1.0, 1.0) * 31000.0)
		bytes.encode_s16(i * 2, int_val)
	
	return _make_stream(bytes)

# Generate high-impact block clash
func _gen_block(duration: float, start_freq: float, end_freq: float) -> AudioStreamWAV:
	var total_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(total_samples * 2)
	
	var phase1 = 0.0
	var phase2 = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var env = exp(-12.0 * t)
		var freq1 = lerpf(start_freq, end_freq, t)
		var freq2 = freq1 * 1.48 # metallic overtone
		phase1 += 2.0 * PI * freq1 / SAMPLE_RATE
		phase2 += 2.0 * PI * freq2 / SAMPLE_RATE
		
		var clang = (sin(phase1) * 0.6 + sin(phase2) * 0.4)
		var snap = (randf() * 2.0 - 1.0) * exp(-25.0 * t) * 0.5
		var sample_val = (clang + snap) * env
		var int_val = int(clampf(sample_val, -1.0, 1.0) * 30000.0)
		bytes.encode_s16(i * 2, int_val)
	
	return _make_stream(bytes)

# Generate jump whoosh
func _gen_jump(duration: float) -> AudioStreamWAV:
	var total_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(total_samples * 2)
	
	var phase = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var env = sin(t * PI) * exp(-2.0 * t)
		var freq = lerpf(120.0, 380.0, t * t)
		phase += 2.0 * PI * freq / SAMPLE_RATE
		var sample_val = sin(phase) * env * 0.75
		var int_val = int(clampf(sample_val, -1.0, 1.0) * 28000.0)
		bytes.encode_s16(i * 2, int_val)
	
	return _make_stream(bytes)

# Generate landing thud
func _gen_land(duration: float) -> AudioStreamWAV:
	var total_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(total_samples * 2)
	
	var phase = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var env = exp(-14.0 * t)
		var freq = lerpf(110.0, 45.0, t)
		phase += 2.0 * PI * freq / SAMPLE_RATE
		var noise = (randf() * 2.0 - 1.0) * 0.3 * env
		var sample_val = (sin(phase) * 0.7 + noise) * env
		var int_val = int(clampf(sample_val, -1.0, 1.0) * 28000.0)
		bytes.encode_s16(i * 2, int_val)
	
	return _make_stream(bytes)

# Resonant temple gong / round bell
func _gen_bell(duration: float, fundamental: float) -> AudioStreamWAV:
	var total_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(total_samples * 2)
	
	var p1 = 0.0
	var p2 = 0.0
	var p3 = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		# Long slow exponential resonance
		var env1 = exp(-2.5 * t)
		var env2 = exp(-4.0 * t)
		var env3 = exp(-7.0 * t)
		
		p1 += 2.0 * PI * fundamental / SAMPLE_RATE
		p2 += 2.0 * PI * (fundamental * 1.58) / SAMPLE_RATE
		p3 += 2.0 * PI * (fundamental * 2.34) / SAMPLE_RATE
		
		var val = (sin(p1) * 0.5 * env1 + sin(p2) * 0.3 * env2 + sin(p3) * 0.2 * env3)
		var int_val = int(clampf(val, -1.0, 1.0) * 31000.0)
		bytes.encode_s16(i * 2, int_val)
	
	return _make_stream(bytes)

# Dramatic KO sub-drop rumble
func _gen_ko(duration: float) -> AudioStreamWAV:
	var total_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(total_samples * 2)
	
	var phase = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var env = exp(-1.8 * t)
		var freq = lerpf(95.0, 28.0, pow(t, 0.4))
		phase += 2.0 * PI * freq / SAMPLE_RATE
		
		var sub = sin(phase)
		var boom = tanh(sub * 2.0) * env * 0.95
		var int_val = int(clampf(boom, -1.0, 1.0) * 32000.0)
		bytes.encode_s16(i * 2, int_val)
	
	return _make_stream(bytes)

# Light UI click
func _gen_click(duration: float) -> AudioStreamWAV:
	var total_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var env = exp(-30.0 * t)
		var val = (randf() * 2.0 - 1.0) * env * 0.6
		var int_val = int(clampf(val, -1.0, 1.0) * 20000.0)
		bytes.encode_s16(i * 2, int_val)
	
	return _make_stream(bytes)

func _make_stream(data: PackedByteArray) -> AudioStreamWAV:
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = SAMPLE_RATE
	s.stereo = false
	s.data = data
	return s
