# card_manager_ingredients.gd
extends Node

func get_ingredient_cards_for_dish(dish_data: Dictionary) -> Array:
	var all_ingredients = [
		"garlic.png", "onion.png", "pepper.png", "salt.png",
		"oil.png", "butter.png", "flour.png", "sugar.png",
		"vinegar.png", "soy_sauce.png", "herbs.png", "spices.png"
	]
	
	var dish_ingredients = dish_data.get("ingredients", [])
	var matched_ingredients = []
	var other_ingredients = []
	
	# Separate ingredients that match the dish
	for ingredient in all_ingredients:
		var ingredient_name = ingredient.replace(".png", "").replace("_", " ").to_lower()
		for dish_ing in dish_ingredients:
			if dish_ing.to_lower() in ingredient_name:
				matched_ingredients.append(ingredient)
				break
			else:
				other_ingredients.append(ingredient)
	
	# Shuffle and select cards (prioritizing matching ingredients)
	matched_ingredients.shuffle()
	other_ingredients.shuffle()
	
	# Return 8 cards (or as many as available) with priority to matched ingredients
	var selected_cards = []
	selected_cards.append_array(matched_ingredients.slice(0, min(4, matched_ingredients.size())))
	selected_cards.append_array(other_ingredients.slice(0, min(8 - selected_cards.size(), other_ingredients.size())))
	
	return selected_cards

func _on_continue_button_pressed():
	# Transition to ingredients scene
	var ingredients_scene = preload("res://UI/scenes/7-Vegetable_sec.tscn").instantiate()
	get_tree().root.add_child(ingredients_scene)
	queue_free()  # Remove current meat scene
