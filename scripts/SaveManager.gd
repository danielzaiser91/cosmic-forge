extends Node
# SaveManager — autoload, handles JSON persistence

const SAVE_PATH = "user://cosmic_forge_save.json"
const AUTOSAVE_INTERVAL = 30.0
const SAVE_VERSION = 1

var _autosave_timer: float = 0.0

func _process(delta: float) -> void:
	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		save_game()

func save_game() -> void:
	var data = GameState.to_dict()
	data["save_version"] = SAVE_VERSION
	var json = JSON.stringify(data, "\t")
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json)
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text = file.get_as_text()
	file.close()
	var result = JSON.parse_string(text)
	if result is Dictionary:
		var save_ver = int(result.get("save_version", 0))
		if save_ver < SAVE_VERSION:
			result = _migrate(result, save_ver)
		GameState.from_dict(result)

func _migrate(data: Dictionary, from_ver: int) -> Dictionary:
	if from_ver < 1:
		data["tutorial_shown"] = true  # existing players skip tutorial
		if not data.has("lifetime_relics"):
			data["lifetime_relics"] = 0
	return data

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
