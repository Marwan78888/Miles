extends CharacterBody2D
class_name Player

# ============================================================
# MOVEMENT PARAMETERS
# ============================================================
@export_group("Death Settings")
@export var max_lives: int = 3
@export var game_over_position: Vector2 = Vector2(0, 0)  # Set from inspector
@export var death_movement_delay: float = 1.0
@export var death_respawn_delay: float = 0.17
@export var respawn_invulnerability_time: float = 0.5  # Increased for safety

# Death state tracking
var current_lives: int = 3
var is_game_over: bool = false
var is_dying: bool = false  # Changed from is_death to match death trigger
var is_movement_disabled: bool = false
var movement_disable_timer: float = 0.0
var is_respawn_invulnerable: bool = false
var respawn_invulnerability_timer: float = 0.0
var backward_end: bool = false

@export_group("Boss Heart System")
@export var boss_heart_system_enabled = Global.boss_heart_system
@export var boss_invulnerability_time: float = 1.0  # Longer invulnerability during boss fights
@export var boss_damage_flash_color: Color = Color.WHITE
@export var boss_damage_flash_duration: float = 0.1
@export var boss_damage_flash_count: int = 3  # Number of flashes

var is_boss_invulnerable: bool = false
var boss_invulnerability_timer: float = 0.0
var is_flashing: bool = false


@export_group("Movement")
@export_range(50, 200, 1) var max_speed: float = 74
@export_range(100, 2000, 10) var ground_acceleration: float = 1200.0
@export_range(100, 2000, 10) var ground_friction: float = 1400.0
@export_range(100, 2000, 10) var air_acceleration: float = 800.0
@export_range(100, 2000, 10) var air_friction: float = 600.0
@export_range(0, 2, 0.1) var air_direction_change_multiplier: float = 1.3

# ============================================================
# NORMAL DASH PARAMETERS
# ============================================================
@export_group("Normal Dash")
@export var dash_enabled: bool = true
@export_range(150, 400, 5) var dash_speed: float = 240.0
@export_range(0.05, 0.3, 0.01) var dash_duration: float = 0.15
@export_range(0.0, 0.1, 0.01) var dash_freeze_frames: float = 0.05
@export_range(0.0, 1.0, 0.05) var dash_cooldown: float = 0.2
@export_range(1, 2, 1) var max_dashes: int = 1
@export_range(0, 200, 5) var dash_end_speed: float = 160.0

# ============================================================
# WALL DASH PARAMETERS (SEPARATE SYSTEM)
# ============================================================
@export_group("Wall Dash")
@export_range(200, 500, 1) var wall_dash_speed: float = 300.0
@export_range(0.1, 0.5, 0.005) var wall_dash_duration: float = 0.14
@export_range(0.0, 0.15, 0.01) var wall_dash_freeze_frames: float = 0.08
@export_range(0, 100, 5) var wall_detection_distance: float = 40.0
@export_range(0.0, 1.0, 0.05) var wall_dash_cooldown: float = 0.3
@export var wall_dash_refills_normal_dash: bool = true

# ============================================================
# WALL DASH TRAIL PARAMETERS
# ============================================================
@export_group("Wall Dash Trails")
@export var wall_dash_trail_colors: Array[Color] = [
	Color(1.0, 0.2, 0.8, 0.95),
	Color(0.8, 0.0, 1.0, 0.9),
	Color(1.0, 0.4, 0.6, 0.85),
	Color(0.9, 0.1, 0.9, 0.8)
]
@export_range(0.2, 2.0, 0.1) var wall_dash_trail_lifetime: float = 0.8
@export_range(0.01, 0.1, 0.01) var wall_dash_trail_spawn_interval: float = 0.03
@export_range(0.5, 1.5, 0.1) var wall_dash_trail_scale: float = 1.0
@export_range(0.1, 1.0, 0.05) var wall_dash_trail_fade_duration: float = 0.4

# ============================================================
# NORMAL DASH TRAIL PARAMETERS
# ============================================================
@export_group("Normal Dash Trail")
@export var normal_trail_colors: Array[Color] = [
	Color(0.4, 0.7, 1.0, 0.9),
	Color(0.6, 0.3, 1.0, 0.8),
	Color(1.0, 0.5, 0.8, 0.7),
	Color(0.3, 1.0, 0.9, 0.6)
]
@export_range(0.1, 1.0, 0.05) var normal_trail_lifetime: float = 0.5
@export_range(0.01, 0.1, 0.01) var normal_trail_spawn_interval: float = 0.02
@export_range(0.5, 1.5, 0.1) var normal_trail_scale: float = 0.9
@export var dash_trails_enabled: bool = true

# ============================================================
# DASH MOMENTUM TECH
# ============================================================
@export_group("Dash Tech")
@export var momentum_tech_enabled: bool = true
@export_range(1.0, 1.5, 0.05) var ultra_speed_multiplier: float = 1.2
@export_range(200, 350, 5) var dash_jump_speed: float = 260.0
@export_range(250, 400, 5) var hyper_dash_speed: float = 325.0
@export var preserve_diagonal_momentum: bool = true

# ============================================================
# JUMP PARAMETERS
# ============================================================
@export_group("Jump")
@export_range(-400, -100, 5) var jump_velocity: float = -270.0
@export_range(0.3, 0.7, 0.05) var jump_cut_multiplier: float = 0.3
@export_range(1, 3, 1) var max_jumps: int = 1
@export_range(0.7, 1.2, 0.05) var double_jump_multiplier: float = 0.95
@export_range(0.3, 2.0, 0.05) var jump_floatiness: float = 1.0

@export_range(0.5, 1.5, 0.05) var jump_rise_gravity_scale: float = 0.85  # Floaty on way up
@export_range(0.0, 0.5, 0.05) var jump_apex_gravity_scale: float = 0.3   # Very floaty at peak
@export_range(50, 150, 5) var apex_detection_threshold: float = 80.0     # When to apply apex float

# Add this after your "Visual Feedback" export group (around line 160)
@export_group("Parry System")
@export var parry_enabled: bool = true
@export_range(0.0, 0.5, 0.01) var parry_window_duration: float = 0.2  # How long parry window stays active
@export_range(0.0, 1.0, 0.05) var parry_cooldown: float = 0.3  # Cooldown between parries
@export_range(0.0, 0.2, 0.01) var parry_freeze_duration: float = 0.08
@export_range(0.0, 10.0, 0.5) var parry_screen_shake_intensity: float = 3.0
@export_range(0.0, 0.3, 0.01) var parry_screen_shake_duration: float = 0.15
@export_range(1.0, 2.0, 0.1) var parry_reflection_speed_multiplier: float = 1.3  # Reflect bullets faster
@export var parry_particles: GPUParticles2D = null # Optional parry particle effect

# ============================================================
# WALL SLIDE PARAMETERS
# ============================================================
@export_group("Wall Slide")
@export var wall_slide_enabled: bool = true
@export_range(10, 100, 5) var wall_slide_speed: float = 40.0
@export_range(100, 400, 10) var wall_jump_force: float = 200
@export_range(-300, -100, 5) var wall_jump_vertical_force: float = -180
@export_range(0.3, 1.0, 0.05) var wall_jump_gravity_multiplier: float = 0.6
@export_range(0.0, 0.5, 0.05) var wall_jump_float_time: float = 0.3
@export_range(0.0, 1.0, 0.05) var wall_jump_cooldown: float = 0.15
@export_range(0.0, 0.3, 0.01) var wall_coyote_time: float = 0.12
@export_range(0.0, 0.2, 0.01) var sticky_wall_time: float = 0.08
@export var wall_jump_variable_height: bool = true 
@export_range(0.3, 0.7, 0.05) var wall_jump_cut_multiplier: float = 0.4

# ============================================================
# GRAVITY & FALL PARAMETERS
# ============================================================
@export_group("Gravity")
@export_range(500, 1500, 10) var gravity: float = 980.0
@export_range(0.8, 2.0, 0.1) var fall_gravity_multiplier: float = 1.3
@export_range(200, 600, 10) var max_fall_speed: float = 240
@export_range(0.0, 1.0, 0.05) var apex_gravity_multiplier: float = 0.45
@export_range(10, 100, 5) var apex_threshold: float = 100.0

# ============================================================
# GAME FEEL PARAMETERS
# ============================================================
@export_group("Game Feel")
@export_range(0.0, 0.3, 0.01) var coyote_time: float = 0.14
@export_range(0.0, 0.3, 0.01) var jump_buffer_time: float = 0.12
@export_range(0, 100, 5) var terminal_velocity_grace: float = 50.0
@export_range(0.0, 1.0, 0.05) var landing_momentum_retention: float = 0.85
@export_range(100, 400, 10) var hard_landing_threshold: float = 280.0

# ============================================================
# VISUAL FEEDBACK
# ============================================================
@export_group("Visual Feedback")
@export var particles_enabled: bool = true
@export var screen_shake_enabled: bool = false
@export_range(0.0, 0.5, 0.05) var squash_amount: float = 0.5

# ============================================================
# PARTICLE NODES
# ============================================================
@export_group("Particle Nodes")
@export var dash_trail_particles: GPUParticles2D = null
@export var jump_particles: GPUParticles2D = null
@export var landing_particles: GPUParticles2D = null
@export var dash_particles: GPUParticles2D = null
@export var wall_dash_particles: GPUParticles2D = null

@export_group("Sounds")
@export var moving_sounds: Array[AudioStream] = []
@export var jumping_sounds: Array[AudioStream] = []
@export var sliding_sounds: Array[AudioStream] = []
@export var wall_jump_sounds: Array[AudioStream] = []
@export var dash_sounds: Array[AudioStream] = []
@export var landing_sounds: Array[AudioStream] = []
@export var hard_landing_sounds: Array[AudioStream] = []
@export var wall_dash_sounds: Array[AudioStream] = []
@export var parry_sounds: Array[AudioStream] = []

# Sound state tracking
var last_moving_sound_index: int = -1
var last_jumping_sound_index: int = -1
var last_sliding_sound_index: int = -1
var last_wall_jump_sound_index: int = -1
var last_dash_sound_index: int = -1
var last_wall_dash_sound_index: int = -1
var last_landing_sound_index: int = -1
var last_hard_landing_sound_index: int = -1
var last_parry_sound_index: int = -1


# Audio player nodes
var audio_player_movement: AudioStreamPlayer2D
var audio_player_action: AudioStreamPlayer2D
var audio_player_slide: AudioStreamPlayer2D

# ============================================================
# STATE
# ============================================================
enum State {IDLE, WALK, RUN, JUMP, FALL, WALL_SLIDE, LANDING, DASHING, WALL_DASHING}
var current_state: State = State.IDLE
var previous_state: State = State.IDLE


# ============================================================
# PARRY STATE
# ============================================================
var parry_freeze_timer: float = 0.0
var is_parry_active: bool = false  # Is parry window currently active?
var parry_window_timer: float = 0.0  # How long parry window has been active
var parry_cooldown_timer: float = 0.0  # Cooldown between parries
var hit_button_pressed: bool = false  # Cache hit input


# ============================================================
# NORMAL DASH STATE
# ============================================================
var dashes_remaining: int = 1
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var dash_cooldown_timer: float = 0.0
var freeze_timer: float = 0.0
var was_dashing: bool = false
var dash_input_buffered: bool = false
var dash_buffer_timer: float = 0.0

# ============================================================
# WALL DASH STATE (SEPARATE SYSTEM)
# ============================================================
var is_wall_dashing: bool = false
var wall_dash_timer: float = 0.0
var wall_dash_direction: Vector2 = Vector2.ZERO
var wall_dash_cooldown_timer: float = 0.0
var wall_dash_freeze_timer: float = 0.0
var wall_dash_entry_position: Vector2 = Vector2.ZERO
var was_wall_dashing: bool = false
var has_exited_wall: bool = false
var is_pushing_out: bool = false
var push_out_direction: Vector2 = Vector2.ZERO
var is_emergency_wall_dash: bool = false  # Flag for auto wall dash to escape
var is_playing_wall_dash_animation: bool = false
var wall_dash_animation_override: bool = false

# ============================================================
# COLLISION STATE
# ============================================================
var original_collision_layer: int = 0
var original_collision_mask: int = 0
var collision_disabled: bool = false

# ============================================================
# NORMAL DASH TRAIL STATE
# ============================================================
var normal_trail_spawn_timer: float = 0.0
var active_normal_trails: Array = []

# ============================================================
# WALL DASH TRAIL STATE
# ============================================================
var wall_dash_trail_spawn_timer: float = 0.0
var active_wall_dash_trails: Array = []

# ============================================================
# WALL JUMP STATE
# ============================================================
var wall_jump_cooldown_timer: float = 0.0
var wall_coyote_timer: float = 0.0
var was_on_wall: bool = false
var wall_jump_float_timer: float = 0.0
var sticky_wall_timer: float = 0.0
var last_wall_side: int = 0
var is_in_wall_jump: bool = false
# ============================================================
# MOMENTUM TRACKING
# ============================================================
var horizontal_speed_before_dash: float = 0.0
var performed_dash_jump: bool = false
var is_crouching: bool = false

# ============================================================
# INTERNAL TIMERS & COUNTERS
# ============================================================
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var landing_timer: float = 0.0
var jumps_remaining: int = 1
var was_on_floor: bool = false
var last_wall_normal: Vector2 = Vector2.ZERO

# ============================================================
# INPUT CACHE
# ============================================================
var input_direction: float = 0.0
var input_vector: Vector2 = Vector2.ZERO
var jump_pressed: bool = false
var jump_released: bool = false
var dash_pressed: bool = false
var crouch_pressed: bool = false

# ============================================================
# PHYSICS TRACKING
# ============================================================
var last_velocity: Vector2 = Vector2.ZERO
var fall_from_y: float = 0.0
var is_at_apex: bool = false

# ============================================================
# WALL DETECTION
# ============================================================
var wall_raycast_right: RayCast2D
var wall_raycast_left: RayCast2D

# ============================================================
# NODES
# ============================================================
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var parry_area : Area2D = $ParryArea
# ============================================================
# MOVEMENT CHECK
# ============================================================
func can_player_move() -> bool:
	"""Check if player is allowed to move based on Global flag"""
	if not Global._can_move_flag:
		return true
	
	return Global._can_move

# ============================================================
# READY
# ============================================================
func _ready() -> void:
	setup_audio_players()
	floor_snap_length = 6.0
	floor_max_angle = deg_to_rad(45)
	floor_stop_on_slope = true
	
	# Save original collision
	original_collision_layer = collision_layer
	original_collision_mask = collision_mask
	
	# Setup wall detection raycasts
	setup_wall_detection()
	
	if parry_enabled:
		setup_parry_area()
	
	if sprite and sprite.sprite_frames:
		sprite.play("idle")
	
	jumps_remaining = max_jumps
	dashes_remaining = max_dashes
	
	# Initialize lives
	current_lives = max_lives
	is_game_over = false
	
	# Initialize trail colors (rest of your code...)
	if normal_trail_colors.is_empty():
		normal_trail_colors = [
			Color(0.4, 0.7, 1.0, 0.9),
			Color(0.6, 0.3, 1.0, 0.8),
			Color(1.0, 0.5, 0.8, 0.7),
			Color(0.3, 1.0, 0.9, 0.6)
		]
	
	if wall_dash_trail_colors.is_empty():
		wall_dash_trail_colors = [
			Color(1.0, 0.2, 0.8, 0.95),
			Color(0.8, 0.0, 1.0, 0.9),
			Color(1.0, 0.4, 0.6, 0.85),
			Color(0.9, 0.1, 0.9, 0.8)
		]

# ============================================================
# SETUP WALL DETECTION
# ============================================================
func setup_wall_detection() -> void:
	# Create right raycast
	wall_raycast_right = RayCast2D.new()
	wall_raycast_right.enabled = true
	wall_raycast_right.target_position = Vector2(wall_detection_distance, 0)
	wall_raycast_right.collision_mask = 1  # Adjust to your wall layer
	add_child(wall_raycast_right)
	
	# Create left raycast
	wall_raycast_left = RayCast2D.new()
	wall_raycast_left.enabled = true
	wall_raycast_left.target_position = Vector2(-wall_detection_distance, 0)
	wall_raycast_left.collision_mask = 1  # Adjust to your wall layer
	add_child(wall_raycast_left)
	

# ============================================================
# PHYSICS PROCESS
# ============================================================
func _physics_process(delta: float) -> void:
	# Check if player can move (death timers updated in update_all_timers)
	update_death_timers(delta)
	update_parry_visual()
	# Check if player can move
	if not Global._can_move_flag or is_movement_disabled or is_dying:
		velocity = Vector2.ZERO
		$AnimatedSprite2D.play("idle")
		update_all_timers(delta)  # Still update other timers
		return
	
	# Handle freeze frames
	if freeze_timer > 0.0 or wall_dash_freeze_timer > 0.0 or parry_freeze_timer > 0.0:
		freeze_timer = max(0.0, freeze_timer - delta)
		wall_dash_freeze_timer = max(0.0, wall_dash_freeze_timer - delta)
		parry_freeze_timer = max(0.0, parry_freeze_timer - delta)
		if freeze_timer > 0.0 or wall_dash_freeze_timer > 0.0 or parry_freeze_timer > 0.0:
			return
	
	if current_lives == 3:
		%Heart1.show()
		%Heart2.show()
		%Heart3.show()
	if current_lives == 2:
		%Heart1.hide()
		%Heart2.show()
		%Heart3.show()
	if current_lives == 1:
		%Heart1.hide()
		%Heart2.hide()
		%Heart3.show()
	
	last_velocity = velocity
	cache_input()
	update_all_timers(delta)
	
	# Update trails
	update_normal_trails(delta)
	update_wall_dash_trails(delta)
	
	# Handle wall slide (only when not wall dashing)
	if wall_slide_enabled and not is_wall_dashing and not collision_disabled:
		handle_wall_slide()
		update_wall_coyote_time(delta)
	
	if is_pushing_out:
		handle_push_out_from_wall(delta)
	# Handle wall dashing
	elif is_wall_dashing:
		handle_wall_dash_movement(delta)
	# Handle normal dashing
	elif is_dashing:
		handle_normal_dash_movement(delta)
	# Normal movement
	else:
		apply_gravity(delta)
		handle_jump()
		handle_horizontal_movement(delta)
	
	# Try to start dash (wall dash takes priority)
	if not is_wall_dashing and not is_dashing:
		handle_dash_input()
		
	if parry_enabled:
		handle_parry_input()
	
	update_state()
	animate()
	apply_visual_effects(delta)
	
	var was_in_air: bool = not is_on_floor()
	move_and_slide()
	
	# Check if exited wall during wall dash
	if is_wall_dashing and collision_disabled:
		check_wall_exit()
	
	if was_in_air and is_on_floor():
		on_landed()
	
	if was_on_floor and not is_on_floor():
		fall_from_y = global_position.y
	
	was_on_floor = is_on_floor()
	was_dashing = is_dashing
	was_wall_dashing = is_wall_dashing
	was_on_wall = is_on_wall_slide()
# ============================================================
# INPUT
# ============================================================
func cache_input() -> void:
	input_direction = Input.get_axis("move_left", "move_right")
	
	var input_x = Input.get_axis("move_left", "move_right")
	var input_y = Input.get_axis("move_up", "move_down")
	input_vector = Vector2(input_x, input_y).normalized()
	
	jump_pressed = Input.is_action_just_pressed("jump")
	jump_released = Input.is_action_just_released("jump")
	dash_pressed = Input.is_action_just_pressed("dash")
	crouch_pressed = Input.is_action_pressed("ui_down")
	hit_button_pressed = Input.is_action_just_pressed("hit")  # <-- ADD THIS LINE
# ============================================================
# TIMERS
# ============================================================
func update_all_timers(delta: float) -> void:
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
	
	if wall_dash_cooldown_timer > 0.0:
		wall_dash_cooldown_timer -= delta
	
	if wall_jump_cooldown_timer > 0.0:
		wall_jump_cooldown_timer -= delta
	
	if parry_window_timer > 0.0:
		parry_window_timer -= delta
		if parry_window_timer <= 0.0:
			is_parry_active = false
	
	if parry_cooldown_timer > 0.0:
		parry_cooldown_timer -= delta
	
	# ✅ ADD BOSS INVULNERABILITY TIMER
	if boss_invulnerability_timer > 0.0:
		boss_invulnerability_timer -= delta
		if boss_invulnerability_timer <= 0.0:
			is_boss_invulnerable = false
			print("🛡️ Boss invulnerability ended")
	
	# Rest of your existing timers...
	if wall_jump_float_timer > 0.0:
		wall_jump_float_timer -= delta
	
	if sticky_wall_timer > 0.0:
		sticky_wall_timer -= delta
	
	if dash_buffer_timer > 0.0:
		dash_buffer_timer -= delta
	
	if normal_trail_spawn_timer > 0.0:
		normal_trail_spawn_timer -= delta
	
	if wall_dash_trail_spawn_timer > 0.0:
		wall_dash_trail_spawn_timer -= delta
	
	if is_on_floor():
		coyote_timer = coyote_time
		jumps_remaining = max_jumps
		if not is_dashing and not is_wall_dashing:
			dashes_remaining = max_dashes
			is_in_wall_jump = false
	else:
		coyote_timer -= delta
	
	if jump_pressed:
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta
	
	if landing_timer > 0.0:
		landing_timer -= delta


# ============================================================
# WALL DETECTION
# ============================================================
func is_near_wall() -> bool:
	if not wall_raycast_right or not wall_raycast_left:
		return false
	
	return wall_raycast_right.is_colliding() or wall_raycast_left.is_colliding()

func get_wall_dash_direction() -> Vector2:
	"""Determine wall dash direction based on input and wall position"""
	var dash_dir: Vector2 = Vector2.ZERO
	
	# If player has directional input, use it
	if input_vector.length() > 0.1:
		dash_dir = input_vector.normalized()
	else:
		# Otherwise, dash toward the wall
		if wall_raycast_right.is_colliding():
			dash_dir = Vector2.RIGHT
		elif wall_raycast_left.is_colliding():
			dash_dir = Vector2.LEFT
		else:
			# Fallback to facing direction
			var facing_x: float = 1.0
			if sprite:
				facing_x = -1.0 if sprite.flip_h else 1.0
			dash_dir = Vector2(facing_x, 0)
	
	return dash_dir.normalized()

# ============================================================
# DASH INPUT HANDLER
# ============================================================
func handle_dash_input() -> void:
	if dash_pressed:
		dash_input_buffered = true
		dash_buffer_timer = 0.08
	
	if not dash_input_buffered:
		return
	
	# Check for WALL DASH first (PRIORITY)
	var can_wall_dash: bool = check_can_wall_dash()
	
	if can_wall_dash:
		start_wall_dash()
		return
	
	# Otherwise, try normal dash
	var can_normal_dash = dash_enabled and dashes_remaining > 0 and dash_cooldown_timer <= 0.0
	
	if can_normal_dash:
		start_normal_dash()

# ============================================================
# CHECK WALL DASH AVAILABILITY
# ============================================================
func check_can_wall_dash() -> bool:
	# Check Global flag
	if not Global._can_wall_dash_flag:
		return false
	
	if not Global._can_wall_dash_flag:
		return false
	
	# Check cooldown
	if wall_dash_cooldown_timer > 0.0:
		return false
	
	# Check if near wall
	if not is_near_wall():
		return false
	
	return true

# ============================================================
# WALL DASH START
# ============================================================
func start_wall_dash() -> void:
	# Get dash direction
	wall_dash_direction = get_wall_dash_direction()
	
	# Start wall dash
	is_wall_dashing = true
	wall_dash_timer = wall_dash_duration
	dash_input_buffered = false
	dash_buffer_timer = 0.0
	
	# Store entry position
	wall_dash_entry_position = global_position
	has_exited_wall = false
	
	# Disable collision
	disable_collision()
	
	# Freeze frame
	wall_dash_freeze_timer = wall_dash_freeze_frames
	
	# Set velocity
	velocity = wall_dash_direction * wall_dash_speed
	
	# SCREEN SHAKE FOR WALL DASH (MORE INTENSE)
	trigger_screen_shake(5.0, 0.2)
	
	# Visual feedback
	spawn_wall_dash_particles()
	wall_dash_trail_spawn_timer = 0.0
	play_wall_dash_sound()
	
	# ✨ NEW: Play wall dash animation ONCE and wait for it to finish
	play_wall_dash_animation_once()

func play_wall_dash_animation_once() -> void:
	"""Play wall_dash animation once without interruption"""
	if not sprite or not sprite.sprite_frames:
		return
	
	# Check if wall_dash animation exists
	if not sprite.sprite_frames.has_animation("wall_dash"):
		print("⚠️ wall_dash animation not found!")
		return
	
	# Set flags to prevent animation override
	is_playing_wall_dash_animation = true
	wall_dash_animation_override = true
	
	# Play the animation
	sprite.play("wall_dash")
	
	# Connect to animation_finished signal
	if not sprite.animation_finished.is_connected(_on_wall_dash_animation_finished):
		sprite.animation_finished.connect(_on_wall_dash_animation_finished)
	
	print("▶️ Playing wall_dash animation")

# ============================================================
# ADD THIS NEW CALLBACK FUNCTION
# ============================================================
func _on_wall_dash_animation_finished() -> void:
	"""Called when wall_dash animation finishes playing"""
	# Only handle if it was the wall_dash animation
	if sprite.animation == "wall_dash":
		print("✅ wall_dash animation finished")
		is_playing_wall_dash_animation = false
		wall_dash_animation_override = false
		
		# Disconnect signal to prevent issues
		if sprite.animation_finished.is_connected(_on_wall_dash_animation_finished):
			sprite.animation_finished.disconnect(_on_wall_dash_animation_finished)

# ============================================================
# NORMAL DASH START
# ============================================================
func start_normal_dash() -> void:
	var dash_dir: Vector2
	if input_vector.length() > 0.1:
		dash_dir = input_vector
	else:
		var facing_x: float = 1.0
		if sprite:
			facing_x = -1.0 if sprite.flip_h else 1.0
		dash_dir = Vector2(facing_x, 0)
	
	if dash_dir.length() == 0:
		dash_dir = Vector2.RIGHT
	
	dash_direction = dash_dir.normalized()
	
	is_dashing = true
	dash_timer = dash_duration
	dash_input_buffered = false
	dash_buffer_timer = 0.0
	dashes_remaining -= 1
	
	horizontal_speed_before_dash = abs(velocity.x)
	is_crouching = crouch_pressed
	
	freeze_timer = dash_freeze_frames
	velocity = dash_direction * dash_speed
	
	# SCREEN SHAKE FOR NORMAL DASH
	trigger_screen_shake(3.0, 0.15)
	
	spawn_dash_particles()
	normal_trail_spawn_timer = 0.0
	performed_dash_jump = false
	play_dash_sound()


# ============================================================
# WALL DASH MOVEMENT
# ============================================================
func handle_wall_dash_movement(delta: float) -> void:
	wall_dash_timer -= delta
	
	# EMERGENCY MODE: Check if we escaped the wall
	if is_emergency_wall_dash:
		# Check every frame if we're clear
		if not is_overlapping_wall():
			print("✅ Escaped wall! Emergency dash complete")
			# We're free! End emergency mode
			is_emergency_wall_dash = false
			is_wall_dashing = false
			finish_wall_dash_exit()
			return
	
	# Maintain velocity
	velocity = wall_dash_direction * wall_dash_speed
	
	# Spawn persistent trails
	if wall_dash_trail_spawn_timer <= 0.0:
		spawn_wall_dash_trail()
		wall_dash_trail_spawn_timer = wall_dash_trail_spawn_interval
	
	# End wall dash when timer expires
	if wall_dash_timer <= 0.0:
		end_wall_dash("Timer expired")

# ============================================================
# NORMAL DASH MOVEMENT
# ============================================================
func handle_normal_dash_movement(delta: float) -> void:
	dash_timer -= delta
	
	velocity = dash_direction * dash_speed
	
	if dash_trails_enabled and normal_trail_spawn_timer <= 0.0:
		spawn_normal_dash_trail()
		normal_trail_spawn_timer = normal_trail_spawn_interval
	
	if momentum_tech_enabled and jump_pressed and is_on_floor():
		perform_dash_jump()
		return
	
	if dash_timer <= 0.0:
		end_normal_dash()

func end_normal_dash() -> void:
	is_dashing = false
	dash_cooldown_timer = dash_cooldown
	
	if dash_direction.y >= 0 and abs(dash_direction.x) > 0.1:
		if preserve_diagonal_momentum and dash_direction.y > 0.5:
			pass
		else:
			velocity.x = sign(velocity.x) * dash_end_speed
	
	if abs(dash_direction.x) < 0.1:
		velocity.y = 120.0 if dash_direction.y > 0 else velocity.y

func perform_dash_jump() -> void:
	performed_dash_jump = true
	is_dashing = false
	dash_cooldown_timer = dash_cooldown
	
	var jump_speed = hyper_dash_speed if is_crouching else dash_jump_speed
	velocity.x = sign(dash_direction.x) * jump_speed if abs(dash_direction.x) > 0.1 else velocity.x
	velocity.y = jump_velocity * 0.7
	
	jumps_remaining -= 1
	spawn_jump_particles()
	

# ============================================================
# COLLISION MANAGEMENT
# ============================================================
func disable_collision() -> void:
	collision_disabled = true
	collision_layer = 0
	collision_mask = 0

func restore_collision() -> void:
	collision_disabled = false
	collision_layer = original_collision_layer
	collision_mask = original_collision_mask

# ============================================================
# CHECK WALL EXIT
# ============================================================
func check_wall_exit() -> void:
	"""Check if player has exited the wall during wall dash"""
	
	# If we've already exited, don't check again
	if has_exited_wall:
		return
	
	# Calculate distance traveled
	var distance_traveled = global_position.distance_to(wall_dash_entry_position)
	
	# Check if we're no longer detecting a wall AND we've traveled some distance
	var no_wall_detected = not is_near_wall()
	var traveled_min_distance = distance_traveled > wall_detection_distance * 0.5
	
	if no_wall_detected and traveled_min_distance:
		has_exited_wall = true

# ============================================================
# END WALL DASH
# ============================================================
func end_wall_dash(reason: String = "") -> void:
	# Reset animation flags
	is_playing_wall_dash_animation = false
	wall_dash_animation_override = false
	
	# Disconnect animation signal if still connected
	if sprite and sprite.animation_finished.is_connected(_on_wall_dash_animation_finished):
		sprite.animation_finished.disconnect(_on_wall_dash_animation_finished)
	
	# Rest of your existing code...
	is_wall_dashing = false
	wall_dash_cooldown_timer = wall_dash_cooldown
	
	# Check if player is stuck in wall
	if is_overlapping_wall():
		start_emergency_wall_dash()
	else:
		finish_wall_dash_exit()
	

# ============================================================
# NORMAL DASH TRAIL SYSTEM
# ============================================================
func spawn_normal_dash_trail() -> void:
	if not sprite or not sprite.sprite_frames:
		return
	
	var current_texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if not current_texture:
		return
	
	var trail = Sprite2D.new()
	trail.texture = current_texture
	trail.global_position = global_position
	trail.flip_h = sprite.flip_h
	trail.scale = sprite.scale * normal_trail_scale
	
	var color_index = active_normal_trails.size() % normal_trail_colors.size()
	trail.modulate = normal_trail_colors[color_index]
	
	var trail_data = {
		"sprite": trail,
		"lifetime": normal_trail_lifetime,
		"initial_alpha": normal_trail_colors[color_index].a
	}
	
	active_normal_trails.append(trail_data)
	get_parent().add_child(trail)

func update_normal_trails(delta: float) -> void:
	var trails_to_remove = []
	
	for i in range(active_normal_trails.size()):
		var trail_data = active_normal_trails[i]
		trail_data.lifetime -= delta
		
		if trail_data.lifetime > 0:
			var fade_progress = trail_data.lifetime / normal_trail_lifetime
			var ease_fade = ease(fade_progress, -2.0)
			trail_data.sprite.modulate.a = trail_data.initial_alpha * ease_fade
		else:
			trails_to_remove.append(i)
	
	for i in range(trails_to_remove.size() - 1, -1, -1):
		var idx = trails_to_remove[i]
		var trail_data = active_normal_trails[idx]
		trail_data.sprite.queue_free()
		active_normal_trails.remove_at(idx)

# ============================================================
# WALL DASH TRAIL SYSTEM (PERSISTENT + TWEEN FADE)
# ============================================================
func spawn_wall_dash_trail() -> void:
	if not sprite or not sprite.sprite_frames:
		return
	
	var current_texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if not current_texture:
		return
	
	var trail = Sprite2D.new()
	trail.texture = current_texture
	trail.global_position = global_position
	trail.flip_h = sprite.flip_h
	trail.scale = sprite.scale * wall_dash_trail_scale
	
	var color_index = active_wall_dash_trails.size() % wall_dash_trail_colors.size()
	trail.modulate = wall_dash_trail_colors[color_index]
	
	# Create tween for fade out
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Delay before starting fade
	var fade_delay = wall_dash_trail_lifetime - wall_dash_trail_fade_duration
	
	# Fade out alpha
	tween.tween_property(
		trail, 
		"modulate:a", 
		0.0, 
		wall_dash_trail_fade_duration
	).set_delay(fade_delay)
	
	# Slight scale down
	tween.tween_property(
		trail, 
		"scale", 
		trail.scale * 0.8, 
		wall_dash_trail_fade_duration
	).set_delay(fade_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# Queue free after lifetime
	tween.tween_callback(trail.queue_free).set_delay(wall_dash_trail_lifetime)
	
	var trail_data = {
		"sprite": trail,
		"tween": tween,
		"lifetime": wall_dash_trail_lifetime,
		"creation_time": Time.get_ticks_msec() / 1000.0
	}
	
	active_wall_dash_trails.append(trail_data)
	get_parent().add_child(trail)
	

func update_wall_dash_trails(delta: float) -> void:
	"""Clean up finished trails"""
	var current_time = Time.get_ticks_msec() / 1000.0
	var trails_to_remove = []
	
	for i in range(active_wall_dash_trails.size()):
		var trail_data = active_wall_dash_trails[i]
		var elapsed = current_time - trail_data.creation_time
		
		if elapsed > trail_data.lifetime:
			trails_to_remove.append(i)
	
	for i in range(trails_to_remove.size() - 1, -1, -1):
		var idx = trails_to_remove[i]
		active_wall_dash_trails.remove_at(idx)

# ============================================================
# GRAVITY
# ============================================================
func apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = min(velocity.y, 50.0)  # Small grace for slopes
		return
	
	# Determine if at apex using velocity threshold
	var is_near_apex = abs(velocity.y) < apex_detection_threshold
	
	var gravity_multiplier: float = 1.0
	
	# Wall jump float takes priority
	if wall_jump_float_timer > 0.0:
		gravity_multiplier = wall_jump_gravity_multiplier
	
	# Rising (negative velocity)
	elif velocity.y < 0:
		if is_near_apex:
			# At apex: maximum floatiness
			gravity_multiplier = jump_apex_gravity_scale
		else:
			# Rising but not at apex: moderate floatiness
			gravity_multiplier = jump_rise_gravity_scale
	
	# Falling (positive velocity)
	else:
		gravity_multiplier = fall_gravity_multiplier
	
	# Apply gravity with multiplier
	velocity.y += gravity * gravity_multiplier * delta
	
	# Cap fall speed
	velocity.y = min(velocity.y, max_fall_speed)

# ============================================================
# WALL SLIDE
# ============================================================
func handle_wall_slide() -> void:
	if not wall_slide_enabled:
		return
	
	if is_on_wall_slide() and not is_on_floor() and input_direction != 0:
		var wall_normal := get_wall_normal()
		
		if wall_normal != Vector2.ZERO and input_direction != 0:
			if sign(input_direction) == -sign(wall_normal.x):
				velocity.y = min(velocity.y, wall_slide_speed)
				jumps_remaining = max_jumps
				last_wall_normal = wall_normal
				last_wall_side = int(-sign(wall_normal.x))
				
				if input_direction != 0 and sign(input_direction) != last_wall_side:
					if sticky_wall_timer <= 0.0:
						sticky_wall_timer = sticky_wall_time

func update_wall_coyote_time(delta: float) -> void:
	if is_on_wall_slide():
		wall_coyote_timer = wall_coyote_time
	else:
		wall_coyote_timer -= delta

func is_on_wall_slide() -> bool:
	return is_on_wall() and not is_on_floor()

# ============================================================
# JUMP
# ============================================================
func handle_jump() -> void:
	var can_ground_jump: bool = (is_on_floor() or coyote_timer > 0.0) and jumps_remaining > 0
	var can_wall_jump: bool = wall_slide_enabled and (is_on_wall_slide() or wall_coyote_timer > 0.0) and wall_jump_cooldown_timer <= 0.0
	var can_air_jump: bool = not is_on_floor() and jumps_remaining > 0 and coyote_timer <= 0.0 and wall_coyote_timer <= 0.0
	
	var should_jump: bool = jump_buffer_timer > 0.0
	
	if should_jump:
		if can_wall_jump:
			perform_wall_jump()
		elif can_ground_jump:
			perform_jump()
		elif can_air_jump:
			perform_air_jump()
	
	# CRITICAL: Variable jump height - handle both regular and wall jumps
	if jump_released and velocity.y < 0:
		# Wall jump variable height
		if is_in_wall_jump and wall_jump_variable_height:
			velocity.y *= wall_jump_cut_multiplier
			is_in_wall_jump = false  # Stop cutting after first release
		# Regular jump variable height (only when not in wall jump float)
		elif not is_in_wall_jump and wall_jump_float_timer <= 0.0:
			velocity.y *= jump_cut_multiplier

func perform_jump() -> void:
	velocity.y = jump_velocity  # Full jump power
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	jumps_remaining -= 1
	spawn_jump_particles()
	play_jumping_sound()

func perform_air_jump() -> void:
	velocity.y = jump_velocity * double_jump_multiplier
	jump_buffer_timer = 0.0
	jumps_remaining -= 1
	spawn_jump_particles()
	play_jumping_sound()

func perform_wall_jump() -> void:
	velocity.y = wall_jump_vertical_force
	
	var wall_dir: float = 1.0
	if is_on_wall_slide():
		var wall_normal := get_wall_normal()
		if wall_normal != Vector2.ZERO:
			wall_dir = wall_normal.x
	elif wall_coyote_timer > 0.0:
		wall_dir = -float(last_wall_side)
	
	velocity.x = wall_dir * wall_jump_force
	
	jump_buffer_timer = 0.0
	wall_coyote_timer = 0.0
	jumps_remaining = max_jumps - 1
	wall_jump_cooldown_timer = wall_jump_cooldown
	wall_jump_float_timer = wall_jump_float_time
	
	spawn_jump_particles()
	play_wall_jump_sound()

# ============================================================
# HORIZONTAL MOVEMENT
# ============================================================
func handle_horizontal_movement(delta: float) -> void:
	if sticky_wall_timer > 0.0:
		velocity.x = 0.0
		return
	
	var target_speed: float = input_direction * max_speed
	var accel: float = ground_acceleration if is_on_floor() else air_acceleration
	var fric: float = ground_friction if is_on_floor() else air_friction
	
	var is_turning_around: bool = false
	if velocity.x != 0 and input_direction != 0:
		is_turning_around = sign(input_direction) != sign(velocity.x)
	
	if is_turning_around and not is_on_floor():
		accel *= 1.4
	
	if not is_on_floor() and is_turning_around:
		accel *= air_direction_change_multiplier
	
	if input_direction != 0:
		velocity.x = move_toward(velocity.x, target_speed, accel * delta)
		if sprite:
			sprite.flip_h = input_direction < 0
		
		# Play footstep sounds when moving on ground
		if is_on_floor() and abs(velocity.x) > 10.0:
			footstep_timer -= delta
			if footstep_timer <= 0.0:
				play_moving_sound()
				footstep_timer = footstep_interval
	else:
		velocity.x = move_toward(velocity.x, 0.0, fric * delta)
		footstep_timer = 0.0  # Reset timer when not moving

# ============================================================
# STATE
# ============================================================
func update_state() -> void:
	previous_state = current_state
	
	if is_wall_dashing:
		current_state = State.WALL_DASHING
	elif is_dashing:
		current_state = State.DASHING
	elif landing_timer > 0.0:
		current_state = State.LANDING
	elif wall_slide_enabled and is_on_wall_slide() and velocity.y > 0 and not collision_disabled:
		var wall_normal := get_wall_normal()
		if input_direction != 0 and wall_normal != Vector2.ZERO:
			if sign(input_direction) == -sign(wall_normal.x):
				current_state = State.WALL_SLIDE
				# Play sliding sound when entering wall slide
				if previous_state != State.WALL_SLIDE:
					play_sliding_sound()
			else:
				current_state = State.FALL
				stop_sliding_sound()
		else:
			current_state = State.FALL
			stop_sliding_sound()
	elif not is_on_floor():
		current_state = State.JUMP if velocity.y < 0 else State.FALL
		stop_sliding_sound()
	elif abs(velocity.x) > 10.0:
		current_state = State.WALK
		stop_sliding_sound()
	else:
		current_state = State.IDLE
		stop_sliding_sound()

# ADD FOOTSTEP TIMER AND LOGIC TO handle_horizontal_movement():
var footstep_timer: float = 0.0
var footstep_interval: float = 0.3  # Adjust based on animation speed

# ============================================================
# LANDING
# ============================================================
func on_landed() -> void:
	var impact_velocity: float = abs(last_velocity.y)
	
	apply_ultra_boost()
	
	velocity.x *= landing_momentum_retention
	
	if impact_velocity > hard_landing_threshold:
		landing_timer = 0.15
		spawn_landing_particles(true)
		play_hard_landing_sound()  # ← ALREADY ADDED HERE
	else:
		spawn_landing_particles(false)
		play_landing_sound()  # ← ALREADY ADDED HERE
	
	jump_buffer_timer = 0.0
	jumps_remaining = max_jumps
	wall_jump_float_timer = 0.0

func apply_ultra_boost() -> void:
	if not momentum_tech_enabled:
		return
	
	if was_dashing and dash_direction.y > 0.5 and abs(dash_direction.x) > 0.1:
		velocity.x *= ultra_speed_multiplier

# ============================================================
# VISUAL
# ============================================================
func apply_visual_effects(_delta: float) -> void:
	if not sprite:
		return
	
	if landing_timer > 0.0 and squash_amount > 0.0:
		var squash_progress: float = landing_timer / 0.15
		sprite.scale.y = 1.0 - (squash_amount * squash_progress)
		sprite.scale.x = 1.0 + (squash_amount * 0.5 * squash_progress)
	else:
		sprite.scale = Vector2.ONE

# ============================================================
# PARTICLES
# ============================================================
func spawn_jump_particles() -> void:
	if particles_enabled and jump_particles:
		jump_particles.restart()

func spawn_landing_particles(hard_landing: bool) -> void:
	if particles_enabled and landing_particles:
		landing_particles.amount = 8 if hard_landing else 4
		landing_particles.restart()

func spawn_dash_particles() -> void:
	if particles_enabled and dash_particles:
		dash_particles.restart()

func spawn_wall_dash_particles() -> void:
	if particles_enabled and wall_dash_particles:
		wall_dash_particles.restart()

func spawn_wall_dash_exit_particles() -> void:
	if particles_enabled and wall_dash_particles:
		wall_dash_particles.restart()

# ============================================================
# ANIMATION
# ============================================================
func animate() -> void:
	if not sprite or not sprite.sprite_frames:
		return
	
	# PRIORITY: If wall dash animation is playing, don't interrupt it
	if is_playing_wall_dash_animation:
		return
	
	# Allow wall dash animation override during wall dash state
	if wall_dash_animation_override:
		return
	
	match current_state:
		State.WALL_DASHING:
			play_animation("wall_dash" if sprite.sprite_frames.has_animation("wall_dash") else "dash")
		State.DASHING:
			play_animation("dash" if sprite.sprite_frames.has_animation("dash") else "jump")
		State.IDLE:
			play_animation("idle")
		State.WALK:
			play_animation("run")
		State.JUMP:
			play_animation("jump")
		State.FALL:
			play_animation("fall")
		State.WALL_SLIDE:
			play_animation("wall_slide" if sprite.sprite_frames.has_animation("wall_slide") else "fall")
		State.LANDING:
			play_animation("landing" if sprite.sprite_frames.has_animation("landing") else "idle")

func play_animation(anim_name: String) -> void:
	if not sprite.sprite_frames.has_animation(anim_name):
		return
	if sprite.animation != anim_name:
		sprite.play(anim_name)

# ============================================================
# DEBUG INFO
# ============================================================
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F3:
			pass
# Spawn Point System - Consolidated and Working Version
# Add these to your player script

# State tracking variables
var last_valid_spawn_point: Vector2 = Vector2.ZERO
var current_level_scene_path: String = ""

func get_current_spawn_point() -> Vector2:
	"""Main function to get the current spawn point - handles all cases"""
	var current_scene_path = get_tree().current_scene.scene_file_path
	
	# Reset spawn tracking when changing levels
	if current_scene_path != current_level_scene_path:
		current_level_scene_path = current_scene_path
		last_valid_spawn_point = Vector2.ZERO
	
	# Method 1: Try camera's current spawn point
	var room_camera = get_tree().get_first_node_in_group("room_camera")
	if room_camera and room_camera.current_spawn_point != Vector2.ZERO:
		if is_position_in_current_level(room_camera.current_spawn_point):
			last_valid_spawn_point = room_camera.current_spawn_point
			return room_camera.current_spawn_point
	
	# Method 2: Find closest spawn in current level
	var level_spawn = get_closest_spawn_in_current_level()
	if level_spawn != Vector2.ZERO:
		last_valid_spawn_point = level_spawn
		return level_spawn
	
	# Method 3: Use last known good spawn
	if last_valid_spawn_point != Vector2.ZERO:
		return last_valid_spawn_point
	
	# Method 4: Emergency fallback
	return get_emergency_spawn_point()

func get_closest_spawn_in_current_level() -> Vector2:
	"""Find closest spawn point within the current level/scene only"""
	var spawn_points = get_tree().get_nodes_in_group("room_spawn_points")
	var valid_spawns = []
	
	# Filter to only spawns in current scene
	for spawn in spawn_points:
		if is_spawn_in_current_scene(spawn):
			valid_spawns.append(spawn)
	
	# No valid spawns found
	if valid_spawns.size() == 0:
		return Vector2.ZERO
	
	# Find closest spawn point
	var closest_spawn = valid_spawns[0]
	var closest_distance = global_position.distance_to(closest_spawn.global_position)
	
	for spawn in valid_spawns:
		var distance = global_position.distance_to(spawn.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_spawn = spawn
	
	return closest_spawn.global_position

func is_spawn_in_current_scene(spawn_point: Node) -> bool:
	"""Check if spawn point belongs to current scene"""
	var current_scene = get_tree().current_scene
	return spawn_point.is_inside_tree() and spawn_point.get_tree() == current_scene.get_tree()

func is_position_in_current_level(pos: Vector2) -> bool:
	"""Check if position is within current level boundaries"""
	var room_camera = get_tree().get_first_node_in_group("room_camera")
	if room_camera:
		var level_bounds = get_current_level_bounds(room_camera)
		return level_bounds.has_point(pos)
	return true

func get_current_level_bounds(camera: Node2D) -> Rect2:
	"""Calculate current level boundaries based on camera system"""
	var current_room = camera.current_room
	var room_size = camera.room_size
	
	# Adjust these values based on your level design
	# This assumes each level spans 10x10 rooms
	var level_start_room = Vector2(
		floor(current_room.x / 10) * 10,
		floor(current_room.y / 10) * 10
	)
	var level_end_room = level_start_room + Vector2(10, 10)
	
	var bounds_start = level_start_room * room_size
	var bounds_size = (level_end_room - level_start_room) * room_size
	
	return Rect2(bounds_start, bounds_size)

func get_emergency_spawn_point() -> Vector2:
	"""Emergency spawn point when all else fails"""
	var room_camera = get_tree().get_first_node_in_group("room_camera")
	if room_camera:
		return room_camera.global_position
	
	# Use viewport center as ultimate fallback
	var viewport_size = get_viewport().get_visible_rect().size
	return viewport_size / 2

func update_last_valid_spawn():
	"""Call this when player enters a new room to update valid spawn"""
	var room_camera = get_tree().get_first_node_in_group("room_camera")
	if room_camera and room_camera.current_spawn_point != Vector2.ZERO:
		last_valid_spawn_point = room_camera.current_spawn_point

func _on_health_component_death() -> void:
	# Check if using boss heart system
	if Global.boss_heart_system:
		handle_boss_damage()
		return
	
	# Normal respawn system (existing code)
	handle_normal_death()

func handle_boss_damage() -> void:
	"""Handle damage during boss fight - no respawn, just flash and invulnerability"""
	
	# ✅ CRITICAL: Check invulnerability properly
	if is_boss_invulnerable:
		print("🛡️ Player is invulnerable - damage blocked (timer: ", boss_invulnerability_timer, ")")
		return
	
	# Decrease lives/hearts
	current_lives -= 1
	print("💔 Boss damage taken! Lives remaining: ", current_lives)
	
	# Update heart UI
	update_heart_ui()
	
	# Check if player died (no more lives)
	if current_lives <= 0:
		# Game over during boss fight
		trigger_boss_game_over()
		return
	
	# ✅ Start invulnerability with proper timer
	is_boss_invulnerable = true
	boss_invulnerability_timer = boss_invulnerability_time
	print("🛡️ Boss invulnerability started for ", boss_invulnerability_time, " seconds")
	
	# Trigger damage flash effect
	trigger_boss_damage_flash()
	
	# Optional: Play hurt sound
	play_boss_hurt_sound()
	
	# Optional: Small knockback
	apply_boss_damage_knockback()
	
func handle_normal_death() -> void:
	"""Handle death with normal respawn system"""
	
	# Prevent multiple death calls
	if is_dying or is_game_over:
		return
	
	# Check if player is invulnerable at respawn point
	if is_respawn_invulnerable:
		return
	
	# Set death state
	is_dying = true
	Global.player_is_dead = true
	
	# Disable movement immediately
	is_movement_disabled = true
	movement_disable_timer = death_movement_delay
	
	# Stop all movement and force idle
	velocity = Vector2.ZERO
	current_state = State.IDLE
	
	# Reset all movement states
	is_dashing = false
	is_wall_dashing = false
	
	# Restore collision if it was disabled
	if collision_disabled:
		restore_collision()
	
	# Decrease lives
	current_lives -= 1
	print("Lives remaining: ", current_lives)
	
	# Update heart UI
	update_heart_ui()
	
	# Check if game over
	if current_lives <= 0:
		trigger_game_over()
	else:
		# Normal respawn
		perform_respawn()

func update_death_timers(delta: float) -> void:
	"""Update all death-related timers"""
	# Update movement disable timer
	if movement_disable_timer > 0.0:
		movement_disable_timer -= delta
		if movement_disable_timer <= 0.0:
			is_movement_disabled = false
	
	# Update respawn invulnerability timer
	if respawn_invulnerability_timer > 0.0:
		respawn_invulnerability_timer -= delta
		if respawn_invulnerability_timer <= 0.0:
			is_respawn_invulnerable = false
			
func is_player_invulnerable() -> bool:
	"""Check if player is currently invulnerable"""
	return is_respawn_invulnerable or is_dying
	
func perform_respawn() -> void:
	"""Handle the respawn sequence"""
	# Wait for respawn delay
	%Respawn_animation.play("respawn_point")
	await get_tree().create_timer(death_respawn_delay).timeout
	
	# Get spawn point and teleport
	var spawn_point = get_current_spawn_point()
	global_position = spawn_point
	
	# ✅ Use centralized reset (WITH invulnerability at respawn)
	reset_player_state(true)
	
	# Update last valid spawn
	update_last_valid_spawn()
	
	print("Respawned! Lives remaining: ", current_lives)

# Add helper function to reset lives (call this when starting new level):

func debug_force_respawn() -> void:
	"""Force respawn for testing - call with F4 or similar"""
	if OS.is_debug_build():
		is_dying = false
		is_respawn_invulnerable = false
		is_movement_disabled = false
		Global.player_is_dead = false
		
		var spawn_point = get_current_spawn_point()
		global_position = spawn_point
		velocity = Vector2.ZERO

func play_random_sound(sound_array: Array[AudioStream], last_index_ref: int, player: AudioStreamPlayer2D, volume_db: float = 3.5) -> int:
	"""
	Play a random sound from array, avoiding immediate repeats
	Returns the new last_index for tracking
	"""
	if sound_array.is_empty() or not player:
		return last_index_ref
	
	# If only one sound, just play it
	if sound_array.size() == 1:
		player.stream = sound_array[0]
		player.volume_db = volume_db
		player.play()
		return 0
	
	# Get random index that's different from last played
	var new_index: int
	var max_attempts = 10  # Prevent infinite loop
	var attempts = 0
	
	while attempts < max_attempts:
		new_index = randi() % sound_array.size()
		if new_index != last_index_ref:
			break
		attempts += 1
	
	# Play the sound
	player.stream = sound_array[new_index]
	player.volume_db = volume_db
	player.play()
	
	return new_index

# ============================================================
# SPECIFIC SOUND FUNCTIONS
# ============================================================
func play_moving_sound(volume_db: float = 12) -> void:
	"""Play random moving/footstep sound"""
	if not audio_player_movement or audio_player_movement.playing:
		return
	
	last_moving_sound_index = play_random_sound(
		moving_sounds,
		last_moving_sound_index,
		audio_player_movement,
		volume_db
	)

func play_jumping_sound(volume_db: float = 12) -> void:
	"""Play random jumping sound"""
	last_jumping_sound_index = play_random_sound(
		jumping_sounds,
		last_jumping_sound_index,
		audio_player_action,
		volume_db
	)

func play_sliding_sound(volume_db: float = 12) -> void:
	"""Play random wall slide sound (looping)"""
	if audio_player_slide.playing:
		return
	
	last_sliding_sound_index = play_random_sound(
		sliding_sounds,
		last_sliding_sound_index,
		audio_player_slide,
		volume_db
	)

func stop_sliding_sound(volume_db: float = 25) -> void:
	"""Stop wall slide sound"""
	if audio_player_slide:
		audio_player_slide.stop()

func play_wall_jump_sound(volume_db: float = 12) -> void:
	"""Play random wall jump sound"""
	last_wall_jump_sound_index = play_random_sound(
		wall_jump_sounds,
		last_wall_jump_sound_index,
		audio_player_action,
		volume_db
	)

func play_dash_sound(volume_db: float = 12) -> void:
	"""Play random dash sound"""
	last_dash_sound_index = play_random_sound(
		dash_sounds,
		last_dash_sound_index,
		audio_player_action,
		volume_db
	)

func play_wall_dash_sound(volume_db: float = 12) -> void:
	"""Play random wall dash sound"""
	last_wall_dash_sound_index = play_random_sound(
		wall_dash_sounds,
		last_wall_dash_sound_index,
		audio_player_action,
		volume_db
	)
func setup_audio_players() -> void:
	"""Create audio players for different sound categories"""
	# Movement sounds (footsteps, sliding)
	audio_player_movement = AudioStreamPlayer2D.new()
	audio_player_movement.name = "AudioPlayerMovement"
	audio_player_movement.bus = "sfx"  # Using "sfx" bus (lowercase)
	add_child(audio_player_movement)
	
	# Action sounds (jumps, dashes)
	audio_player_action = AudioStreamPlayer2D.new()
	audio_player_action.name = "AudioPlayerAction"
	audio_player_action.bus = "sfx"  # Using "sfx" bus (lowercase)
	add_child(audio_player_action)
	
	# Slide sounds (wall slide)
	audio_player_slide = AudioStreamPlayer2D.new()
	audio_player_slide.name = "AudioPlayerSlide"
	audio_player_slide.bus = "sfx"  # Using "sfx" bus (lowercase)
	add_child(audio_player_slide)

func play_landing_sound(volume_db: float = 12) -> void:
	"""Play random landing sound"""
	last_landing_sound_index = play_random_sound(
		landing_sounds,
		last_landing_sound_index,
		audio_player_action,
		volume_db
	)

func play_hard_landing_sound(volume_db: float = 12) -> void:
	"""Play random hard landing sound (louder, more impactful)"""
	last_hard_landing_sound_index = play_random_sound(
		hard_landing_sounds,
		last_hard_landing_sound_index,
		audio_player_action,
		volume_db
	)

func trigger_game_over() -> void:
	"""Handle game over - teleport to game over position"""
	is_game_over = true
	%Respawn_animation.play("respawn_point")
	
	# Wait for death animation
	await get_tree().create_timer(death_respawn_delay).timeout
	
	# Teleport to game over position
	global_position = game_over_position
	
	# ✅ Use centralized reset (NO invulnerability at game over)
	reset_player_state(false)
	
	# Reset lives for next attempt
	current_lives = max_lives
	
	# Reset game over flag
	is_game_over = false
	
func reset_player_state(enable_invulnerability: bool = false) -> void:
	"""Reset ALL player states - use for respawn and game over"""
	# Movement states
	velocity = Vector2.ZERO
	is_dying = false
	is_movement_disabled = false
	movement_disable_timer = 0.0
	
	# Death states
	Global.player_is_dead = false
	
	# Invulnerability states
	is_respawn_invulnerable = enable_invulnerability
	respawn_invulnerability_timer = respawn_invulnerability_time if enable_invulnerability else 0.0
	
	# ✅ CRITICAL: Reset boss invulnerability flags
	is_boss_invulnerable = false
	boss_invulnerability_timer = 0.0
	is_flashing = false
	
	# Dash states
	is_dashing = false
	is_wall_dashing = false
	dashes_remaining = max_dashes
	jumps_remaining = max_jumps
	dash_cooldown_timer = 0.0
	wall_dash_cooldown_timer = 0.0
	
	# Collision
	if collision_disabled:
		restore_collision()
	
	# Animation flags
	is_playing_wall_dash_animation = false
	wall_dash_animation_override = false
	
	# Animation
	if sprite:
		sprite.modulate = Color.WHITE  # Reset color
		sprite.play("idle")
	
	print("✅ Player state fully reset")
func reset_lives() -> void:
	"""Reset lives to maximum - call when starting new level/game"""
	current_lives = max_lives
	is_game_over = false
	print("Lives reset to: ", max_lives)

# Add helper function to get current lives:
func get_current_lives() -> int:
	"""Get current number of lives remaining"""
	return current_lives

# Optional: Add function to add extra lives (pickups, etc):
func add_life() -> void:
	"""Add an extra life (for pickups/powerups)"""
	current_lives = min(current_lives + 1, max_lives + 3)  # Cap at max + 3
	print("Extra life! Lives: ", current_lives)

# ============================================================
# SETUP PARRY AREA
# ============================================================

func flash_bullet(bullet: Node2D) -> void:
	"""Create a flash effect on the reflected bullet"""
	if bullet.has_node("Sprite2D") or bullet.has_node("AnimatedSprite2D"):
		var sprite = bullet.get_node_or_null("Sprite2D")
		if not sprite:
			sprite = bullet.get_node_or_null("AnimatedSprite2D")
		
		if sprite:
			var tween = create_tween()
			tween.tween_property(sprite, "modulate", Color.CYAN, 0.05)
			tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func trigger_parry_screen_shake() -> void:
	"""Trigger screen shake effect for parry"""
	if not screen_shake_enabled:
		return
	
	# Get camera (adjust this to match your camera setup)
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	# Create shake tween
	var original_offset = camera.offset
	var shake_tween = create_tween()
	shake_tween.set_parallel(true)
	
	# Number of shakes
	var shake_count = 4
	var shake_duration = parry_screen_shake_duration / shake_count
	
	for i in range(shake_count):
		var intensity = parry_screen_shake_intensity * (1.0 - float(i) / shake_count)
		var random_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		shake_tween.tween_property(
			camera,
			"offset",
			original_offset + random_offset,
			shake_duration
		).set_delay(i * shake_duration)
	
	# Return to original position
	shake_tween.tween_property(
		camera,
		"offset",
		original_offset,
		shake_duration * 0.5
	).set_delay(shake_count * shake_duration)
	
func spawn_parry_particles() -> void:
	"""Spawn particle effect for parry"""
	if particles_enabled and parry_particles:
		parry_particles.restart()

func play_parry_sound(volume_db: float = -5.0) -> void:
	"""Play random parry sound"""
	if parry_sounds.is_empty():
		# Fallback to dash sound if no parry sounds
		play_dash_sound(volume_db)
		return
	
	last_parry_sound_index = play_random_sound(
		parry_sounds,
		last_parry_sound_index,
		audio_player_action,
		volume_db
	)

func handle_parry_input() -> void:
	"""Activate parry window when Hit button is pressed"""
	if not parry_enabled:
		return
	
	# Check if player pressed Hit button and parry is off cooldown
	if hit_button_pressed and parry_cooldown_timer <= 0.0:
		activate_parry_window()

func activate_parry_window() -> void:
	"""Open the parry window"""
	is_parry_active = true
	parry_window_timer = parry_window_duration
	
	# Visual feedback - flash the parry area
	flash_parry_area()
	
	# Optional: Play a "swing" sound
	play_parry_swing_sound()
	
	print("Parry window opened!")
	
# Update flash_parry_area() function:
func flash_parry_area() -> void:
	"""Flash the parry area to show it's active"""
	if not parry_area:
		return
	
	# Create a temporary visual indicator
	var flash_sprite = Sprite2D.new()
	flash_sprite.texture = preload("res://Assets/Bash/booster00.png")  # Use any texture as placeholder
	flash_sprite.modulate = Color(0, 1, 1, 0)  # Cyan, invisible
	flash_sprite.scale = Vector2(0.5, 0.5)
	parry_area.add_child(flash_sprite)
	
	# Animate the flash
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade in quickly
	tween.tween_property(flash_sprite, "modulate:a", 0.6, 0.05)
	tween.tween_property(flash_sprite, "scale", Vector2(0.7, 0.7), 0.05)
	
	# Hold during parry window
	tween.chain().tween_property(flash_sprite, "modulate:a", 0.3, parry_window_duration - 0.1)
	
	# Fade out
	tween.chain().tween_property(flash_sprite, "modulate:a", 0.0, 0.05)
	tween.chain().tween_callback(flash_sprite.queue_free)
	
func play_parry_swing_sound() -> void:
	"""Play swing sound when activating parry"""
	# You can add a separate swing sound or reuse jump sound
	if audio_player_action and not audio_player_action.playing:
		play_jumping_sound(-8.0)  # Softer sound for swing

func update_parry_visual() -> void:
	"""Update parry visual indicator - now handled by flash_parry_area()"""
	pass  # Visual is now handled by tween in flash_parry_area()


func trigger_screen_shake(intensity: float = 5.0, duration: float = 0.2) -> void:
	"""Universal screen shake function for any action"""
	if not screen_shake_enabled:
		return
	
	# Get camera
	var camera = get_viewport().get_camera_2d()
	if not camera:
		print("⚠️ No camera found for screen shake")
		return
	
	# Store original offset
	var original_offset = camera.offset
	
	# Create shake sequence
	var shake_tween = create_tween()
	shake_tween.set_parallel(false)  # Sequential shakes
	
	# Number of shake iterations
	var shake_count = 6
	var shake_interval = duration / shake_count
	
	# Perform shakes with decreasing intensity
	for i in range(shake_count):
		var decay = 1.0 - (float(i) / shake_count)
		var shake_intensity = intensity * decay
		
		var random_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		
		shake_tween.tween_property(
			camera,
			"offset",
			original_offset + random_offset,
			shake_interval
		)
	
	# Return to original position
	shake_tween.tween_property(camera, "offset", original_offset, shake_interval * 0.5)

func _on_debug_test_parry() -> void:
	"""Test parry system - call this from a button or F5 key"""
	if OS.is_debug_build():
		print("\n=== PARRY DEBUG INFO ===")
		print("Parry Enabled: ", parry_enabled)
		print("Parry Active: ", is_parry_active)
		print("Parry Cooldown: ", parry_cooldown_timer)
		print("ParryArea exists: ", parry_area != null)
		if parry_area:
			print("ParryArea monitoring: ", parry_area.monitoring)
			print("ParryArea collision_mask: ", parry_area.collision_mask)
			print("Overlapping areas: ", parry_area.get_overlapping_areas())
			print("Overlapping bodies: ", parry_area.get_overlapping_bodies())
		print("=======================\n")

func setup_parry_area() -> void:
	"""Connect to the ParryArea node and setup bullet detection"""
	
	# Try to find ParryArea if not already assigned
	if not parry_area:
		parry_area = get_node_or_null("ParryArea")
	
	if not parry_area:
		push_warning("ParryArea node not found! Parry system disabled.")
		parry_enabled = false
		return
	
	# CRITICAL: Set up collision detection
	# Make sure ParryArea detects bullets (adjust layer numbers to match your project)
	parry_area.collision_layer = 0  # ParryArea doesn't need to be on any layer
	parry_area.collision_mask = 8   # Detect bullets on layer 4 (2^3 = 8)
	parry_area.monitoring = true
	parry_area.monitorable = false
	
	# Connect signals
	if not parry_area.area_entered.is_connected(_on_parry_area_entered):
		parry_area.area_entered.connect(_on_parry_area_entered)
	
	if not parry_area.body_entered.is_connected(_on_parry_body_entered):
		parry_area.body_entered.connect(_on_parry_body_entered)
	
	print("✨ Parry system initialized!")

# ============================================================
# PARRY DETECTION (REPLACE EXISTING)
# ============================================================
func _on_parry_area_entered(area: Area2D) -> void:
	"""Detect when an area enters parry zone"""
	if not parry_enabled or not is_parry_active:
		return
	
	print("Area detected: ", area.name, " Groups: ", area.get_groups())
	
	# Check if it's a bullet
	if area.is_in_group("Bullet"):
		perform_parry(area)

func _on_parry_body_entered(body: Node2D) -> void:
	"""Detect when a body enters parry zone"""
	if not parry_enabled or not is_parry_active:
		return
	
	print("Body detected: ", body.name, " Groups: ", body.get_groups())
	
	# Check if it's a bullet (RigidBody2D bullets)
	if body.is_in_group("Bullet"):
		perform_parry(body)

# ============================================================
# IMPROVED PARRY EXECUTION (REPLACE EXISTING)
# ============================================================
func perform_parry(bullet: Node2D) -> void:
	"""Reflect the bullet and trigger effects"""
	print("✨ PERFECT PARRY! ✨ Reflecting: ", bullet.name)
	
	# Close parry window immediately
	is_parry_active = false
	parry_window_timer = 0.0
	
	# Start cooldown
	parry_cooldown_timer = parry_cooldown
	
	# FREEZE FRAME FIRST (before reflecting)
	parry_freeze_timer = parry_freeze_duration
	
	# Reflect the bullet
	reflect_bullet(bullet)
	
	# Trigger effects
	trigger_screen_shake(parry_screen_shake_intensity, parry_screen_shake_duration)
	spawn_parry_particles()
	play_parry_sound()

# ============================================================
# IMPROVED BULLET REFLECTION (REPLACE EXISTING)
# ============================================================
func reflect_bullet(bullet: Node2D) -> void:
	"""Reverse the bullet's direction and speed"""
	
	# Check if bullet has built-in reflect method
	if bullet.has_method("reflect_from_parry"):
		bullet.reflect_from_parry(parry_reflection_speed_multiplier)
		print("  → Used bullet's reflect_from_parry() method")
		return
	
	var reflected: bool = false
	
	# Method 1: RigidBody2D bullets (YOUR CASE)
	if bullet is RigidBody2D:
		# Store original velocity
		var original_velocity = bullet.linear_velocity
		
		# Reflect velocity
		bullet.linear_velocity = -original_velocity * parry_reflection_speed_multiplier
		
		# Disable gravity
		bullet.gravity_scale = 0.0
		
		# Lock rotation
		bullet.lock_rotation = true
		
		# Update direction property if exists
		if "direction" in bullet:
			bullet.direction = -bullet.direction.normalized()
		
		reflected = true
		print("  → Reflected RigidBody2D velocity: ", bullet.linear_velocity)
	
	# Method 2: CharacterBody2D or custom velocity
	elif "velocity" in bullet:
		bullet.velocity = -bullet.velocity * parry_reflection_speed_multiplier
		reflected = true
		print("  → Reflected custom velocity: ", bullet.velocity)
	
	elif "direction" in bullet:
		bullet.direction = -bullet.direction
		if "speed" in bullet:
			bullet.speed *= parry_reflection_speed_multiplier
		reflected = true
		print("  → Reflected direction-based bullet")
	
	if not reflected:
		push_warning("⚠️ Could not reflect bullet: ", bullet.name)
		return
	
	if bullet is RigidBody2D or bullet is Area2D:
		bullet.collision_layer = 4   
		bullet.collision_mask = 4   
		print("  → Changed collision layers to target enemies")
	
	if "is_reflected" in bullet:
		bullet.is_reflected = true
	
	if "team" in bullet:
		bullet.team = "player"
	
	flash_bullet(bullet)
func finish_wall_dash_exit() -> void:
	# Reset animation flags (safety check)
	is_playing_wall_dash_animation = false
	wall_dash_animation_override = false
	
	# Rest of your existing code...
	restore_collision()
	is_emergency_wall_dash = false
	
	if wall_dash_refills_normal_dash and has_exited_wall:
		dashes_remaining = max_dashes
	
	if not is_emergency_wall_dash:
		Global._can_wall_dash_flag = false
	
	velocity.x = sign(velocity.x) * dash_end_speed
	spawn_wall_dash_exit_particles()

# دالة جديدة: فحص لو اللاعب داخل حائط
func is_overlapping_wall() -> bool:
	"""Check if player is currently overlapping with walls"""
	var test_motion = PhysicsTestMotionParameters2D.new()
	test_motion.from = global_transform
	test_motion.motion = Vector2.ZERO
	
	var result = PhysicsTestMotionResult2D.new()
	return PhysicsServer2D.body_test_motion(get_rid(), test_motion, result)
# دالة جديدة: بداية الدفع للخروج
func start_push_out_from_wall() -> void:
	"""Start pushing player out of wall smoothly"""
	is_pushing_out = true
	push_out_direction = wall_dash_direction  # نفس اتجاه الـ wall dash
	
	# Keep collision disabled while pushing out
	# (already disabled from wall dash)
	
	print("🔄 Pushing out from wall...")

# دالة جديدة: التعامل مع الدفع للخروج
func handle_push_out_from_wall(delta: float) -> void:
	"""Smoothly push player out of wall"""
	# Continue moving in wall dash direction
	velocity = push_out_direction * wall_dash_speed * 0.5  # نصف السرعة عشان يبقى smooth
	
	# Check if we're clear of walls
	if not is_overlapping_wall():
		# We're out! Finish the exit
		is_pushing_out = false
		finish_wall_dash_exit()
		print("✅ Successfully pushed out of wall")

func start_emergency_wall_dash() -> void:
	"""Auto wall dash to push player out of wall - EMERGENCY MODE"""
	print("🚨 EMERGENCY! Player stuck in wall - auto wall dash activated")
	
	# Set emergency flag
	is_emergency_wall_dash = true
	
	# Restart wall dash with SAME direction
	is_wall_dashing = true
	wall_dash_timer = wall_dash_duration  # Full duration
	
	# Keep same direction and collision disabled
	velocity = wall_dash_direction * wall_dash_speed
	
	# NO freeze frame (instant)
	wall_dash_freeze_timer = 0.0
	
	# Visual feedback (optional - subtle)
	spawn_wall_dash_trail()

func trigger_boss_damage_flash() -> void:
	"""Flash player white when taking damage during boss fight"""
	
	if not sprite:
		return
	
	# ✅ Allow new flash even if already flashing
	is_flashing = true
	
	# Stop any existing tween
	var tweens = get_tree().get_processed_tweens()
	for tween in tweens:
		if tween and tween.is_valid():
			tween.kill()
	
	# Create flash tween
	var tween = create_tween()
	tween.set_loops(boss_damage_flash_count)
	
	# Flash to white
	tween.tween_property(
		sprite,
		"modulate",
		boss_damage_flash_color,
		boss_damage_flash_duration
	)
	
	# Flash back to normal
	tween.tween_property(
		sprite,
		"modulate",
		Color.WHITE,
		boss_damage_flash_duration
	)
	
	# Reset flashing flag when done
	tween.finished.connect(func(): 
		is_flashing = false
		sprite.modulate = Color.WHITE  # Ensure we end on white
		print("✅ Damage flash completed")
	)
	
	print("✨ Damage flash started")
func apply_boss_damage_knockback() -> void:
	"""Apply small knockback when taking damage in boss fight"""
	
	# Get direction away from damage source
	# You can customize this based on where damage came from
	var knockback_direction = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	
	# Apply knockback velocity
	velocity.x = knockback_direction.x * 150.0
	velocity.y = -100.0  # Small upward bounce

# ============================================================
# OPTIONAL: BOSS HURT SOUND
# ============================================================
func play_boss_hurt_sound() -> void:
	"""Play hurt sound during boss fight"""
	# Add hurt sounds to your sound arrays if you want
	# For now, reuse jump sound as placeholder
	if audio_player_action:
		play_jumping_sound(-5.0)

# ============================================================
# UPDATE HEART UI
# ============================================================
func update_heart_ui() -> void:
	"""Update heart display based on current lives"""
	
	# Check if heart nodes exist
	if not has_node("%Heart1") or not has_node("%Heart2") or not has_node("%Heart3"):
		return
	
	match current_lives:
		3:
			%Heart1.show()
			%Heart2.show()
			%Heart3.show()
		2:
			%Heart1.hide()
			%Heart2.show()
			%Heart3.show()
		1:
			%Heart1.hide()
			%Heart2.hide()
			%Heart3.show()
		0:
			%Heart1.hide()
			%Heart2.hide()
			%Heart3.hide()
			
func trigger_boss_game_over() -> void:
	"""Handle game over during boss fight"""
	print("💀 BOSS FIGHT GAME OVER!")
	
	# Set game over state
	is_game_over = true
	%Respawn_animation.play("respawn_point")
	# ✅ CRITICAL: Reset boss invulnerability IMMEDIATELY
	is_boss_invulnerable = false
	boss_invulnerability_timer = 0.0
	is_flashing = false
	
	# Optional: Play death animation
	if sprite:
		sprite.modulate = Color.WHITE  # Reset color
		sprite.play("death" if sprite.sprite_frames.has_animation("death") else "idle")
	
	# Wait a moment
	await get_tree().create_timer(0.2).timeout
	
	# Teleport to game over position
	global_position = game_over_position
	
	# Reset state (NO invulnerability at game over)
	reset_player_state(false)
	
	# Reset lives
	current_lives = max_lives
	
	# Reset game over flag
	is_game_over = false
	
	# Update UI
	update_heart_ui()
	
	print("Respawned at game over position - ready to take damage again")

func _process(_delta: float) -> void:
	# Press F6 to debug boss health system
	if Input.is_action_just_pressed("ui_focus_next") and OS.is_debug_build():
		print("\n=== BOSS HEALTH DEBUG ===")
		print("Boss Heart System Enabled: ", boss_heart_system_enabled)
		print("Global.boss_heart_system: ", Global.boss_heart_system)
		print("Is Boss Invulnerable: ", is_boss_invulnerable)
		print("Boss Invulnerability Timer: ", boss_invulnerability_timer)
		print("Current Lives: ", current_lives)
		print("Is Dying: ", is_dying)
		print("Is Game Over: ", is_game_over)
		print("Is Flashing: ", is_flashing)
		print("========================\n")
