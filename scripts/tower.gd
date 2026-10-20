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
	var body := Art.RUST
	if hit_flash > 0.0:
		body = body.lightened(0.4)
	var r := radius
	# Footprint and shadow.
	draw_rect(Rect2(-r * 1.1, -r * 0.2, r * 2.2, r * 1.2), Color(0, 0, 0, 0.3))
	draw_rect(Rect2(-r, -r * 1.2, r * 2.0, r * 2.0), body)
	draw_rect(Rect2(-r, -r * 1.2, r * 2.0, r * 2.0), Art.RUST_DARK, false, 3.0)
	# Welded scrap plates.
	draw_rect(Rect2(-r * 0.85, -r * 0.3, r * 0.7, r * 0.8), Art.METAL_DARK)
	draw_rect(Rect2(r * 0.2, -r * 0.55, r * 0.65, r * 0.6), Art.RUST_DARK)
	for i in 4:
		var x := -r * 0.75 + i * r * 0.5
		draw_circle(Vector2(x, -r * 1.0), 2.5, Art.DARK)
		draw_circle(Vector2(x, r * 0.6), 2.5, Art.DARK)
	# Team colour band.
	draw_rect(Rect2(-r, -r * 1.2, r * 2.0, r * 0.3), col)
	# Turret and barrel.
	var turret := Vector2(0, -r * 0.5)
	draw_line(turret, turret + aim * r * 0.95, Art.DARK, r * 0.28)
	draw_circle(turret, r * 0.45, Art.METAL)
	draw_circle(turret, r * 0.25, col.darkened(0.2))
	if kind == "king":
		Art.draw_crown(self, Vector2(0, -r * 1.55), r * 0.45, Color(1.0, 0.82, 0.25))
		if not active:
			var font := ThemeDB.fallback_font
			draw_string(font, Vector2(r * 0.55, -r * 1.35), "z z", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.8))
	draw_hp_bar(r * 2.2, r * 0.95, true)
	var font2 := ThemeDB.fallback_font
	draw_string(font2, Vector2(-r * 1.1, r * 0.95 + 22.0), str(int(ceil(hp))), HORIZONTAL_ALIGNMENT_CENTER, r * 2.2, 16, Color.WHITE)
