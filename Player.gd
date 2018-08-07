extends Node2D


var direction = Vector2()

const MAX_SPEED = 400
const RIGHT = Vector2(1, 0)
const LEFT = Vector2(-1, 0)

var grid

var is_moving = false
var has_selected = false
var grid_position = Vector2()
var target_direction = Vector2()


func _ready():
	grid = get_parent()
	grid_position = position

func _process(delta):
	# Reset direction each loop.
	direction = Vector2()
	
	# Attempt to grab coin from above player character or to push a coin forward.
	# Will always place immediately at the grid_position.			
	if Input.is_action_just_pressed("select_coin"):
		has_selected = grid.select_coins(grid_position)
	if Input.is_action_just_pressed("deselect_coin"):
		if has_selected == true:
			grid.deselect_coins(grid_position) 
			has_selected = false
	
	if Input.is_action_pressed("ui_right"):
		direction = RIGHT
	if Input.is_action_pressed("ui_left"):
		direction = LEFT
			
	# Player has initiated movement.
	if !is_moving && direction != Vector2():
		target_direction = direction
		if grid.does_cell_exist_at_world(position, target_direction):
			grid_position = grid.directed_nearby_pos(self)
			is_moving = true
	# Move towards the goal
	elif is_moving:
		var speed = MAX_SPEED
		var velocity = speed * target_direction * delta
		
		var pos = position
		var distance_to_target = Vector2(abs(grid_position.x - pos.x), abs(grid_position.y - pos.y))
		
		if abs(velocity.x) > distance_to_target.x:
			velocity.x = distance_to_target.x * target_direction.x
			is_moving = false
		if abs(velocity.y) > distance_to_target.y:
			velocity.y = distance_to_target.y * target_direction.y
			is_moving = false
		
		position = position + velocity
