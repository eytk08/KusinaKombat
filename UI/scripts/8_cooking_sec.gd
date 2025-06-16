extends Control

@onready var card_manager = preload("res://UI/scripts/card_manager_cooking.gd").new()
@onready var card_placeholder = $MarginContainer/UiCardPlaceholderc
@onready var ai_agent = preload("res://UI/scripts/AI_AGENT.gd").new()  
@onready var turn_timer = $Timer
@onready var turn_label = $TurnLabel
@onready var user_info_panel = $bg/USER_INFO
@onready var ai_info_panel = $bg/AI_INFO
@onready var user_label = $bg/USER_INFO/user_Label
@onready var ai_label = $bg/AI_INFO/ai_label

var selected_dish_data: Dictionary
var is_player_turn: bool = true
var player_selected_methods: Array = []
var ai_selected_methods: Array = []
var available_methods: Array = []
var current_selection: String = ""
var all_cooking_methods: Array = [] 
var player_score_counter := 2  # Fewer turns for cooking methods
var ai_score_counter := 2

func _ready():
	add_child(card_manager)
	card_placeholder.card_selected.connect(on_card_selected)
	
	# Hardcoded for testing - Kare Kare
	var dish_key: String = "kare kare"  # Lowercase for dataset key
	var dish_name: String = "kare kare"  # Formatted for display
	Globals.selected_dish_name = dish_key  # Store the lowercase version
	
	var dataset := load_dataset()

	if dataset.has("dishes") and dataset["dishes"].has(dish_name):
		selected_dish_data = dataset["dishes"][dish_name]
	else:
		printerr("❌ Dish not found in dataset: ", dish_name)
		return

	# Load and display cooking method cards
	all_cooking_methods = card_manager.get_cooking_cards_for_dish(selected_dish_data)
	available_methods = all_cooking_methods.duplicate()
	display_cards(all_cooking_methods)
	
	start_turn()
	print("✅ Displaying cooking methods for ", dish_name, ": ", all_cooking_methods)

func load_dataset() -> Dictionary:
	var path := "res://assets/DATASET.json"
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		var content := file.get_as_text()
		var json_result = JSON.parse_string(content)
		if typeof(json_result) == TYPE_DICTIONARY:
			return json_result
		else:
			printerr("❌ Failed to parse JSON")
	else:
		printerr("❌ DATASET.json not found!")
	return {}

func display_cards(card_textures: Array):
	# Only show available methods
	var cards_to_show = []
	for card in card_textures:
		if available_methods.has(card) or all_cooking_methods.has(card):
			cards_to_show.append(card)
	
	card_placeholder.setup_with_textures(cards_to_show)
	
	for i in range(cards_to_show.size()):
		print("🍳 Cooking Method %d: %s" % [i, cards_to_show[i]])
		
func start_turn():
	update_turn_ui()
	if is_player_turn:
		turn_label.text = "Your Turn (6s)"
	else:
		turn_label.text = "AI's Turn (6s)"
		ai_turn()
	
	turn_timer.start()

func _on_turn_timeout():
	if is_player_turn and current_selection == "":
		if available_methods.size() > 0:
			on_card_selected(available_methods[0])
	process_turn_end()

func process_turn_end():
	if is_player_turn and current_selection != "":
		player_selected_methods.append(current_selection)
		Globals.player_cooking_methods = player_selected_methods.duplicate()
	elif not is_player_turn:
		Globals.ai_cooking_methods = ai_selected_methods.duplicate()
	
	current_selection = ""
	
	# Game ends when all methods are selected (4 total)
	if player_selected_methods.size() + ai_selected_methods.size() >= 4:
		end_game()
	else:
		is_player_turn = !is_player_turn
		start_turn()

func ai_turn():
	if available_methods.is_empty():
		return
	

	
	# Update AI score
	ai_score_counter -= 1
	ai_label.text = str(ai_score_counter)
	
	display_cards(all_cooking_methods)
	
func end_game():
	var player_score = calculate_cooking_score(player_selected_methods)
	var ai_score = calculate_cooking_score(ai_selected_methods)
	
	Globals.cooking_battle_results = {
		"player_score": player_score,
		"ai_score": ai_score,
		"player_methods": player_selected_methods,
		"ai_methods": ai_selected_methods,
		"dish_data": selected_dish_data
	}
	
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://UI/scenes/cooking_results_screen.tscn")

func calculate_cooking_score(selected_methods: Array) -> int:
	var score = 0
	var dish_data = ai_agent.dish_knowledge.get(selected_dish_data.get("id", ""), {}).get("cooking_methods", {})
	
	for method in selected_methods:
		var method_name = method.get_file().get_basename().to_lower()
		
		# Check against preferred cooking methods
		if dish_data.has("primary") and method_name in dish_data["primary"]:
			score += 4
		elif dish_data.has("secondary") and method_name in dish_data["secondary"]:
			score += 2
		elif dish_data.has("incompatible") and method_name in dish_data["incompatible"]:
			score -= 3
	
	return score
	
func on_card_selected(card_texture: String):
	if not is_player_turn:
		return
	

	
	player_score_counter -= 1
	user_label.text = str(player_score_counter)
	
	# Update display
	display_cards(all_cooking_methods)
	
	# Disable selected button
	var selected_button = card_placeholder.get_selected_button(card_texture)
	if selected_button:
		selected_button.disabled = true
	
	turn_timer.stop()
	process_turn_end()
	
func update_turn_ui():
	if is_player_turn:
		user_info_panel.modulate = Color(1, 1, 1, 1)
		ai_info_panel.modulate = Color(0.6, 0.6, 0.6, 0.5)
	else:
		user_info_panel.modulate = Color(0.6, 0.6, 0.6, 0.5)
		ai_info_panel.modulate = Color(1, 1, 1, 1)
