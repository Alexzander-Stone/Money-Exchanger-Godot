extends AnimationPlayer


func _ready():
	owner.find_node("StateMachine").connect("state_changed", self, "play_animation")

func play_animation(state):
	var s_name = state.name
	play(s_name)