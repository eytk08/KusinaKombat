extends Control

const CARD_SIZE = Vector2(280, 280)
const COLUMNS = 4
const ASSETS_PATH = "res://assets/cards/cooking/"

@onready var grid = $ScrollContainer/VBoxContainer/GridContainer

func _ready():
	print("=== Card Display Initialization ===")
	print("Checking directory access...")
	if DirAccess.dir_exists_absolute(ASSETS_PATH):
		print("Directory exists: ", ASSETS_PATH)
	else:
		push_error("Directory does not exist: " + ASSETS_PATH)
	
	if grid:
		print("GridContainer found successfully")
	else:
		push_error("GridContainer not found! Check node path")
	
	load_and_display_cards()

func load_and_display_cards():
	var card_paths = get_all_card_paths()
	
	if card_paths.is_empty():
		push_error("No card images found in directory")
		# Create a test card to verify grid is working
		var test_card = TextureRect.new()
		test_card.custom_minimum_size = CARD_SIZE
		test_card.texture = create_placeholder_texture()
		grid.add_child(test_card)
		return
	
	# Configure grid
	grid.columns = COLUMNS
	grid.set("theme_override_constants/h_separation", 10)
	grid.set("theme_override_constants/v_separation", 10)
	
	# Create cards
	for path in card_paths:
		var card = create_card(path)
		grid.add_child(card)

func get_all_card_paths() -> Array:
	var paths = []
	var dir = DirAccess.open(ASSETS_PATH)
	
	if dir:
		print("\nDirectory contents:")
		dir.list_dir_begin()  # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var file = dir.get_next()
		while file != "":
			print("- ", file)
			if not dir.current_is_dir():
				var ext = file.get_extension().to_lower()
				if ext in ["png", "jpg", "jpeg", "webp"]:
					var full_path = ASSETS_PATH.path_join(file)
					print("  Adding card: ", full_path)
					paths.append(full_path)
			file = dir.get_next()
		print("\nFound ", paths.size(), " valid card images")
	else:
		push_error("Failed to access directory: " + ASSETS_PATH)
		print("Error code: ", DirAccess.get_open_error())
	
	return paths

func create_card(image_path: String) -> TextureRect:
	print("\nCreating card from: ", image_path)
	var card = TextureRect.new()
	card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.custom_minimum_size = CARD_SIZE
	
	var texture = load(image_path)
	if texture:
		print("Texture loaded successfully")
		card.texture = texture
	else:
		push_error("Failed to load texture")
		print("Creating placeholder")
		card.texture = create_placeholder_texture()
		# Add debug label
		var label = Label.new()
		label.text = image_path.get_file()
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(label)
	
	return card

func create_placeholder_texture() -> Texture2D:
	var image = Image.create(CARD_SIZE.x, CARD_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.2, 0.2))
	return ImageTexture.create_from_image(image)
