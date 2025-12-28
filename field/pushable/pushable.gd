## A class that extends [Gamepieces] to allow for pushability
##
## This class has [member is_pushable] which is a bool to indicate
## If this Gamepiece is pushable. The [method can_move] method checks
## for a raycast collision and walkability for the next tile
class_name Pushable extends Gamepiece

@onready var animation_tree = $AnimationTree
@onready var animation_state = animation_tree.get("parameters/playback")

## Whether this Gamepiece can be pushed
var is_pushable: bool

## This function will check the raycast collision and walkability
## of a target tile in the direction given, and update [member is_pushable] [br][br]
## [param direction] Should be [Vector2], this is the direction we are trying to push this Gamepiece
func can_move(direction: Vector2) -> bool:
	
	is_pushable = true
	
	# Check raycast collision
	ray_cast.target_position = direction * TILE_SIZE
	ray_cast.force_raycast_update()
	if ray_cast.is_colliding():
		is_pushable = false
	
	# Check tile walkability
	var target_pushable_tile := tile_map_layer.local_to_map(global_position + ray_cast.target_position)
	var tile_data := tile_map_layer.get_cell_tile_data(target_pushable_tile)
	if tile_data == null or not tile_data.get_custom_data("walkable"):
		is_pushable = false
	
	return is_pushable

func _process(_delta: float) -> void:
	
	animation_tree.set("parameters/Idle/blend_position", dir)
	animation_tree.set("parameters/Walk/blend_position", dir)
	
	if is_moving:
		animation_state.travel("Walk")
	else:
		animation_state.travel("Idle")
