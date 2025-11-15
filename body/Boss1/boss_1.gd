extends CharacterBody2D
class_name OshiroBoss

# ============================================================
# OSHIRO-STYLE BOSS - CELESTE INSPIRED (IMPROVED)
# ============================================================
@onready var sprite = %AnimatedSprite2D

@export_group("Boss Behavior")
@export var trigger_transform: bool = false
@export var charge_speed: float = 400.0
@export var wait_time_left: float = 1.2
@export var wait_time_right: float = 1.2
@export var match_player_y: bool = true
@export var y_match_speed: float = 80.0
@export var attack_slowmo_duration: float = 0.04  # Slowdown at start of attack
@export var attack_slowmo_amount: float = 0.3  # 0.3 = 30% normal speed

@export_group("Positioning")
@export var screen_left_offset: float = 40.0
@export var screen_right_offset: float = 40.0
@export var y_offset_range: Vector2 = Vector2(-20, 20)

@export_group("Visual Effects - AAA Polish")
@export var first_appear_duration: float = 1.5
@export var first_appear_shake_intensity: float = 12.0
@export var charge_shake_intensity: float = 5.0
@export var transform_shake_intensity: float = 8.0
@export var squash_stretch_enabled: bool = false
@export var anticipation_duration: float = 0.3

# ============================================================
# SOUND SYSTEM
# ============================================================
@export_group("Sound Effects")
@export_subgroup("Appear Sounds")
@export var appear_sounds: Array[AudioStream] = []
@export var appear_volume_db: float = 2.0
@export var appear_pitch_min: float = 0.95
@export var appear_pitch_max: float = 1.05

@export_subgroup("Appear Ambient Sounds (plays simultaneously)")
@export var appear_ambient_sounds: Array[AudioStream] = []
@export var appear_ambient_volume_db: float = -3.0
@export var appear_ambient_pitch_min: float = 0.8
@export var appear_ambient_pitch_max: float = 1.0

@export_subgroup("Transform Sounds")
@export var transform_sounds: Array[AudioStream] = []
@export var transform_volume_db: float = 3.0
@export var transform_pitch_min: float = 0.9
@export var transform_pitch_max: float = 1.0

@export_subgroup("Attack Start Sounds")
@export var attack_start_sounds: Array[AudioStream] = []
@export var attack_start_volume_db: float = 0.0
@export var attack_start_pitch_min: float = 0.95
@export var attack_start_pitch_max: float = 1.05

@export_subgroup("Charge Sounds")
@export var charge_sounds: Array[AudioStream] = []
@export var charge_volume_db: float = -2.0
@export var charge_pitch_min: float = 1.0
@export var charge_pitch_max: float = 1.2

@export_subgroup("Voice Lines While Charging")
@export var charging_voice_sounds: Array[AudioStream] = []
@export var charging_voice_volume_db: float = 1.0
@export var charging_voice_chance: float = 0.4  # 40% chance per charge
@export var charging_voice_pitch_min: float = 0.95
@export var charging_voice_pitch_max: float = 1.05

@export_subgroup("Arrive/Impact Sounds")
@export var arrive_sounds: Array[AudioStream] = []
@export var arrive_volume_db: float = 1.0
@export var arrive_pitch_min: float = 0.9
@export var arrive_pitch_max: float = 1.1

@export_subgroup("Waiting/Idle Sounds")
@export var waiting_sounds: Array[AudioStream] = []
@export var waiting_volume_db: float = -5.0
@export var waiting_interval_min: float = 2.0
@export var waiting_interval_max: float = 5.0

@export_subgroup("Audio Settings")
@export var sound_bus: String = "SFX"

# ============================================================
# STATE TRACKING
# ============================================================
enum BossState {
	HIDDEN,
	APPEARING,
	IDLE_WAITING,  # Waiting in idle (not transformed)
	TRANSFORMING,
	WAITING_LEFT,
	WAITING_RIGHT,
	ATTACKING_RIGHT,
	ATTACKING_LEFT,
	CHARGING_RIGHT,
	CHARGING_LEFT,
	MATCHING_Y
}

var current_state: BossState = BossState.HIDDEN
var wait_timer: float = 0.0
var has_appeared: bool = false
var has_transformed: bool = false
var player_reference: Node2D = null
var room_camera: Node2D = null

# Position tracking
var target_y: float = 0.0
var screen_left_x: float = 0.0
var screen_right_x: float = 0.0
var is_on_left: bool = true

# Audio players
var audio_appear: AudioStreamPlayer2D
var audio_appear_ambient: AudioStreamPlayer2D
var audio_transform: AudioStreamPlayer2D
var audio_attack_start: AudioStreamPlayer2D
var audio_charge: AudioStreamPlayer2D
var audio_charging_voice: AudioStreamPlayer2D
var audio_arrive: AudioStreamPlayer2D
var audio_waiting: AudioStreamPlayer2D

# Audio timers
var waiting_sound_timer: float = 0.0
var has_played_charging_voice: bool = false

# Visual effects
var original_scale: Vector2 = Vector2.ONE
var anticipation_tween: Tween
var squash_tween: Tween

# Slowdown system
var slowmo_timer: float = 0.0
var is_in_slowmo: bool = false

# ============================================================
# READY
# ============================================================
func _ready() -> void:
	setup_audio()
	find_references()
	
	if sprite:
		original_scale = sprite.scale
		sprite.modulate.a = 0.0
		# Connect animation finished signal
		sprite.animation_finished.connect(_on_animation_finished)
	
	update_screen_bounds()
	
	# Initialize waiting sound timer
	waiting_sound_timer = randf_range(waiting_interval_min, waiting_interval_max)
	
	# Always start appearance sequence
	call_deferred("start_boss_sequence")

# ============================================================
# AUDIO SETUP
# ============================================================
func setup_audio() -> void:
	# Appear sounds
	audio_appear = AudioStreamPlayer2D.new()
	audio_appear.name = "AudioAppear"
	audio_appear.bus = sound_bus
	audio_appear.volume_db = appear_volume_db
	add_child(audio_appear)
	
	# Appear ambient sounds (plays simultaneously)
	audio_appear_ambient = AudioStreamPlayer2D.new()
	audio_appear_ambient.name = "AudioAppearAmbient"
	audio_appear_ambient.bus = sound_bus
	audio_appear_ambient.volume_db = appear_ambient_volume_db
	add_child(audio_appear_ambient)
	
	# Transform sounds
	audio_transform = AudioStreamPlayer2D.new()
	audio_transform.name = "AudioTransform"
	audio_transform.bus = sound_bus
	audio_transform.volume_db = transform_volume_db
	add_child(audio_transform)
	
	# Attack start sounds
	audio_attack_start = AudioStreamPlayer2D.new()
	audio_attack_start.name = "AudioAttackStart"
	audio_attack_start.bus = sound_bus
	audio_attack_start.volume_db = attack_start_volume_db
	add_child(audio_attack_start)
	
	# Charge sounds (looping)
	audio_charge = AudioStreamPlayer2D.new()
	audio_charge.name = "AudioCharge"
	audio_charge.bus = sound_bus
	audio_charge.volume_db = charge_volume_db
	add_child(audio_charge)
	
	# Charging voice lines
	audio_charging_voice = AudioStreamPlayer2D.new()
	audio_charging_voice.name = "AudioChargingVoice"
	audio_charging_voice.bus = sound_bus
	audio_charging_voice.volume_db = charging_voice_volume_db
	add_child(audio_charging_voice)
	
	# Arrive sounds
	audio_arrive = AudioStreamPlayer2D.new()
	audio_arrive.name = "AudioArrive"
	audio_arrive.bus = sound_bus
	audio_arrive.volume_db = arrive_volume_db
	add_child(audio_arrive)
	
	# Waiting sounds
	audio_waiting = AudioStreamPlayer2D.new()
	audio_waiting.name = "AudioWaiting"
	audio_waiting.bus = sound_bus
	audio_waiting.volume_db = waiting_volume_db
	add_child(audio_waiting)
	
	print("🔊 Oshiro Boss audio system initialized")

# ============================================================
# SOUND PLAYBACK FUNCTIONS
# ============================================================
func play_random_sound(sound_array: Array[AudioStream], player: AudioStreamPlayer2D, 
					   pitch_min: float = 1.0, pitch_max: float = 1.0) -> void:
	"""Play a random sound from an array with pitch variation"""
	if sound_array.is_empty():
		return
	
	if not player or not is_instance_valid(player):
		return
	
	var random_sound = sound_array.pick_random()
	if random_sound:
		player.stream = random_sound
		player.pitch_scale = randf_range(pitch_min, pitch_max)
		player.play()

func play_appear_sound() -> void:
	# Play main appear sound
	play_random_sound(appear_sounds, audio_appear, appear_pitch_min, appear_pitch_max)
	
	# Play ambient appear sound simultaneously
	play_random_sound(appear_ambient_sounds, audio_appear_ambient, 
					  appear_ambient_pitch_min, appear_ambient_pitch_max)
	
	print("🔊 Playing appear sound + ambient")

func play_transform_sound() -> void:
	play_random_sound(transform_sounds, audio_transform, transform_pitch_min, transform_pitch_max)
	print("🔊 Playing transform sound")

func play_attack_start_sound() -> void:
	play_random_sound(attack_start_sounds, audio_attack_start, attack_start_pitch_min, attack_start_pitch_max)
	print("🔊 Playing attack start sound")

func play_charge_sound() -> void:
	"""Start playing charge sound (can be looping)"""
	play_random_sound(charge_sounds, audio_charge, charge_pitch_min, charge_pitch_max)
	print("🔊 Playing charge sound")

func stop_charge_sound() -> void:
	"""Stop charge sound"""
	if audio_charge and audio_charge.playing:
		audio_charge.stop()

func play_charging_voice() -> void:
	"""Randomly play voice line while charging"""
	if randf() < charging_voice_chance:
		play_random_sound(charging_voice_sounds, audio_charging_voice, 
						  charging_voice_pitch_min, charging_voice_pitch_max)
		print("🔊 Playing charging voice line")

func play_arrive_sound() -> void:
	play_random_sound(arrive_sounds, audio_arrive, arrive_pitch_min, arrive_pitch_max)
	print("🔊 Playing arrive sound")

func play_waiting_sound() -> void:
	play_random_sound(waiting_sounds, audio_waiting, 1.0, 1.0)

# ============================================================
# SETUP
# ============================================================
func find_references() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_reference = players[0]
	
	room_camera = get_tree().get_first_node_in_group("room_camera")

func update_screen_bounds() -> void:
	if room_camera:
		var room_center = room_camera.global_position
		var room_size = room_camera.room_size
		
		screen_left_x = room_center.x - room_size.x / 2 + screen_left_offset
		screen_right_x = room_center.x + room_size.x / 2 - screen_right_offset
	else:
		screen_left_x = global_position.x - 140
		screen_right_x = global_position.x + 140

# ============================================================
# BOSS SEQUENCE
# ============================================================
func start_boss_sequence() -> void:
	if has_appeared:
		return
	
	has_appeared = true
	
	if not player_reference:
		find_references()
	
	position_on_left(true)
	
	if global_position.y == 0:
		global_position.y = 90
	
	# Always play appear animation
	await play_appear_animation()
	
	# Check if boss should transform and attack
	if Global._boss_can_move:
		await play_transform_animation()
		start_attack_cycle()
	else:
		# Stay in idle (not transformed)
		enter_idle_waiting()

func play_appear_animation() -> void:
	current_state = BossState.APPEARING
	
	if not sprite or not sprite.sprite_frames:
		return
	
	is_on_left = true
	
	# SOUND: Appear
	play_appear_sound()
	
	if sprite.sprite_frames.has_animation("appear"):
		sprite.modulate.a = 1.0
		sprite.play("appear")
		
		if room_camera and room_camera.has_method("screen_shake"):
			room_camera.screen_shake(first_appear_shake_intensity, first_appear_duration)
		
		await sprite.animation_finished
	else:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 1.0, first_appear_duration).from(0.0)
		await tween.finished

func play_transform_animation() -> void:
	current_state = BossState.TRANSFORMING
	has_transformed = true
	
	if not sprite or not sprite.sprite_frames:
		return
	
	# SOUND: Transform
	play_transform_sound()
	
	if sprite.sprite_frames.has_animation("transform"):
		sprite.play("transform")
		
		if room_camera and room_camera.has_method("screen_shake"):
			room_camera.screen_shake(transform_shake_intensity, 1.0)
		
		await sprite.animation_finished
	
	if sprite.sprite_frames.has_animation("idle_transformed"):
		sprite.play("idle_transformed")

func enter_idle_waiting() -> void:
	"""Stay in idle state without transforming or attacking"""
	current_state = BossState.IDLE_WAITING
	
	if sprite and sprite.sprite_frames:
		if sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")

# ============================================================
# ATTACK CYCLE
# ============================================================
func start_attack_cycle() -> void:
	is_on_left = true
	enter_waiting_state()

func enter_waiting_state() -> void:
	if is_on_left:
		current_state = BossState.WAITING_LEFT
		wait_timer = wait_time_left
		sprite.flip_h = false  # Face right when on left
	else:
		current_state = BossState.WAITING_RIGHT
		wait_timer = wait_time_right
		sprite.flip_h = true  # Face left when on right
	
	if sprite and sprite.sprite_frames:
		var anim = "idle_transformed" if has_transformed else "idle"
		if sprite.sprite_frames.has_animation(anim):
			sprite.play(anim)
	
	# Reset waiting sound timer
	waiting_sound_timer = randf_range(waiting_interval_min, waiting_interval_max)

func start_attack() -> void:
	# SOUND: Attack start
	play_attack_start_sound()
	
	# Trigger slowdown at START of attack
	trigger_attack_slowmo()
	
	# Play anticipation squash
	if squash_stretch_enabled:
		play_anticipation_squash()
	
	# Set attack state and play attack animation
	if is_on_left:
		current_state = BossState.ATTACKING_RIGHT
		sprite.flip_h = false  # Face right during attack
	else:
		current_state = BossState.ATTACKING_LEFT
		sprite.flip_h = true  # Face left during attack
	
	# Charge shake
	if room_camera and room_camera.has_method("screen_shake"):
		room_camera.screen_shake(charge_shake_intensity, 0.3)
	
	# Play attack animation
	var attack_anim = "attack_transformed" if has_transformed else "attack"
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(attack_anim):
		sprite.play(attack_anim)
	else:
		# Fallback if attack animation doesn't exist - go straight to charging
		_start_charging()

func _start_charging() -> void:
	# Switch to charging state after attack animation
	if is_on_left:
		current_state = BossState.CHARGING_RIGHT
	else:
		current_state = BossState.CHARGING_LEFT
	
	# SOUND: Start charge sound
	play_charge_sound()
	
	# Reset voice flag
	has_played_charging_voice = false
	
	# Randomly play voice line
	if not charging_voice_sounds.is_empty():
		play_charging_voice()
		has_played_charging_voice = true

# ============================================================
# ANIMATION FINISHED HANDLER
# ============================================================
func _on_animation_finished() -> void:
	var anim_name = sprite.animation
	
	# When attack animation finishes, start charging
	if anim_name == "attack" or anim_name == "attack_transformed":
		_start_charging()
	
	# When charging finishes (if you have charge animation), play idle
	elif anim_name == "charge" or anim_name == "charge_transformed":
		var idle_anim = "idle_transformed" if has_transformed else "idle"
		if sprite.sprite_frames.has_animation(idle_anim):
			sprite.play(idle_anim)

# ============================================================
# PHYSICS PROCESS
# ============================================================
func _physics_process(delta: float) -> void:
	update_screen_bounds()
	
	if Global.boss1_delete == true:
		stop_all_sounds()
		self.queue_free()
	
	# Check if boss should transform (if not already transformed)
	if current_state == BossState.IDLE_WAITING and Global._boss_can_move and not has_transformed:
		# Enable death trigger
		if has_node("DeathTrigger/CollisionShape2D"):
			$DeathTrigger/CollisionShape2D.disabled = false
		
		# Transform and start attacking
		await play_transform_animation()
		start_attack_cycle()
		return
	
	# If Global._boss_can_move becomes false, stop all attacking behavior
	if not Global._boss_can_move:
		# Disable death trigger
		if has_node("DeathTrigger/CollisionShape2D"):
			$DeathTrigger/CollisionShape2D.disabled = true
		
		# Stop attacking and return to idle
		if current_state not in [BossState.HIDDEN, BossState.APPEARING, BossState.IDLE_WAITING]:
			stop_attacking_and_idle()
		return
	
	# Handle slowmo timer
	if slowmo_timer > 0.0:
		slowmo_timer -= delta
		if slowmo_timer <= 0.0 and is_in_slowmo:
			end_slowmo()
	
	# Handle waiting sounds timer
	if current_state in [BossState.WAITING_LEFT, BossState.WAITING_RIGHT]:
		waiting_sound_timer -= delta
		if waiting_sound_timer <= 0.0:
			play_waiting_sound()
			waiting_sound_timer = randf_range(waiting_interval_min, waiting_interval_max)
	
	# State machine
	match current_state:
		BossState.IDLE_WAITING:
			# Just stay in idle, do nothing
			pass
		BossState.WAITING_LEFT, BossState.WAITING_RIGHT:
			process_waiting(delta)
		BossState.ATTACKING_RIGHT, BossState.ATTACKING_LEFT:
			# Wait for attack animation to finish (handled by signal)
			pass
		BossState.CHARGING_RIGHT:
			process_charging_right(delta)
		BossState.CHARGING_LEFT:
			process_charging_left(delta)
		BossState.MATCHING_Y:
			process_matching_y(delta)

func stop_attacking_and_idle() -> void:
	"""Stop all attacking behavior and return to idle"""
	current_state = BossState.IDLE_WAITING
	end_slowmo()
	stop_charge_sound()
	
	if sprite and sprite.sprite_frames:
		var idle_anim = "idle_transformed" if has_transformed else "idle"
		if sprite.sprite_frames.has_animation(idle_anim):
			sprite.play(idle_anim)

func stop_all_sounds() -> void:
	"""Stop all currently playing sounds"""
	stop_charge_sound()
	if audio_appear and audio_appear.playing:
		audio_appear.stop()
	if audio_appear_ambient and audio_appear_ambient.playing:
		audio_appear_ambient.stop()
	if audio_transform and audio_transform.playing:
		audio_transform.stop()
	if audio_attack_start and audio_attack_start.playing:
		audio_attack_start.stop()
	if audio_charging_voice and audio_charging_voice.playing:
		audio_charging_voice.stop()
	if audio_arrive and audio_arrive.playing:
		audio_arrive.stop()
	if audio_waiting and audio_waiting.playing:
		audio_waiting.stop()

# ============================================================
# STATE PROCESSING
# ============================================================
func process_waiting(delta: float) -> void:
	if match_player_y and player_reference:
		match_player_y_position(delta)
	
	wait_timer -= delta
	
	if wait_timer <= 0.0:
		start_attack()

func process_charging_right(delta: float) -> void:
	var move_distance = charge_speed * delta
	global_position.x += move_distance
	
	if global_position.x >= screen_right_x:
		stop_charge_sound()
		arrive_at_right()

func process_charging_left(delta: float) -> void:
	var move_distance = charge_speed * delta
	global_position.x -= move_distance
	
	if global_position.x <= screen_left_x:
		stop_charge_sound()
		arrive_at_left()

func process_matching_y(delta: float) -> void:
	if not player_reference:
		enter_waiting_state()
		return
	
	match_player_y_position(delta)
	
	if abs(global_position.y - target_y) < 5.0:
		global_position.y = target_y
		enter_waiting_state()

func match_player_y_position(delta: float) -> void:
	if not player_reference:
		return
	
	target_y = player_reference.global_position.y + randf_range(y_offset_range.x, y_offset_range.y)
	
	var direction = sign(target_y - global_position.y)
	var distance = abs(target_y - global_position.y)
	
	if distance > 2.0:
		global_position.y += direction * min(y_match_speed * delta, distance)

# ============================================================
# ARRIVAL FUNCTIONS
# ============================================================
func arrive_at_right() -> void:
	position_on_right(false)
	is_on_left = false
	
	# Face LEFT after finishing attack to the right
	sprite.flip_h = true
	
	play_arrival_effects()
	enter_waiting_state()

func arrive_at_left() -> void:
	position_on_left(false)
	is_on_left = true
	
	# Face RIGHT after finishing attack to the left
	sprite.flip_h = false
	
	play_arrival_effects()
	enter_waiting_state()

func play_arrival_effects() -> void:
	# SOUND: Arrive/impact
	play_arrive_sound()
	
	if squash_stretch_enabled and sprite:
		play_impact_squash()
	
	if room_camera and room_camera.has_method("screen_shake"):
		room_camera.screen_shake(3.0, 0.2)

# ============================================================
# POSITIONING
# ============================================================
func position_on_left(instant: bool = false) -> void:
	global_position.x = screen_left_x
	if instant and player_reference:
		global_position.y = player_reference.global_position.y

func position_on_right(instant: bool = false) -> void:
	global_position.x = screen_right_x
	if instant and player_reference:
		global_position.y = player_reference.global_position.y

# ============================================================
# SLOWMO SYSTEM (AT START OF ATTACK ONLY)
# ============================================================
func trigger_attack_slowmo() -> void:
	if attack_slowmo_duration <= 0.0:
		return
	
	is_in_slowmo = true
	slowmo_timer = attack_slowmo_duration
	Engine.time_scale = attack_slowmo_amount

func end_slowmo() -> void:
	is_in_slowmo = false
	Engine.time_scale = 1.0

# ============================================================
# VISUAL EFFECTS
# ============================================================
func play_anticipation_squash() -> void:
	if not sprite or not squash_stretch_enabled:
		return
	
	if anticipation_tween:
		anticipation_tween.kill()
	
	anticipation_tween = create_tween()
	anticipation_tween.set_ease(Tween.EASE_IN)
	anticipation_tween.set_trans(Tween.TRANS_QUAD)
	
	var squash_scale = original_scale * Vector2(1.3, 0.8)
	anticipation_tween.tween_property(sprite, "scale", squash_scale, anticipation_duration)

func play_impact_squash() -> void:
	if not sprite or not squash_stretch_enabled:
		return
	
	if squash_tween:
		squash_tween.kill()
	
	squash_tween = create_tween()
	squash_tween.set_ease(Tween.EASE_OUT)
	squash_tween.set_trans(Tween.TRANS_BOUNCE)
	
	var impact_scale = original_scale * Vector2(0.8, 1.2)
	squash_tween.tween_property(sprite, "scale", impact_scale, 0.1)
	squash_tween.tween_property(sprite, "scale", original_scale, 0.4)

# ============================================================
# PUBLIC API
# ============================================================
func hide_boss() -> void:
	current_state = BossState.HIDDEN
	if sprite:
		sprite.modulate.a = 0.0
	end_slowmo()
	stop_all_sounds()
	slowmo_timer = 0.0

func set_charge_speed(speed: float) -> void:
	charge_speed = max(100.0, speed)

func set_wait_times(left: float, right: float) -> void:
	wait_time_left = max(0.3, left)
	wait_time_right = max(0.3, right)

func force_charge_now() -> void:
	wait_timer = 0.0

# ============================================================
# CLEANUP
# ============================================================
func _exit_tree() -> void:
	end_slowmo()
	stop_all_sounds()

# ============================================================
# DEBUG CONTROLS
# ============================================================
func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F5:
				force_charge_now()
			KEY_F6:
				charge_speed += 50
				print("Oshiro Boss: Charge speed = ", charge_speed)
			KEY_F7:
				charge_speed = max(100, charge_speed - 50)
				print("Oshiro Boss: Charge speed = ", charge_speed)
			KEY_F8:
				Global._boss_can_move = not Global._boss_can_move
				print("Oshiro Boss: Global._boss_can_move = ", Global._boss_can_move)
			KEY_F9:
				attack_slowmo_duration += 0.05
				print("Oshiro Boss: Slowmo duration = ", attack_slowmo_duration)
