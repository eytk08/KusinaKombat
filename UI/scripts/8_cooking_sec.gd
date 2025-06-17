extends Control

# Node References
@onready var card_manager = preload("res://UI/scripts/card_manager_cooking.gd").new()
@onready var card_placeholder = $MarginContainer/UiCardPlaceholderc
@onready var ai_agent = preload("res://UI/scripts/AI_AGENT.gd").new()
@onready var turn_timer = $Timer
@onready var turn_label = $TurnLabel
@onready var user_info_panel = $bg/USER_INFO
@onready var ai_info_panel = $bg/AI_INFO
@onready var user_label = $bg/USER_INFO/user_Label
@onready var ai_label = $bg/AI_INFO/ai_label

# Game State Variables
var selected_dish_data: Dictionary
var is_player_turn: bool = true
var player_selected_cards: Array = []
var ai_selected_cards: Array = []
var available_cards: Array = []
var current_selection: String = ""
var all_cooking_cards: Array = []
var player_score_counter := 4  # Fewer cards in cooking phase
var ai_score_counter := 4
var max_cards_per_player := 1  # 2 cooking methods per player
var total_cards_selected := 0

func _ready():
	# Initialize nodes
	add_child(card_manager)
	
	selected_dish_data = Globals.ingredients_battle_results.get("dish_data", {})
	
	# Setup signal connections
	if card_placeholder:
		if card_placeholder.has_signal("card_selected"):
			card_placeholder.card_selected.connect(on_card_selected)
		else:
			printerr("❌ Missing card_selected signal in card placeholder")
	
	# Initialize cooking cards
	all_cooking_cards = card_manager.get_cooking_cards_for_dish(selected_dish_data)
	available_cards = all_cooking_cards.duplicate()
	display_cards(all_cooking_cards)
	
	# Configure AI
	ai_agent.initialize(selected_dish_data, available_cards, ai_agent.BATTLE_TYPE.COOKING)
	ai_agent.difficulty = 2
	
	start_turn()

func display_cards(card_textures: Array):
	var cards_to_show = card_textures.filter(func(card): return available_cards.has(card))
	if card_placeholder:
		card_placeholder.setup_with_textures(cards_to_show)
		print("👨‍🍳 Displaying cooking methods: ", cards_to_show)

func start_turn():
	update_turn_ui()
	if is_player_turn:
		turn_label.text = "Choose Cooking Method (8s)"
	else:
		turn_label.text = "AI Selecting Method..."
		ai_turn()
	
	turn_timer.start(8.0)

func ai_turn():
	if available_cards.is_empty() or ai_selected_cards.size() >= max_cards_per_player:
		return
	
	# Filter out already selected cards
	var selectable_cards = available_cards.duplicate()
	for card in ai_selected_cards:
		if selectable_cards.has(card):
			selectable_cards.erase(card)
	
	if selectable_cards.is_empty():
		return
	
	var ai_selection = ai_agent.select_card(selectable_cards)
	ai_selected_cards.append(ai_selection)
	available_cards.erase(ai_selection)
	
	ai_score_counter -= 1
	ai_label.text = str(ai_score_counter)
	
	# Visual feedback
	var selected_button = card_placeholder.get_selected_button(ai_selection)
	if selected_button:
		selected_button.disabled = true
		selected_button.modulate = Color(0.4, 0.4, 0.4, 0.6)
	

func on_card_selected(card_texture: String):
	if not is_player_turn or player_selected_cards.size() >= max_cards_per_player:
		return
	
	current_selection = card_texture
	available_cards.erase(card_texture)
	player_selected_cards.append(player_selected_cards + [card_texture])
	Globals.player_cooking_cards = player_selected_cards.duplicate()
	
	# Update UI
	player_score_counter -= 1
	user_label.text = str(player_score_counter)
	
	# Visual feedback
	var selected_button = card_placeholder.get_selected_button(card_texture)
	if selected_button:
		selected_button.disabled = true
		selected_button.modulate = Color(0.4, 0.4, 0.4, 0.6)
	
	turn_timer.stop()
	process_turn_end()

func process_turn_end():
	if is_player_turn and current_selection != "":
		total_cards_selected += 1
		current_selection.get_file().replace(".png", "").to_lower()
	elif not is_player_turn:
		total_cards_selected += 1
	
	current_selection = ""
	
	if total_cards_selected >= max_cards_per_player * 2:
		end_game()
		return
	
	is_player_turn = !is_player_turn
	update_turn_ui()
	
	if is_player_turn:
		start_turn()
	else:
		await get_tree().create_timer(1.0).timeout
		ai_turn()
		await get_tree().create_timer(0.5).timeout
		process_turn_end()

func end_game():
	var player_score = calculate_score(player_selected_cards)
	var ai_score = calculate_score(ai_selected_cards)
	
	# Store results including ingredient synergy
	Globals.cooking_battle_results = {
		"player_score": player_score,
		"ai_score": ai_score,
		"player_cards": player_selected_cards,
		"ai_cards": ai_selected_cards,
		"total_score": {
			"player": player_score + Globals.cooking_battle_results.get("player_score", 0),
			"ai": ai_score + Globals.cooking_battle_results.get("ai_score", 0)
		}
	}
	
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://UI/scenes/9-results_page.tscn")

func calculate_score(selected_cards: Array) -> int:
	var score = 0
	var cooking_data = selected_dish_data.get("cooking_methods", {})
	
	for card in selected_cards:
		# Extract just the method name from path (e.g. "stew" from "res://.../stew.png")
		var method_name = current_selection.get_file().get_file().get_basename().to_lower()
		
		# Check if method is incompatible first (skip if true)
		if cooking_data.get("incompatible", []).has(method_name):
			continue
		
		# Primary methods get highest score
		if cooking_data.get("primary", []).has(method_name):
			score += 3
		# Secondary methods get medium score
		elif cooking_data.get("secondary", []).has(method_name):
			score += 2
		# Any other valid method gets basic points
		else:
			score += 1
	
	return score
	

func update_turn_ui():
	if is_player_turn:
		user_info_panel.modulate = Color(1, 1, 1, 1)
		ai_info_panel.modulate = Color(0.6, 0.6, 0.6, 0.5)
	else:
		user_info_panel.modulate = Color(0.6, 0.6, 0.6, 0.5)
		ai_info_panel.modulate = Color(1, 1, 1, 1)

func _on_turn_timeout():
	if is_player_turn and current_selection == "":
		if available_cards.size() > 0:
			on_card_selected(available_cards.pick_random())
	process_turn_end()
