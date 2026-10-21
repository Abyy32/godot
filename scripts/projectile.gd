extends Area2D
var direction:=1
var team:=0
var damage:=22.0
var lifetime:=2.0
func _ready():
    add_to_group("projectiles")
    collision_layer=2; collision_mask=1
    var cs=CollisionShape2D.new(); var sh=CircleShape2D.new(); sh.radius=18; cs.shape=sh; add_child(cs)
    connect("body_entered", self, "_hit")
func _physics_process(delta):
    global_position.x+=direction*620*delta; lifetime-=delta
    if lifetime<=0 or global_position.x < -100 or global_position.x>2300: queue_free()
    update()
func _draw():
    var c=Color("#65e6ff") if team==0 else Color("#ffae58")
    if not GameSession.settings.reduced_effects and GameSession.settings.effects_quality == "high":
        draw_circle(Vector2.ZERO,25,Color(c,.12))
    if not GameSession.settings.reduced_effects and GameSession.settings.effects_quality != "low":
        draw_circle(Vector2.ZERO,16,Color(c,.35))
    draw_circle(Vector2.ZERO,9,c)
    if not GameSession.settings.reduced_effects:
        draw_line(Vector2(-direction*10,0),Vector2(-direction*36,0),Color(c,.6),5 if GameSession.settings.effects_quality == "low" else 7)
func _hit(body):
    if body.is_in_group("fighters") and body.team!=team:
        body.take_damage(damage,Vector2(direction*240,-110)); queue_free()
