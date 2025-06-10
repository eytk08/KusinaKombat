# UICardPlaceholder.gd
extends Control
class_name UICardPlaceholder


signal card_placed
signal card_removed

var current_card = null

func place_card(card_instance):
	if current_card != null:
		return false
	
	add_child(card_instance)
	card_instance.rect_position = Vector2.ZERO
	current_card = card_instance
	emit_signal("card_placed")
	return true

func remove_card():
	if current_card:
		current_card.queue_free()
		current_card = null
		emit_signal("card_removed")
