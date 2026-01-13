extends Control
class_name DraggableItem

var inventory_item: InventoryItem
var inventory_grid: InventoryGrid
var cell_size: int = 32
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

func setup(item: InventoryItem, grid: InventoryGrid, cell_size_px: int):
	inventory_item = item
	inventory_grid = grid
	cell_size = cell_size_px
	
	# Set visual size
	var item_size = item.get_size()
	custom_minimum_size = Vector2(item_size * cell_size)
	self.size = custom_minimum_size
	
	# Create visual
	var texture_rect = TextureRect.new()
	if item.data.icon:
		texture_rect.texture = item.data.icon
	else:
		# Fallback visual
		var img = Image.create(int(self.size.x), int(self.size.y), false, Image.FORMAT_RGBA8)
		img.fill(Color.GRAY)
		texture_rect.texture = ImageTexture.create_from_image(img)
		
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.position = Vector2.ZERO
	texture_rect.size = self.size
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(texture_rect)

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_offset = get_local_mouse_position()
				move_to_front()
			else:
				is_dragging = false
				_try_place_at_mouse()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_rotate_item()

func _rotate_item() -> void:
	if is_dragging:
		return
	if not inventory_item.data.can_rotate:
		return
	
	var old_pos = inventory_item.position
	inventory_grid.items.erase(inventory_item)
	inventory_item.rotate()
	
	if inventory_grid.can_place_item(inventory_item, old_pos):
		inventory_grid.items.append(inventory_item)
		_update_visual()
	else:
		inventory_item.rotate()
		inventory_grid.items.append(inventory_item)

func _update_visual() -> void:
	var item_size = inventory_item.get_size()
	custom_minimum_size = Vector2(item_size * cell_size)
	self.size = custom_minimum_size
	for child in get_children():
		if child is TextureRect:
			child.size = self.size
			break

func _process(_delta):
	if is_dragging:
		# Move with mouse, keeping relative offset
		position = get_parent().get_local_mouse_position() - drag_offset
		
		# Visual feedback
		var grid_pos = _get_grid_position()
		if inventory_grid.can_place_item(inventory_item, grid_pos):
			modulate = Color.GREEN
		else:
			modulate = Color.RED

func _get_grid_position() -> Vector2i:
	# Calculate grid position based on current local position
	# Simple division of top-left is better for grid snapping
	return Vector2i(round(position.x / cell_size), round(position.y / cell_size))

func _try_place_at_mouse():
	var grid_pos = _get_grid_position()
	
	# Snap to grid
	if inventory_grid.can_place_item(inventory_item, grid_pos):
		inventory_item.position = grid_pos
		position = Vector2(grid_pos * cell_size)
		modulate = Color.WHITE
	else:
		# Return to original
		position = Vector2(inventory_item.position * cell_size)
		modulate = Color.WHITE
