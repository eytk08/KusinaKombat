extends Control

@onready var label = $Label1

func _ready():
	# TEMP test data
	Globals.meat_battle_results = {
		"player": 2,
		"ai": 2,
		"player_cards": ["chicken.png", "shrimp.png"],
		"ai_cards": ["fish.png", "beef.png"]
	}

	Globals.ingredients_battle_results = {
		"player": 3,
		"ai": 3,
		"player_cards": ["vinegar.png", "soy_sauce.png", "cabbage.png"],
		"ai_cards": ["coconut.png", "mung beans.png", "okra.png"]
	}

	Globals.cooking_battle_results = {
		"player": 1,
		"ai": 2,
		"player_cards": ["boil.png"],
		"ai_cards": ["saute.png", "grill.png"]
	}

	# Generate result text
	var result_text := ""
	result_text += format_result("🥩 Meat Battle", Globals.meat_battle_results)
	result_text += "\n" + format_result("🧂 Ingredients Battle", Globals.ingredients_battle_results)
	result_text += "\n" + format_result("🍳 Cooking Battle", Globals.cooking_battle_results)

	label.text = result_text

func format_result(title: String, result_data: Dictionary) -> String:
	var player_score = result_data.get("player", 0)
	var ai_score = result_data.get("ai", 0)
	var player_cards = result_data.get("player_cards", [])
	var ai_cards = result_data.get("ai_cards", [])

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
