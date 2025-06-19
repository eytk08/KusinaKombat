extends Node

const DATASET_PATH = "res://assets/DATASET.json"

var dishes_data = {}
var themes_data = {}
var is_loaded = false

func _ready():
	load_dataset()

func load_dataset():
	print("🔄 Loading dataset...")
	
	var file = FileAccess.open(DATASET_PATH, FileAccess.READ)

	if file:
		var json_text = file.get_as_text()
		var parsed = JSON.parse_string(json_text)

		if parsed:
			# ✅ Load dishes and themes
			dishes_data = parsed.get("dishes", {})
			var raw_themes = parsed.get("themes", {})

			print("📋 Raw themes loaded: ", raw_themes.keys())

			# 🔁 Convert theme keys to lowercase PROPERLY
			themes_data = {}
			for key in raw_themes.keys():
				var lowercase_key = key.to_lower()
				themes_data[lowercase_key] = raw_themes[key]
				print("📋 Normalized theme: '%s' -> '%s'" % [key, lowercase_key])

			# ✅ Store in Globals
			Globals.dishes_data = dishes_data
			Globals.themes_data = themes_data
			is_loaded = true

			print("✅ Dataset loaded successfully!")
			print("📁 Final themes in Globals: ", Globals.themes_data.keys())
			print("🔍 Sample theme 'maasim': ", Globals.themes_data.get("maasim", "NOT FOUND"))
			
		else:
			printerr("❌ Failed to parse JSON in DATASET.json")
		
		file.close()
	else:
		printerr("❌ Cannot open file: ", DATASET_PATH)

# Helper function to ensure data is loaded
func ensure_loaded():
	if not is_loaded:
		load_dataset()
	return is_loaded
