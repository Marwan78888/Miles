extends Node2D

## Simple, Perfect Spring/Trampoline

@export var launch_force: float = 600.0
@export var cooldown_time: float = 0.2

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area: Area2D = $Area2D

var can_bounce: bool = true

func _ready() -> void:
	# Play idle animation
	animated_sprite.play("idle")
	
	# Connect signal
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Check if it's the player and can bounce
	if not body.is_in_group("player"):
		return
	
	if not can_bounce:
		return
	
	if not body is CharacterBody2D:
		return
	
	# Launch player
	body.velocity.y = -launch_force
	
	# Play jump animation
	animated_sprite.play("jump")
	
	# Wait then return to idle
	await get_tree().create_timer(0.25).timeout
	animated_sprite.play("idle")
	
	# Start cooldown
	can_bounce = false
	await get_tree().create_timer(cooldown_time).timeout
	can_bounce = true
