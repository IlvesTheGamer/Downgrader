# ControlSacrificePopup.gd
extends Control

@onready var popup_panel: PopupPanel = $PopupPanel
@onready var title_label: Label = $PopupPanel/VBoxContainer/TitleLabel
@onready var instruction_label: Label = $PopupPanel/VBoxContainer/InstructionLabel
@onready var controls_container: VBoxContainer = $PopupPanel/VBoxContainer/ControlsContainer
@onready var confirm_button: Button = $PopupPanel/VBoxContainer/ButtonContainer/ConfirmButton
@onready var reset_button: Button = $PopupPanel/VBoxContainer/ButtonContainer/ResetButton

# Control options
var available_controls = {
	"move_left": {"display_name": "Move Left (A)", "enabled": true},
	"move_right": {"display_name": "Move Right (D)", "enabled": true},
	"jump": {"display_name": "Jump (W)", "enabled": true},
	"dash": {"display_name": "Dash (Shift)", "enabled": true}
}

var required_sacrifices = 1  # How many controls need to be sacrificed
var sacrificed_controls = []
var control_buttons = {}


signal controls_confirmed(sacrificed_controls: Array)
signal popup_closed()


func _ready():

	hide()

	confirm_button.pressed.connect(_on_confirm_pressed)

	reset_button.pressed.connect(_on_reset_pressed)

	
	# Set mouse filter to stop clicks from passing through
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Make sure popup stays on top
	z_index = 100

func show_sacrifice_popup(level: int, required_sacrifice_count: int):

	required_sacrifices = required_sacrifice_count
	sacrificed_controls.clear()
	
	# Update labels
	title_label.text = "Level %d - Choose Your Sacrifice" % level
	instruction_label.text = "You must sacrifice 1 control to proceed.\nClick on the controls you want to sacrifice:"
	
	
	_create_control_buttons()
	_update_confirm_button()
	
	show()
	# Pause the game to prevent movement
	get_tree().paused = true

func _create_control_buttons():
	# Clear existing buttons
	for child in controls_container.get_children():
		child.queue_free()
		await child.tree_exited  # Wait for cleanup
	control_buttons.clear()
	
	# Create buttons for each available control
	for control_key in available_controls.keys():
		if available_controls[control_key]["enabled"]: #if available_controls[control_key].enabled:
			var button = Button.new()
			button.text = available_controls[control_key].display_name
			button.name = control_key
			button.toggle_mode = true
			button.custom_minimum_size = Vector2(300, 40)
			
			# Style the button
			button.flat = false
			
			print("yep")
			button.toggled.connect(_on_control_button_toggled.bind(control_key))
			
			controls_container.add_child(button)
			control_buttons[control_key] = button

func _on_control_button_toggled(control_key: String, pressed: bool):
	print("Button toggled: ", control_key, " pressed: ", pressed)
	
	if pressed:
		# Check if we can add more sacrifices
		if sacrificed_controls.size() < required_sacrifices:
			if not control_key in sacrificed_controls:
				sacrificed_controls.append(control_key)
				print("Added to sacrificed: ", sacrificed_controls)
		else:
			# Can't add more, untoggle this button
			control_buttons[control_key].set_pressed_no_signal(false)
			print("Max selections reached, untoggling")
			return
	else:
		# Remove from sacrificed controls
		if control_key in sacrificed_controls:
			sacrificed_controls.erase(control_key)
			print("Removed from sacrificed: ", sacrificed_controls)
	
	_update_button_states()
	_update_confirm_button()

func _update_button_states():
	print("Updating button states. Sacrificed: ", sacrificed_controls)  # Debug
	var max_selections_reached = sacrificed_controls.size() >= required_sacrifices
	
	for control_key in control_buttons.keys():
		var button = control_buttons[control_key]
		var is_selected = control_key in sacrificed_controls
		
		if is_selected:
			# Selected button - red background, keep pressed
			button.modulate = Color.RED
			button.text = "❌ " + available_controls[control_key].display_name + " (SACRIFICED)"
			button.set_pressed_no_signal(true)
		else:
			# Unselected button
			button.set_pressed_no_signal(false)
			if max_selections_reached:
				# Disabled state - gray out
				button.modulate = Color.GRAY
				button.disabled = true
				button.text = available_controls[control_key].display_name + " (Can't select more)"
			else:
				# Available state - normal
				button.modulate = Color.WHITE
				button.disabled = false
				button.text = "✓ " + available_controls[control_key].display_name

func _update_confirm_button():
	confirm_button.disabled = sacrificed_controls.size() != required_sacrifices
	
	if sacrificed_controls.size() < required_sacrifices:
		var remaining = required_sacrifices - sacrificed_controls.size()
		if remaining == 1:
			confirm_button.text = "Select 1 more control"
		else:
			confirm_button.text = "Select %d more controls" % remaining
	else:
		confirm_button.text = "Confirm Sacrifice & Start Level"

func _on_confirm_pressed():
	if sacrificed_controls.size() == required_sacrifices:
		controls_confirmed.emit(sacrificed_controls.duplicate())
		_close_popup()

func _on_reset_pressed():
	# Reset all buttons
	print("Resetting all selections")  # Debug
	sacrificed_controls.clear()
	for control_key in control_buttons.keys():
		var button = control_buttons[control_key]
		button.set_pressed_no_signal(false)
		button.disabled = false
		button.modulate = Color.WHITE
		button.text = "✓ " + available_controls[control_key].display_name
	_update_confirm_button()

func _close_popup():
	hide()
	get_tree().paused = false
	popup_closed.emit()

func _input(event):
	# Prevent ESC from closing popup - force player to make choice
	if visible and event.is_action_pressed("ui_cancel"):
		# Show a message that they must make a choice
		instruction_label.text = "You MUST sacrifice controls to continue!\nClick on the controls you want to sacrifice:"
		instruction_label.modulate = Color.YELLOW
		
		# Flash the instruction
		var tween = create_tween()
		tween.tween_property(instruction_label, "modulate", Color.WHITE, 1.0)

# Function to call when restarting level
func show_restart_sacrifice_popup(current_level: int, required_sacrifice_count: int):
	title_label.text = "Restart Level %d - Choose New Sacrifice" % current_level
	show_sacrifice_popup(current_level, required_sacrifice_count)
