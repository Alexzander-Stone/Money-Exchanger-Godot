extends "res://Coin/Scripts/Live.gd"

# Initialize.
func enter():
	owner.get_node("AnimatedSprite").play(owner.current_sprite)
	owner.connect("moved", self, "on_movement")
	.enter()

# Reset values.
func exit():
	owner.disconnect("moved", self, "on_movement")
	.exit()

func handle_input(event):
	return .handle_input(event)

# Check to see if the coin should be moving.
# If so, change states.
func update(delta):
	# Hide coin when reaching bottom of grid while selected.
	# Need to create hidden state.
	if owner.is_selected:
		owner.hide()

func on_movement():
	emit_signal("finished", "move")