extends Node2D


var direction = Vector2()

var grid

var grid_position = Vector2()
var target_direction = Vector2()

var has_selected = false

func _ready():
	grid = get_parent()
	grid_position = position