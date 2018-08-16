extends Node2D

var grid
var type
var value

# State Machine, Pushdown automata
signal comboed
signal moved

var current_sprite = "One"
var is_selected = false
var grid_position = Vector2()
var target_direction = Vector2()

var is_dead = false

# Called when added to the scene through add_child from grid.
func _ready():
	grid = get_parent()
	grid_position = position

# Update the value of the coin, and it's appearance.
func change_coin_value(typ, val, sprite):
	type = typ
	value = val
	$AnimatedSprite.animation = sprite
	current_sprite = sprite

func move_to_pos(worldPos):
	grid_position = worldPos
	emit_signal("moved")

func start_death():
	emit_signal("comboed")

func current_state_name():
	return $StateMachine.current_state.name

func release_from_inventory(startingPos):
	show()
	is_selected = false
	position = startingPos

func select():
	is_selected = true