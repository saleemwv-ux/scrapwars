class_name Unit
extends Entity
## A troop or building spawned from a card. Troops walk down their lane,
## cross at a bridge and fight whatever enemy they can target.

const DEPLOY_TIME := 1.0
const MELEE_MAX_RANGE := 45.0
const AIR_HEIGHT := 22.0
const ATTACK_ANIM_TIME := 0.28

var id := ""
var card: Dictionary = {}
var speed := 60.0
var damage := 100.0
var hit_speed := 1.0
var attack_range := 14.0
var sight := 200.0
var targets := "any"
var splash := 0.0
var lifetime := 0.0
var deploy_timer := DEPLOY_TIME
var attack_timer := 0.0
var retarget_timer := 0.0
var target: Entity = null
var locked := false
var anim_t := 0.0
var facing := Vector2.UP
var flip := false
var attack_anim := 0.0
var moving := false
var kamikaze := false
var size := 56.0


func setup(p_game, p_team: int, p_id: String, p_pos: Vector2) -> void:
	game = p_game
	team = p_team
	id = p_id
	card = Cards.get_card(p_id)
	position = p_pos
	max_hp = card["hp"]
	hp = max_hp
	speed = card["speed"]
	damage = card["damage"]
	hit_speed = card["hit_speed"]
	attack_range = card["range"]
	sight = card["sight"]
	targets = card["targets"]
	splash = card["splash"]
	radius = card["radius"]
	is_air = card["air"]
	is_building = card["type"] == "building"
	lifetime = card["lifetime"]
	kamikaze = card["kamikaze"]
	size = card["size"]
	facing = Vector2.UP if team == Arena.PLAYER else Vector2.DOWN
	anim_t = randf() * 10.0
	z_index = 3 if is_air else 0


func _process(delta: float) -> void:
	hit_flash = maxf(0.0, hit_flash - delta)
	attack_anim = maxf(0.0, attack_anim - delta)
	queue_redraw()
	if not game.is_running():
		return
	anim_t += delta
	moving = false
	if deploy_timer > 0.0:
		deploy_timer -= delta
		return
	if lifetime > 0.0:
		hp -= max_hp / lifetime * delta
		if hp <= 0.0:
			die()
			return

	attack_timer = maxf(0.0, attack_timer - delta)
	if target != null and (not is_instance_valid(target) or not target.alive):
		target = null
		locked = false
	retarget_timer -= delta
	if target == null or (not locked and retarget_timer <= 0.0):
		retarget_timer = 0.25
		target = _find_target()
	if target == null:
		return

	var dist := position.distance_to(target.position)
	var reach := attack_range + radius + target.radius
	if dist <= reach:
		if not locked:
			locked = true
			attack_timer = maxf(attack_timer, hit_speed * 0.35)
		facing = (target.position - position).normalized()
		if attack_timer <= 0.0:
			attack_timer = hit_speed
			_attack()
	else:
		if locked and dist > reach + 20.0:
			locked = false
		if speed > 0.0:
			_move_toward_target(delta)


func _find_target() -> Entity:
	var best: Entity = null
	var best_d := INF
	for e in game.entities:
		if not is_instance_valid(e) or not e.alive or e.team == team:
			continue
		if not Entity.targets_allow(targets, e):
			continue
		var d: float = position.distance_to(e.position) - e.radius
		if d <= sight and d < best_d:
			best = e
			best_d = d
	if best != null or speed <= 0.0:
		return best
	return game.default_tower_target(team, position)


func _attack() -> void:
	attack_anim = ATTACK_ANIM_TIME
	if kamikaze:
		game.deal_area(team, position, splash, damage, 1.0, "any")
		game.spawn_effect("boom", position, splash * 1.4, game.faction_color(team))
		die()
		return
	if attack_range > MELEE_MAX_RANGE:
		game.spawn_projectile(self, target, damage, splash, targets)
	else:
		game.deal_damage(team, target, damage, splash, targets, target.position)


func _move_toward_target(delta: float) -> void:
	var goal := target.position
	if not is_air:
		goal = _path_point(goal)
	var to := goal - position
	if to.length() > 1.0:
		var dir := to.normalized()
		facing = dir
		moving = true
		position += dir * minf(speed * delta, to.length())


## Ground units can only cross the river on a bridge, so pick a waypoint.
func _path_point(goal: Vector2) -> Vector2:
	var my_side := Arena.side_of(position.y)
	var goal_side := Arena.side_of(goal.y)
	if my_side == goal_side:
		return goal
	var bank := Arena.RIVER_HALF + 12.0
	if my_side == 0:
		# Already on a bridge: walk straight off it toward the goal's side.
		var bx := Arena.nearest_bridge(position.x)
		return Vector2(bx, Arena.RIVER_Y + goal_side * bank)
	var bridge_x := Arena.bridge_toward(position, goal)
	if absf(position.x - bridge_x) > 8.0:
		return Vector2(bridge_x, Arena.RIVER_Y + my_side * bank)
	if goal_side == 0:
		return goal
	return Vector2(bridge_x, Arena.RIVER_Y - my_side * bank)


func _draw() -> void:
	var col := Arena.team_color(team)
	if absf(facing.x) > 0.25:
		flip = facing.x < 0.0
	var lift := 0.0
	if is_air:
		lift = -AIR_HEIGHT + sin(anim_t * 3.0) * 3.0
	var feet := Vector2(0, radius * 0.6)
	# Shadow and team ring at the feet.
	Art.draw_shadow(self, feet, radius * (1.5 if is_air else 1.3), 0.3 if is_air else 0.45)
	if not is_air:
		draw_set_transform(feet, 0.0, Vector2(1.0, 0.42))
		draw_arc(Vector2.ZERO, radius * 1.25, 0.0, TAU, 28, Color(col, 0.9), 3.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Walk bob, idle breathing and an attack squash with a lunge.
	var bob := 0.0
	var tilt := 0.0
	var squash := sin(anim_t * 2.4) * 0.015
	if moving and not is_building:
		bob = -absf(sin(anim_t * 7.0)) * size * 0.05
		tilt = sin(anim_t * 7.0) * 0.05
	var lunge := Vector2.ZERO
	if attack_anim > 0.0:
		var k := sin((1.0 - attack_anim / ATTACK_ANIM_TIME) * PI)
		squash += 0.14 * k
		if attack_range <= MELEE_MAX_RANGE and not is_building:
			lunge = facing * 7.0 * k
	var mod := Color.WHITE
	if hit_flash > 0.0:
		mod = Art.FLASH
	var deploying := deploy_timer > 0.0
	var drop := 0.0
	if deploying:
		var dk := 1.0 - deploy_timer / DEPLOY_TIME
		drop = -(1.0 - minf(1.0, dk * 3.0)) * 40.0
		mod = Color(1, 1, 1, 0.55 + 0.45 * dk)
	Art.draw_sprite(self, id, feet + Vector2(0, lift + bob + drop) + lunge, size, flip, mod, squash, tilt)
	if deploying:
		var k2 := 1.0 - deploy_timer / DEPLOY_TIME
		draw_arc(Vector2(0, lift), radius + 8.0, -PI * 0.5, -PI * 0.5 + TAU * k2, 24, Color.WHITE, 2.0)
	var ts := Art.tex(id).get_size()
	var height := size * ts.y / maxf(ts.x, ts.y)
	draw_hp_bar(maxf(28.0, radius * 2.2), feet.y + lift - height - 8.0)
