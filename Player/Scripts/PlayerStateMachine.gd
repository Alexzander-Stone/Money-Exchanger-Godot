extends "res://State Machine/IStateMachine.gd"

func _ready():
	states_map = {
		"idle": $Idle,
		"move": $Move
	}