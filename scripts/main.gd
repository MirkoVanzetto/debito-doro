extends Control
## Scena principale v2: costruisce il tavolo da gioco, la barra superiore con Scadenze e Ticket,
## le fiches di navigazione, i 6 pannelli, il gatto dorato, i toast, la modale di Fine Scadenza e la lettera.

const FeltBg := preload("res://scripts/ui/felt_bg.gd")
const TableRail := preload("res://scripts/ui/table_rail.gd")
const TopBar := preload("res://scripts/ui/top_bar.gd")
const ChipButton := preload("res://scripts/ui/chip_button.gd")
const BusinessesPanel := preload("res://scripts/ui/businesses_panel.gd")
const GamblePanel := preload("res://scripts/ui/gamble_panel.gd")
const ManagersPanel := preload("res://scripts/ui/managers_panel.gd")
const UpgradesPanel := preload("res://scripts/ui/upgrades_panel.gd")
const PrestigePanel := preload("res://scripts/ui/prestige_panel.gd")
const TrophiesPanel := preload("res://scripts/ui/trophies_panel.gd")
const LuckyCat := preload("res://scripts/ui/lucky_cat.gd")
const FxLayer := preload("res://scripts/ui/fx_layer.gd")
const StoryModal := preload("res://scripts/ui/story_modal.gd")
const DeadlineModal := preload("res://scripts/ui/deadline_modal.gd")

var felt: Control
var top_bar: Control
var chips: Array[Control] = []
var panels: Array[Control] = []
var cur_tab := 0
var fx: Control
var modal: Control
var deadline_modal: Control
var cat: Control

var _toasts: Array = []
var _shake := 0.0
var _shot_path := ""
var _shot_tab := 0
var _shot_sub := 0
var _shot_frames := 0
var _toast_layer: Control

func _ready() -> void:
	theme = S.theme
	felt = FeltBg.new(); add_child(felt)
	fx = FxLayer.new()
	top_bar = TopBar.new(); add_child(top_bar); top_bar.setup(fx)
	var nav := [
		["LA SALA", S.RED, "icon:slot"],
		["IL BANCO", S.GOLD, "sym:seven"],
		["MANAGER", S.PURPLE, "face"],
		["MIGLIORIE", S.BLUE, "star"],
		["BOTTEGA", S.GREEN, "sym:clover"],
		["TROFEI", S.ORANGE, "cup"],
	]
	for i in nav.size():
		var c := ChipButton.new()
		add_child(c)
		c.setup(nav[i][0], nav[i][1], nav[i][2])
		var idx := i
		c.pressed.connect(func(): select_tab(idx))
		chips.append(c)
	var p_sala := BusinessesPanel.new(); add_child(p_sala); p_sala.setup(fx)
	var p_banco := GamblePanel.new(); add_child(p_banco); p_banco.setup(fx)
	var p_mgr := ManagersPanel.new(); add_child(p_mgr)
	var p_upg := UpgradesPanel.new(); add_child(p_upg)
	var p_fuga := PrestigePanel.new(); add_child(p_fuga); p_fuga.setup(fx)
	var p_tr := TrophiesPanel.new(); add_child(p_tr)
	panels = [p_sala, p_banco, p_mgr, p_upg, p_fuga, p_tr]
	cat = LuckyCat.new(); add_child(cat); cat.setup(fx)
	add_child(fx)
	var toast_layer := Control.new()
	toast_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	toast_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_layer.draw.connect(_draw_toasts.bind(toast_layer))
	add_child(toast_layer)
	_toast_layer = toast_layer
	deadline_modal = DeadlineModal.new(); add_child(deadline_modal)
	deadline_modal.closed_for_shop.connect(func(): select_tab(4))
	modal = StoryModal.new(); add_child(modal)
	add_child(TableRail.new())
	# Segnali
	G.toast.connect(add_toast)
	G.story.connect(func(t, b, bt): modal.show_modal(t, b, bt))
	G.open_deadline_modal.connect(_on_open_deadline_modal)
	G.big_win.connect(func(_a, _l): _shake = 12.0)
	G.achievement_unlocked.connect(func(n): add_toast("TROFEO: " + n + " (+2%)", S.GOLD))
	G.cat_reward.connect(_on_cat_reward)
	resized.connect(_layout)
	select_tab(0)
	_layout()
	_check_intro_and_offline()
	_parse_args()

func _on_open_deadline_modal(w: bool, info: Dictionary) -> void:
	deadline_modal.open_modal(w, info)
	_shake = 14.0

func _on_cat_reward(t: String) -> void:
	fx.banner("MIAO!", t, S.GOLD)
	_shake = 8.0

func _check_intro_and_offline() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--screenshot"):
			return
	if not G.intro_seen:
		G.intro_seen = true
		var dd := G.deadline_data()
		modal.show_modal("DEBITO D'ORO — LA SCADENZA",
			"Hai perso a poker contro %s. Ora hai %d GIORNI per versargli la prima quota di %s, o la tua bisca farà una brutta fine!\n\n- Fai soldi nella SALA o rischia tutto al BANCO (Gratta, Slot, Dadi, Ruota del Destino).\n- Salda la quota PRIMA della scadenza: i giorni risparmiati e il surplus ti danno TICKET D'ORO!\n- Spendi i Ticket nella BOTTEGA per comprare AMULETI per la Vetrinetta e TALISMANI PERMANENTI che ti restano anche se muori!" % [dd["boss"], int(dd["days"]), G.fmt(dd["quota"])],
			"SI COMINCIA!")
	elif G.offline_report > 0:
		modal.show_modal("BENTORNATO BOSS!",
			"Mentre eri via (%s), i tuoi manager hanno tenuto aperta la bisca.\n\nIncasso netto: +%s" % [G.fmt_time(G.offline_seconds), G.fmt(G.offline_report)],
			"INTASCA!")

func _parse_args() -> void:
	var demo := false
	var show_dl := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--screenshot="):
			_shot_path = a.substr(13)
		elif a.begins_with("--tab="):
			_shot_tab = int(a.substr(6))
		elif a.begins_with("--sub="):
			_shot_sub = int(a.substr(6))
		elif a == "--demo":
			demo = true
		elif a == "--demo-modal":
			show_dl = true
	if demo:
		_setup_demo(show_dl)
	if _shot_path != "":
		select_tab(_shot_tab)

func _setup_demo(show_dl := false) -> void:
	G.intro_seen = true
	G.money = 1840.0
	G.all_earned = 250000.0
	G.tickets = 9
	G.clovers = 3.0
	G.equipped_charms = ["peperoncino", "magnete", "dado_piombo"]
	G.deadline_idx = 1
	G.day_in_deadline = 2
	G.day_time_left = 48.0
	G.debt_paid = 14500.0
	var counts := [45, 22, 12, 6, 2, 1, 0, 0, 0, 0]
	for i in counts.size():
		G.owned[i] = counts[i]
		G.managers[i] = i < 4
		G.running[i] = counts[i] > 0
		G.progress[i] = fmod(0.23 + i * 0.31, 0.95)
	G.check_achievements()
	_toasts.clear()
	if _shot_tab == 0:
		cat.spawn()
		cat._pos = Vector2(960, 390)
	if _shot_tab == 1:
		var gp := panels[1]
		gp._select_game(_shot_sub)
		if _shot_sub == 0:
			gp.scratch.new_ticket(100.0)
			for x in range(30, 230, 8):
				gp.scratch._scratch_at(gp.scratch._grid_origin() + Vector2(x, x * 0.85))
				gp.scratch._scratch_at(gp.scratch._grid_origin() + Vector2(x, 50))
	if show_dl:
		deadline_modal.open_modal(true, {"boss": "Zio Tano 'o Squalo", "name": "Napoli — Il Pizzo", "quota": 2500.0, "surplus": 4200.0, "days_saved": 1, "tickets": 8, "next_idx": 1})

func select_tab(idx: int) -> void:
	cur_tab = idx
	for i in panels.size():
		panels[i].visible = i == idx
		chips[i].selected = i == idx

func _layout() -> void:
	top_bar.position = Vector2(4, 12)
	top_bar.size = Vector2(size.x - 8, 96)
	var cw := 112.0
	var gap := 18.0
	var tot := chips.size() * cw + (chips.size() - 1) * gap
	var x0 := (size.x - tot) * 0.5
	for i in chips.size():
		chips[i].position = Vector2(x0 + i * (cw + gap), 114)
		chips[i].size = Vector2(cw, 80)
	var pr := Rect2(8, 196, size.x - 16, size.y - 210)
	for p in panels:
		p.position = pr.position
		p.size = pr.size

func add_toast(txt: String, col := S.GOLD) -> void:
	_toasts.append({"txt": txt, "col": col, "t": 0.0, "life": 4.0})
	if _toasts.size() > 4:
		_toasts.pop_front()

func _process(delta: float) -> void:
	var mgr_ok := false
	for i in G.BUSINESSES.size():
		if not G.managers[i] and G.owned[i] > 0 and G.money >= G.manager_cost(i):
			mgr_ok = true; break
	chips[2].notify = mgr_ok
	var av := G.available_upgrades()
	chips[3].notify = not av.is_empty() and G.money >= av[0]["cost"]
	chips[4].notify = G.tickets >= 2
	var urgent := G.day_time_left < 15.0 and G.day_in_deadline >= int(G.deadline_data()["days"])
	felt.set_tint(0.28 if urgent else (0.18 if G.frenzy_time > 0 else 0.0))
	if _shake > 0:
		_shake = maxf(0.0, _shake - delta * 28.0)
		position = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
	else:
		position = Vector2.ZERO
	for t in _toasts:
		t["t"] += delta
	_toasts = _toasts.filter(func(t): return t["t"] < t["life"])
	_toast_layer.queue_redraw()
	if _shot_path != "":
		_shot_frames += 1
		if _shot_frames == 8:
			var img := get_viewport().get_texture().get_image()
			img.save_png(_shot_path)
			get_tree().quit()

func _draw_toasts(c: Control) -> void:
	for i in _toasts.size():
		var t: Dictionary = _toasts[i]
		var a := minf(1.0, (t["life"] - t["t"]) * 2.0) * minf(1.0, t["t"] * 6.0)
		var w := S.f_num.get_string_size(t["txt"], 0, -1, 17).x + 48
		var r := Rect2((c.size.x - w) * 0.5, c.size.y - 66 - i * 46, w, 38)
		S.draw_card(c, r, Color(S.INK, 0.92 * a), 10, Vector2(0, 4), 2, Color(t["col"], a))
		S.text_in(c, r, t["txt"], 17, Color(t["col"], a), 1, S.f_num)
