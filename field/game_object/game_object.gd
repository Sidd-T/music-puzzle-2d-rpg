## A class that extends [Gamepieces] to allow for basic animations
##
## This class is used to provide animation functionality for any generic object on the grid.
## For example a box. We use [Gamepiece] functionality to move it around if necessary
class_name GameObject extends Gamepiece

@onready var animation_tree = $AnimationTree
@onready var animation_state = animation_tree.get("parameters/playback")

func _process(_delta: float) -> void:
	
	animation_tree.set("parameters/Idle/blend_position", dir)
	animation_tree.set("parameters/Walk/blend_position", dir)
	
	if is_moving:
		animation_state.travel("Walk")
	else:
		animation_state.travel("Idle")
