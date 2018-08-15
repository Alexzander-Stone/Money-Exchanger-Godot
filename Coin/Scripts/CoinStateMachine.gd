extends "res://State Machine/IStateMachine.gd"

func _ready():
	states_map = {
		"idle": $Idle,
		"move": $Move,
		"death": $Death
	}

func _change_state(state_name):
	# State machine interface
	if not _active:
		return
	# Pushdown automata can be relevant here.
	if state_name == "death":
		states_pushdown_stack.push_front(states_map[state_name])
	
	# Call the interface's method.
	._change_state(state_name)