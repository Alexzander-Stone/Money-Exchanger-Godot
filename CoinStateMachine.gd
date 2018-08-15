extends "res://IStateMachine.gd"

func _ready():
	states_map = {
		"idle": $Idle,
		"move": $Move
	}

func _change_state(state_name):
	# State machine interface
	if not _active:
		return
	# Pushdown automata can be relevant here.
	#
	
	# Call the interface's method.
	._change_state(state_name)