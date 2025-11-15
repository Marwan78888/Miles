extends Area2D
# autosave.gd - Complete Working Auto-save Checkpoint

@export var save_cooldown: float = 2.0
@export var show_debug_info: bool = true

var _last_save_time: float = 0.0
var _can_save: bool = true
var _player_inside: bool = false

func _ready() -> void:
	%AutoSaveIcon.hide()
	# CRITICAL: Connect signals in _ready()
	body_exited.connect(_on_body_exited)
	
	# Ensure monitoring is enabled
	monitoring = true
	monitorable = true
	
	print("\n========================================")
	print("[AutoSave] Checkpoint initialized")
	print("[AutoSave] Position: ", global_position)
	print("[AutoSave] Monitoring: ", monitoring)
	print("[AutoSave] Node name: ", name)
	print("[AutoSave] Has CollisionShape: ", get_child_count() > 0)
	if get_child_count() > 0:
		for child in get_children():
			print("[AutoSave] Child: ", child.name, " Type: ", child.get_class())
	print("[AutoSave] Debug mode: ", Global.debug_save_system)
	print("========================================\n")

func _on_body_entered(body: Node2D) -> void:
	print("\n========================================")
	print("[AutoSave] BODY ENTERED CHECKPOINT!")
	print("[AutoSave] Body name: ", body.name)
	print("[AutoSave] Body type: ", body.get_class())
	print("[AutoSave] Body groups: ", body.get_groups())
	print("[AutoSave] Is in 'player' group: ", body.is_in_group("player"))
	print("========================================\n")
	
	# Check if it's the player
	if not body.is_in_group("player"):
		
		print("[AutoSave] Not a player, ignoring")
		return
	
	print("[AutoSave] ✓✓✓ PLAYER DETECTED! ✓✓✓")
	_player_inside = true
	$"../../Game/Transition/ColorRect".show()
	
	# Check if we can save
	if not _can_save:
		print("[AutoSave] Save in cooldown period")
		return
	
	# Check cooldown time
	var current_time = Time.get_ticks_msec() / 1000.0
	var time_since_last_save = current_time - _last_save_time
	
	if time_since_last_save < save_cooldown:
		print("[AutoSave] Cooldown active: %.1f seconds remaining" % (save_cooldown - time_since_last_save))
		return
	
	# Check if we have an active save slot
	print("[AutoSave] Checking save slot...")
	print("[AutoSave] Current slot: ", SaveManager.current_save_slot)
	
	if SaveManager.current_save_slot == 0:
		print("[AutoSave] ✗ No active save slot!")
		return
	
	print("[AutoSave] ✓ All checks passed, initiating save...")
	
	# Perform the auto-save
	_perform_autosave(body)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		print("[AutoSave] Player exited checkpoint")

func _perform_autosave(player: Node2D) -> void:
	_can_save = false
	_last_save_time = Time.get_ticks_msec() / 1000.0
	
	var slot = SaveManager.current_save_slot
	var player_pos = player.global_position
	var scene_path = get_tree().current_scene.scene_file_path
	
	print("\n========================================")
	print("[AutoSave] EXECUTING AUTO-SAVE")
	print("[AutoSave] Slot: %d" % slot)
	print("[AutoSave] Scene: %s" % scene_path)
	print("[AutoSave] Player position: %v" % player_pos)
	print("[AutoSave] Calling SaveManager.auto_save()...")
	print("========================================\n")
	
	# Use SaveManager's auto_save function
	var success = SaveManager.auto_save()
	
	print("\n========================================")
	if success:
		print("[AutoSave] ✓✓✓ AUTO-SAVE SUCCESSFUL! ✓✓✓")
		print("[AutoSave] Game saved to slot %d" % slot)
		print("[AutoSave] Position: %v" % player_pos)
		_show_save_indicator()
	else:
		var error = SaveManager.get_last_error()
		print("[AutoSave] ✗✗✗ AUTO-SAVE FAILED! ✗✗✗")
		print("[AutoSave] Error: %s" % error)
		push_error("[AutoSave] Save failed: " + error)
	print("========================================\n")
	
	# Re-enable saving after cooldown
	await get_tree().create_timer(save_cooldown).timeout
	_can_save = true
	print("[AutoSave] Cooldown finished, ready to save again")

func _show_save_indicator() -> void:
	if not has_node("%SaveIcon"):
		print("[AutoSave] Warning: SaveIcon node not found")
		return
	
	var save_icon = %AutoSaveIcon
	
	# Start invisible
	save_icon.modulate.a = 0.0
	save_icon.show()
	
	# Create tween for fade in
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Fade in (0.5 seconds)
	tween.tween_property(save_icon, "modulate:a", 1.0, 0.5)
	
	# Wait visible (2 seconds)
	tween.tween_interval(2.0)
	
	# Fade out (0.5 seconds)
	tween.tween_property(save_icon, "modulate:a", 0.0, 0.5)
	
	# Hide after fade out completes
	tween.tween_callback(save_icon.hide)
	
	# Wait for entire animation to complete
	await tween.finished
	
	print("[AutoSave] Save indicator animation completed")

# Debug function - can be called manually
func test_save() -> void:
	print("[AutoSave] === MANUAL TEST SAVE ===")
	var player = get_tree().get_first_node_in_group("player")
	if player:
		_last_save_time = 0.0
		_can_save = true
		_perform_autosave(player)
	else:
		print("[AutoSave] No player found for test save")

# Function to check status
func get_status() -> String:
	var status = ""
	status += "Can save: %s\n" % _can_save
	status += "Player inside: %s\n" % _player_inside
	status += "Current slot: %d\n" % SaveManager.current_save_slot
	status += "Monitoring: %s\n" % monitoring
	return status
