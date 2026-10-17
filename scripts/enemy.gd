extends "res://scripts/fighter.gd"

var think_timer = 0.0
var practice_mode = false
var ai_state = "Idle"

func _ready() -> void:
	._ready()
	is_ai = true
	team = 1

func _physics_process(delta: float) -> void:
	think_timer -= delta
	if is_instance_valid(opponent) and health > 0.0 and combat_enabled and not practice_mode:
		var dx: float = opponent.global_position.x - global_position.x
		facing = 1 if dx > 0.0 else -1
		if think_timer <= 0.0:
			think_timer = rand_range(0.18, 0.42)
			is_guarding = false
			if health < max_health * 0.25 and abs(dx) < 150.0 and randf() < 0.3:
				ai_state = "Retreat"
				velocity.x = -sign(dx) * move_speed * 0.65
			elif abs(dx) > 145.0:
				ai_state = "Approach"
				velocity.x = sign(dx) * move_speed * 0.72
				action_state = "run"
			elif energy >= 36.0 and randf() < 0.18:
				ai_state = "Skill"
				cast_rising_strike()
			elif energy >= 28.0 and randf() < 0.28:
				ai_state = "Skill"
				cast_skill()
			elif randf() < 0.55:
				ai_state = "Attack"
				basic_attack()
			else:
				ai_state = "Guard"
				is_guarding = true
				action_state = "guard"
			if randf() < 0.12 and is_on_floor():
				velocity.y = -420.0
	elif practice_mode or not combat_enabled or health <= 0.0:
		ai_state = "Idle" if practice_mode else "KO"
		is_guarding = false
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 7.0 * delta)
	._physics_process(delta)
