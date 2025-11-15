extends CharacterBody2D
class_name FlyingBoss

# ============================================================
# BOSS STATE MACHINE
# ============================================================
enum BossState {
	IDLE,            # Hovering and observing
	CHARGING,        # Preparing to shoot
	ATTACKING,       # Firing bullets
	REPOSITIONING,   # Flying to new position
	HURT,            # Taking damage
	DYING,           # Death sequence
	DEAD             # Fully dead
}

# ============================================================
# CORE STATS
# ============================================================
@export_group("Boss Stats")
@export var max_health: int = 100
@export var contact_damage: int = 15

# ============================================================
# SOUND SYSTEM
# ============================================================
@export_group("Sound Effects")
@export_subgroup("Hit Sounds")
@export var hit_sounds: Array[AudioStream] = []
@export var hit_volume_db: float = 0.0
@export var hit_pitch_min: float = 0.9
@export var hit_pitch_max: float = 1.1

@export_subgroup("Charge Sounds")
@export var charge_sounds: Array[AudioStream] = []
@export var charge_volume_db: float = -3.0
@export var charge_pitch_min: float = 0.95
@export var charge_pitch_max: float = 1.05

@export_subgroup("Shoot Sounds")
@export var shoot_sounds: Array[AudioStream] = []
@export var shoot_volume_db: float = -2.0
@export var shoot_pitch_min: float = 0.9
@export var shoot_pitch_max: float = 1.1

@export_subgroup("Movement Sounds")
@export var reposition_sounds: Array[AudioStream] = []
@export var reposition_volume_db: float = -5.0
@export var reposition_pitch_min: float = 0.95
@export var reposition_pitch_max: float = 1.05

@export_subgroup("Death Sounds")
@export var death_sounds: Array[AudioStream] = []
@export var death_volume_db: float = 3.0
@export var death_pitch_min: float = 0.8
@export var death_pitch_max: float = 1.0

@export_subgroup("Phase Change Sounds")
@export var phase_change_sounds: Array[AudioStream] = []
@export var phase_change_volume_db: float = 2.0
@export var phase_change_pitch_min: float = 0.9
@export var phase_change_pitch_max: float = 1.1

@export_subgroup("Idle Ambient Sounds")
@export var idle_ambient_sounds: Array[AudioStream] = []
@export var idle_ambient_volume_db: float = -8.0
@export var idle_ambient_interval_min: float = 3.0  # Minimum seconds between idle sounds
@export var idle_ambient_interval_max: float = 8.0  # Maximum seconds between idle sounds

@export_subgroup("Audio Settings")
@export var sound_bus: String = "SFX"

# ============================================================
# FLOATING PHYSICS
# ============================================================
@export_group("Float Movement")
@export var float_enabled: bool = true
@export var float_amplitude: float = 15.0  # How high/low it bobs
@export var float_speed: float = 2.0       # How fast it bobs
@export var float_offset: float = 0.0      # Starting phase offset

# ============================================================
# REPOSITIONING
# ============================================================
@export_group("Position System")
@export var fly_positions: Array[Marker2D] = []  # Assign position markers in inspector!
@export var reposition_speed: float = 200.0
@export var min_reposition_time: float = 3.0     # Minimum time before moving
@export var max_reposition_time: float = 7.0     # Maximum time before moving
@export var reposition_chance: float = 0.7       # 70% chance to reposition vs staying

# Phase end positions
@export_group("Phase End Positions")
@export var phase1_end_position: Marker2D  # Where boss goes at end of phase 1
@export var phase2_end_position: Marker2D  # Where boss goes at end of phase 2
@export var phase3_end_position: Marker2D  # Where boss goes at end of phase 3

# ============================================================
# ATTACK SETTINGS
# ============================================================
@export_group("Attack Patterns")
@export var bullet_scene: PackedScene  # Assign bullet scene in inspector!
@export var bullet_spawn_marker: Marker2D  # Where bullets spawn from

# Phase 1 (100% - 66% HP)
@export_subgroup("Phase 1: Opening")
@export var phase1_bullets_per_attack: int = 1
@export var phase1_bullet_delay: float = 0.0
@export var phase1_attack_cooldown: float = 2.5

# Phase 2 (66% - 33% HP)
@export_subgroup("Phase 2: Aggressive")
@export var phase2_bullets_per_attack: int = 3
@export var phase2_bullet_delay: float = 0.15
@export var phase2_attack_cooldown: float = 2.0

# Phase 3 (33% - 0% HP)
@export_subgroup("Phase 3: Desperate")
@export var phase3_bullets_per_attack: int = 5
@export var phase3_bullet_delay: float = 0.1
@export var phase3_attack_cooldown: float = 1.5

# Bullet spread
@export_group("Bullet Spread")
@export var bullet_spread_angle: float = 15.0  # Degrees between bullets
@export var bullet_base_direction: Vector2 = Vector2.LEFT  # Default shoot direction

# ============================================================
# VISUAL EFFECTS
# ============================================================
@export_group("Screen Shake")
@export var hit_shake_intensity: float = 5.0
@export var hit_shake_duration: float = 0.2
@export var death_shake_intensity: float = 12.0
@export var death_shake_duration: float = 0.6
@export var phase_shake_intensity: float = 8.0
@export var phase_shake_duration: float = 0.3

@export_group("Flash Effects")
@export var hit_flash_duration: float = 0.1
@export var hurt_freeze_duration: float = 0.08

# ============================================================
# ANIMATION & AUDIO
# ============================================================
@export_group("Components")
@export var animated_sprite: AnimatedSprite2D  # Assign in inspector!
@export var hitbox: CollisionShape2D

# ============================================================
# AUDIO PLAYERS
# ============================================================
var audio_hit: AudioStreamPlayer2D
var audio_charge: AudioStreamPlayer2D
var audio_shoot: AudioStreamPlayer2D
var audio_movement: AudioStreamPlayer2D
var audio_death: AudioStreamPlayer2D
var audio_phase: AudioStreamPlayer2D
var audio_ambient: AudioStreamPlayer2D

# ============================================================
# INTERNAL STATE
# ============================================================
var current_state: BossState = BossState.IDLE
var previous_state: BossState = BossState.IDLE

# Timers
var attack_cooldown_timer: float = 0.0
var reposition_timer: float = 0.0
var state_timer: float = 0.0
var idle_ambient_timer: float = 0.0

# Float animation
var float_time: float = 0.0
var base_y_position: float = 0.0

# Repositioning
var target_position: Vector2 = Vector2.ZERO
var current_position_index: int = -1
var is_repositioning: bool = false
var is_going_to_phase_end: bool = false

# Attack state
var bullets_fired_this_attack: int = 0
var bullet_delay_timer: float = 0.0
var is_firing_sequence: bool = false

# Phase tracking
var current_phase: int = 1
var health_percentage: float = 100.0
var has_reached_phase_end: Array[bool] = [false, false, false]  # Track if reached each phase end

# Camera reference
var room_camera: Node2D = null

# Hit animation tracking
var is_hit_animation_playing: bool = false

# ============================================================
# INITIALIZATION
# ============================================================
func _ready() -> void:
	add_to_group("boss")
	add_to_group("enemy")
	
	# Setup audio players
	_setup_audio_system()
	
	# Initialize global boss health if not set
	if not "boss2_health" in Global:
		Global.boss2_health = max_health
	else:
		# Use existing global health
		max_health = Global.boss2_health
	
	# Initialize Global.boss2_move if not set
	if not "boss2_move" in Global:
		Global.boss2_move = true
	
	# Get camera reference
	get_camera_reference()
	
	# Validate setup
	validate_setup()
	
	# Physics setup
	collision_layer = 4  # Enemy layer
	collision_mask = 3   # Player + walls
	
	# Store starting position for float animation
	base_y_position = global_position.y
	float_time = float_offset
	
	# Choose initial position if available
	if fly_positions.size() > 0:
		choose_random_position()
		global_position = target_position
		base_y_position = target_position.y
		current_position_index = 0
	
	# Setup reposition timer
	reposition_timer = randf_range(min_reposition_time, max_reposition_time)
	
	# Setup idle ambient timer
	idle_ambient_timer = randf_range(idle_ambient_interval_min, idle_ambient_interval_max)
	
	# Connect animation signals
	if animated_sprite:
		# Connect frame change signal
		if not animated_sprite.frame_changed.is_connected(_on_animation_frame_changed):
			animated_sprite.frame_changed.connect(_on_animation_frame_changed)
		
		# Connect animation finished signal
		if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
			animated_sprite.animation_finished.connect(_on_animation_finished)
		
		animated_sprite.play("idle")
	
	# Start in idle
	change_state(BossState.IDLE)
	
	print("👑 BOSS SPAWNED | HP: ", Global.boss2_health, " | Movement: ", Global.boss2_move)

# ============================================================
# AUDIO SYSTEM SETUP
# ============================================================
func _setup_audio_system() -> void:
	"""Create all audio players for the boss"""
	# Hit sounds
	audio_hit = AudioStreamPlayer2D.new()
	audio_hit.bus = sound_bus
	audio_hit.volume_db = hit_volume_db
	add_child(audio_hit)
	
	# Charge sounds
	audio_charge = AudioStreamPlayer2D.new()
	audio_charge.bus = sound_bus
	audio_charge.volume_db = charge_volume_db
	add_child(audio_charge)
	
	# Shoot sounds
	audio_shoot = AudioStreamPlayer2D.new()
	audio_shoot.bus = sound_bus
	audio_shoot.volume_db = shoot_volume_db
	add_child(audio_shoot)
	
	# Movement sounds
	audio_movement = AudioStreamPlayer2D.new()
	audio_movement.bus = sound_bus
	audio_movement.volume_db = reposition_volume_db
	add_child(audio_movement)
	
	# Death sounds
	audio_death = AudioStreamPlayer2D.new()
	audio_death.bus = sound_bus
	audio_death.volume_db = death_volume_db
	add_child(audio_death)
	
	# Phase change sounds
	audio_phase = AudioStreamPlayer2D.new()
	audio_phase.bus = sound_bus
	audio_phase.volume_db = phase_change_volume_db
	add_child(audio_phase)
	
	# Idle ambient sounds
	audio_ambient = AudioStreamPlayer2D.new()
	audio_ambient.bus = sound_bus
	audio_ambient.volume_db = idle_ambient_volume_db
	add_child(audio_ambient)
	
	print("🔊 Boss audio system initialized")

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

func play_hit_sound() -> void:
	"""Play random hit sound"""
	play_random_sound(hit_sounds, audio_hit, hit_pitch_min, hit_pitch_max)
	print("🔊 Playing hit sound")

func play_charge_sound() -> void:
	"""Play random charge sound"""
	play_random_sound(charge_sounds, audio_charge, charge_pitch_min, charge_pitch_max)
	print("🔊 Playing charge sound")

func play_shoot_sound() -> void:
	"""Play random shoot sound"""
	play_random_sound(shoot_sounds, audio_shoot, shoot_pitch_min, shoot_pitch_max)
	print("🔊 Playing shoot sound")

func play_reposition_sound() -> void:
	"""Play random movement sound"""
	play_random_sound(reposition_sounds, audio_movement, reposition_pitch_min, reposition_pitch_max)
	print("🔊 Playing reposition sound")

func play_death_sound() -> void:
	"""Play random death sound"""
	play_random_sound(death_sounds, audio_death, death_pitch_min, death_pitch_max)
	print("🔊 Playing death sound")

func play_phase_change_sound() -> void:
	"""Play random phase change sound"""
	play_random_sound(phase_change_sounds, audio_phase, phase_change_pitch_min, phase_change_pitch_max)
	print("🔊 Playing phase change sound")

func play_idle_ambient_sound() -> void:
	"""Play random idle ambient sound"""
	play_random_sound(idle_ambient_sounds, audio_ambient, 1.0, 1.0)

# ============================================================
# VALIDATION
# ============================================================
func get_camera_reference() -> void:
	"""Get reference to the room camera"""
	room_camera = get_tree().get_first_node_in_group("room_camera")
	if room_camera:
		print("📷 Camera found for screen shake")
	else:
		print("⚠️ No camera found in 'room_camera' group")

func validate_setup() -> void:
	"""Validate all required components are assigned"""
	var errors: Array[String] = []
	
	if not animated_sprite:
		errors.append("❌ AnimatedSprite2D not assigned!")
	
	if not bullet_scene:
		errors.append("❌ Bullet scene not assigned!")
	
	if not bullet_spawn_marker:
		errors.append("❌ Bullet spawn marker not assigned!")
	
	if fly_positions.size() == 0:
		errors.append("⚠️ No fly positions assigned! Boss will stay in place.")
	
	if not phase1_end_position:
		errors.append("⚠️ Phase 1 end position not assigned!")
	
	if not phase2_end_position:
		errors.append("⚠️ Phase 2 end position not assigned!")
	
	if not phase3_end_position:
		errors.append("⚠️ Phase 3 end position not assigned!")
	
	# Sound warnings (not errors since sounds are optional)
	if hit_sounds.is_empty():
		print("⚠️ No hit sounds assigned")
	if charge_sounds.is_empty():
		print("⚠️ No charge sounds assigned")
	if shoot_sounds.is_empty():
		print("⚠️ No shoot sounds assigned")
	if reposition_sounds.is_empty():
		print("⚠️ No reposition sounds assigned")
	if death_sounds.is_empty():
		print("⚠️ No death sounds assigned")
	if phase_change_sounds.is_empty():
		print("⚠️ No phase change sounds assigned")
	
	if errors.size() > 0:
		print("🚨 BOSS SETUP ERRORS:")
		for error in errors:
			print("  ", error)

# ============================================================
# MAIN LOOP
# ============================================================
func _physics_process(delta: float) -> void:
	if current_state == BossState.DEAD:
		return
	
	# Update timers
	state_timer += delta
	attack_cooldown_timer -= delta
	idle_ambient_timer -= delta
	
	# Play idle ambient sounds periodically
	if current_state == BossState.IDLE and idle_ambient_timer <= 0.0:
		play_idle_ambient_sound()
		idle_ambient_timer = randf_range(idle_ambient_interval_min, idle_ambient_interval_max)
	
	# Only update reposition timer if boss can move
	if Global.boss2_move:
		reposition_timer -= delta
	
	# Apply floating animation (always float, even when not moving)
	apply_float_movement(delta)
	
	# Check phase transitions
	update_phase()
	
	# Check movement state
	check_movement_state()
	
	# State machine
	match current_state:
		BossState.IDLE:
			process_idle_state(delta)
		
		BossState.CHARGING:
			process_charging_state(delta)
		
		BossState.ATTACKING:
			process_attacking_state(delta)
		
		BossState.REPOSITIONING:
			process_repositioning_state(delta)
		
		BossState.HURT:
			process_hurt_state(delta)
		
		BossState.DYING:
			process_dying_state(delta)
	
	# Apply movement
	move_and_slide()

# ============================================================
# MOVEMENT CONTROL
# ============================================================
func check_movement_state() -> void:
	"""Check if boss should stop moving based on Global.boss2_move"""
	if not Global.boss2_move:
		# Boss cannot move - force idle if not in special states
		if current_state == BossState.REPOSITIONING:
			# Stop repositioning
			is_repositioning = false
			velocity = Vector2.ZERO
			change_state(BossState.IDLE)
		elif current_state not in [BossState.HURT, BossState.DYING, BossState.DEAD]:
			# Play idle animation
			if animated_sprite and animated_sprite.animation != "idle":
				animated_sprite.play("idle")

# ============================================================
# FLOATING ANIMATION
# ============================================================
func apply_float_movement(delta: float) -> void:
	"""Smooth sine-wave floating"""
	if not float_enabled or is_repositioning:
		return
	
	float_time += delta * float_speed
	var float_y = sin(float_time) * float_amplitude
	
	# Apply float offset to current position
	var target_y = base_y_position + float_y
	global_position.y = lerp(global_position.y, target_y, 0.1)

# ============================================================
# PHASE SYSTEM
# ============================================================
func update_phase() -> void:
	"""Update combat phase based on health"""
	health_percentage = (float(Global.boss2_health) / float(max_health)) * 100.0
	
	var new_phase = current_phase
	
	if health_percentage > 66.0:
		new_phase = 1
	elif health_percentage > 33.0:
		new_phase = 2
	else:
		new_phase = 3
	
	if new_phase != current_phase:
		current_phase = new_phase
		on_phase_change()

func on_phase_change() -> void:
	"""Called when boss enters a new phase"""
	print("⚡ PHASE TRANSITION: Phase ", current_phase)
	
	# SOUND: Phase change
	play_phase_change_sound()
	
	# Visual feedback
	flash_sprite(Color.RED, 0.3)
	trigger_camera_shake(phase_shake_intensity, phase_shake_duration)
	
	# Spawn phase particles
	spawn_phase_particles()
	
	# Move to phase end position
	move_to_phase_end_position()

func move_to_phase_end_position() -> void:
	"""Move boss to the end position for current phase"""
	var phase_marker: Marker2D = null
	
	match current_phase:
		1:
			phase_marker = phase1_end_position
		2:
			phase_marker = phase2_end_position
		3:
			phase_marker = phase3_end_position
	
	if phase_marker and Global.boss2_move:
		target_position = phase_marker.global_position
		is_going_to_phase_end = true
		change_state(BossState.REPOSITIONING)
		print("🎯 Moving to Phase ", current_phase, " end position")

func get_current_bullets_per_attack() -> int:
	"""Get bullet count based on phase"""
	match current_phase:
		1: return phase1_bullets_per_attack
		2: return phase2_bullets_per_attack
		3: return phase3_bullets_per_attack
		_: return phase1_bullets_per_attack

func get_current_bullet_delay() -> float:
	"""Get bullet delay based on phase"""
	match current_phase:
		1: return phase1_bullet_delay
		2: return phase2_bullet_delay
		3: return phase3_bullet_delay
		_: return phase1_bullet_delay

func get_current_attack_cooldown() -> float:
	"""Get attack cooldown based on phase"""
	match current_phase:
		1: return phase1_attack_cooldown
		2: return phase2_attack_cooldown
		3: return phase3_attack_cooldown
		_: return phase1_attack_cooldown

# ============================================================
# STATE: IDLE
# ============================================================
func process_idle_state(delta: float) -> void:
	"""Hovering and deciding next action"""
	if animated_sprite and animated_sprite.animation != "idle":
		animated_sprite.play("idle")
	
	# Only do actions if boss can move
	if not Global.boss2_move:
		return
	
	# Check if should reposition
	if reposition_timer <= 0.0 and fly_positions.size() > 0:
		if randf() < reposition_chance:
			change_state(BossState.REPOSITIONING)
			return
		else:
			# Stay but reset timer
			reposition_timer = randf_range(min_reposition_time, max_reposition_time)
	
	# Check if can attack
	if attack_cooldown_timer <= 0.0:
		change_state(BossState.CHARGING)

# ============================================================
# STATE: CHARGING
# ============================================================
func process_charging_state(delta: float) -> void:
	"""Preparing to fire"""
	if animated_sprite and animated_sprite.animation != "charge_bullet":
		animated_sprite.play("charge_bullet")
		bullets_fired_this_attack = 0
		is_firing_sequence = false
		
		# SOUND: Charging attack
		play_charge_sound()
	
	# Animation will trigger bullet spawn via signal

# ============================================================
# STATE: ATTACKING
# ============================================================
func process_attacking_state(delta: float) -> void:
	"""Firing bullet sequence"""
	if not is_firing_sequence:
		return
	
	bullet_delay_timer -= delta
	
	if bullet_delay_timer <= 0.0 and bullets_fired_this_attack < get_current_bullets_per_attack():
		spawn_bullet()
		bullets_fired_this_attack += 1
		bullet_delay_timer = get_current_bullet_delay()
	
	# Finished firing all bullets
	if bullets_fired_this_attack >= get_current_bullets_per_attack():
		is_firing_sequence = false
		attack_cooldown_timer = get_current_attack_cooldown()
		change_state(BossState.IDLE)

# ============================================================
# STATE: REPOSITIONING
# ============================================================
func process_repositioning_state(delta: float) -> void:
	"""Flying to new position"""
	# Check if movement is allowed
	if not Global.boss2_move:
		is_repositioning = false
		is_going_to_phase_end = false
		velocity = Vector2.ZERO
		change_state(BossState.IDLE)
		return
	
	if not is_repositioning:
		# Just entered state - choose position if not going to phase end
		if not is_going_to_phase_end:
			choose_random_position()
		is_repositioning = true
		
		# SOUND: Starting reposition
		play_reposition_sound()
	
	# Move towards target
	var direction = (target_position - global_position).normalized()
	velocity = direction * reposition_speed
	
	# Check if reached target
	if global_position.distance_to(target_position) < 10.0:
		global_position = target_position
		base_y_position = target_position.y
		is_repositioning = false
		is_going_to_phase_end = false
		velocity = Vector2.ZERO
		reposition_timer = randf_range(min_reposition_time, max_reposition_time)
		change_state(BossState.IDLE)

func choose_random_position() -> void:
	"""Choose a new random fly position"""
	if fly_positions.size() == 0:
		return
	
	# Choose different position
	var new_index = current_position_index
	if fly_positions.size() > 1:
		while new_index == current_position_index:
			new_index = randi() % fly_positions.size()
	else:
		new_index = 0
	
	current_position_index = new_index
	target_position = fly_positions[new_index].global_position
	
	print("🎯 Flying to position ", new_index, ": ", target_position)

# ============================================================
# STATE: HURT
# ============================================================
func process_hurt_state(delta: float) -> void:
	"""Temporary hurt reaction - waits for hit animation to complete"""
	# Wait for hit animation to finish
	if is_hit_animation_playing:
		# Still playing, keep waiting
		return
	
	# Animation finished, return to previous state
	print("✅ Hit animation complete, returning to ", BossState.keys()[previous_state])
	change_state(previous_state if previous_state != BossState.HURT else BossState.IDLE)

# ============================================================
# STATE: DYING
# ============================================================
func process_dying_state(delta: float) -> void:
	"""Death sequence"""
	if animated_sprite and animated_sprite.animation != "die":
		animated_sprite.play("die")
	
	# Wait for death animation
	if not animated_sprite.is_playing():
		change_state(BossState.DEAD)
		queue_free()

# ============================================================
# STATE MANAGEMENT
# ============================================================
func change_state(new_state: BossState) -> void:
	"""Transition to new state"""
	if current_state == new_state:
		return
	
	# Exit current state
	exit_state(current_state)
	
	previous_state = current_state
	current_state = new_state
	state_timer = 0.0
	
	# Enter new state
	enter_state(new_state)
	
	print("🔄 State: ", BossState.keys()[previous_state], " → ", BossState.keys()[current_state])

func enter_state(state: BossState) -> void:
	"""Called when entering a state"""
	match state:
		BossState.REPOSITIONING:
			is_repositioning = false
		BossState.HURT:
			is_hit_animation_playing = false

func exit_state(state: BossState) -> void:
	"""Called when exiting a state"""
	pass

# ============================================================
# ANIMATION CALLBACKS
# ============================================================
func _on_animation_frame_changed() -> void:
	"""Called when animation frame changes"""
	if not animated_sprite:
		return
	
	# Spawn bullet on frame 40 of charge_bullet animation
	if animated_sprite.animation == "charge_bullet" and animated_sprite.frame == 40:
		if current_state == BossState.CHARGING:
			# Start firing sequence
			change_state(BossState.ATTACKING)
			is_firing_sequence = true
			bullets_fired_this_attack = 0
			bullet_delay_timer = 0.0

func _on_animation_finished() -> void:
	"""Called when any animation finishes"""
	if not animated_sprite:
		return
	
	print("🎬 Animation finished: ", animated_sprite.animation)
	
	# Handle hit animation completion
	if animated_sprite.animation == "hit":
		is_hit_animation_playing = false
		print("✅ Hit animation completed!")

# ============================================================
# BULLET SPAWNING
# ============================================================
func spawn_bullet() -> void:
	"""Spawn a single bullet"""
	if not bullet_scene or not bullet_spawn_marker:
		print("❌ Cannot spawn bullet: Missing scene or marker!")
		return
	
	# SOUND: Shoot bullet
	play_shoot_sound()
	
	var bullet = bullet_scene.instantiate()
	
	# Calculate bullet direction with spread
	var total_bullets = get_current_bullets_per_attack()
	var spread_angle_deg = 0.0
	
	if total_bullets > 1:
		# Calculate spread for this bullet
		var half_bullets = (total_bullets - 1) / 2.0
		var bullet_offset = bullets_fired_this_attack - half_bullets
		spread_angle_deg = bullet_offset * bullet_spread_angle
	
	# Convert to radians and apply to base direction
	var spread_angle_rad = deg_to_rad(spread_angle_deg)
	var rotated_direction = bullet_base_direction.rotated(spread_angle_rad)
	
	# Get player direction for aiming
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var to_player = (player.global_position - bullet_spawn_marker.global_position).normalized()
		rotated_direction = to_player.rotated(spread_angle_rad)
	
	# Setup bullet
	bullet.global_position = bullet_spawn_marker.global_position
	
	# Set direction (bullet script has this)
	if "direction" in bullet:
		bullet.direction = rotated_direction
	
	# Set team (bullet script has this)
	if "team" in bullet:
		bullet.team = "enemy"
	
	get_parent().add_child(bullet)
	
	print("🔫 Bullet ", bullets_fired_this_attack + 1, "/", total_bullets, " | Angle: ", spread_angle_deg, "°")

# ============================================================
# DAMAGE SYSTEM
# ============================================================
func take_damage(amount: int) -> void:
	"""Boss takes damage"""
	if current_state == BossState.DYING or current_state == BossState.DEAD:
		return
	
	# SOUND: Hit sound
	play_hit_sound()
	
	# Update global health
	Global.boss2_health -= amount
	Global.boss2_health = max(0, Global.boss2_health)
	
	print("💔 Boss hit! HP: ", Global.boss2_health, "/", max_health, " (-", amount, ")")
	
	# Visual feedback
	flash_sprite(Color.WHITE, hit_flash_duration)
	trigger_camera_shake(hit_shake_intensity, hit_shake_duration)
	trigger_freeze_frame(hurt_freeze_duration)
	
	# State change
	if Global.boss2_health <= 0:
		on_death()
	else:
		# Play hit animation and enter HURT state
		if current_state != BossState.HURT:
			change_state(BossState.HURT)
			if animated_sprite:
				is_hit_animation_playing = true
				animated_sprite.play("hit")
				print("🎬 Playing hit animation...")

func on_death() -> void:
	"""Boss death"""
	print("💀 BOSS DEFEATED!")
	
	# SOUND: Death sound
	play_death_sound()
	
	# Epic death effects
	trigger_camera_shake(death_shake_intensity, death_shake_duration)
	spawn_death_particles()
	
	change_state(BossState.DYING)

# ============================================================
# VISUAL EFFECTS
# ============================================================
func trigger_camera_shake(intensity: float, duration: float) -> void:
	"""Trigger screen shake using the room camera"""
	# Try to get camera if we don't have it
	if not room_camera:
		room_camera = get_tree().get_first_node_in_group("room_camera")
	
	# Call camera's screen_shake method
	if room_camera and room_camera.has_method("screen_shake"):
		room_camera.screen_shake(intensity, duration)
		print("📳 Screen shake: intensity=", intensity, " duration=", duration)
	else:
		print("⚠️ Could not trigger screen shake - camera not found")

func flash_sprite(color: Color, duration: float) -> void:
	"""Flash sprite with color"""
	if not animated_sprite:
		return
	
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", color, duration * 0.3)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, duration * 0.7)

func trigger_freeze_frame(duration: float) -> void:
	"""Freeze game briefly"""
	get_tree().paused = true
	await get_tree().create_timer(duration, true, false, true).timeout
	get_tree().paused = false

func spawn_phase_particles() -> void:
	"""Particles for phase transition"""
	var particles = CPUParticles2D.new()
	particles.global_position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 50
	particles.lifetime = 1.0
	particles.explosiveness = 1.0
	particles.direction = Vector2.ZERO
	particles.spread = 180
	particles.initial_velocity_min = 200
	particles.initial_velocity_max = 400
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	particles.color = Color.RED
	
	get_parent().add_child(particles)
	get_tree().create_timer(1.5).timeout.connect(particles.queue_free)

func spawn_death_particles() -> void:
	"""Epic death explosion"""
	var particles = CPUParticles2D.new()
	particles.global_position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 100
	particles.lifetime = 2.0
	particles.explosiveness = 1.0
	particles.direction = Vector2.ZERO
	particles.spread = 180
	particles.initial_velocity_min = 300
	particles.initial_velocity_max = 600
	particles.gravity = Vector2(0, 400)
	particles.scale_amount_min = 6.0
	particles.scale_amount_max = 12.0
	particles.color = Color.ORANGE_RED
	
	get_parent().add_child(particles)
	get_tree().create_timer(2.5).timeout.connect(particles.queue_free)
