extends Area2D

# Heart Crystal Collectible Script
# Complete implementation with floating, following, and collection effects
@export var touch_sounds: Array[AudioStream] = []
@export var collect_sounds: Array[AudioStream] = []
@export var float_amplitude: float = 3 # How high/low it floats
@export var float_speed: float = 2.0       # Speed of floating animation
@export var follow_speed: float = 5.0      # How fast it follows the player
@export var follow_distance: float = 20  # Distance above player
@export var ground_wait_time: float = 2.0  # Time to wait after player touches ground
@export var pitch_scale : float = 1

# Node references
var animated_sprite: AnimatedSprite2D
var collision_shape: CollisionShape2D

# State variables
var player: Node2D = null
var is_collected: bool = false
var is_following: bool = false
var original_position: Vector2
var float_time: float = 0.0
var follow_offset: Vector2 = Vector2.ZERO  # Random offset for natural movement
var waiting_for_ground: bool = false
var ground_wait_timer: float = 0.0
var player_was_on_ground: bool = false
var audio_player: AudioStreamPlayer2D

func _ready():
	animated_sprite = $AnimatedSprite2D
	animated_sprite.play("idle")

	collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16
	collision_shape.shape = shape
	add_child(collision_shape)

	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	audio_player.pitch_scale = 0.3
	audio_player.volume_db = -1
	

	original_position = global_position
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	start_idle_animation()

func _process(delta):
	if is_collected:
		return
		
	if is_following and player:
		follow_player(delta)
		check_player_ground_status()
		
		# If waiting for ground timer, count down
		if waiting_for_ground:
			ground_wait_timer += delta
			if ground_wait_timer >= ground_wait_time:
				collect()
	else:
		idle_float(delta)

func start_idle_animation():
	"""Start the idle floating animation"""
	if not is_following:
		float_time = 0.0

func idle_float(delta):
	"""Gentle up and down floating motion"""
	float_time += delta * float_speed
	var float_offset = sin(float_time) * float_amplitude
	global_position.y = original_position.y + float_offset

func follow_player(delta):
	"""Make the crystal follow the player naturally"""
	if not player:
		return
		
	# Calculate target position (above the player with natural offset)
	var base_target = player.global_position + Vector2(0, -follow_distance)
	
	# Add natural floating motion while following
	float_time += delta * float_speed * 0.7  # Slightly slower float while following
	var float_offset = Vector2(
		sin(float_time) * (float_amplitude * 0.3),  # Gentle side-to-side
		cos(float_time * 1.3) * (float_amplitude * 0.4)  # Up and down with different frequency
	)
	
	# Add the random offset for more natural movement
	var target_pos = base_target + follow_offset + float_offset
	
	# Smooth movement towards target
	global_position = global_position.lerp(target_pos, follow_speed * delta)
	
	# Slowly change the random offset for natural drift
	follow_offset = follow_offset.lerp(
		Vector2(randf_range(-15, 15), randf_range(-10, 10)), 
		0.5 * delta
	)

func check_player_ground_status():
	"""Check if player is touching the ground"""
	if not player:
		return
		
	var is_on_ground = false
	
	# Method 1: Check if player has is_on_floor() method (CharacterBody2D)
	if player.has_method("is_on_floor"):
		is_on_ground = player.is_on_floor()
	# Method 2: Check if player has is_grounded property or method
	elif player.has_method("is_grounded"):
		is_on_ground = player.is_grounded()
	elif "is_grounded" in player:
		is_on_ground = player.is_grounded
	# Method 3: Raycast check if player doesn't have ground detection
	else:
		is_on_ground = check_ground_with_raycast()
	
	# If player just touched ground, start waiting
	if is_on_ground and not player_was_on_ground and not waiting_for_ground:
		waiting_for_ground = true
		ground_wait_timer = 0.0
	
	player_was_on_ground = is_on_ground

func check_ground_with_raycast() -> bool:
	"""Fallback ground check using raycast from player position"""
	if not player:
		return false
		
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		player.global_position,
		player.global_position + Vector2(0, 10)  # Short ray downward
	)
	query.exclude = [player]  # Don't hit the player itself
	
	var result = space_state.intersect_ray(query)
	return not result.is_empty()

func _on_area_entered(area):
	"""Triggered when another area enters this one"""
	var area_owner = area.get_parent()
	if area_owner.has_method("collect_heart") or area_owner.is_in_group("player"):
		start_following(area_owner)

func _on_body_entered(body):
	"""Triggered when a body enters this area"""
	if body.has_method("collect_heart") or body.is_in_group("player"):
		start_following(body)

func start_following(target_player):
	"""Begin following the player"""
	if is_collected or is_following:
		return
		
	player = target_player
	is_following = true
	waiting_for_ground = false
	ground_wait_timer = 0.0
	player_was_on_ground = false
	
	# Set initial random offset for natural movement
	follow_offset = Vector2(randf_range(-20, 20), randf_range(-15, 15))
	
	play_random_sound(touch_sounds)
	# Play pickup sound effect here if you have one
	# AudioManager.play_sound("pickup")

func collect():
	"""Handle the collection of the crystal"""
	if is_collected:
		return
		
	is_collected = true
	
	# Disable collision
	collision_shape.disabled = true
	
	# Play collection animation
	animated_sprite.play("collected")
	Global.carrots += 1
	
	# Connect to animation finished signal to clean up
	if not animated_sprite.animation_finished.is_connected(_on_collection_animation_finished):
		animated_sprite.animation_finished.connect(_on_collection_animation_finished)
	
	# Notify player if it has a collection method
	if player and player.has_method("collect_heart"):
		player.collect_heart()
	
	play_random_sound(collect_sounds)
	# Play collection sound
	# AudioManager.play_sound("collect")

func _on_collection_animation_finished():
	"""Called when the collection animation finishes"""
	# Increase global carrots count
	queue_free()

# Utility functions for external scripts

func reset_crystal():
	"""Reset the crystal to its original state"""
	is_collected = false
	is_following = false
	player = null
	global_position = original_position
	scale = Vector2.ONE
	modulate.a = 1.0
	rotation = 0.0
	collision_shape.disabled = false
	animated_sprite.play("idle")
	
	# Restart idle animation
	start_idle_animation()

func set_player_target(new_player):
	"""Manually set the player to follow"""
	if not is_collected:
		start_following(new_player)

# Optional: Add visual feedback when player is nearby
func _on_player_nearby(is_nearby: bool):
	"""Visual feedback when player approaches"""
	if is_collected or is_following:
		return
		
	if is_nearby:
		animated_sprite.modulate = Color(1.2, 1.2, 1.2)
	else:
		animated_sprite.modulate = Color.WHITE


func play_random_sound(sounds: Array[AudioStream]):
	if sounds.size() == 0:
		return
	var random_index = randi_range(0, sounds.size() - 1)
	audio_player.stream = sounds[random_index]
	audio_player.play()
