extends RefCounted

enum BATTLE_TYPE {MEAT, INGREDIENTS, COOKING}

# Dish knowledge database
var dish_knowledge: Dictionary = {}

var available_cards: Array = []
var difficulty: int = 3
var player_selected_cards: Array = []
var selected_dish_id: String = ""
var current_battle_type: int = BATTLE_TYPE.MEAT


func _ready():
	load_dish_knowledge()

func load_dish_knowledge():
	var file = FileAccess.open("res://assets/dish_knowledge.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		var json_result = JSON.parse_string(json_text)
		if typeof(json_result) == TYPE_DICTIONARY:
			dish_knowledge = json_result
		else:
			push_error("Failed to parse JSON into Dictionary.")
	else:
		push_error("Failed to open dish knowledge file.")

# Initialize with battle type
func initialize(dish_data: Dictionary, cards: Array, type: int, player_cards: Array = []):
	selected_dish_id = dish_data.get("id", "")
	available_cards = cards.duplicate()
	player_selected_cards = player_cards.duplicate()
	current_battle_type = type

func select_card(available_cards: Array) -> String:
	if available_cards.is_empty():
		return ""

	var card_scores = _score_all_cards()

	# Sort cards by score (highest first)
	card_scores.sort_custom(func(a, b): return a["score"] > b["score"])

	# Difficulty affects decision making
	var pick_optimal = randf() < (0.5 + difficulty * 0.2)

	if pick_optimal and card_scores.size() > 0 and card_scores[0]["score"] > -50:
		return card_scores[0]["card"]
	elif card_scores.size() > 0:
		# Random selection from top 3 cards
		var top_candidates = card_scores.slice(0, min(3, card_scores.size()))
		if top_candidates.size() > 0:
			return top_candidates[randi() % top_candidates.size()]["card"]

	# Fallback to random selection if all else fails
	return available_cards[randi() % available_cards.size()]

func _score_all_cards() -> Array:
	var player_missing_essential = _is_player_missing_essentials()
	var card_scores = []

	for card in available_cards:
		var score_data = {
			"card": card,
			"score": _score_card(card, player_missing_essential)
		}
		card_scores.append(score_data)

	return card_scores

func _get_current_battle_key() -> String:
	match current_battle_type:
		BATTLE_TYPE.MEAT:
			return "meat"
		BATTLE_TYPE.INGREDIENTS:
			return "ingredients"
		BATTLE_TYPE.COOKING:
			return "cooking"
		_:
			return ""

func _contains_word(text: String, word: String) -> bool:
	var regex = RegEx.new()
	regex.compile("\\b" + word.to_lower() + "\\b")
	return regex.search(text.to_lower()) != null

func _score_card(card: String, player_missing_essential: bool) -> int:
	var score = 0
	var card_lower = card.to_lower()
	var dish_data = dish_knowledge.get(selected_dish_id, {}).get(_get_current_battle_key(), {})

	# Essential ingredients scoring
	for ingredient in dish_data.get("essential", []):
		if _contains_word(card, ingredient):
			score += 4  # Highest priority

	# Block player from getting essentials if they're missing
	if player_missing_essential:
		for ingredient in dish_data.get("essential", []):
			if _contains_word(card, ingredient):
				score += 2  # Blocking bonus

	# Tier1 ingredients
	for item in dish_data.get("tier1", []):
		if _contains_word(card, item):
			score += 3

	# Tier2 ingredients
	for item in dish_data.get("tier2", []):
		if _contains_word(card, item):
			score += 1

	# Avoid bad picks
	for avoid in dish_data.get("avoid", []):
		if _contains_word(card, avoid):
			score -= 100  # Heavy penalty

	# Small random variation
	score += randi() % 3 - 1

	return score

func _is_player_missing_essentials() -> bool:
	var dish_data = dish_knowledge.get(selected_dish_id, {}).get(_get_current_battle_key(), {})

	for item in dish_data.get("essential", []):
		var player_has = false
		for card in player_selected_cards:
			if _contains_word(card, item):
				player_has = true
				break

		if not player_has:
			return true

	return false

func remove_card(card_data: String):
	available_cards.erase(card_data)

func update_player_cards(new_cards: Array):
	player_selected_cards = new_cards.duplicate()
