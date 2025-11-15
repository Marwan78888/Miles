# bash.gd
extends Node2D

# Bash Settings
@export_group("Bash Mechanics")
@export var bash_enabled: bool = true
@export var bash_range: float = 150.0
@export var bash_force: float = 400.0
@export var target_knockback_force: float = 300.0
@export var time_slow_scale: float = 0.15
@export var aim_time_duration: float = 2.0
@export var bash_cooldown: float = 0.3

@export_group("Targeting")
@export var auto_target_closest: bool = true
@export var target_layers: int = 2  # Which collision layers can be bashed
@export var show_trajectory: bool = true
@export var trajectory_points: int = 20
@export var trajectory_spacing: float = 10.0

@export_group("Visual Settings")
@export var aim_line_color: Color = Color(1, 1, 1, 0.8)
@export var target_highlight_color: Color = Color(1, 0.8, 0, 1)
@export var aim_circle_segments: int = 32

@export_group("Audio")
@export var bash_activate_sounds: Array[AudioStream] = []
@export var bash_launch_sounds: Array[AudioStream] = []
@export var bash_volume: float = 0.8

# State
var is_aiming: bool = false
var can_bash: bool = true
var bash_cooldown_timer: float = 0.0
var aim_timer: float = 0.0
var current_target: Node2D = null
var aim_direction: Vector2 = Vector2.ZERO
var bashable_objects: Array[Node2D] = []

# References
var player: CharacterBody2D = null
var camera: Camera2D = null
var audio_player: AudioStreamPlayer2D

# Visual elements
var trajectory_line: Line2D
var aim_indicator: Line2D
var range_circle: Node2D

func _ready():
	# Find player
	player = get_parent() as CharacterBody2D
	if not player:
		push_error("Bash system must be child of player!")
		return
	
	# Setup audio
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	
	# Setup visual elements
	setup_visuals()
	
	# Find camera
	camera = get_viewport().get_camera_2d()
	
	# Hide visuals initially
	hide_visuals()

func setup_visuals():
	# Trajectory line
	trajectory_line = Line2D.new()
	trajectory_line.width = 2.0
	trajectory_line.default_color = aim_line_color
	trajectory_line.z_index = 100
	add_child(trajectory_line)
	
	# Aim indicator (arrow from player to cursor)
	aim_indicator = Line2D.new()
	aim_indicator.width = 3.0
	aim_indicator.default_color = Color(1, 1, 1, 0.9)
	aim_indicator.z_index = 100
	add_child(aim_indicator)
	
	# Range circle
	range_circle = Node2D.new()
	range_circle.z_index = 99
	add_child(range_circle)

func _physics_process(delta):
	if not bash_enabled or not player:
		return
	
	# Handle cooldown
	if bash_cooldown_timer > 0:
		bash_cooldown_timer -= delta
		if bash_cooldown_timer <= 0:
			can_bash = true
	
	# Check for bash input
	if Input.is_action_just_pressed("bash") and can_bash and not player.is_on_floor():
		start_bash_aim()
	
	# Handle aiming state
	if is_aiming:
		handle_bash_aiming(delta)
		
		# Release bash
		if Input.is_action_just_released("bash"):
			execute_bash()
		
		# Cancel bash
		if Input.is_action_just_pressed("ui_cancel"):
			cancel_bash()

func start_bash_aim():
	if player.is_dead:
		return
	
	# Find bashable targets in range
	find_bashable_targets()
	
	if bashable_objects.is_empty():
		print("No bashable targets in range!")
		return
	
	is_aiming = true
	aim_timer = aim_time_duration
	
	# Slow down time
	Engine.time_scale = time_slow_scale
	
	# Auto-target closest if enabled
	if auto_target_closest:
		current_target = get_closest_target()
	
	# Freeze player
	if player.has_method("apply_external_force"):
		player.velocity = Vector2.ZERO
	
	# Play sound
	play_random_sound(bash_activate_sounds)
	
	# Show visuals
	show_visuals()
	
	print("Bash aim started! Targets found: ", bashable_objects.size())

func handle_bash_aiming(delta):
	# Update timer (use unscaled delta for real time)
	aim_timer -= delta / Engine.time_scale
	
	if aim_timer <= 0:
		cancel_bash()
		return
	
	# Get mouse position in world space
	var mouse_pos = get_global_mouse_position()
	
	# Calculate aim direction from current target (or player if no target)
	var aim_origin = player.global_position
	if current_target:
		aim_origin = current_target.global_position
	
	aim_direction = (mouse_pos - aim_origin).normalized()
	
	# Update target if manual targeting
	if not auto_target_closest:
		update_target_from_mouse()
	
	# Update visuals
	update_visuals()
	
	# Draw everything
	queue_redraw()

func execute_bash():
	if not current_target or not is_aiming:
		cancel_bash()
		return
	
	# Calculate launch direction (opposite of aim direction from target)
	var launch_direction = -aim_direction
	
	# Apply force to player
	if player.has_method("apply_external_force"):
		player.velocity = launch_direction * bash_force
	
	# Apply knockback to target
	if current_target.has_method("apply_bash_knockback"):
		current_target.apply_bash_knockback(aim_direction * target_knockback_force)
	elif current_target is RigidBody2D:
		current_target.apply_central_impulse(aim_direction * target_knockback_force)
	
	# Play sound
	play_random_sound(bash_launch_sounds)
	
	# Cleanup
	end_bash()
	
	# Start cooldown
	bash_cooldown_timer = bash_cooldown
	can_bash = false
	
	print("Bash executed! Direction: ", launch_direction)

func cancel_bash():
	print("Bash cancelled!")
	end_bash()

func end_bash():
	is_aiming = false
	current_target = null
	bashable_objects.clear()
	aim_timer = 0.0
	
	# Restore time
	Engine.time_scale = 1.0
	
	# Hide visuals
	hide_visuals()
	
	queue_redraw()

func find_bashable_targets():
	bashable_objects.clear()
	
	# Get all nodes in the bashable group
	var all_bashable = get_tree().get_nodes_in_group("bashable")
	
	for node in all_bashable:
		if node == player:
			continue
		
		# Check if in range
		var distance = player.global_position.distance_to(node.global_position)
		if distance <= bash_range:
			bashable_objects.append(node)
	
	# Also check for Area2D children of bashable objects
	var space_state = player.get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	var shape = CircleShape2D.new()
	shape.radius = bash_range
	query.shape = shape
	query.transform = Transform2D(0, player.global_position)
	query.collision_mask = target_layers
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var collider = result["collider"]
		# Check if the collider's parent is bashable
		if collider.get_parent() and collider.get_parent().is_in_group("bashable"):
			var parent = collider.get_parent()
			if parent != player and not bashable_objects.has(parent):
				bashable_objects.append(parent)
	
	print("Found ", bashable_objects.size(), " bashable targets")

func get_closest_target() -> Node2D:
	if bashable_objects.is_empty():
		return null
	
	var closest: Node2D = null
	var closest_dist: float = INF
	
	for obj in bashable_objects:
		var dist = player.global_position.distance_to(obj.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = obj
	
	return closest

func update_target_from_mouse():
	var mouse_pos = get_global_mouse_position()
	var closest: Node2D = null
	var closest_dist: float = INF
	
	for obj in bashable_objects:
		var dist = mouse_pos.distance_to(obj.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = obj
	
	if closest:
		current_target = closest

func update_visuals():
	if not current_target:
		return
	
	# Update aim indicator line
	aim_indicator.clear_points()
	aim_indicator.add_point(player.to_local(current_target.global_position))
	var end_point = player.to_local(current_target.global_position + aim_direction * 50)
	aim_indicator.add_point(end_point)
	
	# Update trajectory prediction
	if show_trajectory:
		update_trajectory_line()

func update_trajectory_line():
	trajectory_line.clear_points()
	
	if not current_target:
		return
	
	# Simulate trajectory
	var launch_direction = -aim_direction
	var pos = player.global_position
	var vel = launch_direction * bash_force
	var gravity = player.gravity if "gravity" in player else 800.0
	
	for i in range(trajectory_points):
		trajectory_line.add_point(player.to_local(pos))
		
		# Simple physics prediction
		vel.y += gravity * 0.016 * (i + 1) * 0.1
		pos += vel * 0.016
		
		# Stop if hit ground (approximate)
		if pos.y > player.global_position.y + 200:
			break

func show_visuals():
	trajectory_line.visible = true
	aim_indicator.visible = true
	range_circle.visible = true

func hide_visuals():
	trajectory_line.visible = false
	aim_indicator.visible = false
	range_circle.visible = false

func _draw():
	if not is_aiming:
		return
	
	# Draw range circle
	draw_circle(Vector2.ZERO, bash_range, Color(1, 1, 1, 0.1))
	draw_arc(Vector2.ZERO, bash_range, 0, TAU, aim_circle_segments, Color(1, 1, 1, 0.3), 2.0)
	
	# Draw all bashable targets
	for obj in bashable_objects:
		var local_pos = to_local(obj.global_position)
		var color = target_highlight_color if obj == current_target else Color(1, 1, 1, 0.3)
		draw_circle(local_pos, 8, color)
	
	# Draw aim direction arrow from target
	if current_target:
		var target_local = to_local(current_target.global_position)
		var arrow_end = target_local + aim_direction * 40
		draw_line(target_local, arrow_end, aim_line_color, 3.0)
		
		# Draw arrowhead
		var arrow_size = 10.0
		var perpendicular = aim_direction.orthogonal() * arrow_size
		draw_line(arrow_end, arrow_end - aim_direction * arrow_size + perpendicular * 0.5, aim_line_color, 2.0)
		draw_line(arrow_end, arrow_end - aim_direction * arrow_size - perpendicular * 0.5, aim_line_color, 2.0)

func play_random_sound(sound_array: Array[AudioStream]):
	if sound_array.is_empty() or not audio_player:
		return
	
	var sound = sound_array[randi() % sound_array.size()]
	audio_player.stream = sound
	audio_player.volume_db = linear_to_db(bash_volume)
	audio_player.play()

# Public API
func can_perform_bash() -> bool:
	return bash_enabled and can_bash and bash_cooldown_timer <= 0

func is_currently_aiming() -> bool:
	return is_aiming

func get_cooldown_remaining() -> float:
	return bash_cooldown_timer
