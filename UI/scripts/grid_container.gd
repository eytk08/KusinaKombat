extends GridContainer

func _ready():
	
	columns = 3  # Set to your column count
	add_theme_constant_override("hseparation", 20)  # Horizontal spacing
	add_theme_constant_override("vseparation", 20)  # Vertical spacing
	
	var placeholder_scene = preload("res://UI/scenes/UICardPlaceholder.tscn")
	
	for i in 7:
		var ph = placeholder_scene.instantiate()
		ph.name = "Slot_%d" % i
		add_child(ph)
