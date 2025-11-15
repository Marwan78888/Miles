extends Control

func _ready():
	$Panel.hide()
	%Setting_pannel.hide()

func _physics_process(delta):
	pass
	if Input.is_action_just_pressed("ui_cancel"):
		showPanel()
#		if $Control.visible == true:
#			$Control.visible = false
#			$Panel.visible = true
#			$Panel/MarginContainer/VBoxContainer/PlayButton.grab_focus()
#		if $q.visible == true:
#			$q.visible = false
#			$Panel.visible = true
#			$Panel/MarginContainer/VBoxContainer/PlayButton.grab_focus()

func showPanel():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$Panel/MarginContainer/VBoxContainer/PlayButton.grab_focus()
	get_tree().paused = true

func hidePanel():
	get_tree().paused = false

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		$Panel.visible = true
		showPanel()
		await get_tree().create_timer(0.5).timeout
	if Input.is_action_just_pressed("ui_cancel") && $Panel.visible == true:
		$Panel.visible = false
		hidePanel()
	# Quick save functionality (F5 key)
	if Input.is_action_just_pressed("quick_save") && SaveManager && SaveManager.current_save_slot >= 0:
		_on_save_button_pressed()

func _on_play_button_pressed():
	$Panel.visible = false
	hidePanel()

func _on_exit_button_pressed():
	$Panel.visible = false
	if not SaveManager or SaveManager.current_save_slot < 0:
		print("No active save slot to save to")
		return
	SaveManager.save_game(SaveManager.current_save_slot)
	print("Manual save initiated from pause menu")
	get_tree().change_scene_to_file("res://main/main_menu.tscn")
	
func _on_options_button_pressed():
	$Panel.hide()
	%Setting_pannel.show()
	


func _on_save_button_pressed():
	if not SaveManager or SaveManager.current_save_slot < 0:
		print("No active save slot to save to")
		return
	SaveManager.save_game(SaveManager.current_save_slot)
	print("Manual save initiated from pause menu")
