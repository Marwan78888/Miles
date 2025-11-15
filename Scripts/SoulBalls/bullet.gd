extends Node2D

# === MOVEMENT ===
var velocity: Vector2 = Vector2.ZERO
var speed: float = 400.0

# === DAMAGE ===
var damage: float = 10.0

# === LIFETIME ===
var lifetime: float = 3.0
var fade_time: float = 0.3

# === VISUAL ===
@onready var sprite: Sprite2D = null
@onready var glow: Sprite2D = null
@onready var area: Area2D = null

var time_alive: float = 0.0

func _ready():
	# Get references
	if has_node("Sprite2D"):
		sprite = $Sprite2D
	if has_node("Glow"):
		glow = $Glow
	if has_node("Area2D"):
		area = $Area2D
		area.body_entered.connect(_on_hit_body)
		area.area_entered.connect(_on_hit_area)

func _process(delta):
	time_alive += delta
	
	# Move bullet
	position += velocity * delta
	
	# Fade out near end of lifetime
	if time_alive > lifetime - fade_time:
		var fade_progress = (time_alive - (lifetime - fade_time)) / fade_time
		modulate.a = 1.0 - fade_progress
	
	# Destroy after lifetime
	if time_alive >= lifetime:
		queue_free()
	
	# Rotate glow for effect
	if glow:
		glow.rotation += delta * 2.0

func set_velocity(vel: Vector2):
	"""Set bullet velocity directly"""
	velocity = vel

func set_direction(dir: Vector2):
	"""Set bullet direction (uses default speed)"""
	velocity = dir.normalized() * speed

func set_speed(spd: float):
	"""Change bullet speed"""
	speed = spd
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed

func _on_hit_body(body: Node):
	"""Handle collision with a body"""
	if body.is_in_group("Enemy"):
		_deal_damage_to(body)
		_create_hit_effect()
		queue_free()

func _on_hit_area(area_node: Area2D):
	"""Handle collision with an area"""
	if area_node.is_in_group("Enemy"):
		# Try to damage the area's parent
		var target = area_node.get_parent()
		if target:
			_deal_damage_to(target)
		_create_hit_effect()
		queue_free()

func _deal_damage_to(target: Node):
	"""Apply damage to target"""
	# Try method first
	if target.has_method("take_damage"):
		target.take_damage(damage)
	# Try direct health property
	elif "health" in target:
		target.health -= damage
	# Try hit method
	elif target.has_method("hit"):
		target.hit(damage)

func _create_hit_effect():
	"""Create a visual effect on hit"""
	var effect = Node2D.new()
	get_parent().add_child(effect)
	effect.global_position = global_position
	
	# Create particles or flash
	var flash = Sprite2D.new()
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	
	for x in range(32):
		for y in range(32):
			var center = Vector2(16, 16)
			var dist = Vector2(x, y).distance_to(center)
			if dist <= 12.0:
				var alpha = (1.0 - (dist / 12.0)) * 0.8
				img.set_pixel(x, y, Color(0.4, 0.8, 1.0, alpha))
	
	flash.texture = ImageTexture.create_from_image(img)
	effect.add_child(flash)
	
	# Animate the effect
	var tween = effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(2.0, 2.0), 0.3)
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	effect.queue_free()
