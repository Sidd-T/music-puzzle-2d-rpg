## A class that provides the necessary functions for any state machine
##
## This class is a generic tool to create state machines for any parent node
## We define 5 functions that each state can use, and then enter the first state in ready
## if not set in the export var
class_name StateMachine extends Node

@export var initial_state: State = null

@onready var state: State = (func get_initial_state() -> State:
	return initial_state if initial_state != null else get_child(0)
).call()


func _ready() -> void:
	# Connect the finished signal of each state to the callback here in this class
	for state_node: State in find_children("*", "State"):
		state_node.finished.connect(_transition_to_next_state)

	# Enter the first state when owner is ready
	await owner.ready
	state.enter("")

## This function will be used when the state needs to handle user input
func _unhandled_input(event: InputEvent) -> void:
	state.handle_input(event)

## Called every main loop tick.
func _process(delta: float) -> void:
	state.update(delta)

## Called every physics update tick.
func _physics_process(delta: float) -> void:
	state.physics_update(delta)

## Ths function will transition the state machine to the next state [br][br]
## [param target_state_path] The child node's name of the next state to travel to
## [param data] any data that is needed for the next state is but in an object with key value pairs
func _transition_to_next_state(target_state_path: String, data: Dictionary = {}) -> void:
	if not has_node(target_state_path):
		printerr(owner.name + ": Trying to transition to state " + target_state_path + " but it does not exist.")
		return

	var previous_state_path := state.name
	state.exit()
	state = get_node(target_state_path)
	state.enter(previous_state_path, data)
