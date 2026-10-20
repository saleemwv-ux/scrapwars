extends Node2D
## A homing shot fired by ranged units and towers, drawn with the shooter's
## faction throwable (scrap rocket, blight rocket or hex orb).

const SPEED := 520.0
## Which way each projectile sprite points in its image, in radians.
const SPRITE_ANGLE := {"scrap_rocket": PI, "blight_rocket": -PI * 0.25, "hex_orb": 0.0}

var game
var team := 0
var target: Entity = null
var target_pos := Vector2.ZERO
var damage := 0.0
var splash := 0.0
var targets := "any"
var color := Color.WHITE
var sprite := ""
var size := 22.0
var spin := false
var age := 0.0
var trail: Array = []


func setup(p_game, p_team: int, from: Vector2, p_target: Entity, p_damage: float, p_splash: float, p_targets: String, p_size: float = 22.0) -> void:
	game = p_game
	team = p_team
	position = from
	target = p_target
	target_pos = p_target.position
	damage = p_damage
	splash = p_splash
	targets = p_targets
	size = p_size
	color = game.faction_color(team)
	sprite = game.faction_data(team)["projectile"]
	spin = sprite == "hex_orb"
	z_index = 10


func _process(delta: float) -> void:
	if not game.is_running():
		return
	age += delta
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
		if splash > 0.0:
			game.spawn_effect("boom", target_pos, splash, color)
		queue_free()
		return
	trail.push_front(position)
	if trail.size() > 6:
		trail.pop_back()
	position += to.normalized() * step
	rotation = to.angle()
	queue_redraw()


func _draw() -> void:
	# Glowing trail (in local space, which is rotated toward the target).
	for i in trail.size():
		var p: Vector2 = (trail[i] - position).rotated(-rotation)
		draw_circle(p, size * 0.22 * (1.0 - i / 7.0), Color(color, 0.35 * (1.0 - i / 6.0)))
	var rot: float = age * 12.0 if spin else -float(SPRITE_ANGLE.get(sprite, 0.0))
	Art.draw_sprite_centered(self, sprite, Vector2.ZERO, size, rot)
