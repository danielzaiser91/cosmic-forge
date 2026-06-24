extends Node
# GameData — all static definitions, no runtime state

# ── Prestige level names ──────────────────────────────────────────────────────
const LEVEL_NAMES = ["The Miner", "The Alchemist", "The Mage"]
const LEVEL_THEMES = ["Depths of the Earth", "Arcane Laboratory", "Realm of Magic"]
const LEVEL_CLICK_LABELS = ["Mine Stone", "Gather Herbs", "Channel Mana"]

# ── Resources [level][index] ──────────────────────────────────────────────────
# Each level has 3 resources: R0 (basic), R1 (mid), R2 (prestige currency)
const RESOURCES: Array = [
	[  # Level 0 — Miner
		{"id": "stone",   "name": "Stone",   "icon": "🪨"},
		{"id": "iron",    "name": "Iron",    "icon": "⚙"},
		{"id": "gold",    "name": "Gold",    "icon": "🪙"},
	],
	[  # Level 1 — Alchemist
		{"id": "herbs",    "name": "Herbs",    "icon": "🌿"},
		{"id": "potions",  "name": "Potions",  "icon": "⚗"},
		{"id": "essence",  "name": "Essence",  "icon": "✨"},
	],
	[  # Level 2 — Mage
		{"id": "mana",     "name": "Mana",     "icon": "💧"},
		{"id": "spells",   "name": "Spells",   "icon": "📜"},
		{"id": "arcanum",  "name": "Arcanum",  "icon": "🔮"},
	],
]

# ── Buildings [level][index] ──────────────────────────────────────────────────
# produces: which resource index this building generates
# base_production: units per second per building
# base_cost: cost of first purchase
# cost_resource: which resource index to spend
const BUILDINGS: Array = [
	[  # Level 0
		{"name": "Quarry",        "produces": 0, "base_production": 1.0,  "base_cost": 10.0,  "cost_resource": 0},
		{"name": "Forge",         "produces": 1, "base_production": 0.4,  "base_cost": 15.0,  "cost_resource": 0},
		{"name": "Gold Mine",     "produces": 2, "base_production": 0.15, "base_cost": 20.0,  "cost_resource": 1},
		{"name": "Mithril Vein",  "produces": 2, "base_production": 0.10, "base_cost": 40.0,  "cost_resource": 1, "milestone": 2},
		{"name": "Dragon Forge",  "produces": 2, "base_production": 0.35, "base_cost": 100.0, "cost_resource": 2, "milestone": 10},
	],
	[  # Level 1
		{"name": "Garden",               "produces": 0, "base_production": 1.0,  "base_cost": 10.0,  "cost_resource": 0},
		{"name": "Laboratory",           "produces": 1, "base_production": 0.4,  "base_cost": 15.0,  "cost_resource": 0},
		{"name": "Distillery",           "produces": 2, "base_production": 0.15, "base_cost": 20.0,  "cost_resource": 1},
		{"name": "Philosopher's Alembic","produces": 2, "base_production": 0.10, "base_cost": 40.0,  "cost_resource": 1, "milestone": 2},
		{"name": "Eternal Crucible",     "produces": 2, "base_production": 0.35, "base_cost": 100.0, "cost_resource": 2, "milestone": 10},
	],
	[  # Level 2
		{"name": "Mana Font",    "produces": 0, "base_production": 1.0,  "base_cost": 10.0,  "cost_resource": 0},
		{"name": "Spellbook",    "produces": 1, "base_production": 0.4,  "base_cost": 15.0,  "cost_resource": 0},
		{"name": "Arcane Tower", "produces": 2, "base_production": 0.15, "base_cost": 20.0,  "cost_resource": 1},
		{"name": "Ley Nexus",    "produces": 2, "base_production": 0.10, "base_cost": 40.0,  "cost_resource": 1, "milestone": 2},
		{"name": "Void Crystal", "produces": 2, "base_production": 0.35, "base_cost": 100.0, "cost_resource": 2, "milestone": 10},
	],
]

# ── Upgrades [level][index] ───────────────────────────────────────────────────
# type: "click" = boosts manual click, "building" = multiplies building[building_index]
# cost_resource: which resource index to spend
# cost: flat cost
const UPGRADES: Array = [
	[  # Level 0
		{"name": "Sharp Pickaxe",   "desc": "Click gives x3 Stone",      "type": "click",    "multiplier": 3.0, "cost": 50.0,  "cost_resource": 0},
		{"name": "Blast Furnace",   "desc": "Forge production x2",        "type": "building", "building_index": 1, "multiplier": 2.0, "cost": 30.0, "cost_resource": 1},
		{"name": "Deep Veins",      "desc": "Gold Mine production x2",    "type": "building", "building_index": 2, "multiplier": 2.0, "cost": 50.0, "cost_resource": 2},
		{"name": "Grand Mastery",   "desc": "ALL buildings x2",           "type": "global",   "multiplier": 2.0, "cost": 150.0, "cost_resource": 2, "milestone": 5},
		{"name": "Earth's Blessing","desc": "ALL buildings x3",           "type": "global",   "multiplier": 3.0, "cost": 500.0, "cost_resource": 2, "milestone": 20},
	],
	[  # Level 1
		{"name": "Green Thumb",          "desc": "Click gives x3 Herbs",      "type": "click",    "multiplier": 3.0, "cost": 50.0,  "cost_resource": 0},
		{"name": "Potent Brew",          "desc": "Laboratory production x2",  "type": "building", "building_index": 1, "multiplier": 2.0, "cost": 30.0, "cost_resource": 1},
		{"name": "Pure Distillation",    "desc": "Distillery production x2",  "type": "building", "building_index": 2, "multiplier": 2.0, "cost": 50.0, "cost_resource": 2},
		{"name": "Eternal Brew",         "desc": "ALL buildings x2",          "type": "global",   "multiplier": 2.0, "cost": 150.0, "cost_resource": 2, "milestone": 5},
		{"name": "Alchemical Perfection","desc": "ALL buildings x3",          "type": "global",   "multiplier": 3.0, "cost": 500.0, "cost_resource": 2, "milestone": 20},
	],
	[  # Level 2
		{"name": "Mana Attunement",      "desc": "Click gives x3 Mana",       "type": "click",    "multiplier": 3.0, "cost": 50.0,  "cost_resource": 0},
		{"name": "Spell Mastery",        "desc": "Spellbook production x2",   "type": "building", "building_index": 1, "multiplier": 2.0, "cost": 30.0, "cost_resource": 1},
		{"name": "Arcane Focus",         "desc": "Arcane Tower production x2","type": "building", "building_index": 2, "multiplier": 2.0, "cost": 50.0, "cost_resource": 1},
		{"name": "Mana Surge",           "desc": "ALL buildings x2",          "type": "global",   "multiplier": 2.0, "cost": 150.0, "cost_resource": 2, "milestone": 5},
		{"name": "Arcane Transcendence", "desc": "ALL buildings x3",          "type": "global",   "multiplier": 3.0, "cost": 500.0, "cost_resource": 2, "milestone": 20},
	],
]

# ── Prestige goals ────────────────────────────────────────────────────────────
# How much of R2 is needed to unlock the prestige run
const PRESTIGE_GOALS: Array[float] = [1000.0, 500.0, 250.0]
const PRESTIGE_GOAL_LABELS: Array = ["1000 Gold", "500 Essence", "250 Arcanum"]

# ── Relics ────────────────────────────────────────────────────────────────────
# type: "production" | "cost_reduction" | "click" | "offline" | "start_bonus"
const RELICS: Array = [
	{"id": "iron_will",         "name": "Iron Will",         "icon": "🛡",  "desc": "+50% all production",         "type": "production",     "value": 0.5},
	{"id": "alchemists_touch",  "name": "Alchemist's Touch", "icon": "⚗",  "desc": "Buildings cost -20%",          "type": "cost_reduction", "value": 0.2},
	{"id": "time_warp",         "name": "Time Warp",         "icon": "⏳",  "desc": "Offline progress x2",          "type": "offline",        "value": 2.0},
	{"id": "golden_touch",      "name": "Golden Touch",      "icon": "✋",  "desc": "Click gives x5 (stacks)",      "type": "click",          "value": 5.0},
	{"id": "ancient_knowledge", "name": "Ancient Knowledge", "icon": "📖",  "desc": "Start with 10% of prev. R2",   "type": "start_bonus",    "value": 0.1},
	{"id": "eternal_flame",     "name": "Eternal Flame",     "icon": "🔥",  "desc": "+100% all production",         "type": "production",     "value": 1.0},
	{"id": "swift_hands",       "name": "Swift Hands",       "icon": "⚡",  "desc": "+25% all production",          "type": "production",     "value": 0.25},
	{"id": "mana_well",         "name": "Mana Well",         "icon": "💎",  "desc": "Buildings cost -10%",          "type": "cost_reduction", "value": 0.1},
]

# ── Run enemies [level] ───────────────────────────────────────────────────────
# Each level has 4 regular enemies + 1 boss
const ENEMIES: Array = [
	[  # Level 0 — Miner's Run
		{"name": "Cave Rat",     "hp": 28,  "atk": 6,  "special": "Gnaw",     "special_dmg": 10, "special_desc": "Bites for 10"},
		{"name": "Stone Golem",  "hp": 50,  "atk": 9,  "special": "Smash",    "special_dmg": 16, "special_desc": "Smashes for 16"},
		{"name": "Iron Guard",   "hp": 70,  "atk": 11, "special": "Bash",     "special_dmg": 18, "special_desc": "Bashes for 18"},
		{"name": "Cave Troll",   "hp": 85,  "atk": 13, "special": "Rampage",  "special_dmg": 22, "special_desc": "Rampages for 22"},
		{"name": "Mountain King","hp": 130, "atk": 14, "special": "Avalanche","special_dmg": 28, "special_desc": "Triggers avalanche (28)", "is_boss": true},
	],
	[  # Level 1 — Alchemist's Run
		{"name": "Herb Sprite",   "hp": 32,  "atk": 7,  "special": "Sting",    "special_dmg": 12, "special_desc": "Stings for 12"},
		{"name": "Poison Slime",  "hp": 55,  "atk": 10, "special": "Corrode",  "special_dmg": 18, "special_desc": "Corrodes for 18"},
		{"name": "Flask Fiend",   "hp": 75,  "atk": 12, "special": "Splash",   "special_dmg": 20, "special_desc": "Splashes for 20"},
		{"name": "Essence Wraith","hp": 95,  "atk": 14, "special": "Drain",    "special_dmg": 24, "special_desc": "Drains for 24"},
		{"name": "Grand Alchemist","hp":140, "atk": 15, "special": "Transmute","special_dmg": 30, "special_desc": "Transmutes for 30", "is_boss": true},
	],
	[  # Level 2 — Mage's Run
		{"name": "Mana Wisp",    "hp": 38,  "atk": 8,  "special": "Zap",       "special_dmg": 14, "special_desc": "Zaps for 14"},
		{"name": "Spell Shade",  "hp": 60,  "atk": 11, "special": "Hex",       "special_dmg": 20, "special_desc": "Hexes for 20"},
		{"name": "Rune Golem",   "hp": 80,  "atk": 13, "special": "Overload",  "special_dmg": 22, "special_desc": "Overloads for 22"},
		{"name": "Arcane Golem", "hp": 100, "atk": 15, "special": "Nullify",   "special_dmg": 26, "special_desc": "Nullifies for 26"},
		{"name": "The Archmage", "hp": 165, "atk": 17, "special": "Obliterate","special_dmg": 34, "special_desc": "Obliterates for 34", "is_boss": true},
	],
]

# Player special action per prestige level
const PLAYER_SPECIALS: Array = [
	{"name": "Shatter",      "desc": "Deal 2x attack damage"},
	{"name": "Brew",         "desc": "Heal 25 HP"},
	{"name": "Arcane Blast", "desc": "Deal 3x attack damage"},
]

# ── Milestones ────────────────────────────────────────────────────────────────
const MILESTONES: Dictionary = {
	2:  {"icon": "🏗", "name": "Mastery",       "desc": "4th building slot unlocked per level (direct R2 production)"},
	5:  {"icon": "⚔", "name": "Elite Threat",   "desc": "4th upgrade slot unlocked + enemies get +50% HP (one-time spike)"},
	10: {"icon": "🏰", "name": "Ancient Power", "desc": "5th building slot unlocked per level (costs R2, high output)"},
	20: {"icon": "✨", "name": "Transcendence", "desc": "5th upgrade slot unlocked + prestige goals reduced by 25%"},
}
const MILESTONE_MAX: int = 20  # last ascension that unlocks new content

# Building cost scale factor
const COST_SCALE: float = 1.15

# Offline progress cap in seconds
const OFFLINE_CAP_SECONDS: float = 8.0 * 3600.0  # 8 hours

# ── Helpers ───────────────────────────────────────────────────────────────────
static func format_number(n: float) -> String:
	if n < 1000.0:
		return str(int(n))
	elif n < 1_000_000.0:
		return "%.1fK" % (n / 1000.0)
	elif n < 1_000_000_000.0:
		return "%.1fM" % (n / 1_000_000.0)
	else:
		return "%.1fB" % (n / 1_000_000_000.0)

static func unlocked_building_count(level: int, ascension: int) -> int:
	var n = 3
	if ascension >= 2:  n = 4
	if ascension >= 10: n = 5
	return min(n, BUILDINGS[level].size())

static func unlocked_upgrade_count(level: int, ascension: int) -> int:
	var n = 3
	if ascension >= 5:  n = 4
	if ascension >= 20: n = 5
	return min(n, UPGRADES[level].size())

static func prestige_goal(level: int, ascension: int) -> float:
	var base = PRESTIGE_GOALS[level]
	if ascension >= 20:
		base *= 0.75  # -25% at milestone 20
	return base

static func building_cost(level: int, building_index: int, count: int) -> float:
	var base = BUILDINGS[level][building_index]["base_cost"]
	return floor(base * pow(COST_SCALE, count))
