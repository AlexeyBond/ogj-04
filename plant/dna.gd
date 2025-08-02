@tool
extends Resource

class_name DNA

@export var data: PackedByteArray

const ROW_SIZE: int = 8
const N_ROWS: int = 8

func _init() -> void:
	data.resize(N_ROWS * ROW_SIZE)


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
