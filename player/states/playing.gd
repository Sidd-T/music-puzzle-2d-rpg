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
	Songs.handle_input(event)
