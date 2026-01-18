class_name ScaryMonster extends Monster

@onready var animation_tree = $AnimationTree
@onready var animation_state = animation_tree.get("parameters/playback")

# This enum lists all the possible states the character can be in.
enum States {IDLE, WALKING}

# This variable keeps track of the character's current state.
var state: States = States.IDLE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# make sure we are setting up correctly with the parent nodes' readys
	super()
	
	pass # Replace with function body.


func _process(_delta: float) -> void:
	
	animation_tree.set("parameters/Idle/blend_position", dir)
	animation_tree.set("parameters/Walk/blend_position", dir)
	
	# This chases the player once player is in the song range of the monster
	#if _is_in_player_range():
			#travel_astar_path(player.curr_tile)
	
	if is_moving:
		animation_state.travel("Walk")
		return
	
	# This chases the player once player is in the song range of the monster
	if _is_in_player_range():
			travel_astar_path(player.curr_tile)
	
	animation_state.travel("Idle")
	

func _handle_collision() -> void:
	super()
	# Get the parent of the Area2D to check if it belongs to a Gamepiece
	var colliding_object = check_collider() 
	 #This should be the Gamepiece you're colliding with, 
	 #but it could return something else that's not gampiece
	if colliding_object is Player:
		player.die()
