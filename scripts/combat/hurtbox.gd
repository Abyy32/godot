extends Area2D
class_name ArenaHurtbox

var fighter: ArenaFighter

func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	monitoring = false
	monitorable = true

