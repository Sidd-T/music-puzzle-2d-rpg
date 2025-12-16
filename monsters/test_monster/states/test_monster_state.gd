## An extended class of state made for the testmonster character
##
## This class defines the states and checks that the player exists and is a [TestMonster] node
class_name TestMonsterState extends State

const IDLE = "Idle"
const WALKING = "Walking"

var test_monster: TestMonster

func _ready() -> void:
	await owner.ready
	test_monster = owner as TestMonster
	assert(test_monster != null, "The TestMonsterState state type must be used only in the testMonster scene. It needs the owner to be a TestMonster node.")
