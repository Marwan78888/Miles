extends Node2D

var opened = false

func _ready() -> void:
	$StaticBody2D/CollisionShape2D.disabled = false


func _on_open_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") && opened == false:
		%AnimatedSprite2D.play("open")
		opened = true

func _on_close_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") && opened == true:
		%AnimatedSprite2D.play("close")
		opened = false
