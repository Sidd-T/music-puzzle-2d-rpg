@icon("res://assets/editor/icons/Gamepiece.svg")
## A class that represents any generic non-player character
##
## A class that extends [Gamepiece] to provide extra functionality for
## non-player characters.
## The class is still not enough on its own,
## to use, you must extend the [Monster] class from another node
## [br][br]
## Any class that extends [Monster] will be able be a [Gamepiece], but also have
## additional functionality related to NPC
class_name Monster extends Gamepiece

## This is the reference to the player
@onready var player = $"%Player"

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
	
	# connect to player movement, used for range updates
	player.movement_ended.connect(_on_player_movement_ended)
	# Check if in player range, and update accordingly
	_update_in_range()

## Overrides [method _took_step] in [Gamepiece].
func _took_step() -> void:
	_update_in_range()

## Checks if this monster in in the Player range and updates 
## [member in_player_range] and adds/remove to a group
## also connects to the player [signal note_played] signal
func _update_in_range():
	in_player_range = _is_in_player_range()
	if in_player_range:
		add_to_group("in_player_range")
		if !player.is_connected("note_played", _on_player_note_played):
			player.note_played.connect(_on_player_note_played)
	else:
		remove_from_group("in_player_range")
		if player.is_connected("note_played", _on_player_note_played):
			player.note_played.disconnect(_on_player_note_played)

## Function to check if this monster is in the song range of the Player
func _is_in_player_range() -> bool:
	# Calculate Manhattan distance, this reflects the num of tiles between this and player
	var distance = abs((abs(curr_tile.x) - abs(player.curr_tile.x)) + (abs(curr_tile.y) - abs(player.curr_tile.y)))
	# Return true if the distance is in the song range
	return distance <= player.song_range

func _on_player_note_played(note: Globals.Notes):
	print(note)
	pass

func _on_player_movement_ended():
	_update_in_range()
