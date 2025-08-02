@tool
extends Node3D

@export var dna: DNA

@export var segments_limit: int = 512

var _segments: int = 0
var _tasks: Array[GrowthTask] = []

class GrowthTask:
	var parent_segment: PlantSegment
	var source_row: int
	
	func _init(ps: PlantSegment = null, sr: int = 0):
		parent_segment = ps
		source_row = sr

const _DNA_NEXT_START = 4

func _sum_quarter_bytes(v: int) -> int:
	return (v & 0x3) + ((v >> 2) & 0x3)

func _enqueue_next_task(row: int, segment: PlantSegment):
	var weights: Array[int] = []
	var total_weights: int = 0
	for i in range(_DNA_NEXT_START, DNA.ROW_SIZE):
		var w = dna.read_4b(row, i, 0)
		total_weights += w
		weights.append(w)

	if total_weights == 0:
		return
	
	var rnd: int = randi_range(0, total_weights)
	var acc: int = 0
	
	for i in range(_DNA_NEXT_START, DNA.ROW_SIZE):
		var w := dna.read_4b(row, i, 0)
		acc += w
		if w > 0 and acc >= rnd:
			var off = _sum_quarter_bytes(dna.read_4b(row, i, 1))
			var next_row = (row + off) % DNA.N_ROWS
			_tasks.push_back(GrowthTask.new(segment, next_row))
			break


const _SPREAD_ANGLE_BASE := PI * 0.3


@onready var segment_scene: PackedScene = load("res://segment/segment.tscn")


func _grow_task(task: GrowthTask):
	var row = task.source_row
	var base_len = dna.read_4b(row, 0, 0)
	var len_var = dna.read_4b(row, 0, 1)
	var base_hue = dna.read_4b(row, 1, 0)
	var hue_var = dna.read_4b(row, 1, 1)
	var num_base = dna.read_4b(row, 2, 0)
	var num_var = _sum_quarter_bytes(dna.read_4b(row, 2, 1))
	var spread_x = dna.read_2b(row, 3, 0)
	var spread_x_var = dna.read_2b(row, 3, 1)
	var spread_y = dna.read_2b(row, 3, 2)
	var spread_y_var = dna.read_2b(row, 3, 3)
	
	var num = _sum_quarter_bytes(num_base)
	num = (num * num + randi_range(-num_var, num_var)) / 2
	
	if num <= 0:
		if _segments > 3:
			return
		num = 1

	if num > 1:
		spread_x += 1
		spread_y += 1
	
	var base_angle = randf_range(0, PI)
	
	for i in num:
		var a = base_angle + 2.0 * PI * float(i) / float(num)
		var rx = sin(a) * _SPREAD_ANGLE_BASE * float(spread_x) / 4.0
		var ry = cos(a) * _SPREAD_ANGLE_BASE * float(spread_y) / 4.0

		rx += rx * 0.5 * randf_range(-spread_x_var, spread_x_var) / 4.0
		ry += ry * 0.5 * randf_range(-spread_y_var, spread_y_var) / 4.0

		var len = float(1 + base_len) * 0.1
		len += len * 0.1 * (randf_range(-len_var, len_var) / 16.0)

		var tr = Transform3D().rotated(Vector3.LEFT, rx).rotated(Vector3.BACK, ry)
		var segment: PlantSegment = segment_scene.instantiate()
		segment.length = len

		var col = Color.from_hsv(
			float(base_hue) / 16.0 + randf_range(-hue_var, hue_var) / 16.0 / 16.0,
			0.5,
			0.5,
		)
		segment.color_main = col
		segment.color_start = col
		segment.color_end = col

		if task.parent_segment == null:
			add_child(segment)
		else:
			task.parent_segment.add_child_segment(segment)

		segment.transform = tr
		#segment.update_all()

		_segments += 1

		_enqueue_next_task(row, segment)

func reset():
	for child in get_children(true):
		if child is PlantSegment:
			child.queue_free()
	_segments = 0
	_tasks = [GrowthTask.new()]

func grow_all():
	reset()
	while _segments < segments_limit and not _tasks.is_empty():
		_grow_task(_tasks.pop_front())
	print("Grown ", _segments, " segments")
	normalize_vissuals()

func _get_segment_min_area(segment: PlantSegment):
	return 0.01

func _area_to_radius(area: float) -> float:
	return sqrt(area) * 0.3

func _normalize_segment_visuals(segment: PlantSegment) -> float:
	var min_area = _get_segment_min_area(segment)
	var children_total_area: float = min_area
	var children_min_area: float = min_area
	var color_acc := Color.BLACK
	var n_children = 0
	
	for child in segment.get_child_segments():
		var a = _normalize_segment_visuals(child)
		children_total_area += a
		children_min_area = maxf(a, children_min_area)
		color_acc += child.color_main
		n_children += 1

	var final_area = lerpf(children_total_area, children_min_area, 0.5)

	color_acc /= float(n_children)
	segment.color_end = color_acc

	var er = _area_to_radius(final_area)
	segment.radius_end = er
	segment.radius_start = er
	
	for child in segment.get_child_segments():
		child.radius_start = er
		child.color_start = color_acc
		child.update_all()

	return final_area

func normalize_vissuals():
	var total_area: float = 0
	for child in get_children(true):
		if child is PlantSegment:
			total_area += _normalize_segment_visuals(child)

	var rs = _area_to_radius(total_area)

	for child in get_children(true):
		if child is PlantSegment:
			child.radius_start = rs
			child.update_all()

@export_tool_button("Grow")
var grow_all_btn = grow_all
