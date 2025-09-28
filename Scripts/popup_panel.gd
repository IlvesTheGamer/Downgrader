extends PopupPanel

var showw = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if showw:
		show()
	

func _on_up_pressed() -> void:
	showw = false
	hide()


func _on_roll_pressed() -> void:
	showw = false
	hide()


func _on_left_pressed() -> void:
	showw = false
	hide()


func _on_right_pressed() -> void:
	showw = false
	hide()


func _on_upup_pressed() -> void:
	showw = false
	hide()
