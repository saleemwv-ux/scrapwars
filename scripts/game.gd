extends Node2D
## ScrapWars match controller: arena, towers, elixir, hands, deploying cards,
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
	_setup_decks()
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


func _setup_decks() -> void:
	for team in 2:
		var d: Array = Cards.DECK.duplicate()
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
		print("AUTOTEST_RESULT winner=%d crowns=%d-%d time_left=%.1f overtime=%s played=%d/%d" % [
			winner, crowns[0], crowns[1], time_left, overtime, cards_played[0], cards_played[1]])
		get_tree().quit(0)


func on_entity_died(e: Entity) -> void:
	entities.erase(e)
	spawn_effect("boom", e.position, e.radius * 1.8, Color(1.0, 0.7, 0.3))
	if not (e is Tower) or state != State.PLAYING:
		return
	var tower := e as Tower
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
	p.setup(self, source.team, source.position + Vector2(0, -source.radius * 0.6), target, damage, splash, targets)
	world.add_child(p)


func spawn_effect(kind: String, pos: Vector2, size: float, color: Color) -> void:
	var fx := EffectScript.new()
	fx.setup(kind, pos, size, color)
	world.add_child(fx)


func deal_damage(team: int, target: Entity, damage: float, splash: float, targets: String, at: Vector2) -> void:
	if splash <= 0.0:
		if target != null and is_instance_valid(target) and target.alive:
			spawn_effect("hit", at, 10.0, Color(1, 1, 0.8))
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
	var top := Arena.TOP
	var bottom := Arena.BOTTOM
	draw_rect(Rect2(0, top, Arena.W, Arena.RIVER_Y - top), Color(0.44, 0.36, 0.27))
	draw_rect(Rect2(0, Arena.RIVER_Y, Arena.W, bottom - Arena.RIVER_Y), Color(0.41, 0.36, 0.28))
	var tile := 40.0
	for gx in int(Arena.W / tile):
		for gy in int((bottom - top) / tile):
			if (gx + gy) % 2 == 0:
				draw_rect(Rect2(gx * tile, top + gy * tile, tile, tile), Color(1, 1, 1, 0.025))
	for lx in Arena.LANE_X:
		draw_rect(Rect2(lx - 28.0, top + 30.0, 56.0, bottom - top - 60.0), Color(0.3, 0.25, 0.19, 0.45))
	# Scattered scrap.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	var scrap_colors := [Art.METAL_DARK, Art.RUST_DARK, Art.METAL, Art.RUST]
	for i in 70:
		var p := Vector2(rng.randf_range(8.0, Arena.W - 8.0), rng.randf_range(top + 8.0, bottom - 8.0))
		var s := rng.randf_range(3.0, 9.0)
		var c: Color = scrap_colors[rng.randi() % scrap_colors.size()]
		var keep_clear := absf(p.y - Arena.RIVER_Y) < 45.0
		for lx in Arena.LANE_X:
			if absf(p.x - lx) < 34.0:
				keep_clear = true
		if keep_clear:
			continue
		draw_set_transform(p, rng.randf() * PI, Vector2.ONE)
		draw_rect(Rect2(-s, -s * 0.5, s * 2.0, s), Color(c, 0.75))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Oil sludge river.
	var rt := Arena.RIVER_Y - Arena.RIVER_HALF
	draw_rect(Rect2(0, rt, Arena.W, Arena.RIVER_HALF * 2.0), Color(0.14, 0.24, 0.2))
	for x in range(0, int(Arena.W), 36):
		var y := Arena.RIVER_Y + sin(x * 0.3) * 6.0
		draw_line(Vector2(x, y), Vector2(x + 16, y + 2), Color(0.35, 0.5, 0.3, 0.6), 2.0)
	draw_line(Vector2(0, rt), Vector2(Arena.W, rt), Color(0, 0, 0, 0.5), 3.0)
	draw_line(Vector2(0, rt + Arena.RIVER_HALF * 2.0), Vector2(Arena.W, rt + Arena.RIVER_HALF * 2.0), Color(0, 0, 0, 0.5), 3.0)
	# Metal plate bridges.
	for lx in Arena.LANE_X:
		var bw := Arena.BRIDGE_HALF * 2.0
		var r := Rect2(lx - Arena.BRIDGE_HALF, rt - 8.0, bw, Arena.RIVER_HALF * 2.0 + 16.0)
		draw_rect(r, Art.METAL_DARK)
		for k in 5:
			var py: float = r.position.y + 6.0 + k * 11.0
			draw_line(Vector2(r.position.x + 3, py), Vector2(r.end.x - 3, py), Art.METAL, 1.5)
		draw_rect(r, Art.DARK, false, 3.0)
	draw_rect(Rect2(0, top, Arena.W, bottom - top), Color(0, 0, 0, 0.6), false, 4.0)
