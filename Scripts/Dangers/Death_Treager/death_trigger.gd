# DeathTrigger.gd
# Fixed version for continuous death detection
extends Area2D

@export_group("Death Trigger Settings")
@export var trigger_once_only: bool = false
@export var show_debug_messages: bool = true
@export var ignore_invulnerability: bool = false  # Force death even during invulnerability
@export var continuous_check: bool = true  # Check every frame while player is inside

# Internal variables
var has_triggered: bool = false
var player_inside: Node2D = null  # Track if player is currently inside

func _ready():
	# Add to death triggers group so player can find it
	add_to_group("death_triggers")
	
	# Connect the area signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# CRITICAL FIX: Set correct collision settings
	collision_layer = 4  # Put death triggers on layer 4
	collision_mask = 1   # Detect player on layer 1
	

func _process(_delta):
	# Continuously check if player is inside and should die
	if continuous_check and player_inside != null:
		if is_instance_valid(player_inside) and not player_inside.is_dying:
			attempt_trigger_death(player_inside)

func _on_body_entered(body):
	
	# Check if it's the player
	if body.is_in_group("player"):
		player_inside = body
		
		# Try to trigger death immediately on entry
		if not trigger_once_only or not has_triggered:
			attempt_trigger_death(body)

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_inside = null

func attempt_trigger_death(player):
	"""Attempt to trigger death with all checks"""
	if not player or not is_instance_valid(player):
		return
	
	# Check if already triggered once
	if trigger_once_only and has_triggered:
		return
	
	# Check if player is already dying (property check)
	if "is_dying" in player and player.is_dying:
		return
	
	# Check if player is invulnerable (unless we ignore it)
	if not ignore_invulnerability:
		if player.has_method("is_player_invulnerable") and player.is_player_invulnerable():
			if show_debug_messages:
				pass
			return
	
	# Trigger the death
	trigger_death(player)

func trigger_death(player):
	"""Trigger the death function on the player"""
	if not player or not is_instance_valid(player):
		return
	
	# Check if player has the death function
	if player.has_method("_on_health_component_death"):		
		# Call the death function
		player._on_health_component_death()
		
		# Mark as triggered if it's once only
		if trigger_once_only:
			has_triggered = true
	elif player.has_method("die") or player.has_method("kill"):
		# Try alternative death methods
		if player.has_method("die"):
			player.die()
		elif player.has_method("kill"):
			player.kill()
			
		if trigger_once_only:
			has_triggered = true

func reset_trigger():
	"""Reset the trigger so it can cause death again"""
	has_triggered = false
	player_inside = null

# Debug function to force trigger a death
func debug_force_death():
	"""Force trigger death for testing"""
	if OS.is_debug_build():
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			trigger_death(players[0])

# Optional: Visualize the death trigger in editor
func _draw():
	if Engine.is_editor_hint():
		# Draw a red X to show this is a death trigger
		draw_line(Vector2(-20, -20), Vector2(20, 20), Color.RED, 2.0)
		draw_line(Vector2(-20, 20), Vector2(20, -20), Color.RED, 2.0)
