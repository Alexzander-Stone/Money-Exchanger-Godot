extends Node2D

var direction = Vector2()
var velocity

const MAX_SPEED = 400
const DOWN = Vector2(0, 1)
const UP = Vector2(0, -1)

var type
var value

var is_moving = false
var is_selected = false
var grid_position = Vector2()
var target_direction = Vector2()

# Called when added to the scene through add_child from grid.
func _ready():
	grid_position = position

func _process(delta):	
	# Move towards the grid_position. It has already been verified, 
	# so no need to check for correctness in grid.
	if is_moving:
		velocity = MAX_SPEED * target_direction * delta
		var pos = position
		var distance_to_target = Vector2(abs(grid_position.x - pos.x), abs(grid_position.y - pos.y))
		
		if abs(velocity.x) > distance_to_target.x:
			velocity.x = distance_to_target.x * target_direction.x
			is_moving = false
		if abs(velocity.y) > distance_to_target.y:
			velocity.y = distance_to_target.y * target_direction.y
			is_moving = false
		position += velocity
		
	# Hide coin when reaching bottom of grid while selected.
	if is_selected && !is_moving:
			finalize_inventory()

# Need to hide coin and remove from grid when reaching bottom. 
func finalize_inventory():
	hide()

func release_from_inventory(startingPos):
	show()
	is_selected = false
	position = startingPos
	target_direction = UP

func move_to_pos(worldPos, dir):
	grid_position = worldPos
	target_direction = dir
	is_moving = true
	
# Update the value of the coin, and it's appearance.
func change_coin_value(typ, val, sprite):
	type = typ
	value = val
	$AnimatedSprite.animation = sprite
	
func death():
	queue_free()