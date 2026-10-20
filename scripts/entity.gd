class_name Entity
extends Node2D
## Anything with health that can be targeted: units, buildings and towers.

var game
var team := 0
var hp := 100.0
var max_hp := 100.0
var radius := 12.0
var is_building := false
var is_air := false
var alive := true
var hit_flash := 0.0


static func targets_allow(targets: String, e: Entity) -> bool:
	match targets:
		"buildings":
			return e.is_building
		"ground":
			return not e.is_air
	return true


func take_damage(amount: float) -> void:
	if not alive:
		return
	hp -= amount
	hit_flash = 0.12
	_on_damaged()
	if hp <= 0.0:
		die()


func _on_damaged() -> void:
	pass


func die() -> void:
	if not alive:
		return
	alive = false
	hp = 0.0
	game.on_entity_died(self)
	queue_free()


func draw_hp_bar(width: float, y: float, always: bool = false) -> void:
	if not always and hp >= max_hp:
		return
	var r := Rect2(-width * 0.5, y, width, 6.0)
	draw_rect(r.grow(1.0), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(r.position, Vector2(width * clampf(hp / max_hp, 0.0, 1.0), 6.0)), Arena.team_color(team))
