@icon("res://assets/editor/icons/Gamepiece.svg")
class_name Gamepiece extends Node2D

const TILE_SIZE: int = 16

@export var tile_map_layer: TileMapLayer:
	set(value):
		tile_map_layer = value
		update_configuration_warnings()

@export var sprite: AnimatedSprite2D:
	set(value):
		sprite = value
		update_configuration_warnings()
		
@export var move_time: float = 1:
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
	var region_size = astar_grid.region.size
	var region_pos = astar_grid.region.position
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
	
	sprite.global_position = sprite.global_position.move_toward(global_position, move_time)

func travel_curr_path() -> void:	
	if curr_path.is_empty():
		return	
	
	## Get target pos and start moving if not already
	if is_moving == false:
		target_position = tile_map_layer.map_to_local(curr_path.front())
		is_moving = true
		
	## Get direction of travel	
	dir = (target_position - global_position).normalized()	
	
	## Get ray cast for collisions
	ray_cast.target_position = dir * TILE_SIZE
	get_collision()
		
	if !is_colliding:
		## Move, still not animation, that should be in physics process
		var orig_position = global_position
		global_position = target_position
		sprite.global_position = orig_position
		
		## update path if target reached by sprite
		if sprite.global_position == global_position:
			curr_path.pop_front()
		
		## if still points in path, target position is front of path
		if curr_path.is_empty() == false:
			target_position = tile_map_layer.map_to_local(curr_path.front())
		else:
			is_moving = false

func get_target_tile_from_dir(direction: Vector2) -> Vector2i:
	var curr_tile: Vector2i = tile_map_layer.local_to_map(global_position)
	var target_tile: Vector2i = Vector2i(curr_tile.x + direction.x as int, curr_tile.y + direction.y as int)
	return target_tile

func step(direction: Vector2) -> void:
	curr_path.clear()
	curr_path.append(get_target_tile_from_dir(direction))
	travel_curr_path()

func get_straight_path(direction: Vector2) -> void:
	curr_path.clear()
	var curr_tile: Vector2i = tile_map_layer.local_to_map(global_position)
	var target_tile: Vector2i = Vector2i(curr_tile.x + direction.x as int, curr_tile.y + direction.y as int)
	
	var tile_data: TileData = tile_map_layer.get_cell_tile_data(target_tile)
	if tile_data == null or tile_data.get_custom_data("walkable") == false:
		return
	
	## TODO get the 


func get_astar_path(target_tile: Vector2i) -> void:
	curr_path.clear()
	
	var gamepieces = get_tree().get_nodes_in_group("gamepieces")
	var occupied_positions: Array[Vector2i] = []
	
	for gamepiece in gamepieces:
		if gamepiece == self:
			continue
		
		occupied_positions.append(tile_map_layer.local_to_map(gamepiece.global_position))
		
	for occupied_position: Vector2i in occupied_positions:
		astar_grid.set_point_solid(occupied_position)
		
	var path
	
	if is_moving:
		path = astar_grid.get_id_path(
			tile_map_layer.local_to_map(target_position),
			target_tile
	)
	else:
		path = astar_grid.get_id_path(
			tile_map_layer.local_to_map(global_position),
			target_tile
		).slice(1)
	
	if path.is_empty() == false:
		curr_path = path
	
	for occupied_position: Vector2i in occupied_positions:
		astar_grid.set_point_solid(occupied_position, false)

func get_collision() -> void:
	ray_cast.force_raycast_update()
	if ray_cast.is_colliding():
		handle_collision()
	else:
		is_colliding = false

func handle_collision() -> void:
	is_colliding = true
	## can do more stuff in children, make sure to call super for overrides
