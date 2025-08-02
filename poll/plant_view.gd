extends Node3D

signal _done(plant: Plant)
signal done

var _thread: Thread

@export var plant_scene: PackedScene

func _put_plant(plant: Plant):
	for c in get_children(true):
		if c is Plant:
			c.queue_free()
	add_child(plant)
	done.emit()

func _ready() -> void:
	_done.connect(_put_plant)

func _run(dna: DNA):
	var plant: Plant = plant_scene.instantiate()
	plant.dna = dna
	plant.grow_all()
	_done.emit.call_deferred(plant)

func render_plant(dna: DNA):
	if _thread != null:
		_thread.wait_to_finish()
	_thread = Thread.new()
	_thread.start(_run.bind(dna))

func _exit_tree() -> void:
	if _thread != null:
		_thread.wait_to_finish()
