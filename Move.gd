extends "res://State.gd"

const MAX_SPEED = 2000
const DOWN = Vector2(0, 1)
const UP = Vector2(0, -1)

# Initialize.
func enter():
	owner.get_node("AnimatedSprite").play("Combo")

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
	
	# Coin is moving upwards.
	if pos.y - g_pos.y >= 0:
		owner.target_direction = UP
	# Coin is moving downwards.
	else:
		owner.target_direction = DOWN
	
	owner.velocity = MAX_SPEED * owner.target_direction * delta
	
	var distance_to_target = Vector2(abs(g_pos.x - pos.x), abs(g_pos.y - pos.y))
	
	if abs(owner.velocity.x) > distance_to_target.x:
		owner.velocity.x = distance_to_target.x * owner.target_direction.x
		owner.is_moving = false
	if abs(owner.velocity.y) > distance_to_target.y:
		owner.velocity.y = distance_to_target.y * owner.target_direction.y
		owner.is_moving = false
	owner.position += owner.velocity
	
	# Hide coin when reaching bottom of grid while selected.
	# Need to create hidden state.
	if owner.is_selected && !owner.is_moving:
			owner.finalize_inventory()