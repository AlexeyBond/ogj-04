extends CanvasLayer

func _on_something_done():
	if %option1.is_done and %option2.is_done:
		$loading_overlay.visible = false

func _on_option_1_selected() -> void:
	pass # Replace with function body.


func _on_option_2_selected() -> void:
	pass # Replace with function body.

func _ready() -> void:
	$loading_overlay.visible = true

	var dna1 = DNA.new()
	dna1.randomize()
	var dna2 = DNA.new()
	dna2.randomize()

	%option1.render_plant(dna1)
	%option2.render_plant(dna2)
