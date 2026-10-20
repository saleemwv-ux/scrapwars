extends Node2D
## Fire Bomb: lobbed from the caster's king tower, explodes on landing.

const FLIGHT_TIME := 0.8

var game
var team := 0
var card: Dictionary = {}
var start := Vector2.ZERO
var dest := Vector2.ZERO
var t := 0.0


func setup(p_game, p_team: int, p_id: String, from: Vector2, to: Vector2) -> void:
	game = p_game
	team = p_team
	card = Cards.get_card(p_id)
	start = from
	dest = to
	position = from
	z_index = 20


func _process(delta: float) -> void:
	t += delta
	var k := clampf(t / FLIGHT_TIME, 0.0, 1.0)
	position = start.lerp(dest, k) + Vector2(0, -sin(k * PI) * 160.0)
	queue_redraw()
	if k >= 1.0:
		game.deal_area(team, dest, card["spell_radius"], card["damage"], card["tower_mult"])
		game.spawn_effect("boom", dest, card["spell_radius"], Color(1.0, 0.55, 0.15))
		queue_free()


func _draw() -> void:
	var marker := dest - position
	draw_arc(marker, card["spell_radius"], 0.0, TAU, 40, Color(1.0, 0.5, 0.1, 0.6), 2.0)
	Art.draw_unit(self, "firebomb", 12.0, Arena.team_color(team), t * 10.0, Vector2.UP)
