## A node containing all the songs playable by the player and signals to emit
##
## Each song is associated with a sequence of inputs and corresponds to a 
## function which emits a signal. This is an autoloaded load, so it can emit signals
## independently of what nodes are in the scene
extends Node

## This song is related to ...
signal song_1
## This song is related to ...
signal song_2

## A buffer of previous entered key codes
var buffer: Array = []

## The configured functions and the input sequences to trigger
var sequences: Dictionary[String, Callable] = {
	"12345": _seq_one,
	"15243": _seq_two
}

## The processed sequences, converted from string to an array of ascii keys
var _sequences: Dictionary[Array, Callable] = {}

## The longest sequence we need to handle
var max_sequence_length: int

func _ready() -> void:
	_build_sequences()


func handle_input(event) -> void:
	if event is InputEventKey:
		if not event.is_pressed():
			return

		buffer.append(event.keycode)
		print("Pressed '%s', which is ascii code %d" % [event.key_label, event.keycode])
		_check_sequence(buffer)


func _build_sequences() -> void:
	_sequences.clear()
	max_sequence_length = 0
	for sequence in sequences:
		_sequences[Array(sequence.to_ascii_buffer())] = sequences[sequence]
		if max_sequence_length < sequence.length():
			max_sequence_length = sequence.length()

## This function checks the passed in buffer to the sequences[br][br]
## If the buffer is equal to one of the sequences, it calls the function
## for that sequences and emits the song signal, then clears the buffer[br][br]
## [param buf] the buffer being checked, is an array of event keycodes
func _check_sequence(buf: Array) -> void:
	for sequence in _sequences:
		if sequence == buf.slice(-sequence.size()):
			_sequences[sequence].call()
			buf.clear()
	
	while buf.size() > max_sequence_length:
		buf.pop_front()

func cancel_sequence() -> void:
	buffer.clear()

func _seq_one() -> void:
	song_1.emit()


func _seq_two() -> void:
	song_2.emit()
