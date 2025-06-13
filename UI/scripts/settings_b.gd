extends TextureButton

# Option 1: Preload and manage instance
var settings_scene = preload("res://UI/scenes/settings.tscn")
var settings_instance = null

func _on_settings_b_pressed() -> void:
	if settings_instance == null:
		settings_instance = settings_scene.instantiate()
		get_tree().root.add_child(settings_instance)
	
	settings_instance.visible = true
	settings_instance.show()  # Alternative to visible = true

# Call this when closing settings
func _on_settings_closed():
	if settings_instance:
		settings_instance.visible = false
