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
@onready var skip_button = $Button
@onready var input_blocker = $InputBlocker

# Game State Variables
var selected_dish_data: Dictionary
var is_player_turn: bool = true
var player_selected_cards: Array = []
var ai_selected_cards: Array = []
var available_cards: Array = []
var current_selection: String = ""
var all_cooking_cards: Array = []
var player_score_counter := 4
var ai_score_counter := 4
var max_cards_per_player := 1
var total_cards_selected := 0
var turn_duration := 8.0
var turn_time_left := 0.0

func _ready():
	add_child(card_manager)
	
	selected_dish_data = Globals.ingredients_battle_results.get("dish_data", {})
	
	if card_placeholder and card_placeholder.has_signal("card_selected"):
		card_placeholder.card_selected.connect(on_card_selected)
	else:
		printerr("❌ Missing card_selected signal")
	
	skip_button.pressed.connect(_on_skip_button_pressed)
	
	all_cooking_cards = card_manager.get_cooking_cards_for_dish(selected_dish_data)
	available_cards = all_cooking_cards.duplicate()
	display_cards(all_cooking_cards)
	
	ai_agent.initialize(selected_dish_data, available_cards, ai_agent.BATTLE_TYPE.COOKING)
	ai_agent.difficulty = 2
	
	start_turn()
	print("✅ Displaying cooking method cards:", all_cooking_cards)

func display_cards(card_textures: Array):
	var cards_to_show = []
	for card in card_textures:
		if available_cards.has(card) or all_cooking_cards.has(card):
			cards_to_show.append(card)
	card_placeholder.setup_with_textures(cards_to_show)
	for i in range(cards_to_show.size()):
		print("🔥 Cooking Card %d: %s" % [i, cards_to_show[i]])

func _process(delta):
	if turn_timer.is_stopped():
		return
	turn_time_left -= delta
	turn_time_left = max(turn_time_left, 0.0)

	if is_player_turn:
		turn_label.text = "Your Turn (%.0fs)" % turn_time_left
		if turn_time_left == 0:
			print("⏰ Time's up — skipping to AI turn.")
			turn_timer.stop()
			current_selection = ""
			player_score_counter -= 1
			user_label.text = str(player_score_counter)
			process_turn_end()
	else:
		turn_label.text = "AI's Turn (%.0fs)" % turn_time_left

func start_turn():
	update_turn_ui()
	turn_time_left = turn_duration
	turn_timer.start(turn_duration)

func _on_skip_button_pressed():
	if is_player_turn:
		print("⏭️ Player skipped the turn.")
		turn_timer.stop()
		current_selection = ""
		player_score_counter -= 1
		user_label.text = str(player_score_counter)
		process_turn_end()

func process_turn_end():
	if is_player_turn:
		if current_selection != "":
			player_selected_cards.append(current_selection)
			Globals.player_cooking_cards = player_selected_cards.duplicate()
			print("🧍 Player selected:", current_selection)
		else:
			print("⚠️ Player made no selection. Skipping.")
	else:
		print("🤖 AI turn processed.")
		total_cards_selected += 1

	current_selection = ""

	if total_cards_selected >= max_cards_per_player * 2:
		end_game()
		return

	is_player_turn = !is_player_turn
	update_turn_ui()

	if is_player_turn:
		print("🧍 Player's turn begins.")
		start_turn()
	else:
		print("🤖 AI's turn begins.")
		await get_tree().create_timer(1.0).timeout
		ai_turn()
		await get_tree().create_timer(0.5).timeout
		process_turn_end()

func ai_turn():
	if available_cards.is_empty() or ai_selected_cards.size() >= max_cards_per_player:
		return

	var already_picked = ai_selected_cards + player_selected_cards
	var selectable_cards = available_cards.filter(func(card): return !already_picked.has(card))
	if selectable_cards.is_empty():
		print("⚠️ No selectable cooking methods left for AI.")
		return

	ai_agent.update_player_cards(player_selected_cards)
	var ai_selection = ai_agent.select_card(selectable_cards)
	if ai_selection == "":
		print("⚠️ AI failed to select a valid card.")
		return

	ai_selected_cards.append(ai_selection)
	Globals.ai_cooking_cards = ai_selected_cards.duplicate()
	available_cards.erase(ai_selection)

	ai_score_counter -= 1
	ai_label.text = str(ai_score_counter)

	var selected_button = card_placeholder.get_selected_button(ai_selection)
	if selected_button:
		selected_button.disabled = true
		selected_button.modulate = Color(0.5, 0.5, 0.5, 0.7)

	print("🤖 AI selected:", ai_selection)

func end_game():
	var player_score = calculate_score(player_selected_cards)
	var ai_score = calculate_score(ai_selected_cards)

	Globals.cooking_battle_results = {
		"player_score": player_score,
		"ai_score": ai_score,
		"player_cards": player_selected_cards.map(func(c): return c.get_file()),
		"ai_cards": ai_selected_cards.map(func(c): return c.get_file()),
		"total_score": {
			"player": player_score + Globals.ingredients_battle_results.get("player_score", 0),
			"ai": ai_score + Globals.ingredients_battle_results.get("ai_score", 0)
		}
	}

	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://UI/scenes/9-results_page.tscn")

func calculate_score(selected_cards: Array) -> int:
	var score = 0
	var cooking_data = selected_dish_data.get("cooking_methods", {})

	for card in selected_cards:
		var method_name = card.get_file().get_basename().to_lower()
		if cooking_data.get("incompatible", []).has(method_name):
			continue
		elif cooking_data.get("primary", []).has(method_name):
			score += 3
		elif cooking_data.get("secondary", []).has(method_name):
			score += 2
		else:
			score += 1
	return score

func on_card_selected(card_texture: String):
	if not is_player_turn or current_selection != "" or player_selected_cards.size() >= max_cards_per_player:
		return

	current_selection = card_texture
	available_cards.erase(card_texture)

	player_selected_cards.append(card_texture)
	Globals.player_cooking_cards = player_selected_cards.duplicate()
	total_cards_selected += 1

	ai_agent.update_player_cards(player_selected_cards)

	player_score_counter -= 1
	user_label.text = str(player_score_counter)

	var selected_button = card_placeholder.get_selected_button(card_texture)
	if selected_button:
		selected_button.disabled = true
		selected_button.modulate = Color(0.5, 0.5, 0.5, 0.7)

	turn_timer.stop()
	is_player_turn = false
	update_turn_ui()
	await get_tree().create_timer(0.6).timeout
	ai_turn()
	await get_tree().create_timer(0.5).timeout
	process_turn_end()

func update_turn_ui():
	if is_player_turn:
		user_info_panel.modulate = Color(1, 1, 1, 1)
		ai_info_panel.modulate = Color(0.6, 0.6, 0.6, 0.5)
		input_blocker.visible = false
	else:
		user_info_panel.modulate = Color(0.6, 0.6, 0.6, 0.5)
		ai_info_panel.modulate = Color(1, 1, 1, 1)
		input_blocker.visible = true
