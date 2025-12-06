@tool
class_name Monster1 extends Gamepiece

@onready var animationTree = $AnimationTree;
@onready var animationState = animationTree.get("parameters/playback")

@export var player: Player

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	animationTree.set("parameters/Idle/blend_position", dir)
	animationTree.set("parameters/Walk/blend_position", dir)
	
	if is_moving:
		animationState.travel("Walk")
		return
	
	animationState.travel("Idle")

#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		#travel_astar_path(tile_map_layer.local_to_map(get_global_mouse_position()))
