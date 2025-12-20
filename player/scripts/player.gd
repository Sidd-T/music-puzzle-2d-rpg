## A controller for the player, uses [StateMachine], so this class is just for members
## 
## Explaining animation: [br][br]
##The [AnimatedSprite2D] is just for storing the sprite sheets
## The [AnimationPlayer] is for creating the animations
## The [AnimationTree] is what is actually playing the animation
## [br][br]
## In the animation tree we have a state machine with walk and idle
## Both states contain a blend space, which is a grid around (0, 0)
## where we can set animations at certain points.
## So, we can give it the direction as an input, and then the corresponding animation 
## plays depending on the animation state we're in
class_name Player extends Gamepiece

# Signals
## Signal for when player starts a song
@warning_ignore("unused_signal")
signal song_started(song: Globals.Songs)

## Contains a state machine and blend space for each state
@onready var animation_tree = $AnimationTree;
## Contains the animation state the player is currently in
@onready var animation_state = animation_tree.get("parameters/playback")

## Describes the range in which monsters are affected by the song, in Manhattan distance
var song_range: int = 3
## A buffer of entered keys
var input_buffer: Array = []

## The processed sequences, converted from string to an array of ascii keys
var _sequences: Dictionary[Array, Globals.Songs] = {}
## The longest sequence we need to handle
var max_sequence_length: int

func _ready() -> void:
	super()
	_build_sequences()

## Map each song sequence to ascii codes and get the max sequence length
func _build_sequences() -> void:
	_sequences.clear()
	max_sequence_length = 0
	for song in Globals.SongInputs:
		## Converting string to ascii input keys
		_sequences[Array(song.to_ascii_buffer())] = Globals.SongInputs[song]
		## update max sequence length
		if max_sequence_length < song.length():
			max_sequence_length = song.length()

## This function checks the passed in buffer to the sequences[br][br]
## If the buffer is equal to one of the sequences,the player
## emits the corresponding song signal, then clears the buffer[br][br]
## [param buf] the buffer being checked, is an array of event keycodes
func check_sequence(buf: Array) -> void:
	for sequence in _sequences:
		if sequence == buf.slice(-sequence.size()):
			song_started.emit(_sequences[sequence])
			buf.clear()
	
	while buf.size() > max_sequence_length:
		buf.pop_front()

func cancel_sequence() -> void:
	input_buffer.clear()

#func _process(_delta: float) -> void:
	#
	#animation_tree.set("parameters/Idle/blend_position", dir)
	#animation_tree.set("parameters/Walk/blend_position", dir)
	#
	#if is_moving:
		#animation_state.travel("Walk")
		#return
	#
	#if Input.is_action_pressed("ui_up"):
		#step(Vector2.UP)
	#elif Input.is_action_pressed("ui_down"):
		#step(Vector2.DOWN)
	#elif Input.is_action_pressed("ui_left"):
		#step(Vector2.LEFT)
	#elif Input.is_action_pressed("ui_right"):
		#step(Vector2.RIGHT)
	#else:
		#animation_state.travel("Idle");	
		#
#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		#travel_astar_path(tile_map_layer.local_to_map(get_global_mouse_position()))
