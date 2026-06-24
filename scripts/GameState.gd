extends Node
# GameState — autoload, drives all game logic and emits signals for the UI

signal state_changed
signal run_started
signal run_ended(victory: bool, relic_choices: Array)
signal prestige_happened(new_level: int)
signal game_complete(ascension: int, relics_collected: Array)
signal milestone_reached(milestone: Dictionary)

# ── Meta progress (survives full reset) ───────────────────────────────────────
var ascension_count: int = 0           # completed full runs (Miner→Alch→Mage)

# ── Idle state ────────────────────────────────────────────────────────────────
var prestige_level: int = 0            # 0=Miner, 1=Alchemist, 2=Mage
var resources: Array[float] = [0.0, 0.0, 0.0]
var building_counts: Array[int] = [0, 0, 0, 0, 0]
var upgrades_bought: Array[bool] = [false, false, false, false, false]
var relics_owned: Array = []           # list of relic id strings collected this run
var run_available: bool = false
var prev_r2_amount: float = 0.0       # for "Ancient Knowledge" relic

# ── Run state ─────────────────────────────────────────────────────────────────
var run_active: bool = false
var run_room: int = 0                  # 0-3 regular, 4 = boss
var player_hp: int = 100
var player_max_hp: int = 100
var player_attack: int = 12
var player_defense_this_round: int = 0
var enemy_data: Dictionary = {}
var enemy_hp: int = 0
var enemy_next_action: String = "attack"  # "attack" | "special" | "defend"
var combat_log: Array[String] = []
var pending_relic_choices: Array = []

# ── Computed multipliers (recalculated when relics change) ────────────────────
var _production_mult: float = 1.0
var _cost_reduction: float = 0.0
var _click_mult: float = 1.0
var _offline_mult: float = 1.0

func _ready() -> void:
	SaveManager.load_game()
	_recalculate_multipliers()
	state_changed.emit()

func _process(delta: float) -> void:
	if run_active:
		return
	var changed := false
	var unlocked = GameData.unlocked_building_count(prestige_level, ascension_count)
	for i in unlocked:
		var bdata = GameData.BUILDINGS[prestige_level][i]
		var count = building_counts[i]
		if count == 0:
			continue
		var produced = bdata["base_production"] * count * delta * _production_mult * _building_mult(i) * _global_upgrade_mult()
		resources[bdata["produces"]] += produced
		changed = true
	if changed:
		_check_prestige_goal()
		state_changed.emit()

# ── Helpers ───────────────────────────────────────────────────────────────────
func _building_mult(building_index: int) -> float:
	var upgrades = GameData.UPGRADES[prestige_level]
	var mult := 1.0
	for i in min(upgrades.size(), upgrades_bought.size()):
		var u = upgrades[i]
		if upgrades_bought[i] and u["type"] == "building" and u.get("building_index") == building_index:
			mult *= u["multiplier"]
	return mult

func _global_upgrade_mult() -> float:
	var upgrades = GameData.UPGRADES[prestige_level]
	var mult := 1.0
	for i in min(upgrades.size(), upgrades_bought.size()):
		var u = upgrades[i]
		if upgrades_bought[i] and u["type"] == "global":
			mult *= u["multiplier"]
	return mult

func ascension_production_bonus() -> float:
	return ascension_count * 0.10  # +10% per completed run

func _recalculate_multipliers() -> void:
	_production_mult = 1.0 + ascension_production_bonus()
	_cost_reduction = 0.0
	_click_mult = 1.0
	_offline_mult = 1.0
	for rid in relics_owned:
		for r in GameData.RELICS:
			if r["id"] == rid:
				match r["type"]:
					"production":    _production_mult += r["value"]
					"cost_reduction":_cost_reduction  += r["value"]
					"click":         _click_mult      *= r["value"]
					"offline":       _offline_mult    *= r["value"]

func _check_prestige_goal() -> void:
	var goal = GameData.prestige_goal(prestige_level, ascension_count)
	run_available = resources[2] >= goal

func building_cost(index: int) -> float:
	var raw = GameData.building_cost(prestige_level, index, building_counts[index])
	return max(1.0, floor(raw * (1.0 - _cost_reduction)))

func upgrade_cost(index: int) -> float:
	var u = GameData.UPGRADES[prestige_level][index]
	return u["cost"]

func production_per_sec(building_index: int) -> float:
	var bdata = GameData.BUILDINGS[prestige_level][building_index]
	return bdata["base_production"] * building_counts[building_index] * _production_mult * _building_mult(building_index) * _global_upgrade_mult()

# ── Actions ───────────────────────────────────────────────────────────────────
func click_resource() -> void:
	var click_amount = 1.0 * _click_mult
	# upgrade 0 is always the click upgrade
	if upgrades_bought[0]:
		var u = GameData.UPGRADES[prestige_level][0]
		click_amount = u["multiplier"] * _click_mult
	resources[0] += click_amount
	_check_prestige_goal()
	state_changed.emit()

func buy_building(index: int) -> void:
	var cost = building_cost(index)
	var bdata = GameData.BUILDINGS[prestige_level][index]
	var cost_res = bdata["cost_resource"]
	if resources[cost_res] < cost:
		return
	resources[cost_res] -= cost
	building_counts[index] += 1
	SaveManager.save_game()
	state_changed.emit()

func buy_upgrade(index: int) -> void:
	if upgrades_bought[index]:
		return
	var u = GameData.UPGRADES[prestige_level][index]
	var cost_res = u["cost_resource"]
	if resources[cost_res] < u["cost"]:
		return
	resources[cost_res] -= u["cost"]
	upgrades_bought[index] = true
	SaveManager.save_game()
	state_changed.emit()

# ── Prestige / Run ────────────────────────────────────────────────────────────
func start_prestige_run() -> void:
	if not run_available:
		return
	run_active = true
	run_room = 0
	player_defense_this_round = 0
	combat_log.clear()

	# Sqrt scaling = strong early gains, diminishing returns at high resource counts
	var r2 = resources[2]
	var r1 = resources[1]

	# ATK: base 12, +1 per sqrt(R2/50), capped at +18 (max ATK 30)
	var atk_bonus = int(sqrt(r2 / 50.0))
	player_attack = 12 + min(atk_bonus, 18)

	# MaxHP: base 100, +5 per sqrt(R1/10), capped at +150 (max HP 250)
	var hp_bonus = int(sqrt(r1 / 10.0)) * 5
	player_max_hp = 100 + min(hp_bonus, 150)

	player_hp = player_max_hp

	var diff_pct = int((enemy_scale() - 1.0) * 100)
	var diff_str = "Difficulty: ×%.2f (Ascension #%d)" % [enemy_scale(), ascension_count] if ascension_count > 0 else "Difficulty: Normal"
	combat_log.append("Run started — ATK: %d (+%d)   HP: %d (+%d)   %s" % [
		player_attack, player_attack - 12, player_max_hp, player_max_hp - 100, diff_str])
	_load_enemy(run_room)
	run_started.emit()

func enemy_scale() -> float:
	var base = pow(1.15, ascension_count)
	if ascension_count >= 5:  base *= 1.5   # Milestone 5 spike
	if ascension_count >= 10: base *= 1.5   # Milestone 10 spike
	return base

func _load_enemy(room: int) -> void:
	var enemies = GameData.ENEMIES[prestige_level]
	enemy_data = enemies[room].duplicate()
	var scale = enemy_scale()
	enemy_data["hp"]          = int(enemy_data["hp"]          * scale)
	enemy_data["atk"]         = int(enemy_data["atk"]         * pow(1.10, ascension_count))
	enemy_data["special_dmg"] = int(enemy_data["special_dmg"] * pow(1.10, ascension_count))
	# Update the special_desc to reflect scaled damage
	enemy_data["special_desc"] = enemy_data["special_desc"].split("(")[0].strip_edges() + " (%d)" % enemy_data["special_dmg"]
	enemy_hp = enemy_data["hp"]
	_pick_enemy_action()

func _pick_enemy_action() -> void:
	var r = randf()
	if r < 0.5:
		enemy_next_action = "attack"
	elif r < 0.8:
		enemy_next_action = "special"
	else:
		enemy_next_action = "defend"

func _enemy_action_label() -> String:
	match enemy_next_action:
		"attack":  return "%s plans to ATTACK (%d dmg)" % [enemy_data["name"], enemy_data["atk"]]
		"special": return "%s plans to use %s (%s)" % [enemy_data["name"], enemy_data["special"], enemy_data["special_desc"]]
		"defend":  return "%s plans to DEFEND (halves damage)" % enemy_data["name"]
	return ""

func get_enemy_telegraph() -> String:
	return _enemy_action_label()

func player_action(action: String) -> void:
	if not run_active:
		return
	player_defense_this_round = 0
	var log_lines: Array[String] = []

	# Player acts first
	match action:
		"attack":
			var dmg = player_attack
			if enemy_next_action == "defend":
				dmg = max(1, dmg / 2)
			enemy_hp -= dmg
			log_lines.append("You strike for %d damage." % dmg)
		"shield":
			player_defense_this_round = 15
			log_lines.append("You raise your shield (+15 defense).")
		"special":
			_handle_player_special(log_lines)

	# Check enemy death
	if enemy_hp <= 0:
		log_lines.append("%s is defeated!" % enemy_data["name"])
		combat_log.append_array(log_lines)
		_on_enemy_defeated()
		return

	# Enemy acts
	_handle_enemy_action(log_lines)

	# Check player death
	if player_hp <= 0:
		log_lines.append("You have been defeated...")
		combat_log.append_array(log_lines)
		_on_run_lost()
		return

	_pick_enemy_action()
	combat_log.append_array(log_lines)
	state_changed.emit()

func _handle_player_special(log_lines: Array[String]) -> void:
	match prestige_level:
		0:  # Shatter — 2x attack
			var dmg = player_attack * 2
			if enemy_next_action == "defend":
				dmg = max(1, dmg / 2)
			enemy_hp -= dmg
			log_lines.append("SHATTER! You deal %d damage!" % dmg)
		1:  # Brew — heal 25 HP
			var heal = 25
			player_hp = min(player_max_hp, player_hp + heal)
			log_lines.append("BREW! You recover %d HP." % heal)
		2:  # Arcane Blast — 3x attack
			var dmg = player_attack * 3
			if enemy_next_action == "defend":
				dmg = max(1, dmg / 2)
			enemy_hp -= dmg
			log_lines.append("ARCANE BLAST! You deal %d damage!" % dmg)

func _handle_enemy_action(log_lines: Array[String]) -> void:
	match enemy_next_action:
		"attack":
			var dmg = max(1, enemy_data["atk"] - player_defense_this_round)
			player_hp -= dmg
			log_lines.append("%s attacks for %d damage." % [enemy_data["name"], dmg])
		"special":
			var dmg = max(1, enemy_data["special_dmg"] - player_defense_this_round)
			player_hp -= dmg
			log_lines.append("%s uses %s for %d damage!" % [enemy_data["name"], enemy_data["special"], dmg])
		"defend":
			log_lines.append("%s braces itself." % enemy_data["name"])

func _on_enemy_defeated() -> void:
	run_room += 1
	if run_room >= 5:
		_on_run_won()
	else:
		# Restore 25% max HP between rooms
		var heal = int(player_max_hp * 0.25)
		player_hp = min(player_max_hp, player_hp + heal)
		combat_log.append("--- Room cleared! Healed %d HP (now %d/%d) ---" % [heal, player_hp, player_max_hp])
		combat_log.append("--- Entering room %d ---" % (run_room + 1))
		_load_enemy(run_room)
		state_changed.emit()

func _on_run_won() -> void:
	run_active = false
	prev_r2_amount = resources[2]
	# Pick 3 random unique relics the player doesn't own yet
	var available: Array = []
	for r in GameData.RELICS:
		if r["id"] not in relics_owned:
			available.append(r)
	available.shuffle()
	pending_relic_choices = available.slice(0, min(3, available.size()))
	run_ended.emit(true, pending_relic_choices)

func _on_run_lost() -> void:
	run_active = false
	run_ended.emit(false, [])

func choose_relic(relic_id: String) -> void:
	if relic_id != "":
		relics_owned.append(relic_id)
		_recalculate_multipliers()
	_do_prestige()

func _do_prestige() -> void:
	prestige_level += 1

	if prestige_level >= 3:
		# Full run complete — show ascension screen, don't reset yet
		game_complete.emit(ascension_count + 1, relics_owned.duplicate())
		return

	# "Ancient Knowledge" relic: start with 10% of previous R2
	var start_bonus = 0.0
	if "ancient_knowledge" in relics_owned:
		start_bonus = prev_r2_amount * 0.1

	resources = [start_bonus, 0.0, 0.0]
	building_counts = [0, 0, 0, 0, 0]
	upgrades_bought = [false, false, false, false, false]
	run_available = false
	SaveManager.save_game()
	prestige_happened.emit(prestige_level)
	state_changed.emit()

# Called when player clicks "Ascend" on the game complete screen
func do_ascension() -> void:
	var prev = ascension_count
	ascension_count += 1
	prestige_level = 0
	resources = [0.0, 0.0, 0.0]
	building_counts = [0, 0, 0, 0, 0]
	upgrades_bought = [false, false, false, false, false]
	relics_owned = []
	run_available = false
	_recalculate_multipliers()
	SaveManager.save_game()
	# Fire milestone signal if a threshold was just crossed
	if ascension_count in GameData.MILESTONES:
		milestone_reached.emit(GameData.MILESTONES[ascension_count])
	prestige_happened.emit(0)
	state_changed.emit()

# ── Offline progress ──────────────────────────────────────────────────────────
func apply_offline_progress(seconds: float) -> void:
	var capped = min(seconds, GameData.OFFLINE_CAP_SECONDS) * _offline_mult
	for i in 3:
		var bdata = GameData.BUILDINGS[prestige_level][i]
		if building_counts[i] == 0:
			continue
		var produced = bdata["base_production"] * building_counts[i] * capped * _production_mult * _building_mult(i)
		resources[bdata["produces"]] += produced
	_check_prestige_goal()
	state_changed.emit()

# ── Serialization helpers (called by SaveManager) ────────────────────────────
func to_dict() -> Dictionary:
	return {
		"ascension_count": ascension_count,
		"prestige_level": prestige_level,
		"resources": resources,
		"building_counts": building_counts,
		"upgrades_bought": upgrades_bought,
		"relics_owned": relics_owned,
		"timestamp": Time.get_unix_time_from_system(),
	}

func from_dict(d: Dictionary) -> void:
	ascension_count  = d.get("ascension_count", 0)
	prestige_level   = d.get("prestige_level", 0)
	var r = d.get("resources", [0.0, 0.0, 0.0])
	resources        = [float(r[0]), float(r[1]), float(r[2])]
	var bc = d.get("building_counts", [0, 0, 0, 0, 0])
	while bc.size() < 5: bc.append(0)
	building_counts = [int(bc[0]), int(bc[1]), int(bc[2]), int(bc[3]), int(bc[4])]
	var ub = d.get("upgrades_bought", [false, false, false, false, false])
	while ub.size() < 5: ub.append(false)
	upgrades_bought = [bool(ub[0]), bool(ub[1]), bool(ub[2]), bool(ub[3]), bool(ub[4])]
	relics_owned     = d.get("relics_owned", [])
	_recalculate_multipliers()
	_check_prestige_goal()
	var ts = d.get("timestamp", 0)
	if ts > 0:
		var elapsed = Time.get_unix_time_from_system() - ts
		if elapsed > 10:
			apply_offline_progress(elapsed)
