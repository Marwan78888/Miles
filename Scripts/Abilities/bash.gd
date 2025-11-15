# bashable_object.gd
# Attach this to your AnimatedSprite2D node
extends AnimatedSprite2D

# Physics Settings
@export_group("Physics")
@export var has_gravity: bool = true
@export var gravity: float = 800.0
@export var bounce_factor: float = 0.3
@export var friction: float = 200.0
@export var max_fall_speed: float = 500.0
@export var object_stays_static = true

# Floating Animation Settings
@export_group("Floating Animation")
@export var enable_float: bool = true
@export var float_amplitude: float = 10.0  # How far up/down it floats
@export var float_duration: float = 2.0    # Time for one complete float cycle
@export var float_offset: float = 0.0      # Starting offset (for variation)
@export var rotate_while_floating: bool = true
@export var rotation_amplitude: float = 15.0  # Degrees of rotation
@export var horizontal_sway: bool = false
@export var sway_amplitude: float = 5.0

# Bash Settings
@export_group("Bash Response")
@export var bash_force_multiplier: float = 1.0
@export var stun_duration: float = 1.0
@export var rotate_on_bash: bool = true
@export var rotation_speed: float = 10.0
@export var destroy_on_bash: bool = false
@export var bounce_on_walls: bool = true

# Visual Settings
@export_group("Visual Feedback")
@export var flash_on_bash: bool = true
@export var flash_color: Color = Color.WHITE
@export var flash_duration: float = 0.2
@export var spawn_particles_on_bash: bool = false
@export var bash_particle_scene: PackedScene
@export var glow_while_idle: bool = true
@export var glow_color: Color = Color(1, 1, 0.5, 0.3)
@export var glow_pulse_speed: float = 2.0

# Audio
@export_group("Audio")
@export var bash_impact_sounds: Array[AudioStream] = []
@export var bash_sound_volume: float = 0.8

# State
var velocity: Vector2 = Vector2.ZERO
var is_stunned: bool = false
var stun_timer: float = 0.0
var is_bashed: bool = false
var rotation_velocity: float = 0.0
var flash_timer: float = 0.0
var original_modulate: Color
var glow_time: float = 0.0

# Floating state
var base_position: Vector2 = Vector2.ZERO
var float_tween: Tween
var is_floating: bool = true
var original_rotation: float = 0.0

# Collision detection
var collision_shape: CollisionShape2D
var area_2d: Area2D
var audio_player: AudioStreamPlayer2D

func _ready():
	# Add to bashable group so bash system can find it
	add_to_group("bashable")
	
	original_modulate = modulate
	base_position = global_position
	original_rotation = rotation
	
	# Setup collision detection
	setup_collision()
	
	# Setup audio
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	
	# Start floating animation
	if enable_float:
		start_floating_animation()
	
	print(name, " is now bashable and floating!")

func setup_collision():
	# Create Area2D for collision detection (since AnimatedSprite2D can't collide)
	area_2d = Area2D.new()
	area_2d.name = "BashableArea"
	add_child(area_2d)
	
	# Create collision shape
	collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	# Size based on sprite texture (approximate)
	if sprite_frames and sprite_frames.has_animation(animation):
		var frame_texture = sprite_frames.get_frame_texture(animation, frame)
		if frame_texture:
			shape.size = frame_texture.get_size() * scale * 0.8  # Slightly smaller than visual
	else:
		shape.size = Vector2(32, 32)  # Default size
	
	collision_shape.shape = shape
	area_2d.add_child(collision_shape)
	
	# Setup collision layers
	area_2d.collision_layer = 2  # Layer 2 for bashable objects
	area_2d.collision_mask = 0   # Don't detect anything, just be detected
	
	# Connect to world boundaries
	area_2d.body_entered.connect(_on_body_entered)

func start_floating_animation():
	if float_tween:
		float_tween.kill()
	
	is_floating = true
	float_tween = create_tween()
	float_tween.set_loops()
	float_tween.set_trans(Tween.TRANS_SINE)
	float_tween.set_ease(Tween.EASE_IN_OUT)
	
	# Vertical floating
	var target_y = base_position.y - float_amplitude
	float_tween.tween_property(self, "global_position:y", target_y, float_duration / 2.0).from(base_position.y + float_offset)
	float_tween.tween_property(self, "global_position:y", base_position.y + float_offset, float_duration / 2.0)
	
	# Horizontal sway (if enabled)
	if horizontal_sway:
		var sway_tween = create_tween()
		sway_tween.set_loops()
		sway_tween.set_trans(Tween.TRANS_SINE)
		sway_tween.set_ease(Tween.EASE_IN_OUT)
		
		var target_x = base_position.x + sway_amplitude
		sway_tween.tween_property(self, "global_position:x", target_x, float_duration * 0.7).from(base_position.x - sway_amplitude)
		sway_tween.tween_property(self, "global_position:x", base_position.x - sway_amplitude, float_duration * 0.7)
	
	# Rotation animation (if enabled)
	if rotate_while_floating:
		var rotation_tween = create_tween()
		rotation_tween.set_loops()
		rotation_tween.set_trans(Tween.TRANS_SINE)
		rotation_tween.set_ease(Tween.EASE_IN_OUT)
		
		var rot_radians = deg_to_rad(rotation_amplitude)
		rotation_tween.tween_property(self, "rotation", original_rotation + rot_radians, float_duration / 2.0).from(original_rotation - rot_radians)
		rotation_tween.tween_property(self, "rotation", original_rotation - rot_radians, float_duration / 2.0)

func stop_floating_animation():
	is_floating = false
	if float_tween:
		float_tween.kill()
		float_tween = null

func _physics_process(delta):
	# Handle stun state (visual effect only if static)
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
			is_bashed = false
			rotation_velocity = 0.0
			# Resume floating after bash ends (if object was moved)
			if not object_stays_static:
				base_position = global_position
			if enable_float and not is_bashed:
				if not float_tween or not float_tween.is_running():
					start_floating_animation()
	
	# Handle flash effect
	if flash_timer > 0:
		flash_timer -= delta
		var flash_progress = 1.0 - (flash_timer / flash_duration)
		modulate = original_modulate.lerp(flash_color, 1.0 - flash_progress)
		if flash_timer <= 0:
			modulate = original_modulate
	
	# Glow pulse effect when idle
	if glow_while_idle and not is_bashed:
		glow_time += delta * glow_pulse_speed
		var glow_intensity = (sin(glow_time) + 1.0) / 2.0  # 0 to 1
		modulate = original_modulate.lerp(glow_color, glow_intensity * 0.3)
	
	# Apply physics when bashed (ONLY if object is not static)
	if is_bashed and not object_stays_static:
		# Apply gravity
		if has_gravity:
			velocity.y += gravity * delta
			velocity.y = min(velocity.y, max_fall_speed)
		
		# Apply friction (slow down horizontal movement)
		if abs(velocity.x) > 0:
			var friction_amount = friction * delta
			velocity.x = move_toward(velocity.x, 0, friction_amount)
		
		# Rotate if enabled
		if rotate_on_bash:
			rotation += rotation_velocity * delta
		
		# Move the object
		var collision = move_with_collision(delta)
		
		# Handle collision with walls/floor
		if collision:
			handle_collision(collision)

func move_with_collision(delta) -> Dictionary:
	var motion = velocity * delta
	var collision_result = {}
	
	# Simple collision detection using Area2D
	var space_state = get_world_2d().direct_space_state
	
	# Cast a ray in movement direction
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + motion
	)
	query.exclude = [area_2d]
	query.collision_mask = 1  # Check against world layer
	
	var result = space_state.intersect_ray(query)
	
	if result:
		collision_result = result
		# Move to collision point
		global_position = result.position
	else:
		# No collision, move freely
		global_position += motion
	
	return collision_result

func handle_collision(collision: Dictionary):
	if not collision.has("normal"):
		return
	
	var normal = collision.normal
	
	# Bounce off surfaces
	if bounce_on_walls:
		velocity = velocity.bounce(normal) * bounce_factor
		
		# Reduce rotation on impact
		rotation_velocity *= 0.5
		
		# Play sound
		play_random_sound(bash_impact_sounds)
		
		# Stop if velocity is too low
		if velocity.length() < 50:
			velocity = Vector2.ZERO
			is_bashed = false
			is_stunned = false
			# Resume floating
			base_position = global_position
			if enable_float:
				start_floating_animation()
	else:
		# Stick to surface
		velocity = Vector2.ZERO
		is_bashed = false
		is_stunned = false
		base_position = global_position
		if enable_float:
			start_floating_animation()

func apply_bash_knockback(force: Vector2):
	# If object is static, only do visual feedback
	if object_stays_static:
		# Visual feedback only
		is_stunned = true
		stun_timer = stun_duration
		
		# Visual feedback
		if flash_on_bash:
			flash_timer = flash_duration
		
		# Spawn particles
		if spawn_particles_on_bash and bash_particle_scene:
			spawn_bash_particles()
		
		# Play sound
		play_random_sound(bash_impact_sounds)
		
		# Optional: slight scale pulse effect
		var pulse_tween = create_tween()
		pulse_tween.tween_property(self, "scale", scale * 1.2, 0.1)
		pulse_tween.tween_property(self, "scale", scale, 0.1)
		
		print(name, " was bashed (static)! Player launched with force: ", force)
		return
	
	# Original behavior for non-static objects
	# Stop floating animation
	stop_floating_animation()
	
	# Apply the bash force
	velocity = force * bash_force_multiplier
	is_stunned = true
	is_bashed = true
	stun_timer = stun_duration
	
	# Add rotation
	if rotate_on_bash:
		rotation_velocity = rotation_speed * sign(force.x)
	
	# Visual feedback
	if flash_on_bash:
		flash_timer = flash_duration
	
	# Spawn particles
	if spawn_particles_on_bash and bash_particle_scene:
		spawn_bash_particles()
	
	# Play sound
	play_random_sound(bash_impact_sounds)
	
	# Destroy if configured
	if destroy_on_bash:
		# Delay destruction slightly for effects
		await get_tree().create_timer(0.1).timeout
		queue_free()
	
	print(name, " was bashed! Force: ", force)

func _on_body_entered(body):
	# Handle collision with world
	if is_bashed and body.is_in_group("world"):
		var collision_normal = (global_position - body.global_position).normalized()
		handle_collision({"normal": collision_normal})

func spawn_bash_particles():
	if not bash_particle_scene:
		return
	
	var particles = bash_particle_scene.instantiate()
	get_parent().add_child(particles)
	particles.global_position = global_position

func play_random_sound(sound_array: Array[AudioStream]):
	if sound_array.is_empty() or not audio_player:
		return
	
	var sound = sound_array[randi() % sound_array.size()]
	audio_player.stream = sound
	audio_player.volume_db = linear_to_db(bash_sound_volume)
	audio_player.play()

# Utility functions
func get_current_velocity() -> Vector2:
	return velocity

func is_currently_bashed() -> bool:
	return is_bashed

func stop_movement():
	velocity = Vector2.ZERO
	is_bashed = false
	is_stunned = false
	rotation_velocity = 0.0
	base_position = global_position
	if enable_float:
		start_floating_animation()

func set_bash_immunity(immune: bool):
	if immune:
		remove_from_group("bashable")
	else:
		add_to_group("bashable")
