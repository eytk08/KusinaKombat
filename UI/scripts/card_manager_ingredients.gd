# card_manager_ingredients.gd
extends Node

# Returns array containing required ingredients + random ones (total of 21)
func get_ingredient_cards_for_dish(dish_data: Dictionary, total_cards: int = 21) -> Array:
	var all_cards := []
	
	# 1. Get required ingredients first
	var required_cards := _get_required_cards(dish_data)
	all_cards.append_array(required_cards)
	
	# 2. Calculate how many random cards we need
	var remaining_slots = total_cards - required_cards.size()
	if remaining_slots > 0:
		var random_cards := _get_random_ingredient_cards(remaining_slots, required_cards)
		all_cards.append_array(random_cards)
	
	# 3. Shuffle the combined array
	all_cards.shuffle()
	
	print("📦 Generated %d cards (%d required + %d random)" % [
		all_cards.size(),
		required_cards.size(),
		total_cards - required_cards.size()
	])
	return all_cards

# Helper function to get required ingredients 
func _get_required_cards(dish_data: Dictionary) -> Array:
	var required_cards := []
	if dish_data.has("ingredients"):
		for ingredient in dish_data["ingredients"]:
			var cleaned_name = ingredient.to_lower().strip_edges()
			cleaned_name = cleaned_name.replace(" ", "_").replace("-", "_")
			var texture_path = "res://assets/cards/ingredients/%s.png" % cleaned_name
			if ResourceLoader.exists(texture_path):
				required_cards.append(texture_path)
			else:
				printerr("⚠️ Missing required texture: ", texture_path)
	return required_cards

# Enhanced random card selection that ensures we get exactly the requested amount
func _get_random_ingredient_cards(count: int, exclude: Array) -> Array:
	var random_cards := []
	var available_cards := _get_all_ingredient_paths()
	
	# Create a pool of available cards excluding required ones
	var card_pool := []
	for card in available_cards:
		if not exclude.has(card):
			card_pool.append(card)
	
	# If we don't have enough cards, use what we have
	count = min(count, card_pool.size())
	
	# Fisher-Yates shuffle algorithm for better randomness
	for i in range(card_pool.size() - 1, 0, -1):
		var j = randi() % (i + 1)
		var temp = card_pool[i]
		card_pool[i] = card_pool[j]
		card_pool[j] = temp
	
	# Take the first 'count' cards from the shuffled pool
	random_cards = card_pool.slice(0, count)
	
	return random_cards

# Cache the ingredient paths for better performance
var _cached_ingredient_paths := []
func _get_all_ingredient_paths() -> Array:
	if _cached_ingredient_paths.is_empty():
		var dir = DirAccess.open("res://assets/cards/ingredients/")
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir() and file_name.ends_with(".png"):
					_cached_ingredient_paths.append("res://assets/cards/ingredients/" + file_name)
				file_name = dir.get_next()
		else:
			printerr("⚠️ Could not open ingredients directory!")
	return _cached_ingredient_paths.duplicate()
