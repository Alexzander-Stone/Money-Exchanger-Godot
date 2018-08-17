extends TileMap

signal coin_removed
signal coin_comboed
signal row_spawned

var tile_size = get_cell_size()
var half_tile_size = tile_size/2

enum ENTITY_TYPES {ONE, FIVE, TEN, FIFTY, HUN, FHUN}
const entity_names = ["One", "Five", "Ten", "Fifty", "Hundred", "Five Hundred"]
const entity_values = [1, 5, 10, 50, 100, 500]

# Grid contains the entity types, NOT the coordinates. Coordinates are determine through
# the row/col and the use of map_to_world. World_to_map converts world positions to grid/coordinate values.
var grid = []
export (Vector2) var grid_size

const DOWN = Vector2(0, 1)
const UP = Vector2(0, -1)
const RIGHT = Vector2(1, 0)
const LEFT = Vector2(-1, 0)

var coin_container = []
var combo_coin_container = []


var remaining_number_of_combo_death = 0

onready var Coin = preload("res://Coin/Coin.tscn")

func _ready():
	for x in range(grid_size.x):
		grid.append([])
		for y in range(grid_size.y):
			grid[x].append(null)
			
	for x in range(grid_size.x):
		for y in range(grid_size.y/2):
			var coin_type = ENTITY_TYPES.values()[randi() % 6]
			var new_coin = spawn_coin(coin_type, map_to_world(Vector2(x,y)) + half_tile_size)

func _process(delta):
	# TESTING
	if Input.is_action_just_pressed("ui_down"):
		spawn_new_coin_row()

# Given a world coordinate position and a direction to move from it, determine if the intended
# cell is within the grid's boundaries.
func does_cell_exist_at_world(worldPos, direction):
	var mapPos = world_to_map(worldPos) + direction
	# Check array bounds.
	if mapPos.x >= 0 && mapPos.x <= grid_size.x-1 && mapPos.y >= 0 && mapPos.y <= grid_size.y-1:
			return true
	return false

# Given a world coordinate position and a direction to move from it, determine if the intended
# cell is empty.
func is_cell_vacant(pos, direction):
	if does_cell_exist_at_world(pos, direction):
		var newPos = world_to_map(pos) + direction
		if grid[newPos.x][newPos.y] == null:
			return true
	return false

# Updates the grid with new location of the child, and returns 
# the world position for it's new cell location.
func update_child_pos(child):
	# Reset former cell and update new grid cell.
	var gridPos = world_to_map(child.get_position())
	grid[gridPos.x][gridPos.y] = null
	var newGridPos = gridPos + child.direction
	grid[newGridPos.x][newGridPos.y] = child.type
	
	var targetPos = map_to_world(newGridPos) + half_tile_size
	return targetPos

# Erase a grid cell's contents.
func remove_from_grid(child):
	var gridPos = world_to_map(child.grid_position)
	grid[gridPos.x][gridPos.y] = null

# Returns a nearby world position in reference to the passed child's position in the grid.
func directed_nearby_pos(child, direction):
	var gridPos = world_to_map(child.get_position())
	var newGridPos = gridPos + direction
	
	var targetPos = map_to_world(newGridPos) + half_tile_size
	return targetPos

# Remove a coin from the cell and destroy it. Update any coins below to move up if needed.
func spawn_coin(coin_type, worldPos):
	var new_coin = Coin.instance()
	new_coin.change_coin_value(coin_type, entity_values[coin_type], entity_names[coin_type])
	new_coin.set_position(worldPos)
	add_child(new_coin)
	# Find the empty spot above the player.
	var coinGridPos = world_to_map(worldPos)
	while is_cell_vacant(map_to_world(coinGridPos), UP):
		coinGridPos += UP
	
	# Give illusion of coin falling up by placing into a starting position, then immediately giving it
	# another free cell above to move towards.
	new_coin.move_to_pos(map_to_world(coinGridPos) + half_tile_size)
	grid[coinGridPos.x][coinGridPos.y] = new_coin.type
	coin_container.append(new_coin)
	return new_coin


# Remove a coin from the cell and destroy it. Update any coins below to move up if needed.
func remove_coin(coin):
	var worldPos = coin.grid_position
	remove_from_grid(coin)
	coin.queue_free()
	coin_container.remove(coin_container.find(coin))
	# Remove from combo container if needed.
	emit_signal("coin_removed", coin)

# Fills cell position with new type based on the given child object.
# Returns the world coordinates for the new filled cell.
func fill_cell_pos(child, pos):
	var newGridPos = world_to_map(pos)
	var worldPos = pos + half_tile_size
	grid[newGridPos.x][newGridPos.y] = child.type
	return worldPos

# Return true if movement transition is finished. Uses the grid position as the parameter.
func is_coin_moving_at_grid(gridPos):
	var worldPos = map_to_world(gridPos) + half_tile_size
	for coin in coin_container:
		if coin.position == worldPos:
			return false
	return true

# Return true if movement transition is finished. Uses the world position as the parameter.
func is_coin_moving_at_world(worldPos):
	for coin in coin_container:
		if coin.position == worldPos:
			return false
	return true

# Given a position, move all cell entries from below it up by 1 vertical position.
# Only needs to move by one per call since when a single coin removal will only impact the grid by one unit.
func grid_chain_cascade(gridPos):
	var y = gridPos.y
	while y < grid_size.y-1:
		# Update the coin with it's new grid position and the cell of it's new element.
		for coin in coin_container:
			if coin.grid_position == (map_to_world(Vector2(gridPos.x, y+1)) + half_tile_size) && !coin.is_selected:
				var worldPos = map_to_world(Vector2(gridPos.x, y)) + half_tile_size
				remove_from_grid(coin)
				coin.move_to_pos(worldPos)
				fill_cell_pos(coin, worldPos)
				check_combo_of(coin)
		y += 1

func check_combo_of(coin):
	emit_signal("coin_comboed", coin)

# Pushes the original coins in the grid down by one cell vertically.
# Then creates new coin objects at the top of the grid. 
func spawn_new_coin_row():
	emit_signal("row_spawned")