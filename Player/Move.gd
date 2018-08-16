extends "res://State Machine/State.gd"

const MAX_SPEED = 400
const RIGHT = Vector2(1, 0)
const LEFT = Vector2(-1, 0)

var velocity
var target_direction

# Initialize.
func enter():
	# Find the grid position to move towards.
	update_target_direction(owner.position, owner.grid_position)
	print(target_direction)
	if owner.grid.does_cell_exist_at_world(owner.position, target_direction):
		owner.grid_position = owner.grid.directed_nearby_pos(owner, target_direction)
	.enter()

func update(delta):
	var pos = owner.position
	var g_pos = owner.grid_position
	
	if g_pos == pos:
		emit_signal("finished", "idle")
	
	# Move towards the goal
	velocity = MAX_SPEED * target_direction * delta
		
	var distance_to_target = Vector2(abs(g_pos.x - pos.x), abs(g_pos.y - pos.y))
		
	if abs(velocity.x) > distance_to_target.x:
		velocity.x = distance_to_target.x * target_direction.x
	if abs(velocity.y) > distance_to_target.y:
		velocity.y = distance_to_target.y * target_direction.y
		
	owner.position = owner.position + velocity

func update_target_direction(pos, g_pos):
	if Input.is_action_pressed("ui_right"):
		target_direction = RIGHT
	else:
		target_direction = LEFT