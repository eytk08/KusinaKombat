extends Control

@onready var label = $Label1
@onready var home_button = $HomeButton

func _ready():
	home_button.pressed.connect(on_home_pressed)
	
	# Declare selected_dish and knowledge for debugging
	var selected_dish = Globals.selected_dish_name.strip_edges().to_lower().replace(" ", "_")
	print("🌐 Selected Dish Raw:", Globals.selected_dish_name)
	print("🌐 Normalized Key:", selected_dish)

	# Load the dish knowledge base
	var knowledge = load_dish_knowledge()
	print("📘 Available Dishes:", knowledge.keys())

	if not knowledge.has(selected_dish):
		print("❌ Dish '%s' not found in knowledge base." % selected_dish)
		label.text = "Selected dish not found in knowledge base."
		return

	# Continue with the rest of the game logic if dish is found
	var meat_result = calculate_score(Globals.player_meat_cards, Globals.ai_meat_cards, knowledge[selected_dish]["meat"])
	var ingredient_result = calculate_score(Globals.player_ingredient_cards, Globals.ai_ingredient_cards, knowledge[selected_dish]["ingredients"])
	var cooking_result = calculate_score(Globals.player_cooking_cards, Globals.ai_cooking_cards, knowledge[selected_dish]["cooking_methods"])

	Globals.meat_battle_results = meat_result
	Globals.ingredients_battle_results = ingredient_result
	Globals.cooking_battle_results = cooking_result

	var result_text := ""
	result_text += format_result("🥩 Meat Battle", meat_result)
	result_text += "\n" + format_result("🧂 Ingredients Battle", ingredient_result)
	result_text += "\n" + format_result("🍳 Cooking Battle", cooking_result)

	var player_avg = float(meat_result.player + ingredient_result.player + cooking_result.player) / 3.0
	var ai_avg = float(meat_result.ai + ingredient_result.ai + cooking_result.ai) / 3.0

	player_avg = round(player_avg * 100) / 100.0
	ai_avg = round(ai_avg * 100) / 100.0

	var final_outcome := "\n📊 Final Average Score:\nPlayer: %.2f\nAI: %.2f\n" % [player_avg, ai_avg]
	if player_avg > ai_avg:
		final_outcome += "🏆 Final Result: ✅ Player Wins Overall!"
	elif ai_avg > player_avg:
		final_outcome += "🏆 Final Result: ❌ AI Wins Overall!"
	else:
		final_outcome += "🏆 Final Result: 🤝 It's a Draw!"

	result_text += "\n\n" + final_outcome
	label.text = result_text

	# ✅ Log to console
	print("============================")
	print("📋 FINAL GAME RESULTS")
	print("============================")
	print(result_text)
	print("============================")


func on_home_pressed():
	get_tree().change_scene_to_file("res://UI/scenes/1-title_screen.tscn")  # Update path if different\

func load_dish_knowledge() -> Dictionary:
	var file = FileAccess.open("res://assets/dish_knowledge.json", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var result = JSON.parse_string(content)
		if typeof(result) == TYPE_DICTIONARY and result.has("dish_knowledge"):
			return result["dish_knowledge"]
		else:
			push_error("Invalid JSON format in dish_knowledge.json")
	else:
		push_error("Failed to open dish_knowledge.json")
	return {}

func calculate_score(player_cards: Array, ai_cards: Array, rules: Dictionary) -> Dictionary:
	var score_table = {
		"essential": 1,
		"tier1": 1,
		"avoid": -5,
		"primary": 2,
		"secondary": 1, 
		"incompatible": -1, 
	}

	var player_score = get_score(player_cards, rules, score_table)
	var ai_score = get_score(ai_cards, rules, score_table)

	return {
		"player": player_score,
		"ai": ai_score,
		"player_cards": player_cards,
		"ai_cards": ai_cards
	}

func get_score(cards: Array, rules: Dictionary, score_table: Dictionary) -> int:
	var total = 0
	for card in cards:
		var filename = card.get_file() if card is Resource else str(card)
		var name = filename.get_file().get_basename().to_lower().replace(".png", "")
		for key in score_table.keys():
			if key in rules and name in rules[key]:
				total += score_table[key]
				break
	return total

func format_result(title: String, result_data: Dictionary) -> String:
	var player_score = result_data.get("player", 0)
	var ai_score = result_data.get("ai", 0)
	var player_cards_raw = result_data.get("player_cards", [])
	var ai_cards_raw = result_data.get("ai_cards", [])

	var player_cards = []
	for card in player_cards_raw:
		var filename = card.get_file() if card is Resource else str(card)
		player_cards.append(filename.get_file().get_basename().to_lower())

	var ai_cards = []
	for card in ai_cards_raw:
		var filename = card.get_file() if card is Resource else str(card)
		ai_cards.append(filename.get_file().get_basename().to_lower())

	var outcome := ""
	if player_score > ai_score:
		outcome = "✅ Player Wins"
	elif ai_score > player_score:
		outcome = "❌ AI Wins"
	else:
		outcome = "🤝 Draw"

	return "%s:\nPlayer: %d vs AI: %d → %s\n🧍 Player Cards: %s\n🤖 AI Cards: %s\n" % [
		title,
		player_score,
		ai_score,
		outcome,
		str(player_cards),
		str(ai_cards)
	]
