extends Node
# SaveManager.gd - Professional Save System (OPTIMIZED)
# Add as Autoload: Project Settings → Autoload → SaveManager

# === SAVE SLOT MANAGEMENT ===
var current_save_slot: int = 0  # 0 = no active slot, 1-4 = slot number
var selected_slot: int = 0  # Selected from menu
var is_loading_save: bool = false  # Flag for loading screen

# === PATHS AND ENCRYPTION ===
const SAVE_DIR = "user://saves/"
const SLOT_FILES = {
	1: "user://saves/slot_1.sav",
	2: "user://saves/slot_2.sav",
	3: "user://saves/slot_3.sav",
	4: "user://saves/slot_4.sav"
}

# Encryption (split for obfuscation)
const _ENC_P1 = "Miles2_"
const _ENC_P2 = "Secret_"
const _ENC_P3 = "Key_2024!"
const ENCRYPTION_PASSWORD = _ENC_P1 + _ENC_P2 + _ENC_P3

# === STATE ===
var last_error_message: String = ""
var last_save_time: float = 0.0
var auto_save_enabled: bool = true
const AUTO_SAVE_INTERVAL: float = 300.0  # 5 minutes

# === CACHED DATA (for faster loading) ===
var _cached_slot_info: Dictionary = {}
var _cache_valid: Dictionary = {}

# === INITIALIZATION ===
func _ready() -> void:
	_ensure_save_directory()
	_clear_flags()
	_start_auto_save_timer()
	update_save_flags()  # Build cache
	_debug_log("SaveManager initialized successfully")

func _ensure_save_directory() -> void:
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")

func _clear_flags() -> void:
	set_meta("load_saved_position", false)
	set_meta("saved_player_position", Vector2.ZERO)
	current_save_slot = 0
	selected_slot = 0
	is_loading_save = false
	last_error_message = ""

func _start_auto_save_timer() -> void:
	var timer = Timer.new()
	timer.wait_time = AUTO_SAVE_INTERVAL
	timer.autostart = true
	timer.timeout.connect(_on_auto_save_timer_timeout)
	add_child(timer)

func _on_auto_save_timer_timeout() -> void:
	if auto_save_enabled and current_save_slot > 0:
		auto_save()

# === CORE SAVE/LOAD FUNCTIONS ===

func save_slot(slot_number: int, scene_path: String, player_position: Vector2) -> bool:
	_debug_log("=== SAVING SLOT %d ===" % slot_number)
	
	if not _validate_slot_number(slot_number):
		return false
	
	current_save_slot = slot_number
	
	var config = ConfigFile.new()
	
	# === SAVE GAME DATA ===
	var global_data = Global.get_save_data()
	for key in global_data.keys():
		config.set_value("global", key, global_data[key])
	
	# === SAVE SCENE INFO ===
	config.set_value("scene", "current_scene", scene_path)
	config.set_value("scene", "player_position", var_to_str(player_position))
	
	# === SAVE METADATA ===
	config.set_value("meta", "save_time", Time.get_datetime_string_from_system())
	config.set_value("meta", "play_time", float(Global.s))
	config.set_value("meta", "save_version", 1)
	config.set_value("meta", "game_version", ProjectSettings.get_setting("application/config/version", "1.0"))
	
	# === CHECKSUM ===
	var checksum = _generate_checksum(config)
	config.set_value("meta", "checksum", checksum)
	
	# === ATOMIC WRITE ===
	if not _atomic_save(slot_number, config):
		return false
	
	# === SUCCESS ===
	last_save_time = Time.get_ticks_msec() / 1000.0
	_invalidate_cache(slot_number)
	update_save_flags()
	_debug_log("✓ Slot %d saved successfully!" % slot_number)
	return true

func load_slot(slot_number: int) -> bool:
	_debug_log("=== LOADING SLOT %d ===" % slot_number)
	
	if not _validate_slot_number(slot_number):
		return false
	
	if not slot_has_save(slot_number):
		last_error_message = "No save file exists for slot " + str(slot_number)
		_debug_log("✗ " + last_error_message)
		return false
	
	var config = ConfigFile.new()
	var err = config.load_encrypted_pass(SLOT_FILES[slot_number], ENCRYPTION_PASSWORD)
	
	if err != OK:
		last_error_message = "Failed to decrypt save file (Error: " + str(err) + ")"
		_debug_log("✗ " + last_error_message)
		return _try_restore_from_backup(slot_number)
	
	# === VERIFY CHECKSUM ===
	if not _verify_checksum(config):
		last_error_message = "Save file corrupted (checksum mismatch)"
		_debug_log("✗ " + last_error_message)
		return _try_restore_from_backup(slot_number)
	
	# === CHECK VERSION ===
	var save_version = config.get_value("meta", "save_version", 0)
	if save_version != 1:
		last_error_message = "Incompatible save version: " + str(save_version)
		_debug_log("✗ " + last_error_message)
		return false
	
	# === LOAD GLOBAL DATA ===
	var global_data = {}
	if config.has_section("global"):
		for key in config.get_section_keys("global"):
			global_data[key] = config.get_value("global", key)
		Global.load_save_data(global_data)
	
	# === LOAD PLAY TIME ===
	Global.s = int(config.get_value("meta", "play_time", 0.0))
	Global.ss = 0
	
	# === LOAD SCENE ===
	var saved_scene = config.get_value("scene", "current_scene", "")
	var player_pos_str = config.get_value("scene", "player_position", "Vector2(0, 0)")
	var player_pos = str_to_var(player_pos_str)
	
	if saved_scene != "":
		# Store position for SceneLoader
		set_meta("saved_player_position", player_pos)
		set_meta("load_saved_position", true)
		
		current_save_slot = slot_number
		is_loading_save = true
		
		# Change scene
		get_tree().change_scene_to_file(saved_scene)
	
	update_save_flags()
	_debug_log("✓ Slot %d loaded successfully!" % slot_number)
	return true

func new_game_slot(slot_number: int, starting_scene: String) -> bool:
	_debug_log("=== STARTING NEW GAME IN SLOT %d ===" % slot_number)
	
	if not _validate_slot_number(slot_number):
		return false
	
	# Reset game state
	Global.reset_game_state()
	Global.s = 0
	Global.ss = 0
	
	current_save_slot = slot_number
	
	# Clear position restore flag (we start at default position)
	set_meta("load_saved_position", false)
	set_meta("saved_player_position", Vector2.ZERO)
	
	# DON'T save here - let the level save after player spawns
	# This avoids race conditions
	
	# Load starting scene
	get_tree().change_scene_to_file(starting_scene)
	
	_debug_log("✓ New game started in slot %d" % slot_number)
	return true

func auto_save(slot_number: int = -1) -> bool:
	var slot = current_save_slot if slot_number == -1 else slot_number
	
	if slot == 0:
		last_error_message = "No active save slot for auto-save"
		return false
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		last_error_message = "Player not found for auto-save"
		return false
	
	var scene_path = get_tree().current_scene.scene_file_path
	if scene_path.is_empty():
		last_error_message = "Could not determine current scene"
		return false
	
	_debug_log("Auto-saving to slot %d..." % slot)
	return save_slot(slot, scene_path, player.global_position)

func delete_slot(slot_number: int) -> bool:
	_debug_log("=== DELETING SLOT %d ===" % slot_number)
	
	if not _validate_slot_number(slot_number):
		return false
	
	if not slot_has_save(slot_number):
		last_error_message = "No save file to delete"
		return false
	
	var dir = DirAccess.open("user://saves/")
	var err = dir.remove(SLOT_FILES[slot_number].get_file())
	
	if err != OK:
		last_error_message = "Failed to delete save file"
		return false
	
	# Delete backups too
	dir.remove(SLOT_FILES[slot_number].get_file() + ".bak1")
	dir.remove(SLOT_FILES[slot_number].get_file() + ".bak2")
	
	_invalidate_cache(slot_number)
	update_save_flags()
	_debug_log("✓ Slot %d deleted" % slot_number)
	return true

# === QUERY FUNCTIONS ===

func slot_has_save(slot_number: int) -> bool:
	if slot_number < 1 or slot_number > 4:
		return false
	return FileAccess.file_exists(SLOT_FILES[slot_number])

func get_slot_info(slot_number: int) -> Dictionary:
	# Check cache first
	if _cache_valid.get(slot_number, false):
		return _cached_slot_info.get(slot_number, {})
	
	if not slot_has_save(slot_number):
		return {}
	
	var config = ConfigFile.new()
	var err = config.load_encrypted_pass(SLOT_FILES[slot_number], ENCRYPTION_PASSWORD)
	
	if err != OK or not _verify_checksum(config):
		return {"corrupted": true}
	
	var info = {
		"play_time": config.get_value("meta", "play_time", 0.0),
		"save_time": config.get_value("meta", "save_time", "Unknown"),
		"scene": config.get_value("scene", "current_scene", ""),
		"soul_balls": config.get_value("global", "soul_balls_count", 0),
		"blue_burries": config.get_value("global", "BlueBurries", 0),
		"level_name": config.get_value("global", "current_level_name", ""),
		"game_version": config.get_value("meta", "game_version", "1.0")
	}
	
	# Cache the result
	_cached_slot_info[slot_number] = info
	_cache_valid[slot_number] = true
	
	return info

func validate_save_file(slot_number: int) -> Dictionary:
	var result = {"valid": false, "error": "", "can_restore": false}
	
	if not slot_has_save(slot_number):
		result.error = "File not found"
		return result
	
	var config = ConfigFile.new()
	var err = config.load_encrypted_pass(SLOT_FILES[slot_number], ENCRYPTION_PASSWORD)
	
	if err != OK:
		result.error = "Decryption failed"
		result.can_restore = _has_backup(slot_number)
		return result
	
	if not _verify_checksum(config):
		result.error = "Checksum mismatch (file corrupted or tampered)"
		result.can_restore = _has_backup(slot_number)
		return result
	
	result.valid = true
	return result

func update_save_flags() -> void:
	Global._slot_1_saved_flag = slot_has_save(1)
	Global._slot_2_saved_flag = slot_has_save(2)
	Global._slot_3_saved_flag = slot_has_save(3)
	Global._slot_4_saved_flag = slot_has_save(4)

func get_last_error() -> String:
	return last_error_message

# === CACHE MANAGEMENT ===

func _invalidate_cache(slot_number: int) -> void:
	_cache_valid[slot_number] = false
	if _cached_slot_info.has(slot_number):
		_cached_slot_info.erase(slot_number)

# === INTERNAL HELPERS ===

func _validate_slot_number(slot: int) -> bool:
	if slot < 1 or slot > 4:
		last_error_message = "Invalid slot number: " + str(slot)
		push_error(last_error_message)
		return false
	return true

func _atomic_save(slot_number: int, config: ConfigFile) -> bool:
	var temp_path = SLOT_FILES[slot_number] + ".tmp"
	
	# Save to temp file
	var err = config.save_encrypted_pass(temp_path, ENCRYPTION_PASSWORD)
	if err != OK:
		last_error_message = "Failed to write temp file"
		return false
	
	# Verify temp file
	var verify_config = ConfigFile.new()
	err = verify_config.load_encrypted_pass(temp_path, ENCRYPTION_PASSWORD)
	if err != OK or not _verify_checksum(verify_config):
		DirAccess.remove_absolute(temp_path)
		last_error_message = "Temp file verification failed"
		return false
	
	# Create backup
	_create_backup(slot_number)
	
	# Rename temp to actual (atomic operation)
	var dir = DirAccess.open("user://saves/")
	err = dir.rename(temp_path.get_file(), SLOT_FILES[slot_number].get_file())
	if err != OK:
		last_error_message = "Failed to finalize save"
		return false
	
	return true

func _create_backup(slot_number: int) -> void:
	var dir = DirAccess.open("user://saves/")
	var base = SLOT_FILES[slot_number].get_file()
	
	# Shift backups: bak1 → bak2, main → bak1
	if dir.file_exists(base + ".bak1"):
		dir.remove(base + ".bak2")
		dir.rename(base + ".bak1", base + ".bak2")
	
	if dir.file_exists(base):
		dir.rename(base, base + ".bak1")

func _has_backup(slot_number: int) -> bool:
	var dir = DirAccess.open("user://saves/")
	var base = SLOT_FILES[slot_number].get_file()
	return dir.file_exists(base + ".bak1") or dir.file_exists(base + ".bak2")

func _try_restore_from_backup(slot_number: int) -> bool:
	_debug_log("Attempting to restore from backup...")
	
	var dir = DirAccess.open("user://saves/")
	var base = SLOT_FILES[slot_number].get_file()
	
	# Try bak1
	if dir.file_exists(base + ".bak1"):
		if _test_backup(slot_number, ".bak1"):
			dir.rename(base + ".bak1", base)
			_debug_log("✓ Restored from backup 1")
			return load_slot(slot_number)
	
	# Try bak2
	if dir.file_exists(base + ".bak2"):
		if _test_backup(slot_number, ".bak2"):
			dir.rename(base + ".bak2", base)
			_debug_log("✓ Restored from backup 2")
			return load_slot(slot_number)
	
	last_error_message = "No valid backup found"
	return false

func _test_backup(slot_number: int, suffix: String) -> bool:
	var backup_path = "user://saves/" + SLOT_FILES[slot_number].get_file() + suffix
	var config = ConfigFile.new()
	var err = config.load_encrypted_pass(backup_path, ENCRYPTION_PASSWORD)
	return err == OK and _verify_checksum(config)

func restore_from_backup(slot_number: int) -> bool:
	return _try_restore_from_backup(slot_number)

# === CHECKSUM FUNCTIONS ===

func _generate_checksum(config: ConfigFile) -> String:
	var crypto = Crypto.new()
	var salt = crypto.generate_random_bytes(16)
	var data_str = _get_save_data_string(config)
	
	var key = ENCRYPTION_PASSWORD.sha256_buffer()
	var hmac = crypto.hmac_digest(HashingContext.HASH_SHA256, key, data_str.to_utf8_buffer() + salt)
	
	return hmac.hex_encode() + ":" + salt.hex_encode()

func _verify_checksum(config: ConfigFile) -> bool:
	var stored = config.get_value("meta", "checksum", "")
	if stored.is_empty() or not ":" in stored:
		return false
	
	var parts = stored.split(":")
	var stored_hmac = parts[0]
	var salt = _hex_to_bytes(parts[1])
	
	var data_str = _get_save_data_string(config)
	var crypto = Crypto.new()
	var key = ENCRYPTION_PASSWORD.sha256_buffer()
	var computed_hmac = crypto.hmac_digest(HashingContext.HASH_SHA256, key, data_str.to_utf8_buffer() + salt)
	
	return computed_hmac.hex_encode() == stored_hmac

func _get_save_data_string(config: ConfigFile) -> String:
	var data = ""
	for section in config.get_sections():
		data += section + ":"
		for key in config.get_section_keys(section):
			if section == "meta" and key == "checksum":
				continue
			data += key + "=" + str(config.get_value(section, key)) + ";"
		data += "|"
	return data

func _hex_to_bytes(hex: String) -> PackedByteArray:
	var bytes = PackedByteArray()
	for i in range(0, hex.length(), 2):
		bytes.append(hex.substr(i, 2).hex_to_int())
	return bytes

# === DEBUG ===

func _debug_log(message: String) -> void:
	if Global.debug_save_system:
		print("[SaveManager] ", message)
