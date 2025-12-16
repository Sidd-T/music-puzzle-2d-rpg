@icon("res://assets/editor/icons/Gamepiece.svg")
## A class that represents any generic non-player character
##
## A class that extends [Gamepiece] to provide extra functionality for
## non-player characters.
## The class is still not enough on its own,
## to use, you must extend the [Monster] class from another node
## [br][br]
## Any class that extends [Monster] will be able be a [Gamepiece], but also have
## additional functionality
class_name Monster extends Gamepiece

## This is the reference to the player
@export var player: Player:
	set(value):
		player = value
		update_configuration_warnings()

## Whether this monster in inside the range of the player
var in_player_range: bool;

func _ready() -> void:
	# Make we call the ready for the Gamepiece
	super()
	
	# To begin, we update the godot editor to show warnings
	update_configuration_warnings()
		
	# Check for export vars, the monster needs these to function, so we can assert them here
	if not Engine.is_editor_hint():
		assert(player, "Monster '%s' must have a Player reference to function!" % name)
	
	# Check if in player range, and update [member in_player_range] and group
	in_player_range = _is_in_player_range()
	if in_player_range:
		add_to_group("in_player_range")
	else:
		remove_from_group("in_player_range")

## Overrides [method _took_step] in [Gamepiece]. Checks if this monster in in the
## Player range and updates [member in_player_range] and adds/remove to a group
func _took_step() -> void:
	in_player_range = _is_in_player_range()
	if in_player_range:
		add_to_group("in_player_range")
	else:
		remove_from_group("in_player_range")

## Function to check if this monster is in the song range of the Player
func _is_in_player_range() -> bool:
	# Get positions
	var curr_tile := tile_map_layer.local_to_map(global_position)
	var player_tile := tile_map_layer.local_to_map(player.global_position)
	# Calculate Manhattan distance, this reflects the num of tiles between this and player
	var distance = (abs(curr_tile.x) - abs(player_tile.x)) + (abs(curr_tile.y) - abs(player_tile.y))
	# Return true if the distance is in the song range
	return distance <= player.song_range
