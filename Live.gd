extends "res://State.gd"

func _ready():
	owner.connect("comboed", self, "on_combo")

func on_combo():
	emit_signal("finished", "death")