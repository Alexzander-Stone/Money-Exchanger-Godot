extends Node2D


var direction = Vector2()

var grid

var is_moving = false
var has_selected = false
var grid_position = Vector2()
var target_direction = Vector2()


func _ready():
	grid = get_parent()
	grid_position = position

func debug():
	print("player has selected is " + str(has_selected))