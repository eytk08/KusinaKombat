# card_manager.gd
extends Node

# Load all meat cards at startup
var all_meat_cards: Array = []

func _ready():
	load_all_meat_cards()

func load_all_meat_cards():
	var dir = DirAccess.open("res://assets/cards/meat/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".png"):
				all_meat_cards.append(file_name)
			file_name = dir.get_next()
	else:
		printerr("Could not open meat cards directory!")

func get_meat_cards_for_dish(dish_data: Dictionary, total_cards_needed: int = 8) -> Array:
	var dish_meats = dish_data.get("meat", [])
	print("DEBUG: Looking for cards matching meats: ", dish_meats)  # DEBUG

	var matching_cards = []
	var other_cards = all_meat_cards.duplicate()
	
	# Find cards that match dish meats
	for meat in dish_meats:
		var meat_name = meat.to_lower().replace(" ", "_")
		print("DEBUG: Searching for meat pattern: ", meat_name)  # DEBUG
		for card in all_meat_cards:
			if meat_name in card.to_lower():
				print("DEBUG: Found matching card: ", card)
				matching_cards.append(card)
				other_cards.erase(card)  # Remove from other cards
	print("DEBUG: Matching cards found: ", matching_cards.size()) 
	# If we have enough matching cards, use them
	if matching_cards.size() >= total_cards_needed:
		return matching_cards.slice(0, total_cards_needed)
	
	# Otherwise mix with random other meat cards
	var final_cards = matching_cards.duplicate()
	while final_cards.size() < total_cards_needed and other_cards.size() > 0:
		var random_index = randi() % other_cards.size()
		final_cards.append(other_cards[random_index])
		other_cards.remove_at(random_index)
		
	print("DEBUG: Final cards to display: ", final_cards)  # DEBUG
	return final_cards
