extends TextureButton

signal drag_started
signal drag_ended

var original_position: Vector2
var original_parent: Node
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

func _ready():
	# Ensure button can be interacted with
	toggle_mode = false
	focus_mode = Control.FOCUS_NONE
	
	# Store original layout
	original_position = global_position
	original_parent = get_parent()

func _on_button_down():
	# Start drag on click (not wait for release)
	start_drag()

func _on_button_up():
	if is_dragging:
		end_drag()

func start_drag():
	is_dragging = true
	drag_offset = get_global_mouse_position() - global_position
	original_position = global_position
	
	# Move to canvas layer or root to avoid clipping
	original_parent.remove_child(self)
	get_tree().root.add_child(self)
	
	# Visual feedback
	modulate = Color(1, 1, 1, 0.8)
	z_index = 100
	emit_signal("drag_started")

func end_drag():
	is_dragging = false
	var placeholder = _find_drop_target()
	
	if placeholder and placeholder.can_accept_card(self):
		placeholder.occupy(self)
	else:
		_return_to_original()
	
	# Reset visual state
	modulate = Color.WHITE
	z_index = 0
	emit_signal("drag_ended")

func _process(delta):
	if is_dragging:
		global_position = get_global_mouse_position() - drag_offset

func _find_drop_target() -> UICardPlaceholder:
	var space = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = get_global_mouse_position()
	query.collide_with_areas = true
	
	var result = space.intersect_point(query, 1)
	if result.size() > 0 and result[0].collider is UICardPlaceholder:
		return result[0].collider
	return null

func _return_to_original():
	if get_parent() == get_tree().root:
		get_tree().root.remove_child(self)
		original_parent.add_child(self)
	global_position = original_position
