class_name Tower
extends Entity
## King and princess towers. The king tower sleeps until it takes damage
## or one of its princess towers falls.

var kind := "princess"
var lane := -1
var active := true
var damage := 55.0
var hit_speed := 0.8
var attack_range := 230.0
var attack_timer := 0.0
var target: Entity = null
var aim := Vector2.UP
var sprite := ""
var fire_anim := 0.0


func setup(p_game, p_team: int, p_kind: String, p_pos: Vector2, p_lane: int) -> void:
	game = p_game
	team = p_team
	kind = p_kind
	lane = p_lane
	position = p_pos
	is_building = true
	aim = Vector2.UP if team == Arena.PLAYER else Vector2.DOWN
	if kind == "king":
		max_hp = 2400.0
		radius = 44.0
		damage = 70.0
		hit_speed = 1.0
		attack_range = 220.0
		active = false
	else:
		max_hp = 1400.0
		radius = 32.0
	hp = max_hp


func activate() -> void:
	active = true


func _on_damaged() -> void:
	if kind == "king" and not active:
		activate()


func _process(delta: float) -> void:
	hit_flash = maxf(0.0, hit_flash - delta)
	fire_anim = maxf(0.0, fire_anim - delta)
	queue_redraw()
	if not game.is_running() or not active:
		return
	attack_timer = maxf(0.0, attack_timer - delta)
	if target == null or not is_instance_valid(target) or not target.alive or not _in_range(target):
		target = _find_target()
	if target == null:
		return
	aim = (target.position - position).normalized()
	if attack_timer <= 0.0:
		attack_timer = hit_speed
		fire_anim = 0.2
		game.spawn_projectile(self, target, damage, 0.0, "any")


func _in_range(e: Entity) -> bool:
	return position.distance_to(e.position) - e.radius <= attack_range


func _find_target() -> Entity:
	var best: Entity = null
	var best_d := INF
	for e in game.entities:
		if not is_instance_valid(e) or not e.alive or e.team == team or e is Tower:
			continue
		var d: float = position.distance_to(e.position) - e.radius
		if d <= attack_range and d < best_d:
			best = e
			best_d = d
	return best


func _draw() -> void:
	var col := Arena.team_color(team)
	var r := radius
	var base := Vector2(0, r * 0.75)
	Art.draw_shadow(self, base, r * 1.35, 0.55)
	draw_set_transform(base, 0.0, Vector2(1.0, 0.42))
	draw_arc(Vector2.ZERO, r * 1.2, 0.0, TAU, 32, col, 4.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var size := r * (2.95 if kind == "king" else 3.4)
	var mod := Art.FLASH if hit_flash > 0.0 else Color.WHITE
	if kind == "king" and not active:
		mod = mod * Color(0.8, 0.8, 0.85)
	var squash := 0.05 * sin(fire_anim / 0.2 * PI)
	Art.draw_sprite(self, sprite, base, size, false, mod, squash)
	var top := base.y - size
	if kind == "king":
		Art.draw_crown(self, Vector2(0, top - 4.0), r * 0.36, Color(1.0, 0.82, 0.25))
		if not active:
			var font := ThemeDB.fallback_font
			draw_string_outline(font, Vector2(r * 0.5, top + 10.0), "z z", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 4, Color(0, 0, 0, 0.7))
			draw_string(font, Vector2(r * 0.5, top + 10.0), "z z", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 0.9))
	draw_hp_bar(r * 2.2, base.y + 10.0, true)
	var font2 := ThemeDB.fallback_font
	var label_pos := Vector2(-r * 1.1, base.y + 34.0)
	draw_string_outline(font2, label_pos, str(int(ceil(hp))), HORIZONTAL_ALIGNMENT_CENTER, r * 2.2, 16, 4, Color(0, 0, 0, 0.8))
	draw_string(font2, label_pos, str(int(ceil(hp))), HORIZONTAL_ALIGNMENT_CENTER, r * 2.2, 16, Color.WHITE)
