extends Control
# UICardPlaceholder.gd

func setup_with_textures(texture_paths: Array):
	# Clear existing cards
	for child in get_children():
		child.queue_free()
	
	# Create new cards
	for i in range(min(texture_paths.size(), 8)):  # Limit to 8 cards
		var texture_rect = TextureRect.new()
		texture_rect.texture = load("res://assets/cards/meat/" + texture_paths[i])
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(texture_rect)
		
