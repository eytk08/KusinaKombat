extends Node

@export var initial_delay: float = 2
@export var selection_speed: float = 0.2
@export var speed_decrease_rate: float = 0.005
@export var final_selection_delay: float = 0.1
@export var cycles: int = 4

signal dish_selected(dish_name: String, dish_data: Dictionary)

var elements: Array[TextureRect] = []
var current_index: int = 0
var is_selecting: bool = false
var current_speed: float = 0.0
var cycles_completed: int = 0
var target_index: int = 0
var selected_theme: String = ""
var selected_dish: String = ""
var game_data: Dictionary = {}

func _ready():
	# First ensure all nodes are ready
	await get_tree().process_frame
	
	print("Initializing roulette system...")
	_load_game_data()
	
	# Setup roulette elements
	var background = $TextureRect
	if not background:
		printerr("Background TextureRect not found!")
		return
	
	# Find all theme elements
	for child in background.get_children():
		if child is TextureRect:
			elements.append(child)
			print("Found theme element: ", child.name)
	
	if elements.is_empty():
		printerr("No theme elements found!")
		return
	
	_setup_materials()
	
	# Start the selection process after delay
	get_tree().create_timer(initial_delay).timeout.connect(start_selection_roulette)

func _load_game_data():
	var file_path = "res://assets/DATASET.json"
	
	if not FileAccess.file_exists(file_path):
		printerr("JSON file not found!")
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_text) != OK:
		printerr("JSON parse error!")
		return
	
	game_data = json.get_data()
	print("Loaded game data with", game_data.themes.size(), "themes")

func _setup_materials():
	var shader = load("res://UI/glow_shader.gdshader")
	if not shader:
		printerr("Failed to load shader!")
		return
	
	for element in elements:
		var mat = ShaderMaterial.new()
		mat.shader = shader
		element.material = mat
		mat.set_shader_parameter("selected", false)

func start_selection_roulette():
	target_index = randi() % elements.size()
	is_selecting = true
	current_index = 0
	current_speed = selection_speed
	cycles_completed = 0
	_next_selection()

func _next_selection():
	if not is_selecting:
		return
	
	# Update selection
	elements[current_index].material.set_shader_parameter("selected", false)
	current_index = (current_index + 1) % elements.size()
	elements[current_index].material.set_shader_parameter("selected", true)
	
	# Check cycles
	if current_index == 0:
		cycles_completed += 1
	
	# Stop condition
	if cycles_completed >= cycles and current_index == target_index:
		stop_roulette_at(target_index)
		return
	
	# Adjust speed
	current_speed = max(current_speed - speed_decrease_rate, final_selection_delay)
	var delay = current_speed if cycles_completed < cycles-1 else lerp(current_speed, final_selection_delay, float(cycles_completed)/float(cycles))
	
	get_tree().create_timer(delay).timeout.connect(_next_selection)

func stop_roulette_at(index: int):
	is_selecting = false
	
	# Reset all selections
	for element in elements:
		element.material.set_shader_parameter("selected", false)
	
	# Highlight final theme
	var final_element = elements[index]
	final_element.material.set_shader_parameter("selected", true)
	selected_theme = final_element.name.to_lower()
	
	# Select random dish
	select_random_dish_from_theme()

func select_random_dish_from_theme():
	var theme_data = game_data.themes.get(selected_theme, {})
	if theme_data.is_empty():
		return
	
	var random_dish = theme_data.dishes[randi() % theme_data.dishes.size()]
	selected_dish = random_dish.name
	
	# Emit signal with dish data
	var dish_data = get_dish_data(selected_dish)
	dish_selected.emit(selected_dish, dish_data)
	
	# Show dish select UI
	show_dish_select(selected_dish, dish_data)

func get_dish_data(dish_name: String) -> Dictionary:
	var dish_info = game_data.dishes.get(dish_name.to_lower().replace(" ", "-"), {})
	return {
		"name": dish_name.replace("-", " ").capitalize(),
		"ingredients": dish_info.get("ingredients", []),
		"points": dish_info.get("points", 0),
		"cooking_method": dish_info.get("cooking_method", []),
		"dish_type": dish_info.get("dish_type", ""),
		"theme": game_data.themes.get(selected_theme, {}).get("name", "")
	}

func show_dish_select(dish_name: String, dish_data: Dictionary):
	var dish_select = $DishSelect
	if dish_select and dish_select.has_method("display_dish"):
		dish_select.display_dish(dish_name, dish_data)
	else:
		printerr("DishSelect node missing or invalid!")
