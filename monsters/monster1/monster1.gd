@tool
class_name Monster1 extends Gamepiece

@onready var animationTree = $AnimationTree;
@onready var animationState = animationTree.get("parameters/playback")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	animationTree.set("parameters/Idle/blend_position", dir)
	animationTree.set("parameters/Walk/blend_position", dir)
	
	if is_moving:
		animationState.travel("Walk")
		return
	
	animationState.travel("Idle");
