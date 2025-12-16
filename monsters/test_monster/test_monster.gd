class_name TestMonster extends Monster

@onready var animation_tree = $AnimationTree
@onready var animation_state = animation_tree.get("parameters/playback")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# make sure we are setting up correctly with the parent nodes' readys
	super()
	
	pass # Replace with function body.


func _process(_delta: float) -> void:
	
	animation_tree.set("parameters/Idle/blend_position", dir)
	animation_tree.set("parameters/Walk/blend_position", dir)
	
	if is_moving:
		animation_state.travel("Walk")
		return
	
	animation_state.travel("Idle")
