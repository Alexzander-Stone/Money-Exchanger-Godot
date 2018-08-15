extends "res://State.gd"

# Initialize.
func enter():
	owner.get_node("AnimatedSprite").play(owner.current_sprite)

func handle_input(event):
	return .handle_input(event)

# Check to see if the coin should be moving.
# If so, change states.
func update(delta):
	if owner.grid_position != owner.position:
		# Finished with current state, go to move state.
		emit_signal("finished", "move")
		# This return may cause issues with coins that are immediately placed in the correct spot.
		return
	
	# Hide coin when reaching bottom of grid while selected.
	# Need to create hidden state.
	if owner.is_selected:
			owner.finalize_inventory()