extends Node

@export var initial_delay: float = 2
@export var selection_speed: float = 0.2
@export var speed_decrease_rate: float = 0.005
@export var final_selection_delay: float = 0.1
@export var cycles: int = 4

var elements: Array[TextureRect] = []
var current_index: int = 0
var is_selecting: bool = false
var current_speed: float = 0.0
var cycles_completed: int = 0
var target_index: int = 0

func _ready():
	print("Initializing roulette system...")
	
	# Get all direct children of the TextureRect background
	var background = $TextureRect
	if not background:
		printerr("Background TextureRect not found!")
		return
	
	# Find all TextureRect children (elements)
	for child in background.get_children():
		if child is TextureRect:
			elements.append(child)
			print("Found element: ", child.name)
	
	if elements.is_empty():
		printerr("No elements found under background TextureRect!")
		return
	
	_setup_materials()
	get_tree().create_timer(initial_delay).timeout.connect(start_selection_roulette)

func _setup_materials():
	var shader = load("res://UI/glow_shader.gdshader")
	if not shader:
		printerr("Failed to load shader!")
		return
	
	print("Shader loaded successfully")
	
	for element in elements:
		# Create unique material for each element
		var mat = ShaderMaterial.new()
		mat.shader = shader
		element.material = mat
		mat.set_shader_parameter("selected", false)
		print("Applied material to: ", element.name)

func start_selection_roulette():
	if elements.is_empty():
		printerr("Cannot start roulette - no elements available")
		return
	
	print("Starting roulette selection")
	target_index = randi() % elements.size()
	is_selecting = true
	current_index = 0
	current_speed = selection_speed
	cycles_completed = 0
	_next_selection()

func _next_selection():
	if not is_selecting:
		return
	
	# Deselect previous element
	if elements.size() > 0:
		var prev_element = elements[current_index]
		if prev_element.material is ShaderMaterial:
			prev_element.material.set_shader_parameter("selected", false)
	
	# Move to next element
	current_index = (current_index + 1) % elements.size()
	
	# Select current element
	var current_element = elements[current_index]
	if current_element.material is ShaderMaterial:
		current_element.material.set_shader_parameter("selected", true)
	
	# Check for completed cycles
	if current_index == 0:
		cycles_completed += 1
		print("Completed cycle: ", cycles_completed)
	
	# Check stopping condition
	if cycles_completed >= cycles and current_index == target_index:
		stop_roulette_at(target_index)
		return
	
	# Adjust speed (slow down over time)
	current_speed = max(current_speed - speed_decrease_rate, 0.1)
	
	# Calculate delay (slower in final cycles)
	var delay = current_speed
	if cycles_completed >= cycles - 1:
		delay = lerp(current_speed, final_selection_delay, float(cycles_completed) / float(cycles))
	
	get_tree().create_timer(delay).timeout.connect(_next_selection)

func stop_roulette_at(index: int):
	print("Roulette stopped at: ", elements[index].name)
	is_selecting = false
	
	# Deselect all
	for element in elements:
		if element.material is ShaderMaterial:
			element.material.set_shader_parameter("selected", false)
	
	# Select final element
	if index < elements.size():
		var final_element = elements[index]
		if final_element.material is ShaderMaterial:
			final_element.material.set_shader_parameter("selected", true)



	
