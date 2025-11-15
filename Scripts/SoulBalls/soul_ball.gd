extends Node2D

@export var collectible_id: String = ""

@onready var sprite = $AnimatedSprite2D
@onready var area = $Area2D
@onready var collision = $Area2D/CollisionShape2D
@onready var detection_area = $EnemyDetectionArea  # Reference to manually created detection area

# === IDLE FLOATING ===
@export_group("Idle Floating")
@export var idle_enabled: bool = true
@export var idle_float_amplitude: float = 8.0
@export var idle_float_speed: float = 1.5
@export var idle_wobble_amplitude: float = 5.0
@export var idle_wobble_speed: float = 2.0
@export var idle_pattern_variation: float = 0.3

# === FOLLOW BEHAVIOR (CELESTE-STYLE) ===
@export_group("Follow Settings")
@export var follow_delay: float = 0.15  # Lower delay for more responsive following
@export var follow_speed: float = 200.0  # Direct pixel speed
@export var follow_acceleration: float = 12.0  # How fast it accelerates
@export var follow_min_distance: float = 8.0  # Minimum distance to maintain
@export var follow_max_distance: float = 400.0  # Teleport threshold
@export var follow_deceleration: float = 15.0  # How fast it slows down
@export var flip_with_player: bool = true

# === VISUAL EFFECTS ===
@export_group("Visual Effects")
@export var pulse_enabled: bool = true
@export var pulse_speed: float = 3.5
@export var pulse_amount: float = 0.08
@export var squash_stretch_enabled: bool = true
@export var squash_stretch_amount: float = 0.12
@export var float_bob_sprite: bool = true

# === TARGET ===
@export_group("Target")
@export var player: Node2D

# === COLLECTION ===
@export_group("Collection")
@export var collect_on_touch: bool = true
@export var collection_duration: float = 0.5
@export var collection_jump_height: float = 40.0
@export var collection_spin_speed: float = 8.0

# === AUDIO ===
@export_group("Audio")
@export var collect_sound: AudioStream

# === COMBAT ===
@export_group("Combat")
@export var combat_enabled: bool = true
@export var bullet_scene: PackedScene  # Optional: assign a bullet scene
@export var shoot_cooldown: float = 0.5  # Time between shots
@export var bullet_speed: float = 400.0
@export var bullet_damage: float = 10.0
@export var detection_range: float = 200.0  # How far to detect enemies
@export var shoot_sound: AudioStream

# Internal variables
var time_passed: float = 0.0
var spawn_position: Vector2
var velocity: Vector2 = Vector2.ZERO
var is_collected: bool = false
var player_target: Node2D = null
var random_seed: Vector2
var target_position: Vector2
var sprite_offset: Vector2 = Vector2.ZERO
var current_flip: float = 1.0  # Track current flip direction
var shoot_timer: float = 0.0
var current_target_enemy: Node2D = null

func _ready():
	# Auto-generate collectible ID if not set
	if collectible_id == "":
		collectible_id = get_tree().current_scene.scene_file_path + ":" + get_path()

	# Check if already collected
	if Global.is_collectible_collected(collectible_id):
		queue_free()
		return

	spawn_position = global_position
	target_position = global_position
	random_seed = Vector2(randf_range(0, TAU), randf_range(0, TAU))

	if player:
		player_target = player

	if area:
		area.body_entered.connect(_on_body_entered)
		area.area_entered.connect(_on_area_entered)

	if sprite and sprite.sprite_frames:
		if sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")
		elif sprite.sprite_frames.has_animation("default"):
			sprite.play("default")

func _process(delta):
	if is_collected:
		return
	
	time_passed += delta
	shoot_timer -= delta
	
	if Global.follow and player_target and is_instance_valid(player_target):
		_follow_player(delta)
	else:
		_idle_float(delta)
	
	_apply_visual_effects(delta)
	_update_sprite_flip()
	
	# Combat system
	if combat_enabled:
		_detect_and_shoot_enemies(delta)

func _idle_float(delta):
	if not idle_enabled:
		return
	
	# Smooth figure-8 floating pattern
	var float_x = sin(time_passed * idle_wobble_speed + random_seed.x) * idle_wobble_amplitude
	var float_y = sin(time_passed * idle_float_speed + random_seed.y) * idle_float_amplitude
	
	float_x += cos(time_passed * idle_wobble_speed * 0.5 + random_seed.x) * (idle_wobble_amplitude * 0.3)
	float_y += cos(time_passed * idle_float_speed * 1.3 + random_seed.y) * (idle_float_amplitude * 0.4)
	
	target_position = spawn_position + Vector2(float_x, float_y)
	
	# Smooth movement to target with velocity
	var direction = global_position.direction_to(target_position)
	var distance = global_position.distance_to(target_position)
	
	if distance > 1.0:
		velocity = velocity.move_toward(direction * min(distance * 3.0, 100.0), delta * 300.0)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, delta * 200.0)
	
	global_position += velocity * delta

func _follow_player(delta):
	if not is_instance_valid(player_target):
		player_target = null
		return
	
	var player_pos = player_target.global_position
	var distance = global_position.distance_to(player_pos)
	
	# Only teleport if REALLY far (no more random teleporting)
	if distance > follow_max_distance:
		# Smooth teleport with interpolation
		global_position = global_position.lerp(player_pos, 0.5)
		velocity *= 0.5
		return
	
	# Delayed target position (Celeste-style trailing)
	var delay_offset = velocity * -follow_delay
	target_position = player_pos + delay_offset
	
	var target_distance = global_position.distance_to(target_position)
	
	# Dead zone - maintain minimum distance
	if target_distance < follow_min_distance:
		var decel_rate = follow_deceleration * 60.0
		velocity = velocity.move_toward(Vector2.ZERO, decel_rate * delta)
		global_position += velocity * delta
		return
	
	# Calculate movement direction
	var direction = global_position.direction_to(target_position)
	
	# Distance-based speed multiplier (faster when far, slower when close)
	var distance_multiplier = clamp(target_distance / 50.0, 0.5, 2.0)
	var target_speed = follow_speed * distance_multiplier
	
	# Smooth acceleration toward target velocity
	var target_velocity = direction * target_speed
	velocity = velocity.move_toward(target_velocity, delta * follow_acceleration * 60.0)
	
	# Apply velocity with smoothing
	global_position += velocity * delta

func _apply_visual_effects(delta):
	var base_scale = Vector2.ONE
	
	# Breathing pulse
	if pulse_enabled:
		var pulse = 1.0 + sin(time_passed * pulse_speed) * pulse_amount
		base_scale *= pulse
	
	# Squash and stretch based on velocity
	if squash_stretch_enabled and velocity.length() > 10.0:
		var speed_factor = clamp(velocity.length() / 300.0, 0.0, 1.0)
		var move_angle = velocity.angle()
		
		var stretch = 1.0 + speed_factor * squash_stretch_amount
		var squash = 1.0 / (1.0 + speed_factor * squash_stretch_amount * 0.5)
		
		var horizontal = lerp(squash, stretch, abs(cos(move_angle)))
		var vertical = lerp(squash, stretch, abs(sin(move_angle)))
		
		base_scale *= Vector2(horizontal, vertical)
	
	scale = scale.lerp(base_scale, delta * 18.0)
	
	# Sprite float bobbing
	if float_bob_sprite and sprite:
		sprite_offset.y = sin(time_passed * 2.5) * 1.5
		sprite.position = sprite.position.lerp(sprite_offset, delta * 10.0)

func _update_sprite_flip():
	if not flip_with_player or not player_target or not is_instance_valid(player_target):
		return
	
	# Get player's scale to detect flip direction
	var player_scale_x = player_target.scale.x
	
	# Smooth transition to match player flip
	if player_scale_x < 0:
		current_flip = lerp(current_flip, -1.0, 0.2)
	else:
		current_flip = lerp(current_flip, 1.0, 0.2)
	
	# Apply flip to sprite (not the whole node, just the visual)
	if sprite:
		sprite.scale.x = abs(sprite.scale.x) * sign(current_flip)

func _on_body_entered(body):
	if body.is_in_group("player"):
		if not player_target:
			player_target = body
		
		if collect_on_touch and not is_collected:
			collect()

func _on_area_entered(area_node):
	if area_node.is_in_group("player"):
		if not player_target:
			player_target = area_node.get_parent()
		
		if collect_on_touch and not is_collected:
			collect()

func collect():
	if is_collected:
		return

	is_collected = true

	# Register collectible with save system
	Global.register_collectible(collectible_id)
	Global.soul_balls_count += 1

	if collect_sound:
		var audio_player = AudioStreamPlayer2D.new()
		get_parent().add_child(audio_player)
		audio_player.stream = collect_sound
		audio_player.play()
		audio_player.finished.connect(audio_player.queue_free)

	var tween = create_tween()
	tween.set_parallel(true)

	var start_y = global_position.y
	tween.tween_property(self, "global_position:y", start_y - collection_jump_height, collection_duration * 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "global_position:y", start_y - collection_jump_height * 0.5, collection_duration * 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC).set_delay(collection_duration * 0.4)

	if sprite:
		tween.tween_property(sprite, "rotation", sprite.rotation + TAU * collection_spin_speed, collection_duration)

	tween.tween_property(self, "scale", Vector2.ONE * 1.3, collection_duration * 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ZERO, collection_duration * 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK).set_delay(collection_duration * 0.4)

	tween.tween_property(self, "modulate:a", 0.0, collection_duration * 0.5).set_delay(collection_duration * 0.5)

	await tween.finished
	queue_free()

# === UTILITY FUNCTIONS ===

func set_player_target(target: Node2D):
	player_target = target

func reset_to_spawn():
	player_target = null
	global_position = spawn_position
	velocity = Vector2.ZERO
	target_position = spawn_position

func set_spawn_position(pos: Vector2):
	spawn_position = pos

func add_impulse(impulse: Vector2):
	velocity += impulse

# === COMBAT SYSTEM ===

func _detect_and_shoot_enemies(delta):
	"""Find nearest enemy and shoot at it"""
	if shoot_timer > 0:
		return
	
	var nearest_enemy = _find_nearest_enemy()
	
	if nearest_enemy and is_instance_valid(nearest_enemy):
		_shoot_at_enemy(nearest_enemy)
		shoot_timer = shoot_cooldown

func _find_nearest_enemy() -> Node2D:
	"""Find the closest enemy in range"""
	if not detection_area:
		return null
	
	var nearest: Node2D = null
	var nearest_distance: float = INF
	
	# Check bodies in group "Enemy"
	var bodies = detection_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("Enemy") and is_instance_valid(body):
			var dist = global_position.distance_to(body.global_position)
			if dist < nearest_distance and dist <= detection_range:
				nearest_distance = dist
				nearest = body
	
	# Check areas in group "Enemy"
	var areas = detection_area.get_overlapping_areas()
	for area_node in areas:
		if area_node.is_in_group("Enemy") and is_instance_valid(area_node):
			var dist = global_position.distance_to(area_node.global_position)
			if dist < nearest_distance and dist <= detection_range:
				nearest_distance = dist
				nearest = area_node
	
	return nearest

func _create_default_bullet() -> Node2D:
	"""Create a simple default bullet if no scene is provided"""
	var bullet = Node2D.new()
	bullet.name = "SoulBullet"
	
	# Visual
	var sprite_node = Sprite2D.new()
	var texture = _create_bullet_texture()
	sprite_node.texture = texture
	sprite_node.modulate = Color(0.4, 0.8, 1.0)
	bullet.add_child(sprite_node)
	
	# Add a glow effect
	var glow = Sprite2D.new()
	glow.texture = texture
	glow.modulate = Color(0.6, 0.9, 1.0, 0.5)
	glow.scale = Vector2(1.5, 1.5)
	bullet.add_child(glow)
	
	# Collision
	var area_node = Area2D.new()
	bullet.add_child(area_node)
	
	var collision_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 4.0
	collision_shape.shape = circle
	area_node.add_child(collision_shape)
	
	# Script for bullet behavior
	var script_text = """
extends Node2D

var velocity: Vector2 = Vector2.ZERO
var damage: float = 10.0
var lifetime: float = 3.0

func _ready():
	var area = $Area2D
	area.body_entered.connect(_on_hit)
	area.area_entered.connect(_on_hit_area)

func _process(delta):
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func set_velocity(vel: Vector2):
	velocity = vel

func set_direction(dir: Vector2):
	velocity = dir * 400.0

func _on_hit(body):
	if body.is_in_group('Enemy'):
		if body.has_method('take_damage'):
			body.take_damage(damage)
		elif 'health' in body:
			body.health -= damage
		queue_free()

func _on_hit_area(area_node):
	if area_node.is_in_group('Enemy'):
		var parent = area_node.get_parent()
		if parent and parent.has_method('take_damage'):
			parent.take_damage(damage)
		elif parent and 'health' in parent:
			parent.health -= damage
		queue_free()
"""
	
	var bullet_script = GDScript.new()
	bullet_script.source_code = script_text
	bullet_script.reload()
	bullet.set_script(bullet_script)
	
	return bullet

func _create_bullet_texture() -> Texture2D:
	"""Create a simple circular texture for the bullet"""
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	
	for x in range(16):
		for y in range(16):
			var center = Vector2(8, 8)
			var dist = Vector2(x, y).distance_to(center)
			if dist <= 4.0:
				var alpha = 1.0 - (dist / 4.0) * 0.3
				img.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	return ImageTexture.create_from_image(img)
func _shoot_at_enemy(enemy: Node2D):
	"""Create and shoot a bullet at the same target the enemy is attacking"""
	# Try to find what the enemy is targeting
	var target_position = _get_enemy_target_position(enemy)
	
	if target_position == Vector2.ZERO:
		return  # No valid target found
	
	var bullet: Node2D
	
	# Use custom bullet scene if provided, otherwise create default
	if bullet_scene:
		bullet = bullet_scene.instantiate()
	else:
		bullet = _create_default_bullet()
	
	# Add bullet to scene
	get_parent().add_child(bullet)
	bullet.global_position = global_position
	
	# Calculate direction to the same target the enemy is attacking
	var direction = global_position.direction_to(target_position)
	bullet.rotation = direction.angle()
	
	# Set bullet velocity
	if bullet.has_method("set_velocity"):
		bullet.set_velocity(direction * bullet_speed)
	elif bullet.has_method("set_direction"):
		bullet.set_direction(direction)
	elif "velocity" in bullet:
		bullet.velocity = direction * bullet_speed
	elif "direction" in bullet:
		bullet.direction = direction
	
	# Set bullet damage
	if "damage" in bullet:
		bullet.damage = bullet_damage
	
	# Play shoot sound
	if shoot_sound:
		var audio_player = AudioStreamPlayer2D.new()
		add_child(audio_player)
		audio_player.stream = shoot_sound
		audio_player.play()
		audio_player.finished.connect(audio_player.queue_free)

func _get_enemy_target_position(enemy: Node2D) -> Vector2:
	"""Get the position of what the enemy is targeting"""
	# Method 1: Check if enemy has a target property
	if "target" in enemy and enemy.target and is_instance_valid(enemy.target):
		return enemy.target.global_position
	
	# Method 2: Check if enemy has a player_target property
	if "player_target" in enemy and enemy.player_target and is_instance_valid(enemy.player_target):
		return enemy.player_target.global_position
	
	# Method 3: Use our player_target as fallback
	if player_target and is_instance_valid(player_target):
		return player_target.global_position
	
	# Method 4: Try to find player in the scene
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node:
		return player_node.global_position
	
	return Vector2.ZERO  # No valid target found
