extends TextureButton

func _on_pressed():
	# This will work with either approach:
	# 1. If using hide/show:
	get_parent().visible = false
	
	# 2. If using queue_free:
	# get_parent().queue_free()
	
	# Always unpause if you paused the game
	get_tree().paused = false
