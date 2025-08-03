@tool
extends Resource

class_name DNA

@export var data: PackedByteArray

const ROW_SIZE: int = 8
const N_ROWS: int = 8

func _init() -> void:
	data.resize(N_ROWS * ROW_SIZE)

func write(row: int, col: int, val: int):
	assert(col >= 0)
	assert(col < ROW_SIZE)
	assert(val >= 0)
	assert(val < 256)
	data[col + (row % N_ROWS) * ROW_SIZE] = val

func read(row: int, col: int) -> int:
	assert(col >= 0)
	assert(col < ROW_SIZE)
	return data[col + (row % N_ROWS) * ROW_SIZE]

func read_4b(row: int, col: int, off: int) -> int:
	assert(off >= 0)
	assert(off <= 1)
	return (read(row, col) >> (off * 4)) & 0x0F

func read_2b(row: int, col: int, off: int) -> int:
	assert(off >= 0)
	assert(off <= 3)
	return (read(row, col) >> (off * 2)) & 0x3

func clear():
	data.clear()
	data.resize(N_ROWS * ROW_SIZE)

func randomize():
	clear()
	for i in N_ROWS * ROW_SIZE:
		data[i] = randi() & 255

@export_tool_button("Clear")
var clear_btn = clear

@export_tool_button("Randomize")
var randomize_btn = randomize

func mutate_1():
	data[randi() % data.size()] ^= (1 << (randi() % 8))

func mutate(n: int):
	for i in n:
		mutate_1()

func _mix_by_rows(other: DNA) -> DNA:
	var res := DNA.new()
	for row in N_ROWS:
		var source = self
		if randf() < 0.5:
			source = other
		for col in ROW_SIZE:
			res.write(row, col, source.read(row, col))
	return res

func _mix_by_cells(other: DNA) -> DNA:
	var res := DNA.new()
	for row in N_ROWS:
		for col in ROW_SIZE:
			var source = self
			if randf() < 0.5:
				source = other
			res.write(row, col, source.read(row, col))
	return res

func mix(other: DNA) -> DNA:
	var r := randf()
	if r > 0.3:
		return _mix_by_rows(other)
	return _mix_by_cells(other)
