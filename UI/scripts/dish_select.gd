extends Control

@onready var dish_name_label: Label = $DishNameLabel
@onready var announcement_label: Label = $AnnouncementLabel

signal dish_selected(dish_data: Dictionary)

const loading_scene_path = "res://UI/scenes/5-loading_sec.tscn"
const DATASET_PATH = "res://assets/DATASET.json"

func _ready():
	if not dish_name_label:
		printerr("❌ DishNameLabel not found!")
	if not announcement_label:
		printerr("❌ AnnouncementLabel not found!")
	
	# Load dataset if not already loaded
	ensure_dataset_loaded()

func ensure_dataset_loaded():
	if Globals.themes_data.is_empty():
		print("🔄 Loading dataset in data_select...")
		load_dataset()
	else:
		print("✅ Dataset already loaded with themes: ", Globals.themes_data.keys())

func load_dataset():
	print("📂 Attempting to load from: ", DATASET_PATH)
	
	# Check if file exists
	if not FileAccess.file_exists(DATASET_PATH):
		printerr("❌ File does not exist: ", DATASET_PATH)
		return
	
	var file = FileAccess.open(DATASET_PATH, FileAccess.READ)
	
	if not file:
		printerr("❌ Cannot open file: ", DATASET_PATH)
		printerr("❌ Error code: ", FileAccess.get_open_error())
		return
	
	print("✅ File opened successfully")
	
	var json_text = file.get_as_text()
	file.close()
	
	print("📄 JSON text length: ", json_text.length())
	print("📄 First 200 characters: ", json_text.substr(0, 200))
	
	if json_text.is_empty():
		printerr("❌ JSON file is empty!")
		return
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		printerr("❌ JSON parse error: ", json.get_error_message())
		printerr("❌ Error line: ", json.get_error_line())
		return
	
	var parsed = json.data
	print("✅ JSON parsed successfully")
	print("📊 Parsed data keys: ", parsed.keys())
	
	if not parsed.has("themes"):
		printerr("❌ No 'themes' key in JSON data!")
		return
	
	if not parsed.has("dishes"):
		printerr("❌ No 'dishes' key in JSON data!")
		return
	
	var raw_themes = parsed.get("themes", {})
	var dishes = parsed.get("dishes", {})
	
	print("📋 Raw themes count: ", raw_themes.size())
	print("📋 Raw themes keys: ", raw_themes.keys())
	print("🍽 Dishes count: ", dishes.size())
	
	if raw_themes.is_empty():
		printerr("❌ Themes dictionary is empty!")
		return
	
	# Normalize theme keys
	var normalized_themes = {}
	for key in raw_themes.keys():
		var lowercase_key = key.to_lower()
		normalized_themes[lowercase_key] = raw_themes[key]
		print("🔄 Normalizing: '%s' -> '%s'" % [key, lowercase_key])
		
		# Debug the theme data
		var theme_data = raw_themes[key]
		if theme_data.has("clue"):
			print("   📝 Clue: %s" % theme_data["clue"])
		else:
			print("   ❌ No clue in theme data!")
	
	# Store in Globals
	Globals.themes_data = normalized_themes
	Globals.dishes_data = dishes
	
	print("✅ Dataset loaded successfully!")
	print("📁 Final themes in Globals: ", Globals.themes_data.keys())
	print("📊 Globals themes count: ", Globals.themes_data.size())
	
	# Test specific theme
	if normalized_themes.has("maasim"):
		print("✅ Found 'maasim' theme!")
		var maasim_data = normalized_themes["maasim"]
		print("   📝 Maasim clue: ", maasim_data.get("clue", "NO CLUE"))
	else:
		print("❌ 'maasim' theme not found in normalized themes!")

func display_dish(dish_name: String, input_data: Dictionary):
	if not is_instance_valid(dish_name_label) or not is_instance_valid(announcement_label):
		printerr("❌ UI labels not initialized!")
		return

	# Ensure dataset is loaded
	ensure_dataset_loaded()
	
	visible = true

	var display_name = dish_name.replace("-", " ").capitalize()
	var full_dish_data = Globals.dishes_data.get(dish_name.to_lower(), {})

	if full_dish_data.is_empty():
		full_dish_data = input_data

	full_dish_data["name"] = display_name
	full_dish_data["theme"] = input_data.get("theme", "")

	Globals.selected_dish_name = display_name
	set_meta("selected_dish", full_dish_data)

	# Get the clue
	var theme_key = full_dish_data.get("theme", "").to_lower()
	var clue_text = "❌ Hindi natagpuan ang tema"

	print("🔍 Looking for theme: '%s'" % theme_key)
	print("📁 Available themes: ", Globals.themes_data.keys())
	print("📊 Globals themes count: ", Globals.themes_data.size())
	print("📊 Globals themes type: ", typeof(Globals.themes_data))

	if Globals.themes_data.has(theme_key):
		var theme_data = Globals.themes_data[theme_key]
		clue_text = theme_data.get("clue", "❓ Walang pahiwatig")
		print("✅ Found theme! Clue: %s" % clue_text)
	else:
		print("❌ Theme '%s' not found" % theme_key)
		
		# Try to find partial matches
		for available_theme in Globals.themes_data.keys():
			if available_theme.contains(theme_key) or theme_key.contains(available_theme):
				print("🔍 Possible match: '%s'" % available_theme)

	# Display only the clue (no dish name, no prefix)
	dish_name_label.text = ""  # Hide dish name
	announcement_label.text = clue_text  # Show only the clue text

	print("🍽 Final display: %s | %s" % [display_name, clue_text])

func _on_texture_button_pressed() -> void:
	if is_inside_tree() and get_tree():
		get_tree().change_scene_to_file(loading_scene_path)
	else:
		printerr("❌ Cannot change scene - scene tree not available")
