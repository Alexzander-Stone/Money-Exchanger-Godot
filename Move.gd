extends "res://State.gd"

# Initialize.
func enter():
	owner.get_node("AnimatedSprite").play("Combo")

func handle_input(event):
	return .handle_input(event)

# Check to see if the coin should be moving.
# If so, change states.
func update(delta):
	if owner.grid_position == owner.position:
		# Finished with current state, go to move state.
		emit_signal("finished", "idle")