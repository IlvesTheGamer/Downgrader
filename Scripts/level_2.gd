# level_2.gd - Updated with GameManager functionality
extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var sacrifice_popup: Control = $ControlSacrificePopup

var current_level = 2
var disabled_controls = []

# Level 2 requires 1 sacrifice
var required_sacrifices = 1

func _on_teleport_body_entered(_body: Node2D) -> void:
	if _body.name == "Player": 
		# Remove the teleport area safely
		call_deferred("queue_free")
		
		# Change the scene safely, deferred until after physics step
		call_deferred("_change_to_level_2")


func _change_to_level_2() -> void:
	get_tree().change_scene_to_file("res://Scenes/level_3.tscn")

func _ready():
	print("Level 2 starting")
	sacrifice_popup.controls_confirmed.connect(_on_controls_sacrificed)
	sacrifice_popup.popup_closed.connect(_on_popup_closed)
	

	
	# Start level 2 with sacrifice requirement
	start_level()

func start_level():
	print("Starting level 2 with sacrifice requirement")
	
	# Lock player movement
	if player and player.has_method("lock_movement"):
		player.lock_movement()
		print("Player movement locked for level 2")
	else:
		print("ERROR: Could not find player or lock_movement method")
	
	# Reset controls
	disabled_controls.clear()
	
	# Show sacrifice popup since level 2 requires 1 sacrifice
	sacrifice_popup.show_sacrifice_popup(current_level, required_sacrifices)
	
func _on_controls_sacrificed(sacrificed_controls_array: Array):
	print("Level 2 - Controls sacrificed: ", sacrificed_controls_array)
	disabled_controls = sacrificed_controls_array.duplicate()
	_update_player_controls()
	_start_level_gameplay()

func _on_popup_closed():
	# Popup was closed
	pass

func _update_player_controls():
	# Update the player's movement script with disabled controls
	if player and player.has_method("set_disabled_controls"):
		player.set_disabled_controls(disabled_controls)
	
	# Unlock player movement
	if player and player.has_method("unlock_movement"):
		player.unlock_movement()

func _start_level_gameplay():
	print("Level 2 gameplay started! Disabled controls: ", disabled_controls)

func restart_current_level():
	# Allow restarting with different controls
	sacrifice_popup.show_restart_sacrifice_popup(current_level, required_sacrifices)


	
