extends Node3D

var sens = 0.0018

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED





func _input(event) -> void:
	if event is InputEventMouseMotion:
		get_parent().rotate(Vector3.UP, -event.relative.x * sens)
		rotate_x(-event.relative.y * sens)
		rotation.x = clamp(rotation.x, deg_to_rad(-90), deg_to_rad(90))
