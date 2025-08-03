extends CanvasLayer

func _on_something_done():
	if %option1.is_done and %option2.is_done:
		$loading_overlay.visible = false

func _on_option_1_selected() -> void:
	EvolutionManager.vote_for_competitor(0)
	get_tree().reload_current_scene()


func _on_option_2_selected() -> void:
	EvolutionManager.vote_for_competitor(1)
	get_tree().reload_current_scene()

func _ready() -> void:
	$loading_overlay.visible = true

	EvolutionManager.prepare_competition()

	%option1.render_plant(EvolutionManager.get_competitor(0))
	%option2.render_plant(EvolutionManager.get_competitor(1))
