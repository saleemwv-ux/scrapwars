extends Node
## A simple rule-based opponent. Every second or so it looks at the board:
## it defends against troops on its side, throws a Fire Bomb at clumps,
## and otherwise saves elixir to push a lane with a tank plus support.

const TANKS := ["giant", "ram"]
const SUPPORT := ["archers", "drones", "scrapper", "gremlins"]

var game
var team := Arena.ENEMY
var think_timer := 2.0
var attack_threshold := 8.0


func _process(delta: float) -> void:
	if game == null or not game.is_running():
		return
	think_timer -= delta
	if think_timer > 0.0:
		return
	think_timer = randf_range(0.5, 1.1)
	_think()


func _think() -> void:
	var threats := _threats()
	if not threats.is_empty() and _defend(threats):
		return
	if _try_fire_bomb():
		return
	if _support_push():
		return
	_attack()


# --- Helpers ---------------------------------------------------------------

func _elixir() -> float:
	return game.elixir[team]


func _hand() -> Array:
	return game.hands[team]


func _slot_of(id: String) -> int:
	if not game.can_afford(team, id):
		return -1
	return _hand().find(id)


## Converts a position given from this AI's point of view (own side at the
## bottom, like the player) into world coordinates.
func _p(pos: Vector2) -> Vector2:
	return Arena.team_pos(team, pos)


func _on_my_side(pos: Vector2) -> bool:
	if team == Arena.PLAYER:
		return pos.y > Arena.RIVER_Y - 60.0
	return pos.y < Arena.RIVER_Y + 60.0


func _threats() -> Array:
	var list := []
	for e in game.entities:
		if e is Unit and e.alive and e.team != team and _on_my_side(e.position):
			list.append(e)
	list.sort_custom(func(a, b): return a.hp > b.hp)
	return list


func _my_hp_near(pos: Vector2, dist: float) -> float:
	var total := 0.0
	for e in game.entities:
		if e is Unit and e.alive and e.team == team and e.position.distance_to(pos) < dist:
			total += e.hp
	return total


## Clamps a world position into this AI's own deploy zone.
func _clamp_own(pos: Vector2) -> Vector2:
	var edge := Arena.RIVER_HALF + 24.0
	pos.x = clampf(pos.x, 24.0, Arena.W - 24.0)
	if team == Arena.PLAYER:
		pos.y = clampf(pos.y, Arena.RIVER_Y + edge, Arena.BOTTOM - 20.0)
	else:
		pos.y = clampf(pos.y, Arena.TOP + 20.0, Arena.RIVER_Y - edge)
	return pos


func _try_play(id: String, pos: Vector2) -> bool:
	var slot := _slot_of(id)
	if slot < 0:
		return false
	if game.play_card(team, slot, pos):
		return true
	# Probably landed on a tower: try a little to the side.
	return game.play_card(team, slot, pos + Vector2(50, 0)) or game.play_card(team, slot, pos - Vector2(50, 0))


# --- Decisions -------------------------------------------------------------

func _defend(threats: Array) -> bool:
	var main: Unit = threats[0]
	var threat_hp := 0.0
	for t in threats:
		threat_hp += t.hp
	if _my_hp_near(main.position, 220.0) >= threat_hp * 0.8:
		return true  # Already handled; keep saving elixir.
	var prefs: Array
	if main.is_air:
		prefs = ["archers", "drones"]
	elif main.targets == "buildings":
		prefs = ["cannon", "gremlins", "scrapper", "drones", "archers"]
	elif threats.size() >= 3:
		prefs = ["archers", "scrapper", "drones", "cannon"]
	else:
		prefs = ["scrapper", "gremlins", "archers", "drones", "cannon"]
	var king: Entity = game.kings[team]
	for id in prefs:
		var pos: Vector2
		if id == "cannon":
			pos = _p(Vector2(Arena.MID_X + randf_range(-30, 30), 760.0))
		else:
			var toward_king := (king.position - main.position).normalized()
			var gap := 140.0 if id == "archers" else 70.0
			pos = _clamp_own(main.position + toward_king * gap)
		if _try_play(id, pos):
			return true
	return false


func _try_fire_bomb() -> bool:
	if _slot_of("firebomb") < 0:
		return false
	var radius: float = Cards.get_card("firebomb")["spell_radius"]
	var best_pos := Vector2.ZERO
	var best_score := 0.0
	for e in game.entities:
		if not (e is Unit) or not e.alive or e.team == team:
			continue
		var count := 0
		var hp := 0.0
		for o in game.entities:
			if o is Unit and o.alive and o.team != team and o.position.distance_to(e.position) < radius * 0.8:
				count += 1
				hp += minf(o.hp, 520.0)
		var score := hp if count >= 3 else 0.0
		if score > best_score:
			best_score = score
			best_pos = e.position + (e as Unit).facing * 25.0
	if best_score >= 600.0:
		return _try_play("firebomb", best_pos)
	# Finish off a weak tower.
	for t in game.towers[1 - team]:
		if is_instance_valid(t) and t.alive and t.hp <= 520.0 * 0.35:
			return _try_play("firebomb", t.position)
	return false


## If one of our tanks is walking to the bridge, back it up.
func _support_push() -> bool:
	if _elixir() < 3.0:
		return false
	for e in game.entities:
		if e is Unit and e.alive and e.team == team and TANKS.has(e.id) and _on_my_side(e.position):
			if _my_hp_near(e.position, 120.0) > e.hp + 200.0:
				continue  # Already has company.
			var behind := _clamp_own(e.position + _p(Vector2(0, 60)) - _p(Vector2.ZERO))
			for id in SUPPORT:
				if _try_play(id, behind):
					return true
	return false


func _attack() -> void:
	if _elixir() < attack_threshold:
		return
	var lane := _weak_lane()
	var lx: float = Arena.LANE_X[lane]
	for id in TANKS:
		var y := 990.0 if id == "giant" else 600.0
		if _try_play(id, _p(Vector2(lx, y))):
			attack_threshold = randf_range(6.5, 10.0)
			return
	for id in SUPPORT:
		if _try_play(id, _p(Vector2(lx + randf_range(-20, 20), 610.0))):
			attack_threshold = randf_range(6.5, 10.0)
			return
	# Nothing useful to push with: drop a cannon so the hand cycles.
	if _elixir() >= 9.5:
		_try_play("cannon", _p(Vector2(Arena.MID_X, 760.0)))


func _weak_lane() -> int:
	var enemy := 1 - team
	var hp := [0.0, 0.0]
	for lane in 2:
		if not game.princess_alive(enemy, lane):
			return lane
	for t in game.towers[enemy]:
		if is_instance_valid(t) and t.alive and t.kind == "princess":
			hp[t.lane] = t.hp
	if absf(hp[0] - hp[1]) < 50.0:
		return randi() % 2
	return 0 if hp[0] < hp[1] else 1
