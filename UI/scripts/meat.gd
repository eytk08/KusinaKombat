extends Control

var grid: GridContainer
var placeholder_scene = preload("res://UI/scenes/UICardPlaceholder.tscn")
var card_scene = preload("res://UI/scenes/UICard.tscn")

var card_types = ["A", "B", "C", "D", "E", "F"]  # Your card types

func _ready():
	setup_grid(4, 2)  # 4 columns, 3 rows
	distribute_cards()

func setup_grid(columns, rows):
	# Configure grid
	grid.columns = columns
	
	# Create placeholders
	for i in columns * rows:
		var ph = placeholder_scene.instance()
		grid.add_child(ph)
		ph.connect("card_clicked", self, "_on_card_clicked")

func distribute_cards():
	var placeholders = grid.get_children()
	var cards_to_place = []
	
	# Create pairs (for matching game)
	for type in card_types:
		cards_to_place.append(type)
		cards_to_place.append(type)
	
	cards_to_place.shuffle()
	
	for i in range(min(cards_to_place.size(), placeholders.size())):
		var card = card_scene.instance()
		card.setup(cards_to_place[i])
		placeholders[i].place_card(card)

func _on_card_clicked(card):
	print("Card clicked: ", card.card_data)
