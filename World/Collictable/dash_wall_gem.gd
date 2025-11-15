extends Area2D

var animated_sprite: AnimatedSprite2D
var collision: CollisionShape2D
var particles: CPUParticles2D
var tween: Tween
var original_position: Vector2
var collected = false

# مدة التجميد (تقدر تغيّرها من الـ Inspector)
@export var freeze_time: float = 0.06
@export var collect_sounds: Array[AudioStream]   # أصوات عند الجمع
@export var respawn_sounds: Array[AudioStream]   # أصوات عند الـ Respawn
var audio_player: AudioStreamPlayer




# Respawn settings
@export var respawn_time: float = 10.0

# Random movement variables
var float_speed: float
var float_intensity: float
var rotation_speed: float
var start_delay: float

func _ready() -> void:
	$Outline.hide()
	original_position = position
	randomize_movement_properties()
	setup_components()
	setup_particles()
	
	# نضيف AudioStreamPlayer
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	audio_player.volume_db = -4
	audio_player.pitch_scale = 0.5

	
	# Add random start delay to desync all power-ups
	await get_tree().create_timer(start_delay).timeout
	start_floating_animation()

func randomize_movement_properties():
	# Random floating speed (1.5 to 4.5 seconds per cycle)
	float_speed = randf_range(1, 2.5)
	
	# Random floating intensity (8 to 18 pixels)
	float_intensity = randf_range(4, 10)
	
	# Random rotation speed for alternative animations
	rotation_speed = randf_range(2.0, 4.0)
	
	# Random start delay (0 to 2 seconds) to desync animations
	start_delay = randf_range(0.0, 2.0)

func setup_components():
	# Get existing children instead of creating new ones
	animated_sprite = $AnimatedSprite2D
	collision = $CollisionShape2D
	
	# Play your idle animation
	animated_sprite.play("idle")
	
	# Connect the body_entered signal

func setup_particles():
	# Create particles programmatically
	particles = CPUParticles2D.new()
	add_child(particles)
	
	# Configure particle properties
	particles.emitting = false
	particles.amount = 50
	particles.lifetime = 1.5
	particles.one_shot = true
	
	# Emission properties
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 20.0
	
	# Movement and physics
	particles.direction = Vector2(0, -1)
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 120.0
	particles.gravity = Vector2(0, 200)
	particles.angular_velocity_min = -180.0
	particles.angular_velocity_max = 180.0
	
	# Appearance
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.5
	particles.color = Color.CYAN
	particles.color_ramp = create_color_gradient()
	
	# Fading and scaling over time
	particles.scale_amount_curve = create_scale_curve()

func create_color_gradient() -> Gradient:
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color.WHITE)
	gradient.add_point(0.3, Color.CYAN)
	gradient.add_point(0.7, Color.DEEP_SKY_BLUE)
	gradient.add_point(1.0, Color.TRANSPARENT)
	return gradient

func create_scale_curve() -> Curve:
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.3, 1.3))
	curve.add_point(Vector2(0.8, 0.8))
	curve.add_point(Vector2(1.0, 0.0))
	return curve

func start_floating_animation():
	if collected:
		return
		
	tween = create_tween()
	tween.set_loops()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	# Use randomized speed for unique movement
	tween.tween_method(_update_float_position, 0.0, TAU, float_speed)

func _update_float_position(angle: float):
	if not collected:
		# Use randomized intensity for varied movement
		var float_offset = sin(angle) * float_intensity
		position.y = original_position.y + float_offset

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not collected:
		collected = true
		Global._can_wall_dash_flag = true
		play_collection_effect()
		
			# ✨ تجميد اللعبة
		get_tree().paused = true
		await get_tree().create_timer(freeze_time, true).timeout
		get_tree().paused = false

func play_collection_effect():
	# Stop floating animation
	if collect_sounds.size() > 0:
		var sound = collect_sounds[randi() % collect_sounds.size()]
		audio_player.stream = sound
		audio_player.play()
	if tween:
		tween.kill()
	
	# Disable collision to prevent multiple triggers
	collision.set_deferred("disabled", true)
	
	# Start particles
	$Outline.show()
	particles.emitting = true
	
	# Create collection animation tween
	var collection_tween = create_tween()
	collection_tween.set_parallel(true)  # Allow multiple animations simultaneously
	
	# Scale up then down animation
	collection_tween.tween_property(animated_sprite, "scale", Vector2(1.5, 1.5), 0.15)
	collection_tween.tween_property(animated_sprite, "scale", Vector2(0, 0), 0.3).set_delay(0.15)
	
	# Rotation animation
	collection_tween.tween_property(animated_sprite, "rotation", deg_to_rad(360), 0.45)
	
	# Fade out animation
	collection_tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.4)
	
	# Upward movement using individual property
	collection_tween.tween_property(self, "position:y", position.y - 30, 0.5)
	
	# Add a subtle scale pulse to the whole object
	collection_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	collection_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.1)
	
	# Start respawn timer instead of queue_free
	collection_tween.tween_callback(start_respawn_timer).set_delay(0.6)

func start_respawn_timer():
	# Wait for respawn time
	await get_tree().create_timer(respawn_time).timeout
	respawn()

func respawn():
	# Reset collected state
	collected = false
	$Outline.hide()
	
	# Reset position
	position = original_position
	
	# Re-enable collision
	collision.set_deferred("disabled", false)
	
	# Create respawn animation and particles
	play_respawn_effect()

func play_respawn_effect():
	if respawn_sounds.size() > 0:
		var sound = respawn_sounds[randi() % respawn_sounds.size()]
		audio_player.stream = sound
		audio_player.play()
	# Start respawn particles
	particles.emitting = true
	
	# Reset sprite properties for respawn animation
	animated_sprite.scale = Vector2(0, 0)
	animated_sprite.rotation = 0
	animated_sprite.modulate = Color.TRANSPARENT
	scale = Vector2(1.0, 1.0)
	
	# Create respawn tween
	var respawn_tween = create_tween()
	respawn_tween.set_parallel(true)
	
	# Scale in animation
	respawn_tween.tween_property(animated_sprite, "scale", Vector2(1.2, 1.2), 0.3)
	respawn_tween.tween_property(animated_sprite, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.3)
	
	# Fade in animation
	respawn_tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.4)
	
	# Gentle rotation during spawn
	respawn_tween.tween_property(animated_sprite, "rotation", deg_to_rad(180), 0.5)
	
	# Bounce effect
	respawn_tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.2).set_delay(0.3)
	respawn_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3).set_delay(0.5)
	
	# Start floating animation again after respawn effect
	respawn_tween.tween_callback(restart_floating_animation).set_delay(0.8)

func restart_floating_animation():
	# Randomize movement properties again for variety
	randomize_movement_properties()
	
	# Reset sprite rotation to 0 for clean floating animation
	animated_sprite.rotation = 0
	
	# Start floating animation
	start_floating_animation()

# Alternative floating patterns you can use by calling them instead of start_floating_animation():

func start_pulse_animation():
	if collected:
		return
		
	tween = create_tween()
	tween.set_loops()
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# Random pulsing speed and scale
	var pulse_duration = randf_range(0.6, 1.2)
	var pulse_scale = randf_range(1.15, 1.35)
	
	tween.tween_property(animated_sprite, "scale", Vector2(pulse_scale, pulse_scale), pulse_duration)
	tween.tween_property(animated_sprite, "scale", Vector2(1.0, 1.0), pulse_duration)

func start_rotation_float_animation():
	if collected:
		return
		
	# Use tween_method for position animation with random speed
	var pos_tween = create_tween()
	pos_tween.set_loops()
	pos_tween.tween_method(_update_rotation_float, 0.0, TAU, float_speed)
	
	# Separate rotation animation with random speed
	var rot_tween = create_tween()
	rot_tween.set_loops()
	rot_tween.tween_property(animated_sprite, "rotation", deg_to_rad(360), rotation_speed)

func _update_rotation_float(angle: float):
	if not collected:
		# Use randomized intensity
		var float_offset = sin(angle) * float_intensity * 0.8
		position.y = original_position.y + float_offset

func start_figure_eight_animation():
	if collected:
		return
		
	tween = create_tween()
	tween.set_loops()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	# Random figure-8 speed and size
	var fig8_speed = randf_range(3.0, 6.0)
	tween.tween_method(_update_oval_position, 0.0, TAU, fig8_speed)

func _update_oval_position(angle: float):
	if not collected:
		# Random oval size
		var x_intensity = randf_range(6.0, 12.0)
		var y_intensity = randf_range(10.0, 16.0)
		
		var offset_x = sin(angle) * x_intensity
		var offset_y = sin(angle * 2) * y_intensity
		position = original_position + Vector2(offset_x, offset_y)
