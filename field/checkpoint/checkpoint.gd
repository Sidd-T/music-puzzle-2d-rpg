class_name Checkpoint extends Gamepiece

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d: Area2D = $Area2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	animated_sprite.play("idle")


func _on_area_2d_area_entered(area_entering: Area2D) -> void:
	var gamepiece := area_entering.get_parent()
	if gamepiece is Player:
		gamepiece.spawn_tile = self.spawn_tile
