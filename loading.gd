extends Control
# LoadingScreen.gd - Professional Loading Screen
# This scene handles both new games and loading saves

@export_file("*.tscn") var new_game_scene: String = "res://Levels/map1/map_1.tscn"

@onready var progress_bar: ProgressBar = %ProgressBar
@onready var loading_label: Label = %LoadingLabel
@onready var tips_label: Label = %TipsLabel
@onready var spinner: Control = %Spinner

# Loading tips
const LOADING_TIPS = [
	"Collect Soul Balls to unlock new abilities!",
	"Blue Berries restore your health.",
	"Watch out for enemy patterns!",
	"Wall climbing helps you reach hidden areas.",
	"Save your game at checkpoints!",
	"Explore every corner for secrets.",
	"Master the wall dash to move faster!",
	"Some enemies have weak points.",
	"Don't forget to dodge enemy attacks!",
	"Your progress is automatically saved at checkpoints."
]

var _current_tip_index: int = 0
var _load_progress: float = 0.0
var _target_scene: String = ""
var _is_loading: bool = false

func _ready() -> void:
	# Hide cursor during loading
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	# Initialize UI
	if progress_bar:
		progress_bar.value = 0
	
	if tips_label:
		_show_random_tip()
		_start_tip_rotation()
	
	if spinner:
		_animate_spinner()
	
	# Start loading process
	await get_tree().process_frame
	_start_loading()

func _start_loading() -> void:
	"""بدء عملية التحميل"""
	_is_loading = true
	
	var slot = SaveManager.selected_slot
	
	if Global.debug_save_system:
		print("[LoadingScreen] Starting load process for slot ", slot)
		print("[LoadingScreen] is_loading_save = ", SaveManager.is_loading_save)
	
	# Determine what to do
	if SaveManager.is_loading_save:
		# Load existing save
		if loading_label:
			loading_label.text = "Loading Save..."
		
		await _simulate_loading_progress(0.3)
		
		var success = SaveManager.load_slot(slot)
		
		if not success:
			_show_error("Failed to load save:\n" + SaveManager.get_last_error())
			return
		
		# SaveManager.load_slot already changes the scene
		# Just show completion
		if progress_bar:
			progress_bar.value = 100
		
	else:
		# Start new game
		if loading_label:
			loading_label.text = "Starting New Game..."
		
		await _simulate_loading_progress(0.3)
		
		var success = SaveManager.new_game_slot(slot, new_game_scene)
		
		if not success:
			_show_error("Failed to start new game:\n" + SaveManager.get_last_error())
			return
		
		# SaveManager.new_game_slot already changes the scene
		if progress_bar:
			progress_bar.value = 100

func _simulate_loading_progress(duration: float) -> void:
	"""محاكاة تقدم التحميل"""
	var elapsed = 0.0
	
	while elapsed < duration:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		
		var progress = elapsed / duration
		_load_progress = progress * 100.0
		
		if progress_bar:
			progress_bar.value = _load_progress

func _show_random_tip() -> void:
	"""عرض نصيحة عشوائية"""
	if not tips_label:
		return
	
	_current_tip_index = randi() % LOADING_TIPS.size()
	tips_label.text = "Tip: " + LOADING_TIPS[_current_tip_index]

func _start_tip_rotation() -> void:
	"""بدء دوران النصائح"""
	var timer = Timer.new()
	timer.wait_time = 5.0
	timer.timeout.connect(_show_random_tip)
	timer.autostart = true
	add_child(timer)

func _animate_spinner() -> void:
	"""تحريك الـ spinner"""
	if not spinner:
		return
	
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(spinner, "rotation", TAU, 1.0)

func _show_error(message: String) -> void:
	"""عرض رسالة خطأ"""
	if loading_label:
		loading_label.text = "Error!"
		loading_label.add_theme_color_override("font_color", Color.RED)
	
	if progress_bar:
		progress_bar.visible = false
	
	if spinner:
		spinner.visible = false
	
	# Create error dialog
	await get_tree().create_timer(0.5).timeout
	
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	dialog.title = "Loading Error"
	dialog.confirmed.connect(func(): 
		get_tree().change_scene_to_file("res://UI/MainMenu.tscn")  # العودة للقائمة الرئيسية
	)
	add_child(dialog)
	dialog.popup_centered()
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(_delta: float) -> void:
	"""تحديث UI"""
	if _is_loading and progress_bar:
		# Smooth progress bar
		progress_bar.value = lerpf(progress_bar.value, _load_progress, 0.1)
