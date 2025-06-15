extends TextureButton

# Add a small delay to ensure safe scene transition
var scene_change_requested := false

func _ready():
	# Use call_deferred for safer connection
	pressed.connect(_on_pressed.bind(), CONNECT_DEFERRED)

func _on_pressed():
	if scene_change_requested:
		return
	
	scene_change_requested = true
	
	# Double safety check
	if not is_inside_tree():
		push_warning("Button pressed but node not in tree")
		return
	
	# Get tree reference safely
	var current_tree := get_tree()
	if not current_tree:
		push_warning("Could not get scene tree reference")
		return
	
	# Queue the scene change to happen safely
	call_deferred("_safe_change_scene")

func _safe_change_scene():
	# Final verification before changing scene
	if not is_inside_tree():
		push_warning("Node left tree before scene change could complete")
		return
	
	var current_tree := get_tree()
	if current_tree:
		current_tree.change_scene_to_file("res://UI/scenes/5-loading_sec.tscn")
	else:
		push_error("Failed to change scene - no valid tree reference")
	
	scene_change_requested = false
