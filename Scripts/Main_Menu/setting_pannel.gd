extends Panel

@onready var screen_shake_checkBox = %CheckBox
@onready var master_volume_slider = %Master_music_slider
@onready var sfx_volume_slider = %SFX_music_slider
var master_bus_index = AudioServer.get_bus_index("Master")
var sfx_bus_index = AudioServer.get_bus_index("Sfx")

func _ready() -> void:
	
	# Load video settings
	var video_settings = ConfigFileHandler.load_video_settings()
	
	# Load and apply screen shake setting
	if video_settings.has("screen_shake"):
		var screen_shake_value = video_settings["screen_shake"]
		%CheckBox.button_pressed = screen_shake_value
		Global.screen_shake = screen_shake_value

	# Load audio settings
	var audio_settings = ConfigFileHandler.load_audio_settings()
	
	# Load and apply master volume setting
	if audio_settings.has("master_volume"):
		var master_volume = audio_settings["master_volume"]
		master_volume_slider.value = master_volume * 100
		AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(master_volume))

	# Load and apply sfx volume setting
	if audio_settings.has("sfx_volume"):
		var sfx_volume = audio_settings["sfx_volume"]
		sfx_volume_slider.value = sfx_volume * 100
		AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(sfx_volume))

	
func _on_back_pressed() -> void:
	self.hide()
	%GameLogo.show()
	%Menu.show()
	%InputSetting.hide()
	
func _on_keyboard_bind_pressed() -> void:
	self.hide()
	%GameLogo.hide()
	%Menu.hide()
	%InputSetting.show()

func _on_check_box_toggled(toggled_on: bool) -> void:
	Global.screen_shake = toggled_on
	ConfigFileHandler.save_video_setting("screen_shake", toggled_on)

func _on_sfx_music_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		var sfx_value = sfx_volume_slider.value / 100
		ConfigFileHandler.save_audio_setting("sfx_volume", sfx_value)

func _on_master_music_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		var master_value = master_volume_slider.value / 100
		ConfigFileHandler.save_audio_setting("master_volume", master_value)

func _on_master_music_slider_value_changed(value: float) -> void:
	var volume_linear = value / 100
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(volume_linear))

func _on_sfx_music_slider_value_changed(value: float) -> void:
	var volume_linear = value / 100
	AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(volume_linear))
