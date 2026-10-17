extends KinematicBody2D
class_name ArenaFighter

signal damaged(amount)
signal skill_used(fighter_name, skill_name, team)
const Projectile = preload("res://scripts/projectile.gd")
const HitboxScript = preload("res://scripts/combat/hitbox.gd")
const HurtboxScript = preload("res://scripts/combat/hurtbox.gd")
export var team = 0
export var max_health = 100.0
export var move_speed = 280.0
export var attack_power = 12.0
export var arena_left = 28.0
export var arena_right = 1252.0
export var character_name = "Shinobi"
var velocity = Vector2.ZERO
var health = 100.0
var energy = 100.0
var facing = 1
var opponent
var attack_timer = 0.0
var skill_timer = 0.0
var rising_strike_timer = 0.0
var skill_animation_timer = 0.0
var dash_timer = 0.0
var hit_flash = 0.0
var attack_frame = 0.0
var hitbox_active_time = 0.0
var attack_hit_done = false
var run_cycle_phase = 0.0
var landing_squash = 0.0
var combo_step = 0
var current_combo_step = 0
var combo_window = 0.0
var combo_queued = false
var action_state = "idle"
var is_ai = false
var color_main = Color("#2a9dca")
var color_accent = Color("#d9f3ff")
var knockback = 0.0
var is_guarding = false
var combat_enabled = true
var sprite_texture: Texture
var animated_sprite: AnimatedSprite
var attack_hitbox
var hurtbox

const ANIMATION_CELLS = {
    "idle": [Vector2(0, 0)],
    "run": [Vector2(1, 0)],
    "jump": [Vector2(2, 0)],
    "guard": [Vector2(3, 0)],
    "attack": [Vector2(0, 1), Vector2(1, 1)],
    "heavy_attack": [Vector2(1, 1)],
    "skill": [Vector2(2, 1)],
    "ko": [Vector2(3, 1)],
}

func _ready():
    health=max_health; collision_layer=1; collision_mask=1
    var cs=CollisionShape2D.new(); var cap=CapsuleShape2D.new()
    cap.radius=23; cap.height=112; cs.shape=cap; cs.position=Vector2(0,-57); add_child(cs); z_index=10
    hurtbox = HurtboxScript.new()
    hurtbox.fighter = self
    var hurt_shape = CollisionShape2D.new()
    var hurt_rectangle = RectangleShape2D.new()
    hurt_rectangle.size = Vector2(48, 104)
    hurt_shape.shape = hurt_rectangle
    hurt_shape.position = Vector2(0, -58)
    hurtbox.add_child(hurt_shape)
    add_child(hurtbox)
    attack_hitbox = HitboxScript.new()
    add_child(attack_hitbox)
    if sprite_texture != null:
        animated_sprite = AnimatedSprite.new()
        animated_sprite.frames = _create_sprite_frames(sprite_texture)
        animated_sprite.position = Vector2(0, -70)
        animated_sprite.scale = Vector2(0.28, 0.28)
        animated_sprite.z_index = 1
        add_child(animated_sprite)
        animated_sprite.play("idle")

func _create_sprite_frames(atlas: Texture) -> SpriteFrames:
    var frames = SpriteFrames.new()
    frames.remove_animation("default")
    for animation_name in ANIMATION_CELLS:
        frames.add_animation(animation_name)
        frames.set_animation_speed(animation_name, 8.0)
        frames.set_animation_loop(animation_name, animation_name != "ko" and animation_name != "attack")
        for cell in ANIMATION_CELLS[animation_name]:
            var atlas_frame = AtlasTexture.new()
            atlas_frame.atlas = atlas
            atlas_frame.region = Rect2(cell.x * 384, cell.y * 512, 384, 512)
            frames.add_frame(animation_name, atlas_frame)
    return frames
func _physics_process(delta):
    var was_on_floor = is_on_floor()
    attack_timer=max(0,attack_timer-delta); skill_timer=max(0,skill_timer-delta)
    rising_strike_timer=max(0,rising_strike_timer-delta); combo_window=max(0,combo_window-delta)
    skill_animation_timer=max(0.0,skill_animation_timer-delta)
    hitbox_active_time=max(0.0,hitbox_active_time-delta)
    dash_timer=max(0,dash_timer-delta); hit_flash=max(0,hit_flash-delta); attack_frame=max(0,attack_frame-delta)
    energy=min(100,energy+8*delta)
    if is_instance_valid(opponent): facing=1 if opponent.global_position.x>global_position.x else -1
    if not is_on_floor(): velocity.y+=1500*delta
    else: velocity.y=0
    _controls()
    if attack_frame > 0.0 and attack_frame <= 0.105 and not attack_hit_done:
        _apply_melee_hit()
    if hitbox_active_time <= 0.0:
        attack_hitbox.deactivate()
    if combo_queued and attack_timer <= 0.0 and combo_step < 3:
        combo_queued = false
        _begin_combo_attack()
    if combo_window <= 0.0:
        combo_step = 0
        combo_queued = false
    if abs(knockback)>1: velocity.x=knockback; knockback=move_toward(knockback,0,900*delta)
    elif dash_timer<=0 and (attack_frame<=0 or skill_animation_timer>0.0): velocity.x=move_toward(velocity.x,0,move_speed*7*delta)
    velocity = move_and_slide(velocity, Vector2.UP)
    global_position.x=clamp(global_position.x,arena_left,arena_right)
    if global_position.y>=535: global_position.y=535
    if not was_on_floor and is_on_floor():
        landing_squash = 1.0
    landing_squash = move_toward(landing_squash, 0.0, delta * 5.5)
    var run_amount = clamp(abs(velocity.x) / max(1.0, move_speed), 0.0, 1.25)
    run_cycle_phase = fposmod(run_cycle_phase + delta * TAU * 7.0 * run_amount, TAU)
    _refresh_visual(delta)
    update()
func _controls():
    if is_ai or not combat_enabled or health<=0:
        return
    is_guarding=Input.is_action_pressed("guard")
    if is_guarding:
        action_state="guard"
        velocity.x=move_toward(velocity.x,0,move_speed*7*get_physics_process_delta_time())
        return
    var d=Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    if abs(d) > 0.1:
        facing = 1 if d > 0.0 else -1
    if dash_timer<=0 and (attack_frame<=0 or skill_animation_timer>0.0) and abs(d)>.1:
        velocity.x=d*move_speed*float(GameSession.settings.control_sensitivity)
        if skill_animation_timer <= 0.0: action_state="run"
    elif is_on_floor() and attack_frame<=0: action_state="idle"
    if Input.is_action_just_pressed("jump") and is_on_floor(): velocity.y=-560; action_state="jump"
    if Input.is_action_just_pressed("attack"):
        if attack_timer > 0.0:
            if combo_window > 0.0 and combo_step > 0:
                combo_queued = true
        elif combo_window > 0.0 and combo_step > 0:
            _begin_combo_attack()
        else:
            combo_step = 0
            _begin_combo_attack()
    if Input.is_action_just_pressed("skill"): cast_skill()
    if Input.is_action_just_pressed("skill_alt"): cast_rising_strike()
    if Input.is_action_just_pressed("dash"): dash()
func basic_attack():
    if attack_timer > 0.0 or health <= 0.0 or not combat_enabled:
        return
    if combo_window <= 0.0:
        combo_step = 0
    _begin_combo_attack()

func _begin_combo_attack() -> void:
    if attack_timer > 0.0 or health <= 0.0 or not combat_enabled:
        return
    attack_timer = 0.34
    attack_frame = 0.19
    attack_hit_done = false
    combo_window = 0.58
    current_combo_step = combo_step
    action_state = "heavy_attack" if current_combo_step == 1 else "attack"
    combo_step = (combo_step + 1) % 3

func _apply_melee_hit():
    attack_hit_done=true
    if not is_instance_valid(attack_hitbox):
        return
    var combo_multiplier: float = [1.0, 1.25, 1.5][current_combo_step]
    attack_hitbox.activate(team, attack_power * combo_multiplier, Vector2(facing * 280, -80), Vector2(facing * 58, -64), Vector2(82, 68))
    hitbox_active_time = 0.09

func cast_skill():
    if skill_timer>0 or energy<28 or health<=0 or not combat_enabled:return
    energy-=28; skill_timer=1.1; action_state="skill"; attack_frame=.42; skill_animation_timer=.42
    emit_signal("skill_used", character_name, "Energy Bolt", team)
    var p=Projectile.new(); p.direction=facing; p.team=team; p.global_position=global_position+Vector2(facing*45,-65)
    get_tree().current_scene.add_child(p)

func cast_rising_strike():
    if rising_strike_timer > 0.0 or energy < 36.0 or health <= 0.0 or not combat_enabled:
        return
    energy -= 36.0
    rising_strike_timer = 2.4
    action_state = "skill"
    attack_frame = 0.34
    skill_animation_timer = 0.34
    emit_signal("skill_used", character_name, "Rising Strike", team)
    velocity.y = -360.0
    attack_hit_done = true
    attack_hitbox.activate(team, attack_power * 1.8, Vector2(facing * 150, -420), Vector2(facing * 18, -112), Vector2(92, 124))
    hitbox_active_time = 0.20
func dash():
    if dash_timer>0 or not combat_enabled or health<=0:return
    dash_timer=.22; velocity.x=facing*690*float(GameSession.settings.control_sensitivity); action_state="dash"
func take_damage(amount,impulse=Vector2.ZERO):
    if health<=0 or not combat_enabled:return
    var applied_damage=amount*.25 if is_guarding else amount
    health=max(0,health-applied_damage); energy=min(100,energy+applied_damage*.25); hit_flash=.18
    knockback=impulse.x*.35 if is_guarding else impulse.x; velocity.y=impulse.y; action_state="guard" if is_guarding else "hurt"
    emit_signal("damaged", applied_damage)
    update()
func set_combat_enabled(enabled: bool):
    combat_enabled=enabled
    if not enabled:
        velocity=Vector2.ZERO

func _refresh_visual(delta: float):
    if not is_instance_valid(animated_sprite):
        return
    animated_sprite.flip_h = facing < 0
    var flash_amount = clamp(hit_flash * float(GameSession.settings.flash_intensity) * 5.0, 0.0, 1.0)
    if GameSession.settings.reduced_effects:
        flash_amount *= 0.2
    animated_sprite.modulate = Color.white.linear_interpolate(Color("#fff0e8"), flash_amount)
    var target_animation = "idle"
    if health <= 0.0:
        target_animation = "ko"
    elif action_state == "hurt" or hit_flash > 0.0:
        target_animation = "guard"
    elif action_state == "guard":
        target_animation = "guard"
    elif action_state == "skill":
        target_animation = "skill"
    elif action_state == "attack":
        target_animation = "attack"
    elif action_state == "heavy_attack":
        target_animation = "heavy_attack"
    elif not is_on_floor():
        target_animation = "jump"
    elif abs(velocity.x) > 25.0:
        target_animation = "run"
    if animated_sprite.animation != target_animation:
        animated_sprite.play(target_animation)
    elif target_animation != "ko" and not animated_sprite.is_playing():
        animated_sprite.play(target_animation)

    var target_position = Vector2(0.0, -70.0)
    var target_scale = Vector2(0.28, 0.28)
    var target_rotation = 0.0
    if target_animation == "run":
        var step_bob = sin(run_cycle_phase * 2.0)
        target_position.y += abs(step_bob) * -2.4
        target_scale.x *= 1.0 + step_bob * 0.018
        target_scale.y *= 1.0 - step_bob * 0.018
        target_rotation = clamp(velocity.x / max(1.0, move_speed), -1.0, 1.0) * -0.035
    elif target_animation == "jump":
        var rising = velocity.y < 0.0
        target_position.y += -2.0 if rising else 1.5
        target_scale.x *= 0.97 if rising else 1.025
        target_scale.y *= 1.04 if rising else 0.975
        target_rotation = clamp(velocity.x / max(1.0, move_speed), -1.0, 1.0) * -0.025
    if landing_squash > 0.0 and is_on_floor():
        var squash = landing_squash * 0.055
        target_position.y += landing_squash * 1.5
        target_scale.x *= 1.0 + squash
        target_scale.y *= 1.0 - squash

    var blend = 1.0 - exp(-delta * 14.0)
    animated_sprite.position = animated_sprite.position.linear_interpolate(target_position, blend)
    animated_sprite.scale = animated_sprite.scale.linear_interpolate(target_scale, blend)
    animated_sprite.rotation = lerp_angle(animated_sprite.rotation, target_rotation, blend)

func _draw():
    if is_instance_valid(animated_sprite):
        return
    var c=Color.white if hit_flash>0 else color_main
    var f=float(facing)
    draw_set_transform(Vector2.ZERO,0,Vector2(1,1))
    draw_circle(Vector2(0,-2),31,Color(0,0,0,.28))
    var scarf=PoolVector2Array([Vector2(-f*8,-86),Vector2(-f*42,-79+sin(OS.get_ticks_msec()/95.0)*4),Vector2(-f*52,-68),Vector2(-f*22,-73),Vector2(-f*5,-69)])
    draw_colored_polygon(scarf,Color("#e84a5f") if team==0 else Color("#c49a45"))
    draw_line(Vector2(-10,-42),Vector2(-15,-12),Color("#151b2a"),12); draw_line(Vector2(10,-42),Vector2(15,-12),Color("#151b2a"),12)
    draw_line(Vector2(-17,-10),Vector2(-5,-8),Color("#d5d9e4"),7); draw_line(Vector2(12,-10),Vector2(24,-8),Color("#d5d9e4"),7)
    draw_colored_polygon(PoolVector2Array([Vector2(-18,-83),Vector2(18,-83),Vector2(25,-45),Vector2(13,-37),Vector2(-15,-37),Vector2(-25,-48)]),c)
    draw_line(Vector2(-18,-77),Vector2(18,-45),color_accent,3)
    draw_line(Vector2(-17,-76),Vector2(-30,-52),c,12); draw_line(Vector2(17,-76),Vector2(28,-56),c,12)
    draw_circle(Vector2(-30,-51),7,Color("#e4b59a")); draw_circle(Vector2(28,-55),7,Color("#e4b59a"))
    draw_rect(Rect2(-7,-91,14,12),Color("#d9a58a")); draw_circle(Vector2(0,-105),18,Color("#e8b99e"))
    draw_colored_polygon(PoolVector2Array([Vector2(-18,-108),Vector2(-26,-127),Vector2(-12,-120),Vector2(-7,-139),Vector2(2,-122),Vector2(13,-136),Vector2(15,-119),Vector2(25,-124),Vector2(17,-105)]),Color("#172238") if team==0 else Color("#eee8db"))
    draw_rect(Rect2(-17,-111,34,5),Color("#a9c5d9")); draw_rect(Rect2(-5,-112,10,6),Color("#e2e7ef"))
    draw_line(Vector2(4,-104),Vector2(13,-103),Color("#202030"),3)
    if action_state in ["skill","attack","guard"]:
        var aura=Color("#69dfff",.7) if team==0 else Color("#ffb15e",.7)
        draw_arc(Vector2(f*22,-65),35,-1.1,1.1,20,aura,5)
        if action_state=="attack": draw_line(Vector2(f*25,-67),Vector2(f*70,-58),Color(1,1,1,.9),7)
        if action_state=="guard": draw_arc(Vector2.ZERO,47,-1.2,1.2,18,Color("#a6d9ff",.8),4)
