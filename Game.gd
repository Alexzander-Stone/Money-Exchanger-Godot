extends Node

onready var Player = preload("res://Player/Player.tscn")

func _ready():
	var grid = find_node("Grid")
	# Place the player at the bottom-right corner.
	var new_player = Player.instance()
	var starting_player_position = Vector2(grid.grid_size.x-1, grid.grid_size.y-1)
	new_player.set_position(grid.map_to_world(starting_player_position) + grid.half_tile_size)
	add_child(new_player)