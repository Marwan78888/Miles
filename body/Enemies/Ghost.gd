extends CharacterBody2D

# Exported variables for easy tweaking in the editor
@export_group("Movement")
@export var move_speed: float = 100.0
@export var start_direction: int = 1  # 1 for right, -1 for left
@export var patrol_duration: float = 2.0  # Time before flipping direction

@export_group("Float Effect")
@export var float_amplitude: float = 10.0
@export var float_frequency: float = 2.0

@export_group("Smooth Movement")
@export var acceleration: float = 300.0
@export var deceleration: float = 400.0


# Internal variables
var current_float_time: float = 0.0
var base_y: float = 0.0
var current_velocity_x: float = 0.0
var direction: int = 1
var initial_scale: Vector2

# Timer
var patrol_timer: Timer

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Store the base Y coordinate
	base_y = global_position.y
	direction = start_direction
	
	# Store the initial scale
	if animated_sprite:
		initial_scale = animated_sprite.scale
		animated_sprite.scale.x = abs(initial_scale.x) * -direction
	
	# Setup patrol timer
	setup_timer()
	
	# Play the idle animation
	if animated_sprite and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")

func setup_timer() -> void:
	patrol_timer = Timer.new()
	add_child(patrol_timer)
	patrol_timer.wait_time = patrol_duration
	patrol_timer.one_shot = false
	patrol_timer.timeout.connect(_on_patrol_timer_timeout)
	patrol_timer.start()

func _physics_process(delta: float) -> void:
	# Calculate target velocity for horizontal movement
	var target_velocity_x = direction * move_speed
	
	# Smooth acceleration/deceleration
	if abs(current_velocity_x) < abs(target_velocity_x):
		current_velocity_x = move_toward(current_velocity_x, target_velocity_x, acceleration * delta)
	else:
		current_velocity_x = move_toward(current_velocity_x, target_velocity_x, deceleration * delta)
	
	# Set the velocity
	velocity.x = current_velocity_x
	velocity.y = 0
	
	# Apply the floaty sine wave effect on Y axis
	current_float_time += delta
	var float_offset = sin(current_float_time * float_frequency) * float_amplitude
	
	# Move horizontally with move_and_slide
	move_and_slide()
	
	# Manually set Y position for float effect (after move_and_slide)
	global_position.y = base_y + float_offset

func _on_patrol_timer_timeout() -> void:
	flip_direction()

func flip_direction() -> void:
	# Reverse direction
	direction *= -1
	
	# Reset velocity to prevent sliding
	current_velocity_x = 0
	velocity.x = 0
	
	# Flip the sprite scale
	if animated_sprite:
		animated_sprite.scale.x = abs(initial_scale.x) * -direction
	
	# Restart the timer
	if patrol_timer:
		patrol_timer.start()
