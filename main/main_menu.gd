extends Node2D


func _ready() -> void:
	$Game/Transition/AnimationPlayer.play("new_animation")
