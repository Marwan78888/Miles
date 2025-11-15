extends RigidBody2D
# ============================================================
# PERFECT AREA-BASED PARRY BULLET SYSTEM WITH ZIGZAG & TRAIL
# ============================================================

# Bullet settings
@export var speed: float = 300.0
@export var direction: Vector2 = Vector2.LEFT
@export var lifetime: float = 10.0
@export var player_damage: int = 10
@export var enemy_damage: int = 15

# Zigzag settings
@export_group("Zigzag Movement")
@export var zigzag_amplitude: float = 15.0  # How far the bullet sways
@export var zigzag_frequency: float = 8.0   # How fast it zigzags

# Trail settings
@export_group("Trail Effect")
@export var trail_spawn_interval: float = 0.05  # How often to spawn trail sprites
@export var trail_lifetime: float = 0.3  # How long each trail sprite lives
@export var trail_spread: float = 8.0  # Random spread amount
@export var trail_color: Color = Color(1.0, 0.5, 0.2, 0.6)  # Trail color with transparency
@export var trail_initial_scale: float = 0.5  # Starting size of trail circles
@export var trail_final_scale: float = 0.1  # Ending size of trail circles

# Parry settings
@export_group("Parry Settings")
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

var player_in_parry_zone: bool = false
var is_being_destroyed: bool = false  # Prevent double destruction

# Zigzag & Trail state
var time_alive: float = 0.0
var trail_timer: float = 0.0
var active_trails: Array[Polygon2D] = []  # Track all trail sprites

# ============================================================
# READY
# ============================================================
func _ready() -> void:
	add_to_group("Bullet")
	
	# Collision setup - ENEMY BULLET
	collision_layer = 8  # Layer 4 (bullets)
	collision_mask = 3   # Layers 1+2 (player + walls)
	
	# Physics
	gravity_scale = 0.0
	lock_rotation = true
	contact_monitor = false  # Start disabled
	max_contacts_reported = 4
	
	# Set velocity
	linear_velocity = direction.normalized() * speed
	rotation = direction.angle()
	
	# Spawn protection timer
	spawn_timer = 0.1
	is_spawn_protected = true
	
	# Setup parry area
	setup_parry_area()
	
	# Auto-destroy after lifetime
	get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_expired)
	
	print("🔫 Bullet spawned | Team: ", team, " | Speed: ", speed)

func _on_lifetime_expired() -> void:
	"""Safe destruction after lifetime"""
	if not is_being_destroyed:
		destroy_bullet()

# ============================================================
# PARRY AREA SETUP
# ============================================================
func setup_parry_area() -> void:
	"""Connect parry area signals"""
	if not parry_area:
		push_warning("⚠️ No parry_area assigned! Add an Area2D child and assign it in inspector!")
		return
	
	# Configure parry area
	parry_area.monitoring = true
	parry_area.monitorable = false
	
	# Connect signals safely
	if not parry_area.body_entered.is_connected(_on_parry_area_entered):
		parry_area.body_entered.connect(_on_parry_area_entered)
	
	if not parry_area.body_exited.is_connected(_on_parry_area_exited):
		parry_area.body_exited.connect(_on_parry_area_exited)
	
	print("✅ Parry area connected")

func _on_parry_area_entered(body: Node) -> void:
	"""Player entered parry zone"""
	if is_being_destroyed or is_reflected:
		return
		
	if body.is_in_group("player") and team == "enemy":
		player_in_parry_zone = true
		print("🎯 Player in parry zone!")
		flash_warning()

func _on_parry_area_exited(body: Node) -> void:
	"""Player left parry zone"""
	if is_being_destroyed:
		return
		
	if body.is_in_group("player"):
		player_in_parry_zone = false
		print("🚪 Player left parry zone")
		stop_warning_flash()

# ============================================================
# PHYSICS PROCESS - WITH ZIGZAG & TRAIL
# ============================================================
func _physics_process(delta: float) -> void:
	if is_being_destroyed:
		return
	
	# Update time
	time_alive += delta
	trail_timer += delta
	
	# Handle spawn protection
	if is_spawn_protected:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			is_spawn_protected = false
			contact_monitor = true
			if not body_entered.is_connected(_on_body_entered):
				body_entered.connect(_on_body_entered)
			print("✅ Spawn protection ended")
	
	# CHECK FOR PARRY INPUT (only for enemy bullets)
	if player_in_parry_zone and team == "enemy" and not is_reflected and not is_spawn_protected:
		if Input.is_action_just_pressed("hit"):
			perform_parry()
			return
	
	# ZIGZAG MOVEMENT
	var perpendicular = Vector2(-direction.y, direction.x)
	var zigzag_offset = sin(time_alive * zigzag_frequency) * zigzag_amplitude
	
	# Apply movement with zigzag
	var target_velocity = (direction.normalized() + perpendicular * zigzag_offset * 0.01) * speed
	linear_velocity = target_velocity
	
	# Update rotation to match direction (optional - remove if you want fixed rotation)
	# rotation = linear_velocity.angle()
	
	# SPAWN TRAIL SPRITES
	if trail_timer >= trail_spawn_interval:
		trail_timer = 0.0
		_spawn_trail_sprite()

# ============================================================
# TRAIL SYSTEM - FIXED VERSION
# ============================================================
func _spawn_trail_sprite() -> void:
	# Create a circular trail sprite using a simple polygon
	var trail = Polygon2D.new()
	
	# Create circle vertices
	var circle_points: PackedVector2Array = []
	var segments = 16  # Number of segments for the circle
	var radius = 10.0  # Base radius for the circle
	
	for i in range(segments):
		var angle = (i * TAU) / segments
		circle_points.append(Vector2(cos(angle), sin(angle)) * radius)
	
	trail.polygon = circle_points
	trail.color = trail_color
	trail.global_position = global_position
	trail.scale = Vector2.ONE * trail_initial_scale
	trail.z_index = z_index - 1
	
	# Add random spread offset
	var spread_offset = Vector2(
		randf_range(-trail_spread, trail_spread),
		randf_range(-trail_spread, trail_spread)
	)
	trail.global_position += spread_offset
	
	# Add slight random rotation
	trail.rotation = randf_range(0, TAU)
	
	# Add to scene (not as child, so it stays in place)
	get_parent().add_child(trail)
	
	# Track this trail
	active_trails.append(trail)
	
	# Animate the trail sprite
	_animate_trail_sprite(trail)

func _animate_trail_sprite(trail: Polygon2D) -> void:
	# Use SceneTreeTween instead of owned tween
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	
	# Fade out - create a new color with fading alpha
	var fade_color = trail_color
	fade_color.a = 0.0
	tween.tween_property(trail, "color", fade_color, trail_lifetime)
	
	# Shrink to final scale
	tween.tween_property(trail, "scale", Vector2.ONE * trail_final_scale, trail_lifetime)
	
	# Slight rotation
	tween.tween_property(trail, "rotation", trail.rotation + randf_range(-1.0, 1.0), trail_lifetime)
	
	# Delete after lifetime and remove from tracking
	tween.finished.connect(func(): 
		active_trails.erase(trail)
		if is_instance_valid(trail):
			trail.queue_free()
	)

func _cleanup_trails() -> void:
	"""Force cleanup all trail sprites"""
	for trail in active_trails:
		if is_instance_valid(trail):
			trail.queue_free()
	active_trails.clear()

# ============================================================
# HELPER FUNCTIONS
# ============================================================
func is_wall_or_environment(body: Node) -> bool:
	"""Check if body is a wall or environment (supports TileMapLayer and StaticBody2D)"""
	# Check groups first
	if body.is_in_group("wall") or body.is_in_group("environment"):
		return true
	
	# Check if it's a TileMapLayer (Godot 4.x tilemaps)
	if body is TileMapLayer:
		return true
	
	# Check if it's a TileMap (Godot 3.x tilemaps, for compatibility)
	if body.get_class() == "TileMap":
		return true
	
	# Check if it's a StaticBody2D with collision layer 2 (walls)
	if body is StaticBody2D:
		if body.collision_layer & 2:  # Layer 2 = walls
			return true
	
	# Check if it's a CharacterBody2D or RigidBody2D acting as wall
	if body is CharacterBody2D or body is RigidBody2D:
		if body.collision_layer & 2:  # Layer 2 = walls
			return true
	
	return false

# ============================================================
# COLLISION HANDLING - PERFECT VERSION
# ============================================================
func _on_body_entered(body: Node) -> void:
	if is_being_destroyed:
		return
	
	print("💥 Collision with: ", body.name, " | Team: ", team, " | Reflected: ", is_reflected)
	
	# ============================================================
	# ENEMY BULLET (not reflected yet)
	# ============================================================
	if team == "enemy" and not is_reflected:
		# Hit player - damage and destroy
		if body.is_in_group("player"):
			print("💔 BULLET HIT PLAYER!")
			damage_player(body)
			trigger_hit_screen_shake()
			create_impact_effect(global_position, Color.ORANGE_RED)
			destroy_bullet()
			return
		
		# Hit wall or environment - destroy
		if is_wall_or_environment(body):
			print("🧱 Hit wall/environment")
			create_impact_effect(global_position, Color.ORANGE_RED)
			destroy_bullet()
			return
	
	# ============================================================
	# REFLECTED BULLET (parried by player)
	# ============================================================
	elif team == "player" and is_reflected:
		# Hit boss - damage and destroy
		if body.is_in_group("boss"):
			print("💥💥 REFLECTED BULLET HIT BOSS!")
			damage_boss(body)
			create_impact_effect(global_position, Color.CYAN)
			destroy_bullet()
			return
		
		# Hit enemy - damage and destroy
		if body.is_in_group("enemy"):
			print("💥 REFLECTED BULLET HIT ENEMY!")
			damage_enemy(body)
			create_impact_effect(global_position, Color.CYAN)
			destroy_bullet()
			return
		
		# Hit wall or environment - destroy
		if is_wall_or_environment(body):
			print("🧱 Reflected bullet hit wall")
			create_impact_effect(global_position, Color.CYAN)
			destroy_bullet()
			return
		
		# Hit player (shouldn't happen but just in case) - destroy without damage
		if body.is_in_group("player"):
			print("⚠️ Reflected bullet touched player")
			destroy_bullet()
			return

# ============================================================
# DAMAGE FUNCTIONS
# ============================================================
func damage_player(player: Node) -> void:
	"""Deal damage to player"""
	if player.has_method("take_damage"):
		player.take_damage(player_damage)
	elif player.has_method("damage"):
		player.damage(player_damage)
	elif player.has_method("hurt"):
		player.hurt(player_damage)

func damage_boss(boss: Node) -> void:
	"""Deal damage to boss"""
	if boss.has_method("take_damage"):
		boss.take_damage(enemy_damage)
	elif boss.has_method("damage"):
		boss.damage(enemy_damage)
	elif boss.has_method("hurt"):
		boss.hurt(enemy_damage)

func damage_enemy(enemy: Node) -> void:
	"""Deal damage to regular enemy"""
	if enemy.has_method("take_damage"):
		enemy.take_damage(enemy_damage)
	elif enemy.has_method("damage"):
		enemy.damage(enemy_damage)
	elif enemy.has_method("hurt"):
		enemy.hurt(enemy_damage)

# ============================================================
# PARRY EXECUTION - PERFECT VERSION
# ============================================================
func perform_parry() -> void:
	"""Execute the parry - reverse bullet direction"""
	if is_being_destroyed or is_reflected:
		return
	
	print("✨✨✨ PERFECT PARRY! ✨✨✨")
	
	# Clear state
	player_in_parry_zone = false
	
	# Mark as reflected
	is_reflected = true
	team = "player"
	is_spawn_protected = false
	
	# REVERSE DIRECTION COMPLETELY
	var reflected_speed = speed * parry_speed_multiplier
	
	# Calculate opposite direction
	var new_direction = -direction.normalized()
	
	# Apply new velocity
	linear_velocity = new_direction * reflected_speed
	direction = new_direction
	rotation = direction.angle()
	
	# Change trail color to cyan for reflected bullets
	trail_color = Color(0.3, 0.8, 1.0, 0.6)
	
	print("  🔄 NEW Direction: ", direction)
	print("  🔄 NEW Velocity: ", linear_velocity)
	print("  🔄 Speed increase: ", speed, " → ", reflected_speed)
	
	# Change collision to hit enemies AND walls
	collision_layer = 4   # Bullet layer
	collision_mask = 6    # Layers 2+3 (walls + enemies)
	contact_monitor = true
	
	# Disable parry area (can't parry again)
	if parry_area:
		parry_area.monitoring = false
		parry_area.body_entered.disconnect(_on_parry_area_entered)
		parry_area.body_exited.disconnect(_on_parry_area_exited)
	
	# Trigger all effects
	stop_warning_flash()
	flash_bullet()
	spawn_parry_particles()
	trigger_freeze_frame()
	trigger_parry_screen_shake()
	play_parry_sound()

# ============================================================
# DESTROY BULLET - SAFE DESTRUCTION WITH TRAIL CLEANUP
# ============================================================
func destroy_bullet() -> void:
	"""Safely destroy the bullet (prevents double-destruction)"""
	if is_being_destroyed:
		return
	
	is_being_destroyed = true
	
	# Clean up all active trails immediately
	_cleanup_trails()
	
	# Disable all collision immediately
	set_physics_process(false)
	contact_monitor = false
	collision_layer = 0
	collision_mask = 0
	
	# Disable parry area
	if parry_area:
		parry_area.monitoring = false
		if parry_area.body_entered.is_connected(_on_parry_area_entered):
			parry_area.body_entered.disconnect(_on_parry_area_entered)
		if parry_area.body_exited.is_connected(_on_parry_area_exited):
			parry_area.body_exited.disconnect(_on_parry_area_exited)
	
	# Stop all movement
	linear_velocity = Vector2.ZERO
	
	# Destroy
	queue_free()
	print("🗑️ Bullet destroyed")

# ============================================================
# VISUAL EFFECTS
# ============================================================
func flash_warning() -> void:
	"""Flash red to warn player they can parry"""
	if is_being_destroyed:
		return
		
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

func trigger_parry_screen_shake() -> void:
	"""Shake the camera on successful parry"""
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	# Try room_camera group method first
	var room_camera = get_tree().get_first_node_in_group("room_camera")
	if room_camera and room_camera.has_method("screen_shake"):
		room_camera.screen_shake(parry_shake_intensity, parry_shake_duration)
		return
	
	# Fallback to manual shake
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
		return
	
	# Try room_camera group method first
	var room_camera = get_tree().get_first_node_in_group("room_camera")
	if room_camera and room_camera.has_method("screen_shake"):
		room_camera.screen_shake(hit_shake_intensity, hit_shake_duration)
		return
	
	# Fallback to manual shake
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
