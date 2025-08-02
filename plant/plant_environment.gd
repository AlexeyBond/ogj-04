extends Node3D

func _process(delta: float) -> void:
	var a = Input.get_axis("ui_left", "ui_right")
	
	if abs(a) > 0.1:
		$cameraContainer.rotate(Vector3.UP, a * delta)
	else:
		$cameraContainer.rotate(Vector3.UP, delta * 0.5)
