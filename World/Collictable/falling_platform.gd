extends Node2D

# ===== EXPORTED VARIABLES =====
@export var shake_strength: float = 3.0
@export var shake_duration: float = 0.8
@export var fade_delay: float = 1.0
@export var respawn_delay: float = 3.0

# ===== INTERNAL VARIABLES =====
var is_triggered: bool = false
var platform_pieces: Array = []
var original_positions: Array = []

# ===== INITIALIZATION =====
func _ready():
	print("FadingPlatform ready!")
	setup_pieces()

func setup_pieces():
	"""تجهيز قطع المنصة وحفظ المواضع الأصلية"""
	platform_pieces.clear()
	original_positions.clear()
	
	for child in get_children():
		if child is RigidBody2D:
			platform_pieces.append(child)
			original_positions.append(child.global_position)
			
			# تجميد القطعة في البداية
			child.freeze = true
			child.gravity_scale = 1.5
			
			print("Found platform piece: ", child.name)
	
	print("Total platform pieces: ", platform_pieces.size())

# ===== MAIN TRIGGER FUNCTION =====
func trigger_fade():
	"""تشغيل تسلسل اختفاء وإعادة ظهور المنصة"""
	if is_triggered:
		print("Platform already triggered!")
		return
		
	print("Platform triggered! Starting fade sequence...")
	is_triggered = true
	start_shake_sequence()

# ===== SHAKE SEQUENCE =====
func start_shake_sequence():
	"""بدء تسلسل الاهتزاز قبل الاختفاء"""
	print("Starting shake sequence...")
	
	# هز كل قطعة بتأخير بسيط
	for i in platform_pieces.size():
		shake_piece_sprite(platform_pieces[i], i * 0.1)
	
	# انتظار انتهاء فترة الاهتزاز ثم بدء الاختفاء
	await get_tree().create_timer(fade_delay).timeout
	start_fade_out_sequence()

func shake_piece_sprite(piece: RigidBody2D, delay: float = 0.0):
	"""اهتزاز الـ sprite فقط دون تحريك الـ RigidBody2D"""
	await get_tree().create_timer(delay).timeout
	
	# البحث عن الـ sprite داخل القطعة
	for child in piece.get_children():
		if child is Sprite2D or child is ColorRect or child is TextureRect:
			var tween = create_tween()
			var original_pos = child.position
			
			# تسلسل الاهتزاز
			tween.tween_property(child, "position", original_pos + Vector2(shake_strength * 0.3, 0), 0.08)
			tween.tween_property(child, "position", original_pos + Vector2(-shake_strength * 0.5, -1), 0.12)
			tween.tween_property(child, "position", original_pos + Vector2(shake_strength * 0.8, 0), 0.15)
			tween.tween_property(child, "position", original_pos + Vector2(-shake_strength, 1), 0.15)
			tween.tween_property(child, "position", original_pos + Vector2(shake_strength * 0.6, 0), 0.12)
			tween.tween_property(child, "position", original_pos + Vector2(-shake_strength * 0.3, 0), 0.1)
			tween.tween_property(child, "position", original_pos, 0.08)
			break

# ===== FADE OUT SEQUENCE =====
func start_fade_out_sequence():
	"""بدء تسلسل الاختفاء التدريجي"""
	print("Starting fade out sequence...")
	
	# اختفاء القطع بشكل متدرج
	await fade_pieces_gradually(true)
	
	# تعطيل التصادمات
	disable_all_collisions()
	
	# انتظار فترة إعادة الظهور
	await get_tree().create_timer(respawn_delay).timeout
	
	# إعادة تفعيل التصادمات وبدء إعادة الظهور
	enable_all_collisions()
	start_fade_in_sequence()

func fade_pieces_gradually(fade_out: bool):
	"""اختفاء أو ظهور القطع بشكل متدرج"""
	var total_pieces = platform_pieces.size()
	
	if total_pieces == 0:
		print("No pieces to fade!")
		return
	
	# القطعة الأولى
	if total_pieces > 0:
		fade_piece(platform_pieces[0], fade_out)
		await get_tree().create_timer(0.4).timeout
	
	# القطعتين الثانية والثالثة معاً
	if total_pieces > 1:
		fade_piece(platform_pieces[1], fade_out)
	if total_pieces > 2:
		fade_piece(platform_pieces[2], fade_out)
		await get_tree().create_timer(0.4).timeout
	
	# باقي القطع
	for i in range(3, total_pieces):
		fade_piece(platform_pieces[i], fade_out)
		await get_tree().create_timer(0.2).timeout
	
	# انتظار انتهاء آخر تحريك
	await get_tree().create_timer(0.5).timeout

func fade_piece(piece: RigidBody2D, fade_out: bool):
	"""اختفاء أو ظهور قطعة واحدة"""
	var fade_tween = create_tween()
	fade_tween.set_parallel(true)
	
	if fade_out:
		print("Fading out piece: ", piece.name)
		# اختفاء تدريجي بالشفافية فقط
		for child in piece.get_children():
			if child is Sprite2D or child is ColorRect or child is TextureRect:
				fade_tween.tween_property(child, "modulate:a", 0.0, 0.5)
				break
	else:
		print("Fading in piece: ", piece.name)
		# إعادة تعيين المقياس إلى الحجم الطبيعي فوراً
		piece.scale = Vector2(1.0, 1.0)
		
		# ظهور تدريجي بالشفافية فقط
		for child in piece.get_children():
			if child is Sprite2D or child is ColorRect or child is TextureRect:
				child.modulate.a = 0.0
				fade_tween.tween_property(child, "modulate:a", 1.0, 0.6)
				break

# ===== FADE IN SEQUENCE =====
func start_fade_in_sequence():
	"""بدء تسلسل الظهور التدريجي"""
	print("Starting fade in sequence...")
	
	# ظهور القطع بشكل متدرج
	await fade_pieces_gradually(false)
	
	# إعادة تعيين حالة المنصة
	is_triggered = false
	print("Platform fully restored and ready!")

# ===== COLLISION MANAGEMENT =====
func disable_all_collisions():
	"""تعطيل جميع تصادمات المنصة"""
	print("Disabling all collisions...")
	for piece in platform_pieces:
		for child in piece.get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				child.disabled = true

func enable_all_collisions():
	"""تفعيل جميع تصادمات المنصة"""
	print("Enabling all collisions...")
	for piece in platform_pieces:
		for child in piece.get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				child.disabled = false

# ===== EVENT HANDLERS =====
func _on_area_2d_body_entered(body):
	"""معالج دخول جسم إلى منطقة التشغيل"""
	if body.name == "Player" or body.is_in_group("player"):
		trigger_fade()
