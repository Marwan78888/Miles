extends Node

@export var player: CharacterBody2D
@export var Camera_ZoneNPC: PhantomCamera2D
@export var Camera_Zone0: PhantomCamera2D
@export var Camera_Zone1: PhantomCamera2D
@export var Camera_Zone2: PhantomCamera2D
@export var Camera_ZoneNPC2: PhantomCamera2D
@export var transition_duration: float = 1.0

var current_camera_zone: int = 4  # Start with Camera_ZoneNPC (zone 4)
var is_transitioning: bool = false

func _ready() -> void:
	# Set Camera_ZoneNPC as the initial active camera
	switch_to_zone(4)

func switch_to_zone(zone: int):
	"""Manually switch to a specific camera zone"""
	if is_transitioning:
		return
	
	current_camera_zone = zone
	update_camera()

func update_current_zone(body, zone_a: int, zone_b: int):
	if body == player and not is_transitioning:
		match current_camera_zone:
			zone_a:
				current_camera_zone = zone_b
			zone_b:
				current_camera_zone = zone_a
		update_camera()

func update_camera():
	if is_transitioning:
		return
	
	is_transitioning = true
	
	# Reset all camera priorities
	var cameras = [Camera_Zone0, Camera_Zone1, Camera_Zone2, Camera_ZoneNPC, Camera_ZoneNPC2]
	for camera in cameras:
		if camera != null:
			camera.priority = 0
	
	# Set the new active camera
	match current_camera_zone:
		0:
			if Camera_Zone0 != null:
				Camera_Zone0.priority = 1
		1:
			if Camera_Zone1 != null:
				Camera_Zone1.priority = 1
		2:
			if Camera_Zone2 != null:
				Camera_Zone2.priority = 1
		3:
			if Camera_ZoneNPC2 != null:
				Camera_ZoneNPC2.priority = 1
		4:
			if Camera_ZoneNPC != null:
				Camera_ZoneNPC.priority = 1
	
	# Disable player processing during transition
	if player != null:
		player.set_physics_process(false)
		player.set_process(false)
		player.set_process_input(false)
	
	# Wait for transition duration
	await get_tree().create_timer(transition_duration).timeout
	
	# Re-enable player processing
	if player != null:
		player.set_physics_process(true)
		player.set_process(true)
		player.set_process_input(true)
	
	is_transitioning = false

func _on_zone_01_body_entered(body: Node2D) -> void:
	update_current_zone(body, 0, 1)

func _on_zone_12_body_entered(body: Node2D) -> void:
	update_current_zone(body, 1, 2)

func _on_zone_npc_body_entered(body: Node2D) -> void:
	update_current_zone(body, 2, 3)
	player.set_physics_process(true)
	player.set_process(true)
	player.set_process_input(true)
	if body.is_in_group("player"):
		Global._can_move_flag = false
		Global.start_Dialouge_2 = true

func _on_zone_start_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	# This zone is only for the NPC dialogue at the start
	if Global.start_Dialouge_1 == true:
		update_current_zone(body, 0, 4)
		Global._can_move_flag = false
		Global.robin_flip = true
	else:
		# Normal zone transition
		update_current_zone(body, 0, 1)
