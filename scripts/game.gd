extends Node
## Autoload "G": stato del gioco, ciclo di Scadenze / Giorni stile CloverPit,
## vetrinette Amuleti, Ticket dal surplus, Ruota del Destino, economia e salvataggio.

signal toast(text: String, color: Color)
signal story(title: String, body: String, button: String)
signal big_win(amount: float, label: String)
signal achievement_unlocked(name: String)
signal state_reset
signal cat_reward(text: String)
signal open_deadline_modal(won: bool, info: Dictionary)
signal charm_triggered(id: String)

const SAVE_VERSION := 2
var save_path := "user://save.json"

# ------------------------------------------------------------------ DATI ATTIVITÀ
const BUSINESSES := [
	{"name": "Edicola Gratta&Vinci", "desc": "I pensionati grattano, tu incassi.", "icon": "ticket", "color": Color("f2b632"),
	 "cost": 4.0, "coef": 1.11, "rev": 1.2, "time": 1.0, "mgr": 300.0},
	{"name": "Slot del Bar Sport", "desc": "Una macchinetta vicino al flipper.", "icon": "slot", "color": Color("d6344a"),
	 "cost": 60.0, "coef": 1.15, "rev": 55.0, "time": 3.0, "mgr": 3000.0},
	{"name": "Sala Bingo", "desc": "Nonne agguerrite, cartelle infinite.", "icon": "bingo", "color": Color("3a6fd8"),
	 "cost": 720.0, "coef": 1.14, "rev": 540.0, "time": 6.0, "mgr": 28000.0},
	{"name": "Agenzia Ippica", "desc": "Cavalli, fantini e soffiate.", "icon": "horse", "color": Color("8a5a3c"),
	 "cost": 8640.0, "coef": 1.13, "rev": 4800.0, "time": 11.0, "mgr": 160000.0},
	{"name": "Poker Clandestino", "desc": "Retrobottega, fumo e bluff.", "icon": "cards", "color": Color("2bb3a3"),
	 "cost": 103680.0, "coef": 1.12, "rev": 55000.0, "time": 22.0, "mgr": 900000.0},
	{"name": "Roulette Truccata", "desc": "Il banco vince. Il banco sei tu.", "icon": "roulette", "color": Color("1b1420"),
	 "cost": 1.24416e6, "coef": 1.11, "rev": 650000.0, "time": 54.0, "mgr": 6e6},
	{"name": "Lotteria Nazionale", "desc": "Un'intera nazione che sogna.", "icon": "lottery", "color": Color("ff6fae"),
	 "cost": 1.492992e7, "coef": 1.10, "rev": 8.0e6, "time": 160.0, "mgr": 6e7},
	{"name": "Casinò Galleggiante", "desc": "In acque internazionali, niente tasse.", "icon": "ship", "color": Color("f07f2e"),
	 "cost": 1.7915904e8, "coef": 1.09, "rev": 9.5e7, "time": 520.0, "mgr": 4e8},
	{"name": "Crypto-Casinò", "desc": "Scommesse sulla blockchain. Fidati.", "icon": "crypto", "color": Color("8a4fd1"),
	 "cost": 2.14990848e9, "coef": 1.08, "rev": 1.2e9, "time": 1800.0, "mgr": 5e9},
	{"name": "Casinò Lunare", "desc": "Gravità bassa, puntate altissime.", "icon": "moon", "color": Color("5ac35a"),
	 "cost": 2.579890176e10, "coef": 1.07, "rev": 3.2e10, "time": 7200.0, "mgr": 5e10},
]

const MANAGERS := [
	{"name": "Nonna Pina", "line": "Gratta anche i biglietti degli altri.", "face": {"hair": "bun", "glasses": true, "skin": Color("f5d0a9")}},
	{"name": "Er Tasca", "line": "Cambia le monete. Ne tiene qualcuna.", "face": {"hair": "slick", "mustache": true, "hat": "cap", "hat_col": Color("d6344a")}},
	{"name": "Suor Tombola", "line": "Estrae i numeri con fede.", "face": {"hat": "veil", "glasses": true}},
	{"name": "Fantino Gino", "line": "Sa sempre chi vince. Sempre.", "face": {"hat": "jockey", "hat_col": Color("3a6fd8"), "skin": Color("e0ac69")}},
	{"name": "Il Baro", "line": "Ha sette assi nella manica.", "face": {"shades": true, "mustache": true, "hat": "fedora", "hat_col": Color("d6344a"), "hair_col": Color("3b2416")}},
	{"name": "Madame Rouge", "line": "Rien ne va plus, chéri.", "face": {"hair": "long", "hair_col": Color("8e1c2e"), "hat": "beret", "hat_col": Color("d6344a")}},
	{"name": "Il Notaio", "line": "Certifica estrazioni... creative.", "face": {"hair": "bald", "glasses": true, "mustache": true, "hair_col": Color("888888")}},
	{"name": "Capitan Fiche", "line": "Rotta verso le acque internazionali.", "face": {"hat": "captain", "mustache": true, "hair_col": Color("eeeeee"), "skin": Color("c68642")}},
	{"name": "Satoshi Esposito", "line": "To the moon, guagliò.", "face": {"shades": true, "hair": "slick", "hair_col": Color("2a2a2a"), "skin": Color("f1c27d")}},
	{"name": "L'Astronauta", "line": "Houston, abbiamo un jackpot.", "face": {"hat": "helmet", "skin": Color("8d5524")}},
]

# Scadenze (Deadlines) della run: ogni scadenza ha tot giorni e una quota da versare
const DEADLINES := [
	{"name": "Napoli — Il Pizzo", "boss": "Zio Tano 'o Squalo", "quota": 2000.0, "days": 3},
	{"name": "Napoli — Gli Interessi", "boss": "Zio Tano 'o Squalo", "quota": 30000.0, "days": 3},
	{"name": "Montecarlo — Il Tavolo VIP", "boss": "Le Requin", "quota": 450000.0, "days": 3},
	{"name": "Las Vegas — La Strip", "boss": "Big Shark Tony", "quota": 9.0e6, "days": 3},
	{"name": "Macao — La Triade", "boss": "Madame Shā", "quota": 2.2e8, "days": 4},
	{"name": "Dubai — Il Grattacielo", "boss": "Lo Sceicco Pinna", "quota": 7.5e9, "days": 4},
	{"name": "Base Lunare — Il Cratere", "boss": "Lo Squalo Spaziale", "quota": 2.8e11, "days": 4},
	{"name": "Marte — Il Casinò Rosso", "boss": "Il Megalodonte", "quota": 1.4e13, "days": 4},
]

# Amuleti da vetrinetta (ispirati a CloverPit): si comprano coi Ticket tra una scadenza e l'altra (o in Bottega)
const CHARMS := [
	{"id": "peperoncino", "name": "Peperoncino Piccante", "rarity": "Comune", "cost": 3, "col": Color("d6344a"), "sym": "cherry",
	 "desc": "Vincite ai minigiochi x1.6 e +2 Fortuna."},
	{"id": "zampa", "name": "Zampa di Coniglio", "rarity": "Comune", "cost": 3, "col": Color("f2b632"), "sym": "clover",
	 "desc": "+4 Fortuna. I Gratta e Vinci pagano x1.5."},
	{"id": "magnete", "name": "Magnete da Slot", "rarity": "Raro", "cost": 5, "col": Color("3a6fd8"), "sym": "horseshoe",
	 "desc": "Nella Slot 777 il simbolo 7 esce il triplo più spesso!"},
	{"id": "dado_piombo", "name": "Dado Piombato", "rarity": "Raro", "cost": 5, "col": Color("2bb3a3"), "sym": "diamond",
	 "desc": "Ai Dadi i Doppi pagano x4 (invece di x2) e +15% vittoria."},
	{"id": "clessidra", "name": "Clessidra Truccata", "rarity": "Raro", "cost": 6, "col": Color("f07f2e"), "sym": "bell",
	 "desc": "+25 secondi a ogni Giorno prima che suoni la sirena!"},
	{"id": "stampante", "name": "Stampante Clandestina", "rarity": "Epico", "cost": 8, "col": Color("5ac35a"), "sym": "clover",
	 "desc": "Tutte le attività della Sala producono x2.5!"},
	{"id": "gatto_oro", "name": "Maneki-Neko d'Oro", "rarity": "Epico", "cost": 7, "col": Color("f2b632"), "sym": "bell",
	 "desc": "Il Gatto Dorato appare 2x più spesso e dà anche +2 Ticket!"},
	{"id": "teschio", "name": "Teschio del Baro", "rarity": "Epico", "cost": 9, "col": Color("8a4fd1"), "sym": "seven",
	 "desc": "Raddoppia o Lascia: 35% di salvarti se perdi, e +10% chance!"},
	{"id": "valigetta", "name": "Valigetta Diplomatica", "rarity": "Raro", "cost": 5, "col": Color("8a5a3c"), "sym": "diamond",
	 "desc": "+60% Ticket dal surplus e niente Taglieggio a fine giorno!"},
	{"id": "croupier", "name": "Guanto del Croupier", "rarity": "Epico", "cost": 8, "col": Color("ff6fae"), "sym": "horseshoe",
	 "desc": "Velocità di tutte le attività x2 e Manager -40% costo."},
	{"id": "limone", "name": "Limone Spremuto", "rarity": "Comune", "cost": 3, "col": Color("ffe14d"), "sym": "lemon",
	 "desc": "Ogni giocata persa ai minigiochi ti rimborsa il 35% della puntata."},
	{"id": "dente_squalo", "name": "Dente dello Squalo", "rarity": "Leggendario", "cost": 14, "col": Color("d6344a"), "sym": "seven",
	 "desc": "Riduce tutte le Quote dello Squalo del 25% e guadagni x2!"},
]

const SPEED_MILESTONES := [25, 50, 100, 200, 300, 400]
const SYNERGY_MILESTONES := [10, 25, 50, 100, 200, 300, 400, 500, 750, 1000]

# Talismani PERMANENTI (sopravvivono alla morte / nuova run, si comprano coi Ticket)
const TALISMANS := [
	{"id": "cornetto", "name": "Cornetto Rosso", "desc": "Inizi ogni nuova Run con più capitale liquido (attività sempre da 0).", "base": 2.0, "grow": 2.0, "max": 10},
	{"id": "ferro", "name": "Ferro di Cavallo", "desc": "+2 Fortuna permanente in tutte le Run.", "base": 2.0, "grow": 1.8, "max": 15},
	{"id": "vetrina", "name": "Vetrinetta Extra", "desc": "+1 slot Amuleto equipaggiabile (fino a 7).", "base": 5.0, "grow": 3.0, "max": 3},
	{"id": "autogratta", "name": "Grattatore Automatico", "desc": "Gratta biglietti gratis da solo in background.", "base": 4.0, "grow": 2.2, "max": 5},
	{"id": "autoleva", "name": "Leva Automatica", "desc": "Gira la slot gratis da sola in background.", "base": 6.0, "grow": 2.2, "max": 5},
	{"id": "contabile", "name": "Contabile Corrotto", "desc": "Manager -30% di costo per livello.", "base": 3.0, "grow": 2.5, "max": 4},
	{"id": "orologio", "name": "Orologio Svizzero", "desc": "+10 secondi per ogni Giorno della scadenza.", "base": 4.0, "grow": 2.2, "max": 5},
	{"id": "fuga_oro", "name": "Passaporto Falso", "desc": "+25% guadagni globali permanenti per livello.", "base": 3.0, "grow": 1.8, "max": 20},
	{"id": "dadi", "name": "Dadi Truccati", "desc": "+4% vittoria su Raddoppia, Dadi e Ruota.", "base": 3.0, "grow": 2.0, "max": 5},
]

const SCRATCH_PRIZES := [
	{"sym": "cherry", "mult": 1.5, "w": 42.0},
	{"sym": "lemon", "mult": 2.5, "w": 25.0},
	{"sym": "bell", "mult": 4.0, "w": 15.0},
	{"sym": "clover", "mult": 7.0, "w": 9.0},
	{"sym": "horseshoe", "mult": 15.0, "w": 5.5},
	{"sym": "diamond", "mult": 60.0, "w": 2.5},
	{"sym": "seven", "mult": 500.0, "w": 1.0},
]
const SLOT_WEIGHTS := {"cherry": 28.0, "lemon": 24.0, "bell": 18.0, "clover": 12.0, "horseshoe": 9.0, "diamond": 6.0, "seven": 3.0}
const SLOT_PAY := {"cherry": 5.0, "lemon": 8.0, "bell": 15.0, "clover": 30.0, "horseshoe": 60.0, "diamond": 200.0, "seven": 1000.0}

# Spicchi della Ruota del Destino (pensata per gli streamer: alta tensione!)
const WHEEL_SLICES := [
	{"label": "JACKPOT x8", "col": Color("f2b632"), "kind": "mult", "val": 8.0},
	{"label": "TESCHIO (0)", "col": Color("1b1420"), "kind": "mult", "val": 0.0},
	{"label": "RADDOPPIA x2", "col": Color("2bb3a3"), "kind": "mult", "val": 2.0},
	{"label": "+3 TICKET!", "col": Color("5ac35a"), "kind": "tickets", "val": 3.0},
	{"label": "TRIPLICA x3", "col": Color("3a6fd8"), "kind": "mult", "val": 3.0},
	{"label": "SQUALO (-50%)", "col": Color("d6344a"), "kind": "shark", "val": 0.5},
	{"label": "FRENESIA x7!", "col": Color("f07f2e"), "kind": "frenzy", "val": 25.0},
	{"label": "TESCHIO (0)", "col": Color("1b1420"), "kind": "mult", "val": 0.0},
]

const SHARK_LINES := [
	"Lo Squalo: \"Il tempo scorre, guagliò. Vedo pochi soldi nella cassa.\"",
	"Lo Squalo: \"Bel posto. Sarebbe un peccato se stasera chiudesse per sempre.\"",
	"Lo Squalo: \"Hai sentito il ticchettio? Non è un orologio. Sono io.\"",
	"Lo Squalo: \"Paga in anticipo e ti riempio di Ticket. Ritarda e nuoti coi pesci.\"",
	"Lo Squalo: \"Gira quella Ruota del Destino, vediamo se hai fegato!\"",
]

# ------------------------------------------------------------------ STATO
var money := 15.0
var run_earned := 0.0
var all_earned := 0.0
var owned: Array = []
var managers: Array = []
var progress: Array = []
var running: Array = []
var upgrades_bought := {}

# Sistema Ticket + Scadenze + Amuleti (CloverPit style)
var tickets := 3
var total_tickets_earned := 3
var clovers := 0.0
var clovers_spent := 0.0
var talismans := {}
var equipped_charms: Array = [] # lista di id amuleti nella vetrinetta della run
var shop_offers: Array = []     # 3 amuleti proposti nella bottega

var deadline_idx := 0
var day_in_deadline := 1
var day_time_left := 75.0
var debt_paid := 0.0
var deadline_paused := false
var cities_cleared := 0
var best_deadline := 0
var runs_played := 1

var stats := {"scratch": 0, "spins": 0, "rolls": 0, "wheels": 0, "jackpots": 0, "cats": 0, "best_double": 0, "prestiges": 0, "biggest_win": 0.0, "play_time": 0.0, "deaths": 0}
var achievements := {}
var buy_mode := 0  # 0=x1 1=x10 2=x100 3=MAX
var stake_mult := 1.0
var sfx_on := true
var music_on := true
var intro_seen := false
var frenzy_time := 0.0
var luckboost_time := 0.0

var UPGRADES: Array = []
var ACHIEVEMENTS: Array = []

var _autosave_t := 0.0
var _shark_t := 45.0
var _ach_t := 0.0
var _auto_scratch_t := 0.0
var _auto_spin_t := 0.0
var _cache_ips := 0.0
var _cache_t := 0.0

func _ready() -> void:
	_build_upgrades()
	_build_achievements()
	_reset_run_arrays()
	for a in OS.get_cmdline_user_args():
		if a == "--fresh":
			save_path = "user://save_test.json"
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	load_game()
	if shop_offers.is_empty():
		roll_shop_offers()
	if owned[0] == 0 and run_earned == 0:
		_apply_run_start_bonuses()

func _reset_run_arrays() -> void:
	owned.clear(); managers.clear(); progress.clear(); running.clear()
	for i in BUSINESSES.size():
		owned.append(0); managers.append(false); progress.append(0.0); running.append(false)

func _apply_run_start_bonuses() -> void:
	_reset_run_arrays()
	money = start_money_for(tal("cornetto"))
	day_time_left = day_duration()

# ------------------------------------------------------------------ AMULETI (VETRINETTA)
func max_charms() -> int:
	return 4 + tal("vetrina")

func has_charm(id: String) -> bool:
	return equipped_charms.has(id)

func charm_count(id: String) -> int:
	var c := 0
	for x in equipped_charms:
		if x == id:
			c += 1
	return c

func charm_def(id: String) -> Dictionary:
	for c in CHARMS:
		if c["id"] == id:
			return c
	return CHARMS[0]

func roll_shop_offers() -> void:
	shop_offers.clear()
	var pool := CHARMS.duplicate()
	pool.shuffle()
	for c in pool:
		if not equipped_charms.has(c["id"]) and shop_offers.size() < 3:
			shop_offers.append(c["id"])
	while shop_offers.size() < 3:
		shop_offers.append(CHARMS.pick_random()["id"])

func reroll_shop() -> bool:
	if tickets < 1:
		return false
	tickets -= 1
	roll_shop_offers()
	Sfx.play("dice")
	return true

func buy_charm(id: String) -> bool:
	if equipped_charms.size() >= max_charms():
		toast.emit("Vetrinetta piena! Vendi un Amuleto o sblocca Vetrinetta Extra.", S.RED)
		return false
	var d := charm_def(id)
	var cost: int = d["cost"]
	if tickets < cost:
		return false
	tickets -= cost
	equipped_charms.append(id)
	shop_offers.erase(id)
	if id == "clessidra":
		day_time_left += 25.0
	_cache_t = 0.0
	Sfx.play("jackpot")
	toast.emit("Amuleto equipaggiato: " + d["name"] + "!", S.GOLD)
	return true

func sell_charm(idx: int) -> void:
	if idx < 0 or idx >= equipped_charms.size():
		return
	var id: String = equipped_charms[idx]
	var d := charm_def(id)
	var refund := maxi(1, int(d["cost"] / 2))
	equipped_charms.remove_at(idx)
	tickets += refund
	_cache_t = 0.0
	Sfx.play("coin")
	toast.emit("Venduto %s (+%d Ticket)" % [d["name"], refund], S.GOLD)

# ------------------------------------------------------------------ SCADENZE & GIORNI (CLOVERPIT LOOP)
func deadline_data() -> Dictionary:
	var base: Dictionary
	if deadline_idx < DEADLINES.size():
		base = DEADLINES[deadline_idx].duplicate()
	else:
		var extra := deadline_idx - DEADLINES.size() + 1
		base = {
			"name": "Inferno d'Oro #%d" % extra,
			"boss": "Il Megalodonte Cosmico",
			"quota": 1.4e13 * pow(25.0, extra),
			"days": 4,
		}
	if has_charm("dente_squalo"):
		base["quota"] *= 0.75
	return base

func city_data() -> Dictionary:
	var d := deadline_data()
	return {"name": d["name"], "debt": d["quota"], "boss": d["boss"], "days": d["days"]}

func day_duration() -> float:
	return 70.0 + 10.0 * tal("orologio") + (25.0 if has_charm("clessidra") else 0.0)

func debt_left() -> float:
	return maxf(0.0, float(deadline_data()["quota"]) - debt_paid)

## Calcola i Ticket che ricevi saldando la scadenza ora (più surplus e più giorni risparmiati = più Ticket!)
func calc_deadline_tickets(surplus_money: float, days_saved: int) -> int:
	var quota := float(deadline_data()["quota"])
	var ratio := maxf(0.0, surplus_money / maxf(1.0, quota))
	var bonus_surplus := int(floor(pow(ratio, 0.45) * 2.5))
	var base_t := 3 + deadline_idx + days_saved * 2 + clampi(bonus_surplus, 0, 25)
	if has_charm("valigetta"):
		base_t = int(ceil(base_t * 1.6))
	return base_t

func pay_debt() -> float:
	var amt := minf(money, debt_left())
	if amt <= 0:
		return 0.0
	money -= amt
	debt_paid += amt
	Sfx.play("cash")
	if debt_left() <= 0.01:
		_complete_deadline()
	return amt

func _complete_deadline() -> void:
	var dd := deadline_data()
	var days_saved := maxi(0, int(dd["days"]) - day_in_deadline)
	var surplus := money
	var t_gain := calc_deadline_tickets(surplus, days_saved)
	tickets += t_gain
	total_tickets_earned += t_gain
	clovers += 1.0 + deadline_idx * 0.5
	cities_cleared += 1
	if deadline_idx + 1 > best_deadline:
		best_deadline = deadline_idx + 1
	deadline_paused = true
	roll_shop_offers()
	Sfx.play("jackpot")
	Sfx.trigger_hype(16.0)
	check_achievements()
	save_game()
	open_deadline_modal.emit(true, {
		"boss": dd["boss"],
		"name": dd["name"],
		"quota": dd["quota"],
		"surplus": surplus,
		"days_saved": days_saved,
		"tickets": t_gain,
		"next_idx": deadline_idx + 1,
	})

func advance_to_next_deadline() -> void:
	deadline_idx += 1
	debt_paid = 0.0
	day_in_deadline = 1
	run_earned = 0.0
	_reset_run_arrays()
	upgrades_bought.clear()
	money = start_money_for(tal("cornetto")) * pow(2.0, deadline_idx)
	day_time_left = day_duration()
	deadline_paused = false
	_cache_t = 0.0
	save_game()
	state_reset.emit()

func _trigger_deadline_timeout() -> void:
	# Se hai abbastanza soldi in tasca per saldare sulla sirena, lo Squalo se li prende al volo!
	if money >= debt_left():
		money -= debt_left()
		debt_paid = float(deadline_data()["quota"])
		toast.emit("Saldato all'ultimo secondo sulla sirena!", S.GOLD)
		_complete_deadline()
		return
	var dd := deadline_data()
	var next_day: int = day_in_deadline + 1
	if next_day <= int(dd["days"]):
		day_in_deadline = next_day
		day_time_left = day_duration()
		Sfx.play("lose")
		# Taglieggio di fine giornata: se tieni contanti non versati, lo Squalo ti tassa il 18%!
		if money > 2.0 and not has_charm("valigetta"):
			var tax := money * 0.18
			money -= tax
			toast.emit("FINE GIORNO %d! Taglieggio dello Squalo sulla cassa: -%s (-18%%)" % [day_in_deadline - 1, fmt(tax)], S.RED)
		else:
			toast.emit("FINE GIORNO %d! Lo Squalo bussa alla porta..." % (day_in_deadline - 1), S.RED)
	else:
		# GAME OVER DELLA RUN: lo Squalo ti pignora la bisca, tutti i livelli attività tornano a 0, ma tieni Ticket & Talismani!
		deadline_paused = true
		stats["deaths"] = int(stats.get("deaths", 0)) + 1
		var consolation := maxi(2, 1 + deadline_idx * 2 + int(floor(debt_paid / maxf(1.0, float(dd["quota"])) * 3.0)))
		tickets += consolation
		total_tickets_earned += consolation
		roll_shop_offers()
		Sfx.play("lose")
		open_deadline_modal.emit(false, {
			"boss": dd["boss"],
			"name": dd["name"],
			"quota": dd["quota"],
			"paid": debt_paid,
			"tickets": consolation,
		})

## Nuova Run (Soft Reset): AZZERA tutti i livelli delle attività, i manager e le migliorie, ma conserva Ticket e Talismani!
func start_new_run(keep_charms := false) -> void:
	runs_played += 1
	stats["prestiges"] += 1
	deadline_idx = 0
	debt_paid = 0.0
	day_in_deadline = 1
	run_earned = 0.0
	_reset_run_arrays()
	upgrades_bought.clear()
	if not keep_charms:
		equipped_charms.clear()
	frenzy_time = 0.0
	luckboost_time = 0.0
	stake_mult = 1.0
	_apply_run_start_bonuses()
	deadline_paused = false
	roll_shop_offers()
	_cache_t = 0.0
	save_game()
	state_reset.emit()

## Hard Reset completo (Ricomincia da 0 assoluto): azzera attività, soldi, Ticket, Amuleti, Talismani e Scadenze!
func full_reset_to_zero() -> void:
	deadline_idx = 0
	debt_paid = 0.0
	day_in_deadline = 1
	run_earned = 0.0
	all_earned = 0.0
	tickets = 0
	total_tickets_earned = 0
	clovers = 0.0
	clovers_spent = 0.0
	talismans.clear()
	equipped_charms.clear()
	upgrades_bought.clear()
	achievements.clear()
	cities_cleared = 0
	best_deadline = 0
	runs_played = 1
	stats = {"scratch": 0, "spins": 0, "rolls": 0, "wheels": 0, "jackpots": 0, "cats": 0, "best_double": 0, "prestiges": 0, "biggest_win": 0.0, "play_time": 0.0, "deaths": 0}
	frenzy_time = 0.0
	luckboost_time = 0.0
	stake_mult = 1.0
	_reset_run_arrays()
	money = 8.0
	day_time_left = day_duration()
	deadline_paused = false
	roll_shop_offers()
	_cache_t = 0.0
	save_game()
	state_reset.emit()
	toast.emit("Partita resettata da ZERO assoluto! Buona fortuna!", S.GOLD)

# ------------------------------------------------------------------ UPGRADES
func _build_upgrades() -> void:
	UPGRADES.clear()
	var flavor := ["Insegna al neon", "Biglietti dorati", "Musica da ascensore", "Ragazze immagine", "Cocktail gratis", "Moquette ipnotica", "Orologi spariti", "Ossigeno in sala"]
	for i in BUSINESSES.size():
		UPGRADES.append({"id": "e%d" % i, "name": "Cartello luminoso", "target": i, "mult": 2.0, "cost": BUSINESSES[i]["cost"] * 120.0})
	for t in 8:
		for i in BUSINESSES.size():
			var cost := 1.0e5 * pow(10.0, 0.55 * i) * pow(1e5, t)
			UPGRADES.append({"id": "t%d_%d" % [t, i], "name": flavor[t], "target": i, "mult": 3.0, "cost": cost})
		UPGRADES.append({"id": "all%d" % t, "name": "Campagna pubblicitaria %d" % (t + 1), "target": -1, "mult": 3.0, "cost": 5.0e9 * pow(1e5, t)})
	var gnames := ["Monetina fortunata", "Unghie d'acciaio", "Leva oliata", "Dadi d'avorio", "Occhio di tigre", "Sorriso del banco", "Talento naturale", "Mano santa"]
	for k in 8:
		UPGRADES.append({"id": "g%d" % k, "name": gnames[k], "target": -2, "mult": 2.0, "cost": 250.0 * pow(45.0, k)})
	var lnames := ["Cornicello in tasca", "Calzini fortunati", "Santino nel portafoglio", "Coccinella sul cappello", "Oroscopo favorevole", "Numero 17 evitato"]
	for k in 6:
		UPGRADES.append({"id": "l%d" % k, "name": lnames[k], "target": -3, "mult": 1.0, "cost": 800.0 * pow(180.0, k)})
	UPGRADES.sort_custom(func(a, b): return a["cost"] < b["cost"])

func upgrade_desc(u: Dictionary) -> String:
	match int(u["target"]):
		-1: return "Tutte le attività x%d" % int(u["mult"])
		-2: return "Vincite minigiochi x%d" % int(u["mult"])
		-3: return "+1 Fortuna"
		_: return "%s x%d" % [BUSINESSES[u["target"]]["name"], int(u["mult"])]

func buy_upgrade(u: Dictionary) -> bool:
	if upgrades_bought.has(u["id"]) or money < u["cost"]:
		return false
	money -= u["cost"]
	upgrades_bought[u["id"]] = true
	Sfx.play("buy")
	_cache_t = 0.0
	return true

func available_upgrades() -> Array:
	var out := []
	for u in UPGRADES:
		if not upgrades_bought.has(u["id"]):
			out.append(u)
	return out

# ------------------------------------------------------------------ ACHIEVEMENTS
func _build_achievements() -> void:
	ACHIEVEMENTS.clear()
	for i in BUSINESSES.size():
		for n in [25, 100, 250, 500]:
			ACHIEVEMENTS.append({"id": "b%d_%d" % [i, n], "name": "%s x%d" % [BUSINESSES[i]["name"], n], "kind": "own", "i": i, "n": n})
	for p in [3, 6, 9, 12, 15, 18, 21, 24]:
		ACHIEVEMENTS.append({"id": "earn%d" % p, "name": "Guadagna %s in totale" % fmt(pow(10.0, p)), "kind": "earn", "n": pow(10.0, p)})
	for n in [10, 100, 500]:
		ACHIEVEMENTS.append({"id": "sc%d" % n, "name": "Gratta %d biglietti" % n, "kind": "stat", "stat": "scratch", "n": n})
		ACHIEVEMENTS.append({"id": "sp%d" % n, "name": "Gira la slot %d volte" % n, "kind": "stat", "stat": "spins", "n": n})
		ACHIEVEMENTS.append({"id": "dr%d" % n, "name": "Lancia i dadi %d volte" % n, "kind": "stat", "stat": "rolls", "n": n})
	for n in [1, 10, 50]:
		ACHIEVEMENTS.append({"id": "jp%d" % n, "name": "Fai %d jackpot" % n, "kind": "stat", "stat": "jackpots", "n": n})
	for n in [1, 10, 50]:
		ACHIEVEMENTS.append({"id": "cat%d" % n, "name": "Accarezza %d gatti dorati" % n, "kind": "stat", "stat": "cats", "n": n})
	for n in [3, 5, 8, 10]:
		ACHIEVEMENTS.append({"id": "dbl%d" % n, "name": "Raddoppia %d volte di fila" % n, "kind": "stat", "stat": "best_double", "n": n})
	for n in [1, 3, 5, 8]:
		ACHIEVEMENTS.append({"id": "city%d" % n, "name": "Supera %d Scadenze dello Squalo" % n, "kind": "city", "n": n})

func check_achievements() -> void:
	for a in ACHIEVEMENTS:
		if achievements.has(a["id"]):
			continue
		var ok := false
		match a["kind"]:
			"own": ok = owned[a["i"]] >= a["n"]
			"earn": ok = all_earned >= a["n"]
			"stat": ok = float(stats.get(a["stat"], 0)) >= float(a["n"])
			"city": ok = cities_cleared >= a["n"]
		if ok:
			achievements[a["id"]] = true
			_cache_t = 0.0
			achievement_unlocked.emit(a["name"])

func achievement_mult() -> float:
	return 1.0 + 0.02 * achievements.size()

# ------------------------------------------------------------------ TALISMANI (CON TICKET)
func tal(id: String) -> int:
	return int(talismans.get(id, 0))

func tal_def(id: String) -> Dictionary:
	for t in TALISMANS:
		if t["id"] == id:
			return t
	return {}

func tal_cost(id: String) -> int:
	var d := tal_def(id)
	return int(ceil(d["base"] * pow(d["grow"], tal(id))))

func buy_talisman(id: String) -> bool:
	var d := tal_def(id)
	if tal(id) >= d["max"]:
		return false
	var c := tal_cost(id)
	if tickets < c:
		return false
	tickets -= c
	talismans[id] = tal(id) + 1
	if id == "orologio":
		day_time_left += 10.0
	Sfx.play("jackpot")
	_cache_t = 0.0
	return true

func tal_effect_text(id: String, lvl: int) -> String:
	match id:
		"cornetto": return "Capitale iniziale: %s (attività da 0)" % fmt(start_money_for(lvl))
		"ferro": return "Fortuna +%d" % (lvl * 2)
		"vetrina": return "%d slot Amuleti" % (4 + lvl)
		"autogratta": return "Off" if lvl == 0 else "1 biglietto ogni %.1fs" % auto_interval(lvl)
		"autoleva": return "Off" if lvl == 0 else "1 giro ogni %.1fs" % auto_interval(lvl)
		"contabile": return "Manager -%d%%" % int((1.0 - pow(0.7, lvl)) * 100)
		"orologio": return "+%ds per Giorno" % (10 * lvl)
		"fuga_oro": return "Guadagni +%d%%" % (25 * lvl)
		"dadi": return "+%d%% vittoria" % (4 * lvl)
	return ""

func start_money_for(lvl: int) -> float:
	return 8.0 if lvl == 0 else 25.0 * pow(2.5, lvl)

func auto_interval(lvl: int) -> float:
	return 3.5 / (1.0 + 0.6 * (lvl - 1))

# ------------------------------------------------------------------ MOLTIPLICATORI
func clover_eff() -> float:
	return 0.10

func clover_mult() -> float:
	return (1.0 + clovers * clover_eff()) * (1.0 + 0.25 * tal("fuga_oro"))

func city_mult() -> float:
	return pow(1.5, deadline_idx)

func synergy_level() -> int:
	var mn: int = owned.min()
	var n := 0
	for m in SYNERGY_MILESTONES:
		if mn >= m:
			n += 1
	return n

func global_mult() -> float:
	var m := clover_mult() * city_mult() * achievement_mult() * pow(2.0, synergy_level())
	for u in UPGRADES:
		if u["target"] == -1 and upgrades_bought.has(u["id"]):
			m *= u["mult"]
	if has_charm("stampante"):
		m *= 2.5
	if has_charm("dente_squalo"):
		m *= 2.0
	if frenzy_time > 0:
		m *= 7.0
	return m

func upgrade_mult(i: int) -> float:
	var m := 1.0
	for u in UPGRADES:
		if u["target"] == i and upgrades_bought.has(u["id"]):
			m *= u["mult"]
	return m

func milestone_profit_mult(i: int) -> float:
	var o: int = owned[i]
	if o < 500:
		return 1.0
	return pow(2.0, floor((o - 400) / 100.0))

func speed_level(i: int) -> int:
	var n := 0
	for m in SPEED_MILESTONES:
		if owned[i] >= m:
			n += 1
	return n

func next_milestone(i: int) -> int:
	for m in SPEED_MILESTONES:
		if owned[i] < m:
			return m
	return int((floor(owned[i] / 100.0) + 1) * 100)

func cycle_time(i: int) -> float:
	var t: float = BUSINESSES[i]["time"] / pow(2.0, speed_level(i))
	if has_charm("croupier"):
		t *= 0.5
	return t

func cycle_revenue(i: int) -> float:
	return BUSINESSES[i]["rev"] * owned[i] * upgrade_mult(i) * milestone_profit_mult(i) * global_mult()

func luck() -> int:
	var l := tal("ferro") * 2
	for u in UPGRADES:
		if u["target"] == -3 and upgrades_bought.has(u["id"]):
			l += 1
	if has_charm("peperoncino"): l += 2
	if has_charm("zampa"): l += 4
	return l

func game_mult() -> float:
	var m := clover_mult() * city_mult()
	for u in UPGRADES:
		if u["target"] == -2 and upgrades_bought.has(u["id"]):
			m *= u["mult"]
	if has_charm("peperoncino"):
		m *= 1.6
	if has_charm("dente_squalo"):
		m *= 2.0
	if luckboost_time > 0:
		m *= 5.0
	return m

func income_per_sec(only_managed := true) -> float:
	var t := 0.0
	for i in BUSINESSES.size():
		if owned[i] > 0 and (managers[i] or not only_managed):
			t += cycle_revenue(i) / cycle_time(i)
	return t

func ips_cached() -> float:
	return _cache_ips

func base_stake() -> float:
	var ips := income_per_sec(false)
	var s := maxf(1.0, minf(maxf(2.0, ips * 2.5), maxf(1.0, money * 0.25)))
	var p := pow(10.0, floor(log(s) / log(10.0)))
	return maxf(1.0, floor(s / p) * p)

func stake() -> float:
	return minf(maxf(1.0, money), base_stake() * stake_mult)

# ------------------------------------------------------------------ COSTI
func cost_of(i: int, n: int) -> float:
	var b: Dictionary = BUSINESSES[i]
	var c: float = b["coef"]
	return b["cost"] * pow(c, owned[i]) * (pow(c, n) - 1.0) / (c - 1.0)

func max_affordable(i: int) -> int:
	var b: Dictionary = BUSINESSES[i]
	var c: float = b["coef"]
	var first: float = b["cost"] * pow(c, owned[i])
	if money < first:
		return 0
	return int(floor(log(money * (c - 1.0) / first + 1.0) / log(c)))

func buy_amount(i: int) -> int:
	match buy_mode:
		0: return 1
		1: return 10
		2: return 100
		_: return maxi(1, max_affordable(i))

func buy_business(i: int) -> bool:
	var n := buy_amount(i)
	var c := cost_of(i, n)
	if money < c:
		return false
	var before_speed := speed_level(i)
	money -= c
	owned[i] += n
	if not running[i] and managers[i]:
		running[i] = true
	_cache_t = 0.0
	if speed_level(i) > before_speed:
		toast.emit("%s: velocità x2!" % BUSINESSES[i]["name"], S.GOLD)
		Sfx.play("jackpot")
	else:
		Sfx.play("buy")
	check_achievements()
	return true

func manager_cost(i: int) -> float:
	var m: float = BUSINESSES[i]["mgr"] * pow(0.7, tal("contabile"))
	if has_charm("croupier"):
		m *= 0.6
	return m

func hire_manager(i: int) -> bool:
	if managers[i] or money < manager_cost(i) or owned[i] <= 0:
		return false
	money -= manager_cost(i)
	managers[i] = true
	running[i] = true
	_cache_t = 0.0
	Sfx.play("cash")
	return true

func start_cycle(i: int) -> bool:
	if owned[i] <= 0 or running[i]:
		return false
	running[i] = true
	return true

# ------------------------------------------------------------------ TICK
signal cycle_done(i: int, amount: float)

func earn(v: float) -> void:
	money += v
	run_earned += v
	all_earned += v

func _process(delta: float) -> void:
	stats["play_time"] += delta
	if frenzy_time > 0: frenzy_time = maxf(0.0, frenzy_time - delta)
	if luckboost_time > 0: luckboost_time = maxf(0.0, luckboost_time - delta)
	# Timer del Giorno / Scadenza dello Squalo
	if not deadline_paused and intro_seen:
		day_time_left -= delta
		if day_time_left <= 0.0:
			_trigger_deadline_timeout()
	for i in BUSINESSES.size():
		if owned[i] <= 0 or not running[i]:
			continue
		var t := cycle_time(i)
		progress[i] += delta / t
		if progress[i] >= 1.0:
			var cycles := 1.0
			if managers[i]:
				cycles = floor(progress[i])
				progress[i] -= cycles
			else:
				progress[i] = 0.0
				running[i] = false
			var amt := cycle_revenue(i) * cycles
			earn(amt)
			cycle_done.emit(i, amt)
	_cache_t -= delta
	if _cache_t <= 0:
		_cache_t = 0.4
		_cache_ips = income_per_sec(true)
	if tal("autogratta") > 0 and not deadline_paused:
		_auto_scratch_t += delta
		if _auto_scratch_t >= auto_interval(tal("autogratta")):
			_auto_scratch_t = 0.0
			_auto_play("scratch")
	if tal("autoleva") > 0 and not deadline_paused:
		_auto_spin_t += delta
		if _auto_spin_t >= auto_interval(tal("autoleva")):
			_auto_spin_t = 0.0
			_auto_play("slot")
	_ach_t -= delta
	if _ach_t <= 0:
		_ach_t = 1.0
		check_achievements()
	_shark_t -= delta
	if _shark_t <= 0:
		_shark_t = randf_range(55, 110)
		toast.emit(SHARK_LINES.pick_random(), S.RED)
	_autosave_t += delta
	if _autosave_t > 10.0:
		_autosave_t = 0.0
		save_game()

signal auto_result(kind: String, win: float)

func _auto_play(kind: String) -> void:
	var st := base_stake() * 0.5
	var win := 0.0
	if kind == "scratch":
		var r := roll_scratch()
		win = r["win"] * st * (1.5 if has_charm("zampa") else 1.0)
		stats["scratch"] += 1
	else:
		var r := roll_slot()
		win = r["mult"] * st
		stats["spins"] += 1
	win *= game_mult()
	if win > 0:
		earn(win)
		auto_result.emit(kind, win)

# ------------------------------------------------------------------ MINIGIOCHI
func _weighted_pick(items: Array, key := "w") -> Dictionary:
	var tot := 0.0
	for it in items:
		tot += it[key]
	var r := randf() * tot
	for it in items:
		r -= it[key]
		if r <= 0:
			return it
	return items[-1]

func scratch_win_chance() -> float:
	return minf(0.72, 0.36 + 0.018 * luck())

func roll_scratch() -> Dictionary:
	var grid := []
	var win := 0.0
	var wsym := ""
	if randf() < scratch_win_chance():
		var p := _weighted_pick(SCRATCH_PRIZES)
		wsym = p["sym"]
		win = p["mult"] * (1.5 if has_charm("zampa") else 1.0)
		grid = [wsym, wsym, wsym]
	var counts := {}
	for s in grid:
		counts[s] = counts.get(s, 0) + 1
	while grid.size() < 9:
		var s: String = S.SYMBOLS.pick_random()
		if counts.get(s, 0) >= 2 or (s == wsym):
			continue
		counts[s] = counts.get(s, 0) + 1
		grid.append(s)
	grid.shuffle()
	return {"grid": grid, "win": win, "sym": wsym}

func _slot_symbol() -> String:
	var weights := SLOT_WEIGHTS.duplicate()
	if has_charm("magnete"):
		weights["seven"] = weights["seven"] * 3.2
		weights["diamond"] = weights["diamond"] * 1.8
	var tot := 0.0
	for k in weights:
		tot += weights[k]
	var r := randf() * tot
	for k in weights:
		r -= weights[k]
		if r <= 0:
			return k
	return "cherry"

func _slot_eval(reels: Array) -> Dictionary:
	if reels[0] == reels[1] and reels[1] == reels[2]:
		return {"mult": SLOT_PAY[reels[0]], "kind": "tris", "sym": reels[0]}
	if reels[0] == reels[1] or reels[1] == reels[2] or reels[0] == reels[2]:
		return {"mult": 2.5, "kind": "coppia", "sym": ""}
	return {"mult": 0.0, "kind": "", "sym": ""}

func roll_slot() -> Dictionary:
	var reels := [_slot_symbol(), _slot_symbol(), _slot_symbol()]
	var res := _slot_eval(reels)
	if res["mult"] == 0.0 and randf() < minf(0.55, 0.045 * luck()):
		reels = [_slot_symbol(), _slot_symbol(), _slot_symbol()]
		res = _slot_eval(reels)
	res["reels"] = reels
	return res

func dice_bonus_chance() -> float:
	return minf(0.6, 0.04 * tal("dadi") + 0.02 * luck() + (0.15 if has_charm("dado_piombo") else 0.0))

func roll_dice(bet: int) -> Dictionary:
	var d := [randi_range(1, 6), randi_range(1, 6)]
	var won := _dice_win(bet, d[0] + d[1])
	if not won and randf() < dice_bonus_chance():
		d = [randi_range(1, 6), randi_range(1, 6)]
		won = _dice_win(bet, d[0] + d[1])
	var mult := 0.0
	if won:
		mult = 6.0 if bet == 1 else 2.5
		if d[0] == d[1]:
			mult *= (4.0 if has_charm("dado_piombo") else 2.0)
	return {"dice": d, "mult": mult}

func _dice_win(bet: int, sum: int) -> bool:
	match bet:
		0: return sum < 7
		1: return sum == 7
		_: return sum > 7

func double_chance() -> float:
	return minf(0.75, 0.52 + 0.04 * tal("dadi") + 0.005 * luck() + (0.10 if has_charm("teschio") else 0.0))

func register_win(win: float, st: float, label := "") -> void:
	if win > stats["biggest_win"]:
		stats["biggest_win"] = win
	if win >= st * 10.0:
		Sfx.trigger_hype(14.0)
	if win >= st * 50.0:
		big_win.emit(win, label)

# ------------------------------------------------------------------ GATTO
func cat_interval() -> float:
	return randf_range(35.0, 75.0) / (2.0 if has_charm("gatto_oro") else 1.0)

func cat_duration() -> float:
	return 11.0

func claim_cat() -> void:
	stats["cats"] += 1
	if has_charm("gatto_oro"):
		tickets += 2
		total_tickets_earned += 2
	var r := randf()
	if r < 0.40:
		frenzy_time = 30.0
		cat_reward.emit("FRENESIA! Attività x7 per 30s" + (" (+2 Ticket!)" if has_charm("gatto_oro") else ""))
	elif r < 0.72:
		var v: float = maxf(income_per_sec(false) * 45.0, maxf(money * 0.35, 50.0))
		earn(v)
		cat_reward.emit("Il gatto sputa monete: +%s" % fmt(v))
	else:
		luckboost_time = 30.0
		tickets += 1
		total_tickets_earned += 1
		cat_reward.emit("FORTUNA x5 (30s) + 1 TICKET D'ORO!")
	_cache_t = 0.0
	Sfx.play("jackpot")

# ------------------------------------------------------------------ SALVATAGGIO
func save_game() -> void:
	var d := {
		"v": SAVE_VERSION, "time": Time.get_unix_time_from_system(),
		"money": money, "run_earned": run_earned, "all_earned": all_earned,
		"owned": owned, "managers": managers, "progress": progress, "running": running,
		"upgrades": upgrades_bought.keys(), "clovers": clovers, "clovers_spent": clovers_spent,
		"tickets": tickets, "total_tickets": total_tickets_earned,
		"talismans": talismans, "charms": equipped_charms, "shop": shop_offers,
		"deadline_idx": deadline_idx, "day_in_deadline": day_in_deadline, "day_time_left": day_time_left,
		"debt_paid": debt_paid, "cities_cleared": cities_cleared, "best_deadline": best_deadline, "runs_played": runs_played,
		"stats": stats, "achievements": achievements.keys(), "buy_mode": buy_mode,
		"sfx": sfx_on, "music": music_on, "intro": intro_seen,
	}
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))

var offline_report := 0.0
var offline_seconds := 0.0

func load_game() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var f := FileAccess.open(save_path, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return
	money = d.get("money", 15.0)
	run_earned = d.get("run_earned", 0.0)
	all_earned = d.get("all_earned", 0.0)
	var o: Array = d.get("owned", [])
	for i in mini(o.size(), owned.size()):
		owned[i] = int(o[i])
		managers[i] = bool(d.get("managers", [])[i]) if i < d.get("managers", []).size() else false
		progress[i] = float(d.get("progress", [])[i]) if i < d.get("progress", []).size() else 0.0
		running[i] = bool(d.get("running", [])[i]) if i < d.get("running", []).size() else false
	upgrades_bought.clear()
	for k in d.get("upgrades", []):
		upgrades_bought[k] = true
	clovers = d.get("clovers", 0.0)
	clovers_spent = d.get("clovers_spent", 0.0)
	tickets = int(d.get("tickets", 3))
	total_tickets_earned = int(d.get("total_tickets", tickets))
	talismans = d.get("talismans", {})
	equipped_charms = d.get("charms", [])
	shop_offers = d.get("shop", [])
	deadline_idx = int(d.get("deadline_idx", d.get("city", 0)))
	day_in_deadline = int(d.get("day_in_deadline", 1))
	day_time_left = float(d.get("day_time_left", day_duration()))
	debt_paid = d.get("debt_paid", 0.0)
	cities_cleared = int(d.get("cities_cleared", 0))
	best_deadline = int(d.get("best_deadline", cities_cleared))
	runs_played = int(d.get("runs_played", 1))
	var st: Dictionary = d.get("stats", {})
	for k in st:
		stats[k] = st[k]
	achievements.clear()
	for k in d.get("achievements", []):
		achievements[k] = true
	buy_mode = int(d.get("buy_mode", 0))
	sfx_on = d.get("sfx", true)
	music_on = d.get("music", true)
	intro_seen = d.get("intro", false)
	var elapsed: float = clampf(Time.get_unix_time_from_system() - float(d.get("time", 0)), 0.0, 86400.0)
	if elapsed > 30:
		var v := income_per_sec(true) * elapsed * 0.5
		if v > 0:
			earn(v)
			offline_report = v
			offline_seconds = elapsed

func hard_reset() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	get_tree().reload_current_scene()

# ------------------------------------------------------------------ FORMATTAZIONE
const SUFFIX := ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod", "Vg"]

func num(v: float) -> String:
	if is_nan(v) or is_inf(v):
		return "MAX"
	var neg := v < 0
	v = absf(v)
	var s := ""
	if v < 1000.0:
		if v < 10.0 and v != floor(v):
			s = "%.2f" % v
		elif v < 100.0 and v != floor(v):
			s = "%.1f" % v
		else:
			s = "%d" % int(floor(v))
	else:
		var e := int(floor(log(v) / log(1000.0)))
		var m := v / pow(1000.0, e)
		if m >= 999.995:
			m /= 1000.0
			e += 1
		var suf := ""
		if e < SUFFIX.size():
			suf = SUFFIX[e]
		else:
			var k := e - SUFFIX.size()
			suf = char(97 + int(k / 26) % 26) + char(97 + k % 26)
		s = "%.2f%s" % [m, suf] if m < 100 else "%.1f%s" % [m, suf]
	return ("-" if neg else "") + s

func fmt(v: float) -> String:
	return "€" + num(v)

func fmt_time(t: float) -> String:
	if t < 1.0:
		return "%.1fs" % t
	var s := int(ceil(t))
	if s < 60:
		return "%ds" % s
	if s < 3600:
		return "%d:%02d" % [s / 60, s % 60]
	return "%d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]
