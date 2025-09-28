extends Area2D


@export var target_position: Vector2

func _on_teleport_body_entered(body):
	if body.is_in_group ("Player"):
		body.global_position = target_position
	print ("entered teleport")

func _ready():
	body_entered.connect(_on_teleport_body_entered)
