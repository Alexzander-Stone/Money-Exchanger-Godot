extends Node

var grid

var inventory_queue = []

func _ready():
	grid = get_parent()

# Select and add coins to the coin inventory from cells above the passed position. 
# If it already has coins within, it will grab coins of the same type. 
func select_coins(pos):
	var grab_type = null
	if(inventory_queue.size() > 0): 
		grab_type = inventory_queue[0].type
	# Go from the square closest to the player on the bottom to the top.
	for currentY in range(grid.grid_size.y):
		var newPos = grid.world_to_map(pos) + Vector2(0, -currentY)
		# If coin is comboing, break out of loop.
		if grid.grid[newPos.x][newPos.y] == -1:
			if inventory_queue.size() > 0:
				return true
			else:
				return false
		
		# Found the coin to select in the grid. Next, find the coin 
		# in the container and change it to a selected status.
		if grid.grid[newPos.x][newPos.y] != null:
			var coinWorldPos = grid.map_to_world(newPos) + grid.half_tile_size
			# Coin hasn't finished moving, exit. If there are items already inside the inventory, then return true.
			# Otherwise false.
			for coin in grid.coin_container:
				if coin.grid_position == coinWorldPos && grid.is_coin_moving_at_grid(newPos):
					if inventory_queue.size() > 0:
						return true
					else:
						return false
			
			# Inventory is empty.
			if grab_type == null:
				grab_type = grid.grid[newPos.x][newPos.y]
			
			# Coin isn't same type as inventory.
			elif grid.grid[newPos.x][newPos.y] != grab_type:
				break
			
			for coin in grid.coin_container:
				# Verify that the coin hasn't been selected yet.
				if coin.grid_position == coinWorldPos && !coin.is_selected:
					grid.remove_from_grid(coin)
					# Move to below player.
					coin.move_to_pos(pos + Vector2(0, grid.tile_size.y))
					coin.select()
					inventory_queue.push_back(coin)
	return true

# Release the coins above the passed pos. Empties the inventory when finished. Coin combinations will check during this step.
# Can only release coins if they have reached the bottom of the grid.
func deselect_coins(playerPos):
	if inventory_queue[0].current_state_name() == "Move":
		return false
	# Find the the top-most open slot for the initial coin.
	var coinGridPos = grid.world_to_map(playerPos)
	while grid.is_cell_vacant(grid.map_to_world(coinGridPos), grid.UP):
		coinGridPos += grid.UP
	coinGridPos = grid.map_to_world(coinGridPos)
	
	# Spawn the coins stacked on each other below the player.
	var coin_offset = 0
	for coin in inventory_queue:
		var start_pos = grid.world_to_map(playerPos)
		start_pos = grid.map_to_world(Vector2(start_pos.x, grid.grid_size.y+coin_offset)) + grid.half_tile_size
		coin.release_from_inventory(start_pos)
		
		var grid_pos = grid.fill_cell_at_pos(coin, coinGridPos)
		coin.move_to_pos(grid_pos)
		
		coinGridPos += grid.map_to_world(grid.DOWN)
		coin_offset += 1
	
	# Try to combine the inventory coins with it's new surrounding coins. 
	# If they are combined, move coins below up by 1 vertical coordinate.
	# Can't have multiple calls of combine_coins, need to wait until the previous is entirely finished.
	# To solve this, keep a queue of coins to check for combinations.
	grid.check_combo_of(inventory_queue[inventory_queue.size()-1])
	
	# Empty Inventory
	inventory_queue.clear()
	
	return true