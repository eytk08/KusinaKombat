extends Control

@onready var label = $Label1

func _ready():
	var result_text := ""

	result_text += format_result("🥩 Meat Battle", Globals.meat_battle_results)
	result_text += "\n" + format_result("🧂 Ingredients Battle", Globals.ingredients_battle_results)
	result_text += "\n" + format_result("🍳 Cooking Battle", Globals.cooking_battle_results)

	label.text = result_text

func format_result(title: String, result_data: Dictionary) -> String:
	var player_score = result_data.get("player", 0)
	var ai_score = result_data.get("ai", 0)

	var outcome := ""
	if player_score > ai_score:
		outcome = "✅ Player Wins"
	elif ai_score > player_score:
		outcome = "❌ AI Wins"
	else:
		outcome = "🤝 Draw"

	return "%s:\nPlayer: %d vs AI: %d → %s" % [title, player_score, ai_score, outcome]
