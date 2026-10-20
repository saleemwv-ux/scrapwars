extends Node2D
## Short-lived visual effects: explosions and hit sparks.

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
	if kind == "boom":
		life = 0.6
		for i in 8:
			var a := randf() * TAU
			debris.append(Vector2(cos(a), sin(a)) * randf_range(0.6, 1.2))
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
	if kind == "boom":
		var r := size * (0.35 + 0.65 * k)
		draw_circle(Vector2.ZERO, r, Color(color, 0.35 * (1.0 - k)))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, c, 3.0)
		for d in debris:
			var p: Vector2 = d * size * k
			draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), Color(Art.METAL_DARK, 1.0 - k))
	else:
		draw_circle(Vector2.ZERO, 3.0 + size * 0.3 * (1.0 - k), c)
