extends StaticBody2D
# ============================================================
# SHOOTER SYSTEM WITH INITIAL DELAY & RANDOM SOUND SUPPORT
# ============================================================

# Bullet scene to instantiate
@export var bullet_scene: PackedScene

# Reference to the Marker2D where bullets spawn (assign in inspector)
@export var bullet_spawn_point: Marker2D

# Shooting settings
@export var can_shoot: bool = true
@export var auto_shoot: bool = false
@export var shoot_interval: float = 1.0

# 🔸 Delay before starting to shoot (for auto mode)
@export var start_delay: float = 0.0

# 🔊 Sound settings
@export_group("Sound Settings")
@export var shoot_sounds: Array[AudioStream] = []  # Array of sound effects
@export var sound_volume_db: float = 0.0  # Volume in decibels
@export var sound_pitch_min: float = 0.9  # Minimum pitch variation
@export var sound_pitch_max: float = 1.1  # Maximum pitch variation
@export var sound_bus: String = "SFX"  # Audio bus to use

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Audio player for shoot sounds
var audio_player: AudioStreamPlayer2D

var is_emitting: bool = false
var should_emit_bullet: bool = false
var emit_frame: int = 10

# ============================================================
# SETUP
# ============================================================
func _ready() -> void:
	# Setup audio player
	_setup_audio_player()
	
	if animated_sprite:
		animated_sprite.play("idle")
		animated_sprite.frame_changed.connect(_on_frame_changed)
		animated_sprite.animation_finished.connect(_on_animation_finished)
	
	if auto_shoot:
		_start_auto_shoot()

func _setup_audio_player() -> void:
	"""Create and configure the audio player"""
	audio_player = AudioStreamPlayer2D.new()
	audio_player.bus = sound_bus
	audio_player.volume_db = sound_volume_db
	add_child(audio_player)

# ============================================================
# INPUT HANDLING (Manual shooting)
# ============================================================
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and can_shoot and not is_emitting:
		shoot()

# ============================================================
# SHOOTING CORE
# ============================================================
func shoot() -> void:
	if not can_shoot or is_emitting:
		return
	
	is_emitting = true
	should_emit_bullet = true
	
	# Play random shoot sound
	_play_random_shoot_sound()
	
	if animated_sprite:
		animated_sprite.play("emitt")

func _on_frame_changed() -> void:
	if animated_sprite and animated_sprite.animation == "emitt":
		if animated_sprite.frame == emit_frame and should_emit_bullet:
			_spawn_bullet()
			should_emit_bullet = false

func _spawn_bullet() -> void:
	if not bullet_scene:
		push_error("Bullet scene is not assigned!")
		return
	
	if not bullet_spawn_point:
		push_error("Bullet spawn point Marker2D is not assigned!")
		return
	
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	bullet.global_position = bullet_spawn_point.global_position
	
	var shoot_direction = Vector2.RIGHT.rotated(global_rotation)
	
	if bullet.has_method("set_direction"):
		bullet.set_direction(shoot_direction)

func _on_animation_finished() -> void:
	if animated_sprite and animated_sprite.animation == "emitt":
		is_emitting = false
		animated_sprite.play("idle")

# ============================================================
# SOUND SYSTEM
# ============================================================
func _play_random_shoot_sound() -> void:
	"""Play a random sound from the shoot_sounds array"""
	if shoot_sounds.is_empty():
		return  # No sounds to play
	
	if not audio_player or not is_instance_valid(audio_player):
		push_warning("Audio player is not valid!")
		return
	
	# Pick a random sound from the array
	var random_sound = shoot_sounds.pick_random()
	
	if random_sound:
		audio_player.stream = random_sound
		
		# Apply random pitch variation for variety
		audio_player.pitch_scale = randf_range(sound_pitch_min, sound_pitch_max)
		
		# Play the sound
		audio_player.play()
	else:
		push_warning("Selected sound is null!")

func set_sound_volume(volume_db: float) -> void:
	"""Change the volume of shoot sounds"""
	sound_volume_db = volume_db
	if audio_player:
		audio_player.volume_db = volume_db

func set_sound_pitch_range(min_pitch: float, max_pitch: float) -> void:
	"""Change the pitch variation range"""
	sound_pitch_min = min_pitch
	sound_pitch_max = max_pitch

func add_shoot_sound(sound: AudioStream) -> void:
	"""Add a new sound to the shoot sounds array"""
	if sound and sound not in shoot_sounds:
		shoot_sounds.append(sound)

func remove_shoot_sound(sound: AudioStream) -> void:
	"""Remove a sound from the shoot sounds array"""
	if sound in shoot_sounds:
		shoot_sounds.erase(sound)

func clear_shoot_sounds() -> void:
	"""Clear all shoot sounds"""
	shoot_sounds.clear()

# ============================================================
# AUTO SHOOTING WITH INITIAL DELAY
# ============================================================
func _start_auto_shoot() -> void:
	await get_tree().create_timer(start_delay).timeout  # ⏳ wait before starting
	while auto_shoot:
		shoot()
		await get_tree().create_timer(shoot_interval).timeout

# ============================================================
# MANUAL CONTROL
# ============================================================
func enable_shooting() -> void:
	can_shoot = true

func disable_shooting() -> void:
	can_shoot = false

func set_shoot_interval(interval: float) -> void:
	shoot_interval = interval
