extends Control

@onready var dish_name_label: Label = $DishNameLabel
@onready var announcement_label: Label = $AnnouncementLabel

signal dish_selected(dish_data: Dictionary)

const loading_scene_path = "res://UI/scenes/5-loading_sec.tscn"

func _ready():
	if not dish_name_label:
		printerr("DishNameLabel not found!")
	if not announcement_label:
		printerr("AnnouncementLabel not found!")

func display_dish(dish_name: String, input_data: Dictionary):
	if not is_instance_valid(dish_name_label) or not is_instance_valid(announcement_label):
		printerr("UI labels not initialized!")
		return

	visible = true		
	var display_name = dish_name.replace("-", " ").capitalize()
	announcement_label.text = "Hmm...\n%s!\nTama! Halika na at baka maubusan tayo." % display_name

	# 🔍 Fetch full data from dataset
	var full_dish_data = Globals.dishes_data.get(dish_name.to_lower(), {})

	# Fallback to input_data in case it's not found
	if full_dish_data.is_empty():
		full_dish_data = input_data

	full_dish_data["name"] = display_name
	full_dish_data["theme"] = input_data.get("theme", "")  # optional override

	Globals.selected_dish_name = display_name
	set_meta("selected_dish", full_dish_data)

	# ✅ Log full data
	print("🍽 Selected Dish: %s" % display_name)
	print("📦 Full Dish Data:")
	print(JSON.stringify(full_dish_data, "\t"))
	
func _on_texture_button_pressed() -> void:
	if is_inside_tree() and get_tree():
		get_tree().change_scene_to_file(loading_scene_path)
	else:
		printerr("Cannot change scene - scene tree not available")
