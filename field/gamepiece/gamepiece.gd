@icon("res://assets/editor/icons/Gamepiece.svg")
class_name Gamepiece extends Node2D

const TILE_SIZE: int = 16

signal movement_started
signal movement_ended

@export var tile_map_layer: TileMapLayer:
	set(value):
		tile_map_layer = value
		update_configuration_warnings()

@export var sprite: AnimatedSprite2D:
	set(value):
		sprite = value
		update_configuration_warnings()
		
## time between steps in seconds
@export var move_time: float = 0.5:
	set(value):
		move_time = value

@export var ray_cast: RayCast2D:
	set(value):
		ray_cast = value

var astar_grid: AStarGrid2D = AStarGrid2D.new()
var curr_path: Array[Vector2i]
var target_position: Vector2
var is_moving: bool
var is_colliding: bool = false
var dir: Vector2

func _ready() -> void:
	update_configuration_warnings()
		
	## Check for tilemap
	if not Engine.is_editor_hint():
		assert(tile_map_layer, "Gamepiece '%s' must have a TileMapLayer reference to function!" % name)
		assert(sprite, "Gamepiece '%s' must have a AnimatedSprite2D reference to function!" % name)
		assert(ray_cast, "Gamepiece '%s' must have a RayCast2D reference to function!" % name)
	
	## Setup grid
	astar_grid.region = tile_map_layer.get_used_rect()
	astar_grid.cell_size = Vector2i(TILE_SIZE, TILE_SIZE)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
	## Setup unwalkable tiles
	var region_size := astar_grid.region.size
	var region_pos := astar_grid.region.position
	for x in region_size.x:
		for y in region_size.y:
			var tile_pos = Vector2i(
				x + region_pos.x, 
				y + region_pos.y
			)
			var tile_data: TileData = tile_map_layer.get_cell_tile_data(tile_pos)
			if tile_data == null or tile_data.get_custom_data("walkable") == false:
				astar_grid.set_point_solid(tile_pos)
				
			

func _physics_process(_delta: float) -> void:
	if is_moving == false:
		return
	
	if global_position == sprite.global_position:
		is_moving = false
		return
	
	sprite.global_position = sprite.global_position.move_toward(global_position, 1)
	

## wait for sprite to finish moving
func _wait_for_sprite_arrived() -> void:
	while sprite.global_position != global_position:
		await get_tree().physics_frame

func _travel_curr_path() -> void:	
	
	if curr_path.is_empty():
		return	
	
	### Get target pos and start moving if not already
	#if is_moving == false:
	target_position = tile_map_layer.map_to_local(curr_path.front())
		
	## Get direction of travel	
	dir = (target_position - global_position).normalized()	
	
	## Get ray cast for collisions
	ray_cast.target_position = dir * TILE_SIZE
	_get_collision()
		
	if !is_colliding:
		## Move, still not animation, that should be in physics process
		var orig_position := global_position
		global_position = target_position
		sprite.global_position = orig_position
		
		## update path after sprite is finished moving
		await _wait_for_sprite_arrived()
		curr_path.pop_front()
		
		## if still points in path, target position is front of path
		if curr_path.is_empty() == false:
			target_position = tile_map_layer.map_to_local(curr_path.front())
			_travel_curr_path()
		else:
			emit_signal("movement_ended")
			is_moving = false

func get_target_tile_from_dir(direction: Vector2) -> Vector2i:
	var curr_tile: Vector2i = tile_map_layer.local_to_map(global_position)
	var target_tile: Vector2i = Vector2i(curr_tile.x + direction.x as int, curr_tile.y + direction.y as int)
	return target_tile

func _start_movement() -> void:
	emit_signal("movement_started")
	curr_path.clear()
	is_moving = true

func step(direction: Vector2) -> void:
	_start_movement()
	
	var target_tile := get_target_tile_from_dir(direction)
	var tile_data := tile_map_layer.get_cell_tile_data(target_tile)
	if tile_data == null or not tile_data.get_custom_data("walkable"):
		return
	curr_path.append(target_tile)
	_travel_curr_path()

func travel_straight_path(direction: Vector2, distance: int = -1) -> void:
	_start_movement()
	
	var unit_dir: Vector2i = Vector2i(direction.x as int, direction.y as int)
	var curr_tile: Vector2i = tile_map_layer.local_to_map(global_position)
	var pos := curr_tile
	var steps_taken := 0

	while true:
		pos += unit_dir
		steps_taken += 1

		# Distance limit reached (if distance >= 0)
		if distance >= 0 and steps_taken > distance:
			break

		# Check walkability
		var tile_data := tile_map_layer.get_cell_tile_data(pos)
		if tile_data == null or not tile_data.get_custom_data("walkable"):
			break

		curr_path.append(pos)
	
	_travel_curr_path()

func travel_astar_path(target_tile: Vector2i) -> void:
	_start_movement()
	
	var gamepieces = get_tree().get_nodes_in_group("gamepieces")
	var occupied_positions: Array[Vector2i] = []
	
	for gamepiece in gamepieces:
		if gamepiece == self:
			continue
		
		occupied_positions.append(tile_map_layer.local_to_map(gamepiece.global_position))
		
	for occupied_position: Vector2i in occupied_positions:
		astar_grid.set_point_solid(occupied_position)
		
	var path
	
	path = astar_grid.get_id_path(
		tile_map_layer.local_to_map(global_position),
		target_tile
	).slice(1)
	
	if path.is_empty() == false:
		curr_path = path
	
	for occupied_position: Vector2i in occupied_positions:
		astar_grid.set_point_solid(occupied_position, false)
	
	_travel_curr_path()

func _get_collision() -> void:
	ray_cast.force_raycast_update()
	if ray_cast.is_colliding():
		_handle_collision()
	else:
		is_colliding = false

func _handle_collision() -> void:
	is_colliding = true
	## can do more stuff in children, make sure to call super for overrides
