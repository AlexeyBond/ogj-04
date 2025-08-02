extends VBoxContainer

signal done
var is_done: bool = false

signal selected

func _on_plant_preview_done() -> void:
	is_done = true
	done.emit()

func render_plant(dna: DNA):
	is_done = false
	%PlantPreview.render_plant(dna)


func _on_button_pressed() -> void:
	selected.emit()
