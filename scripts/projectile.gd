extends Node2D
## A homing bolt fired by ranged units and towers.

const SPEED := 520.0

var game
var team := 0
var target: Entity = null
var target_pos := Vector2.ZERO
var damage := 0.0
var splash := 0.0
var targets := "any"
var color := Color.WHITE


func setup(p_game, p_team: int, from: Vector2, p_target: Entity, p_damage: float, p_splash: float, p_targets: String) -> void:
	game = p_game
	team = p_team
	position = from
	target = p_target
	target_pos = p_target.position
	damage = p_damage
	splash = p_splash
	targets = p_targets
	color = Arena.team_color(team).lightened(0.4)
	z_index = 10


func _process(delta: float) -> void:
	if not game.is_running():
		return
	var has_target := target != null and is_instance_valid(target) and target.alive
	if has_target:
		target_pos = target.position
	var to := target_pos - position
	var step := SPEED * delta
	if to.length() <= step:
		if has_target:
			game.deal_damage(team, target, damage, splash, targets, target_pos)
		elif splash > 0.0:
			game.deal_damage(team, null, damage, splash, targets, target_pos)
		queue_free()
		return
	position += to.normalized() * step
	rotation = to.angle()
	queue_redraw()


func _draw() -> void:
	draw_line(Vector2(-10, 0), Vector2(4, 0), Color(color, 0.5), 3.0)
	draw_circle(Vector2(4, 0), 4.0, color)
