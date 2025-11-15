extends StaticBody2D
class_name PainterLaser

# ============================================================================
# AAA QUALITY LASER SYSTEM - FIXED
# ============================================================================

# Node references
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var idle_sprite: AnimatedSprite2D = $Idle
@onready var beam_sprite: AnimatedSprite2D = $Beam
@onready var active_sprite: AnimatedSprite2D = $Active
@onready var paint_back_sprite: AnimatedSprite2D = $PaintBack

# Laser states
enum LaserState {
	IDLE,
	PAINT_BACK_WINDUP,
	FIRING,
	COOLDOWN
}

# Configuration
@export_group("Laser Properties")
@export var laser_length: float = 1000.0
@export var laser_width: float = 20.0
@export var damage_per_second: float = 50.0
@export var cooldown_duration: float = 2.0

@export_group("Activation")
@export var auto_activate: bool = true
@export var activation_delay: float = 1.0
@export var fire_duration: float = 3.0

@export_group("Visual Effects")
@export var beam_shake_intensity: float = 2.0
@export var beam_glow_speed: float = 3.0

@export_group("Audio")
@export var windup_sound: AudioStream
@export var beam_sound: AudioStream
@export var cooldown_sound: AudioStream

# State management
var current_state: LaserState = LaserState.IDLE
var state_timer: float = 0.0
var can_fire: bool = true

# Raycast for laser detection
var laser_raycast: RayCast2D
var hit_bodies: Array[Node2D] = []

# Visual effects
var beam_base_position: Vector2
var glow_time: float = 0.0

# Audio
var audio_player: AudioStreamPlayer2D


# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	_setup_raycast()
	_setup_collision()
	_setup_audio()
	_setup_sprites()
	_set_state(LaserState.IDLE)
	
	if auto_activate:
		await get_tree().create_timer(activation_delay).timeout
		start_laser()


func _setup_raycast() -> void:
	laser_raycast = RayCast2D.new()
	add_child(laser_raycast)
	laser_raycast.enabled = true
	laser_raycast.target_position = Vector2(laser_length, 0)
	laser_raycast.collide_with_areas = true
	laser_raycast.collide_with_bodies = true


func _setup_collision() -> void:
	if collision_shape and collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = Vector2(laser_length, laser_width)
		collision_shape.position = Vector2(laser_length / 2, 0)
		collision_shape.disabled = true


func _setup_audio() -> void:
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)


func _setup_sprites() -> void:
	# Idle sprite
	if idle_sprite:
		idle_sprite.visible = false
	
	# Beam sprite
	if beam_sprite:
		beam_base_position = beam_sprite.position
		beam_sprite.visible = false
	
	# Active sprite
	if active_sprite:
		active_sprite.visible = false
	
	# PaintBack sprite
	if paint_back_sprite:
		paint_back_sprite.visible = false
		paint_back_sprite.animation_finished.connect(_on_paintback_finished)


# ============================================================================
# MAIN LOOP
# ============================================================================

func _process(delta: float) -> void:
	state_timer += delta
	
	match current_state:
		LaserState.IDLE:
			pass
			
		LaserState.PAINT_BACK_WINDUP:
			# Wait for animation to finish (handled by signal)
			pass
			
		LaserState.FIRING:
			_update_beam_effects(delta)
			_detect_and_damage(delta)
			
			if state_timer >= fire_duration:
				_set_state(LaserState.COOLDOWN)
			
		LaserState.COOLDOWN:
			if state_timer >= cooldown_duration:
				_set_state(LaserState.IDLE)
				if auto_activate:
					start_laser()


# ============================================================================
# STATE MANAGEMENT
# ============================================================================

func _set_state(new_state: LaserState) -> void:
	# Exit old state
	if current_state == LaserState.FIRING:
		collision_shape.disabled = true
		hit_bodies.clear()
	
	# Enter new state
	current_state = new_state
	state_timer = 0.0
	
	match new_state:
		LaserState.IDLE:
			_show_idle()
			can_fire = true
			
		LaserState.PAINT_BACK_WINDUP:
			_show_windup()
			
		LaserState.FIRING:
			_show_firing()
			
		LaserState.COOLDOWN:
			_show_cooldown()


func _show_idle() -> void:
	# IDLE: Show only idle animation
	idle_sprite.visible = true
	idle_sprite.play("idle")
	
	beam_sprite.visible = false
	active_sprite.visible = false
	paint_back_sprite.visible = false


func _show_windup() -> void:
	# CHARGING: idle hide, paintback show, beam hide, active show
	idle_sprite.visible = false
	
	paint_back_sprite.visible = true
	paint_back_sprite.play("paintBack")
	
	beam_sprite.visible = false
	
	active_sprite.visible = true
	active_sprite.play("active")
	
	if windup_sound:
		audio_player.stream = windup_sound
		audio_player.play()


func _show_firing() -> void:
	# ATTACK: idle show, paintback show, beam show, active hide
	%Idle.show()

	%PaintBack.visible = true
	%CollisionShape2D.disabled = false

	# Keep paintback on last frame (don't replay)
	
	beam_sprite.visible = true
	beam_sprite.play("Beam")
	
	active_sprite.visible = false
	
	collision_shape.disabled = false
	glow_time = 0.0
	
	if beam_sound:
		audio_player.stream = beam_sound
		audio_player.play()


func _show_cooldown() -> void:
	# COOLDOWN: Show only idle animation
	%Idle.show()
	%CollisionShape2D.disabled = true
	%Idle.play("idle")
	beam_sprite.visible = false
	active_sprite.visible = false
	%PaintBack.visible = false
	
	if cooldown_sound:
		audio_player.stream = cooldown_sound
		audio_player.play()


# ============================================================================
# ANIMATION CALLBACKS
# ============================================================================

func _on_paintback_finished() -> void:
	if current_state == LaserState.PAINT_BACK_WINDUP:
		_set_state(LaserState.FIRING)


# ============================================================================
# LASER EFFECTS
# ============================================================================

func _update_beam_effects(delta: float) -> void:
	if not beam_sprite:
		return
	
	glow_time += delta * beam_glow_speed
	
	# Screen shake
	var shake = Vector2(
		randf_range(-beam_shake_intensity, beam_shake_intensity),
		randf_range(-beam_shake_intensity, beam_shake_intensity)
	)
	beam_sprite.position = beam_base_position + shake
	
	# Pulsing glow
	var pulse = (sin(glow_time) + 1.0) / 2.0
	var glow = 1.0 + pulse * 0.3
	beam_sprite.modulate = Color(glow, glow, glow, 1.0)


func _detect_and_damage(delta: float) -> void:
	laser_raycast.force_raycast_update()
	hit_bodies.clear()
	
	var collider = laser_raycast.get_collider()
	if collider and collider is Node2D:
		hit_bodies.append(collider)
		
		var damage = damage_per_second * delta
		
		if collider.has_method("take_damage"):
			collider.take_damage(damage)
		elif collider.has_method("damage"):
			collider.damage(damage)
		elif collider.has_method("apply_damage"):
			collider.apply_damage(damage)
		
		_on_laser_hit(collider, damage)


# ============================================================================
# PUBLIC API
# ============================================================================

func start_laser() -> void:
	"""Trigger laser attack"""
	if can_fire and current_state == LaserState.IDLE:
		can_fire = false
		_set_state(LaserState.PAINT_BACK_WINDUP)


func stop_laser() -> void:
	"""Force stop laser"""
	if current_state == LaserState.FIRING:
		_set_state(LaserState.COOLDOWN)


func set_direction(angle_rad: float) -> void:
	"""Set laser direction in radians"""
	rotation = angle_rad


func set_direction_vector(direction: Vector2) -> void:
	"""Set laser direction from vector"""
	rotation = direction.angle()


func is_firing() -> bool:
	return current_state == LaserState.FIRING


func get_state_name() -> String:
	match current_state:
		LaserState.IDLE: return "IDLE"
		LaserState.PAINT_BACK_WINDUP: return "WINDUP"
		LaserState.FIRING: return "FIRING"
		LaserState.COOLDOWN: return "COOLDOWN"
		_: return "UNKNOWN"


# ============================================================================
# CALLBACKS
# ============================================================================

func _on_laser_hit(body: Node2D, damage: float) -> void:
	"""Override for custom hit behavior"""
	pass
