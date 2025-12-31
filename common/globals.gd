extends Node

enum Notes {NOTE1, NOTE2, NOTE3, NOTE4, NOTE5}

## True when the game state is idle and allowed to change.
## Set to false while an UndoRedo action is being constructed.
var open_game_state := true
## Godot's UndoRedo manager used to track reversible game state changes.
var undo_redo := UndoRedo.new()
## Number of pieces currently moving.
## Used to delay committing the UndoRedo action until all movement finishes.
var moving_pieces := 0

## Ensures an UndoRedo action is active before modifying game state.
## Safe to call multiple times; it will only start an action if needed.
func ensure_action_started():
	if open_game_state:
		begin_advance_game_state()

## Begins a new UndoRedo action for advancing the game state.
## Locks the game state to prevent overlapping actions.
func begin_advance_game_state():
	if !open_game_state:
		return

	open_game_state = false
	undo_redo.create_action("Advance Game State")

## Ends the current UndoRedo action and commits all recorded changes.
## Unlocks the game state so new actions may begin.
func _end_advance_game_state():
	if open_game_state:
		return

	undo_redo.commit_action()
	open_game_state = true

## Registers the start of a piece's movement.
## Increments the active movement counter.
func register_movement_start():
	moving_pieces += 1

## Registers the end of a piece's movement.
## Decrements the movement counter and commits the game state
## once all movement has completed.
func register_movement_end():
	# Guard against the counter going negative due to mismatched calls.
	moving_pieces = max(moving_pieces - 1, 0)

	# When no pieces are moving, finalize the UndoRedo action.
	if moving_pieces == 0:
		_end_advance_game_state()

## Handles input events not consumed by the UI.
## Allows undoing the last action when the game state is open.
func _unhandled_input(event: InputEvent):
	# Ignore input while an UndoRedo action is in progress.
	if !open_game_state:
		return
	
	if event.is_action_pressed("undo"):
		if undo_redo.has_undo():
			undo_redo.undo()
