# ai_agent.gd
extends RefCounted

var dish_knowledge: Dictionary = {
	# Example structure (you should populate this with your actual dish data)
	"beef_stew": {
		"essential": ["beef", "carrot", "potato"],
		"tier1": ["red_wine", "thyme"],
		"tier2": ["mushroom", "onion"],
		"avoid": ["fish", "citrus"]
	}
}
var available_cards: Array = []
var difficulty: int = 1  # 1-3 scale
var player_selected_cards: Array = []
var selected_dish_id: String = ""

func initialize(dish_data: Dictionary, cards: Array, player_cards: Array):
	selected_dish_id = dish_data.get("id", "")
	available_cards = cards.duplicate()
	player_selected_cards = player_cards.duplicate()
	
	# If dish isn't in knowledge base, create a basic entry
	if not dish_knowledge.has(selected_dish_id):
		dish_knowledge[selected_dish_id] = {
			"essential": dish_data.get("required_ingredients", []),
			"tier1": [],
			"tier2": dish_data.get("optional_ingredients", []),
			"avoid": []
		}

func select_card() -> String:
	var card_scores = _score_all_cards()
	
	# Sort cards by score (highest first)
	card_scores.sort_custom(func(a, b): return a["score"] > b["score"])
	
	# Difficulty affects how often it picks optimal cards
	var pick_optimal = randf() < (0.5 + difficulty * 0.2)
	
	if pick_optimal and card_scores.size() > 0 and card_scores[0]["score"] > 0:
		return card_scores[0]["card"]
	elif card_scores.size() > 0:
		# Fall back to random selection from top 3 cards
		var top_candidates = card_scores.slice(0, min(3, card_scores.size() - 1))
		return top_candidates[randi() % top_candidates.size()]["card"]
	else:
		return ""

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

func _score_card(card: String, player_missing_essential: bool) -> int:
	var score = 0
	var card_lower = card.to_lower()
	var dish_data = dish_knowledge.get(selected_dish_id, {})
	
	# Priority 1: Essential ingredients
	for ingredient in dish_data.get("essential", []):
		if ingredient.to_lower() in card_lower:
			score += 4  # Highest priority
	
	# Priority 2: Deny player essentials if they're lacking
	if player_missing_essential:
		for ingredient in dish_data.get("essential", []):
			if ingredient.to_lower() in card_lower:
				score += 2  # Blocking bonus
	
	# Priority 3: Tier1 ingredients
	for item in dish_data.get("tier1", []):
		if item.to_lower() in card_lower:
			score += 3
	
	# Priority 4: Tier2 ingredients
	for item in dish_data.get("tier2", []):
		if item.to_lower() in card_lower:
			score += 1
	
	# Penalties for bad picks
	for avoid in dish_data.get("avoid", []):
		if avoid.to_lower() in card_lower:
			score -= 100  # Make sure AI never picks these
	
	# Small random variation to make AI less predictable
	score += randi() % 3 - 1
	
	return score

func _is_player_missing_essentials() -> bool:
	var dish_data = dish_knowledge.get(selected_dish_id, {})
	
	for item in dish_data.get("essential", []):
		var player_has = false
		for card in player_selected_cards:
			if item.to_lower() in card.to_lower():
				player_has = true
				break
		
		if not player_has:
			return true
	
	return false

func remove_card(card_data: String):
	available_cards.erase(card_data)

func update_player_cards(new_cards: Array):
	player_selected_cards = new_cards.duplicate()
