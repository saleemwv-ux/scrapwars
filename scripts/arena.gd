class_name Arena
extends RefCounted
## Arena layout constants and helpers. The player (team 0) is always at the
## bottom of the screen and the opponent (team 1) at the top.

const W := 720.0
const H := 1280.0
const TOP := 60.0
const BOTTOM := 1020.0
const RIVER_Y := 540.0
const RIVER_HALF := 22.0
const BRIDGE_HALF := 34.0
const LANE_X := [160.0, 560.0]
const MID_X := 360.0

const PLAYER := 0
const ENEMY := 1


## -1 = enemy (top) half, 1 = player (bottom) half, 0 = in the river.
static func side_of(y: float) -> int:
	if y < RIVER_Y - RIVER_HALF:
		return -1
	if y > RIVER_Y + RIVER_HALF:
		return 1
	return 0


static func lane_of(x: float) -> int:
	return 0 if x < MID_X else 1


static func mirror_y(y: float) -> float:
	return TOP + BOTTOM - y


## Converts a position written from the player's point of view into the
## same spot on the given team's side of the arena.
static func team_pos(team: int, pos: Vector2) -> Vector2:
	if team == PLAYER:
		return pos
	return Vector2(pos.x, mirror_y(pos.y))


static func team_rect(team: int, r: Rect2) -> Rect2:
	if team == PLAYER:
		return r
	return Rect2(r.position.x, mirror_y(r.position.y + r.size.y), r.size.x, r.size.y)


static func team_color(team: int) -> Color:
	return Color(0.2, 0.6, 1.0) if team == PLAYER else Color(1.0, 0.36, 0.25)


static func bridge_toward(from: Vector2, to: Vector2) -> float:
	var best: float = LANE_X[0]
	var best_d := INF
	for bx in LANE_X:
		var b := Vector2(bx, RIVER_Y)
		var d := from.distance_to(b) + b.distance_to(to)
		if d < best_d:
			best_d = d
			best = bx
	return best


static func nearest_bridge(x: float) -> float:
	return LANE_X[0] if absf(x - LANE_X[0]) < absf(x - LANE_X[1]) else LANE_X[1]
