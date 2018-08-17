extends Node

var grid

const DOWN = Vector2(0, 1)
const UP = Vector2(0, -1)
const RIGHT = Vector2(1, 0)
const LEFT = Vector2(-1, 0)

const combo_count = [5, 2, 5, 2, 5, 2]
var combo_coin_container = []
var combo_coins_to_remove = []
var combo_spawn_location
# Keeps track of the death processes of each coin.
var is_comboing = false

func _ready():
	grid = get_parent()
	# Connect removal coin signal.
	get_parent().connect("coin_removed", self, "remove_combo_for")
	get_parent().connect("coin_comboed", self, "add_combo_for")
	get_parent().connect("row_spawned", self, "on_row_spawn")

func _process(delta):
	# Available combos for consumption and a combo hasn't been initiated.
	if combo_coin_container.size() > 0 && !is_comboing:
		# Find any combo checks that are available for consumption. Coin transition
		# needs to be finished before being called.
		for combo_coin in combo_coin_container:
			if  is_comboing == false && !grid.is_coin_moving_at_world(combo_coin.grid_position):
				var index = combo_coin_container.find(combo_coin)
				is_comboing = combine_coins(combo_coin_container[index].grid_position)
				combo_coin_container.remove(index)
	# Available combos for consumption, but a combo hasn't finished.
	# When the remaining number of coins dieing has reached zero, finish the combo.
	elif is_comboing && has_combo_finished():
		is_comboing = !finish_combo(combo_coins_to_remove)

func remove_combo_for(coin):
	var index_to_remove = combo_coin_container.find(coin)
	if index_to_remove != -1:
		combo_coin_container.remove(index_to_remove)

func add_combo_for(coin):
	if !combo_coin_container.has(coin):
		combo_coin_container.append(coin)

# Cycle through the grid checking for coin combos. Doesn't start until player places at least one unit down.
# Coin's aren't valid for consumption until they have reached their grid_position (finished transitioning).
# We will change the check to only check in the new player placed items, instead of the full grid every time.
# Returns true when combo is found, otherwise false.
func combine_coins(worldPos):
	var x = grid.world_to_map(worldPos).x
	var y = grid.world_to_map(worldPos).y
	
	if grid.grid[x][y] != null && !grid.is_coin_moving_at_grid(Vector2(x,y)):
		var coin_positions = []
		recursive_combo_check(Vector2(x, y), coin_positions, grid.grid[x][y])
		# Check to see if length is long enough for completion, then place into the combo container.
		if coin_positions.size() >= combo_count[grid.grid[x][y]]:
			# Spawn location for potential new coin.
			combo_spawn_location = worldPos
			# Remove the former coins. If there are coins below the removed ones, update their position to move up.
			for coinPos in coin_positions:
				var coinWorldPos = grid.map_to_world(coinPos) + grid.half_tile_size
				for coin in grid.coin_container:
					if coin.grid_position == coinWorldPos:
						coin.start_death()
						combo_coins_to_remove.append(coin)
						grid.grid[coinPos.x][coinPos.y] = -1
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
		coin_positions.append(grid.world_to_map(coin.grid_position))
		coin_type = coin.type + 1
	
	var worldPos = combo_spawn_location
	var gridPos = grid.world_to_map(worldPos)
	
	# Destroy the combo coins.
	for coin in coins:
		grid.remove_coin(coin)
	
	if coin_type < grid.ENTITY_TYPES.size():
		var coin = grid.spawn_coin(coin_type, worldPos)
		add_combo_for(coin)
		
		# Remove the space occupied by the new coin from the cascade.
		var index = coin_positions.find(grid.world_to_map(coin.grid_position))
		if index != -1:
			coin_positions.remove(index)
	
	# Update the grid to move coins up if space is freed above.
	# Sort the inventory by the y coordinate in descending order, then update each coin below.
	coin_positions.sort_custom(VerticalSorter, "descending_sort")
	for coinPos in coin_positions:
		grid.grid_chain_cascade(coinPos)
	
	# Clear the coins to be removed.
	combo_coins_to_remove.clear()
	
	return true

# Verify that the coin transition has finished before adding to the array.
func recursive_combo_check(mapPos, coinArray, type):
	if not coinArray.has(mapPos):
		var current_coin
		for coin in grid.coin_container:
			if coin.grid_position == grid.map_to_world(mapPos) + grid.half_tile_size:
				current_coin = coin
				break
		
		if current_coin.position == current_coin.grid_position:
			coinArray.append(mapPos)
			var worldPos = grid.map_to_world(mapPos)
			# Up
			if(grid.does_cell_exist_at_world(worldPos, UP) && grid.grid[mapPos.x][mapPos.y-1] == type):
				recursive_combo_check(Vector2(mapPos.x, mapPos.y-1), coinArray, type)
			# Right
			if(grid.does_cell_exist_at_world(worldPos, RIGHT) && grid.grid[mapPos.x+1][mapPos.y] == type):
				recursive_combo_check(Vector2(mapPos.x+1, mapPos.y), coinArray, type)
			# Down
			if(grid.does_cell_exist_at_world(worldPos, DOWN) && grid.grid[mapPos.x][mapPos.y+1] == type):
				recursive_combo_check(Vector2(mapPos.x, mapPos.y+1), coinArray, type)
			#Left
			if(grid.does_cell_exist_at_world(worldPos, LEFT) && grid.grid[mapPos.x-1][mapPos.y] == type):
				recursive_combo_check(Vector2(mapPos.x-1, mapPos.y), coinArray, type)

# Returns a boolean that describes the combo death state of the combo coins to remove.
func has_combo_finished():
	for coin in combo_coins_to_remove:
		if coin.is_dead == false:
			return false
	return true

func on_row_spawn():
	if combo_spawn_location != null:
		combo_spawn_location += map_to_world(grid.DOWN)

class VerticalSorter:
	static func descending_sort(a, b):
		if a.y > b.y:
			return true
		return false