extends PlayerState

func enter(_previous_state_path: String, _data := {}) -> void:
	var player_dir := Vector2.DOWN if player.dir == Vector2.ZERO else player.dir
	player.animation_tree.set("parameters/Idle/blend_position", player_dir)
	player.animation_state.travel("Idle")

func update(_delta: float) -> void:
	
	var movement_callable := Callable(player, "step")
	var input_dir: Vector2
	
	var next_action := "idle"
	
	if Input.is_action_pressed("ui_up"):
		input_dir = Vector2.UP
		next_action = "walking"
	elif Input.is_action_pressed("ui_down"):
		input_dir = Vector2.DOWN
		next_action = "walking"
	elif Input.is_action_pressed("ui_left"):
		input_dir = Vector2.LEFT
		next_action = "walking"
	elif Input.is_action_pressed("ui_right"):
		input_dir = Vector2.RIGHT
		next_action = "walking"
	elif Input.is_action_pressed("start_song"):
		next_action = "start_song"
		return
	
	## get next state
	match next_action:
		"idle":
			return
		"walking":
			finished.emit(WALKING, { "move_func": movement_callable, "param": input_dir })
		"start_song":
			finished.emit(PLAYING)

func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		var movement_callable := Callable(player, "travel_astar_path")
		var target_tile := player.tile_map_layer.local_to_map(player.get_global_mouse_position())
		finished.emit(WALKING, { "move_func": movement_callable, "param": target_tile })
	
