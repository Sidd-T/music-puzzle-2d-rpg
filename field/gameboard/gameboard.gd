class_name Gameboard extends TileMapLayer

enum Orientations {NORTH, EAST, SOUTH, WEST}

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

func rotate_tile(tile: Vector2i) -> Vector2i:
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

func rotate_dir(dir: Vector2i) -> Vector2i:
	match orientation:
		Orientations.NORTH: return dir
		Orientations.EAST:  return Vector2i(-dir.y, dir.x)
		Orientations.SOUTH: return -dir
		Orientations.WEST:  return Vector2i(dir.y, -dir.x)
	
	return dir
