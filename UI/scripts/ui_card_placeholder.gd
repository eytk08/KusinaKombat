# UICardPlaceholder.gd
extends Control

signal card_received(card_ref)

var occupied: bool = false
var current_card: Control = null

func _ready():
	# Visual setup
	custom_minimum_size = Vector2(120, 180)
	add_theme_stylebox_override("panel", get_theme_stylebox("panel", "CardPlaceholder"))

func can_drop_data(_position, data):
	return data is Dictionary and data.has("card") and not occupied

func drop_data(_position, data):
	var card = data["card"]
	if card is Control and not occupied:
		occupy(card)
		emit_signal("card_received", card)

func occupy(card: Control):
	occupied = true
	current_card = card
	# Visual feedback
	modulate = Color(1, 1, 1, 0.5)

func release():
	occupied = false
	current_card = null
	modulate = Color(1, 1, 1, 1)
