# Loading.gd - Loading screen that handles save loading and new game creation
extends Control

@export var text: Label

# Wave Animation Settings
@export_group("Wave Settings")
@export var wave_speed: float = 3.0
@export var wave_height: float = 10.0
@export var wave_spacing: float = 0.5

# Scale Pulse Settings
@export_group("Scale Settings")
@export var scale_speed: float = 4.0
@export var scale_intensity: float = 0.2
@export var scale_offset: float = 0.1

# Color Pulse Settings
@export_group("Color Settings")
@export var color_speed: float = 5.0
@export var color_min_intensity: float = 0.7
@export var color_max_intensity: float = 1.0
@export var color_offset: float = 0.4

# Scene Settings
@export_group("Scene Settings")
@export var loading_duration: float = 3.0  # Time before changing scene
@export_file("*.tscn") var new_game_scene: String = "res://Levels/start_level.tscn"  # Scene for new games

var time_passed: float = 0.0
var original_text: String = ""
var char_labels: Array = []
var scene_changed: bool = false

func _ready() -> void:
	# Determine what we're doing based on SaveManager flags
	if SaveManager.is_loading_save:
		# Loading an existing save
		if text:
			text.text = "Loading Save..."
	else:
		# Starting a new game
		if text:
			text.text = "Starting New Game..."
	
	if text:
		original_text = text.text
		setup_wave_animation()
	
	# Add debug logging
	if Global.debug_save_system:
		print("[Loading] Selected slot: " + str(SaveManager.selected_slot) + ", Is loading save: " + str(SaveManager.is_loading_save))

func setup_wave_animation() -> void:
	# Hide original label
	text.visible = false
	
	# Create individual labels for each character
	var char_container = HBoxContainer.new()
	char_container.position = text.position
	char_container.add_theme_constant_override("separation", 0)
	add_child(char_container)
	
	for i in range(original_text.length()):
		var char_label = Label.new()
		char_label.text = original_text[i]
		
		# Get font size safely
		var font_size = text.get_theme_font_size("font_size")
		if font_size > 0:
			char_label.add_theme_font_size_override("font_size", font_size)
		
		# Copy font and color from original
		if text.get_theme_font("font"):
			char_label.add_theme_font_override("font", text.get_theme_font("font"))
		if text.get_theme_color("font_color"):
			char_label.add_theme_color_override("font_color", text.get_theme_color("font_color"))
		
		char_container.add_child(char_label)
		char_labels.append(char_label)

func _process(delta: float) -> void:
	time_passed += delta
	
	# Check if it's time to change scene
	if time_passed >= loading_duration and not scene_changed:
		scene_changed = true
		handle_scene_transition()
	
	# Wave animation
	for i in range(char_labels.size()):
		var char_label = char_labels[i]
		
		# Wave motion
		var wave_offset = sin(time_passed * wave_speed + i * wave_spacing) * wave_height
		char_label.position.y = wave_offset
		
		# Scale pulse
		var scale_factor = 1.0 + sin(time_passed * scale_speed + i * scale_offset) * scale_intensity
		char_label.scale = Vector2(scale_factor, scale_factor)
		
		# Color pulse
		var color_range = color_max_intensity - color_min_intensity
		var color_intensity = color_min_intensity + sin(time_passed * color_speed + i * color_offset) * color_range * 0.5 + color_range * 0.5
		char_label.modulate = Color(color_intensity, color_intensity, color_intensity, 1.0)

func handle_scene_transition() -> void:
	# Add debug logging
	if Global.debug_save_system:
		print("[Loading] Starting scene transition")
	
	# Check if we're loading a save or starting new game
	if SaveManager.is_loading_save:
		# Update text for debug feedback
		if Global.debug_save_system and text:
			text.text = "Verifying save file..."
		
		# Add debug logging
		if Global.debug_save_system:
			print("[Loading] Calling SaveManager.load_slot(" + str(SaveManager.selected_slot) + ")")
		
		# Load the save file
		var success = SaveManager.load_slot(SaveManager.selected_slot)
		if success:
			if Global.debug_save_system:
				print("[Loading] Save loaded successfully")
			# SaveManager.load_slot() handles scene change automatically
		else:
			# Enhanced error handling
			var error_msg = SaveManager.get_last_error()
			if Global.debug_save_system and text:
				text.text = "Error: " + error_msg
			# Always show user-facing fallback message
			print("Loading: Save file corrupted, starting new game")
			start_new_game()
	else:
		# Add debug logging
		if Global.debug_save_system:
			print("[Loading] Starting new game in slot " + str(SaveManager.selected_slot))
		# Start a new game
		start_new_game()

func start_new_game() -> void:
	# Add debug logging
	if Global.debug_save_system:
		print("[Loading] Creating new save file for slot " + str(SaveManager.selected_slot))
		print("[Loading] New game scene: " + new_game_scene)
	
	# Create new save in selected slot
	var success = SaveManager.new_game_slot(SaveManager.selected_slot, new_game_scene)
	if success:
		if Global.debug_save_system:
			print("[Loading] New game started successfully")
		# SaveManager.new_game_slot() handles scene change automatically
	else:
		if Global.debug_save_system:
			print("[Loading] Failed to start new game")
		# Fallback: just go to the start level
		get_tree().change_scene_to_file(new_game_scene)
