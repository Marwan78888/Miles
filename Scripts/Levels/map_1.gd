extends Node2D
# map_1.gd - Complete Working Level Script

func _ready() -> void:

	
	# Set level name
	Global.set_current_level("Map 1")
	

	
	# Handle save logic and camera animation
	if SaveManager.current_save_slot > 0:
		_handle_save_slot()
	else:
		# No save file = play animation
		Global.level1_camera_animation = true
		Global._can_move_flag = false
		
	%AnimationPlayer.play("new_animation")
func _handle_save_slot() -> void:
	var slot = SaveManager.current_save_slot
	
	# Check if loading existing save or new game
	if SaveManager.is_loading_save:
		
		# Save file exists = DON'T play animation
		$Game/Player/Player/Heart_System/Control.show()
		Global.level1_camera_animation = false
		Global._can_move_flag = true
		%Player_2.hide()
		%Player.show()
		%Camera_animation.stop()
		
		# Wait for player and position restore
		await get_tree().create_timer(0.4).timeout
		
		var player = get_tree().get_first_node_in_group("player")
		
		if player:
			# Check if we have a saved position to restore
			if SaveManager.has_meta("load_saved_position") and SaveManager.get_meta("load_saved_position"):
				var saved_position = SaveManager.get_meta("saved_player_position")
				
				if saved_position != Vector2.ZERO:
					player.global_position = saved_position
					
					# Clear the flags after restoring
					SaveManager.set_meta("load_saved_position", false)
					SaveManager.set_meta("saved_player_position", Vector2.ZERO)
					SaveManager.is_loading_save = false
					
				else:
					pass
			else:
				pass
		else:
			pass
	else:
		# New game with save slot = play animation
		Global.level1_camera_animation = true
		Global._can_move_flag = false

# Debug function - Press ESC to check status
