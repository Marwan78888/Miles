extends RigidBody2D
class_name Bullet_shotter

@export var speed: float = 500.0
@export var hit_area: Area2D

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

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var direction: Vector2 = Vector2.RIGHT
var is_destroying: bool = false
var time_alive: float = 0.0
var trail_timer: float = 0.0
var active_trails: Array[Polygon2D] = []  # Track all trail sprites

func _ready() -> void:
	# Play idle animation
	if animated_sprite:
		animated_sprite.play("idle")
	
	# Set up the rigidbody
	gravity_scale = 0.0
	linear_damp = 0.0
	
	# Set initial velocity
	linear_velocity = direction.normalized() * speed
	
	# Connect Area2D signals if assigned
	if hit_area:
		hit_area.body_entered.connect(_on_hit_area_body_entered)
		hit_area.area_entered.connect(_on_hit_area_area_entered)

func _physics_process(delta: float) -> void:
	if not is_destroying:
		time_alive += delta
		trail_timer += delta
		
		# Calculate zigzag offset perpendicular to direction
		var perpendicular = Vector2(-direction.y, direction.x)
		var zigzag_offset = sin(time_alive * zigzag_frequency) * zigzag_amplitude
		
		# Apply movement with zigzag
		var target_velocity = (direction.normalized() + perpendicular * zigzag_offset * 0.01) * speed
		linear_velocity = target_velocity
		
		# Spawn trail sprites continuously
		if trail_timer >= trail_spawn_interval:
			trail_timer = 0.0
			_spawn_trail_sprite()

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

func set_direction(new_direction: Vector2) -> void:
	direction = new_direction.normalized()
	# Rotate bullet to face direction
	rotation = direction.angle()

func _on_hit_area_body_entered(_body: Node) -> void:
	if not is_destroying:
		_destroy()

func _on_hit_area_area_entered(_area: Area2D) -> void:
	if not is_destroying:
		_destroy()

func _destroy() -> void:
	is_destroying = true
	
	# Stop movement
	linear_velocity = Vector2.ZERO
	
	# Disable collision
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		if has_node("DeathTrigger"):
			$DeathTrigger.queue_free()
	
	# Disable hit area
	if hit_area:
		hit_area.set_deferred("monitoring", false)
		hit_area.set_deferred("monitorable", false)
	
	# Clean up all active trails immediately
	_cleanup_trails()
	
	# Play destroy animation
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("destroy"):
		animated_sprite.play("destroy")
		await animated_sprite.animation_finished
	
	# Remove bullet from scene
	queue_free()

func _cleanup_trails() -> void:
	# Force cleanup all trail sprites
	for trail in active_trails:
		if is_instance_valid(trail):
			trail.queue_free()
	active_trails.clear()
