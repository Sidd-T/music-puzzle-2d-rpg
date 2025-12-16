## A controller for the player, uses [StateMachine], so this class is just for members
## 
## Explaining animation: [br][br]
##The [AnimatedSprite2D] is just for storing the sprite sheets
## The [AnimationPlayer] is for creating the animations
## The [AnimationTree] is what is actually playing the animation
## [br][br]
## In the animation tree we have a state machine with walk and idle
## Both states contain a blend space, which is a grid around (0, 0)
## where we can set animations at certain points.
## So, we can give it the direction as an input, and then the corresponding animation 
## plays depending on the animation state we're in
class_name Player extends Gamepiece

# Signals
## Signal for when player starts a song
@warning_ignore("unused_signal")
signal song_started

## Contains a state machine and blend space for each state
@onready var animation_tree = $AnimationTree;
## Contains the animation state the player is currently in
@onready var animation_state = animation_tree.get("parameters/playback")

# Player Attributes
## Describes the range in which monsters are affected by the song, in Manhattan distance
var song_range: int = 3

func _ready() -> void:
	super()

#func _process(_delta: float) -> void:
	#
	#animation_tree.set("parameters/Idle/blend_position", dir)
	#animation_tree.set("parameters/Walk/blend_position", dir)
	#
	#if is_moving:
		#animation_state.travel("Walk")
		#return
	#
	#if Input.is_action_pressed("ui_up"):
		#step(Vector2.UP)
	#elif Input.is_action_pressed("ui_down"):
		#step(Vector2.DOWN)
	#elif Input.is_action_pressed("ui_left"):
		#step(Vector2.LEFT)
	#elif Input.is_action_pressed("ui_right"):
		#step(Vector2.RIGHT)
	#else:
		#animation_state.travel("Idle");	
		#
#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		#travel_astar_path(tile_map_layer.local_to_map(get_global_mouse_position()))
