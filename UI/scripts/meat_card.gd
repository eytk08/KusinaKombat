# card_output.gd
extends Control

enum {PLAYER_TURN, AI_TURN}

@onready var card_manager = preload("res://UI/scripts/card_manager_meat.gd").new()
@onready var ai_agent = preload("res://UI/scripts/AI_AGENT.gd").new()
@onready var card_placeholder = $UICardPlaceholder
@onready var turn_label = $TurnLabel
@onready var timer = $Timer
@onready var player_info = $PlayerInfo
@onready var player_cards_left = $PlayerInfo/Label
@onready var ai_info = $AIInfo
@onready var ai_cards_left = $AIInfo/Label
@onready var player_selection_display = $PlayerSelection
@onready var ai_selection_display = $AISelection
@onready var result_label = $ResultLabel
@onready var continue_button = $ContinueButton

var current_turn = PLAYER_TURN
var selected_dish_data: Dictionary
var available_cards: Array = []
var player_selected_cards: Array = []
var ai_selected_cards: Array = []
var card_objects: Array = []
var cards_per_turn: int = 4
var player_cards_remaining: int = 4
var ai_cards_remaining: int = 4

func _ready():
	add_child(card_manager)
	add_child(ai_agent)
	
	continue_button.visible = false
	result_label.visible = false
	
	var dish_selection = get_node_or_null("/root/DishSelection")
	if dish_selection:
		dish_selection.connect("dish_selected", _on_dish_selected)

func _on_dish_selected(dish_data: Dictionary):
	selected_dish_data = dish_data
	available_cards = card_manager.get_meat_cards_for_dish(dish_data)
	ai_agent.initialize(dish_data, available_cards.duplicate())
	setup_cards(available_cards)
	start_battle()

func setup_cards(card_textures: Array):
	# Clear existing cards
	for child in card_placeholder.get_children():
		child.queue_free()
	card_objects = []
	
	for i in range(min(card_textures.size(), 8)):
		var card = preload("res://UI/scenes/card_template.tscn").instantiate()
		card.set_texture(load("res://assets/cards/meat/" + card_textures[i]))
		card.set_meta("card_data", card_textures[i])
		card_placeholder.add_child(card)
		card_objects.append(card)
		card.connect("pressed", _on_card_selected.bind(card))

func start_battle():
	player_selected_cards = []
	ai_selected_cards = []
	player_cards_remaining = cards_per_turn
	ai_cards_remaining = cards_per_turn
	
	# Reset UI
	continue_button.visible = false
	result_label.visible = false
	
	# Reset all cards
	for card in card_objects:
		card.disabled = false
		card.modulate = Color(1, 1, 1)
	
	update_cards_remaining_display()
	update_turn_display()
	update_selection_display()
	
	if current_turn == AI_TURN:
		begin_ai_turn()

func begin_ai_turn():
	timer.start(0.5)  # Initial delay before AI starts selecting

func ai_turn():
	if ai_cards_remaining <= 0:
		end_ai_turn()
		return
	
	# Get AI's card selection
	var selected_card_data = ai_agent.select_card()
	
	if selected_card_data == "":
		end_ai_turn()
		return
	
	# Find and select the card in the UI
	for card in card_objects:
		if not card.disabled and card.get_meta("card_data") == selected_card_data:
			ai_selected_cards.append(selected_card_data)
			ai_cards_remaining -= 1
			ai_agent.remove_card(selected_card_data)
			card.disabled = true
			card.modulate = Color(1, 0.5, 0.5)  # Red tint for AI selection
			break
	
	update_cards_remaining_display()
	update_selection_display()
	
	# Continue selecting or end turn
	if ai_cards_remaining > 0:
		timer.start(0.8)  # Delay between AI selections
	else:
		end_ai_turn()

func _on_card_selected(card):
	if current_turn != PLAYER_TURN || player_cards_remaining <= 0:
		return
	
	var card_data = card.get_meta("card_data")
	player_selected_cards.append(card_data)
	player_cards_remaining -= 1
	ai_agent.remove_card(card_data)  # Remove from AI's available cards
	card.disabled = true
	card.modulate = Color(0.5, 0.5, 0.5)  # Gray out player selection
	
	update_cards_remaining_display()
	update_selection_display()
	
	if player_cards_remaining <= 0:
		end_player_turn()

func end_player_turn():
	current_turn = AI_TURN
	update_turn_display()
	update_cards_remaining_display()
	begin_ai_turn()

func end_ai_turn():
	current_turn = PLAYER_TURN
	player_cards_remaining = cards_per_turn  # Reset player's allowance
	update_turn_display()
	update_cards_remaining_display()
	
	check_battle_end()

func update_turn_display():
	turn_label.text = "Player's Turn" if current_turn == PLAYER_TURN else "AI's Turn"
	
	# Visual feedback
	if current_turn == PLAYER_TURN:
		player_info.modulate = Color(1, 1, 1)  # Bright
		ai_info.modulate = Color(0.5, 0.5, 0.5)  # Dim
	else:
		player_info.modulate = Color(0.5, 0.5, 0.5)  # Dim
		ai_info.modulate = Color(1, 1, 1)  # Bright

func update_cards_remaining_display():
	player_cards_left.text = "Cards Left: %d" % player_cards_remaining
	ai_cards_left.text = "Cards Left: %d" % ai_cards_remaining

func update_selection_display():
	player_selection_display.update_cards(player_selected_cards)
	ai_selection_display.update_cards(ai_selected_cards)

func check_battle_end():
	# Check if both players have selected all their cards
	var player_done = player_selected_cards.size() >= cards_per_turn
	var ai_done = ai_selected_cards.size() >= cards_per_turn
	
	# Or if no cards left to select
	var no_cards_left = true
	for card in card_objects:
		if not card.disabled:
			no_cards_left = false
			break
	
	if (player_done and ai_done) or no_cards_left:
		evaluate_results()

func evaluate_results():
	var player_score = calculate_score(player_selected_cards)
	var ai_score = calculate_score(ai_selected_cards)
	
	result_label.visible = true
	
	if player_score > ai_score:
		result_label.text = "You won! Great ingredient choices!"
	elif player_score < ai_score:
		result_label.text = "AI won! Better luck next time!"
	else:
		result_label.text = "It's a tie!"
	
	# Store results for later use
	if GlobalGameState:
		GlobalGameState.player_selected_meats = player_selected_cards
		GlobalGameState.ai_selected_meats = ai_selected_cards
	
	continue_button.visible = true


func _on_continue_button_pressed():
	get_tree().change_scene_to_file("res://next_scene_path.tscn")

func _on_timer_timeout():
	if current_turn == AI_TURN:
		ai_turn()
