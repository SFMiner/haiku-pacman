extends RefCounted

# Each test_* method runs under tests/run_tests.gd. Counts are checked by expect().
# Only the pure helpers are tested here. File and localStorage access needs a running game.

# === STATE ===

var passes: int = 0
var fails: int = 0


# === HELPERS ===

func expect(condition: bool, message: String) -> void:
	if condition:
		passes += 1
	else:
		fails += 1
		print("  FAIL: %s" % message)


# === TESTS: RECORDING ===

func test_record_only_raises_the_score() -> void:
	var scores: Dictionary = {}
	expect(SaveManager.record(scores, "default", 100), "first score is a new record")
	expect(int(scores["default"]) == 100, "record stores the score")
	expect(not SaveManager.record(scores, "default", 50), "a lower score is not a record")
	expect(int(scores["default"]) == 100, "a lower score leaves the table alone")
	expect(not SaveManager.record(scores, "default", 100), "a tied score is not a record")


func test_each_mode_keeps_its_own_high_score() -> void:
	var scores: Dictionary = {"default": 500}
	expect(SaveManager.record(scores, "classic", 300), "classic starts its own table at 0")
	expect(int(scores["default"]) == 500, "default's score is untouched by classic")
	expect(int(scores["classic"]) == 300, "classic has its own score")


# === TESTS: STORAGE FORMAT ===

func test_round_trip_keeps_scores() -> void:
	var scores: Dictionary = {"default": 12340, "classic": 800}
	var back: Dictionary = SaveManager.parse_scores(SaveManager.serialize_scores(scores))
	expect(back == scores, "scores survive serialize then parse (got %s)" % str(back))


func test_broken_data_gives_an_empty_table() -> void:
	expect(SaveManager.parse_scores("").is_empty(), "empty text gives an empty table")
	expect(SaveManager.parse_scores("not json").is_empty(), "invalid JSON gives an empty table")
	expect(SaveManager.parse_scores("[1, 2, 3]").is_empty(), "a JSON array gives an empty table")


func test_parse_skips_non_numeric_values() -> void:
	var back: Dictionary = SaveManager.parse_scores("{\"default\": \"lots\", \"classic\": 40}")
	expect(back.size() == 1 and int(back["classic"]) == 40, "only numeric scores are kept (got %s)" % str(back))
