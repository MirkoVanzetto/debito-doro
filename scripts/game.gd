extends Node
## Autoload "G": stato del gioco, dati, economia, salvataggio.

signal toast(text: String, color: Color)
signal story(title: String, body: String, button: String)
signal big_win(amount: float, label: String)
signal achievement_unlocked(name: String)
signal state_reset
signal cat_reward(text: String)

const SAVE_VERSION := 1
var save_path := "user://save.json"

# ------------------------------------------------------------------ DATI
const BUSINESSES := [
	{"name": "Edicola Gratta&Vinci", "desc": "I pensionati grattano, tu incassi.", "icon": "ticket", "color": Color("f2b632"),
	 "cost": 4.0, "coef": 1.07, "rev": 1.0, "time": 0.8, "mgr": 1000.0},
	{"name": "Slot del Bar Sport", "desc": "Una macchinetta vicino al flipper.", "icon": "slot", "color": Color("d6344a"),
	 "cost": 60.0, "coef": 1.15, "rev": 60.0, "time": 3.0, "mgr": 15000.0},
	{"name": "Sala Bingo", "desc": "Nonne agguerrite, cartelle infinite.", "icon": "bingo", "color": Color("3a6fd8"),
	 "cost": 720.0, "coef": 1.14, "rev": 540.0, "time": 6.0, "mgr": 100000.0},
	{"name": "Agenzia Ippica", "desc": "Cavalli, fantini e soffiate.", "icon": "horse", "color": Color("8a5a3c"),
	 "cost": 8640.0, "coef": 1.13, "rev": 4320.0, "time": 12.0, "mgr": 500000.0},
	{"name": "Poker Clandestino", "desc": "Retrobottega, fumo e bluff.", "icon": "cards", "color": Color("2bb3a3"),
	 "cost": 103680.0, "coef": 1.12, "rev": 51840.0, "time": 24.0, "mgr": 1.2e6},
	{"name": "Roulette Truccata", "desc": "Il banco vince. Il banco sei tu.", "icon": "roulette", "color": Color("1b1420"),
	 "cost": 1.24416e6, "coef": 1.11, "rev": 622080.0, "time": 96.0, "mgr": 1e7},
	{"name": "Lotteria Nazionale", "desc": "Un'intera nazione che sogna.", "icon": "lottery", "color": Color("ff6fae"),
	 "cost": 1.492992e7, "coef": 1.10, "rev": 7.46496e6, "time": 384.0, "mgr": 1.11e8},
	{"name": "Casinò Galleggiante", "desc": "In acque internazionali, niente tasse.", "icon": "ship", "color": Color("f07f2e"),
	 "cost": 1.7915904e8, "coef": 1.09, "rev": 8.957952e7, "time": 1536.0, "mgr": 5.55e8},
	{"name": "Crypto-Casinò", "desc": "Scommesse sulla blockchain. Fidati.", "icon": "crypto", "color": Color("8a4fd1"),
	 "cost": 2.14990848e9, "coef": 1.08, "rev": 1.074954240e9, "time": 6144.0, "mgr": 1e10},
	{"name": "Casinò Lunare", "desc": "Gravità bassa, puntate altissime.", "icon": "moon", "color": Color("5ac35a"),
	 "cost": 2.579890176e10, "coef": 1.07, "rev": 2.9668737024e10, "time": 36864.0, "mgr": 1e11},
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

const CITIES := [
	{"name": "Napoli", "debt": 1e6, "boss": "Zio Tano 'o Squalo"},
	{"name": "Montecarlo", "debt": 1e9, "boss": "Le Requin"},
	{"name": "Las Vegas", "debt": 1e12, "boss": "Big Shark Tony"},
	{"name": "Macao", "debt": 1e15, "boss": "Madame Shā"},
	{"name": "Dubai", "debt": 1e18, "boss": "Lo Sceicco Pinna"},
	{"name": "Luna", "debt": 1e21, "boss": "Lo Squalo Spaziale"},
	{"name": "Marte", "debt": 1e25, "boss": "Il Megalodonte"},
]

const SPEED_MILESTONES := [25, 50, 100, 200, 300, 400]
const SYNERGY_MILESTONES := [10, 25, 50, 100, 200, 300, 400, 500, 750, 1000]

# Talismani: costi in quadrifogli (sacrificati come in AdCap)
const TALISMANS := [
	{"id": "cornetto", "name": "Cornetto Rosso", "desc": "Inizi ogni fuga con più soldi.", "base": 3.0, "grow": 3.0, "max": 10},
	{"id": "ferro", "name": "Ferro di Cavallo", "desc": "+1 Fortuna permanente.", "base": 2.0, "grow": 2.2, "max": 15},
	{"id": "gatto", "name": "Gatto Nero", "desc": "Il gatto dorato appare più spesso.", "base": 8.0, "grow": 3.0, "max": 5},
	{"id": "autogratta", "name": "Grattatore Automatico", "desc": "Gratta biglietti da solo.", "base": 12.0, "grow": 3.0, "max": 5},
	{"id": "autoleva", "name": "Leva Automatica", "desc": "Gira la slot da sola.", "base": 25.0, "grow": 3.0, "max": 5},
	{"id": "contabile", "name": "Contabile Corrotto", "desc": "Manager -30% di costo per livello.", "base": 6.0, "grow": 4.0, "max": 3},
	{"id": "salvadanaio", "name": "Salvadanaio", "desc": "Guadagni offline +10% per livello.", "base": 4.0, "grow": 2.5, "max": 5},
	{"id": "quadrifoglio", "name": "Quadrifoglio d'Oro", "desc": "Ogni quadrifoglio dà +1% in più.", "base": 20.0, "grow": 2.5, "max": 10},
	{"id": "dadi", "name": "Dadi Truccati", "desc": "+3% vittoria su Raddoppia e Dadi.", "base": 5.0, "grow": 2.5, "max": 5},
]

const SCRATCH_PRIZES := [
	{"sym": "cherry", "mult": 1.0, "w": 45.0},
	{"sym": "lemon", "mult": 2.0, "w": 25.0},
	{"sym": "bell", "mult": 3.0, "w": 14.0},
	{"sym": "clover", "mult": 5.0, "w": 9.0},
	{"sym": "horseshoe", "mult": 10.0, "w": 5.0},
	{"sym": "diamond", "mult": 50.0, "w": 1.7},
	{"sym": "seven", "mult": 500.0, "w": 0.3},
]
const SLOT_WEIGHTS := {"cherry": 30.0, "lemon": 25.0, "bell": 18.0, "clover": 12.0, "horseshoe": 8.0, "diamond": 5.0, "seven": 2.0}
const SLOT_PAY := {"cherry": 5.0, "lemon": 8.0, "bell": 15.0, "clover": 30.0, "horseshoe": 60.0, "diamond": 200.0, "seven": 1000.0}

const SHARK_LINES := [
	"Lo Squalo: \"Ricordati di me. Io mi ricordo di te.\"",
	"Lo Squalo: \"Bel posto. Sarebbe un peccato se prendesse fuoco.\"",
	"Lo Squalo: \"Gli interessi non dormono. Nemmeno io.\"",
	"Lo Squalo: \"Hai visto il mio dente d'oro? L'ho preso all'ultimo che non pagava.\"",
	"Lo Squalo: \"Tic tac. Tic tac.\"",
	"Lo Squalo: \"Mia madre dice che sei un bravo ragazzo. Dimostralo.\"",
	"Lo Squalo: \"Oggi mi sento generoso. Domani no.\"",
	"Un tizio in giacca ti fissa dall'angolo. Meglio pagare.",
]

# ------------------------------------------------------------------ STATO
var money := 5.0
var run_earned := 0.0
var all_earned := 0.0
var owned: Array = []
var managers: Array = []
var progress: Array = []
var running: Array = []
var upgrades_bought := {}
var clovers := 0.0
var clovers_spent := 0.0
var talismans := {}
var city := 0
var debt_paid := 0.0
var cities_cleared := 0
var stats := {"scratch": 0, "spins": 0, "rolls": 0, "jackpots": 0, "cats": 0, "best_double": 0, "prestiges": 0, "biggest_win": 0.0, "play_time": 0.0}
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
var _shark_t := 90.0
var _ach_t := 0.0
var _auto_scratch_t := 0.0
var _auto_spin_t := 0.0
var _cache_ips := 0.0
var _cache_t := 0.0

func _ready() -> void:
	_build_upgrades()
	_build_achievements()
	_reset_run_arrays()
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a == "--fresh":
			save_path = "user://save_test.json"
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	load_game()

func _reset_run_arrays() -> void:
	owned.clear(); managers.clear(); progress.clear(); running.clear()
	for i in BUSINESSES.size():
		owned.append(0); managers.append(false); progress.append(0.0); running.append(false)

# ------------------------------------------------------------------ UPGRADES
func _build_upgrades() -> void:
	UPGRADES.clear()
	var flavor := ["Insegna al neon", "Biglietti dorati", "Musica da ascensore", "Ragazze immagine", "Cocktail gratis", "Moquette ipnotica", "Orologi spariti", "Ossigeno in sala"]
	# tier iniziale x2 (prezzo legato al costo base)
	for i in BUSINESSES.size():
		UPGRADES.append({"id": "e%d" % i, "name": "Cartello luminoso", "target": i, "mult": 2.0, "cost": BUSINESSES[i]["cost"] * 250.0})
	for t in 8:
		for i in BUSINESSES.size():
			var cost := 2.5e5 * pow(10.0, 0.6 * i) * pow(1e6, t)
			UPGRADES.append({"id": "t%d_%d" % [t, i], "name": flavor[t], "target": i, "mult": 3.0, "cost": cost})
		UPGRADES.append({"id": "all%d" % t, "name": "Campagna pubblicitaria %d" % (t + 1), "target": -1, "mult": 3.0, "cost": 1.5e11 * pow(1e6, t)})
	# minigiochi
	var gnames := ["Monetina fortunata", "Unghie d'acciaio", "Leva oliata", "Dadi d'avorio", "Occhio di tigre", "Sorriso del banco", "Talento naturale", "Mano santa"]
	for k in 8:
		UPGRADES.append({"id": "g%d" % k, "name": gnames[k], "target": -2, "mult": 2.0, "cost": 500.0 * pow(80.0, k)})
	var lnames := ["Cornicello in tasca", "Calzini fortunati", "Santino nel portafoglio", "Coccinella sul cappello", "Oroscopo favorevole", "Numero 17 evitato"]
	for k in 6:
		UPGRADES.append({"id": "l%d" % k, "name": lnames[k], "target": -3, "mult": 1.0, "cost": 2000.0 * pow(400.0, k)})
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
	for p in [3, 6, 9, 12, 15, 18, 21, 24, 30]:
		ACHIEVEMENTS.append({"id": "earn%d" % p, "name": "Guadagna %s in totale" % fmt(pow(10.0, p)), "kind": "earn", "n": pow(10.0, p)})
	for n in [10, 100, 1000, 10000]:
		ACHIEVEMENTS.append({"id": "sc%d" % n, "name": "Gratta %d biglietti" % n, "kind": "stat", "stat": "scratch", "n": n})
		ACHIEVEMENTS.append({"id": "sp%d" % n, "name": "Gira la slot %d volte" % n, "kind": "stat", "stat": "spins", "n": n})
		ACHIEVEMENTS.append({"id": "dr%d" % n, "name": "Lancia i dadi %d volte" % n, "kind": "stat", "stat": "rolls", "n": n})
	for n in [1, 10, 50]:
		ACHIEVEMENTS.append({"id": "jp%d" % n, "name": "Fai %d jackpot" % n, "kind": "stat", "stat": "jackpots", "n": n})
	for n in [1, 10, 50, 200]:
		ACHIEVEMENTS.append({"id": "cat%d" % n, "name": "Accarezza %d gatti dorati" % n, "kind": "stat", "stat": "cats", "n": n})
	for n in [3, 5, 8, 10]:
		ACHIEVEMENTS.append({"id": "dbl%d" % n, "name": "Raddoppia %d volte di fila" % n, "kind": "stat", "stat": "best_double", "n": n})
	for n in [1, 3, 10, 25]:
		ACHIEVEMENTS.append({"id": "pr%d" % n, "name": "Fuggi %d volte" % n, "kind": "stat", "stat": "prestiges", "n": n})
	for n in [1, 2, 3, 5, 7]:
		ACHIEVEMENTS.append({"id": "city%d" % n, "name": "Ripaga %d Squali" % n, "kind": "city", "n": n})

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

# ------------------------------------------------------------------ TALISMANI
func tal(id: String) -> int:
	return int(talismans.get(id, 0))

func tal_def(id: String) -> Dictionary:
	for t in TALISMANS:
		if t["id"] == id:
			return t
	return {}

func tal_cost(id: String) -> float:
	var d := tal_def(id)
	return ceil(d["base"] * pow(d["grow"], tal(id)))

func buy_talisman(id: String) -> bool:
	var d := tal_def(id)
	if tal(id) >= d["max"]:
		return false
	var c := tal_cost(id)
	if clovers < c:
		return false
	clovers -= c
	clovers_spent += c
	talismans[id] = tal(id) + 1
	Sfx.play("jackpot")
	_cache_t = 0.0
	return true

func tal_effect_text(id: String, lvl: int) -> String:
	match id:
		"cornetto": return "Soldi iniziali: %s" % fmt(start_money_for(lvl))
		"ferro": return "Fortuna +%d" % lvl
		"gatto": return "Frequenza gatto x%.1f" % (1.0 + 0.35 * lvl)
		"autogratta": return "Off" if lvl == 0 else "1 biglietto ogni %.1fs" % auto_interval(lvl)
		"autoleva": return "Off" if lvl == 0 else "1 giro ogni %.1fs" % auto_interval(lvl)
		"contabile": return "Manager -%d%%" % int((1.0 - pow(0.7, lvl)) * 100)
		"salvadanaio": return "Offline %d%%" % (50 + 10 * lvl)
		"quadrifoglio": return "+%d%% per quadrifoglio" % (2 + lvl)
		"dadi": return "+%d%% vittoria" % (3 * lvl)
	return ""

func start_money_for(lvl: int) -> float:
	return 5.0 if lvl == 0 else 10.0 * pow(10.0, lvl)

func auto_interval(lvl: int) -> float:
	return 4.0 / (1.0 + 0.6 * (lvl - 1))

# ------------------------------------------------------------------ MOLTIPLICATORI
func clover_eff() -> float:
	return 0.02 + 0.01 * tal("quadrifoglio")

func clover_mult() -> float:
	return 1.0 + clovers * clover_eff()

func city_mult() -> float:
	return pow(3.0, cities_cleared)

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
	return BUSINESSES[i]["time"] / pow(2.0, speed_level(i))

func cycle_revenue(i: int) -> float:
	return BUSINESSES[i]["rev"] * owned[i] * upgrade_mult(i) * milestone_profit_mult(i) * global_mult()

func luck() -> int:
	var l := tal("ferro")
	for u in UPGRADES:
		if u["target"] == -3 and upgrades_bought.has(u["id"]):
			l += 1
	return l

func game_mult() -> float:
	var m := clover_mult() * city_mult()
	for u in UPGRADES:
		if u["target"] == -2 and upgrades_bought.has(u["id"]):
			m *= u["mult"]
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

## Puntata base dei minigiochi: scala con le entrate ma resta sempre giocabile a x1.
func base_stake() -> float:
	var ips := income_per_sec(false)
	var s := maxf(1.0, minf(maxf(1.0, ips * 2.5), maxf(1.0, money * 0.25)))
	var p := pow(10.0, floor(log(s) / log(10.0)))
	return maxf(1.0, floor(s / p) * p)

func stake() -> float:
	return base_stake() * stake_mult

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
		_: return max(1, max_affordable(i))

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
	return BUSINESSES[i]["mgr"] * pow(0.7, tal("contabile"))

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
	if frenzy_time > 0: frenzy_time = max(0.0, frenzy_time - delta)
	if luckboost_time > 0: luckboost_time = max(0.0, luckboost_time - delta)
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
	# cache entrate
	_cache_t -= delta
	if _cache_t <= 0:
		_cache_t = 0.5
		_cache_ips = income_per_sec(true)
	# auto-minigiochi
	if tal("autogratta") > 0:
		_auto_scratch_t += delta
		if _auto_scratch_t >= auto_interval(tal("autogratta")):
			_auto_scratch_t = 0.0
			_auto_play("scratch")
	if tal("autoleva") > 0:
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
		_shark_t = randf_range(120, 240)
		if true:
			toast.emit(SHARK_LINES.pick_random(), S.RED)
	_autosave_t += delta
	if _autosave_t > 10.0:
		_autosave_t = 0.0
		save_game()

signal auto_result(kind: String, win: float)

func _auto_play(kind: String) -> void:
	var st := base_stake()
	if money < st:
		return
	money -= st
	var win := 0.0
	if kind == "scratch":
		var r := roll_scratch()
		win = r["win"] * st
		stats["scratch"] += 1
	else:
		var r := roll_slot()
		win = r["mult"] * st
		stats["spins"] += 1
	win *= game_mult()
	if win > 0:
		earn(win)
	auto_result.emit(kind, win - st)

# ------------------------------------------------------------------ MINIGIOCHI (logica)
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
	return min(0.6, 0.28 + 0.015 * luck())

## Restituisce {"grid": [9 simboli], "win": moltiplicatore, "sym": simbolo vincente}
func roll_scratch() -> Dictionary:
	var grid := []
	var win := 0.0
	var wsym := ""
	if randf() < scratch_win_chance():
		var p := _weighted_pick(SCRATCH_PRIZES)
		wsym = p["sym"]
		win = p["mult"]
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
	var tot := 0.0
	for k in SLOT_WEIGHTS:
		tot += SLOT_WEIGHTS[k]
	var r := randf() * tot
	for k in SLOT_WEIGHTS:
		r -= SLOT_WEIGHTS[k]
		if r <= 0:
			return k
	return "cherry"

func _slot_eval(reels: Array) -> Dictionary:
	if reels[0] == reels[1] and reels[1] == reels[2]:
		return {"mult": SLOT_PAY[reels[0]], "kind": "tris", "sym": reels[0]}
	if reels[0] == reels[1] or reels[1] == reels[2] or reels[0] == reels[2]:
		return {"mult": 2.0, "kind": "coppia", "sym": ""}
	return {"mult": 0.0, "kind": "", "sym": ""}

func roll_slot() -> Dictionary:
	var reels := [_slot_symbol(), _slot_symbol(), _slot_symbol()]
	var res := _slot_eval(reels)
	if res["mult"] == 0.0 and randf() < min(0.45, 0.04 * luck()):
		reels = [_slot_symbol(), _slot_symbol(), _slot_symbol()]
		res = _slot_eval(reels)
	res["reels"] = reels
	return res

func dice_bonus_chance() -> float:
	return min(0.5, 0.03 * tal("dadi") + 0.02 * luck())

## bet: 0 sotto, 1 sette, 2 sopra
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
			mult *= 2.0
	return {"dice": d, "mult": mult}

func _dice_win(bet: int, sum: int) -> bool:
	match bet:
		0: return sum < 7
		1: return sum == 7
		_: return sum > 7

func double_chance() -> float:
	return min(0.65, 0.5 + 0.03 * tal("dadi") + 0.005 * luck())

func register_win(win: float, st: float, label := "") -> void:
	if win > stats["biggest_win"]:
		stats["biggest_win"] = win
	if win >= st * 100.0:
		big_win.emit(win, label)

# ------------------------------------------------------------------ GATTO
func cat_interval() -> float:
	return randf_range(70.0, 180.0) / (1.0 + 0.35 * tal("gatto"))

func cat_duration() -> float:
	return 9.0 + 2.0 * tal("gatto")

func claim_cat() -> void:
	stats["cats"] += 1
	var r := randf()
	if r < 0.45:
		frenzy_time = 30.0
		cat_reward.emit("FRENESIA! Attività x7 per 30s")
	elif r < 0.75:
		var v: float = max(income_per_sec(false) * 600.0, money * 0.15, 25.0)
		earn(v)
		cat_reward.emit("Il gatto sputa monete: +%s" % fmt(v))
	else:
		luckboost_time = 30.0
		cat_reward.emit("FORTUNA SFACCIATA! Minigiochi x5 per 30s")
	_cache_t = 0.0
	Sfx.play("jackpot")

# ------------------------------------------------------------------ DEBITO / CITTÀ
func city_data() -> Dictionary:
	if city < CITIES.size():
		return CITIES[city]
	var n := city - CITIES.size() + 1
	return {"name": "Dimensione X-%d" % n, "debt": 1e25 * pow(1e4, n), "boss": "Lo Squalo Cosmico #%d" % n}

func debt_left() -> float:
	return max(0.0, city_data()["debt"] - debt_paid)

func pay_debt() -> float:
	var amt: float = min(money, debt_left())
	if amt <= 0:
		return 0.0
	money -= amt
	debt_paid += amt
	Sfx.play("cash")
	if debt_left() <= 0.0:
		var old := city_data()
		cities_cleared += 1
		city += 1
		debt_paid = 0.0
		_cache_t = 0.0
		var nxt := city_data()
		story.emit("DEBITO SALDATO!",
			"%s conta i soldi. Due volte. Poi sorride con tutti i denti.\n\n\"Sei a posto, ragazzo. Per ora.\"\n\nBONUS PERMANENTE: tutte le entrate x3!\n\nMa la voce gira... A %s c'è %s, e dice che ora devi a LUI %s, per \"diritti di passaggio\"." % [old["boss"], nxt["name"], nxt["boss"], fmt(nxt["debt"])],
			"Ah, ecco.")
		check_achievements()
	return amt

# ------------------------------------------------------------------ PRESTIGIO
func clovers_total_for(earned: float) -> float:
	return floor(3.0 * sqrt(earned / 1e6))

func clovers_claimable() -> float:
	return max(0.0, clovers_total_for(all_earned) - clovers - clovers_spent)

func prestige() -> void:
	var gain := clovers_claimable()
	clovers += gain
	stats["prestiges"] += 1
	money = start_money_for(tal("cornetto"))
	run_earned = 0.0
	_reset_run_arrays()
	upgrades_bought.clear()
	frenzy_time = 0.0
	luckboost_time = 0.0
	stake_mult = 1.0
	_cache_t = 0.0
	check_achievements()
	save_game()
	state_reset.emit()

# ------------------------------------------------------------------ SALVATAGGIO
func save_game() -> void:
	var d := {
		"v": SAVE_VERSION, "time": Time.get_unix_time_from_system(),
		"money": money, "run_earned": run_earned, "all_earned": all_earned,
		"owned": owned, "managers": managers, "progress": progress, "running": running,
		"upgrades": upgrades_bought.keys(), "clovers": clovers, "clovers_spent": clovers_spent,
		"talismans": talismans, "city": city, "debt_paid": debt_paid, "cities_cleared": cities_cleared,
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
	money = d.get("money", 5.0)
	run_earned = d.get("run_earned", 0.0)
	all_earned = d.get("all_earned", 0.0)
	var o: Array = d.get("owned", [])
	for i in min(o.size(), owned.size()):
		owned[i] = int(o[i])
		managers[i] = bool(d.get("managers", [])[i]) if i < d.get("managers", []).size() else false
		progress[i] = float(d.get("progress", [])[i]) if i < d.get("progress", []).size() else 0.0
		running[i] = bool(d.get("running", [])[i]) if i < d.get("running", []).size() else false
	upgrades_bought.clear()
	for k in d.get("upgrades", []):
		upgrades_bought[k] = true
	clovers = d.get("clovers", 0.0)
	clovers_spent = d.get("clovers_spent", 0.0)
	talismans = d.get("talismans", {})
	city = int(d.get("city", 0))
	debt_paid = d.get("debt_paid", 0.0)
	cities_cleared = int(d.get("cities_cleared", 0))
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
	# guadagni offline
	var elapsed: float = clamp(Time.get_unix_time_from_system() - float(d.get("time", 0)), 0.0, 86400.0)
	if elapsed > 30:
		var eff := 0.5 + 0.1 * tal("salvadanaio")
		var v := income_per_sec(true) * elapsed * eff
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
		return "∞"
	var neg := v < 0
	v = abs(v)
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
