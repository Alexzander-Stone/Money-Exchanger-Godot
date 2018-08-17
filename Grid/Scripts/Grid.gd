extends TileMap

var tile_size = get_cell_size()
var half_tile_size = tile_size/2

enum ENTITY_TYPES {ONE, FIVE, TEN, FIFTY, HUN, FHUN}
const entity_names = ["One", "Five", "Ten", "Fifty", "Hundred", "Five Hundred"]
const entity_values = [1, 5, 10, 50, 100, 500]
const combo_count = [5, 2, 5, 2, 5, 2]

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
var combo_spawn_location
# Keeps track of the death processes of each coin.
var is_comboing = false
var remaining_number_of_combo_death = 0
var combo_coins_to_remove = []

onready var Coin = preload("res://Coin/Coin.tscn")

func _ready():
	for x in range(grid_size.x):
		grid.append([])
		for y in range(grid_size.y):
			grid[x].append(null)
			
	for x in range(grid_size.x):
		for y in range(grid_size.y/2):
			var coin_type = ENTITY_TYPES.values()[randi() % 6]
			var new_coin = Coin.instance()
			new_coin.change_coin_value(coin_type, entity_values[coin_type], entity_names[coin_type])
			new_coin.set_position(map_to_world(Vector2(x,y)) + half_tile_size)
			grid[x][y] = new_coin.type
			add_child(new_coin)
			coin_container.append(new_coin)

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
func remove_coin(coin):
	var worldPos = coin.grid_position
	remove_from_grid(coin)
	coin.queue_free()
	coin_container.remove(coin_container.find(coin))
	var index_to_remove = combo_coin_container.find(coin)
	if index_to_remove != -1:
		combo_coin_container.remove(index_to_remove)

# Fills cell position with new type based on the given child object.
# Returns the world coordinates for the new filled cell.
func fill_cell_pos(child, pos):
	var newGridPos = world_to_map(pos)
	var worldPos = pos + half_tile_size
	grid[newGridPos.x][newGridPos.y] = child.type
	return worldPos

# Pushes the original coins in the grid down by one cell vertically.
# Then creates new coin objects at the top of the grid. 
func spawn_new_coin_row():
	# Push the contents of the grid down one (can change to variable size).
	for gridX in range(grid_size.x):
		# Used to reverse the iteration of x, in descending order.
		var reverseGridX = grid_size.x-1-gridX
		var gridY = grid_size.y-1
		while gridY > 0:
			# Update grid.
			grid[reverseGridX][gridY] = grid[reverseGridX][gridY-1]
			# Update coin objects.
			var coinWorldPos = map_to_world(Vector2(reverseGridX, gridY-1)) + half_tile_size
			for coin in coin_container:
				if coin.grid_position == coinWorldPos:
					coin.move_to_pos(map_to_world(Vector2(reverseGridX, gridY)) + half_tile_size)
			gridY -= 1
	# Create the new row of coins. Need to add coin as child as required by the _ready func.
	for gridX in range(grid_size.x):
		var coin_type = ENTITY_TYPES.values()[randi() % 6]
		var new_coin = Coin.instance()
		new_coin.change_coin_value(coin_type, entity_values[coin_type], entity_names[coin_type])
		new_coin.set_position(map_to_world(Vector2(gridX, -1)) + half_tile_size)
		add_child(new_coin)
		new_coin.move_to_pos(map_to_world(Vector2(gridX, 0)) + half_tile_size)
		grid[gridX][0] = new_coin.type
		coin_container.append(new_coin)
	# Increment the spawn location for combo coins if one is being used currently.
	if combo_spawn_location != null:
		combo_spawn_location += map_to_world(DOWN)

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

# Cycle through the grid checking for coin combos. Doesn't start until player places at least one unit down.
# Coin's aren't valid for consumption until they have reached their grid_position (finished transitioning).
# We will change the check to only check in the new player placed items, instead of the full grid every time.
# Returns true when combo is found, otherwise false.
func combine_coins(worldPos):
	var x = world_to_map(worldPos).x
	var y = world_to_map(worldPos).y
	
	if grid[x][y] != null && !is_coin_moving_at_grid(Vector2(x,y)):
		var coin_positions = []
		recursive_coin_check(Vector2(x, y), coin_positions, grid[x][y])
		# Check to see if length is long enough for completion, then place into the combo container.
		if coin_positions.size() >= combo_count[grid[x][y]]:
			# Spawn location for potential new coin.
			combo_spawn_location = worldPos
			# Remove the former coins. If there are coins below the removed ones, update their position to move up.
			for coinPos in coin_positions:
				var coinWorldPos = map_to_world(coinPos) + half_tile_size
				for coin in coin_container:
					if coin.grid_position == coinWorldPos:
						coin.start_death()
						combo_coins_to_remove.append(coin)
						grid[coinPos.x][coinPos.y] = -1
						break
			# Combo has succeeded.
			return true
	return false

# Creates the combo coin and cascades lower coins. Called during second half of combo phase, 
# after initial coins have played out their death animation.
func finish_combo(coins):
	# Spawn the new coin at given x, but using the highest available y position.
	# If two or more five hundred were combined, don't spawn new coin.
	var coin_positions = []
	var coin_type
	for coin in coins:
		coin_positions.append(world_to_map(coin.grid_position))
		coin_type = coin.type + 1
	
	var worldPos = combo_spawn_location
	var gridPos = world_to_map(worldPos)
	
	# Destroy the combo coins.
	for coin in coins:
		remove_coin(coin)
	
	if coin_type < ENTITY_TYPES.size():
		var new_coin = Coin.instance()
		new_coin.change_coin_value(coin_type, entity_values[coin_type], entity_names[coin_type])
		new_coin.set_position(worldPos)
		add_child(new_coin)
		# Find the empty spot above the player.
		var coinGridPos = world_to_map(worldPos)
		while is_cell_vacant(map_to_world(coinGridPos), UP):
			coinGridPos += UP
		new_coin.move_to_pos(map_to_world(coinGridPos) + half_tile_size)
		grid[coinGridPos.x][coinGridPos.y] = new_coin.type
		coin_container.append(new_coin)
		# Check new coin for potential combos.
		combo_coin_container.append(new_coin)
		
		# Remove the space occupied by the new coin from the cascade.
		coin_positions.remove(coin_positions.find(coinGridPos))
	
	# Update the grid to move coins up if space is freed above.
	# Sort the inventory by the y coordinate in descending order, then update each coin below.
	coin_positions.sort_custom(VerticalSorter, "descending_sort")
	for coinPos in coin_positions:
		grid_chain_cascade(coinPos)
	
	# Clear the coins to be removed.
	combo_coins_to_remove.clear()
	
	return true

# Verify that the coin transition has finished before adding to the array.
func recursive_coin_check(mapPos, coinArray, type):
	if not coinArray.has(mapPos):
		var current_coin
		for coin in coin_container:
			if coin.grid_position == map_to_world(mapPos) + half_tile_size:
				current_coin = coin
				break
		
		if current_coin.position == current_coin.grid_position:
			coinArray.append(mapPos)
			var worldPos = map_to_world(mapPos)
			# Up
			if(does_cell_exist_at_world(worldPos, UP) && grid[mapPos.x][mapPos.y-1] == type):
				recursive_coin_check(Vector2(mapPos.x, mapPos.y-1), coinArray, type)
			# Right
			if(does_cell_exist_at_world(worldPos, RIGHT) && grid[mapPos.x+1][mapPos.y] == type):
				recursive_coin_check(Vector2(mapPos.x+1, mapPos.y), coinArray, type)
			# Down
			if(does_cell_exist_at_world(worldPos, DOWN) && grid[mapPos.x][mapPos.y+1] == type):
				recursive_coin_check(Vector2(mapPos.x, mapPos.y+1), coinArray, type)
			#Left
			if(does_cell_exist_at_world(worldPos, LEFT) && grid[mapPos.x-1][mapPos.y] == type):
				recursive_coin_check(Vector2(mapPos.x-1, mapPos.y), coinArray, type)

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
				if combo_coin_container.find(coin) == -1:
					combo_coin_container.append(coin)
		y += 1

func _process(delta):
	# Available combos for consumption and a combo hasn't been initiated.
	if combo_coin_container.size() > 0 && !is_comboing:
		# Find any combo checks that are available for consumption. Coin transition
		# needs to be finished before being called.
		for combo_coin in combo_coin_container:
			if !is_coin_moving_at_world(combo_coin.grid_position):
				var index = combo_coin_container.find(combo_coin)
				is_comboing = combine_coins(combo_coin_container[index].grid_position)
				combo_coin_container.remove(index)
				break
	# Available combos for consumption, but a combo hasn't finished.
	# When the remaining number of coins dieing has reached zero, finish the combo.
	elif is_comboing && has_combo_finished():
		is_comboing = !finish_combo(combo_coins_to_remove)
	
	# Display grid.
	if Input.is_action_just_pressed("ui_up"):
		debug()
	# Add a new row to the grid.
	if Input.is_action_just_pressed("ui_down"):
		spawn_new_coin_row()

# Returns a boolean that describes the combo death state of the combo coins to remove.
func has_combo_finished():
	for coin in combo_coins_to_remove:
		if coin.is_dead == false:
			return false
	return true

func debug():
	#print("-------------------------")
	#print(str(grid[0][0]) + " | " + str(grid[1][0]) + " | " + str(grid[2][0]) + " | " + str(grid[3][0]))
	#print(str(grid[0][1]) + " | " + str(grid[1][1]) + " | " + str(grid[2][1]) + " | " + str(grid[3][1]))
	#print(str(grid[0][2]) + " | " + str(grid[1][2]) + " | " + str(grid[2][2]) + " | " + str(grid[3][2]))
	#print(str(grid[0][3]) + " | " + str(grid[1][3]) + " | " + str(grid[2][3]) + " | " + str(grid[3][3]))
	#print("-------------------------\n")
	#print(inventory_queue.size())
	#print(inventory_queue[0].position)
	#print(inventory_queue[0].is_selected)
	pass
	
class VerticalSorter:
	static func descending_sort(a, b):
		if a.y > b.y:
			return true
		return false