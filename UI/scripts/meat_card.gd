extends Control

@onready var card_manager = preload("res://UI/scripts/card_manager_meat.gd").new()
@onready var card_placeholder = $MarginContainer/UiCardPlaceholder
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
var all_meat_cards: Array = [] 
var player_score_counter := 8
var ai_score_counter := 8
var max_cards_per_player := 2  # Each player picks 2 cards
var total_cards_selected := 0  # Tracks all picks (player + AI)

func _ready():
	add_child(card_manager)
	card_placeholder.card_selected.connect(on_card_selected)
	
	var dataset := load_dataset()
	var dish_name: String = Globals.selected_dish_name.strip_edges().to_lower()

	if dataset.has("dishes") and dataset["dishes"].has(dish_name):
		selected_dish_data = dataset["dishes"][dish_name]
	else:
		printerr("❌ Dish not found in dataset: ", dish_name)
		return

	# Load and display cards
	all_meat_cards = card_manager.get_meat_cards_for_dish(selected_dish_data)
	available_cards = all_meat_cards.duplicate()
	display_cards(all_meat_cards)
	
	ai_agent.initialize(selected_dish_data, available_cards, ai_agent.BATTLE_TYPE.MEAT)
	ai_agent.difficulty = 2
	start_turn()
	print("✅ Displaying meat cards for ", dish_name, ": ", all_meat_cards)

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
		if available_cards.has(card) or all_meat_cards.has(card):
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
		Globals.player_meat_cards = player_selected_cards.duplicate()
		total_cards_selected += 1
	elif not is_player_turn:
		total_cards_selected += 1  

	current_selection = ""  # Reset selection

	# End game after 4 cards (2 per player)
	if total_cards_selected >= max_cards_per_player * 2:
		end_game()
	else:
		# Switch turns
		is_player_turn = !is_player_turn
		if is_player_turn:
			start_turn()  # Player's turn
		else:
			await get_tree().create_timer(1.0).timeout  # AI "thinking" delay
			ai_turn()     # AI picks 1 card
			# Don't call process_turn_end() here - let the timer or next input trigger it
			start_turn()  # Start the next turn instead

func ai_turn():
	if available_cards.is_empty() or ai_selected_cards.size() >= max_cards_per_player:
		return  # Stop if no cards left or AI already picked 2

	var ai_selection = ai_agent.select_card()
	ai_selected_cards.append(ai_selection)
	Globals.ai_meat_cards = ai_selected_cards.duplicate()
	available_cards.erase(ai_selection)

	# Update UI
	ai_score_counter -= 1
	ai_label.text = str(ai_score_counter)

	# Disable the selected card
	var selected_button = card_placeholder.get_selected_button(ai_selection)
	if selected_button:
		selected_button.disabled = true
		selected_button.modulate = Color(0.5, 0.5, 0.5, 0.7)  # Gray out
	
func end_game():
	var player_score = calculate_score(player_selected_cards)
	var ai_score = calculate_score(ai_selected_cards)
	
	Globals.meat_battle_results = {
		"player_score": player_score,
		"ai_score": ai_score,
		"player_cards": player_selected_cards,
		"ai_cards": ai_selected_cards,
		"dish_data": selected_dish_data 
	}
	
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://UI/scenes/7-Vegetable_sec.tscn")

func calculate_score(selected_cards: Array) -> int:
	var score = 0
	var key = ai_agent._get_current_battle_key()
	var dish_data = ai_agent.dish_knowledge.get(selected_dish_data.get("id", ""), {}).get(key, {})	
	
	for card in selected_cards:
		var card_lower = card.to_lower()
		
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
	if not is_player_turn or player_selected_cards.size() >= max_cards_per_player:
		return  # Ignore if not player's turn or already picked 2

	current_selection = card_texture
	available_cards.erase(card_texture)
	ai_agent.update_player_cards(player_selected_cards + [card_texture])

	# Update UI
	player_score_counter -= 1
	user_label.text = str(player_score_counter)

	# Disable card
	var selected_button = card_placeholder.get_selected_button(card_texture)
	if selected_button:
		selected_button.disabled = true
		selected_button.modulate = Color(0.5, 0.5, 0.5, 0.7)

	turn_timer.stop()
	process_turn_end()  # Proceed to AI turn
	
func update_turn_ui():
	if is_player_turn:
		user_info_panel.modulate = Color(1, 1, 1, 1)  # Fully visible
		ai_info_panel.modulate = Color(0.6, 0.6, 0.6, 0.5)  # Dimmed
	else:
		user_info_panel.modulate = Color(0.6, 0.6, 0.6, 0.5)  # Dimmed
		ai_info_panel.modulate = Color(1, 1, 1, 1)  # Fully visible
	
