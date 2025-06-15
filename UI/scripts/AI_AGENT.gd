# ai_agent.gd
extends RefCounted

enum BATTLE_TYPE {MEAT, INGREDIENTS}

# Dish knowledge database
var dish_knowledge: Dictionary = {
	"beef_stew": {
		"meat": {
			"essential": ["beef"],
			"tier1": ["lamb"],
			"avoid": ["fish", "poultry"]
		},
		"ingredients": {
			"essential": ["carrot", "potato"],
			"tier1": ["red_wine", "thyme"],
			"tier2": ["mushroom", "onion"],
			"avoid": ["citrus", "sugar"]
		}
	}
}

var available_cards: Array = []
var difficulty: int = 1  # 1-3 scale
var player_selected_cards: Array = []
var selected_dish_id: String = ""
var current_battle_type: int = BATTLE_TYPE.MEAT

# Initialize with battle type
func initialize(dish_data: Dictionary, cards: Array, type: int, player_cards: Array = []):
	selected_dish_id = dish_data.get("id", "")
	available_cards = cards.duplicate()
	player_selected_cards = player_cards.duplicate()
	current_battle_type = type

func select_card() -> String:
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

func _score_card(card: String, player_missing_essential: bool) -> int:
	var score = 0
	var card_lower = card.to_lower()
	var dish_data = dish_knowledge.get(selected_dish_id, {}).get("meat" if current_battle_type == BATTLE_TYPE.MEAT else "ingredients", {})
	
	# Essential ingredients scoring
	for ingredient in dish_data.get("essential", []):
		if ingredient.to_lower() in card_lower:
			score += 4  # Highest priority
	
	# Block player from getting essentials if they're missing
	if player_missing_essential:
		for ingredient in dish_data.get("essential", []):
			if ingredient.to_lower() in card_lower:
				score += 2  # Blocking bonus
	
	# Tier1 ingredients
	for item in dish_data.get("tier1", []):
		if item.to_lower() in card_lower:
			score += 3
	
	# Tier2 ingredients
	for item in dish_data.get("tier2", []):
		if item.to_lower() in card_lower:
			score += 1
	
	# Avoid bad picks
	for avoid in dish_data.get("avoid", []):
		if avoid.to_lower() in card_lower:
			score -= 100  # Heavy penalty
	
	# Small random variation
	score += randi() % 3 - 1
	
	return score

func _is_player_missing_essentials() -> bool:
	var dish_data = dish_knowledge.get(selected_dish_id, {}).get("meat" if current_battle_type == BATTLE_TYPE.MEAT else "ingredients", {})
	
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
