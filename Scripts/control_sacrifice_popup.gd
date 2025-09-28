

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

var required_sacrifices = 1
var sacrificed_controls = []
var control_buttons = {}
var modal_overlay: ColorRect
var is_popup_open = false
var current_level_sacrifices = {}  # Track sacrifices per level: {level: [control1, control2]}

signal controls_confirmed(sacrificed_controls: Array)
signal popup_closed()
signal popup_opened() 

func _ready():
	hide()
	confirm_button.pressed.connect(_on_confirm_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100

func show_sacrifice_popup(level: int, required_sacrifice_count: int):
	print("DEBUG: Showing sacrifice popup for level ", level, " with ", required_sacrifice_count, " sacrifices")
	
	is_popup_open = true
	required_sacrifices = required_sacrifice_count
	sacrificed_controls.clear()
	
	# Check if player already made sacrifices for this level
	if _has_already_decided_sacrifices(level):
		title_label.text = "Level %d - Faith Already Decided" % level
		instruction_label.text = "You have already chosen your sacrifices for this level.\nYour decision is final."
		_create_readonly_buttons(level)
		confirm_button.visible = false  # Hide confirm button
		reset_button.visible = false    # Hide reset button
	else:
		title_label.text = "Level %d - Choose Your Sacrifice" % level
		instruction_label.text = "You must sacrifice %d control(s) to proceed.\nClick on the controls you want to sacrifice:" % required_sacrifice_count
		_create_control_buttons()
		confirm_button.visible = true   # Show confirm button
		reset_button.visible = true     # Show reset button
	
	_update_confirm_button()
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Position in top-left corner
	# ONLY show the PopupPanel, not our Control
	popup_panel.position = Vector2(20, 20)
	popup_panel.popup()
	
	# DON'T pause the game - just disable player input through your GameManager
	# get_tree().paused = true  ← REMOVE THIS LINE
	
	# Instead, notify GameManager to disable player movement
	popup_opened.emit()  # Add this signal

func _close_popup():
	is_popup_open = false
	popup_panel.hide()
	
	# DON'T unpause the game - let GameManager handle it
	# get_tree().paused = false  ← REMOVE THIS LINE
	
	popup_closed.emit()

func _has_already_decided_sacrifices(level: int) -> bool:
	# Check if sacrifices were already made for this level
	return current_level_sacrifices.has(level) and current_level_sacrifices[level].size() > 0

func _create_readonly_buttons(level: int):
	# Clear existing buttons
	for child in controls_container.get_children():
		child.queue_free()
	control_buttons.clear()
	
	# Create disabled buttons showing previous choices
	var previous_sacrifices = current_level_sacrifices.get(level, [])
	
	for control_key in available_controls.keys():
		if available_controls[control_key]["enabled"]:
			var button = Button.new()
			button.text = available_controls[control_key].display_name
			button.name = control_key
			button.disabled = true  # Make it unclickable
			button.custom_minimum_size = Vector2(300, 40)
			button.flat = false
			
			# Check if this control was sacrificed
			if control_key in previous_sacrifices:
				button.text = "❌ " + available_controls[control_key].display_name + " (SACRIFICED)"
				button.modulate = Color.RED
			else:
				button.text = "✓ " + available_controls[control_key].display_name + " (KEPT)"
				button.modulate = Color.GREEN
			
			controls_container.add_child(button)
			control_buttons[control_key] = button

func _create_control_buttons():
	for child in controls_container.get_children():
		child.queue_free()
	control_buttons.clear()
	
	for control_key in available_controls.keys():
		if available_controls[control_key]["enabled"]:
			var button = Button.new()
			button.text = available_controls[control_key].display_name
			button.name = control_key
			controls_container.add_child(button)
			control_buttons[control_key] = button

			button.toggle_mode = true
			button.custom_minimum_size = Vector2(300, 40)
			button.flat = false
			
			button.toggled.connect(_on_control_button_toggled.bind(control_key))

func _on_control_button_toggled(button_pressed: bool, control_key: String):
	print("Button toggled: ", control_key, " pressed: ", button_pressed)
	
	if button_pressed:
		if sacrificed_controls.size() < required_sacrifices:
			if not control_key in sacrificed_controls:
				sacrificed_controls.append(control_key)
				print("Added to sacrificed: ", sacrificed_controls)
		else:
			control_buttons[control_key].set_pressed_no_signal(false)
			print("Max selections reached, untoggling")
			return
	else:
		if control_key in sacrificed_controls:
			sacrificed_controls.erase(control_key)
			print("Removed from sacrificed: ", sacrificed_controls)
	
	_update_button_states()
	_update_confirm_button()

func _update_button_states():
	print("Updating button states. Sacrificed: ", sacrificed_controls)
	var max_selections_reached = sacrificed_controls.size() >= required_sacrifices
	
	for control_key in control_buttons.keys():
		var button = control_buttons[control_key]
		var is_selected = control_key in sacrificed_controls
		
		if is_selected:
			button.modulate = Color.RED
			button.text = "❌ " + available_controls[control_key].display_name + " (SACRIFICED)"
			button.set_pressed_no_signal(true)
		else:
			button.set_pressed_no_signal(false)
			if max_selections_reached:
				button.modulate = Color.GRAY
				button.disabled = true
				button.text = available_controls[control_key].display_name + " (Can't select more)"
			else:
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
	print("DEBUG: Confirm button pressed")
	if sacrificed_controls.size() == required_sacrifices:
		# Store the sacrifices for this level
		var current_level = 2  # You need to get the actual current level
		current_level_sacrifices[current_level] = sacrificed_controls.duplicate()
		
		controls_confirmed.emit(sacrificed_controls.duplicate())
		_close_popup()

func _on_reset_pressed():
	print("DEBUG: Reset button pressed")
	sacrificed_controls.clear()
	for control_key in control_buttons.keys():
		var button = control_buttons[control_key]
		button.set_pressed_no_signal(false)
		button.disabled = false
		button.modulate = Color.WHITE
		button.text = "✓ " + available_controls[control_key].display_name
	_update_confirm_button()

	

	


func _input(event):
	# ESC toggles the menu open/close (single press)
	if event.is_action_pressed("ui_cancel"):
		# Check the ACTUAL PopupPanel visibility, not your boolean
		if popup_panel.visible:
			_close_popup()
		else:
			var current_level = 2  # Replace with how you get current level
			if current_level > 1:
				show_sacrifice_popup(current_level, 1)
		get_viewport().set_input_as_handled()

func show_restart_sacrifice_popup(current_level: int, required_sacrifice_count: int):
	title_label.text = "Restart Level %d - Choose New Sacrifice" % current_level
	show_sacrifice_popup(current_level, required_sacrifice_count)
