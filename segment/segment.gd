@tool
extends MeshInstance3D

class_name PlantSegment

@export var section_resolution: int = 16
@export var sections: int = 16

@export var length: float = 2.0

var length_overhead_start: float = 0.1
var length_overhead_end: float = 0.1

@export var radius_start: float = 0.5
@export var radius_end: float = 0.5

@export var color_start: Color = Color.DARK_GREEN
@export var color_end: Color = Color.DARK_GREEN
@export var color_main: Color = Color.DARK_GREEN

@export var children_container: Node3D

func _get_section_point_radius(a: float, s: float) -> float:
	var sl: float = min(
		1.0,
		pow(s / length_overhead_start, .5),
		pow((1.0 - s) / length_overhead_end, .5)
	)
	return 1.0 * sl

func _generate_section(s: float) -> PackedVector2Array:
	var arr := PackedVector2Array()
	var r_base := lerpf(radius_start, radius_end, s)
	for i in section_resolution:
		var a = 2.0 * float(i) * PI / float(section_resolution)
		var r = _get_section_point_radius(a, s) * r_base
		arr.append(Vector2(
			sin(a) * r,
			cos(a) * r
		))

	return arr

func _get_section_normals(section: PackedVector2Array) -> PackedVector2Array:
	assert(section.size() == section_resolution)
	var arr := PackedVector2Array()
	arr.resize(section_resolution)
	for i in range(section_resolution):
		var ti := (i + 1) % section_resolution
		var si := (i + 2) % section_resolution
		arr[ti] = (section[si] - section[i]).rotated(PI * 0.5).normalized()
	return arr

func _generate(st: SurfaceTool):
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	length_overhead_start = radius_start / length
	length_overhead_end = radius_end / length

	for i in sections:
		var s := float(i) / float(sections - 1)
		var y := lerpf(-(length * length_overhead_start), length + length * length_overhead_end, s)
		var s2 := clampf(y / length, 0.0, 1.0)
		var color: Color = lerp(
			lerp(color_start, color_main, clampf(s2 * 2.0, 0.0, 1.0)),
			lerp(color_main, color_end, clampf(s2 * 2.0 - 1.0, 0.0, 1.0)),
			s2
		)
		var section := _generate_section(s)
		var normals := _get_section_normals(section)

		st.set_color(color)

		for j in section_resolution:
			st.set_normal(Vector3(normals[j].x, 0.0, normals[j].y))
			st.set_uv(Vector2(float(j) / float(section_resolution), s2))
			st.add_vertex(Vector3(section[j].x, y, section[j].y))

	for si in sections - 1:
		var sstart = si * section_resolution
		var nstart = sstart + section_resolution
		for i in section_resolution:
			st.add_index(i + nstart)
			st.add_index(sstart + (i + sstart + 1) % section_resolution)
			st.add_index(i + sstart)

			st.add_index(sstart + (i + 1) % section_resolution)
			st.add_index(i + nstart)
			st.add_index(nstart + (i + 1) % section_resolution)

var am = ArrayMesh.new()

func _update_mesh():
	var st = SurfaceTool.new()
	_generate(st)
	am.clear_surfaces()
	st.commit(am)

@export_tool_button("Update mesh", "Callable") var update_mesh = _update_mesh

func _update_children_container():
	children_container.transform = Transform3D().translated(Vector3(0, length, 0))
	

func _ready() -> void:
	mesh = am
	if children_container == null:
		children_container = Node3D.new()
		children_container.name = "children_container"
	if children_container.get_parent() != self:
		if children_container.is_inside_tree():
			children_container.reparent(self)
		else:
			add_child(children_container, true)
	_update_children_container()
	_update_mesh()

func update_all():
	_update_children_container()
	_update_mesh()

func add_child_segment(segment: PlantSegment):
	children_container.add_child(segment)

func get_child_segments() -> Array[PlantSegment]:
	var res: Array[PlantSegment] = []

	for c in children_container.get_children():
		if c is PlantSegment:
			res.append(c)

	return res

func get_parent_segment() -> PlantSegment:
	var pp = get_parent().get_parent()
	if pp is PlantSegment:
		return pp
	
	return null
