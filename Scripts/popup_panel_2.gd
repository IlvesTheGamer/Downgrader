extends PopupPanel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	show()



func _on_reset_button_pressed() -> void:
	call_deferred("_reset_scene")

func _reset_scene() -> void:
	var current = get_tree().current_scene
	if current and current.scene_file_path != "":
		get_tree().change_scene_to_file(current.scene_file_path)
