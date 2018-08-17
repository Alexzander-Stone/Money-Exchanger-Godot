extends Node2D


var direction = Vector2()

var grid_interaction
var grid

var grid_position = Vector2()
var target_direction = Vector2()

var has_selected = false

func _ready():
	grid = get_parent().find_node("Grid")
	grid_interaction = grid.find_node("Coin Interaction")
	grid_position = position