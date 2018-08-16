# Money-Exchanger-Godot

Simple 2D clone of the Neo Geo MVS arcade game, Money Idol Exchanger. The project was created to increase my
knowledge of the Godot game engine and common game design principles.

## Controls

## Testing Program
Simple tutorial for testing the game inside the Godot 3.0 engine within the Windows 10 environment.
### Prerequisites
* [Godot V3.05](https://godotengine.org/download/windows) - Godot official download page.
* [Godot Previous Releases](https://downloads.tuxfamily.org/godotengine/) - Godot official previous release list.
### Running
After installation, run the Godot game engine.
When the engine has loaded, click import and lead file path to the project.godot in the project files.
From there, click the play button in the top-corner of the program to play the game.
In case there is an issue with finding the primary scene, direct the project towards the Game.tcsn in the res:// path.
## Relevant Design Principles

Separation of Content and Presentation - 
	The grid is a 2D array used primarily for coin positions within the scene. 
	These cells correspond to the world coordinates in the scene and are used for 
	movement and identification.
	
State Machines - 
	Coin uses the pushdown automaton.
	Player uses a simple FSM.