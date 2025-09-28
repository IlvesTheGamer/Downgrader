extends Node2D

func _on_teleport_body_entered(_body: Node2D) -> void:
	if _body.name == "Player": 
		# Remove the teleport area safely
		call_deferred("queue_free")
		
		# Change the scene safely, deferred until after physics step
		call_deferred("_change_to_level_2")


func _change_to_level_2() -> void:
	get_tree().change_scene_to_file("res://Scenes/level_5.tscn")
