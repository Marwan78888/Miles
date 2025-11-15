extends RigidBody2D
# ============================================================
# AREA-BASED PARRY BULLET SYSTEM
# ============================================================

# Bullet settings
@export var speed: float = 300.0
@export var direction: Vector2 = Vector2.LEFT
@export var lifetime: float = 10.0
@export var player_damage: int = 10
@export var enemy_damage: int = 15

# Parry settings
@export var parry_speed_multiplier: float = 1.5
@export var parry_freeze_duration: float = 0.1
@export var parry_shake_intensity: float = 4.0
@export var parry_shake_duration: float = 0.2

# Hit shake settings
@export var hit_shake_intensity: float = 6.0
@export var hit_shake_duration: float = 0.3

# Area-based parry
@export var parry_area: Area2D  # ⚙️ Assign in Inspector!

# State
var is_reflected: bool = false
var team: String = "enemy"
var is_spawn_protected: bool = true
var spawn_timer: float = 0.1

var player_in_parry_zone: bool = false  # Is player inside parry area?

# ============================================================
# READY
# ============================================================
func _ready() -> void:
	add_to_group("Bullet")
	
	# Collision setup
	collision_layer = 8  # Layer 4 (bullets)
	collision_mask = 3   # Layers 1+2 (player + walls)
	
	# Physics
	gravity_scale = 0.0
	lock_rotation = true
	contact_monitor = false
	max_contacts_reported = 4
	
	# Set velocity
	linear_velocity = direction.normalized() * speed
	rotation = direction.angle()
	
	# Spawn protection
	spawn_timer = 0.1
	is_spawn_protected = true
	
	# Setup parry area
	setup_parry_area()
	
	# Auto-destroy
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	
	print("🔫 Bullet spawned | Speed: ", speed, " | Direction: ", direction)

# ============================================================
# PARRY AREA SETUP
# ============================================================
func setup_parry_area() -> void:
	"""Connect parry area signals"""
	if not parry_area:
		print("⚠️ WARNING: No parry_area assigned! Add an Area2D child and assign it in inspector!")
		return
	
	# Connect area signals
	if not parry_area.body_entered.is_connected(_on_parry_area_entered):
		parry_area.body_entered.connect(_on_parry_area_entered)
	
	if not parry_area.body_exited.is_connected(_on_parry_area_exited):
		parry_area.body_exited.connect(_on_parry_area_exited)
	
	print("✅ Parry area connected")

func _on_parry_area_entered(body: Node) -> void:
	"""Player entered parry zone"""
	if body.is_in_group("player") and team == "enemy" and not is_reflected:
		player_in_parry_zone = true
		print("🎯 Player in parry zone!")
		flash_warning()

func _on_parry_area_exited(body: Node) -> void:
	"""Player left parry zone"""
	if body.is_in_group("player"):
		player_in_parry_zone = false
		print("🚪 Player left parry zone")
		stop_warning_flash()

# ============================================================
# PHYSICS PROCESS
# ============================================================
func _physics_process(delta: float) -> void:
	# Handle spawn protection
	if is_spawn_protected:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			is_spawn_protected = false
			contact_monitor = true
			if not body_entered.is_connected(_on_body_entered):
				body_entered.connect(_on_body_entered)
			print("✅ Spawn protection ended")
	
	# CHECK FOR PARRY INPUT
	if player_in_parry_zone and not is_reflected and not is_spawn_protected:
		if Input.is_action_just_pressed("hit"):
			perform_parry()
			return
	
	# Maintain velocity (only for non-reflected bullets)
	if not is_reflected:
		if linear_velocity.length() < speed * 0.5:
			linear_velocity = direction.normalized() * speed
	
	# Update rotation
	if linear_velocity.length() > 0:
		direction = linear_velocity.normalized()
		rotation = direction.angle()

# ============================================================
# COLLISION HANDLING
# ============================================================
func _on_body_entered(body: Node) -> void:
	if is_spawn_protected or is_reflected:
		return
	
	print("💥 Collision: ", body.name, " | Team: ", team)
	
	# BULLET HIT PLAYER - DAMAGE AND SHAKE
	if body.is_in_group("player") and team == "enemy":
		print("💔 BULLET HIT PLAYER!")
		
		# Deal damage
		if body.has_method("take_damage"):
			body.take_damage(player_damage)
		elif body.has_method("damage"):
			body.damage(player_damage)
		elif body.has_method("hurt"):
			body.hurt(player_damage)
		
		# Screen shake on hit
		trigger_hit_screen_shake()
		
		# Impact effect
		create_impact_effect(global_position, Color.ORANGE_RED)
		
		# Destroy bullet
		queue_free()
		return
	
	# REFLECTED BULLET - damages enemies
	if is_reflected and team == "player":
		if body.is_in_group("enemy") or body.is_in_group("boss"):
			print("💥💥 REFLECTED BULLET HIT ENEMY!")
			
			if body.has_method("take_damage"):
				body.take_damage(enemy_damage)
			elif body.has_method("damage"):
				body.damage(enemy_damage)
			elif body.has_method("hurt"):
				body.hurt(enemy_damage)
			
			create_impact_effect(body.global_position, Color.CYAN)
			queue_free()
			return
		
		# Hit wall
		if body.is_in_group("wall") or body.is_in_group("environment"):
			create_impact_effect(global_position, Color.CYAN)
			queue_free()
			return
	
	# Hit wall (normal bullet)
	if body.is_in_group("wall") or body.is_in_group("environment"):
		create_impact_effect(global_position, Color.ORANGE_RED)
		queue_free()
		return

# ============================================================
# PARRY EXECUTION
# ============================================================
func perform_parry() -> void:
	"""Execute the parry - reverse bullet direction"""
	print("✨✨✨ PERFECT PARRY! ✨✨✨")
	
	# Clear state
	player_in_parry_zone = false
	
	# Mark as reflected
	is_reflected = true
	team = "player"
	is_spawn_protected = false
	
	# REVERSE DIRECTION COMPLETELY
	var old_velocity = linear_velocity
	var reflected_speed = speed * parry_speed_multiplier
	
	# Calculate opposite direction
	var new_direction = -direction.normalized()
	
	# Apply new velocity
	linear_velocity = new_direction * reflected_speed
	direction = new_direction
	rotation = direction.angle()
	
	print("  🔄 OLD Velocity: ", old_velocity)
	print("  🔄 NEW Velocity: ", linear_velocity)
	print("  🔄 Speed increase: ", speed, " → ", reflected_speed)
	
	# Change collision to hit enemies AND walls
	collision_layer = 4   # Bullet layer
	collision_mask = 6    # Layers 2+3 (walls + enemies)
	contact_monitor = true
	
	# Disable parry area (can't parry again)
	if parry_area:
		parry_area.monitoring = false
	
	# Trigger all effects
	stop_warning_flash()
	flash_bullet()
	spawn_parry_particles()
	trigger_freeze_frame()
	trigger_parry_screen_shake()
	play_parry_sound()

# ============================================================
# VISUAL EFFECTS
# ============================================================
func flash_warning() -> void:
	"""Flash red to warn player they can parry"""
	var sprite = get_node_or_null("Sprite2D")
	if not sprite:
		sprite = get_node_or_null("AnimatedSprite2D")
	
	if sprite:
		var tween = create_tween()
		tween.set_loops(0)  # Infinite loop while in zone
		tween.tween_property(sprite, "modulate", Color.RED, 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func stop_warning_flash() -> void:
	"""Stop the warning flash"""
	var sprite = get_node_or_null("Sprite2D")
	if not sprite:
		sprite = get_node_or_null("AnimatedSprite2D")
	
	if sprite:
		# Kill all tweens on sprite
		var tweens = get_tree().get_processed_tweens()
		for tween in tweens:
			if tween.is_valid():
				tween.kill()
		
		sprite.modulate = Color.WHITE

func flash_bullet() -> void:
	"""Flash bullet cyan when parried"""
	var sprite = get_node_or_null("Sprite2D")
	if not sprite:
		sprite = get_node_or_null("AnimatedSprite2D")
	
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.CYAN, 0.05)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
		tween.tween_property(sprite, "modulate", Color(0.5, 1, 1), 0.1)

func spawn_parry_particles() -> void:
	"""Spawn epic particle burst at parry location"""
	var particles = CPUParticles2D.new()
	particles.global_position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 30
	particles.lifetime = 0.6
	particles.explosiveness = 1.0
	
	# Particle settings
	particles.direction = Vector2.ZERO
	particles.spread = 180
	particles.initial_velocity_min = 150
	particles.initial_velocity_max = 250
	particles.gravity = Vector2(0, 200)
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	particles.color = Color.CYAN
	
	get_parent().add_child(particles)
	get_tree().create_timer(1.0).timeout.connect(particles.queue_free)

func trigger_freeze_frame() -> void:
	"""Freeze the game briefly for impact"""
	get_tree().paused = true
	await get_tree().create_timer(parry_freeze_duration, true, false, true).timeout
	get_tree().paused = false
	print("⏸️ Freeze frame: ", parry_freeze_duration, "s")

func trigger_parry_screen_shake() -> void:
	"""Shake the camera on successful parry"""
	var camera = get_viewport().get_camera_2d()
	if not camera:
		print("⚠️ No camera found")
		return
	
	var original_offset = camera.offset
	var shake_tween = create_tween()
	shake_tween.set_parallel(false)
	
	var shake_count = 8
	var interval = parry_shake_duration / shake_count
	
	for i in range(shake_count):
		var decay = 1.0 - (float(i) / shake_count)
		var intensity = parry_shake_intensity * decay
		
		var offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		
		shake_tween.tween_property(camera, "offset", original_offset + offset, interval)
	
	shake_tween.tween_property(camera, "offset", original_offset, interval * 0.5)

func trigger_hit_screen_shake() -> void:
	"""Shake the camera when bullet hits player"""
	var camera = get_viewport().get_camera_2d()
	if not camera:
		print("⚠️ No camera found")
		return
	
	var original_offset = camera.offset
	var shake_tween = create_tween()
	shake_tween.set_parallel(false)
	
	var shake_count = 10
	var interval = hit_shake_duration / shake_count
	
	for i in range(shake_count):
		var decay = 1.0 - (float(i) / shake_count)
		var intensity = hit_shake_intensity * decay
		
		var offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		
		shake_tween.tween_property(camera, "offset", original_offset + offset, interval)
	
	shake_tween.tween_property(camera, "offset", original_offset, interval * 0.5)
	print("📳 Hit screen shake triggered!")

func play_parry_sound() -> void:
	"""Play parry sound effect"""
	var audio = AudioStreamPlayer2D.new()
	audio.bus = "SFX"
	add_child(audio)
	
	# Add your parry sound here:
	# audio.stream = preload("res://sounds/parry.wav")
	# audio.play()
	
	get_tree().create_timer(2.0).timeout.connect(audio.queue_free)

func create_impact_effect(pos: Vector2, color: Color) -> void:
	"""Create impact particles"""
	var impact = CPUParticles2D.new()
	impact.global_position = pos
	impact.emitting = true
	impact.one_shot = true
	impact.amount = 15
	impact.lifetime = 0.4
	impact.explosiveness = 1.0
	impact.spread = 180
	impact.initial_velocity_min = 80
	impact.initial_velocity_max = 150
	impact.color = color
	impact.scale_amount_min = 2.0
	impact.scale_amount_max = 4.0
	
	get_parent().add_child(impact)
	get_tree().create_timer(0.6).timeout.connect(impact.queue_free)
