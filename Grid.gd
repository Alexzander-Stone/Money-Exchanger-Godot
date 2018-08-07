extends TileMap

var tile_size = get_cell_size()
var half_tile_size = tile_size/2

enum ENTITY_TYPES {ONE, FIVE, TEN, FIFTY, HUN, FHUN}
var entity_names = ["One", "Five", "Ten", "Fifty", "Hundred", "Five Hundred"]
var entity_values = [1, 5, 10, 50, 100, 500]
var combo_count = [5, 2, 5, 2, 5, 2]

# Grid contains the entity types, NOT the coordinates. Coordinates are determine through
# the row/col and the use of map_to_world. World_to_map converts world positions to grid/coordinate values.
var grid = []
export (Vector2) var grid_size = Vector2(4, 4)

const DOWN = Vector2(0, 1)
const UP = Vector2(0, -1)
const RIGHT = Vector2(1, 0)
const LEFT = Vector2(-1, 0)

var coin_container = []
var inventory_queue = []
var combo_coin_container = []

onready var Coin = preload("res://Coin.tscn")
onready var Player = preload("res://Player.tscn")

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
		
	# Place the player at the bottom-right corner.
	var new_player = Player.instance()
	var starting_player_position = Vector2(grid_size.x-1, grid_size.y-1)
	new_player.set_position(map_to_world(starting_player_position) + half_tile_size)
	add_child(new_player)

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

# Returns a nearby world position in reference to the passed child's position in the grid.
func directed_nearby_pos(child):
	var gridPos = world_to_map(child.get_position())
	var newGridPos = gridPos + child.direction
	
	var targetPos = map_to_world(newGridPos) + half_tile_size
	return targetPos

# Erase a grid cell's contents.
func remove_from_grid(child):
	var gridPos = world_to_map(child.grid_position)
	grid[gridPos.x][gridPos.y] = null

# Remove a coin from the cell and destroy it. Update any coins below to move up if needed.
func remove_coin(coin):
	var worldPos = coin.grid_position
	remove_from_grid(coin)
	coin.death()
	coin_container.remove(coin_container.find(coin))

# Fills cell position with new type based on the given child object.
# Returns the world coordinates for the new filled cell.
func fill_cell_pos(child, pos):
	var newGridPos = world_to_map(pos)
	var worldPos = pos + half_tile_size
	grid[newGridPos.x][newGridPos.y] = child.type
	return worldPos

# Select and add coins to the coin inventory from cells above the passed position. 
# If it already has coins within, it will grab coins of the same type. 
func select_coins(pos):
	var grab_type = null
	if(inventory_queue.size() > 0):
		grab_type = inventory_queue[0].type
	# Go from the square closest to the player on the bottom to the top.
	for currentY in range(grid_size.y):
		var newPos = world_to_map(pos) + Vector2(0, -currentY)
		# Found the coin to select in the grid. Next, find the coin 
		# in the container and change it to a selected status.
		if grid[newPos.x][newPos.y] != null:
			# Inventory is empty.
			if grab_type == null:
				grab_type = grid[newPos.x][newPos.y]
			# Coin isn't same type as inventory.
			elif grid[newPos.x][newPos.y] != grab_type:
				break
			var coinWorldPos = map_to_world(newPos) + half_tile_size
			for coin in coin_container:
				# Verify that the coin hasn't been selected yet.
				if coin.grid_position == coinWorldPos && !coin.is_selected:
					remove_from_grid(coin)
					coin.move_to_pos(pos, DOWN)
					coin.is_selected = true
					inventory_queue.push_back(coin)

# Release the coins above the passed pos. Empties the inventory when finished. Coin combinations will check during this step.
func deselect_coins(playerPos):
	# Find the the top-most open slot for the initial coin.
	var coinGridPos = world_to_map(playerPos)
	while is_cell_vacant(map_to_world(coinGridPos), UP):
		coinGridPos += UP
	coinGridPos = map_to_world(coinGridPos)
	
	# Spawn the coins stacked on each other below the player.
	var coin_offset = 0
	for coin in inventory_queue:
		var start_pos = world_to_map(playerPos)
		start_pos = map_to_world(Vector2(start_pos.x, grid_size.y+coin_offset)) + half_tile_size
		coin.release_from_inventory(start_pos)
		
		var grid_pos = fill_cell_pos(coin, coinGridPos)
		coin.move_to_pos(grid_pos, UP)
		
		coinGridPos += map_to_world(DOWN)
		coin_offset += 1
	
	# Try to combine the inventory coins with it's new surrounding coins. 
	# If they are combined, move coins below up by 1 vertical coordinate.
	# Can't have multiple calls of combine_coins, need to wait until the previous is entirely finished.
	# To solve this, keep a queue of coins to check for combinations.
	combo_coin_container.append(inventory_queue[inventory_queue.size()-1])
	
	# Empty Inventory
	inventory_queue.clear()

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
				if coin.grid_position.x == coinWorldPos.x && coin.grid_position.y == coinWorldPos.y:
					coin.move_to_pos(map_to_world(Vector2(reverseGridX, gridY)) + half_tile_size, DOWN)
			gridY -= 1
	# Create the new row of coins. Need to add coin as child as required by the _ready func.
	for gridX in range(grid_size.x):
		var coin_type = ENTITY_TYPES.values()[randi() % 6]
		var new_coin = Coin.instance()
		new_coin.change_coin_value(coin_type, entity_values[coin_type], entity_names[coin_type])
		new_coin.set_position(map_to_world(Vector2(gridX, -1)) + half_tile_size)
		add_child(new_coin)
		new_coin.move_to_pos(map_to_world(Vector2(gridX, 0)) + half_tile_size, DOWN)
		grid[gridX][0] = new_coin.type
		coin_container.append(new_coin)

# Return true if movement transition is finished. Uses the grid position as the parameter.
func check_coin_transition_from_grid(gridPos):
	var worldPos = map_to_world(gridPos) + half_tile_size
	for coin in coin_container:
		if coin.grid_position == worldPos:
			return true
	return false

# Return true if movement transition is finished. Uses the world position as the parameter.
func check_coin_transition_from_world(worldPos):
	for coin in coin_container:
		if coin.grid_position == worldPos:
			return true
	return false

# Cycle through the grid checking for coin combos. Doesn't start until player places at least one unit down.
# Coin's aren't valid for consumption until they have reached their grid_position (finished transitioning).
# We will change the check to only check in the new player placed items, instead of the full grid every time.
# Returns true when combo is found, otherwise false.
func combine_coins(worldPos):
	var x = world_to_map(worldPos).x
	var y = world_to_map(worldPos).y
	if grid[x][y] != null && check_coin_transition_from_grid(Vector2(x,y)):
		var coin_positions = []
		recursive_coin_check(Vector2(x, y), coin_positions, grid[x][y])
		# Check to see if length is long enough for completion, then place into the combo container.
		print(coin_positions.size())
		if coin_positions.size() >= combo_count[grid[x][y]]:
			var coin_type = grid[x][y] + 1
			# Remove the former coins. If there are coins below the removed ones, update their position to move up.
			for coinPos in coin_positions:
				var coinWorldPos = map_to_world(coinPos) + half_tile_size
				for coin in coin_container:
					if coin.grid_position == coinWorldPos:
						remove_coin(coin)
						break
			
			# Spawn the new coin at given x, but using the highest available y position.
			# If two or more five hundred were combined, don't spawn new coin.
			if coin_type < ENTITY_TYPES.size():
				var new_coin = Coin.instance()
				new_coin.change_coin_value(coin_type, entity_values[coin_type], entity_names[coin_type])
				# Find the empty spot above the player.
				var coinGridPos = world_to_map(worldPos)
				while is_cell_vacant(map_to_world(coinGridPos), UP):
					coinGridPos += UP
				new_coin.set_position(map_to_world(coinGridPos) + half_tile_size)
				grid[coinGridPos.x][coinGridPos.y] = new_coin.type
				add_child(new_coin)
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
			
			# Combo has succeeded.
			return true
	return false

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
			if coin.grid_position == (map_to_world(Vector2(gridPos.x, y+1)) + half_tile_size):
				var worldPos = map_to_world(Vector2(gridPos.x, y)) + half_tile_size
				remove_from_grid(coin)
				coin.move_to_pos(worldPos, UP)
				fill_cell_pos(coin, worldPos)
		y += 1

func _process(delta):
	if combo_coin_container.size() > 0:
		# Check to see if coin transition has stopped before attempting to combine.
		if check_coin_transition_from_world(combo_coin_container[0].position):
			combine_coins(combo_coin_container.pop_front().grid_position)
	
	# Display grid.
	if Input.is_action_just_pressed("ui_up"):
		debug_grid()
	# Add a new row to the grid.
	if Input.is_action_just_pressed("ui_down"):
		spawn_new_coin_row()

func debug_grid():
	print("-------------------------")
	print(str(grid[0][0]) + " | " + str(grid[1][0]) + " | " + str(grid[2][0]) + " | " + str(grid[3][0]))
	print(str(grid[0][1]) + " | " + str(grid[1][1]) + " | " + str(grid[2][1]) + " | " + str(grid[3][1]))
	print(str(grid[0][2]) + " | " + str(grid[1][2]) + " | " + str(grid[2][2]) + " | " + str(grid[3][2]))
	print(str(grid[0][3]) + " | " + str(grid[1][3]) + " | " + str(grid[2][3]) + " | " + str(grid[3][3]))
	print("-------------------------\n")
	
class VerticalSorter:
	static func descending_sort(a, b):
		if a.y > b.y:
			return true
		return false