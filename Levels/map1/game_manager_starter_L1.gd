extends Node
class_name boss1_area
# ============================================================
# LEVEL MANAGER - ORGANIZED & CLEAN
# ============================================================
var phase2_triggered: bool = false
var phase3_triggered: bool = false
var phase4_triggered: bool = false
# ============================================================
# EXPORTS
# ============================================================
@export_group("Boss Encounter Sounds")
@export var boss_encounter_sounds: Array[AudioStream] = []  # Add 4 sounds here in inspector
@export var encounter_volume_db: float = 2.0  # How loud the sound is
@export var encounter_pitch_min: float = 0.95  # Minimum pitch variation
@export var encounter_pitch_max: float = 1.05  # Maximum pitch variation
@export var sound_bus: String = "SFX"  # Which audio bus to use

# Create audio player in _ready()
@export var starter_boss: AudioStream  # Assign ONE sound in inspector
var audio_boss_encounter: AudioStreamPlayer2D

@export_group("Parallax Settings")
@export var parallax_factor: float = 0.3
@export var parallax_factor2: float = 0.5

@export_group("Boss Settings")
@export var boss_scene: PackedScene
@export var boss_spawn_position: Vector2 = Vector2(2378.753, 136.018)
var boss2_start = true

# ============================================================
# STATE TRACKING
# ============================================================
# Text/Credits state
var text_appears: bool = false
var text_appeared: bool = false

# Dialogue states
var robin_dialogue_finished: bool = false
var boss_dialogue_started: bool = false
var boss_spawned: bool = false

# Boss reference
var boss_instance: Node2D = null

# ============================================================
# READY
# ============================================================
func _ready() -> void:
	audio_boss_encounter = AudioStreamPlayer2D.new()
	audio_boss_encounter.name = "AudioBossEncounter"
	audio_boss_encounter.bus = sound_bus
	audio_boss_encounter.volume_db = encounter_volume_db
	add_child(audio_boss_encounter)
	# Initial setup
	Global._can_move_flag = false
	$"../Player/Player".hide()
	%Boss2.position = Vector2(6993.0,-1830.0)
	
	print("[Level Manager] Ready - Level initialized")

# ============================================================
# PROCESS
# ============================================================
func _process(_delta: float) -> void:
	# Parallax effect for credits
	if text_appeared:
		var player_x = $"../Player/Player".position.x
		%Game_by.position.x = player_x * parallax_factor
		%Marwan.position.x = player_x * parallax_factor2
		%Deyaa.position.x = player_x * parallax_factor2
		%Mostafa.position.x = player_x * parallax_factor2

# ============================================================
# INPUT
# ============================================================
func _input(event: InputEvent) -> void:
	# Debug all Accept presses
	if event.is_action_pressed("ui_accept"):
		print("[INPUT DEBUG] Accept pressed!")
		print("  - boss_dialogue_started: ", boss_dialogue_started)
		print("  - boss_spawned: ", boss_spawned)
		print("  - Can spawn? ", boss_dialogue_started and not boss_spawned)
	
	# Boss spawn on first Accept press during dialogue
	if event.is_action_pressed("ui_accept") and boss_dialogue_started and not boss_spawned:
		print("[INPUT] SPAWNING BOSS NOW!")
		spawn_boss()

# ============================================================
# INTRO SEQUENCE - Animation Events
# ============================================================
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"new_animation":
			if Global.level1_camera_animation:
				%Camera_animation.play("Camera Start")
				print("[Intro] Starting camera animation")
		
		"Text_game":
			if text_appears:
				text_appeared = true
				print("[Credits] Text animation finished")

func _on_camera_animation_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Camera Start":
		$"../Player/Player_2".play("start")
		print("[Intro] Player intro animation starting")

func _on_player_2_animation_finished() -> void:
	var animation = $"../Player/Player_2".animation
	
	match animation:
		"start":
			$"../Player/Player_2".play("stand")
		
		"stand":
			# Intro finished - enable player
			Global._can_move_flag = true
			$"../Player/Player_2".hide()
			$"../Player/Player/Heart_System/Control".show()
			%HeartShow.play("new_animation")
			$"../Player/Player".show()
			%buttons_anim.play("start")
			print("[Intro] Player control enabled")

# ============================================================
# CREDITS TEXT TRIGGER
# ============================================================
func _on_game_by_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not text_appears:
		text_appears = true
		
		# Play credits animation
		%Camera_animation.play("Text_game")
		
		# Show credits
		%Game_by.show()
		%Marwan.show()
		%Deyaa.show()
		%Mostafa.show()
		
		print("[Credits] Credits sequence started")

# ============================================================
# ROBIN DIALOGUE (First NPC)
# ============================================================
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not robin_dialogue_finished:
		start_robin_dialogue()

func start_robin_dialogue() -> void:
	print("[Robin] Starting dialogue")
	
	# Flip Robin to face player
	$Robin.flip_h = true
	
	# Disable player movement
	Global._can_move_flag = false
	
	# Smooth zoom in with tween
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(%CelesteCamera, "zoom", Vector2(2, 2), 0.5)
	tween.tween_property(%CelesteCamera, "offset", Vector2(35.9, 28.16), 0.5)
	
	# Wait for zoom, then show dialogue
	await tween.finished
	DialogueManager.show_dialogue_balloon(
		load("res://main/story/Dialouges/Dialouge1.dialogue"),
		"start"
	)
	
	# Wait for dialogue to end
	await DialogueManager.dialogue_ended
	finish_robin_dialogue()

func finish_robin_dialogue() -> void:
	print("[Robin] Dialogue finished")
	robin_dialogue_finished = true
	
	# Smooth zoom out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(%CelesteCamera, "zoom", Vector2(1, 1), 0.5)
	tween.tween_property(%CelesteCamera, "offset", Vector2.ZERO, 0.5)
	
	# Re-enable movement after zoom
	await tween.finished
	Global._can_move_flag = true

# ============================================================
# BOSS ENCOUNTER
# ============================================================
func _on_boss_1_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not boss_dialogue_started:
		Global.boss1_delete = false
		Global.boss_heart_system = true
		start_boss_dialogue()

func start_boss_dialogue() -> void:
	print("[Boss] Starting boss dialogue")
	print("[Boss] boss_dialogue_started was: ", boss_dialogue_started)
	boss_dialogue_started = true
	print("[Boss] boss_dialogue_started now: ", boss_dialogue_started)
	
	# Disable movement
	Global._can_move_flag = false
	Global._boss_can_move = false
	
	print("[Boss] Press 'Accept' now to spawn boss during dialogue!")
	
	# Zoom in to boss area
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(%CelesteCamera, "zoom", Vector2(2, 2), 0.5)
	tween.tween_property(%CelesteCamera, "offset", Vector2(10, 28.16), 0.5)
	
	await tween.finished
	
	# Show dialogue
	print("[Boss] Showing dialogue balloon...")
	DialogueManager.show_dialogue_balloon(
		load("res://main/story/Dialouges/Boss1.dialogue"),
		"start"
	)
	
	print("[Boss] Dialogue is now active - you can press Accept to spawn boss")
	
	# Wait for dialogue to end
	await DialogueManager.dialogue_ended
	print("[Boss] Dialogue ended signal received")
	finish_boss_dialogue()

func spawn_boss() -> void:
	print("[Boss] spawn_boss() called!")
	print("[Boss] boss_spawned: ", boss_spawned)
	print("[Boss] boss_scene: ", boss_scene)
	
	if boss_spawned:
		print("[Boss] ERROR: Boss already spawned!")
		return
	
	if not boss_scene:
		push_error("[Boss] ERROR: Boss scene not assigned in Inspector!")
		return
	
	print("[Boss] Spawning boss at: ", boss_spawn_position)
	boss_spawned = true
	
	# Create boss instance
	boss_instance = boss_scene.instantiate()
	print("[Boss] Boss instance created: ", boss_instance)
	
	boss_instance.scale.x = -1  # Flip to face left
	print("[Boss] Boss flipped to face left")
	
	# Add to scene
	var scene_root = get_tree().current_scene
	print("[Boss] Adding boss to scene root: ", scene_root.name)
	scene_root.add_child(boss_instance)
	
	# Wait one frame
	await get_tree().process_frame
	
	# Set position
	boss_instance.global_position = boss_spawn_position
	
	print("[Boss] ✅ Boss spawned successfully!")
	print("[Boss]    - Global position: ", boss_instance.global_position)
	print("[Boss]    - Local position: ", boss_instance.position)
	print("[Boss]    - Scale: ", boss_instance.scale)
	print("[Boss] Waiting for dialogue to finish...")

func finish_boss_dialogue() -> void:
	print("[Boss] Dialogue finished - Starting boss fight!")
	
	# Fix boss scale (flip back to normal)
	if boss_instance:
		boss_instance.scale.x = 1
	
	# Enable movement and boss
	Global._can_move_flag = true
	Global._boss_can_move = true
	
	# Zoom out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(%CelesteCamera, "zoom", Vector2(1, 1), 0.5)
	tween.tween_property(%CelesteCamera, "offset", Vector2.ZERO, 0.5)
	
	await tween.finished
	print("[Boss] Boss fight started!")
	

# ============================================================
# UTILITY FUNCTIONS
# ============================================================
func reset_camera() -> void:
	"""Reset camera to default state"""
	%CelesteCamera.zoom = Vector2(1, 1)
	%CelesteCamera.offset = Vector2.ZERO

func enable_player_movement() -> void:
	"""Enable player movement"""
	Global._can_move_flag = true

func disable_player_movement() -> void:
	"""Disable player movement"""
	Global._can_move_flag = false


func _on_game_over_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		Global.boss1_delete = true
		boss_dialogue_started = false
		Global.boss_heart_system = false
		boss_spawned = false


func _on_boss_1_end_body_entered(body: Node2D) -> void:
	Global.boss1_delete = true
	Global.boss_heart_system = false


func _on_boss_2_area_body_entered(body: Node2D) -> void:
	var camera = get_tree().get_first_node_in_group("room_camera")
	var audio = AudioStreamPlayer2D.new()
	if body.is_in_group("player") && boss2_start == true:
		%Door_clossed.play("Door_close")
		audio.stream = starter_boss; audio.bus = "SFX"; add_child(audio); audio.play()
		
		# 🔊 PLAY RANDOM BOSS ENCOUNTER SOUND
		play_random_encounter_sound()
		
		camera.screen_shake(10.0, 0.3)  # intensity, duration
		Global._can_move_flag = false
		Global.boss_heart_system = true
		Global.boss2_move = false
		await get_tree().create_timer(0.5).timeout
		
		# Get the camera and trigger shake
		%Boss_animations.play("Boss_Enter")

		if camera:
			camera.screen_shake(15.0, 1.8)  # intensity, duration


func _on_boss_animations_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Boss_Enter":
		%Boss2.position = %Marker2D.position
		await get_tree().create_timer(1.7).timeout
		Global.boss2_move = true
		Global._can_move_flag = true
		boss2_start = false
	if anim_name == "phase2_start":
		$"../Objects/Killeres/Shotter7".position = %Marker2D5.position

func play_random_encounter_sound() -> void:
	"""Play a random sound from the boss encounter sounds array"""
	if boss_encounter_sounds.is_empty():
		print("⚠️ No boss encounter sounds assigned!")
		return
	
	if not audio_boss_encounter or not is_instance_valid(audio_boss_encounter):
		print("⚠️ Audio player not valid!")
		return
	
	# Pick a random sound from the array
	var random_sound = boss_encounter_sounds.pick_random()
	
	if random_sound:
		audio_boss_encounter.stream = random_sound
		
		# Apply random pitch variation for variety
		audio_boss_encounter.pitch_scale = randf_range(encounter_pitch_min, encounter_pitch_max)
		
		# Play the sound
		audio_boss_encounter.play()
		print("🔊 Playing random boss encounter sound")
	else:
		print("⚠️ Selected sound is null!")

func _physics_process(delta: float) -> void:
	var camera = get_tree().get_first_node_in_group("room_camera")
	
	# Only trigger ONCE when health drops below 55
	if Global.boss2_health <= 55 and not phase2_triggered:
		phase2_triggered = true  # Set flag so this never runs again
		
		Global.boss2_move = false
		camera.screen_shake(15.0, 0.8)
		%Boss_animations.play("phase2_start")
		$"../Objects/Killeres/Shotter7".can_shoot = true
		await %Boss_animations.animation_finished
		Global.boss2_move = true
		
	if Global.boss2_health <= 25 and not phase3_triggered:
		phase3_triggered = true  # Set flag so this never runs again
		
		Global.boss2_move = false
		camera.screen_shake(15.0, 0.6)
		%Boss_animations.play("phase3_start")
		await %Boss_animations.animation_finished
		Global.boss2_move = true
		
	if Global.boss2_health == 0 and not phase4_triggered:
		phase3_triggered = true  # Set flag so this never runs again
		
		Global.boss2_move = false
		Global._can_move_flag = false
		camera.screen_shake(15.0, 0.6)
		%Boss_animations.play("Last_pahse")
		await get_tree().create_timer(0.5).timeout
		%Boss2.queue_free()
		await get_tree().create_timer(0.4).timeout
		Global._can_move_flag = true
