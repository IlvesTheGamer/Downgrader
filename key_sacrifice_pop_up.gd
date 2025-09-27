extends PopupPanel

var key_actions = {
	"Key_W": "ui_up",
	"Key_A": "ui_left",
	"Key_S": "ui_down",
	"Key_D": "ui_right",

}
func _ready() -> void:
	_keychoice1() # Replace with function body.


func _keychoice1():
	popup_centered()
	for button_name in key_actions.keys():
		var btn = $VBoxContainer/HBoxContainer.get_node(button_name)
		btn.disabled = false
		btn.modulate = Color(1, 1, 1)
		
		# Godot 4.5 correct connect
		if not btn.pressed.is_connected(Callable(self, "_on_key_pressed").bind(button_name)):
			btn.pressed.connect(Callable(self, "_on_key_pressed").bind(button_name))

func _on_key_pressed(button_name):
	InputMap.action_erase_events(key_actions[button_name])
	var btn = $VBoxContainer/HBoxContainer.get_node(button_name)
	btn.disabled = true
	btn.modulate = Color(0.5, 0.5, 0.5)
	hide()
