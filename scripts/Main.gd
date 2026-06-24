extends Control
# Main.gd — builds all UI programmatically, connects to GameState signals

# ── Colors ────────────────────────────────────────────────────────────────────
const C_BG       = Color(0.10, 0.10, 0.18)
const C_PANEL    = Color(0.09, 0.13, 0.25)
const C_BORDER   = Color(0.06, 0.20, 0.38)
const C_TEXT     = Color(0.88, 0.88, 0.92)
const C_DIM      = Color(0.55, 0.55, 0.62)
const C_GOLD     = Color(0.96, 0.65, 0.14)
const C_GREEN    = Color(0.30, 0.76, 0.45)
const C_RED      = Color(0.96, 0.26, 0.26)
const C_BLUE     = Color(0.25, 0.60, 0.96)
const C_PURPLE   = Color(0.70, 0.35, 0.96)
const C_HEADER   = Color(0.13, 0.17, 0.32)

# ── Node references ───────────────────────────────────────────────────────────
var _idle_panel: Control
var _run_panel: Control
var _relic_panel: Control
var _offline_panel: Control

# Idle UI refs
var _lbl_title: Label
var _lbl_level: Label
var _lbl_resources: Array[Label] = []
var _lbl_per_sec: Array[Label] = []
var _btn_click: Button
var _building_rows: Array = []   # Array of {lbl_name, lbl_count, lbl_cost, btn}
var _upgrade_rows: Array = []    # Array of {lbl_name, lbl_desc, btn}
var _progress_bar: ProgressBar
var _lbl_progress: Label
var _relic_chips: HBoxContainer
var _btn_prestige: Button

# Run UI refs
var _lbl_run_title: Label
var _lbl_room: Label
var _lbl_player_hp: Label
var _lbl_enemy_name: Label
var _lbl_enemy_hp: Label
var _lbl_telegraph: Label
var _btn_attack: Button
var _btn_shield: Button
var _btn_special: Button
var _lbl_run_atk: Label
var _log_label: Label

# Relic choice refs
var _relic_choice_btns: Array[Button] = []

# Ascension panel refs
var _ascension_panel: Control
var _lbl_ascension_nr: Label
var _lbl_ascension_relics: Label
var _lbl_ascension_bonus: Label
var _lbl_ascension_count: Label  # shown in header
var _milestone_strip: HBoxContainer

# Offline panel refs
var _lbl_offline_time: Label
var _btn_offline_ok: Button

# ── Setup ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_set_bg()
	_build_idle_panel()
	_build_run_panel()
	_build_relic_panel()
	_build_ascension_panel()
	_build_offline_panel()
	_connect_signals()
	_refresh_ui()

func _set_bg() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = C_BG
	add_theme_stylebox_override("panel", style)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

# ── Build: Idle panel ─────────────────────────────────────────────────────────
func _build_idle_panel() -> void:
	_idle_panel = VBoxContainer.new()
	_idle_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_idle_panel)

	# Header
	var header = _make_panel(C_HEADER)
	header.custom_minimum_size = Vector2(0, 56)
	_idle_panel.add_child(header)
	var hrow = HBoxContainer.new()
	hrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hrow.add_theme_constant_override("separation", 12)
	header.add_child(hrow)

	_lbl_title = _make_label("COSMIC FORGE", 22, C_GOLD, true)
	hrow.add_child(_lbl_title)
	var spacer = Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hrow.add_child(spacer)
	_lbl_level = _make_label("Level 0 — The Miner", 14, C_BLUE)
	hrow.add_child(_lbl_level)
	var spacer2 = Control.new(); spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hrow.add_child(spacer2)
	_lbl_ascension_count = _make_label("Ascension #0", 12, C_DIM)
	hrow.add_child(_lbl_ascension_count)

	# Prestige run button
	_btn_prestige = _make_button("⚔  Start Prestige Run", C_PURPLE)
	_btn_prestige.custom_minimum_size = Vector2(220, 0)
	_btn_prestige.pressed.connect(_on_prestige_pressed)
	hrow.add_child(_btn_prestige)

	# Main 3-column row
	var columns = HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 0)
	_idle_panel.add_child(columns)

	_build_resource_column(columns)
	_add_vsep(columns)
	_build_buildings_column(columns)
	_add_vsep(columns)
	_build_upgrades_column(columns)

	# Progress + relics footer
	var footer = _make_panel(C_HEADER)
	footer.custom_minimum_size = Vector2(0, 80)
	_idle_panel.add_child(footer)
	var fvbox = VBoxContainer.new()
	fvbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fvbox.add_theme_constant_override("separation", 4)
	footer.add_child(fvbox)

	var prow = HBoxContainer.new()
	prow.add_theme_constant_override("separation", 8)
	fvbox.add_child(prow)
	_lbl_progress = _make_label("Progress: 0 / 1000 Gold", 13, C_TEXT)
	prow.add_child(_lbl_progress)
	_progress_bar = ProgressBar.new()
	_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress_bar.custom_minimum_size = Vector2(0, 18)
	_progress_bar.value = 0; _progress_bar.max_value = 100
	_progress_bar.show_percentage = false
	prow.add_child(_progress_bar)

	var rrow = HBoxContainer.new()
	rrow.add_theme_constant_override("separation", 8)
	fvbox.add_child(rrow)
	rrow.add_child(_make_label("Relics:", 12, C_DIM))
	_relic_chips = HBoxContainer.new()
	_relic_chips.add_theme_constant_override("separation", 6)
	rrow.add_child(_relic_chips)

func _build_resource_column(parent: Control) -> void:
	var col = _make_panel(C_PANEL)
	col.custom_minimum_size = Vector2(220, 0)
	parent.add_child(col)
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	col.add_child(vbox)

	vbox.add_child(_make_label("RESOURCES", 13, C_GOLD, true))
	vbox.add_child(_make_hsep())

	# Click button
	_btn_click = _make_button("Mine Stone", C_BLUE)
	_btn_click.custom_minimum_size = Vector2(0, 40)
	_btn_click.pressed.connect(_on_click_pressed)
	vbox.add_child(_btn_click)

	vbox.add_child(_make_hsep())

	# Resource rows
	_lbl_resources.clear(); _lbl_per_sec.clear()
	for i in 3:
		var row = VBoxContainer.new()
		row.add_theme_constant_override("separation", 1)
		vbox.add_child(row)
		var lbl = _make_label("— 0", 16, C_TEXT, true)
		_lbl_resources.append(lbl)
		row.add_child(lbl)
		var lbl_ps = _make_label("  0.0 /s", 11, C_DIM)
		_lbl_per_sec.append(lbl_ps)
		row.add_child(lbl_ps)

	var sp = Control.new(); sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(sp)

func _build_buildings_column(parent: Control) -> void:
	var col = _make_panel(C_PANEL)
	col.custom_minimum_size = Vector2(380, 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(col)
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	col.add_child(vbox)

	vbox.add_child(_make_label("BUILDINGS", 13, C_GOLD, true))
	vbox.add_child(_make_hsep())

	_building_rows.clear()
	for i in 5:
		var row = _build_building_row(i)
		vbox.add_child(row["container"])
		_building_rows.append(row)

	var sp = Control.new(); sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(sp)

func _build_building_row(index: int) -> Dictionary:
	var container = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.2)
	style.set_corner_radius_all(4)
	container.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	container.add_child(hbox)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	var lbl_name = _make_label("Building", 14, C_TEXT, true)
	info.add_child(lbl_name)
	var lbl_cost = _make_label("Cost: ?", 11, C_DIM)
	info.add_child(lbl_cost)

	var right = VBoxContainer.new()
	right.custom_minimum_size = Vector2(90, 0)
	hbox.add_child(right)

	var lbl_count = _make_label("x0", 13, C_BLUE, true)
	lbl_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(lbl_count)

	var btn = _make_button("Buy", C_GREEN)
	btn.custom_minimum_size = Vector2(80, 30)
	btn.pressed.connect(func(): _on_buy_building(index))
	right.add_child(btn)

	return {"container": container, "lbl_name": lbl_name, "lbl_count": lbl_count, "lbl_cost": lbl_cost, "btn": btn}

func _build_upgrades_column(parent: Control) -> void:
	var col = _make_panel(C_PANEL)
	col.custom_minimum_size = Vector2(280, 0)
	parent.add_child(col)
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	col.add_child(vbox)

	vbox.add_child(_make_label("UPGRADES", 13, C_GOLD, true))
	vbox.add_child(_make_hsep())

	_upgrade_rows.clear()
	for i in 5:
		var row = _build_upgrade_row(i)
		vbox.add_child(row["container"])
		_upgrade_rows.append(row)

	var sp = Control.new(); sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(sp)

func _build_upgrade_row(index: int) -> Dictionary:
	var container = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.2)
	style.set_corner_radius_all(4)
	container.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	container.add_child(vbox)

	var lbl_name = _make_label("Upgrade", 13, C_TEXT, true)
	vbox.add_child(lbl_name)
	var lbl_desc = _make_label("description", 11, C_DIM)
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl_desc)
	var btn = _make_button("Buy", C_PURPLE)
	btn.custom_minimum_size = Vector2(0, 28)
	btn.pressed.connect(func(): _on_buy_upgrade(index))
	vbox.add_child(btn)

	return {"container": container, "lbl_name": lbl_name, "lbl_desc": lbl_desc, "btn": btn}

# ── Build: Run panel ──────────────────────────────────────────────────────────
func _build_run_panel() -> void:
	_run_panel = PanelContainer.new()
	_run_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_run_panel.visible = false
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.05, 0.10, 0.95)
	_run_panel.add_theme_stylebox_override("panel", bg)
	add_child(_run_panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 12)
	_run_panel.add_child(vbox)

	# Header
	var hdr = HBoxContainer.new()
	hdr.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(hdr)
	_lbl_run_title = _make_label("THE MINER'S RUN", 22, C_GOLD, true)
	hdr.add_child(_lbl_run_title)
	var sp = Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(sp)
	_lbl_room = _make_label("Room 1 / 5", 14, C_BLUE)
	hdr.add_child(_lbl_room)

	# HP row
	var hp_row = HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 20)
	vbox.add_child(hp_row)
	_lbl_player_hp = _make_label("HP: 100 / 100", 16, C_GREEN, true)
	hp_row.add_child(_lbl_player_hp)
	var sp2 = Control.new(); sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(sp2)
	_lbl_enemy_hp = _make_label("Enemy HP: 0 / 0", 16, C_RED)
	hp_row.add_child(_lbl_enemy_hp)
	var sp3 = Control.new(); sp3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(sp3)
	_lbl_run_atk = _make_label("ATK: 12", 14, C_GOLD)
	hp_row.add_child(_lbl_run_atk)

	vbox.add_child(_make_hsep())

	# Enemy area
	var enemy_panel = _make_panel(C_PANEL)
	enemy_panel.custom_minimum_size = Vector2(0, 100)
	vbox.add_child(enemy_panel)
	var ev = VBoxContainer.new()
	ev.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ev.add_theme_constant_override("separation", 6)
	enemy_panel.add_child(ev)
	_lbl_enemy_name = _make_label("Enemy", 18, C_RED, true)
	_lbl_enemy_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ev.add_child(_lbl_enemy_name)
	_lbl_telegraph = _make_label("...", 13, C_GOLD)
	_lbl_telegraph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_telegraph.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ev.add_child(_lbl_telegraph)

	vbox.add_child(_make_hsep())

	# Action buttons
	var action_row = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 16)
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(action_row)

	_btn_attack = _make_button("⚔  ATTACK\n(12 dmg)", C_RED)
	_btn_attack.custom_minimum_size = Vector2(160, 70)
	_btn_attack.pressed.connect(func(): _on_run_action("attack"))
	action_row.add_child(_btn_attack)

	_btn_shield = _make_button("🛡  SHIELD\n(+15 def)", C_BLUE)
	_btn_shield.custom_minimum_size = Vector2(160, 70)
	_btn_shield.pressed.connect(func(): _on_run_action("shield"))
	action_row.add_child(_btn_shield)

	_btn_special = _make_button("✨  SHATTER\n(2x dmg)", C_PURPLE)
	_btn_special.custom_minimum_size = Vector2(160, 70)
	_btn_special.pressed.connect(func(): _on_run_action("special"))
	action_row.add_child(_btn_special)

	vbox.add_child(_make_hsep())

	# Combat log
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 120)
	vbox.add_child(scroll)
	_log_label = Label.new()
	_log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.add_theme_font_size_override("font_size", 12)
	_log_label.add_theme_color_override("font_color", C_TEXT)
	scroll.add_child(_log_label)

# ── Build: Relic choice panel ─────────────────────────────────────────────────
func _build_relic_panel() -> void:
	_relic_panel = PanelContainer.new()
	_relic_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_relic_panel.custom_minimum_size = Vector2(620, 340)
	_relic_panel.visible = false
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.07, 0.07, 0.15)
	bg.border_color = C_GOLD
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(8)
	_relic_panel.add_theme_stylebox_override("panel", bg)
	add_child(_relic_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	_relic_panel.add_child(vbox)

	var ttl = _make_label("⚔  VICTORY  ⚔", 20, C_GOLD, true)
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(ttl)
	var sub = _make_label("Choose a Relic — it will persist through all future runs.", 12, C_DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(row)

	_relic_choice_btns.clear()
	for i in 3:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(160, 130)
		btn.text = ""
		btn.pressed.connect(func(): _on_relic_chosen(i))
		_style_button(btn, C_BORDER)
		row.add_child(btn)
		_relic_choice_btns.append(btn)

	var skip_btn = _make_button("Skip (no relic)", C_DIM)
	skip_btn.pressed.connect(func(): _on_relic_chosen(-1))
	skip_btn.custom_minimum_size = Vector2(160, 32)
	vbox.add_child(skip_btn)

# ── Build: Ascension complete panel ──────────────────────────────────────────
func _build_ascension_panel() -> void:
	_ascension_panel = PanelContainer.new()
	_ascension_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ascension_panel.visible = false
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.04, 0.04, 0.10, 0.97)
	_ascension_panel.add_theme_stylebox_override("panel", bg)
	add_child(_ascension_panel)

	var center = VBoxContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center.custom_minimum_size = Vector2(600, 400)
	center.add_theme_constant_override("separation", 18)
	_ascension_panel.add_child(center)

	var ttl = _make_label("✨  ASCENSION COMPLETE  ✨", 28, C_GOLD, true)
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(ttl)

	_lbl_ascension_nr = _make_label("", 16, C_BLUE)
	_lbl_ascension_nr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_lbl_ascension_nr)

	center.add_child(_make_hsep())

	_lbl_ascension_relics = _make_label("", 13, C_TEXT)
	_lbl_ascension_relics.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_ascension_relics.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center.add_child(_lbl_ascension_relics)

	center.add_child(_make_hsep())

	_lbl_ascension_bonus = _make_label("", 14, C_GREEN, true)
	_lbl_ascension_bonus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_lbl_ascension_bonus)

	var sub = _make_label("All relics are lost. You begin anew — stronger.", 12, C_DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(sub)

	var btn = _make_button("⚡  ASCEND  —  Start Run #%d" % (GameState.ascension_count + 1), C_GOLD)
	btn.custom_minimum_size = Vector2(300, 50)
	btn.pressed.connect(_on_ascend_pressed)
	center.add_child(btn)

	center.add_child(_make_hsep())

	# Milestone progress strip
	var strip_lbl = _make_label("MILESTONE PROGRESSION", 11, C_DIM, true)
	strip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(strip_lbl)
	_milestone_strip = HBoxContainer.new()
	_milestone_strip.add_theme_constant_override("separation", 10)
	_milestone_strip.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(_milestone_strip)

# ── Build: Offline progress panel ────────────────────────────────────────────
func _build_offline_panel() -> void:
	_offline_panel = PanelContainer.new()
	_offline_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_offline_panel.custom_minimum_size = Vector2(400, 200)
	_offline_panel.visible = false
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.07, 0.07, 0.15)
	bg.border_color = C_BLUE
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(8)
	_offline_panel.add_theme_stylebox_override("panel", bg)
	add_child(_offline_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	_offline_panel.add_child(vbox)

	vbox.add_child(_make_label("Welcome Back!", 18, C_BLUE, true))
	_lbl_offline_time = _make_label("You were away for 0 minutes.", 13, C_TEXT)
	_lbl_offline_time.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_lbl_offline_time)
	_btn_offline_ok = _make_button("Collect & Continue", C_GREEN)
	_btn_offline_ok.pressed.connect(_on_offline_ok)
	vbox.add_child(_btn_offline_ok)

# ── Signal connections ────────────────────────────────────────────────────────
func _connect_signals() -> void:
	GameState.state_changed.connect(_refresh_ui)
	GameState.run_started.connect(_on_run_started)
	GameState.run_ended.connect(_on_run_ended)
	GameState.prestige_happened.connect(_on_prestige_happened)
	GameState.game_complete.connect(_on_game_complete)
	GameState.milestone_reached.connect(_on_milestone_reached)

# ── UI Refresh ────────────────────────────────────────────────────────────────
func _refresh_ui() -> void:
	_refresh_idle()

func _refresh_idle() -> void:
	if not is_instance_valid(_lbl_level):
		return
	var lvl = GameState.prestige_level
	var res_data = GameData.RESOURCES[lvl]
	var bld_data = GameData.BUILDINGS[lvl]
	var upg_data = GameData.UPGRADES[lvl]

	var asc = GameState.ascension_count
	if asc > 0:
		_lbl_ascension_count.text = "Ascension #%d  (+%d%% prod.)" % [asc, int(GameState.ascension_production_bonus() * 100)]
		_lbl_ascension_count.add_theme_color_override("font_color", C_GOLD)
	else:
		_lbl_ascension_count.text = ""

	_lbl_level.text = "Level %d — %s" % [lvl, GameData.LEVEL_NAMES[lvl]]
	_btn_click.text = GameData.LEVEL_CLICK_LABELS[lvl]

	# Resources
	for i in 3:
		var r = GameData.RESOURCES[lvl][i]
		_lbl_resources[i].text = "%s %s  %s" % [r["icon"], r["name"], GameData.format_number(GameState.resources[i])]
		var ps = GameState.production_per_sec(i)
		if ps > 0.001:
			_lbl_per_sec[i].text = "   %.2f /s" % ps
		else:
			_lbl_per_sec[i].text = ""

	var asc = GameState.ascension_count
	var unlocked_b = GameData.unlocked_building_count(lvl, asc)
	var unlocked_u = GameData.unlocked_upgrade_count(lvl, asc)

	# Buildings (show/hide based on milestone)
	for i in 5:
		var row = _building_rows[i]
		if i >= unlocked_b:
			row["container"].visible = false
			continue
		row["container"].visible = true
		var b = bld_data[i]
		var produces_res = GameData.RESOURCES[lvl][b["produces"]]
		var milestone_tag = " 🔓" if b.get("milestone", 0) > 0 else ""
		row["lbl_name"].text = "%s%s  (+%.2f %s/s each)" % [b["name"], milestone_tag, b["base_production"], produces_res["name"]]
		row["lbl_count"].text = "x%d" % GameState.building_counts[i]
		var cost = GameState.building_cost(i)
		var cost_res = GameData.RESOURCES[lvl][b["cost_resource"]]
		row["lbl_cost"].text = "Cost: %s %s" % [GameData.format_number(cost), cost_res["name"]]
		var can_afford = GameState.resources[b["cost_resource"]] >= cost
		row["btn"].disabled = not can_afford
		row["btn"].modulate = C_TEXT if can_afford else C_DIM

	# Upgrades (show/hide based on milestone)
	for i in 5:
		var row = _upgrade_rows[i]
		if i >= unlocked_u:
			row["container"].visible = false
			continue
		row["container"].visible = true
		var u = upg_data[i]
		var milestone_tag = " 🔓" if u.get("milestone", 0) > 0 else ""
		row["lbl_name"].text = u["name"] + milestone_tag
		var cost_res_name = GameData.RESOURCES[lvl][u["cost_resource"]]["name"]
		row["lbl_desc"].text = "%s\nCost: %s %s" % [u["desc"], GameData.format_number(u["cost"]), cost_res_name]
		if GameState.upgrades_bought[i]:
			row["btn"].text = "✓ Owned"
			row["btn"].disabled = true
			row["btn"].modulate = C_DIM
		else:
			var can_afford = GameState.resources[u["cost_resource"]] >= u["cost"]
			row["btn"].text = "Buy"
			row["btn"].disabled = not can_afford
			row["btn"].modulate = C_TEXT if can_afford else C_DIM

	# Progress bar
	var goal = GameData.prestige_goal(lvl, asc)
	var current_r2 = GameState.resources[2]
	var pct = clampf(current_r2 / goal * 100.0, 0.0, 100.0)
	_progress_bar.value = pct
	var r2_name = GameData.RESOURCES[lvl][2]["name"]
	_lbl_progress.text = "Goal: %s / %s %s  (%.0f%%)" % [
		GameData.format_number(current_r2), GameData.format_number(goal), r2_name, pct]

	# Prestige button
	_btn_prestige.disabled = not GameState.run_available
	if GameState.run_available:
		_btn_prestige.text = "⚔  START PRESTIGE RUN"
		_btn_prestige.modulate = Color.WHITE
	else:
		_btn_prestige.text = "⚔  Prestige Run (locked)"
		_btn_prestige.modulate = C_DIM

	# Relics
	for child in _relic_chips.get_children():
		_relic_chips.remove_child(child)
		child.queue_free()
	for rid in GameState.relics_owned:
		for r in GameData.RELICS:
			if r["id"] == rid:
				var chip = _make_label("%s %s" % [r["icon"], r["name"]], 11, C_GOLD)
				var chip_panel = PanelContainer.new()
				var sty = StyleBoxFlat.new()
				sty.bg_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15)
				sty.border_color = C_GOLD
				sty.set_border_width_all(1)
				sty.set_corner_radius_all(4)
				chip_panel.add_theme_stylebox_override("panel", sty)
				chip_panel.add_child(chip)
				_relic_chips.add_child(chip_panel)
				break

func _refresh_run() -> void:
	var lvl = GameState.prestige_level
	var run_names = ["The Miner's Run", "The Alchemist's Run", "The Mage's Run"]
	_lbl_run_title.text = run_names[lvl]
	var room = GameState.run_room
	var is_boss = room >= 4
	_lbl_room.text = "Room %d / 5%s" % [room + 1, "  [BOSS]" if is_boss else ""]
	_lbl_player_hp.text = "❤ HP: %d / %d" % [GameState.player_hp, GameState.player_max_hp]
	if GameState.player_hp <= 30:
		_lbl_player_hp.add_theme_color_override("font_color", C_RED)
	else:
		_lbl_player_hp.add_theme_color_override("font_color", C_GREEN)

	if GameState.enemy_data.is_empty():
		return
	var edata = GameState.enemy_data
	_lbl_enemy_name.text = "%s%s" % ["👑 " if is_boss else "", edata["name"]]
	_lbl_enemy_hp.text = "Enemy HP: %d / %d" % [GameState.enemy_hp, edata["hp"]]
	_lbl_telegraph.text = "▶ " + GameState.get_enemy_telegraph()

	# Update action button labels
	_lbl_run_atk.text = "⚔ ATK: %d" % GameState.player_attack
	_btn_attack.text = "⚔  ATTACK\n(%d dmg)" % GameState.player_attack
	_btn_shield.text = "🛡  SHIELD\n(+15 def)"
	var special = GameData.PLAYER_SPECIALS[lvl]
	var special_dmg = GameState.player_attack * (3 if lvl == 2 else 2)
	_btn_special.text = "✨  %s\n(%d dmg)" % [special["name"].to_upper(), special_dmg]

	# Update log
	var log_lines = GameState.combat_log
	var recent = log_lines.slice(max(0, log_lines.size() - 12))
	_log_label.text = "\n".join(recent)

# ── Event handlers ────────────────────────────────────────────────────────────
func _on_click_pressed() -> void:
	GameState.click_resource()

func _on_buy_building(index: int) -> void:
	GameState.buy_building(index)

func _on_buy_upgrade(index: int) -> void:
	GameState.buy_upgrade(index)

func _on_prestige_pressed() -> void:
	GameState.start_prestige_run()

func _on_run_action(action: String) -> void:
	GameState.player_action(action)
	_refresh_run()

func _on_run_started() -> void:
	_idle_panel.visible = false
	_run_panel.visible = true
	_refresh_run()

func _on_run_ended(victory: bool, relic_choices: Array) -> void:
	if victory:
		_show_relic_choices(relic_choices)
	else:
		_run_panel.visible = false
		_idle_panel.visible = true
		_show_defeat_message()

func _show_defeat_message() -> void:
	# Brief label overlay — reuse as notification
	var lbl = _make_label("Defeated! The prestige run can be retried.", 14, C_RED, true)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(lbl)
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(lbl):
		lbl.queue_free()

func _show_relic_choices(choices: Array) -> void:
	_run_panel.visible = false
	_relic_panel.visible = true
	for i in 3:
		var btn = _relic_choice_btns[i]
		if i < choices.size():
			var r = choices[i]
			btn.text = "%s\n%s\n\n%s" % [r["icon"], r["name"], r["desc"]]
			btn.visible = true
		else:
			btn.visible = false

func _on_relic_chosen(index: int) -> void:
	_relic_panel.visible = false
	var relic_id = ""
	if index >= 0 and index < GameState.pending_relic_choices.size():
		relic_id = GameState.pending_relic_choices[index]["id"]
	GameState.choose_relic(relic_id)
	# game_complete signal will take over if this was the Mage prestige,
	# otherwise show idle again
	if not _ascension_panel.visible:
		_idle_panel.visible = true
		_refresh_idle()

func _on_prestige_happened(_new_level: int) -> void:
	_refresh_idle()

func _on_game_complete(ascension: int, relics_collected: Array) -> void:
	_relic_panel.visible = false
	_run_panel.visible = false
	_idle_panel.visible = false
	_ascension_panel.visible = true

	_lbl_ascension_nr.text = "You have completed Run #%d!" % ascension
	var relic_names = []
	for rid in relics_collected:
		for r in GameData.RELICS:
			if r["id"] == rid:
				relic_names.append("%s %s" % [r["icon"], r["name"]])
	if relic_names.is_empty():
		_lbl_ascension_relics.text = "Relics collected: none"
	else:
		_lbl_ascension_relics.text = "Relics collected this run:\n" + "   ".join(relic_names)

	var next_prod = int(ascension * 10)
	var next_diff = int((GameState.enemy_scale() * (1.15 if ascension < 20 else 1.0) - 1.0) * 100)
	var goal_note = "  |  goals -25%" if ascension >= 20 else ""
	_lbl_ascension_bonus.text = "Next run:  +%d%% production   |   enemies +%d%% HP/ATK%s" % [next_prod, next_diff, goal_note]

	# Build milestone strip
	for child in _milestone_strip.get_children():
		_milestone_strip.remove_child(child)
		child.queue_free()

	var thresholds = [2, 5, 10, 20]
	for t in thresholds:
		var m = GameData.MILESTONES[t]
		var done = ascension >= t
		var is_next = not done and (t == thresholds[0] or ascension >= thresholds[thresholds.find(t) - 1])
		var chip = PanelContainer.new()
		var sty = StyleBoxFlat.new()
		sty.set_corner_radius_all(6)
		if done:
			sty.bg_color = Color(C_GREEN.r, C_GREEN.g, C_GREEN.b, 0.25)
			sty.border_color = C_GREEN
		elif is_next:
			sty.bg_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.20)
			sty.border_color = C_GOLD
		else:
			sty.bg_color = Color(0.15, 0.15, 0.20)
			sty.border_color = C_BORDER
		sty.set_border_width_all(1)
		chip.add_theme_stylebox_override("panel", sty)
		chip.custom_minimum_size = Vector2(120, 0)
		var vb = VBoxContainer.new()
		vb.add_theme_constant_override("separation", 2)
		chip.add_child(vb)
		var prefix = "✓ " if done else ("▶ " if is_next else "🔒 ")
		var col = C_GREEN if done else (C_GOLD if is_next else C_DIM)
		var lbl_t = _make_label("%s Asc #%d" % [prefix, t], 11, col, true)
		lbl_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(lbl_t)
		var lbl_n = _make_label(m["name"], 10, col)
		lbl_n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(lbl_n)
		_milestone_strip.add_child(chip)

	# Check if all milestones done
	if ascension >= GameData.MILESTONE_MAX:
		var end_lbl = _make_label("All milestones complete — you've reached the end of new content!", 11, C_PURPLE)
		end_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		end_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_milestone_strip.get_parent().add_child(end_lbl)

func _on_ascend_pressed() -> void:
	_ascension_panel.visible = false
	GameState.do_ascension()
	_idle_panel.visible = true
	_refresh_idle()

func _on_milestone_reached(milestone: Dictionary) -> void:
	var lbl = _make_label("🔓  MILESTONE UNLOCKED: %s\n%s" % [milestone["name"], milestone["desc"]], 15, C_GOLD, true)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size = Vector2(500, 0)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var sty = StyleBoxFlat.new()
	sty.bg_color = Color(0.07, 0.07, 0.12)
	sty.border_color = C_GOLD
	sty.set_border_width_all(2)
	sty.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", sty)
	panel.add_child(lbl)
	add_child(panel)
	await get_tree().create_timer(4.0).timeout
	if is_instance_valid(panel):
		panel.queue_free()

func _on_offline_ok() -> void:
	_offline_panel.visible = false

# ── UI Factories ──────────────────────────────────────────────────────────────
func _make_label(text: String, size: int, color: Color, bold: bool = false) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		pass  # Godot uses default font, bold handled by size/color contrast
	return l

func _make_button(text: String, color: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	_style_button(btn, color)
	return btn

func _style_button(btn: Button, color: Color) -> void:
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(color.r * 0.3, color.g * 0.3, color.b * 0.3)
	normal.border_color = color
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", normal)

	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(color.r * 0.5, color.g * 0.5, color.b * 0.5)
	hover.border_color = color
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = color
	pressed_style.border_color = color
	pressed_style.set_border_width_all(1)
	pressed_style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	var disabled_style = StyleBoxFlat.new()
	disabled_style.bg_color = Color(0.15, 0.15, 0.20)
	disabled_style.border_color = Color(0.3, 0.3, 0.35)
	disabled_style.set_border_width_all(1)
	disabled_style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("disabled", disabled_style)

	btn.add_theme_color_override("font_color", C_TEXT)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", C_DIM)
	btn.add_theme_font_size_override("font_size", 13)

func _make_panel(bg_color: Color) -> PanelContainer:
	var p = PanelContainer.new()
	var sty = StyleBoxFlat.new()
	sty.bg_color = bg_color
	sty.border_color = C_BORDER
	sty.set_border_width_all(1)
	p.add_theme_stylebox_override("panel", sty)
	return p

func _make_hsep() -> HSeparator:
	var sep = HSeparator.new()
	sep.add_theme_color_override("color", C_BORDER)
	return sep

func _add_vsep(parent: Control) -> void:
	var sep = VSeparator.new()
	sep.add_theme_color_override("color", C_BORDER)
	parent.add_child(sep)
