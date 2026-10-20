extends Node2D
## A spell card: lobbed from the caster's king tower, it lands and either
## bursts at once or (for poison) lingers and deals its damage over time.

const FLIGHT_TIME := 0.8
const TICK := 0.5

var game
var team := 0
var id := ""
var card: Dictionary = {}
var start := Vector2.ZERO
var dest := Vector2.ZERO
var t := 0.0
var landed := false
var linger := 0.0
var tick_timer := 0.0
var bubbles: Array = []


func setup(p_game, p_team: int, p_id: String, from: Vector2, to: Vector2) -> void:
	game = p_game
	team = p_team
	id = p_id
	card = Cards.get_card(p_id)
	start = from
	dest = to
	position = from
	z_index = 20


func _process(delta: float) -> void:
	queue_redraw()
	if not game.is_running():
		return
	t += delta
	if not landed:
		var k := clampf(t / FLIGHT_TIME, 0.0, 1.0)
		position = start.lerp(dest, k) + Vector2(0, -sin(k * PI) * 160.0)
		if k >= 1.0:
			_land()
		return
	linger -= delta
	tick_timer -= delta
	if tick_timer <= 0.0 and linger > -0.01:
		tick_timer = TICK
		var ticks: float = card["poison"] / TICK
		game.deal_area(team, dest, card["spell_radius"], card["damage"] / ticks, card["tower_mult"])
	if linger <= 0.0:
		queue_free()


func _land() -> void:
	landed = true
	position = dest
	z_index = 1
	var col: Color = game.faction_color(team)
	if card["poison"] > 0.0:
		linger = card["poison"]
		tick_timer = 0.0
		for i in 14:
			var a := randf() * TAU
			bubbles.append([Vector2(cos(a), sin(a) * 0.6) * randf() * card["spell_radius"], randf() * TAU])
		game.spawn_effect("boom", dest, card["spell_radius"] * 0.6, col)
		return
	game.deal_area(team, dest, card["spell_radius"], card["damage"], card["tower_mult"])
	game.spawn_effect("blast", dest, card["spell_radius"], col)
	queue_free()


func _draw() -> void:
	var col: Color = game.faction_color(team)
	var r: float = card["spell_radius"]
	if not landed:
		var marker := dest - position
		draw_arc(marker, r, 0.0, TAU, 40, Color(col, 0.7), 2.0)
		draw_circle(marker, r, Color(col, 0.08))
		var k := clampf(t / FLIGHT_TIME, 0.0, 1.0)
		Art.draw_sprite_centered(self, id, Vector2.ZERO, card["size"] * (0.8 + 0.4 * sin(k * PI)), sin(t * 8.0) * 0.2)
		return
	# Lingering poison cloud.
	var fade := clampf(linger / 0.6, 0.0, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.7))
	for i in 3:
		draw_circle(Vector2.ZERO, r * (1.0 - i * 0.22), Color(col.darkened(0.2), 0.12 * fade))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(col, 0.5 * fade), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for b in bubbles:
		var phase: float = b[1] + t * 2.0
		var p: Vector2 = b[0] + Vector2(0, -fmod(phase, 2.0) * 14.0)
		draw_circle(p, 4.0 + 3.0 * sin(phase), Color(col.lightened(0.3), 0.55 * fade))
