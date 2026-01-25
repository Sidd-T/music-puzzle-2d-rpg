class_name Gameboard extends TileMapLayer

enum Orientations {NORTH, EAST, SOUTH, WEST}

## Signal emitted when player wants to reset the board
signal reset

# Export Variables
@export var orientation: Orientations:
	set(value):
		orientation = value
		update_configuration_warnings()

var grid_center: Vector2i

func _ready():
	var rect := get_used_rect()
	grid_center = rect.position + rect.size / 2

func rotate_board(steps: int) -> void:
	orientation = ((orientation + steps) % 4) as Orientations

## Function to rotate all tiles around the grid center depending on the gameboard orientation
func to_orientated_tile(tile: Vector2i) -> Vector2i:
	var rel := tile - grid_center

	match orientation:
		Orientations.NORTH:
			return tile

		Orientations.EAST:
			# (x, y) → (-y, x)
			return grid_center + Vector2i(-rel.y, rel.x)

		Orientations.SOUTH:
			# (x, y) → (-x, -y)
			return grid_center + Vector2i(-rel.x, -rel.y)

		Orientations.WEST:
			# (x, y) → (y, -x)
			return grid_center + Vector2i(rel.y, -rel.x)
			
	return tile

func to_orientated_dir(dir: Vector2i) -> Vector2i:
	match orientation:
		Orientations.NORTH: return dir
		Orientations.EAST:  return Vector2i(-dir.y, dir.x)
		Orientations.SOUTH: return -dir
		Orientations.WEST:  return Vector2i(dir.y, -dir.x)
	
	return dir

## Function for reset functionality
func _unhandled_input(event: InputEvent) -> void:	
	
	if event.is_action_pressed("reset"):
		reset.emit()
