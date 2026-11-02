class_name GameProfile
extends RefCounted

const VERSION := 1
var path: String = "user://profile.json"
var data: Dictionary
var last_error: String = ""

func _init(save_path: String = "user://profile.json") -> void:
	path = save_path
	data = defaults()

func defaults() -> Dictionary:
	return {"version": VERSION, "seals": 0, "buildings": {"arsenal": false, "library": false}, "best_time": 0.0, "wins": 0, "runs": 0, "settings": {"volume": 0.55, "effects": 0.7, "shake": true, "fullscreen": false}}

func load_profile() -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		last_error = "Não foi possível ler o progresso."
		return false
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		last_error = "Progresso inválido. Arquivo preservado."
		return false
	var parsed = parser.data
	if not parsed is Dictionary or parsed.get("version", 0) != VERSION:
		last_error = "Progresso inválido ou versão incompatível. Arquivo preservado."
		return false
	for key in ["seals", "best_time", "runs", "wins"]:
		if parsed.has(key) and not (parsed[key] is float or parsed[key] is int):
			last_error = "Progresso com campos inválidos. Arquivo preservado."
			return false
	if parsed.has("buildings") and not parsed.buildings is Dictionary:
		last_error = "Progresso com construções inválidas. Arquivo preservado."
		return false
	if parsed.has("settings") and not parsed.settings is Dictionary:
		last_error = "Preferências inválidas. Arquivo preservado."
		return false
	var check_options: Dictionary = parsed.get("settings", {})
	for key in ["volume", "effects"]:
		if check_options.has(key) and not (check_options[key] is float or check_options[key] is int):
			last_error = "Preferências com campos inválidos. Arquivo preservado."
			return false
	data = defaults()
	data.seals = clampi(int(parsed.get("seals", 0)), 0, 999999)
	data.best_time = clampf(float(parsed.get("best_time", 0)), 0, 100000)
	data.runs = clampi(int(parsed.get("runs", 0)), 0, 999999)
	data.wins = clampi(int(parsed.get("wins", 0)), 0, data.runs)
	var buildings = parsed.get("buildings", {})
	if buildings is Dictionary:
		for key in data.buildings:
			data.buildings[key] = buildings.get(key, false) == true
	var options = parsed.get("settings", {})
	if options is Dictionary:
		data.settings.volume = clampf(float(options.get("volume", 0.55)), 0, 1)
		data.settings.effects = clampf(float(options.get("effects", 0.7)), 0, 1)
		data.settings.shake = options.get("shake", true) == true
		data.settings.fullscreen = options.get("fullscreen", false) == true
	return true

func save() -> bool:
	# Write new data first. Keep a readable previous version on replacement.
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		last_error = "Não foi possível salvar o progresso."
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(path, path + ".bak")
	var result := DirAccess.rename_absolute(path + ".tmp", path)
	if result != OK:
		last_error = "Falha ao concluir o salvamento."
	return result == OK

func purchase(id: String) -> bool:
	if not data.buildings.has(id) or data.buildings[id] or data.seals < 8:
		return false
	data.seals -= 8
	data.buildings[id] = true
	return save()

func reward(seconds: float, kills: int, victory: bool, collected: int) -> int:
	var total := floori(seconds / 30.0) + floori(kills / 30.0) + collected + (10 if victory else 0)
	data.seals += total
	data.runs += 1
	data.wins += int(victory)
	data.best_time = maxf(data.best_time, seconds)
	save()
	return total
