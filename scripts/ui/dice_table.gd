extends Control
## Tavolo dei Dadi: Sotto 7 / Sette / Sopra 7. Dadi doppi = vincita x2!

signal finished(win: float, stake: float, mult: float)

const PIPS := {
	1: [Vector2(0, 0)],
	2: [Vector2(-1, -1), Vector2(1, 1)],
	3: [Vector2(-1, -1), Vector2(0, 0), Vector2(1, 1)],
	4: [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)],
	5: [Vector2(-1, -1), Vector2(1, -1), Vector2(0, 0), Vector2(-1, 1), Vector2(1, 1)],
	6: [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(1, 0), Vector2(-1, 1), Vector2(1, 1)],
}

var bet := 1
var rolling := false
var dice := [3, 4]
var _res := {}
var _stake := 0.0
var _roll_t := 0.0
var _pos := [Vector2.ZERO, Vector2.ZERO]
var _rot := [0.0, 0.0]
var _hover_zone := -1

func _ready() -> void:
	custom_minimum_size = Vector2(540, 390)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func roll(p_stake: float) -> void:
	if rolling:
		return
	_stake = p_stake
	_res = G.roll_dice(bet)
	rolling = true
	_roll_t = 0.0
	Sfx.play("dice")

func _process(delta: float) -> void:
	if rolling:
		_roll_t += delta
		var k := clampf(_roll_t / 0.7, 0.0, 1.0)
		var bounce := absf(sin(k * PI * 3.5)) * (1.0 - k)
		for i in 2:
			var side := -1 if i == 0 else 1
			var target := Vector2(size.x * 0.5 + side * 66, 225)
			var start := Vector2(size.x * 0.5 + side * 180, 120)
			_pos[i] = start.lerp(target, 1.0 - pow(1.0 - k, 2.5)) + Vector2(0, -bounce * 60)
			_rot[i] = (1.0 - k) * (10.0 if i == 0 else -12.0)
		if k < 0.85 and int(_roll_t * 24) != int((_roll_t - delta) * 24):
			dice = [randi_range(1, 6), randi_range(1, 6)]
		if k >= 1.0:
			rolling = false
			dice = _res["dice"]
			_rot = [randf_range(-0.12, 0.12), randf_range(-0.12, 0.12)]
			G.stats["rolls"] += 1
			var win: float = _res["mult"] * _stake * G.game_mult()
			finished.emit(win, _stake, _res["mult"])
	else:
		_pos = [Vector2(size.x * 0.5 - 66, 225), Vector2(size.x * 0.5 + 66, 225)]
	queue_redraw()

func _zone_rect(idx: int) -> Rect2:
	var w := (size.x - 60) / 3.0
	return Rect2(20 + idx * (w + 10), 22, w, 108)

func _gui_input(e: InputEvent) -> void:
	var mm := e as InputEventMouseMotion
	if mm:
		_hover_zone = -1
		for i in 3:
			if _zone_rect(i).has_point(mm.position):
				_hover_zone = i
	var mb := e as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and not rolling:
		for i in 3:
			if _zone_rect(i).has_point(mb.position):
				bet = i
				Sfx.play("pop")

func _draw() -> void:
	var titles := ["SOTTO 7", "SETTE!", "SOPRA 7"]
	var subs := ["2 - 6   Paga x2.5", "Esatto 7   Paga x6", "8 - 12   Paga x2.5"]
	var cols := [S.BLUE, S.RED, S.TEAL]
	for i in 3:
		var r := _zone_rect(i)
		var sel := bet == i
		var fill: Color = cols[i] if sel else cols[i].darkened(0.35)
		if _hover_zone == i and not sel:
			fill = fill.lightened(0.12)
		S.draw_card(self, r, fill, 14, Vector2(0, 5), 4 if sel else 3, S.GOLD if sel else S.INK)
		S.text(self, Vector2(r.get_center().x, r.position.y + 42), titles[i], 26, S.GOLD if sel else S.PAPER, 1, S.f_title, 5, S.INK)
		S.text(self, Vector2(r.get_center().x, r.position.y + 68), subs[i], 14, S.PAPER, 1, S.f_num, 3, S.INK)
		if sel:
			S.draw_chip(self, Vector2(r.end.x - 24, r.end.y - 22), 16, S.GOLD)
			S.text_in(self, Rect2(r.end.x - 40, r.end.y - 38, 32, 32), "€", 16, S.INK, 1, S.f_title)
	# pista di lancio
	var pit := Rect2(20, 146, size.x - 40, 170)
	S.draw_card(self, pit, Color(0, 0, 0, 0.25), 18, Vector2.ZERO, 3, S.GOLD_DARK)
	S.text(self, Vector2(pit.get_center().x, pit.position.y + 22), "DADI DOPPI = VINCITA RADDOPPIATA!", 13, Color(S.GOLD, 0.7), 1, S.f_num)
	for i in 2:
		_draw_die(_pos[i], _rot[i], dice[i])
	# risultato
	var sum: int = dice[0] + dice[1]
	var dbl: bool = dice[0] == dice[1]
	var txt := "Totale: %d" % sum + (" (DOPPI!)" if dbl else "")
	if not rolling and _res.has("mult"):
		txt += ("  —  VINTO x" + G.num(_res["mult"]) + "!") if _res["mult"] > 0 else "  —  Perso"
	var col := S.GOLD if _res.get("mult", 0.0) > 0 else S.PAPER
	S.text(self, Vector2(size.x * 0.5, 348), txt, 24, col, 1, S.f_title, 6, S.INK)

func _draw_die(c: Vector2, rot: float, val: int) -> void:
	var s := 82.0
	draw_set_transform(c, rot)
	var r := Rect2(-s * 0.5, -s * 0.5, s, s)
	S.draw_card(self, r, S.PAPER, 16, Vector2(6, 8), 3.5)
	S.draw_round_rect(self, r.grow(-6), Color("efe2c2"), 12)
	for p in PIPS.get(val, []):
		var pp: Vector2 = p * 21.0
		var col := S.RED if val == 1 or val == 4 else S.INK
		draw_circle(pp + Vector2(0, 1), 7.5, Color(0, 0, 0, 0.2))
		draw_circle(pp, 7.5, col)
	draw_set_transform(Vector2.ZERO)
