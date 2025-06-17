extends Node

var dishes_data = {}
var themes_data = {}

func _ready():
	var path = "res://assets/DATASET.json"
	var file = FileAccess.open(path, FileAccess.READ)
	
	if file:
		var json_text = file.get_as_text()
		var parsed = JSON.parse_string(json_text)
		
		if parsed:
			dishes_data = parsed.get("dishes", {})
			themes_data = parsed.get("themes", {})
			Globals.dishes_data = dishes_data
			Globals.themes_data = themes_data
			print("✅ Dataset loaded successfully.")
		else:
			printerr("❌ Failed to parse JSON in DATASET.json")
	else:
		printerr("❌ Cannot open file: ", path)
