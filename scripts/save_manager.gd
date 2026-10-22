class_name SaveManager
extends RefCounted

# Saves the high score table, one score per maze mode. Desktop writes user://highscore.json;
# the web build uses localStorage. The parse, serialize and record helpers are pure, so tests run them headless.

# === CONSTANTS ===

const SAVE_PATH: String = "user://highscore.json"
const WEB_KEY: String = "haiku_pac_highscores"


# === PUBLIC API ===

## Loads the high score table. Missing or broken data gives an empty table.
static func load_scores() -> Dictionary:
	var text: String = _web_read() if OS.has_feature("web") else _file_read()
	return parse_scores(text)


## Writes the high score table. A failed write is reported, not raised.
static func save_scores(scores: Dictionary) -> void:
	var text: String = serialize_scores(scores)
	if OS.has_feature("web"):
		_web_write(text)
	else:
		_file_write(text)


## Raises the stored score for a mode if `score` beats it. Returns true when the table changed.
static func record(scores: Dictionary, mode: String, score: int) -> bool:
	if score <= int(scores.get(mode, 0)):
		return false
	scores[mode] = score
	return true


static func parse_scores(text: String) -> Dictionary:
	var out: Dictionary = {}
	if text == "":
		return out
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		return out
	var data: Dictionary = parsed
	for key: String in data.keys():
		var value: Variant = data[key]
		if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
			out[key] = int(value)
	return out


static func serialize_scores(scores: Dictionary) -> String:
	return JSON.stringify(scores)


# === STORAGE: DESKTOP ===

static func _file_read() -> String:
	if not FileAccess.file_exists(SAVE_PATH):
		return ""
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Could not read high scores from %s" % SAVE_PATH)
		return ""
	return file.get_as_text()


static func _file_write(text: String) -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write high scores to %s" % SAVE_PATH)
		return
	file.store_string(text)


# === STORAGE: WEB ===

static func _web_read() -> String:
	var code: String = "(function(){try{return localStorage.getItem('%s') || '';}catch(e){return '';}})()" % WEB_KEY
	var result: Variant = JavaScriptBridge.eval(code, true)
	if result == null:
		return ""
	return String(result)


static func _web_write(text: String) -> void:
	var code: String = "(function(){try{localStorage.setItem('%s', %s);}catch(e){}})()" % [WEB_KEY, JSON.stringify(text)]
	JavaScriptBridge.eval(code, true)
