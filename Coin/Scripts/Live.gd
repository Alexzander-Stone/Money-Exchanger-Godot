extends "res://State Machine/State.gd"

func enter():
	owner.connect("comboed", self, "on_combo")
	.enter()

# Reset values.
func exit():
	owner.disconnect("comboed", self, "on_combo")
	.exit()

func on_combo():
	emit_signal("finished", "death")