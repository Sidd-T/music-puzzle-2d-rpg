extends PlayerState

var is_song_playing: bool

func enter(_previous_state_path: String, _data := {}) -> void:
	is_song_playing = true
	player.animation_state.travel("Play")

func update(_delta: float) -> void:
	
	if is_song_playing:
		return
	
	finished.emit(IDLE)

func handle_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if not event.is_pressed():
			return

		player.input_buffer.append(event.keycode)
		print("Pressed '%s', which is ascii code %d" % [event.key_label, event.keycode])
		player.check_sequence(player.input_buffer)
