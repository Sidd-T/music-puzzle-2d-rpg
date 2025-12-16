## An extended class of state made for the player character
##
## This class defines the states and checks that the player exists and is a [Player] node
class_name PlayerState extends State

const IDLE = "Idle"
const WALKING = "Walking"
const PLAYING = "Playing"

var player: Player

func _ready() -> void:
	await owner.ready
	player = owner as Player
	assert(player != null, "The PlayerState state type must be used only in the player scene. It needs the owner to be a Player node.")
