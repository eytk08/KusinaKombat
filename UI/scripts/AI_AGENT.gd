extends RefCounted

enum BATTLE_TYPE {MEAT, INGREDIENTS, COOKING}

# Dish knowledge database
var dish_knowledge: Dictionary = {}
var dish_data: Dictionary = {}

var available_cards: Array = []
var difficulty: int = 3
var player_selected_cards: Array = []
var selected_dish_id: String = ""
var current_battle_type: int = BATTLE_TYPE.MEAT
var selected_cards: Array = []
var player_cards: Array = []

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
	self.dish_data = dish_data  # ✅ This fixes future .get("meat") or .get("ingredients")
	selected_dish_id = dish_data.get("id", "")
	available_cards = cards.duplicate()
	player_selected_cards = player_cards.duplicate()
	current_battle_type = type

func select_card(selectable_cards: Array) -> String:
	if selectable_cards.is_empty():
		return ""

	var scores = _score_all_cards(selectable_cards)
	if scores.is_empty():
		return ""

	# Sort by descending score, return the top card
	scores.sort_custom(func(a, b):
		return b["score"] - a["score"]
	)

	return scores[0]["card"]



func select_from_priority(selectable_cards: Array, category_data: Dictionary) -> String:
	var priority_items = category_data.get("essential", []) + category_data.get("tier1", [])
	var avoid_items = category_data.get("avoid", [])

	# Try to select from essential and tier1
	var preferred = selectable_cards.filter(func(card):
		var item_name = card.get_file().replace(".png", "").to_lower()
		return priority_items.has(item_name)
	)

	if preferred.size() > 0:
		return preferred[randi() % preferred.size()]

	# Fallback: try to avoid avoid_items
	var safe = selectable_cards.filter(func(card):
		var item_name = card.get_file().replace(".png", "").to_lower()
		return !avoid_items.has(item_name)
	)

	if safe.size() > 0:
		return safe[randi() % safe.size()]

	# Last fallback: anything
	return selectable_cards[randi() % selectable_cards.size()]


func _score_all_cards(card_list: Array) -> Array:
	var scores = []
	var missing_essential = _is_player_missing_essentials()

	for card in card_list:
		var score = _score_card(card, missing_essential)
		scores.append({ "card": card, "score": score })
		#print("Scoring card: ", card, " → ", score)

	return scores

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

func _contains_word(card: String, word: String) -> bool:
	var normalized_card := normalize_card_name(card)
	var normalized_word := word.to_lower()
	return normalized_card == normalized_word

func _score_card(card: String, player_missing_essential: bool) -> int:
	var score = 0
	var dish_data = dish_knowledge.get(selected_dish_id, {}).get(_get_current_battle_key(), {})

	# Early rejection for avoid-listed items
	for avoid in dish_data.get("avoid", []):
		if _contains_word(card, avoid):
			return -9999

	# Essential ingredients
	for item in dish_data.get("essential", []):
		if _contains_word(card, item):
			score += 4

	# Block bonus if player lacks essential
	if player_missing_essential:
		for item in dish_data.get("essential", []):
			if _contains_word(card, item):
				score += 2

	# Tier1
	for item in dish_data.get("tier1", []):
		if _contains_word(card, item):
			score += 3

	# Tier2
	for item in dish_data.get("tier2", []):
		if _contains_word(card, item):
			score += 1

	return score

func _is_player_missing_essentials() -> bool:
	var dish_data = dish_knowledge.get(selected_dish_id, {}).get(_get_current_battle_key(), {})

	for item in dish_data.get("essential", []):
		for card in player_selected_cards:
			if _contains_word(card, item):
				return false
	return true

func remove_card(card_data: String):
	available_cards.erase(card_data)

func update_player_cards(new_cards: Array):
	player_selected_cards = new_cards.duplicate()

func normalize_card_name(card: String) -> String:
	var base := card.get_file().get_basename()
	return base.replace("_", " ").to_lower()
