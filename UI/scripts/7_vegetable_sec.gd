extends Control

@onready var card_manager = preload("res://UI/scripts/card_manager_ingredients.gd").new()
@onready var card_placeholder = $MarginContainer/UiCardPlaceholderv
@onready var ai_agent = preload("res://UI/scripts/AI_AGENT.gd").new()  
@onready var turn_timer = $Timer
@onready var turn_label = $TurnLabel
@onready var user_info_panel = $bg/USER_INFO
@onready var ai_info_panel = $bg/AI_INFO
@onready var user_label = $bg/USER_INFO/user_Label
@onready var ai_label = $bg/AI_INFO/ai_label

var selected_dish_data: Dictionary
var is_player_turn: bool = true
var player_selected_cards: Array = []
var ai_selected_cards: Array = []
var available_cards: Array = []
var current_selection: String = ""
var all_ingredient_cards: Array = [] 
var player_score_counter := 6  # Fewer turns for ingredients
var ai_score_counter := 6

func _ready():
	add_child(card_manager)
	card_placeholder.card_selected.connect(on_card_selected)
	
	# Hardcoded for testing - Kare Kare
	var dish_key: String = "kare kare"  # Lowercase for dataset key
	var dish_name: String = "kare kare"  # Formatted for display
	Globals.selected_dish_name = dish_key  # Store the lowercase version
	
	var dataset := load_dataset()
	#var dish_name: String = Globals.selected_dish_name.strip_edges().to_lower()

	if dataset.has("dishes") and dataset["dishes"].has(dish_name):
		selected_dish_data = dataset["dishes"][dish_name]
	else:
		printerr("❌ Dish not found in dataset: ", dish_name)
		return

	# Load and display cards - now using ingredient cards
	all_ingredient_cards = card_manager.get_ingredient_cards_for_dish(selected_dish_data)
	available_cards = all_ingredient_cards.duplicate()
	display_cards(all_ingredient_cards)
	

	
	start_turn()
	print("✅ Displaying ingredient cards for ", dish_name, ": ", all_ingredient_cards)

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
	# Only show available cards
	var cards_to_show = []
	for card in card_textures:
		if available_cards.has(card) or all_ingredient_cards.has(card):
			cards_to_show.append(card)
	
	card_placeholder.setup_with_textures(cards_to_show)
	
	for i in range(cards_to_show.size()):
		print("🃏 Card %d: %s" % [i, cards_to_show[i]])
		
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
		if available_cards.size() > 0:
			on_card_selected(available_cards[0])
	process_turn_end()

func process_turn_end():
	if is_player_turn and current_selection != "":
		player_selected_cards.append(current_selection)
		Globals.player_ingredient_cards = player_selected_cards.duplicate()
	elif not is_player_turn:
		Globals.ai_ingredient_cards = ai_selected_cards.duplicate()
	
	current_selection = ""
	
	# Check if game should end (after at least 1 card each)
	if player_selected_cards.size() + ai_selected_cards.size() >= 2:
		end_game()
	else:
		is_player_turn = !is_player_turn
		start_turn()

func ai_turn():
	if available_cards.is_empty():
		return
	
	var ai_selection = ai_agent.select_card()
	ai_selected_cards.append(ai_selection)
	available_cards.erase(ai_selection)
	
	# Update AI score
	ai_score_counter -= 1
	ai_label.text = str(ai_score_counter)
	
	display_cards(all_ingredient_cards)  # Show all cards but only available ones will be visible
	
func end_game():
	var player_score = calculate_score(player_selected_cards)
	var ai_score = calculate_score(ai_selected_cards)
	
	Globals.ingredient_battle_results = {
		"player_score": player_score,
		"ai_score": ai_score,
		"player_cards": player_selected_cards,
		"ai_cards": ai_selected_cards,
		"dish_data": selected_dish_data,
		"player_meat_cards": Globals.player_meat_cards,
		"ai_meat_cards": Globals.ai_meat_cards
	}
	
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://UI/scenes/results_screen.tscn")

func calculate_score(selected_cards: Array) -> int:
	var score = 0
	var dish_data = ai_agent.dish_knowledge.get(selected_dish_data.get("id", ""), {}).get("ingredients", {})
	
	for card in selected_cards:
		var card_lower = card.to_lower()
		
		# Check meat compatibility first
		for meat_card in Globals.player_meat_cards:
			var meat_name = meat_card.get_file().get_basename().to_lower()
			if ai_agent.is_incompatible(meat_name, card_lower):
				score -= 2  # Penalty for incompatible combinations
		
		# Then check regular ingredients
		for ingredient in dish_data.get("essential", []):
			if ingredient.to_lower() in card_lower:
				score += 4
		
		for item in dish_data.get("tier1", []):
			if item.to_lower() in card_lower:
				score += 3
		
		for item in dish_data.get("tier2", []):
			if item.to_lower() in card_lower:
				score += 1
	
	return score
	
func on_card_selected(card_texture: String):
	if not is_player_turn:
		return
	
	current_selection = card_texture
	available_cards.erase(card_texture)
	ai_agent.update_player_cards(player_selected_cards + [card_texture])
	
	player_score_counter -= 1
	user_label.text = str(player_score_counter)
	
	# Update display
	display_cards(all_ingredient_cards)
	
	# Disable selected button
	var selected_button = card_placeholder.get_selected_button(card_texture)
	if selected_button:
		selected_button.disabled = true
	
	turn_timer.stop()
	process_turn_end()
	
func update_turn_ui():
	if is_player_turn:
		user_info_panel.modulate = Color(1, 1, 1, 1)  # Fully visible
		ai_info_panel.modulate = Color(0.6, 0.6, 0.6, 0.5)  # Dimmed
	else:
		user_info_panel.modulate = Color(0.6, 0.6, 0.6, 0.5)  # Dimmed
		ai_info_panel.modulate = Color(1, 1, 1, 1)  # Fully visible
