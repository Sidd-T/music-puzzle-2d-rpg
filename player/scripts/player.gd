class_name Player extends Gamepiece

#@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animationTree = $AnimationTree;
@onready var animationState = animationTree.get("parameters/playback")

func _process(_delta: float) -> void:
	
	animationTree.set("parameters/Idle/blend_position", dir)
	animationTree.set("parameters/Walk/blend_position", dir)
	
	if is_moving:
		animationState.travel("Walk")
		return
	
	if Input.is_action_pressed("ui_up"):
		step(Vector2.UP)
	elif Input.is_action_pressed("ui_down"):
		step(Vector2.DOWN)
	elif Input.is_action_pressed("ui_left"):
		step(Vector2.LEFT)
	elif Input.is_action_pressed("ui_right"):
		step(Vector2.RIGHT)
	else:
		animationState.travel("Idle");	
