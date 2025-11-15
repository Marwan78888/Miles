extends Node

var config = ConfigFile.new()
const SETTINGS_FILE_PATH = "user://settings.ini"

func _ready() -> void:
	
	# Load existing config or create new one
	if !FileAccess.file_exists(SETTINGS_FILE_PATH):
		_create_default_config()
	else:
		var error = config.load(SETTINGS_FILE_PATH)
		
		# Fix missing keybindings
		_fix_missing_keybindings()
	
	# Apply keybindings immediately on startup
	_apply_keybindings()

func _fix_missing_keybindings():
	var required_bindings = {
		"jump": "Space",
		"dash": "X",
		"ui_right": "D",
		"ui_left": "A"
	}
	
	var fixed_any = false
	for action in required_bindings:
		if !config.has_section_key("keybinding", action):
			config.set_value("keybinding", action, required_bindings[action])
			fixed_any = true
	

func _create_default_config():
	# Make sure all 4 keybindings are set
	config.set_value("keybinding", "jump", "Space")
	config.set_value("keybinding", "dash", "X",)
	config.set_value("keybinding", "ui_right", "right")
	config.set_value("keybinding", "ui_left", "left")
	
	config.set_value("video", "screen_shake", true)
	config.set_value("audio", "master_volume", 1.0)
	config.set_value("audio", "sfx_volume", 1.0)
	
	var save_error = config.save(SETTINGS_FILE_PATH)
	
	# Reload the config to make sure it's in memory
	config.load(SETTINGS_FILE_PATH)

func _apply_keybindings():
	if !config.has_section("keybinding"):
		return
	
	var keys = config.get_section_keys("keybinding")
	
	for action in keys:
		var event_str = config.get_value("keybinding", action)
		
		var input_event = _string_to_input_event(event_str)
		
		if input_event:
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, input_event)

	


func save_video_setting(key: String, value):
	config.set_value("video", key, value)
	config.save(SETTINGS_FILE_PATH)

func load_video_settings():
	var video_settings = {}
	for key in config.get_section_keys("video"):
		video_settings[key] = config.get_value("video", key)
	return video_settings
		
func save_audio_setting(key: String, value):
	config.set_value("audio", key, value)
	config.save(SETTINGS_FILE_PATH)

func load_audio_settings():
	var audio_settings = {}
	for key in config.get_section_keys("audio"):
		audio_settings[key] = config.get_value("audio", key)
	return audio_settings

func save_keybinding(action: StringName, event: InputEvent):
	
	var event_str = _input_event_to_string(event)
	
	# First, reload config to make sure we have latest data
	config.load(SETTINGS_FILE_PATH)
	
	config.set_value("keybinding", action, event_str)
	var save_result = config.save(SETTINGS_FILE_PATH)
	
	# Immediately apply the change
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	
	# Verify it was saved by reloading
	config.load(SETTINGS_FILE_PATH)
	var verify = config.get_value("keybinding", action)
func _input_event_to_string(event: InputEvent) -> String:
	if event is InputEventKey:
		var keycode_string = OS.get_keycode_string(event.physical_keycode)
		return keycode_string
	elif event is InputEventMouseButton:
		var mouse_string = "mouse_" + str(event.button_index)
		return mouse_string
	return ""

func _string_to_input_event(event_str: String) -> InputEvent:
	var input_event
	
	if event_str.begins_with("mouse_"):
		input_event = InputEventMouseButton.new()
		var button_str = event_str.trim_prefix("mouse_")
		input_event.button_index = int(button_str)
		input_event.pressed = true
	else:
		input_event = InputEventKey.new()
		var keycode = OS.find_keycode_from_string(event_str)
		input_event.physical_keycode = keycode
		input_event.pressed = true
	
	return input_event

func get_current_keybinding(action: String) -> String:
	var events = InputMap.action_get_events(action)
	if events.size() > 0:
		return events[0].as_text().trim_suffix(" (Physical)")
	return ""

func reset_keybindings():
	InputMap.load_from_project_settings()
	
	var actions = ["jump", "dash", "ui_right", "ui_left"]
	for action in actions:
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			var event_str = _input_event_to_string(events[0])
			config.set_value("keybinding", action, event_str)
	
	var save_result = config.save(SETTINGS_FILE_PATH)
