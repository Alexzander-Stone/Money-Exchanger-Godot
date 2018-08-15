extends "res://State.gd"

export (int) var time_for_death
var death_timer

# Initialize.
func enter():
	owner.get_node("AnimatedSprite").play("Combo")
	
	death_timer = Timer.new()
	death_timer.set_one_shot(true)
	death_timer.set_wait_time(time_for_death)
	death_timer.connect("timeout", self, "end_death")
	add_child(death_timer)
	death_timer.start()

func end_death():
	owner.is_dead = true