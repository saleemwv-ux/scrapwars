extends Node2D
## Short-lived visual effects: explosions, spell blasts and hit sparks.

var kind := "boom"
var size := 30.0
var color := Color.WHITE
var life := 0.5
var age := 0.0
var debris: Array = []


func setup(p_kind: String, pos: Vector2, p_size: float, p_color: Color) -> void:
	kind = p_kind
	position = pos
	size = p_size
	color = p_color
	z_index = 15
	if kind == "boom" or kind == "blast":
		life = 0.6 if kind == "boom" else 0.75
		for i in (10 if kind == "boom" else 18):
			var a := randf() * TAU
			debris.append([Vector2(cos(a), sin(a)) * randf_range(0.5, 1.2), randf_range(2.0, 5.0)])
	else:
		life = 0.18


func _process(delta: float) -> void:
	age += delta
	if age >= life:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := age / life
	var c := Color(color, 1.0 - k)
	if kind == "boom" or kind == "blast":
		var r := size * (0.35 + 0.65 * k)
		# Hot core, coloured fireball, shockwave ring and flying scrap.
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.75))
		draw_circle(Vector2.ZERO, r, Color(color, 0.3 * (1.0 - k)))
		draw_circle(Vector2.ZERO, r * 0.6 * (1.0 - k), Color(1.0, 0.95, 0.75, 0.8 * (1.0 - k)))
		draw_arc(Vector2.ZERO, r * 1.1, 0.0, TAU, 40, c, 4.0 * (1.0 - k) + 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for d in debris:
			var p: Vector2 = d[0] * size * k + Vector2(0, -sin(k * PI) * size * 0.3)
			var s: float = d[1]
			draw_rect(Rect2(p - Vector2(s, s), Vector2(s, s) * 2.0), Color(Art.METAL_DARK.lerp(color, 0.3), 1.0 - k))
	else:
		draw_circle(Vector2.ZERO, 3.0 + size * 0.4 * (1.0 - k), c)
		draw_circle(Vector2.ZERO, 2.0 + size * 0.2 * (1.0 - k), Color(1, 1, 1, 1.0 - k))
