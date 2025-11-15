extends Node2D

# Block dimensions
const BLOCK_SIZE = Vector2(79.846, 47.883)

# Movement Types
enum MovementType {
	HORIZONTAL,
	VERTICAL,
	CUSTOM
}

# Movement Settings
@export var movement_type: MovementType = MovementType.HORIZONTAL
@export var movement_speed: float = 100.0
@export var movement_distance: float = 200.0

# Custom Movement Pattern Settings
@export_group("Custom Movement Pattern")
@export var pattern_step_1_direction: Vector2 = Vector2.RIGHT
@export var pattern_step_1_distance: float = 150.0
@export var pattern_step_1_speed: float = 120.0
@export var pattern_step_1_wait_time: float = 0.5

@export var pattern_step_2_direction: Vector2 = Vector2.DOWN
@export var pattern_step_2_distance: float = 100.0
@export var pattern_step_2_speed: float = 80.0
@export var pattern_step_2_wait_time: float = 1.0

@export var pattern_step_3_direction: Vector2 = Vector2.LEFT
@export var pattern_step_3_distance: float = 150.0
@export var pattern_step_3_speed: float = 120.0
@export var pattern_step_3_wait_time: float = 0.3

@export var pattern_step_4_direction: Vector2 = Vector2.UP
@export var pattern_step_4_distance: float = 100.0
@export var pattern_step_4_speed: float = 100.0
@export var pattern_step_4_wait_time: float = 0.8

@export var pattern_steps_count: int = 4

# Bounce Settings
@export_group("Bounce Settings")
@export var enable_bounce: bool = true
@export var bounce_strength: float = 20.0
@export var bounce_duration: float = 0.3
@export var bounce_wait_time: float = 0.5
@export var bounce_ease_type: Tween.EaseType = Tween.EASE_OUT
@export var bounce_transition_type: Tween.TransitionType = Tween.TRANS_BACK

# Professional Dust Preset - MOVED TO TOP
@export_group("Professional Dust Preset")
@export var act_as_dust: bool = false : set = set_act_as_dust

# Particles Settings
@export_group("Particles Settings")
@export var enable_particles: bool = true
@export var particle_textures: Array[Texture2D] = []
@export var particle_count: int = 25
@export var particle_lifetime: float = 1.0
@export var particle_speed_min: float = 50.0
@export var particle_speed_max: float = 150.0
@export var particle_size_min: float = 2.0
@export var particle_size_max: float = 6.0
@export var particle_color: Color = Color(0.8, 0.6, 0.4, 1.0)
@export var particle_gravity: float = 98.0
@export var particle_friction: float = 0.95
@export var particle_rotation_speed_min: float = -180.0
@export var particle_rotation_speed_max: float = 180.0
@export var enable_particle_fade: bool = true
@export var fade_in_duration: float = 0.2
@export var fade_out_duration: float = 0.8
@export var particle_z_index: int = 1000

# Transparency Animation Settings
@export_group("Transparency Animation")
@export var enable_transparency_fade: bool = true
@export var transparency_fade_delay: float = 0.5
@export var transparency_fade_duration: float = 1.0
@export var final_transparency: float = 0.0

# Particle Separation and Explosion Settings
@export_group("Particle Separation & Explosion")
@export var enable_separation: bool = true
@export var separation_force: float = 100.0
@export var separation_radius: float = 20.0
@export var enable_explosion: bool = false
@export var explosion_force: float = 200.0
@export var explosion_radius: float = 50.0
@export var explosion_delay: float = 0.0
@export var explosion_duration: float = 0.3

# Particle Position Settings for Each Direction
@export_group("Particle Positions - Right Direction")
@export var right_particles_enabled: bool = true
@export var right_particle_positions: Array[Vector2] = [Vector2(40, -12), Vector2(40, 0), Vector2(40, 12)]
@export var right_spawn_spread: float = 5.0

@export_group("Particle Positions - Left Direction") 
@export var left_particles_enabled: bool = true
@export var left_particle_positions: Array[Vector2] = [Vector2(-40, -12), Vector2(-40, 0), Vector2(-40, 12)]
@export var left_spawn_spread: float = 5.0

@export_group("Particle Positions - Down Direction")
@export var down_particles_enabled: bool = true
@export var down_particle_positions: Array[Vector2] = [Vector2(-20, 24), Vector2(0, 24), Vector2(20, 24)]
@export var down_spawn_spread: float = 5.0

@export_group("Particle Positions - Up Direction")
@export var up_particles_enabled: bool = true
@export var up_particle_positions: Array[Vector2] = [Vector2(-20, -24), Vector2(0, -24), Vector2(20, -24)]
@export var up_spawn_spread: float = 5.0

# Particle Animation Settings
@export_group("Particle Animations")
@export var enable_size_animation: bool = true
@export var size_animation_scale_start: float = 0.5
@export var size_animation_scale_peak: float = 1.2
@export var size_animation_scale_end: float = 0.3
@export var enable_bounce_particles: bool = true
@export var particle_bounce_damping: float = 0.7
@export var particle_bounce_threshold: float = 5.0

# Screen Shake Settings
@export_group("Screen Shake Settings")
@export var enable_screen_shake: bool = true
@export var shake_intensity: float = 10.0
@export var shake_duration: float = 0.2

# Internal variables
var current_direction: Vector2 = Vector2.RIGHT
var start_position: Vector2
var target_position: Vector2
var is_moving: bool = false
var is_bouncing: bool = false
var is_waiting: bool = false
var custom_pattern_index: int = 0
var custom_movement_pattern: Array[Dictionary] = []

# Nodes references
var movement_tween: Tween
var bounce_tween: Tween
var wait_tween: Tween
var particle_system: Node2D
var camera: Camera2D

# Particle arrays
var active_particles: Array[Dictionary] = []
var particle_index_counter: int = 0

# Dust preset backup variables
var original_settings: Dictionary = {}

func _ready():
	# Store original settings before any modifications
	store_original_settings()
	
	setup_custom_pattern()
	setup_movement()
	setup_particle_system()
	find_camera()
	
	# Set this node's z-index to be high
	z_index = particle_z_index
	
	# Apply dust preset if enabled
	if act_as_dust:
		apply_dust_preset()
	
	start_movement()

func store_original_settings():
	original_settings = {
		"particle_count": particle_count,
		"particle_lifetime": particle_lifetime,
		"particle_speed_min": particle_speed_min,
		"particle_speed_max": particle_speed_max,
		"particle_size_min": particle_size_min,
		"particle_size_max": particle_size_max,
		"particle_gravity": particle_gravity,
		"particle_friction": particle_friction,
		"particle_rotation_speed_min": particle_rotation_speed_min,
		"particle_rotation_speed_max": particle_rotation_speed_max,
		"particle_color": particle_color,
		"enable_particle_fade": enable_particle_fade,
		"fade_in_duration": fade_in_duration,
		"fade_out_duration": fade_out_duration,
		"enable_transparency_fade": enable_transparency_fade,
		"transparency_fade_delay": transparency_fade_delay,
		"transparency_fade_duration": transparency_fade_duration,
		"final_transparency": final_transparency,
		"enable_size_animation": enable_size_animation,
		"size_animation_scale_start": size_animation_scale_start,
		"size_animation_scale_peak": size_animation_scale_peak,
		"size_animation_scale_end": size_animation_scale_end,
		"enable_bounce_particles": enable_bounce_particles,
		"particle_bounce_damping": particle_bounce_damping,
		"particle_bounce_threshold": particle_bounce_threshold,
		"enable_separation": enable_separation,
		"separation_force": separation_force,
		"separation_radius": separation_radius,
		"enable_explosion": enable_explosion,
		"right_particle_positions": right_particle_positions.duplicate(),
		"left_particle_positions": left_particle_positions.duplicate(),
		"down_particle_positions": down_particle_positions.duplicate(),
		"up_particle_positions": up_particle_positions.duplicate(),
		"right_spawn_spread": right_spawn_spread,
		"left_spawn_spread": left_spawn_spread,
		"down_spawn_spread": down_spawn_spread,
		"up_spawn_spread": up_spawn_spread
	}

func set_act_as_dust(value: bool):
	act_as_dust = value
	if act_as_dust:
		apply_dust_preset()
	else:
		restore_original_settings()

func apply_dust_preset():
	# Professional dust settings inspired by Celeste and indie 2D games
	particle_count = 15
	particle_lifetime = 1.8
	particle_speed_min = 25.0
	particle_speed_max = 80.0
	particle_size_min = 1.5
	particle_size_max = 4.0
	particle_gravity = 50.0
	particle_friction = 0.92
	particle_rotation_speed_min = -90.0
	particle_rotation_speed_max = 90.0
	
	# Epic dust colors - warm brownish with variations
	particle_color = Color(0, 0, 100, 1.0)
	
	# Fade settings for professional look
	enable_particle_fade = true
	fade_in_duration = 0.15
	fade_out_duration = 1.2
	
	# Transparency fade for epic effect
	enable_transparency_fade = true
	transparency_fade_delay = 0.2
	transparency_fade_duration = 1.4
	final_transparency = 0.0
	
	# Size animation for professional dust
	enable_size_animation = true
	size_animation_scale_start = 0.3
	size_animation_scale_peak = 1.1
	size_animation_scale_end = 0.1
	
	# Bounce settings for dust realism
	enable_bounce_particles = true
	particle_bounce_damping = 0.4
	particle_bounce_threshold = 3.0
	
	# Separation for natural dust spreading
	enable_separation = true
	separation_force = 80.0
	separation_radius = 15.0
	
	# Disable explosion for natural dust
	enable_explosion = false
	
	# Enhanced particle positions for better dust spread
	setup_dust_particle_positions()

func restore_original_settings():
	if original_settings.size() > 0:
		particle_count = original_settings.get("particle_count", 25)
		particle_lifetime = original_settings.get("particle_lifetime", 1.0)
		particle_speed_min = original_settings.get("particle_speed_min", 50.0)
		particle_speed_max = original_settings.get("particle_speed_max", 150.0)
		particle_size_min = original_settings.get("particle_size_min", 2.0)
		particle_size_max = original_settings.get("particle_size_max", 6.0)
		particle_gravity = original_settings.get("particle_gravity", 98.0)
		particle_friction = original_settings.get("particle_friction", 0.95)
		particle_rotation_speed_min = original_settings.get("particle_rotation_speed_min", -180.0)
		particle_rotation_speed_max = original_settings.get("particle_rotation_speed_max", 180.0)
		particle_color = original_settings.get("particle_color", Color(0.8, 0.6, 0.4, 1.0))
		enable_particle_fade = original_settings.get("enable_particle_fade", true)
		fade_in_duration = original_settings.get("fade_in_duration", 0.2)
		fade_out_duration = original_settings.get("fade_out_duration", 0.8)
		enable_transparency_fade = original_settings.get("enable_transparency_fade", true)
		transparency_fade_delay = original_settings.get("transparency_fade_delay", 0.5)
		transparency_fade_duration = original_settings.get("transparency_fade_duration", 1.0)
		final_transparency = original_settings.get("final_transparency", 0.0)
		enable_size_animation = original_settings.get("enable_size_animation", true)
		size_animation_scale_start = original_settings.get("size_animation_scale_start", 0.5)
		size_animation_scale_peak = original_settings.get("size_animation_scale_peak", 1.2)
		size_animation_scale_end = original_settings.get("size_animation_scale_end", 0.3)
		enable_bounce_particles = original_settings.get("enable_bounce_particles", true)
		particle_bounce_damping = original_settings.get("particle_bounce_damping", 0.7)
		particle_bounce_threshold = original_settings.get("particle_bounce_threshold", 5.0)
		enable_separation = original_settings.get("enable_separation", true)
		separation_force = original_settings.get("separation_force", 100.0)
		separation_radius = original_settings.get("separation_radius", 20.0)
		enable_explosion = original_settings.get("enable_explosion", false)
		right_particle_positions = original_settings.get("right_particle_positions", [Vector2(40, -12), Vector2(40, 0), Vector2(40, 12)])
		left_particle_positions = original_settings.get("left_particle_positions", [Vector2(-40, -12), Vector2(-40, 0), Vector2(-40, 12)])
		down_particle_positions = original_settings.get("down_particle_positions", [Vector2(-20, 24), Vector2(0, 24), Vector2(20, 24)])
		up_particle_positions = original_settings.get("up_particle_positions", [Vector2(-20, -24), Vector2(0, -24), Vector2(20, -24)])
		right_spawn_spread = original_settings.get("right_spawn_spread", 5.0)
		left_spawn_spread = original_settings.get("left_spawn_spread", 5.0)
		down_spawn_spread = original_settings.get("down_spawn_spread", 5.0)
		up_spawn_spread = original_settings.get("up_spawn_spread", 5.0)

func setup_dust_particle_positions():
	# More spread out positions for natural dust clouds
	right_particle_positions = [
		Vector2(35, -15), Vector2(40, -8), Vector2(42, 0), 
		Vector2(40, 8), Vector2(35, 15), Vector2(30, -5), Vector2(30, 5)
	]
	right_spawn_spread = 8.0
	
	left_particle_positions = [
		Vector2(-35, -15), Vector2(-40, -8), Vector2(-42, 0),
		Vector2(-40, 8), Vector2(-35, 15), Vector2(-30, -5), Vector2(-30, 5)
	]
	left_spawn_spread = 8.0
	
	down_particle_positions = [
		Vector2(-25, 22), Vector2(-12, 24), Vector2(0, 26),
		Vector2(12, 24), Vector2(25, 22), Vector2(-8, 20), Vector2(8, 20)
	]
	down_spawn_spread = 8.0
	
	up_particle_positions = [
		Vector2(-25, -22), Vector2(-12, -24), Vector2(0, -26),
		Vector2(12, -24), Vector2(25, -22), Vector2(-8, -20), Vector2(8, -20)
	]
	up_spawn_spread = 8.0

func setup_custom_pattern():
	custom_movement_pattern.clear()
	
	# Add patterns based on steps count
	for i in range(pattern_steps_count):
		var pattern = {}
		match i:
			0:
				pattern = {
					"direction": pattern_step_1_direction,
					"distance": pattern_step_1_distance,
					"speed": pattern_step_1_speed,
					"wait_time": pattern_step_1_wait_time
				}
			1:
				pattern = {
					"direction": pattern_step_2_direction,
					"distance": pattern_step_2_distance,
					"speed": pattern_step_2_speed,
					"wait_time": pattern_step_2_wait_time
				}
			2:
				pattern = {
					"direction": pattern_step_3_direction,
					"distance": pattern_step_3_distance,
					"speed": pattern_step_3_speed,
					"wait_time": pattern_step_3_wait_time
				}
			3:
				pattern = {
					"direction": pattern_step_4_direction,
					"distance": pattern_step_4_distance,
					"speed": pattern_step_4_speed,
					"wait_time": pattern_step_4_wait_time
				}
		
		if pattern.size() > 0:
			custom_movement_pattern.append(pattern)

func setup_movement():
	start_position = global_position
	
	match movement_type:
		MovementType.HORIZONTAL:
			current_direction = Vector2.RIGHT
			target_position = start_position + current_direction * movement_distance
		MovementType.VERTICAL:
			current_direction = Vector2.DOWN
			target_position = start_position + current_direction * movement_distance
		MovementType.CUSTOM:
			if custom_movement_pattern.size() > 0:
				var first_pattern = custom_movement_pattern[0]
				current_direction = first_pattern.get("direction", Vector2.RIGHT)
				var distance = first_pattern.get("distance", movement_distance)
				target_position = start_position + current_direction * distance

func setup_particle_system():
	particle_system = Node2D.new()
	particle_system.name = "ParticleSystem"
	particle_system.z_index = particle_z_index
	add_child(particle_system)

func find_camera():
	camera = get_viewport().get_camera_2d()

func start_movement():
	if is_moving or is_bouncing or is_waiting:
		return
	
	is_moving = true
	var speed = movement_speed
	
	if movement_type == MovementType.CUSTOM and custom_pattern_index < custom_movement_pattern.size():
		var pattern = custom_movement_pattern[custom_pattern_index]
		speed = pattern.get("speed", movement_speed)
	
	var distance_to_target = global_position.distance_to(target_position)
	var move_duration = distance_to_target / speed
	
	movement_tween = create_tween()
	movement_tween.tween_property(self, "global_position", target_position, move_duration)
	movement_tween.tween_callback(on_movement_completed)

func on_movement_completed():
	is_moving = false
	
	if enable_bounce:
		perform_bounce()
	else:
		setup_next_movement()

func perform_bounce():
	if is_bouncing:
		return
	
	is_bouncing = true
	
	# Create particles
	if enable_particles:
		create_bounce_particles()
	
	# Screen shake
	if enable_screen_shake and camera:
		shake_camera()
	
	# Bounce animation
	var bounce_offset = -current_direction * bounce_strength
	var bounce_position = global_position + bounce_offset
	
	bounce_tween = create_tween()
	bounce_tween.set_ease(bounce_ease_type)
	bounce_tween.set_trans(bounce_transition_type)
	bounce_tween.tween_property(self, "global_position", bounce_position, bounce_duration * 0.6)
	bounce_tween.tween_property(self, "global_position", target_position, bounce_duration * 0.4)
	bounce_tween.tween_callback(on_bounce_completed)

func on_bounce_completed():
	is_bouncing = false
	
	if bounce_wait_time > 0:
		wait_tween = create_tween()
		wait_tween.tween_interval(bounce_wait_time)
		wait_tween.tween_callback(setup_next_movement)
	else:
		setup_next_movement()

func setup_next_movement():
	match movement_type:
		MovementType.HORIZONTAL:
			current_direction *= -1
			target_position = global_position + current_direction * movement_distance
		
		MovementType.VERTICAL:
			current_direction *= -1
			target_position = global_position + current_direction * movement_distance
		
		MovementType.CUSTOM:
			custom_pattern_index = (custom_pattern_index + 1) % custom_movement_pattern.size()
			var pattern = custom_movement_pattern[custom_pattern_index]
			current_direction = pattern.get("direction", Vector2.RIGHT)
			var distance = pattern.get("distance", movement_distance)
			var wait_time = pattern.get("wait_time", 0.0)
			
			target_position = global_position + current_direction * distance
			
			if wait_time > 0:
				is_waiting = true
				wait_tween = create_tween()
				wait_tween.tween_interval(wait_time)
				wait_tween.tween_callback(on_wait_completed)
			else:
				start_movement()
			return
	
	start_movement()

func on_wait_completed():
	is_waiting = false
	start_movement()

func create_bounce_particles():
	var particle_positions = get_particle_spawn_positions()
	
	for pos in particle_positions:
		for i in range(particle_count):
			var particle = create_dust_particle(pos)
			active_particles.append(particle)

func get_particle_spawn_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	
	match current_direction:
		Vector2.RIGHT:
			if right_particles_enabled:
				for pos in right_particle_positions:
					var spawn_pos = global_position + pos
					# Add random spread
					spawn_pos += Vector2(
						randf_range(-right_spawn_spread, right_spawn_spread),
						randf_range(-right_spawn_spread, right_spawn_spread)
					)
					positions.append(spawn_pos)
		
		Vector2.LEFT:
			if left_particles_enabled:
				for pos in left_particle_positions:
					var spawn_pos = global_position + pos
					spawn_pos += Vector2(
						randf_range(-left_spawn_spread, left_spawn_spread),
						randf_range(-left_spawn_spread, left_spawn_spread)
					)
					positions.append(spawn_pos)
		
		Vector2.DOWN:
			if down_particles_enabled:
				for pos in down_particle_positions:
					var spawn_pos = global_position + pos
					spawn_pos += Vector2(
						randf_range(-down_spawn_spread, down_spawn_spread),
						randf_range(-down_spawn_spread, down_spawn_spread)
					)
					positions.append(spawn_pos)
		
		Vector2.UP:
			if up_particles_enabled:
				for pos in up_particle_positions:
					var spawn_pos = global_position + pos
					spawn_pos += Vector2(
						randf_range(-up_spawn_spread, up_spawn_spread),
						randf_range(-up_spawn_spread, up_spawn_spread)
					)
					positions.append(spawn_pos)
		
		_:  # Custom direction
			positions.append(global_position + current_direction * BLOCK_SIZE.x * 0.5)
	
	return positions

func get_random_texture() -> Texture2D:
	if particle_textures.size() > 0:
		var random_index = randi() % particle_textures.size()
		return particle_textures[random_index]
	else:
		return null

func create_dust_particle(spawn_position: Vector2) -> Dictionary:
	var particle = {
		"index": particle_index_counter,
		"position": spawn_position,
		"initial_position": spawn_position,
		"velocity": get_particle_velocity(),
		"size": randf_range(particle_size_min, particle_size_max),
		"initial_size": 0.0,
		"target_size": 0.0,
		"lifetime": particle_lifetime,
		"current_life": 0.0,
		"alpha": 0.0,
		"base_alpha": 1.0,
		"transparency_alpha": 1.0,
		"rotation": randf_range(0, 2 * PI),
		"rotation_speed": randf_range(particle_rotation_speed_min, particle_rotation_speed_max),
		"color": get_dust_color() if act_as_dust else particle_color,
		"texture": get_random_texture(),
		"has_bounced": false,
		"fade_in_complete": false,
		"fade_out_started": false,
		"transparency_fade_started": false,
		"explosion_applied": false,
		"explosion_time": 0.0,
		"separation_force_applied": Vector2.ZERO,
		"dust_drift": Vector2(randf_range(-15.0, 15.0), randf_range(-10.0, 5.0)) if act_as_dust else Vector2.ZERO
	}
	
	# Set up size animation
	particle["initial_size"] = particle["size"] * size_animation_scale_start
	particle["target_size"] = particle["size"]
	
	# Increment index counter
	particle_index_counter += 1
	
	return particle

func get_dust_color() -> Color:
	# Professional dust color variations like in Celeste
	var dust_colors = [
		Color(0.9, 0.8, 0.6, 1.0),    # Warm beige
		Color(0.85, 0.75, 0.55, 1.0), # Darker beige
		Color(0.95, 0.85, 0.7, 1.0),  # Light cream
		Color(0.8, 0.7, 0.5, 1.0),    # Brown dust
		Color(0.92, 0.82, 0.65, 1.0), # Golden dust
		Color(0.88, 0.78, 0.58, 1.0)  # Medium dust
	]
	
	return dust_colors[randi() % dust_colors.size()]

func get_particle_velocity() -> Vector2:
	var base_velocity: Vector2
	var spread_angle: float
	
	if act_as_dust:
		# Enhanced dust velocity for more realistic movement
		spread_angle = PI * 0.75  # Wider spread for dust
		base_velocity = -current_direction
		
		# Add some upward bias for dust floating effect
		base_velocity += Vector2(0, -0.3)
		
		# More varied angle for dust
		var angle_offset = randf_range(-spread_angle * 0.5, spread_angle * 0.5)
		base_velocity = base_velocity.rotated(angle_offset)
		
		# Add some lateral drift for dust
		base_velocity.x += randf_range(-20.0, 20.0)
	else:
		# Original velocity calculation
		spread_angle = PI * 0.5  # 90 degrees spread
		base_velocity = -current_direction
		var angle_offset = randf_range(-spread_angle * 0.5, spread_angle * 0.5)
		base_velocity = base_velocity.rotated(angle_offset)
	
	# Random speed
	var speed = randf_range(particle_speed_min, particle_speed_max)
	return base_velocity * speed

func shake_camera():
	if not camera:
		return
	
	var original_offset = camera.offset
	var shake_tween = create_tween()
	var shake_steps = int(shake_duration * 30)  # 30 FPS shake
	
	for i in range(shake_steps):
		var shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		shake_tween.parallel().tween_property(camera, "offset", original_offset + shake_offset, shake_duration / shake_steps)
	
	shake_tween.tween_property(camera, "offset", original_offset, 0.1)

func _process(delta):
	update_particles(delta)
	queue_redraw()

func update_particles(delta: float):
	# Apply separation forces
	if enable_separation:
		apply_separation_forces()
	
	# Apply explosion forces
	if enable_explosion:
		apply_explosion_forces(delta)
	
	for i in range(active_particles.size() - 1, -1, -1):
		var particle = active_particles[i]
		
		# Update life and progress
		particle["current_life"] += delta
		var life_progress = particle["current_life"] / particle["lifetime"]
		
		# Apply gravity and movement
		if act_as_dust:
			# Enhanced dust physics
			particle["velocity"].y += particle_gravity * delta * 0.7  # Lighter gravity for dust
			particle["velocity"] *= particle_friction
			
			# Add dust drift for floating effect
			particle["velocity"] += particle["dust_drift"] * delta * 0.3
			
			# Add slight air resistance
			particle["velocity"] *= 0.998
		else:
			# Original physics
			particle["velocity"].y += particle_gravity * delta
			particle["velocity"] *= particle_friction
		
		# Add separation force to velocity
		particle["velocity"] += particle["separation_force_applied"] * delta
		particle["separation_force_applied"] = Vector2.ZERO  # Reset for next frame
		
		particle["position"] += particle["velocity"] * delta
		
		# Handle particle bouncing
		if enable_bounce_particles and not particle["has_bounced"]:
			if particle["velocity"].y > particle_bounce_threshold and particle["position"].y > particle["initial_position"].y + 50:
				particle["velocity"].y *= -particle_bounce_damping
				particle["has_bounced"] = true
		
		# Update rotation
		particle["rotation"] += deg_to_rad(particle["rotation_speed"]) * delta
		
		# Handle fade animations
		if enable_particle_fade:
			var fade_in_progress = min(particle["current_life"] / fade_in_duration, 1.0)
			var fade_out_start_time = particle["lifetime"] - fade_out_duration
			
			if particle["current_life"] <= fade_in_duration:
				# Fade in
				particle["base_alpha"] = ease_out_cubic(fade_in_progress)
				particle["fade_in_complete"] = false
			elif particle["current_life"] >= fade_out_start_time:
				# Fade out
				if not particle["fade_out_started"]:
					particle["fade_out_started"] = true
				var fade_out_progress = (particle["current_life"] - fade_out_start_time) / fade_out_duration
				particle["base_alpha"] = 1.0 - ease_in_cubic(fade_out_progress)
			else:
				# Fully visible
				particle["base_alpha"] = 1.0
				particle["fade_in_complete"] = true
		else:
			particle["base_alpha"] = 1.0 - life_progress
		
		# Handle transparency fade animation
		if enable_transparency_fade:
			var transparency_start_time = transparency_fade_delay
			var transparency_end_time = transparency_start_time + transparency_fade_duration
			
			if particle["current_life"] >= transparency_start_time and particle["current_life"] <= transparency_end_time:
				if not particle["transparency_fade_started"]:
					particle["transparency_fade_started"] = true
				
				var transparency_progress = (particle["current_life"] - transparency_start_time) / transparency_fade_duration
				particle["transparency_alpha"] = lerp(1.0, final_transparency, ease_in_cubic(transparency_progress))
			elif particle["current_life"] > transparency_end_time:
				particle["transparency_alpha"] = final_transparency
		else:
			particle["transparency_alpha"] = 1.0
		
		# Handle size animation
		if enable_size_animation:
			var size_progress = life_progress
			if size_progress <= 0.3:
				# Growing phase
				var grow_progress = size_progress / 0.3
				particle["size"] = lerp(particle["initial_size"], particle["target_size"] * size_animation_scale_peak, ease_out_back(grow_progress))
			elif size_progress <= 0.7:
				# Stable phase
				particle["size"] = particle["target_size"] * size_animation_scale_peak
			else:
				# Shrinking phase
				var shrink_progress = (size_progress - 0.7) / 0.3
				particle["size"] = lerp(particle["target_size"] * size_animation_scale_peak, particle["target_size"] * size_animation_scale_end, ease_in_cubic(shrink_progress))
		
		# Combine both alpha values for final alpha
		particle["alpha"] = particle["base_alpha"] * particle["transparency_alpha"]
		
		# Update color alpha
		particle["color"].a = particle["alpha"]
		
		# Remove dead particles
		if particle["current_life"] >= particle["lifetime"]:
			active_particles.remove_at(i)

# Easing functions for smooth animations
func ease_in_cubic(t: float) -> float:
	return t * t * t

func ease_out_cubic(t: float) -> float:
	var p = t - 1
	return p * p * p + 1

func ease_out_back(t: float) -> float:
	var c1 = 1.70158
	var c3 = c1 + 1
	return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2)

# Separation and Explosion Functions
func apply_separation_forces():
	for i in range(active_particles.size()):
		var particle_a = active_particles[i]
		
		for j in range(i + 1, active_particles.size()):
			var particle_b = active_particles[j]
			
			var distance = particle_a["position"].distance_to(particle_b["position"])
			if distance < separation_radius and distance > 0:
				var direction = (particle_a["position"] - particle_b["position"]).normalized()
				var force = separation_force / (distance + 1.0)  # Add 1 to avoid division by zero
				
				particle_a["separation_force_applied"] += direction * force
				particle_b["separation_force_applied"] -= direction * force

func apply_explosion_forces(delta: float):
	for particle in active_particles:
		if not particle["explosion_applied"] and particle["current_life"] >= explosion_delay:
			# Apply explosion force
			var explosion_center = particle["initial_position"]
			for other_particle in active_particles:
				var distance = other_particle["position"].distance_to(explosion_center)
				if distance <= explosion_radius:
					var direction = (other_particle["position"] - explosion_center).normalized()
					var force_magnitude = explosion_force * (1.0 - distance / explosion_radius)
					var explosion_velocity = direction * force_magnitude
					
					# Apply explosion over duration
					other_particle["velocity"] += explosion_velocity * delta / explosion_duration
			
			particle["explosion_applied"] = true
		
		particle["explosion_time"] += delta

func trigger_manual_explosion(explosion_center: Vector2, custom_force: float = -1.0, custom_radius: float = -1.0):
	var force = custom_force if custom_force > 0 else explosion_force
	var radius = custom_radius if custom_radius > 0 else explosion_radius
	
	for particle in active_particles:
		var distance = particle["position"].distance_to(explosion_center)
		if distance <= radius:
			var direction = (particle["position"] - explosion_center).normalized()
			var force_magnitude = force * (1.0 - distance / radius)
			particle["velocity"] += direction * force_magnitude

func get_particles_in_radius(center: Vector2, radius: float) -> Array[Dictionary]:
	var particles_in_range: Array[Dictionary] = []
	for particle in active_particles:
		if particle["position"].distance_to(center) <= radius:
			particles_in_range.append(particle)
	return particles_in_range

func get_particle_by_index(index: int) -> Dictionary:
	for particle in active_particles:
		if particle["index"] == index:
			return particle
	return {}  # Return empty dictionary if not found

func _draw():
	# Draw particles with high z-index
	for particle in active_particles:
		var particle_position = to_local(particle["position"])
		
		if particle.has("texture") and particle["texture"] != null:
			# Draw with the randomly assigned texture
			var particle_texture = particle["texture"] as Texture2D
			var texture_size = particle_texture.get_size()
			var scale = particle["size"] / max(texture_size.x, texture_size.y)
			
			# Create transform for rotation and scale
			var transform = Transform2D()
			transform = transform.scaled(Vector2(scale, scale))
			transform = transform.rotated(particle["rotation"])
			transform.origin = particle_position
			
			draw_set_transform_matrix(transform)
			draw_texture(particle_texture, -texture_size * 0.5, particle["color"])
			draw_set_transform_matrix(Transform2D())
		else:
			# Draw as circle if no texture with enhanced dust effect
			if act_as_dust:
				# Draw dust as soft circles with slight glow effect
				var dust_color = particle["color"]
				var glow_color = Color(dust_color.r, dust_color.g, dust_color.b, dust_color.a * 0.3)
				
				# Draw glow effect
				draw_circle(particle_position, particle["size"] * 1.5, glow_color)
				# Draw main particle
				draw_circle(particle_position, particle["size"], dust_color)
			else:
				draw_circle(particle_position, particle["size"], particle["color"])

# Public functions to control the block
func pause_movement():
	if movement_tween and movement_tween.is_valid():
		movement_tween.pause()
	if bounce_tween and bounce_tween.is_valid():
		bounce_tween.pause()
	if wait_tween and wait_tween.is_valid():
		wait_tween.pause()

func resume_movement():
	if movement_tween and movement_tween.is_valid():
		movement_tween.play()
	if bounce_tween and bounce_tween.is_valid():
		bounce_tween.play()
	if wait_tween and wait_tween.is_valid():
		wait_tween.play()

func stop_movement():
	if movement_tween and movement_tween.is_valid():
		movement_tween.kill()
	if bounce_tween and bounce_tween.is_valid():
		bounce_tween.kill()
	if wait_tween and wait_tween.is_valid():
		wait_tween.kill()
	is_moving = false
	is_bouncing = false
	is_waiting = false

func set_movement_pattern(pattern: Array[Dictionary]):
	custom_movement_pattern = pattern
	custom_pattern_index = 0
	if movement_type == MovementType.CUSTOM:
		setup_movement()

func update_custom_pattern_from_inspector():
	setup_custom_pattern()
	if movement_type == MovementType.CUSTOM:
		custom_pattern_index = 0
		setup_movement()

func toggle_bounce(enabled: bool):
	enable_bounce = enabled

func toggle_particles(enabled: bool):
	enable_particles = enabled

func toggle_screen_shake(enabled: bool):
	enable_screen_shake = enabled

# Updated function to handle multiple textures
func set_particle_textures(textures: Array[Texture2D]):
	particle_textures = textures

func add_particle_texture(texture: Texture2D):
	if texture != null and not particle_textures.has(texture):
		particle_textures.append(texture)

func remove_particle_texture(texture: Texture2D):
	var index = particle_textures.find(texture)
	if index >= 0:
		particle_textures.remove_at(index)

func clear_particle_textures():
	particle_textures.clear()

func get_particle_texture_count() -> int:
	return particle_textures.size()

func clear_particles():
	active_particles.clear()
	particle_index_counter = 0

func get_particle_count() -> int:
	return active_particles.size()

func get_all_particle_indices() -> Array[int]:
	var indices: Array[int] = []
	for particle in active_particles:
		indices.append(particle["index"])
	return indices

func set_particle_positions_for_direction(direction: Vector2, positions: Array[Vector2]):
	match direction:
		Vector2.RIGHT:
			right_particle_positions = positions
		Vector2.LEFT:
			left_particle_positions = positions
		Vector2.DOWN:
			down_particle_positions = positions
		Vector2.UP:
			up_particle_positions = positions

func enable_particles_for_direction(direction: Vector2, enabled: bool):
	match direction:
		Vector2.RIGHT:
			right_particles_enabled = enabled
		Vector2.LEFT:
			left_particles_enabled = enabled
		Vector2.DOWN:
			down_particles_enabled = enabled
		Vector2.UP:
			up_particles_enabled = enabled

func set_separation_settings(enabled: bool, force: float, radius: float):
	enable_separation = enabled
	separation_force = force
	separation_radius = radius

func set_explosion_settings(enabled: bool, force: float, radius: float, delay: float = 0.0):
	enable_explosion = enabled
	explosion_force = force
	explosion_radius = radius
	explosion_delay = delay

func toggle_separation(enabled: bool):
	enable_separation = enabled

func toggle_explosion(enabled: bool):
	enable_explosion = enabled

func set_transparency_fade_settings(enabled: bool, delay: float, duration: float, final_alpha: float):
	enable_transparency_fade = enabled
	transparency_fade_delay = delay
	transparency_fade_duration = duration
	final_transparency = clamp(final_alpha, 0.0, 1.0)

func toggle_transparency_fade(enabled: bool):
	enable_transparency_fade = enabled

func toggle_dust_mode(enabled: bool):
	act_as_dust = enabled

func set_particle_z_index(new_z_index: int):
	particle_z_index = new_z_index
	z_index = particle_z_index
	if particle_system:
		particle_system.z_index = particle_z_index

func restart_movement():
	stop_movement()
	global_position = start_position
	custom_pattern_index = 0
	setup_custom_pattern()
	setup_movement()
	start_movement()
