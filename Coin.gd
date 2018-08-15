extends Node2D

var grid
var type
var value

# State Machine, Pushdown automata
var current_sprite = "One"
var is_selected = false
var grid_position = Vector2()
var target_direction = Vector2()

var is_dead = false
export (int) var time_for_death
var death_timer

# Called when added to the scene through add_child from grid.
func _ready():
	grid = get_parent()
	grid_position = position
	
	death_timer = Timer.new()
	death_timer.set_one_shot(true)
	death_timer.set_wait_time(time_for_death)
	death_timer.connect("timeout", self, "end_death")
	add_child(death_timer)

func _process(delta):
	pass

# Need to hide coin and remove from grid when reaching bottom. 
func finalize_inventory():
	hide()

func release_from_inventory(startingPos):
	show()
	is_selected = false
	position = startingPos

func move_to_pos(worldPos, dir):
	grid_position = worldPos
	
# Update the value of the coin, and it's appearance.
func change_coin_value(typ, val, sprite):
	type = typ
	value = val
	$AnimatedSprite.animation = sprite
	current_sprite = sprite

# WorldPos is the location of the spawner coin, this coin will determine when all the coins are removed.
func start_death(worldPos):
	$AnimatedSprite.animation = "Combo"
	death_timer.start()

func end_death():
	# Inform grid that coin is ready for death.
	is_dead = true

func current_state_name():
	return $StateMachine.current_state.name