extends Control

signal card_selected(texture_path: String)

@onready var grid_container = $GridContainer
var texture_buttons: Array = []

func _ready():
	# Get all TextureButton nodes when the scene loads
	for child in grid_container.get_children():
		if child is TextureButton:
			texture_buttons.append(child)
			child.visible = false  # Hide by default
			child.modulate = Color(1, 1, 1, 1)

func setup_with_textures(texture_paths: Array):
	# First reset all buttons
	for button in texture_buttons:
		button.visible = false
		button.modulate = Color(1, 1, 1, 1)
		if button.pressed.is_connected(_on_card_pressed):
			button.pressed.disconnect(_on_card_pressed)
	
	# Show and setup only the needed buttons
	for i in range(min(texture_paths.size(), texture_buttons.size())):
		var texture = load("res://assets/cards/meat/" + texture_paths[i])
		if texture:
			texture_buttons[i].texture_normal = texture
			# Connect with the button reference
			texture_buttons[i].pressed.connect(
				func(): _on_card_pressed(texture_paths[i], texture_buttons[i])
			)
			texture_buttons[i].visible = true
		else:
			push_warning("Failed to load texture: " + texture_paths[i])

func _on_card_pressed(texture_path: String, button: TextureButton):
	# Visual feedback when clicked
	var tween = create_tween()
	tween.tween_property(button, "modulate", Color(0.5, 0.5, 0.5, 0.7), 0.1)
	
	emit_signal("card_selected", texture_path)

func get_selected_button(texture_path: String) -> TextureButton:
	for button in texture_buttons:
		if button.visible and button.texture_normal:
			if button.texture_normal.resource_path.ends_with(texture_path):
				return button
	return null
