extends Area2D
class_name ArenaHitbox

var team = 0
var damage = 0.0
var impulse = Vector2.ZERO
var hit_targets: Dictionary = {}
var shape_node: CollisionShape2D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 4
	monitoring = false
	monitorable = false
	shape_node = CollisionShape2D.new()
	var rectangle = RectangleShape2D.new()
	rectangle.size = Vector2(82, 68)
	shape_node.shape = rectangle
	add_child(shape_node)
	connect("area_entered", self, "_on_area_entered")

func activate(attacker_team: int, damage_amount: float, knockback: Vector2, shape_position: Vector2, shape_size: Vector2) -> void:
	team = attacker_team
	damage = damage_amount
	impulse = knockback
	hit_targets.clear()
	var rectangle = RectangleShape2D.new()
	rectangle.size = shape_size
	shape_node.set_deferred("position", shape_position)
	shape_node.set_deferred("shape", rectangle)
	set_deferred("monitoring", true)

func deactivate() -> void:
	set_deferred("monitoring", false)

func _on_area_entered(area: Area2D) -> void:
	var target = area.get("fighter")
	if target == null or target.team == team:
		return
	var target_id = target.get_instance_id()
	if hit_targets.has(target_id):
		return
	hit_targets[target_id] = true
	target.take_damage(damage, impulse)
