# card_manager_ingredients.gd
extends Node

# Returns array containing 4 cooking method cards (required + random)
func get_cooking_cards_for_dish(dish_data: Dictionary, total_cards: int = 4) -> Array:
	var all_cards := []
	
	# 1. Get required cooking methods first
	var required_methods := _get_required_cooking_methods(dish_data)
	all_cards.append_array(required_methods)
	
	# 2. Fill remaining slots with random methods
	var remaining_slots = total_cards - required_methods.size()
	if remaining_slots > 0:
		var random_methods := _get_random_cooking_methods(remaining_slots, required_methods)
		all_cards.append_array(random_methods)
	
	# 3. Shuffle the combined array
	all_cards.shuffle()
	
	print("🍳 Generated %d cooking methods (%d required + %d random)" % [
		all_cards.size(),
		required_methods.size(),
		total_cards - required_methods.size()
	])
	return all_cards

# Gets required cooking methods from dish data
func _get_required_cooking_methods(dish_data: Dictionary) -> Array:
	var required_methods := []
	if dish_data.has("cooking_method"):
		for method in dish_data["cooking_method"]:
			var texture_path = "res://assets/cards/cooking/%s.png" % method.to_lower().replace(" ", "_").strip_edges()
			if ResourceLoader.exists(texture_path):
				required_methods.append(texture_path)
			else:
				printerr("⚠️ Missing cooking method texture: ", texture_path)
	return required_methods

# Gets random cooking methods that aren't already included
func _get_random_cooking_methods(count: int, exclude: Array) -> Array:
	var random_methods := []
	var available_methods := _get_all_cooking_methods()
	
	# Create pool excluding required methods
	var method_pool := []
	for method in available_methods:
		if not exclude.has(method):
			method_pool.append(method)
	
	# Safety check
	count = min(count, method_pool.size())
	
	# Fisher-Yates shuffle
	for i in range(method_pool.size() - 1, 0, -1):
		var j = randi() % (i + 1)
		var temp = method_pool[i]
		method_pool[i] = method_pool[j]
		method_pool[j] = temp
	
	return method_pool.slice(0, count)

# Cached list of all cooking method textures
var _cached_cooking_methods := []
func _get_all_cooking_methods() -> Array:
	if _cached_cooking_methods.is_empty():
		var dir = DirAccess.open("res://assets/cards/cooking/")
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir() and file_name.ends_with(".png"):
					_cached_cooking_methods.append("res://assets/cards/cooking/" + file_name)
				file_name = dir.get_next()
		else:
			printerr("⚠️ Could not open cooking methods directory!")
	return _cached_cooking_methods.duplicate()
