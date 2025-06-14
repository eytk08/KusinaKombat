extends Label

@export var bounce_height := 10.0
@export var bounce_speed := 3.0

var time := 0.0

func _process(delta):
	time += delta
	queue_redraw()

func _draw():
	var font = get_theme_font("font")
	var font_size = get_theme_font_size("font_size")
	var pos = Vector2.ZERO

	for i in text.length():
		var char_str = text.substr(i, 1)
		var bounce = abs(sin(time * bounce_speed + i * 0.5)) * bounce_height
		draw_char(font, pos + Vector2(0, -bounce), char_str, font_size, -1)
		pos.x += font.get_char_size(char_str[0], font_size).x
