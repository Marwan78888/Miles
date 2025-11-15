#Global

extends Node
 
var s:int = 0
var ss:int = 0
var screen_shake = true
var follow = true

var BlueBurries = 0

var level1_camera_animation = true
var _slot_1_saved_flag = false
var _slot_2_saved_flag = false
var _slot_3_saved_flag = false
var _slot_4_saved_flag = false

# Internal flags (do not access directly from gameplay code)
var boss1_delete = true
var boss_heart_system = false
var start_Dialouge_2 = false
var start_Dialouge_1 = true
var start_level_dialouge  : bool = true
var robin_flip : bool = false
var _can_move_flag: bool = true
var _can_dash_flag: bool = true
var _can_wall_dash_flag: bool = false
var _can_wall_climb_flag: bool = true
var _can_grab_flag: bool = false
var player_is_dead = false 
var _boss_can_move = true
var boss2_move = false
var boss2_health: int = 100

var move_walk: bool = false

# New save system variables
var current_level_name: String = ""
var collectibles_collected: Dictionary = {}
var soul_balls_count: int = 0
var debug_save_system: bool = false
var debug_save_ui_visible: bool = false
# Public query functions (use these from gameplay code)
func can_move() -> bool:
	return _can_move_flag

func can_dash() -> bool:
	return _can_dash_flag

func can_wall_dash() -> bool:
	return _can_wall_dash_flag

func can_wall_climb() -> bool:
	return _can_wall_climb_flag

# Mutator utilities
func enable_all_movement():
	"""Enable all movement and abilities"""
	_can_move_flag = true
	_can_dash_flag = true

func disable_all_movement():
	"""Disable all movement and abilities (for cutscenes, etc.)"""
	_can_move_flag = false

func enable_wall_dash_upgrade():
	"""Give the player the wall dash upgrade"""
	_can_wall_dash_flag = true

func disable_wall_dash_upgrade():
	"""Remove the wall dash upgrade"""
	_can_wall_dash_flag = false

func enable_wall_climb_upgrade():
	"""Give the player the wall climb upgrade"""
	_can_wall_climb_flag = true

func disable_wall_climb_upgrade():
	"""Remove the wall climb upgrade"""
	_can_wall_climb_flag = false

func set_walk_mode(enabled: bool):
	"""Set walk mode (slower movement)"""
	move_walk = enabled

func freeze_player():
	"""Completely freeze the player (for cutscenes, dialogue, etc.)"""
	_can_move_flag = false

func unfreeze_player():
	"""Unfreeze the player"""
	_can_move_flag = true

func register_collectible(collectible_id: String):
	"""Mark a collectible as collected"""
	collectibles_collected[collectible_id] = true

func is_collectible_collected(collectible_id: String) -> bool:
	"""Check if a collectible has been collected"""
	return collectibles_collected.has(collectible_id)

func set_current_level(level_name: String):
	"""Update the current level name"""
	current_level_name = level_name

func reset_game_state():
	"""Reset all game state for a new game"""
	_can_wall_dash_flag = false
	_can_wall_climb_flag = true
	_can_dash_flag = true
	_can_move_flag = true
	start_Dialouge_1 = true
	start_Dialouge_2 = false
	start_level_dialouge = true
	robin_flip = false
	screen_shake = true
	follow = true
	move_walk = false
	collectibles_collected = {}
	soul_balls_count = 0
	current_level_name = ""

func enable_save_debug():
	debug_save_system = true

func disable_save_debug():
	debug_save_system = false

func toggle_save_debug():
	debug_save_system = !debug_save_system

# === SAVE/LOAD SYSTEM ===
# Add these if you want to save upgrades

func get_save_data() -> Dictionary:
	"""Get all Global data for saving"""
	return {
		"can_wall_dash": _can_wall_dash_flag,
		"can_wall_climb": _can_wall_climb_flag,
		"can_dash": _can_dash_flag,
		"can_move": _can_move_flag,
		"start_Dialouge_1": start_Dialouge_1,
		"start_Dialouge_2": start_Dialouge_2,
		"start_level_dialouge": start_level_dialouge,
		"robin_flip": robin_flip,
		"screen_shake": screen_shake,
		"follow": follow,
		"move_walk": move_walk,
		"collectibles_collected": collectibles_collected,
		"soul_balls_count": soul_balls_count,
		"current_level_name": current_level_name,
	}

func load_save_data(data: Dictionary):
	"""Load Global data from save"""
	if data.has("can_wall_dash"):
		_can_wall_dash_flag = data.can_wall_dash
	if data.has("can_wall_climb"):
		_can_wall_climb_flag = data.can_wall_climb
	if data.has("can_dash"):
		_can_dash_flag = data.can_dash
	if data.has("can_move"):
		_can_move_flag = data.can_move
	if data.has("start_Dialouge_1"):
		start_Dialouge_1 = data.start_Dialouge_1
	if data.has("start_Dialouge_2"):
		start_Dialouge_2 = data.start_Dialouge_2
	if data.has("start_level_dialouge"):
		start_level_dialouge = data.start_level_dialouge
	if data.has("robin_flip"):
		robin_flip = data.robin_flip
	if data.has("screen_shake"):
		screen_shake = data.screen_shake
	if data.has("follow"):
		follow = data.follow
	if data.has("move_walk"):
		move_walk = data.move_walk
	if data.has("collectibles_collected"):
		collectibles_collected = data.collectibles_collected
	if data.has("soul_balls_count"):
		soul_balls_count = data.soul_balls_count
	if data.has("current_level_name"):
		current_level_name = data.current_level_name

# === DEBUG INFO ===
func _ready():
	pass
