extends "res://State.gd"

const MAX_SPEED = 2000
const DOWN = Vector2(0, 1)
const UP = Vector2(0, -1)

var velocity
var target_direction = DOWN

# Initialize.
func enter():
	owner.get_node("AnimatedSprite").play("Combo")
	update_target_direction(owner.position, owner.grid_position)

func handle_input(event):
	return .handle_input(event)

# Check to see if the coin should be moving.
# If so, change states.
func update(delta):
	var pos = owner.position
	var g_pos = owner.grid_position
	
	if g_pos == pos:
		# Finished with current state, go to move state.
		emit_signal("finished", "idle")
	
	update_target_direction(pos, g_pos)
	
	velocity = MAX_SPEED * target_direction * delta
	
	var distance_to_target = Vector2(abs(g_pos.x - pos.x), abs(g_pos.y - pos.y))
	
	if abs(velocity.x) > distance_to_target.x:
		velocity.x = distance_to_target.x * target_direction.x
	if abs(velocity.y) > distance_to_target.y:
		velocity.y = distance_to_target.y * target_direction.y
	owner.position += velocity

func update_target_direction(pos, g_pos):
	if pos > g_pos:
		target_direction = UP
	else:
		target_direction = DOWN