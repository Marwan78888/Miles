class_name RoomCamera
extends Camera2D

@export var target: Node2D
@export var room_size: Vector2 = Vector2(320, 180)
@export var follow_smoothing: float = 10.0

# Screen Shake Variables
@export var shake_intensity: float = 1.49
@export var shake_duration: float = 0.54
@export var shake_fade: float = 0.15

var current_room: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var current_spawn_point: Vector2
var room_spawns: Dictionary = {}

# Screen Shake Variables
var shake_timer: float = 0.0
var shake_offset: Vector2 = Vector2.ZERO
var base_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	# إضافة الكاميرا للـ group عشان اللاعب يلاقيها
	add_to_group("room_camera")
	
	if target:
		cache_spawn_points()
		current_room = get_room_from_position(target.global_position)
		target_position = calculate_room_center(current_room)
		base_position = target_position
		global_position = target_position  # الكاميرا تبدأ متوسّطة
		
		# تحديث spawn point للغرفة الحالية في البداية
		current_spawn_point = room_spawns.get(current_room, calculate_room_center(current_room))


func _physics_process(delta: float) -> void:
	if target:
		update_target_position()
		base_position = base_position.lerp(target_position, follow_smoothing * delta)
		
		# تطبيق screen shake
		if shake_timer > 0:
			shake_timer -= delta
			# إنشاء اهتزاز عشوائي
			shake_offset = Vector2(
				randf_range(-shake_intensity, shake_intensity),
				randf_range(-shake_intensity, shake_intensity)
			)
			# تقليل شدة الاهتزاز مع الوقت
			var shake_strength = shake_timer / shake_duration
			shake_offset *= shake_strength * shake_fade
		else:
			shake_offset = Vector2.ZERO
		
		# تطبيق الموضع النهائي مع الاهتزاز
		global_position = base_position + shake_offset
		
func calculate_room_center(room: Vector2) -> Vector2:
	return room * room_size + (room_size / 2)

func get_room_from_position(pos: Vector2) -> Vector2:
	return (pos / room_size).floor()

func update_target_position() -> void:
	var target_room = get_room_from_position(target.global_position)
	if target_room != current_room:
		current_room = target_room
		target_position = calculate_room_center(current_room)
		
		# تحديث spawn point للغرفة الجديدة
		current_spawn_point = room_spawns.get(current_room, calculate_room_center(current_room))

func cache_spawn_points() -> void:
	room_spawns.clear()
	for marker in get_tree().get_nodes_in_group("room_spawn_points"):
		var room = get_room_from_position(marker.global_position)
		room_spawns[room] = marker.global_position
	

# دالة مساعدة لتحديث spawn point يدوياً إذا لزم الأمر
func set_spawn_point_for_current_room(new_spawn: Vector2) -> void:
	current_spawn_point = new_spawn
	room_spawns[current_room] = new_spawn

# Screen Shake Functions
func screen_shake(intensity: float = -1, duration: float = -1):
	"""
	تشغيل screen shake
	intensity: شدة الاهتزاز (اختياري، يستخدم القيمة الافتراضية إذا لم يتم تمريرها)
	duration: مدة الاهتزاز (اختياري، يستخدم القيمة الافتراضية إذا لم يتم تمريرها)
	"""
	if intensity > 0:
		shake_intensity = intensity
	if duration > 0:
		shake_duration = duration
	
	shake_timer = shake_duration

func stop_shake():
	"""إيقاف الاهتزاز فوراً"""
	shake_timer = 0.0
	shake_offset = Vector2.ZERO
func get_current_spawn_point() -> Vector2:
	"""Get spawn point based on camera's current room - LEVEL RESTRICTED"""
	# First, try to get the room camera
	var room_camera = get_tree().get_first_node_in_group("room_camera")
	if room_camera and room_camera.has_method("get_spawn_point_for_room"):
		# Get the current room from camera
		var current_room = room_camera.current_room
		# Get spawn point for this room
		var room_spawn = room_camera.get_spawn_point_for_room(current_room)
		if room_spawn != Vector2.ZERO:
			return room_spawn
	
	# Fallback: Find closest spawn point BUT ONLY IN CURRENT LEVEL
	return get_closest_spawn_point_in_current_level()

func get_closest_spawn_point_in_current_level() -> Vector2:
	"""Find closest spawn point ONLY within the current level/scene"""
	var current_level_name = get_tree().current_scene.scene_file_path
	var spawn_points = get_tree().get_nodes_in_group("room_spawn_points")
	var valid_spawn_points = []
	
	# Filter spawn points to only include ones in the current level
	for spawn in spawn_points:
		# Check if spawn point belongs to current scene
		if is_spawn_point_in_current_level(spawn):
			valid_spawn_points.append(spawn)
	
	# If no spawn points found in current level, use camera fallback
	if valid_spawn_points.size() == 0:
		return get_camera_fallback_spawn()
	
	# Find the closest spawn point from valid ones
	var closest_spawn = valid_spawn_points[0]
	var closest_distance = global_position.distance_to(closest_spawn.global_position)
	
	for spawn in valid_spawn_points:
		var distance = global_position.distance_to(spawn.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_spawn = spawn
	
	return closest_spawn.global_position

func is_spawn_point_in_current_level(spawn_point: Node) -> bool:
	"""Check if spawn point belongs to current level"""
	# Method 1: Check if spawn point is a child of current scene
	var current_scene = get_tree().current_scene
	return spawn_point.get_tree() == current_scene.get_tree() and spawn_point.is_inside_tree()

func get_camera_fallback_spawn() -> Vector2:
	"""Fallback using camera's room center if no spawn points found"""
	var room_camera = get_tree().get_first_node_in_group("room_camera")
	if room_camera:
		# Use camera's current room center as spawn point
		return room_camera.calculate_room_center(room_camera.current_room)
	
	# Ultimate fallback - use player's current position
	return global_position

# Alternative method using level bounds checking
func get_spawn_point_within_level_bounds() -> Vector2:
	"""Get spawn point using level boundary detection"""
	var room_camera = get_tree().get_first_node_in_group("room_camera")
	if not room_camera:
		return get_closest_spawn_point_in_current_level()
	
	# Get current level boundaries based on camera
	var level_bounds = get_current_level_bounds(room_camera)
	var spawn_points = get_tree().get_nodes_in_group("room_spawn_points")
	var valid_spawns = []
	
	# Filter spawns within level bounds
	for spawn in spawn_points:
		if level_bounds.has_point(spawn.global_position):
			valid_spawns.append(spawn)
	
	if valid_spawns.size() == 0:
		return room_camera.current_spawn_point
	
	# Find closest within bounds
	var closest_spawn = valid_spawns[0]
	var closest_distance = global_position.distance_to(closest_spawn.global_position)
	
	for spawn in valid_spawns:
		var distance = global_position.distance_to(spawn.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_spawn = spawn
	
	return closest_spawn.global_position

func get_current_level_bounds(camera: Node2D) -> Rect2:
	"""Calculate current level boundaries based on camera system"""
	# This assumes your levels are contained within certain room ranges
	# Adjust based on your level design
	var current_room = camera.current_room
	var room_size = camera.room_size
	
	# Define level bounds - you may need to adjust this logic
	# This example assumes each level spans multiple rooms
	var level_start_room = Vector2(floor(current_room.x / 10) * 10, floor(current_room.y / 10) * 10)
	var level_end_room = level_start_room + Vector2(10, 10)  # Adjust based on your level size
	
	var bounds_start = level_start_room * room_size
	var bounds_size = (level_end_room - level_start_room) * room_size
	
	return Rect2(bounds_start, bounds_size)

# Enhanced method that remembers the last valid spawn point
var last_valid_spawn_point: Vector2 = Vector2.ZERO
var current_level_scene_path: String = ""

func get_secure_spawn_point() -> Vector2:
	"""Secure method that remembers last valid spawn and prevents cross-level spawning"""
	var current_scene_path = get_tree().current_scene.scene_file_path
	
	# If we changed levels, reset the last valid spawn
	if current_scene_path != current_level_scene_path:
		current_level_scene_path = current_scene_path
		last_valid_spawn_point = Vector2.ZERO
	
	# Try to get room-based spawn
	var room_camera = get_tree().get_first_node_in_group("room_camera")
	if room_camera:
		var room_spawn = room_camera.current_spawn_point
		if room_spawn != Vector2.ZERO and is_position_in_current_level(room_spawn):
			last_valid_spawn_point = room_spawn
			return room_spawn
	
	# Try closest spawn in current level
	var level_spawn = get_closest_spawn_point_in_current_level()
	if level_spawn != Vector2.ZERO:
		last_valid_spawn_point = level_spawn
		return level_spawn
	
	# Use last known good spawn point
	if last_valid_spawn_point != Vector2.ZERO:
		return last_valid_spawn_point
	
	# Ultimate fallback - scene center or camera position
	return get_emergency_spawn_point()

func is_position_in_current_level(pos: Vector2) -> bool:
	"""Check if position is within current level boundaries"""
	var room_camera = get_tree().get_first_node_in_group("room_camera")
	if room_camera:
		var level_bounds = get_current_level_bounds(room_camera)
		return level_bounds.has_point(pos)
	return true

func get_emergency_spawn_point() -> Vector2:
	"""Emergency spawn point when all else fails"""
	var room_camera = get_tree().get_first_node_in_group("room_camera")
	if room_camera:
		return room_camera.global_position
	
	# Use scene center
	var viewport_size = get_viewport().get_visible_rect().size
	return viewport_size / 2

# Call this when player enters a new room to update valid spawn
func update_last_valid_spawn():
	"""Update last valid spawn point when entering new rooms"""
	var room_camera = get_tree().get_first_node_in_group("room_camera")
	if room_camera and room_camera.current_spawn_point != Vector2.ZERO:
		last_valid_spawn_point = room_camera.current_spawn_point
