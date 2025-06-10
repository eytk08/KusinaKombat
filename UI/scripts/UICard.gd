# UICard.gd
extends TextureButton

signal card_clicked(card)

var card_data = null

func setup(data):
	card_data = data
	texture_normal = load("res://cards/%s.png" % data)

func _on_UICard_pressed():
	emit_signal("card_clicked", self)
