extends "res://State Machine/State.gd"

func handle_input(event):
	if event.is_action_pressed("ui_right") || event.is_action_pressed("ui_left"):
		emit_signal("finished", "move")
	return .handle_input(event)