extends Node
# SceneLoader.gd - OPTIMIZED Scene Transition Manager
# Add as Autoload in Project Settings

var _is_transitioning: bool = false
var _fade_overlay: ColorRect

# Position restoration (optimized - no retry needed)
var _position_to_restore: Vector2 = Vector2.ZERO
var _should_restore_position: bool = false

func _ready() -> void:
	_setup_fade_overlay()
	get_tree().node_added.connect(_on_node_added)
	
	if Global.debug_save_system:
		print("[SceneLoader] ✓ Initialized")

func _setup_fade_overlay() -> void:
	_fade_overlay = ColorRect.new()
	_fade_overlay.color = Color.BLACK
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_overlay.visible = false
	
	var canvas = CanvasLayer.new()
	canvas.layer = 1000
	canvas.name = "FadeOverlay"
	add_child(canvas)
	canvas.add_child(_fade_overlay)
	
	_fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

func _on_node_added(node: Node) -> void:
	"""Called whenever a node is added to the tree"""
	# Check if this is the player and we need to restore position
	if _should_restore_position and node.is_in_group("player"):
		_restore_player_position(node)

func _restore_player_position(player: Node) -> void:
	"""Restore player position immediately when player spawns"""
	if Global.debug_save_system:
		print("[SceneLoader] ========================================")
		print("[SceneLoader] RESTORING PLAYER POSITION")
		print("[SceneLoader] Target position: ", _position_to_restore)
		print("[SceneLoader] Player current position: ", player.global_position)
		print("[SceneLoader] ========================================")
	
	# Apply position
	if player.has_method("set_saved_position"):
		player.set_saved_position(_position_to_restore)
	else:
		player.global_position = _position_to_restore
		if player.has_method("reset_velocity"):
			player.reset_velocity()
	
	# Clear flags
	_should_restore_position = false
	SaveManager.set_meta("load_saved_position", false)
	SaveManager.is_loading_save = false
	
	# Fade in
	_fade_in()
	
	if Global.debug_save_system:
		print("[SceneLoader] ✓ Position restored to: ", player.global_position)
		print("[SceneLoader] ✓ Save loaded successfully!")
		print("[SceneLoader] ========================================")

# === PUBLIC API ===

func prepare_position_restore(position: Vector2) -> void:
	"""Prepare to restore player position when they spawn"""
	_position_to_restore = position
	_should_restore_position = true
	
	if Global.debug_save_system:
		print("[SceneLoader] Position restore prepared: ", position)

func change_scene_with_fade(scene_path: String, fade_duration: float = 0.3) -> void:
	"""Change scene with fade transition"""
	if _is_transitioning:
		return
	
	_is_transitioning = true
	
	# Fade out
	await _fade_out(fade_duration)
	
	# Change scene
	var err = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("[SceneLoader] Failed to load scene: ", scene_path)
		_is_transitioning = false
		await _fade_in(fade_duration)
		return
	
	# Wait for scene to load
	await get_tree().process_frame
	
	# Fade in (unless waiting for position restore)
	if not _should_restore_position:
		await _fade_in(fade_duration)
	
	_is_transitioning = false

func _fade_out(duration: float = 0.3) -> void:
	_fade_overlay.visible = true
	_fade_overlay.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(_fade_overlay, "modulate:a", 1.0, duration)
	await tween.finished

func _fade_in(duration: float = 0.3) -> void:
	if not _fade_overlay.visible:
		return
	
	_fade_overlay.modulate.a = 1.0
	
	var tween = create_tween()
	tween.tween_property(_fade_overlay, "modulate:a", 0.0, duration)
	await tween.finished
	
	_fade_overlay.visible = false

func is_transitioning() -> bool:
	return _is_transitioning

func get_current_scene_path() -> String:
	var scene = get_tree().current_scene
	if scene and scene.scene_file_path:
		return scene.scene_file_path
	return ""
