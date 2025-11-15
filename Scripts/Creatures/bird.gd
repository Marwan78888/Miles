extends AnimatedSprite2D

# Configuration
@export var detection_radius: float = 150.0  # How close player needs to be to scare bird
@export var fly_speed: float = 200.0  # Base flying speed
@export var fly_acceleration: float = 150.0  # How fast bird accelerates
@export var idle_animation: String = "idle"  # Name of idle animation
@export var fly_animation: String = "fly"  # Name of fly animation

# Flight behavior
@export var upward_angle: float = -45.0  # Angle in degrees (negative is up, -45 = diagonal up-right)
@export var flutter_intensity: float = 15.0  # How much the bird bobs up/down while flying
@export var flutter_speed: float = 8.0  # How fast the flutter animation is

# Internal state
enum State { IDLE, STARTLED, FLYING, ESCAPED }
var current_state: State = State.IDLE
var player: Node2D = null
var velocity: Vector2 = Vector2.ZERO
var current_speed: float = 0.0
var flutter_time: float = 0.0
var initial_y: float = 0.0

func _ready() -> void:
	# Find the player node (adjust the path to match your scene structure)
	player = get_tree().get_first_node_in_group("player")
	
	if player == null:
		push_warning("Bird: No player found in 'player' group!")
	
	# Start with idle animation
	play(idle_animation)
	initial_y = global_position.y

func _process(delta: float) -> void:
	match current_state:
		State.IDLE:
			_process_idle()
		State.STARTLED:
			_process_startled(delta)
		State.FLYING:
			_process_flying(delta)
		State.ESCAPED:
			pass  # Do nothing, waiting to be freed

func _process_idle() -> void:
	# Check if player is nearby
	if player and _is_player_near():
		_start_flying()

func _process_startled(delta: float) -> void:
	# Brief moment before taking off (optional, for more natural feel)
	# You can add a small hop or preparation animation here
	current_state = State.FLYING
	play(fly_animation)

func _process_flying(delta: float) -> void:
	# Accelerate to full speed
	current_speed = min(current_speed + fly_acceleration * delta, fly_speed)
	
	# Calculate base direction (diagonal up-right)
	var angle_rad = deg_to_rad(upward_angle)
	var base_direction = Vector2(cos(angle_rad), sin(angle_rad)).normalized()
	
	# Add flutter effect for natural movement
	flutter_time += delta * flutter_speed
	var flutter_offset = sin(flutter_time) * flutter_intensity
	
	# Apply movement with flutter
	velocity = base_direction * current_speed
	global_position += velocity * delta
	global_position.y += flutter_offset * delta
	
	# Slight rotation based on flutter for extra realism
	rotation = sin(flutter_time * 0.5) * 0.1
	
	# Check if bird has left the scene
	_check_if_escaped()

func _is_player_near() -> bool:
	if not player:
		return false
	
	var distance = global_position.distance_to(player.global_position)
	return distance < detection_radius

func _start_flying() -> void:
	current_state = State.STARTLED
	initial_y = global_position.y
	
	# Optional: Play a chirp sound here
	# $ChirpSound.play()

func _check_if_escaped() -> void:
	var viewport_rect = get_viewport_rect()
	var pos = global_position
	
	# Check if bird is outside the viewport bounds (with some margin)
	var margin = 100.0
	if pos.x > viewport_rect.size.x + margin or \
	   pos.x < -margin or \
	   pos.y < -margin or \
	   pos.y > viewport_rect.size.y + margin:
		_escape()

func _escape() -> void:
	current_state = State.ESCAPED
	queue_free()  # Remove the bird from the scene

# Optional: Draw detection radius in editor
func _draw() -> void:
	if Engine.is_editor_hint():
		draw_arc(Vector2.ZERO, detection_radius, 0, TAU, 32, Color(1, 1, 0, 0.3), 2.0)

# Optional: Visual debugging
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if not get_tree().get_first_node_in_group("player"):
		warnings.append("No node found in 'player' group. Add your player to the 'player' group.")
	
	if not sprite_frames:
		warnings.append("No SpriteFrames resource assigned.")
	elif sprite_frames:
		if not sprite_frames.has_animation(idle_animation):
			warnings.append("Idle animation '" + idle_animation + "' not found in SpriteFrames.")
		if not sprite_frames.has_animation(fly_animation):
			warnings.append("Fly animation '" + fly_animation + "' not found in SpriteFrames.")
	
	return warnings
