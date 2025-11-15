extends Control
# slot_save.gd - OPTIMIZED Save Slot UI

@export_group("Slot Settings")
@export var slot_number: int = 1
@export_file("*.tscn") var loading_scene: String = "res://Levels/map1/map_1.tscn"

@export_group("UI References")
@export var HourLabel: Label
@export var HourSymbolLabel: Label
@export var NewGamePanel: Control
@export var SaveInfoContainer: Control

var _confirmation_dialog: ConfirmationDialog
var _is_deleting: bool = false
var _is_processing: bool = false

func _ready() -> void:
	$Transition2.layer = -1
	SaveManager.update_save_flags()
	_update_ui()
	_setup_confirmation_dialog()
	_update_village_visibility()
	
	# Connect signals
	if has_node("PanelContainer"):
		$PanelContainer.gui_input.connect(_on_panel_gui_input)
	
	if has_node("DeleteButton"):
		$DeleteButton.pressed.connect(_on_delete_button_pressed)

func _setup_confirmation_dialog() -> void:
	_confirmation_dialog = ConfirmationDialog.new()
	_confirmation_dialog.dialog_text = "Are you sure you want to delete this save?\n\nThis action cannot be undone!"
	_confirmation_dialog.ok_button_text = "Delete"
	_confirmation_dialog.cancel_button_text = "Cancel"
	_confirmation_dialog.confirmed.connect(_on_delete_confirmed)
	add_child(_confirmation_dialog)

func _update_village_visibility() -> void:
	"""Update village preview visibility"""
	var has_save = SaveManager.slot_has_save(slot_number)
	
	if has_node("PanelContainer/Village1/Village1"):
		$PanelContainer/Village1/Village1.visible = has_save
	
	if has_node("PanelContainer/Village1/Village1/Player"):
		$PanelContainer/Village1/Village1/Player.visible = has_save
	
	if has_node("%Village1"):
		%Village1.visible = has_save

func _update_ui() -> void:
	var has_save = SaveManager.slot_has_save(slot_number)
	
	if has_save:
		var info = SaveManager.get_slot_info(slot_number)
		
		if info.has("corrupted") and info.corrupted:
			_show_corrupted_ui()
			return
		
		if info.is_empty():
			_show_corrupted_ui()
			return
		
		_show_save_info(info)
	else:
		_show_new_game_ui()

func _show_save_info(info: Dictionary) -> void:
	var play_time = info.get("play_time", 0.0)
	var hours = int(play_time / 3600)
	var minutes = int((play_time - hours * 3600) / 60)
	
	if HourLabel:
		HourLabel.text = str(hours)
		HourLabel.show()
	
	if HourSymbolLabel:
		HourSymbolLabel.show()
	
	if NewGamePanel:
		NewGamePanel.hide()
	
	if SaveInfoContainer:
		SaveInfoContainer.show()
	
	if has_node("%SoulBallsLabel"):
		%SoulBallsLabel.text = str(info.get("soul_balls", 0))
	
	if has_node("%BlueBurriesLabel"):
		%BlueBurriesLabel.text = str(info.get("blue_burries", 0))
	
	if has_node("%LevelLabel"):
		%LevelLabel.text = info.get("level_name", "Unknown")
	
	if has_node("%SaveTimeLabel"):
		%SaveTimeLabel.text = info.get("save_time", "Unknown")

func _show_new_game_ui() -> void:
	if HourLabel:
		HourLabel.hide()
	
	if HourSymbolLabel:
		HourSymbolLabel.hide()
	
	if NewGamePanel:
		NewGamePanel.show()
	
	if SaveInfoContainer:
		SaveInfoContainer.hide()

func _show_corrupted_ui() -> void:
	if HourLabel:
		HourLabel.text = "!"
		HourLabel.show()
	
	if HourSymbolLabel:
		HourSymbolLabel.hide()
	
	if has_node("%CorruptedLabel"):
		%CorruptedLabel.text = "CORRUPTED"
		%CorruptedLabel.show()
	
	if NewGamePanel:
		NewGamePanel.hide()
	
	if SaveInfoContainer:
		SaveInfoContainer.show()

func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if not _is_processing:
				_on_slot_pressed()

func _on_slot_pressed() -> void:
	"""Handle slot click - start transition animation"""
	_is_processing = true
	$Transition2.layer += 2
	# LAYER FIX: Put transition ABOVE slot during animation
	if has_node("$Transition2"):
		$Transition2.layer = 10  # High layer (above slot)
	
	# Make slot go behind during transition
	if has_node("$PanelContainer"):
		$PanelContainer.z_index = -1
	
	# Show transition elements
	if has_node("%Village1"):
		%Village1.show()
	if has_node("$Hours"):
		$Hours.show()
	if has_node("$HBoxContainer"):
		$HBoxContainer.show()
	
	# Play transition animation
	if has_node("%Transition_anim2"):
		%Transition_anim2.play("new_animation")

func _on_delete_button_pressed() -> void:
	"""Show delete confirmation dialog"""
	if not SaveManager.slot_has_save(slot_number):
		return
	
	_confirmation_dialog.popup_centered()

func _on_delete_confirmed() -> void:
	"""Actually delete the save"""
	_is_deleting = true
	
	# Hide village immediately
	if has_node("PanelContainer/Village1/Village1"):
		$PanelContainer/Village1/Village1.hide()
	if has_node("PanelContainer/Village1/Village1/Player"):
		$PanelContainer/Village1/Village1/Player.hide()
	if has_node("%Village1"):
		%Village1.hide()
	
	var deleted = SaveManager.delete_slot(slot_number)
	
	if deleted:
		_update_ui()
		if Global.debug_save_system:
			pass

	else:
		_show_error_message("Failed to delete save:\n" + SaveManager.get_last_error())
	
	_is_deleting = false

func _on_transition_anim_2_animation_finished(anim_name: StringName) -> void:
	"""Called when transition animation completes"""
	if anim_name != "new_animation" or _is_deleting:
		_is_processing = false
		# LAYER FIX: Reset layers after animation
		if has_node("$Transition2"):
			$Transition2.layer = 0  # Behind slot
		if has_node("$PanelContainer"):
			$PanelContainer.z_index = 0
		return
	
	var has_save = SaveManager.slot_has_save(slot_number)
	
	if has_save:
		# LOAD EXISTING SAVE
		_load_existing_save()
	else:
		# CREATE NEW GAME
		_create_new_game()
	
	_is_processing = false
	
	# LAYER FIX: Reset layers after loading
	if has_node("$Transition2"):
		$Transition2.layer = 0  # Behind slot when idle
	if has_node("$PanelContainer"):
		$PanelContainer.z_index = 0

func _load_existing_save() -> void:
	"""Load an existing save file"""
	var validation = SaveManager.validate_save_file(slot_number)
	
	if not validation.valid:
		_show_corrupted_dialog(validation)
		return
	
	if Global.debug_save_system:
		pass
	# Load the save
	if SaveManager.load_slot(slot_number):
		# Scene transition handled by SaveManager
		if Global.debug_save_system:
			pass
	else:
		_show_error_message("Failed to load save:\n" + SaveManager.get_last_error())

func _create_new_game() -> void:
	"""Start a new game in this slot"""
	if Global.debug_save_system:
		pass
	# Start new game
	if SaveManager.new_game_slot(slot_number, loading_scene):
		# Scene transition handled by SaveManager
		if Global.debug_save_system:
			pass
	else:
		_show_error_message("Failed to create new save:\n" + SaveManager.get_last_error())

func _show_corrupted_dialog(validation: Dictionary) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Corrupted Save File"
	dialog.dialog_text = "Save file is corrupted!\n\nError: " + validation.error
	
	if validation.can_restore:
		dialog.dialog_text += "\n\nA backup is available."
		dialog.add_button("Restore Backup", true, "restore")
		dialog.custom_action.connect(_on_restore_action)
	else:
		dialog.dialog_text += "\n\nNo backup available.\nYou must delete this save."
	
	dialog.confirmed.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered()

func _on_restore_action(action: String) -> void:
	if action == "restore":
		if SaveManager.restore_from_backup(slot_number):
			_update_ui()
			_show_success_message("Backup restored successfully!")
		else:
			_show_error_message("Failed to restore backup.\nYou must delete this save.")

func _show_success_message(message: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Success"
	dialog.dialog_text = message
	dialog.confirmed.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered()

func _show_error_message(message: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Error"
	dialog.dialog_text = message
	dialog.confirmed.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered()

# === PUBLIC API ===

func refresh_ui() -> void:
	SaveManager.update_save_flags()
	_update_ui()
	_update_village_visibility()

func get_save_info_text() -> String:
	if not SaveManager.slot_has_save(slot_number):
		return "Empty Slot"
	
	var info = SaveManager.get_slot_info(slot_number)
	if info.is_empty() or info.has("corrupted"):
		return "Corrupted Save"
	
	var hours = int(info.get("play_time", 0.0) / 3600)
	var minutes = int((info.get("play_time", 0.0) - hours * 3600) / 60)
	
	return "Playtime: %dh %dm\nLevel: %s\nSoul Balls: %d\nBlue Berries: %d" % [
		hours,
		minutes,
		info.get("level_name", "Unknown"),
		info.get("soul_balls", 0),
		info.get("blue_burries", 0)
	]

func set_slot_enabled(enabled: bool) -> void:
	if has_node("PanelContainer"):
		$PanelContainer.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	modulate.a = 1.0 if enabled else 0.5

func is_valid_save() -> bool:
	if not SaveManager.slot_has_save(slot_number):
		return false
	
	var validation = SaveManager.validate_save_file(slot_number)
	return validation.valid
