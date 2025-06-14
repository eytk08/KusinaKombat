# global_game_state.gd
extends Node

var player_selected_meats: Array = []
var ai_selected_meats: Array = []
var player_selected_ingredients: Array = []
var ai_selected_ingredients: Array = []
var selected_dish_data: Dictionary = {}

func reset():
	player_selected_meats = []
	ai_selected_meats = []
	player_selected_ingredients = []
	ai_selected_ingredients = []
	selected_dish_data = {}
