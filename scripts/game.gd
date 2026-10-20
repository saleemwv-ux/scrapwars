extends Node2D
## Scrapfall match controller: arena, towers, elixir, hands, deploying cards,
## damage, collisions and win conditions.
##
## Run with `-- --autotest` to watch two AIs play a full match without input
## (handy for headless checks: godot --headless --fixed-fps 60 -- --autotest).

enum State { READY, PLAYING, OVER }

const MATCH_TIME := 180.0
const OVERTIME_TIME := 60.0
const DOUBLE_ELIXIR_AT := 60.0
const ELIXIR_MAX := 10.0
const ELIXIR_PER_SEC := 1.0 / 2.8
const START_ELIXIR := 5.0
const HAND_SIZE := 4

const ProjectileScript := preload("res://scripts/projectile.gd")
const SpellScript := preload("res://scripts/spell.gd")
const EffectScript := preload("res://scripts/effect.gd")
const AIScript := preload("res://scripts/ai.gd")
const HudScript := preload("res://scripts/hud.gd")
const ARENA_TEX := preload("res://art/arena.png")

var state: State = State.READY
var time_left := MATCH_TIME
var overtime := false
var winner := -1
var over_time := 0.0
var entities: Array = []
var towers: Array = [[], []]
var kings: Array = [null, null]
var elixir: Array = [START_ELIXIR, START_ELIXIR]
var hands: Array = [[], []]
var decks: Array = [[], []]
var crowns: Array = [0, 0]
var cards_played: Array = [0, 0]
var factions: Array = ["scrappers", "infected"]
var ruins: Array = []  # [position, radius] of destroyed towers.
var autotest := false
var autotest_clock := 0.0

var world: Node2D
var hud


func _ready() -> void:
	randomize()
	autotest = OS.get_cmdline_user_args().has("--autotest")
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = HudScript.new()
	hud.game = self
	layer.add_child(hud)
	_setup_towers()
	set_player_faction(Cards.FACTION_IDS[randi() % Cards.FACTION_IDS.size()] if autotest else "scrappers")
	_add_ai(Arena.ENEMY)
	if autotest:
		_add_ai(Arena.PLAYER)
		start_match()


func _add_ai(team: int) -> void:
	var ai := AIScript.new()
	ai.game = self
	ai.team = team
	add_child(ai)


func _setup_towers() -> void:
	for team in 2:
		var king := Tower.new()
		king.setup(self, team, "king", Arena.team_pos(team, Vector2(Arena.MID_X, 950.0)), -1)
		_add_entity(king)
		kings[team] = king
		towers[team].append(king)
		for lane in 2:
			var t := Tower.new()
			t.setup(self, team, "princess", Arena.team_pos(team, Vector2(Arena.LANE_X[lane], 850.0)), lane)
			_add_entity(t)
			towers[team].append(t)


## Picks the player's faction; the computer takes one of the other two.
func set_player_faction(id: String) -> void:
	var others: Array = Cards.FACTION_IDS.filter(func(f): return f != id)
	factions = [id, others[randi() % others.size()]]
	_setup_decks()
	for team in 2:
		for t in towers[team]:
			if is_instance_valid(t):
				t.sprite = faction_data(team)["king" if t.kind == "king" else "princess"]


func faction_data(team: int) -> Dictionary:
	return Cards.faction(factions[team])


func faction_color(team: int) -> Color:
	return faction_data(team)["color"]


func _setup_decks() -> void:
	for team in 2:
		var d: Array = faction_data(team)["deck"].duplicate()
		d.shuffle()
		hands[team] = d.slice(0, HAND_SIZE)
		decks[team] = d.slice(HAND_SIZE)


func _add_entity(e: Entity) -> void:
	entities.append(e)
	world.add_child(e)


# --- Match flow ------------------------------------------------------------

func start_match() -> void:
	state = State.PLAYING


func restart() -> void:
	get_tree().reload_current_scene()


func is_running() -> bool:
	return state == State.PLAYING


func is_ready_screen() -> bool:
	return state == State.READY


func is_over() -> bool:
	return state == State.OVER


func is_double_elixir() -> bool:
	return overtime or time_left <= DOUBLE_ELIXIR_AT


func _process(delta: float) -> void:
	if autotest:
		autotest_clock += delta
		if autotest_clock > MATCH_TIME + OVERTIME_TIME + 30.0:
			push_error("AUTOTEST: match did not finish")
			get_tree().quit(1)
	if state != State.PLAYING:
		return
	time_left -= delta
	var rate := ELIXIR_PER_SEC * (2.0 if is_double_elixir() else 1.0)
	for team in 2:
		elixir[team] = minf(ELIXIR_MAX, elixir[team] + rate * delta)
	_resolve_collisions()
	if time_left <= 0.0:
		time_left = 0.0
		_on_time_up()


func _on_time_up() -> void:
	if crowns[0] != crowns[1]:
		_end_match(0 if crowns[0] > crowns[1] else 1)
		return
	if not overtime:
		overtime = true
		time_left = OVERTIME_TIME
		hud.show_message("OVERTIME! Next crown wins", 2.5)
		return
	# Tie-breaker: the side whose weakest tower is lowest loses.
	var low0 := _lowest_tower_hp(0)
	var low1 := _lowest_tower_hp(1)
	if is_equal_approx(low0, low1):
		_end_match(-1)
	else:
		_end_match(0 if low0 > low1 else 1)


func _lowest_tower_hp(team: int) -> float:
	var low := INF
	for t in towers[team]:
		if is_instance_valid(t) and t.alive:
			low = minf(low, t.hp)
	return 0.0 if low == INF else low


func _end_match(w: int) -> void:
	if state == State.OVER:
		return
	state = State.OVER
	winner = w
	over_time = Time.get_ticks_msec() / 1000.0
	if autotest:
		print("AUTOTEST_RESULT winner=%d crowns=%d-%d time_left=%.1f overtime=%s played=%d/%d factions=%s/%s" % [
			winner, crowns[0], crowns[1], time_left, overtime, cards_played[0], cards_played[1], factions[0], factions[1]])
		get_tree().quit(0)


func on_entity_died(e: Entity) -> void:
	entities.erase(e)
	spawn_effect("boom", e.position, e.radius * (2.6 if e is Tower else 1.8), faction_color(e.team).lerp(Color(1.0, 0.7, 0.3), 0.5))
	if not (e is Tower) or state != State.PLAYING:
		return
	var tower := e as Tower
	ruins.append([tower.position, tower.radius])
	queue_redraw()
	var scorer := 1 - tower.team
	if tower.kind == "king":
		crowns[scorer] = 3
		_end_match(scorer)
		return
	crowns[scorer] += 1
	var king = kings[tower.team]
	if is_instance_valid(king) and king.alive:
		king.activate()
	if overtime:
		_end_match(scorer)


# --- Cards -----------------------------------------------------------------

func can_afford(team: int, id: String) -> bool:
	return elixir[team] >= Cards.get_card(id)["cost"]


## Plays the card in hand slot `slot` at `pos`. Returns true on success.
func play_card(team: int, slot: int, pos: Vector2) -> bool:
	if not is_running() or slot < 0 or slot >= hands[team].size():
		return false
	var id: String = hands[team][slot]
	var card := Cards.get_card(id)
	if elixir[team] < card["cost"]:
		return false
	if not is_valid_drop(team, id, pos):
		return false
	elixir[team] -= card["cost"]
	cards_played[team] += 1
	_spawn_card(team, id, pos)
	hands[team][slot] = decks[team].pop_front()
	decks[team].push_back(id)
	return true


func next_card(team: int) -> String:
	return decks[team][0]


func drop_zones(team: int, id: String) -> Array:
	if Cards.get_card(id)["type"] == "spell":
		return [Rect2(0, Arena.TOP, Arena.W, Arena.BOTTOM - Arena.TOP)]
	var own_edge := Arena.RIVER_Y + Arena.RIVER_HALF + 6.0
	var zones := [Arena.team_rect(team, Rect2(0, own_edge, Arena.W, Arena.BOTTOM - own_edge))]
	# Destroying a princess tower unlocks a pocket on that side of the map.
	for lane in 2:
		if not princess_alive(1 - team, lane):
			var x := 0.0 if lane == 0 else Arena.MID_X
			var pocket_top := 330.0
			zones.append(Arena.team_rect(team, Rect2(x, pocket_top, Arena.MID_X, Arena.RIVER_Y - Arena.RIVER_HALF - pocket_top)))
	return zones


func is_valid_drop(team: int, id: String, pos: Vector2) -> bool:
	var inside := false
	for z in drop_zones(team, id):
		if z.has_point(pos):
			inside = true
			break
	if not inside:
		return false
	if Cards.get_card(id)["type"] != "spell":
		for e in entities:
			if e is Tower and e.alive and pos.distance_to(e.position) < e.radius:
				return false
	return true


func princess_alive(team: int, lane: int) -> bool:
	for t in towers[team]:
		if is_instance_valid(t) and t.alive and t.kind == "princess" and t.lane == lane:
			return true
	return false


func _spawn_card(team: int, id: String, pos: Vector2) -> void:
	var card := Cards.get_card(id)
	if card["type"] == "spell":
		var s := SpellScript.new()
		s.setup(self, team, id, kings[team].position, pos)
		world.add_child(s)
		return
	var count: int = card["count"]
	var spread: float = card["radius"] * 1.8
	for i in count:
		var off := Vector2.ZERO
		if count > 1:
			var a := TAU * i / count + PI * 0.25
			off = Vector2(cos(a), sin(a)) * spread
		var u := Unit.new()
		u.setup(self, team, id, pos + off)
		_add_entity(u)


# --- Combat ----------------------------------------------------------------

func default_tower_target(team: int, pos: Vector2) -> Entity:
	var enemy := 1 - team
	var lane := Arena.lane_of(pos.x)
	for t in towers[enemy]:
		if is_instance_valid(t) and t.alive and t.kind == "princess" and t.lane == lane:
			return t
	var king = kings[enemy]
	if is_instance_valid(king) and king.alive:
		return king
	return null


func spawn_projectile(source: Entity, target: Entity, damage: float, splash: float, targets: String) -> void:
	var p := ProjectileScript.new()
	var from := source.position + Vector2(0, -source.radius * (2.2 if source is Tower else 1.4))
	p.setup(self, source.team, from, target, damage, splash, targets, 30.0 if source is Tower else 20.0)
	world.add_child(p)


func spawn_effect(kind: String, pos: Vector2, size: float, color: Color) -> void:
	var fx := EffectScript.new()
	fx.setup(kind, pos, size, color)
	world.add_child(fx)


func deal_damage(team: int, target: Entity, damage: float, splash: float, targets: String, at: Vector2) -> void:
	if splash <= 0.0:
		if target != null and is_instance_valid(target) and target.alive:
			spawn_effect("hit", at, 12.0, faction_color(team).lightened(0.4))
			target.take_damage(damage)
		return
	deal_area(team, at, splash, damage, 1.0, targets)


func deal_area(team: int, at: Vector2, area: float, damage: float, tower_mult: float, targets: String = "any") -> void:
	for e in entities.duplicate():
		if not is_instance_valid(e) or not e.alive or e.team == team:
			continue
		if not Entity.targets_allow(targets, e):
			continue
		if e.position.distance_to(at) <= area + e.radius:
			e.take_damage(damage * (tower_mult if e is Tower else 1.0))


func _resolve_collisions() -> void:
	var n := entities.size()
	for i in n:
		var a: Entity = entities[i]
		for j in range(i + 1, n):
			var b: Entity = entities[j]
			if a.is_air != b.is_air or (a.is_building and b.is_building):
				continue
			var d := b.position - a.position
			var min_d := a.radius + b.radius
			var dist := d.length()
			if dist >= min_d:
				continue
			if dist < 0.01:
				d = Vector2(randf() - 0.5, randf() - 0.5)
				dist = d.length()
			var nrm := d / dist
			var push := (min_d - dist) * 0.5
			if a.is_building:
				_slide(b, nrm, push * 2.0)
			elif b.is_building:
				_slide(a, -nrm, push * 2.0)
			else:
				a.position -= nrm * push
				b.position += nrm * push
	for e in entities:
		if e.is_building:
			continue
		var r: float = e.radius
		e.position.x = clampf(e.position.x, r, Arena.W - r)
		e.position.y = clampf(e.position.y, Arena.TOP + r, Arena.BOTTOM - r)
		if not e.is_air and Arena.side_of(e.position.y) == 0:
			var bx := Arena.nearest_bridge(e.position.x)
			var half := Arena.BRIDGE_HALF - r
			e.position.x = clampf(e.position.x, bx - half, bx + half)


## Pushes a unit out of a building and nudges it sideways so it walks around.
func _slide(u: Entity, away: Vector2, amount: float) -> void:
	u.position += away * amount
	if u is Unit:
		var perp := Vector2(-away.y, away.x)
		if perp.dot((u as Unit).facing) < 0.0:
			perp = -perp
		u.position += perp * amount * 0.6


# --- Arena art -------------------------------------------------------------

func _draw() -> void:
	# Painted by tools/make_arena.py.
	draw_texture(ARENA_TEX, Vector2(0, Arena.TOP))
	# Scorched rubble where towers fell.
	for ruin in ruins:
		var p: Vector2 = ruin[0] + Vector2(0, ruin[1] * 0.6)
		var r: float = ruin[1]
		draw_set_transform(p, 0.0, Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, r * 1.4, Color(0.05, 0.04, 0.03, 0.55))
		draw_circle(Vector2.ZERO, r * 0.9, Color(0.1, 0.08, 0.06, 0.6))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var rng := RandomNumberGenerator.new()
		rng.seed = int(p.x * 31.0 + p.y)
		for i in 14:
			var a := rng.randf() * TAU
			var d := rng.randf() * r
			var q := p + Vector2(cos(a) * d, sin(a) * d * 0.55)
			var s := rng.randf_range(3.0, 8.0)
			draw_set_transform(q, rng.randf() * PI, Vector2.ONE)
			draw_rect(Rect2(-s, -s * 0.6, s * 2.0, s * 1.2), [Art.METAL_DARK, Art.RUST_DARK, Art.DARK][i % 3])
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(0, Arena.TOP, Arena.W, Arena.BOTTOM - Arena.TOP), Color(0, 0, 0, 0.6), false, 4.0)
