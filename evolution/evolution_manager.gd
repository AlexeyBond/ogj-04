extends Node

class_name CEvolutionManager

const BASE_RATING := 1000.0

@export var checkpoint: EvolutionCheckpoint

@export var max_species: int = 10

@export var select_size: int = 4

@export var mutation_min: int = 10
@export var mutation_max: int = 20

@export var k_factor: float = 32.0

@export var min_polls_per_species: int = 2

var cp_index = 0

var species: Array[EvolutionSpecies]

func _randomize():
	species = []
	while species.size() < max_species:
		var dna := DNA.new()
		dna.randomize()
		var s := EvolutionSpecies.new()
		s.dna = dna
		s.polls = 0
		s.rating = BASE_RATING
		species.append(s)

func _restore_checkpoint(cp: EvolutionCheckpoint):
	species = cp.species.duplicate(true)

func _save_checkpoint():
	var ts = Time.get_datetime_string_from_system().replace(':', '-')
	var url = "res://checkpoints/cp-"  + ts + "-" + str(cp_index) + ".tres"
	cp_index += 1
	var cp = EvolutionCheckpoint.new()
	cp.species = species.duplicate(true)
	ResourceSaver.save(cp, url)
	ResourceSaver.save(cp, "res://checkpoints/_latest.tres")

func _select_fittest():
	species.sort_custom(func(a, b): return a.rating > b.rating)
	species.resize(select_size)
	print("Selected ", species.size(), " species")

func _make_new_species():
	var initial := species.size()
	assert(initial >= 2)
	for s in species:
		s.polls = 0
	var i = 0
	while species.size() < max_species:
		var parent1 = species[i]
		var parent2 = species[randi() % initial]
		var dna = parent1.dna.mix(parent2.dna)
		dna.mutate(randi_range(mutation_min, mutation_max))
		var s = EvolutionSpecies.new()
		s.dna = dna
		s.rating = lerpf(lerpf(parent1.rating, parent2.rating, 0.5), BASE_RATING, 0.95)
		s.polls = 0
		species.append(s)
	print("Made new ", species.size() - initial, " species")

func prepare_competition():
	assert(species.size() >= 2)
	species.sort_custom(func(a, b): return a.polls < b.polls)

func get_competitor(i: int) -> DNA:
	assert(i == 1 or i == 0)
	assert(species.size() >= 2)
	return species[i].dna

func _update_rating(s: EvolutionSpecies, other: EvolutionSpecies, win: bool):
	var e = 1.0 / (1.0 + pow(10.0, (other.rating - s.rating) / 400))
	var r = 1.0 if win else 0.0
	s.rating += k_factor * (r - e)
	s.polls += 1

func _have_enough_polls() -> bool:
	for s in species:
		if s.polls < min_polls_per_species:
			return false
	return true

func vote_for_competitor(winner: int):
	assert(winner == 1 or winner == 0)
	var loser = 1 - winner
	_update_rating(species[winner], species[loser], true)
	_update_rating(species[loser], species[winner], false)
	_save_checkpoint()

	if _have_enough_polls():
		_select_fittest()
		_make_new_species()
		_save_checkpoint()

func _ready() -> void:
	if checkpoint == null:
		_randomize()
	else:
		_restore_checkpoint(checkpoint)
