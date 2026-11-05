extends Node

## Headless check: every `feedback.<name>` used in scripts must exist on FeedbackConfig.
## Run: godot --headless --path "<project>" res://tests/check_feedback_config.tscn

func _ready() -> void:
	var used: Dictionary = _used_property_names()
	var config: FeedbackConfig = FeedbackConfig.new()
	var existing: Dictionary = {}
	for property in config.get_property_list():
		existing[property["name"]] = true

	var missing: Array[String] = []
	for name in used.keys():
		if not existing.has(name):
			missing.append(name)
	missing.sort()

	if missing.is_empty():
		print("OK: %d FeedbackConfig properties referenced by scripts, all exist" % used.size())
		get_tree().quit(0)
		return

	printerr("MISSING FeedbackConfig properties: %s" % str(missing))
	get_tree().quit(1)


func _used_property_names() -> Dictionary:
	var names: Dictionary = {}
	var directory := DirAccess.open("res://scripts")
	if directory == null:
		return names
	var regex := RegEx.new()
	regex.compile("feedback\\.([a-z_]+)")
	for file in directory.get_files():
		if not file.ends_with(".gd"):
			continue
		var text: String = FileAccess.get_file_as_string("res://scripts/" + file)
		for result in regex.search_all(text):
			names[result.get_string(1)] = true
	return names
