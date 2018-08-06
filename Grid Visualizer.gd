extends Node2D

onready var grid = get_parent()

func _ready():
	pass

func _draw():
	var lineColor = Color(255,255,255)
	var lineWidth = 2
	var windowSize = OS.get_real_window_size()
	
	for x in range(grid.grid_size.x + 1):
		var colPos = x * grid.tile_size.x
		var limit = grid.grid_size.y * grid.tile_size.y
		draw_line(Vector2(colPos, 0), Vector2(colPos, limit), lineColor, lineWidth)
	
	for y in range(grid.grid_size.y + 1):
		var rowPos = y * grid.tile_size.y
		var limit = grid.grid_size.x * grid.tile_size.x
		draw_line(Vector2(0, rowPos), Vector2(limit, rowPos), lineColor, lineWidth)
