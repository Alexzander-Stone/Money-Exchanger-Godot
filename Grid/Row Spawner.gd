extends Node

var grid

func _ready():
	grid = get_parent()
	grid.connect("row_spawned", self, "spawn_row")

# Pushes the original coins in the grid down by one cell vertically.
# Then creates new coin objects at the top of the grid. 
func spawn_row():
	var grid_size = grid.grid_size
	# Push the contents of the grid down one (can change to variable size).
	for gridX in range(grid_size.x):
		# Used to reverse the iteration of x, in descending order.
		var reverseGridX = grid_size.x-1-gridX
		var gridY = grid_size.y-1
		while gridY > 0:
			# Update grid.
			grid.grid[reverseGridX][gridY] = grid.grid[reverseGridX][gridY-1]
			# Update coin objects.
			var coinWorldPos = grid.map_to_world(Vector2(reverseGridX, gridY-1)) + grid.half_tile_size
			for coin in grid.coin_container:
				if coin.grid_position == coinWorldPos:
					coin.move_to_pos(grid.map_to_world(Vector2(reverseGridX, gridY)) + grid.half_tile_size)
			gridY -= 1
	# Create the new row of coins. Need to add coin as child as required by the _ready func.
	for gridX in range(grid_size.x):
		var coin_type = grid.ENTITY_TYPES.values()[randi() % 6]
		var new_coin = grid.Coin.instance()
		new_coin.change_coin_value(coin_type, grid.entity_values[coin_type], grid.entity_names[coin_type])
		new_coin.set_position(grid.map_to_world(Vector2(gridX, -1)) + grid.half_tile_size)
		add_child(new_coin)
		new_coin.move_to_pos(grid.map_to_world(Vector2(gridX, 0)) + grid.half_tile_size)
		grid.grid[gridX][0] = new_coin.type
		grid.coin_container.append(new_coin)
	# Increment the spawn location for combo coins if one is being used currently.