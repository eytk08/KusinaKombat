extends Control

@onready var dish_name_label: Label = $DishNameLabel
@onready var announcement_label: Label = $AnnouncementLabel


signal dish_selected(dish_data: Dictionary)


func _ready():
	# Verify nodes exist
	if not dish_name_label:
		printerr("DishNameLabel not found!")
	if not announcement_label:
		printerr("AnnouncementLabel not found!")

func display_dish(dish_name: String, dish_data: Dictionary):
	if not is_instance_valid(dish_name_label) or not is_instance_valid(announcement_label):
		printerr("UI labels not initialized!")
		return
	
	visible = true
	announcement_label.text = "Hmm.. ano kaya ang masarap ayon sa tema?\nAlam ko na!"
	
	await get_tree().create_timer(1).timeout
	
	var display_name = dish_name.replace("-", " ").capitalize()
	announcement_label.text = " %s!\nHalika na at mamili sa palengke!" % display_name
	dish_name_label.text 
	set_meta("selected_dish", dish_data)
	Globals.selected_dish_name = dish_data["name"]  

const loading_scene_path = "res://UI/scenes/5-loading_sec.tscn"

func _on_texture_button_pressed() -> void:
	if is_inside_tree() and get_tree():
		get_tree().change_scene_to_file(loading_scene_path)
	else:
		printerr("Cannot change scene - scene tree not available")
