extends Node2D
## On-screen UI: timer, crowns, the hand of cards, elixir bar, the placement
## preview, and the start / game-over screens.
##
## Controls: tap a card, then tap the arena to deploy it. Dragging a card
## onto the arena works too.

const SLOT_X := [112.0, 264.0, 416.0, 568.0]
const SLOT_Y := 1034.0
const SLOT_W := 142.0
const SLOT_H := 176.0
const NEXT_RECT := Rect2(12, 1070, 86, 112)
const ELIXIR_RECT := Rect2(112, 1226, 598, 34)
const ELIXIR_COLOR := Color(0.86, 0.3, 0.95)
const PANEL := Color(0.13, 0.12, 0.13)
const FACTION_PANEL_Y := [372.0, 622.0, 872.0]
const FACTION_PANEL_SIZE := Vector2(660, 230)

var game
var font: Font
var selected := -1
var dragging := false
var message := ""
var message_timer := 0.0


func _ready() -> void:
	font = ThemeDB.fallback_font


func _process(delta: float) -> void:
	message_timer = maxf(0.0, message_timer - delta)
	queue_redraw()


func show_message(text: String, duration: float = 1.2) -> void:
	message = text
	message_timer = duration


func slot_rect(i: int) -> Rect2:
	return Rect2(SLOT_X[i], SLOT_Y, SLOT_W, SLOT_H)


func _in_arena(p: Vector2) -> bool:
	return p.y > Arena.TOP and p.y < Arena.BOTTOM


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var p := get_global_mouse_position()
	if mb.pressed:
		_on_press(p)
	else:
		_on_release(p)


func faction_panel(i: int) -> Rect2:
	return Rect2(Vector2((Arena.W - FACTION_PANEL_SIZE.x) * 0.5, FACTION_PANEL_Y[i]), FACTION_PANEL_SIZE)


func _on_press(p: Vector2) -> void:
	if game.is_ready_screen():
		for i in Cards.FACTION_IDS.size():
			if faction_panel(i).has_point(p):
				game.set_player_faction(Cards.FACTION_IDS[i])
				game.start_match()
		return
	if game.is_over():
		if Time.get_ticks_msec() / 1000.0 - game.over_time > 1.0:
			game.restart()
		return
	if not game.is_running():
		return
	for i in SLOT_X.size():
		if slot_rect(i).has_point(p):
			if selected == i:
				selected = -1
				dragging = false
			else:
				selected = i
				dragging = true
			return
	if selected >= 0 and _in_arena(p):
		_try_play(p)


func _on_release(p: Vector2) -> void:
	if dragging and selected >= 0 and _in_arena(p):
		_try_play(p)
	dragging = false


func _try_play(p: Vector2) -> void:
	var id: String = game.hands[0][selected]
	if not game.can_afford(Arena.PLAYER, id):
		show_message("Not enough elixir")
		return
	if not game.is_valid_drop(Arena.PLAYER, id, p):
		show_message("Can't deploy there")
		return
	if game.play_card(Arena.PLAYER, selected, p):
		selected = -1


# --- Drawing ---------------------------------------------------------------

func _text(text: String, center_x: float, baseline: float, size: int, color: Color, outline: bool = false) -> void:
	var pos := Vector2(center_x - 360.0, baseline)
	if outline:
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, 720.0, size, 6, Color(0, 0, 0, 0.85))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, 720.0, size, color)


func _draw() -> void:
	_draw_top_bar()
	_draw_preview()
	_draw_bottom_panel()
	if message_timer > 0.0:
		var a := clampf(message_timer * 3.0, 0.0, 1.0)
		_text(message, Arena.MID_X, 600.0, 34, Color(1, 1, 1, a), true)
	if game.is_ready_screen():
		_draw_start_screen()
	elif game.is_over():
		_draw_end_screen()


func _draw_top_bar() -> void:
	draw_rect(Rect2(0, 0, Arena.W, Arena.TOP), Color(PANEL, 0.82))
	var enemy_col := Arena.team_color(Arena.ENEMY)
	var player_col := Arena.team_color(Arena.PLAYER)
	var enemy_name: String = game.faction_data(Arena.ENEMY)["name"]
	var player_name: String = game.faction_data(Arena.PLAYER)["name"]
	draw_string(font, Vector2(14, 25), "AI · " + enemy_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, enemy_col)
	draw_string(font, Vector2(Arena.W - 314, 25), "YOU · " + player_name.to_upper(), HORIZONTAL_ALIGNMENT_RIGHT, 300, 18, player_col)
	for i in 3:
		var got_enemy: bool = i < game.crowns[Arena.ENEMY]
		var got_player: bool = i < game.crowns[Arena.PLAYER]
		Art.draw_crown(self, Vector2(26 + i * 34, 44), 12.0, enemy_col if got_enemy else Color(1, 1, 1, 0.15))
		Art.draw_crown(self, Vector2(Arena.W - 26 - i * 34, 44), 12.0, player_col if got_player else Color(1, 1, 1, 0.15))
	var t: float = maxf(0.0, game.time_left)
	var label := "%d:%02d" % [int(t) / 60, int(t) % 60]
	_text(label, Arena.MID_X, 36, 32, Color.WHITE)
	if game.overtime:
		_text("OVERTIME", Arena.MID_X, 55, 14, Color(1, 0.6, 0.3))
	elif game.is_double_elixir():
		_text("2x ELIXIR", Arena.MID_X, 55, 14, ELIXIR_COLOR.lightened(0.3))


func _draw_bottom_panel() -> void:
	draw_rect(Rect2(0, Arena.BOTTOM, Arena.W, Arena.H - Arena.BOTTOM), PANEL)
	draw_line(Vector2(0, Arena.BOTTOM), Vector2(Arena.W, Arena.BOTTOM), Color(0.35, 0.3, 0.25), 3.0)
	# Next card preview.
	draw_string(font, Vector2(NEXT_RECT.position.x, NEXT_RECT.position.y - 8), "NEXT", HORIZONTAL_ALIGNMENT_CENTER, NEXT_RECT.size.x, 16, Color(1, 1, 1, 0.7))
	_draw_card(NEXT_RECT, game.next_card(Arena.PLAYER), true, false, 0.6)
	# Hand.
	for i in SLOT_X.size():
		var id: String = game.hands[Arena.PLAYER][i]
		var r := slot_rect(i)
		if i == selected:
			r.position.y -= 14.0
		_draw_card(r, id, game.can_afford(Arena.PLAYER, id), i == selected, 1.0)
	# Elixir bar.
	var e: float = game.elixir[Arena.PLAYER]
	draw_rect(ELIXIR_RECT, Color(0.05, 0.03, 0.07))
	var seg_w := ELIXIR_RECT.size.x / 10.0
	for i in 10:
		var fill := clampf(e - i, 0.0, 1.0)
		var seg := Rect2(ELIXIR_RECT.position.x + i * seg_w + 2, ELIXIR_RECT.position.y + 3, (seg_w - 4) * fill, ELIXIR_RECT.size.y - 6)
		draw_rect(seg, ELIXIR_COLOR if fill >= 1.0 else ELIXIR_COLOR.darkened(0.35))
	var drop := Vector2(55, ELIXIR_RECT.get_center().y)
	draw_circle(drop, 24.0, ELIXIR_COLOR.darkened(0.2))
	draw_arc(drop, 24.0, 0.0, TAU, 24, Color(1, 1, 1, 0.6), 2.0)
	_text(str(int(e)), drop.x, drop.y + 10, 28, Color.WHITE, true)


func _draw_card(r: Rect2, id: String, affordable: bool, highlight: bool, scale_k: float) -> void:
	var card := Cards.get_card(id)
	var fcol: Color = Cards.faction(Cards.faction_of_card(id))["color"]
	draw_rect(r, fcol.darkened(0.55))
	var inner := r.grow(-4)
	draw_rect(inner, Color(0.16, 0.14, 0.13))
	# Soft faction glow behind the portrait.
	var glow_c := inner.get_center() + Vector2(0, -6 * scale_k)
	for i in 4:
		draw_circle(glow_c, inner.size.x * (0.48 - i * 0.1), Color(fcol, 0.08))
	var portrait := inner.size.x * 0.98
	var feet := Vector2(inner.get_center().x, inner.end.y - (32.0 if scale_k >= 1.0 else 6.0))
	var ts := Art.tex(id).get_size()
	if ts.x > ts.y:
		# Wide art (dragons, drones, spells): centre it instead of standing it up.
		Art.draw_sprite_centered(self, id, glow_c, portrait)
	else:
		Art.draw_sprite(self, id, feet, minf(portrait, inner.size.y - (36.0 if scale_k >= 1.0 else 8.0)))
	if scale_k >= 1.0:
		draw_rect(Rect2(inner.position.x, inner.end.y - 30, inner.size.x, 30), Color(0, 0, 0, 0.7))
		var label: String = card["name"]
		var fs := 15 if label.length() <= 14 else 12
		_text(label, r.get_center().x, r.end.y - 14, fs, Color.WHITE)
	# Elixir cost bubble.
	var bubble := r.position + Vector2(18, 18) * scale_k + Vector2(2, 2)
	draw_circle(bubble, 16.0 * scale_k, Color(0, 0, 0, 0.6))
	draw_circle(bubble, 14.0 * scale_k, ELIXIR_COLOR.darkened(0.15))
	_text(str(card["cost"]), bubble.x, bubble.y + 8 * scale_k, int(22 * scale_k), Color.WHITE, true)
	if not affordable:
		draw_rect(r, Color(0, 0, 0, 0.55))
	if highlight:
		draw_rect(r, Color(1.0, 0.85, 0.3), false, 4.0)
	else:
		draw_rect(r, Color(0, 0, 0, 0.6), false, 2.0)


func _draw_preview() -> void:
	if selected < 0 or not game.is_running():
		return
	var id: String = game.hands[Arena.PLAYER][selected]
	var card := Cards.get_card(id)
	for z in game.drop_zones(Arena.PLAYER, id):
		if card["type"] != "spell":
			draw_rect(z, Color(0.3, 1.0, 0.4, 0.08))
			draw_rect(z, Color(0.3, 1.0, 0.4, 0.35), false, 2.0)
	var p := get_global_mouse_position()
	if not _in_arena(p):
		return
	var valid: bool = game.is_valid_drop(Arena.PLAYER, id, p)
	var col := Color(1, 1, 1, 0.55) if valid else Color(1, 0.3, 0.3, 0.55)
	if card["type"] == "spell":
		draw_circle(p, card["spell_radius"], Color(game.faction_color(Arena.PLAYER), 0.15))
		draw_arc(p, card["spell_radius"], 0.0, TAU, 40, col, 2.0)
		return
	if card["range"] > 45.0:
		draw_arc(p, card["range"] + card["radius"], 0.0, TAU, 48, Color(1, 1, 1, 0.2), 1.5)
	Art.draw_sprite(self, id, p + Vector2(0, card["radius"] * 0.6), card["size"], false, Color(1, 1, 1, 0.6))
	draw_arc(p, card["radius"] + 8.0, 0.0, TAU, 24, col, 2.0)


func _draw_start_screen() -> void:
	draw_rect(Rect2(0, 0, Arena.W, Arena.H), Color(0.05, 0.04, 0.05, 0.86))
	_text("SCRAPFALL", Arena.MID_X, 230, 88, Color(1.0, 0.45, 0.2), true)
	_text("1v1 wasteland card battles", Arena.MID_X, 278, 26, Color(1, 1, 1, 0.85))
	_text("Choose your faction", Arena.MID_X, 345, 28, Color(1.0, 0.85, 0.5))
	var now := Time.get_ticks_msec() / 1000.0
	for i in Cards.FACTION_IDS.size():
		var f := Cards.faction(Cards.FACTION_IDS[i])
		var r := faction_panel(i)
		var col: Color = f["color"]
		draw_rect(r, col.darkened(0.7))
		draw_rect(r, Color(col, 0.9), false, 3.0)
		var hero_feet := Vector2(r.position.x + 110, r.end.y - 12)
		draw_circle(hero_feet + Vector2(0, -95), 90, Color(col, 0.12))
		Art.draw_sprite(self, f["hero"], hero_feet + Vector2(0, -absf(sin(now * 2.0 + i)) * 4.0), 200)
		var tx := r.position.x + 230
		draw_string_outline(font, Vector2(tx, r.position.y + 52), f["name"].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 40, 6, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(tx, r.position.y + 52), f["name"].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 40, col.lightened(0.25))
		draw_string(font, Vector2(tx, r.position.y + 84), f["tagline"], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 0.8))
		var deck: Array = f["deck"]
		for k in deck.size():
			var cell := Rect2(tx + (k % 4) * 104, r.position.y + 100 + (k / 4) * 62, 98, 58)
			draw_rect(cell, Color(0, 0, 0, 0.35))
			Art.draw_sprite_centered(self, deck[k], cell.get_center(), 54)
	var pulse := 0.6 + 0.4 * sin(Time.get_ticks_msec() / 250.0)
	_text("TAP A FACTION TO START", Arena.MID_X, 1150, 30, Color(1, 1, 1, pulse), true)
	_text("Deploy cards, smash towers, take the King for an instant win.", Arena.MID_X, 1195, 18, Color(1, 1, 1, 0.65))


func _draw_end_screen() -> void:
	draw_rect(Rect2(0, 0, Arena.W, Arena.H), Color(0, 0, 0, 0.65))
	var title := "DRAW"
	var col := Color.WHITE
	if game.winner == Arena.PLAYER:
		title = "VICTORY!"
		col = Arena.team_color(Arena.PLAYER).lightened(0.3)
	elif game.winner == Arena.ENEMY:
		title = "DEFEAT"
		col = Arena.team_color(Arena.ENEMY)
	_text(title, Arena.MID_X, 520, 84, col, true)
	_text("%d  -  %d" % [game.crowns[Arena.PLAYER], game.crowns[Arena.ENEMY]], Arena.MID_X, 600, 44, Color.WHITE, true)
	_text("You          AI", Arena.MID_X, 640, 20, Color(1, 1, 1, 0.7))
	_text("Tap to play again", Arena.MID_X, 760, 32, Color(1, 1, 1, 0.9), true)
