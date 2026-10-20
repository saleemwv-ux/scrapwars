class_name Art
extends RefCounted
## Placeholder art drawn with code: scrap robots, crowns and icons.
## Every shape is drawn around the origin, with `s` roughly the unit radius.

const METAL := Color(0.58, 0.6, 0.64)
const METAL_DARK := Color(0.32, 0.33, 0.37)
const DARK := Color(0.14, 0.14, 0.16)
const RUST := Color(0.6, 0.37, 0.21)
const RUST_DARK := Color(0.4, 0.24, 0.14)
const GLOW := Color(1.0, 0.88, 0.3)
const FIRE := Color(1.0, 0.5, 0.12)


static func draw_unit(ci: CanvasItem, id: String, s: float, col: Color, t: float, facing: Vector2) -> void:
	match id:
		"scrapper":
			_scrapper(ci, s, col, t)
		"archers":
			_archer(ci, s, col, t)
		"giant":
			_giant(ci, s, col, t)
		"drones":
			_drone(ci, s, col, t)
		"gremlins":
			_gremlin(ci, s, col, t)
		"cannon":
			_cannon(ci, s, col, facing)
		"ram":
			_ram(ci, s, col, t, facing)
		"firebomb":
			_bomb(ci, s, t)
		_:
			ci.draw_circle(Vector2.ZERO, s, col)


static func draw_crown(ci: CanvasItem, center: Vector2, s: float, col: Color) -> void:
	var pts := PackedVector2Array([
		center + Vector2(-s, s * 0.5),
		center + Vector2(-s, -s * 0.4),
		center + Vector2(-s * 0.5, s * 0.05),
		center + Vector2(0, -s * 0.7),
		center + Vector2(s * 0.5, s * 0.05),
		center + Vector2(s, -s * 0.4),
		center + Vector2(s, s * 0.5),
	])
	ci.draw_colored_polygon(pts, col)
	ci.draw_polyline(pts + PackedVector2Array([pts[0]]), col.darkened(0.45), 2.0)


static func _scrapper(ci: CanvasItem, s: float, col: Color, t: float) -> void:
	var b := sin(t * 9.0) * s * 0.06
	ci.draw_rect(Rect2(-s * 0.6, s * 0.3, s * 0.4, s * 0.6), DARK)
	ci.draw_rect(Rect2(s * 0.2, s * 0.3, s * 0.4, s * 0.6), DARK)
	ci.draw_rect(Rect2(-s * 0.8, -s * 0.55 + b, s * 1.6, s * 1.0), METAL)
	ci.draw_rect(Rect2(-s * 0.55, -s * 0.38 + b, s * 1.1, s * 0.62), col)
	ci.draw_rect(Rect2(-s * 0.45, -s * 1.05 + b, s * 0.9, s * 0.5), METAL_DARK)
	ci.draw_rect(Rect2(-s * 0.32, -s * 0.9 + b, s * 0.64, s * 0.16), GLOW)
	var swing := sin(t * 6.0) * 0.4
	var hand := Vector2(s * 0.95, -s * 0.15 + b)
	var tip := hand + Vector2(cos(-1.2 + swing), sin(-1.2 + swing)) * s * 0.9
	ci.draw_line(hand, tip, METAL_DARK, s * 0.22)
	ci.draw_circle(tip, s * 0.24, METAL)
	ci.draw_circle(tip, s * 0.1, DARK)


static func _archer(ci: CanvasItem, s: float, col: Color, t: float) -> void:
	var b := sin(t * 8.0) * s * 0.05
	ci.draw_rect(Rect2(-s * 0.45, s * 0.3, s * 0.3, s * 0.6), DARK)
	ci.draw_rect(Rect2(s * 0.15, s * 0.3, s * 0.3, s * 0.6), DARK)
	ci.draw_rect(Rect2(-s * 0.55, -s * 0.5 + b, s * 1.1, s * 0.9), col)
	ci.draw_rect(Rect2(-s * 0.55, -s * 0.5 + b, s * 1.1, s * 0.9), METAL_DARK, false, 1.5)
	ci.draw_circle(Vector2(0, -s * 0.85 + b), s * 0.38, METAL)
	ci.draw_circle(Vector2(0, -s * 0.85 + b), s * 0.15, GLOW)
	ci.draw_line(Vector2(0, -s * 1.2 + b), Vector2(s * 0.25, -s * 1.6 + b), METAL_DARK, 1.5)
	# Bow made from a bent pipe.
	ci.draw_arc(Vector2(s * 0.75, -s * 0.1 + b), s * 0.7, -1.2, 1.2, 12, METAL_DARK, s * 0.15)
	ci.draw_line(Vector2(s * 0.75 + cos(-1.2) * s * 0.7, -s * 0.1 + b + sin(-1.2) * s * 0.7),
		Vector2(s * 0.75 + cos(1.2) * s * 0.7, -s * 0.1 + b + sin(1.2) * s * 0.7), GLOW, 1.0)


static func _giant(ci: CanvasItem, s: float, col: Color, t: float) -> void:
	var b := sin(t * 4.0) * s * 0.04
	ci.draw_rect(Rect2(-s * 0.7, s * 0.35, s * 0.5, s * 0.6), DARK)
	ci.draw_rect(Rect2(s * 0.2, s * 0.35, s * 0.5, s * 0.6), DARK)
	ci.draw_rect(Rect2(-s * 0.9, -s * 0.75 + b, s * 1.8, s * 1.2), RUST)
	ci.draw_rect(Rect2(-s * 0.9, -s * 0.75 + b, s * 1.8, s * 1.2), RUST_DARK, false, 2.0)
	ci.draw_rect(Rect2(-s * 1.15, -s * 0.8 + b, s * 0.4, s * 0.45), col)
	ci.draw_rect(Rect2(s * 0.75, -s * 0.8 + b, s * 0.4, s * 0.45), col)
	ci.draw_rect(Rect2(-s * 1.1, -s * 0.35 + b, s * 0.3, s * 0.8), METAL_DARK)
	ci.draw_rect(Rect2(s * 0.8, -s * 0.35 + b, s * 0.3, s * 0.8), METAL_DARK)
	for i in 3:
		ci.draw_circle(Vector2(-s * 0.5 + i * s * 0.5, s * 0.25 + b), s * 0.07, RUST_DARK)
	ci.draw_rect(Rect2(-s * 0.4, -s * 1.05 + b, s * 0.8, s * 0.35), METAL_DARK)
	ci.draw_circle(Vector2(-s * 0.18, -s * 0.88 + b), s * 0.08, Color(1, 0.2, 0.15))
	ci.draw_circle(Vector2(s * 0.18, -s * 0.88 + b), s * 0.08, Color(1, 0.2, 0.15))


static func _drone(ci: CanvasItem, s: float, col: Color, t: float) -> void:
	var a := t * 25.0
	for arm in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var hub: Vector2 = arm * s * 0.75
		ci.draw_line(Vector2.ZERO, hub, METAL_DARK, s * 0.15)
		var r := Vector2(cos(a), sin(a)) * s * 0.45
		ci.draw_line(hub - r, hub + r, Color(METAL, 0.8), 1.5)
	ci.draw_circle(Vector2.ZERO, s * 0.55, col)
	ci.draw_arc(Vector2.ZERO, s * 0.55, 0.0, TAU, 16, METAL_DARK, 1.5)
	ci.draw_circle(Vector2(0, s * 0.05), s * 0.2, GLOW)


static func _gremlin(ci: CanvasItem, s: float, col: Color, t: float) -> void:
	var spin := t * 6.0
	for i in 8:
		var a := spin + i * TAU / 8.0
		var p := Vector2(cos(a), sin(a)) * s * 0.85
		ci.draw_circle(p, s * 0.22, METAL_DARK)
	ci.draw_circle(Vector2.ZERO, s * 0.8, METAL)
	ci.draw_circle(Vector2.ZERO, s * 0.55, col)
	ci.draw_circle(Vector2(-s * 0.2, -s * 0.12), s * 0.14, GLOW)
	ci.draw_circle(Vector2(s * 0.2, -s * 0.12), s * 0.14, GLOW)


static func _cannon(ci: CanvasItem, s: float, col: Color, facing: Vector2) -> void:
	ci.draw_rect(Rect2(-s, -s * 0.6, s * 2.0, s * 1.4), METAL_DARK)
	ci.draw_rect(Rect2(-s, -s * 0.6, s * 2.0, s * 0.3), col)
	var dir := facing.normalized() if facing.length() > 0.1 else Vector2.UP
	ci.draw_line(Vector2.ZERO, dir * s * 1.2, DARK, s * 0.45)
	ci.draw_circle(Vector2.ZERO, s * 0.55, METAL)
	# Horseshoe magnet on top.
	ci.draw_arc(Vector2.ZERO, s * 0.3, PI, TAU, 10, Color(0.9, 0.2, 0.2), s * 0.14)


static func _ram(ci: CanvasItem, s: float, col: Color, t: float, facing: Vector2) -> void:
	var dir := facing.normalized() if facing.length() > 0.1 else Vector2.UP
	var side := Vector2(-dir.y, dir.x)
	var wheel_spin := t * 12.0
	for w in [-1.0, 1.0]:
		for f in [-0.5, 0.5]:
			var wp: Vector2 = side * s * 0.75 * w + dir * s * f
			ci.draw_circle(wp, s * 0.28, DARK)
			ci.draw_line(wp, wp + Vector2(cos(wheel_spin), sin(wheel_spin)) * s * 0.25, METAL_DARK, 1.5)
	var body := PackedVector2Array([
		dir * s * 1.25,
		dir * s * 0.4 + side * s * 0.65,
		-dir * s * 0.8 + side * s * 0.65,
		-dir * s * 0.8 - side * s * 0.65,
		dir * s * 0.4 - side * s * 0.65,
	])
	ci.draw_colored_polygon(body, METAL)
	ci.draw_circle(dir * s * 1.1, s * 0.25, METAL_DARK)
	ci.draw_circle(-dir * s * 0.2, s * 0.35, col)


static func _bomb(ci: CanvasItem, s: float, t: float) -> void:
	ci.draw_circle(Vector2.ZERO, s, DARK)
	ci.draw_circle(Vector2(-s * 0.3, -s * 0.3), s * 0.25, METAL_DARK)
	ci.draw_line(Vector2(s * 0.5, -s * 0.7), Vector2(s * 0.9, -s * 1.2), RUST, 2.0)
	var flick := 0.6 + 0.4 * sin(t * 3.0)
	ci.draw_circle(Vector2(s * 0.95, -s * 1.3), s * 0.3 * flick, FIRE)
	ci.draw_circle(Vector2(s * 0.95, -s * 1.3), s * 0.14, GLOW)
