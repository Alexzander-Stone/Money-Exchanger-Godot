# Money-Exchanger-Godot

Simple 2D clone of the Neo Geo MVS arcade game, Money Idol Exchanger. The project was created to increase my
knowledge of the Godot game engine and common game design principles.

# Relevant Design Principles

Separation of Content and Presentation - 
	The grid is a 2D array used primarily for coin positions within the scene. 
	These cells correspond to the world coordinates in the scene and are used for 
	movement and identification.
	
State Machines - 
	Coin uses the pushdown automata.
	Player uses a simple FSM.