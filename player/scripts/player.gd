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
		
## States that the player can be in
enum State {IDLE, WALKING, SLIDING, PLAYING, DIE}
## Variable to keep track of current state
var prev_state := State.IDLE
var curr_state := State.IDLE

# Signals
## Signal for when player plays a note
signal note_played(note: Globals.Notes)

## Contains a state machine and blend space for each state
@onready var animation_tree = $AnimationTree;
## Contains the animation state the player is currently in
@onready var animation_state = animation_tree.get("parameters/playback")

## Describes the range in which monsters are affected by the song, in Manhattan distance
@export var song_range: int = 7

func _ready() -> void:
	super()
	_transition_to_next_state(State.IDLE, "Idle")

func _process(_delta: float) -> void:
	# Have to return otherwise process will continously get our input and try and move
	if is_moving:
		return 
	
	# getting our input
	if Input.is_action_pressed("ui_up"):
		step(Vector2.UP)
	elif Input.is_action_pressed("ui_down"):
		step(Vector2.DOWN)
	elif Input.is_action_pressed("ui_left"):
		step(Vector2.LEFT)
	elif Input.is_action_pressed("ui_right"):
		step(Vector2.RIGHT)
		
		
	### TODO: 
	# if come in contact with scary monster, play die animation and quit getting input forever 
	# (quit process) until game is reset
	# In gamepiece script, add a new group of "things in contact"
	# then for player we can check the group if things in contact include a "scary monster"
	# if yes, then play die animation and quit
	#if 
	#die()

## This is an addition function to add point and click movement to the player
func _unhandled_input(event: InputEvent) -> void:	
	if curr_state != State.IDLE:
		return
	
	# We check if mouse was clicked, and get to tile that is at the mouse position to pathfind to
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		travel_astar_path(gameboard.local_to_map(get_global_mouse_position()))
		return
	
	handle_note_input(event)

func handle_note_input(event: InputEvent) -> void:
	var note: Globals.Notes
	var playing_note := false
	if event.is_action_pressed("note_1"):
		note = Globals.Notes.NOTE1
		playing_note = true
	if event.is_action_pressed("note_2"):
		note = Globals.Notes.NOTE2
		playing_note = true
	if event.is_action_pressed("note_3"):
		note = Globals.Notes.NOTE3
		playing_note = true
	if event.is_action_pressed("note_4"):
		note = Globals.Notes.NOTE4
		playing_note = true
	if event.is_action_pressed("note_5"):
		note = Globals.Notes.NOTE5
		playing_note = true
	
	if playing_note:
		Globals.begin_advance_game_state()
		print("playing note", note)
		note_played.emit(note)
	
	

func _direction_updated() -> void:
	animation_tree.set("parameters/Idle/blend_position", dir)
	animation_tree.set("parameters/Walk/blend_position", dir)

func _start_movement() -> void:
	super()
	_transition_to_next_state(State.WALKING, "Walk")

func _end_movement() -> void:
	super()
	_transition_to_next_state(State.IDLE, "Idle")

func _transition_to_next_state(new_state: State, anim_state: String) -> void:
	prev_state = curr_state
	curr_state = new_state
	animation_state.travel(anim_state)
	
#func _handle_collision() -> void:
	#super()
	## Get the parent of the Area2D to check if it belongs to a Gamepiece
	#var colliding_object = check_collider() 
	# This should be the Gamepiece you're colliding with, 
	# but it could return something else that's not gampiece
	#if colliding_object is ScaryMonster:
		#_end_movement()
		#die()

# play die animation
func die() -> void:
	_end_movement()
	_transition_to_next_state(State.DIE, "Die")
	
