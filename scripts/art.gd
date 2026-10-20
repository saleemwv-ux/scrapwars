class_name Art
extends RefCounted
## Sprite drawing helpers. Sprites are cut from the Scrapfall concept sheets
## (see tools/extract_sprites.py) and live in res://art/sprites/.

const DARK := Color(0.14, 0.14, 0.16)
const METAL := Color(0.58, 0.6, 0.64)
const METAL_DARK := Color(0.32, 0.33, 0.37)
const RUST := Color(0.6, 0.37, 0.21)
const RUST_DARK := Color(0.4, 0.24, 0.14)
const GLOW := Color(1.0, 0.88, 0.3)
const FLASH := Color(1.9, 1.9, 1.9)

static var _cache := {}


static func tex(name: String) -> Texture2D:
	if not _cache.has(name):
		_cache[name] = load("res://art/sprites/%s.png" % name)
	return _cache[name]


## Draws a sprite so its longer side is `size` pixels. `anchor` is where the
## sprite's bottom centre goes (its feet). `squash` stretches x and shrinks y.
static func draw_sprite(ci: CanvasItem, name: String, anchor: Vector2, size: float,
		flip: bool = false, modulate: Color = Color.WHITE, squash: float = 0.0, tilt: float = 0.0) -> void:
	var t := tex(name)
	if t == null:
		return
	var ts := t.get_size()
	var k := size / maxf(ts.x, ts.y)
	var dims := ts * k * Vector2(1.0 + squash, 1.0 - squash)
	ci.draw_set_transform(anchor, tilt, Vector2(-1.0 if flip else 1.0, 1.0))
	ci.draw_texture_rect(t, Rect2(-dims.x * 0.5, -dims.y, dims.x, dims.y), false, modulate)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Draws a sprite centred on `center`, fitted inside a box of `size`.
static func draw_sprite_centered(ci: CanvasItem, name: String, center: Vector2, size: float,
		rot: float = 0.0, modulate: Color = Color.WHITE) -> void:
	var t := tex(name)
	if t == null:
		return
	var ts := t.get_size()
	var dims := ts * (size / maxf(ts.x, ts.y))
	ci.draw_set_transform(center, rot, Vector2.ONE)
	ci.draw_texture_rect(t, Rect2(-dims * 0.5, dims), false, modulate)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Soft oval shadow on the ground.
static func draw_shadow(ci: CanvasItem, center: Vector2, rx: float, alpha: float = 0.35) -> void:
	ci.draw_set_transform(center, 0.0, Vector2(1.0, 0.4))
	ci.draw_circle(Vector2.ZERO, rx, Color(0, 0, 0, alpha * 0.6))
	ci.draw_circle(Vector2.ZERO, rx * 0.7, Color(0, 0, 0, alpha * 0.5))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


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
