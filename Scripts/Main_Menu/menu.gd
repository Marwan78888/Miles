extends Control

# Button and arrow references (assign these in the editor)
@export var arrow_node: Sprite2D
@export var button_nodes: Array[Control] = []
var is_playing_backwards: bool = false
# Arrow movement and animation
@export var arrow_move_pixels: int = 2  # Pixels to move left/right in animation
@export var arrow_tween_speed: float = 2.0  # Speed of the continuous tween animation
@export var arrow_distance_from_button: int = 20  # Distance from button (pixels)
var arrow_base_position: Vector2  # Base position for the arrow
var arrow_continuous_tween: Tween

# Menu position tracking
@export var current_arrow_position: int = 0  # Which button (0-3) the arrow is on
var button_positions: Array[Vector2] = []  # Store original button positions

# Button visual feedback
@export var button_move_pixels: int = 2  # How much buttons move when selected
@export var button_normal_color: Color = Color.WHITE
@export var button_selected_color: Color = Color.YELLOW

# Sound arrays
@export var move_sounds: Array[AudioStream] = []
@export var enter_sounds: Array[AudioStream] = []

# Audio players
@onready var move_audio_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var enter_audio_player: AudioStreamPlayer = AudioStreamPlayer.new()

# Internal state
var is_mouse_controlling: bool = false
var buttons_original_positions: Array[Vector2] = []

func _ready():
	self.show()
	%GameLogo.show()
	%Setting_pannel.hide()
	%Setting_pannel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	%InputSetting.hide()
	$"../../../SaveSlots/SaveSlots/Save_Slot".mouse_filter = Control.MOUSE_FILTER_IGNORE
	$"../../../SaveSlots/SaveSlots/Save_Slot2".mouse_filter = Control.MOUSE_FILTER_IGNORE
	$"../../../SaveSlots/SaveSlots/Save_Slot3".mouse_filter = Control.MOUSE_FILTER_IGNORE
	$"../../../SaveSlots/SaveSlots/Save_Slot4".mouse_filter = Control.MOUSE_FILTER_IGNORE



	# Add audio players as children
	add_child(move_audio_player)
	add_child(enter_audio_player)
	
	# Validate setup
	if not arrow_node:
		push_error("Arrow node not assigned!")
		return
	
	if button_nodes.size() != 4:
		push_error("Exactly 4 button nodes required!")
		return
	
	# Store original positions
	arrow_base_position = arrow_node.position
	for button in button_nodes:
		buttons_original_positions.append(button.position)
	
	# Calculate button positions for arrow placement
	_calculate_button_positions()
	
	# Initialize arrow position and start continuous animation
	_update_arrow_position()
	_start_continuous_arrow_animation()
	_update_button_states()
	
	# Menu starts active - no need to wait for mouse input
	is_mouse_controlling = false

func _calculate_button_positions():
	button_positions.clear()
	for button in button_nodes:
		# Position arrow using the customizable distance variable
		var arrow_pos = Vector2(button.position.x - arrow_distance_from_button, button.position.y + button.size.y / 2)
		button_positions.append(arrow_pos)

func _input(event):
	# Prioritize keyboard input - always respond to keys
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP:
				_move_arrow_up()
			KEY_DOWN:
				_move_arrow_down()
			KEY_ENTER:
				_button_pressed()
		return  # Exit early to prevent mouse interference
	
	# Handle mouse movement - always check for mouse hover
	elif event is InputEventMouseMotion:
		_handle_mouse_movement(event.position)
	
	# Handle left mouse click on buttons
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_mouse_click(event.position)

func _move_arrow_up():
	if current_arrow_position > 0:
		current_arrow_position -= 1
		_play_move_sound()
		_update_arrow_position()
		_update_button_states()
		is_mouse_controlling = false  # Keyboard takes priority

func _move_arrow_down():
	if current_arrow_position < 3:
		current_arrow_position += 1
		_play_move_sound()
		_update_arrow_position()
		_update_button_states()
		is_mouse_controlling = false  # Keyboard takes priority

func _handle_mouse_movement(mouse_pos: Vector2):
	# Check which button the mouse is over
	for i in range(button_nodes.size()):
		var button = button_nodes[i]
		var button_rect = Rect2(button.global_position, button.size)
		
		if button_rect.has_point(mouse_pos):
			if current_arrow_position != i:
				current_arrow_position = i
				_play_move_sound()
				_update_arrow_position()
				_update_button_states()
				is_mouse_controlling = true
			return

func _handle_mouse_click(mouse_pos: Vector2):
	# Check which button was clicked
	for i in range(button_nodes.size()):
		var button = button_nodes[i]
		var button_rect = Rect2(button.global_position, button.size)
		
		if button_rect.has_point(mouse_pos):
			# Move arrow to clicked button if not already there
			if current_arrow_position != i:
				current_arrow_position = i
				_play_move_sound()
				_update_arrow_position()
				_update_button_states()
			
			# Execute button press
			_button_pressed()
			is_mouse_controlling = true
			return

func _start_continuous_arrow_animation():
	# Stop any existing tween
	if arrow_continuous_tween:
		arrow_continuous_tween.kill()
	
	# Create new continuous tween with pixel-perfect movement
	arrow_continuous_tween = create_tween()
	arrow_continuous_tween.set_loops() # Infinite loops
	arrow_continuous_tween.set_trans(Tween.TRANS_LINEAR) # No easing for pixel-perfect
	
	# Create discrete pixel steps instead of smooth interpolation
	var steps = arrow_move_pixels * 2 # Total steps for full left-right cycle
	var step_duration = (1.0 / arrow_tween_speed) / steps
	
	# Animate to the right pixel by pixel
	for i in range(arrow_move_pixels + 1):
		arrow_continuous_tween.tween_method(_set_arrow_pixel_position, i, i, step_duration)
	
	# Animate to the left pixel by pixel
	for i in range(arrow_move_pixels - 1, -arrow_move_pixels - 1, -1):
		arrow_continuous_tween.tween_method(_set_arrow_pixel_position, i, i, step_duration)

func _set_arrow_pixel_position(pixel_offset: int):
	# Set exact pixel position - no interpolation
	arrow_node.position = arrow_base_position + Vector2(pixel_offset, 0)

func _update_arrow_position():
	if current_arrow_position < button_positions.size():
		arrow_base_position = button_positions[current_arrow_position]
		# Restart the pixel animation from the new position
		_start_continuous_arrow_animation()

func _update_button_states():
	for i in range(button_nodes.size()):
		var button = button_nodes[i]
		var original_pos = buttons_original_positions[i]
		
		if i == current_arrow_position:
			# Selected button: move and change color
			button.position = original_pos + Vector2(button_move_pixels, 0)
			button.modulate = button_selected_color
		else:
			# Normal button: original position and color
			button.position = original_pos
			button.modulate = button_normal_color

func _button_pressed():
	_play_enter_sound()
	# Add your button action logic here based on current_arrow_position
	match current_arrow_position:
		0:
			%Menu.hide()
			%SaveSlots.show()
			$"../../../SaveSlots/SaveSlots/Save_Slot".mouse_filter = Control.MOUSE_FILTER_STOP
			$"../../../SaveSlots/SaveSlots/Save_Slot2".mouse_filter = Control.MOUSE_FILTER_STOP
			$"../../../SaveSlots/SaveSlots/Save_Slot3".mouse_filter = Control.MOUSE_FILTER_STOP
			$"../../../SaveSlots/SaveSlots/Save_Slot4".mouse_filter = Control.MOUSE_FILTER_STOP
			

		1:
			self.hide()
			%GameLogo.hide()
			%Setting_pannel.show()
			%InputSetting.hide()
		2:
			%AnimationPlayer.play("credits")
		3:
			%AnimationPlayer.play("quite")
	
	# Emit signal or call function for button action
	_execute_button_action(current_arrow_position)

func _execute_button_action(button_index: int):
	# Override this function or connect signals for specific button actions
	pass

func _play_move_sound():
	if move_sounds.size() > 0 and move_audio_player:
		var sound_index = randi() % move_sounds.size()
		move_audio_player.stream = move_sounds[sound_index]
		move_audio_player.play()

func _play_enter_sound():
	if enter_sounds.size() > 0 and enter_audio_player:
		var sound_index = randi() % enter_sounds.size()
		enter_audio_player.stream = enter_sounds[sound_index]
		enter_audio_player.play()

# Getter functions for exported variables
func get_current_arrow_position() -> int:
	return current_arrow_position

func get_arrow_move_pixels() -> int:
	return arrow_move_pixels

func get_button_move_pixels() -> int:
	return button_move_pixels

func get_button_selected_color() -> Color:
	return button_selected_color

func get_button_normal_color() -> Color:
	return button_normal_color

func get_move_sounds() -> Array[AudioStream]:
	return move_sounds

func get_enter_sounds() -> Array[AudioStream]:
	return enter_sounds

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "new_animation" && is_playing_backwards == true:
		get_tree().change_scene_to_file("res://Levels/Loading&Transitions/loading.tscn")
