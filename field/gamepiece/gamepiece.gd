@icon("res://assets/editor/icons/Gamepiece.svg")
## A class that can travel in multiple ways while snapped to a grid
##
## A Gamepiece is a generic class for anything that moves while snapped to the grid
## The class does nothing on its own.
## To use, you must extend the [Gamepiece] class from another node
## [br][br]
## Any class that extends [Gamepiece] will be able to follow a path on a [TileMapLayer]
## given that it calls the relevant methods
class_name Gamepiece extends Node2D

# Constants
## Tile Size in pixels
const TILE_SIZE: int = 16

# Signals
## Emitted whenever a path is created and travel begins
signal movement_started
## Emitted whenever the gamepiece has finished travel or has collided
signal movement_ended

# Export Variables
## This is the grid that the gamepiece travels on
@export var gameboard: Gameboard:
	set(value):
		gameboard = value
		update_configuration_warnings()

## This is the sprite, used only in the physics process for movement.
## The actual gamepiece moves instantly, we use the physics process to
## have the sprite 'catch up' to the actual position.
## This is done to optimize because we want to minimize stuff in physics process
@export var sprite: AnimatedSprite2D:
	set(value):
		sprite = value
		update_configuration_warnings()

@export var initial_tile: Vector2i:
	set(value):
		initial_tile = value
		update_configuration_warnings()
		
## Speed to move the sprite between tiles
@export var move_speed: float = 1
## Whether this Gamepiece can be pushed
@export var pushable: bool = false


# Class Variables (Members)
## Used for collision
var ray_cast := RayCast2D.new()
var area := Area2D.new()
var collision_shape := CollisionShape2D.new()
var rectangle_shape := RectangleShape2D.new()
## The grid used for pathfinding. a limiation of [AStarGrid2D] is that the grid is 
## fully connected. That is, all tiles have edges (connections) to all other neighbour tiles.
## so you cannot stop a [Gamepiece] from moving along a specific edge. To do that, you will have to
## refactor using [ASTAR2D] instead and manually create the grid
var astar_grid := AStarGrid2D.new()
## The gamepiece's current tile position
var curr_tile: Vector2i
## The target position of the gamepiece's current travel, in pixels
var target_position: Vector2
## The direction of travel
var dir: Vector2
# boolean statuses
var is_moving: bool
var is_colliding: bool = false
var is_pushing: bool = false
var is_being_pushed: bool = false

func _ready() -> void:
	# To begin, we update the godot editor to show warnings
	update_configuration_warnings()
		
	# Check for export vars, the gamepiece needs these to function, so we can assert them here
	if not Engine.is_editor_hint():
		assert(gameboard, "Gamepiece '%s' must have a TileMapLayer reference to function!" % name)
		assert(sprite, "Gamepiece '%s' must have a AnimatedSprite2D reference to function!" % name)
		assert(initial_tile, "Gamepiece '%s' must have a Vector2i reference to function!" % name)
	
	# Every Gamepiece is added to a group
	add_to_group("gamepieces")
	
	# Setup RayCast2D, we are pointing a ray to an adjacent tile, in this case, the one below
	ray_cast.target_position = Vector2.DOWN * TILE_SIZE
	ray_cast.collide_with_areas = true # Make sure it will collide with areas
	ray_cast.enabled = true 
	add_child(ray_cast)  # Make sure it's part of the scene
	
	# Setup Area2D and CollisionShape2D, these represent the hitbox for collisions
	# First we add the area
	add_child(area) 
	# Then we create a square for the hitbox
	rectangle_shape.size.x = TILE_SIZE
	rectangle_shape.size.y = TILE_SIZE
	# Then we add that square to the collision shape
	collision_shape.shape = rectangle_shape
	# Finally add collision shape as a child of area
	area.add_child(collision_shape)
	
	# Setup grid for pathfinding
	astar_grid.region = gameboard.get_used_rect()
	astar_grid.cell_size = Vector2i(TILE_SIZE, TILE_SIZE)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
	# Setup unwalkable tiles, we are looping through the grid, and checking if
	# the tile on the tile map is walkable or not. walkable is a custom data layer
	# on our tiles
	var region_size := astar_grid.region.size
	var region_pos := astar_grid.region.position
	for x in region_size.x:
		for y in region_size.y:
			var tile_pos = Vector2i(
				x + region_pos.x, 
				y + region_pos.y
			)
			# get the tile at this location and see if its walkable
			var tile_data: TileData = gameboard.get_cell_tile_data(tile_pos)
			if tile_data == null or tile_data.get_custom_data("walkable") == false:
				astar_grid.set_point_solid(tile_pos) # this sets the tile unwalkable
	
	## set the init position based on the gameboards rotation and initial tile
	initial_tile = gameboard.rotate_tile(initial_tile)
	curr_tile = initial_tile
	global_position = gameboard.map_to_local(curr_tile)

func _physics_process(_delta: float) -> void:
	# The only thing we do in this is we update the sprite to move towards the next position
	# This class moves instantly, but we keep the sprite behind on purpose
	# This is so we can optimize by only doing 1 thing in physics process 
	# which is smoothly move the sprite
	
	# If the gamepiece is not moving we dont need to do anything
	if is_moving == false:
		return
	
	# otherwise we can move the sprite
	sprite.global_position = sprite.global_position.move_toward(global_position, move_speed)

## wait for sprite to finish moving
func _wait_for_sprite_arrived() -> void:
	while sprite.global_position != global_position:
		await get_tree().physics_frame

## Function to immediately move a gamepiece to a target tile [br][br]
## [param target_tile] should be [Vector2i]
func _teleport_to_tile(target_tile: Vector2i) -> void:
	var target_pos := gameboard.map_to_local(target_tile)
	global_position = target_pos
	curr_tile = gameboard.local_to_map(global_position)
	is_moving = false
	return

## Travel the [param curr_path]. [br][br]
## This is the core function of [Gamepiece] which will travel along a path of 2d coords.
func _travel_path(curr_path: Array[Vector2i]) -> void:	
	# if the gamepiece's current tile is in the path, we need to pop it
	# This is needed for undo/redo logic where we send in a reverse path
	while !curr_path.is_empty() and curr_path.front() == curr_tile:
		curr_path.pop_front()

	# Check if no path found 
	if curr_path.is_empty():
		# In this case we don't call _end_movement b/c if we're here we didn't move
		is_moving = false 
		return
		
	# overwrite collision and pushing from any previous movement attempt
	is_colliding = false
	is_pushing = false
	
	# Get target position (in pixels)
	target_position = gameboard.map_to_local(curr_path.front())
		
	# Get direction of travel	
	dir = (target_position - global_position).normalized()	
	_direction_updated()
	
	# Set ray cast for collisions and see if we are colliding
	ray_cast.target_position = dir * TILE_SIZE
	_get_collision()

	if !is_colliding or is_pushing:
		# Move the Gamepiece, but not the actual sprite, that's in physics process
		var orig_position := global_position
		global_position = target_position
		sprite.global_position = orig_position
		
		# update path after sprite is finished moving
		await _wait_for_sprite_arrived()
		_took_step()
		curr_path.pop_front()
		
		# if still points in path, recursive call to travel again
		if curr_path.is_empty() == false:
			_travel_path(curr_path)
		else:
			_end_movement()
			return

## Returns a tile in the direction given [br][br]
## [param direction]: should be a [Vector2].
func get_target_tile_from_dir(direction: Vector2) -> Vector2i:
	var target_tile: Vector2i = Vector2i(curr_tile.x + direction.x as int, curr_tile.y + direction.y as int)
	return target_tile

## start movement of [Gamepiece]
func _start_movement() -> void:
	movement_started.emit()
	is_moving = true
	
## end movement of [Gamepiece]
func _end_movement() -> void:
	is_moving = false
	movement_ended.emit()

## Move [Gamepiece] by 1 tile in direction given [br][br]
## [param direction]: should be a [Vector2].
func step(direction: Vector2) -> void:
	# Get the next tile we want to move to
	var target_tile := get_target_tile_from_dir(direction)
	# Check for walkability, in the ready method, those checks are just for the astar grid
	# So, we still need to do this here
	var tile_data := gameboard.get_cell_tile_data(target_tile)
	if tile_data == null or not tile_data.get_custom_data("walkable"):
		return
	
	# If the tile is walkable, now we can start movement,
	# otherwise if we were already moving we'd be stuck
	_start_movement()
	var curr_path: Array[Vector2i]
	curr_path.append(target_tile)
	_travel_path(curr_path)

## Move [Gamepiece] in direction given until blocked or travelled optional given distance
## [br][br][param direction] Should be a [Vector2]
## [br][br][param distance] Should be an [int]
func travel_straight_path(direction: Vector2, distance: int = -1) -> void:
	_start_movement()
	
	# normalize the direction
	var unit_dir: Vector2i = Vector2i(direction.x as int, direction.y as int)
	#var curr_tile: Vector2i = gameboard.local_to_map(global_position)
	var pos := curr_tile
	var steps_taken := 0
	var curr_path: Array[Vector2i]
	
	# This loop will generate the path
	while true:
		pos += unit_dir
		steps_taken += 1

		# Distance limit reached (if distance >= 0)
		if distance >= 0 and steps_taken > distance:
			break

		# Check walkability
		var tile_data := gameboard.get_cell_tile_data(pos)
		if tile_data == null or not tile_data.get_custom_data("walkable"):
			break

		curr_path.append(pos)
	
	_travel_path(curr_path)

## Get whether a target tile is valid to move to
## [br][br][param target_tile] Should be a [Vector2i]
func _is_target_tile_valid(target_tile: Vector2i) -> bool:
	var target_invalid = false
	var tile_data := gameboard.get_cell_tile_data(target_tile)
	if tile_data == null or not tile_data.get_custom_data("walkable")\
	or target_tile == gameboard.local_to_map(global_position):
		target_invalid = true
	
	return target_invalid

## Move [Gamepiece] towards a target tile using A* pathfinding
## [br][br][param target_tile] Should be a [Vector2i]
func travel_astar_path(target_tile: Vector2i) -> void:
	
	if _is_target_tile_valid(target_tile):
		return
	
	# This first part of the code is getting all other gamepieces to mark
	# the tiles that are occupied.
	# Each Gamepiece is in a group called gamepieces
	var gamepieces = get_tree().get_nodes_in_group("gamepieces")
	var occupied_positions: Array[Vector2i] = []
	for gamepiece in gamepieces:
		if gamepiece == self:
			continue
		# add a tile to occupied positions if a gamepiece is on it
		occupied_positions.append(gameboard.local_to_map(gamepiece.global_position))
	
	# set occupied positions as unwalkable tiles in the grid
	for occupied_position: Vector2i in occupied_positions:
		if target_tile == occupied_position:
			continue
		astar_grid.set_point_solid(occupied_position)
	
	# Create the astar path	and remove the starting position with slice
	var path = astar_grid.get_id_path(
		gameboard.local_to_map(global_position),
		target_tile
	)
	
	var curr_path: Array[Vector2i]
	if path.is_empty() == false:
		curr_path = path
	else: 
		return
	
	print(curr_path)
	_start_movement()
	
	# Now that we have the path, we can reset the occupied positions.
	# Any collisions now are handled in _travel_curr_path() 
	for occupied_position: Vector2i in occupied_positions:
		astar_grid.set_point_solid(occupied_position, false)
	
	_travel_path(curr_path)

## Check if the [Gamepiece] is colliding using [member ray_cast][br][br]
## If the raycast is colliding we can call [method _handle_collision].
func _get_collision() -> void:
	ray_cast.force_raycast_update()
	if ray_cast.is_colliding():
		_handle_collision()
	else:
		is_colliding = false

## For a [Gamepiece], this func only sets the status and ends the movement
## This function is meant to be overriden in child classes to do more stuff
func _handle_collision() -> void:
	is_colliding = true
	var collider = ray_cast.get_collider()
	if collider is Area2D:
		# Get the parent of the Area2D to check if it belongs to a Gamepiece
		var collider_gamepiece = collider.get_parent()  # This should be the Gamepiece
		if collider_gamepiece is Gamepiece:
			if collider_gamepiece.can_be_pushed(dir):
				is_pushing = true
				collider_gamepiece.is_being_pushed = true
				collider_gamepiece.step(dir)
				
	if !is_pushing:
		_end_movement()
		
## This function will check the raycast collision and walkability
## of a target tile in the direction given, and returns if we can push this Gamepiece [br][br]
## [param direction] Should be [Vector2], this is the direction we are trying to push this Gamepiece
func can_be_pushed(direction: Vector2) -> bool:
	
	if pushable == false:
		return false
	
	# Check raycast collision
	ray_cast.target_position = direction * TILE_SIZE
	ray_cast.force_raycast_update()
	if ray_cast.is_colliding():
		return false
	
	# Check tile walkability
	var target_pushable_tile := gameboard.local_to_map(global_position + ray_cast.target_position)
	var tile_data := gameboard.get_cell_tile_data(target_pushable_tile)
	if tile_data == null or not tile_data.get_custom_data("walkable"):
		return false
	
	return true

## Used for any child classes to do anything on each step taken
func _took_step() -> void:
	is_being_pushed = false
	curr_tile = gameboard.local_to_map(global_position)

## Used for any child classes to do anything on each direction update
func _direction_updated() -> void:
	pass
	
