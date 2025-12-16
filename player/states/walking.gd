extends PlayerState

func enter(_previous_state_path: String, data := {}) -> void:
	player.animation_state.travel("Walk")
	
	var movement_callable := Callable(data["move_func"])
	var param = (data["param"])
	
	movement_callable.call(param)

func update(_delta: float) -> void:
	player.animation_tree.set("parameters/Walk/blend_position", player.dir)
	
	if player.is_moving == false:
		finished.emit(IDLE)
