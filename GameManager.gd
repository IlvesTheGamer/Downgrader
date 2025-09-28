# GameManager.gd - Add this to your main game scene
extends Node

 
@onready var player: CharacterBody2D = $"../Player"  # Adjust path to your player
@onready var sacrifice_popup: Control = $"../CanvasLayer/ControlSacrificePopup"

var current_level = 1
var disabled_controls = []

# Level progression - defines how many controls to sacrifice per level
var level_sacrifice_requirements = {
	1: 0,  # Tutorial level - all controls
	2: 1,  # Sacrifice 1 control
	3: 1,  # Sacrifice 1 control  
	4: 2,  # Sacrifice 2 controls
	5: 2,  # Sacrifice 2 controls
	6: 3,  # Sacrifice 3 controls (only 1 control left!)
}

func _ready():
	sacrifice_popup.controls_confirmed.connect(_on_controls_sacrificed)
	sacrifice_popup.popup_closed.connect(_on_popup_closed)
	
	# Start first level
	start_level(current_level)

func start_level(level: int):
	print("Starting level: ", level)
	current_level = level
	
	# Set the current level in the sacrifice popup
	sacrifice_popup.set_current_level(level)
	
	
	
	# Lock player movement at start of level
	if player and player.has_method("lock_movement"):
		player.lock_movement()
		print("Player movement locked for level start")  # Debug
	else:
		print("ERROR: Could not find player or lock_movement method")  # Debug
	
	# Reset all controls first
	disabled_controls.clear()
	
	# Check if we need to sacrifice controls
	var required_sacrifices = level_sacrifice_requirements.get(level, 0)
	print("Required sacrifices for level ", level, ": ", required_sacrifices)  # Debug
	
	if required_sacrifices > 0:
		sacrifice_popup.show_sacrifice_popup(level, required_sacrifices)
	else:
		# No sacrifices needed, start level immediately
		_update_player_controls()
		_start_level_gameplay()

func _on_controls_sacrificed(sacrificed_controls_array: Array):
	print("Controls sacrificed: ", sacrificed_controls_array)  # Debug
	disabled_controls = sacrificed_controls_array.duplicate()
	_update_player_controls()
	_start_level_gameplay()

func _on_popup_closed():
	# Popup was closed, continue with current disabled controls
	pass

func _start_level_gameplay():
	# Here you would start the actual level gameplay
	# Enable player input, start timers, etc.
	print("Level %d started! Disabled controls: %s" % [current_level, disabled_controls])

func _update_player_controls():
	# Update the player's movement script with disabled controls
	if player and player.has_method("set_disabled_controls"):
		player.set_disabled_controls(disabled_controls)
	
	# Unlock player movement
	if player and player.has_method("unlock_movement"):
		player.unlock_movement()

func restart_current_level():
	# Called when player wants to restart level and choose new controls
	var required_sacrifices = level_sacrifice_requirements.get(current_level, 0)
	if required_sacrifices > 0:
		sacrifice_popup.show_restart_sacrifice_popup(current_level, required_sacrifices)
	else:
		# No sacrifices needed for this level
		start_level(current_level)

func advance_to_next_level():
	# Called when player completes current level
	current_level += 1
	start_level(current_level)
