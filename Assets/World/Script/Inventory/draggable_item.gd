extends Control
class_name DraggableItem

var inventory_item: InventoryItem
var inventory_grid: InventoryGrid
var cell_size: int = 32
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

var background_panel: Panel
var texture_rect: TextureRect

func setup(item: InventoryItem, grid: InventoryGrid, cell_size_px: int):
	inventory_item = item
	inventory_grid = grid
	cell_size = cell_size_px
	
	# Create Background (Translucent Gray with Border)
	background_panel = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 0.4)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color.BLACK
	background_panel.add_theme_stylebox_override("panel", style)
	background_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background_panel)
	
	# Create Icon
	texture_rect = TextureRect.new()
	if item.data.icon:
		texture_rect.texture = item.data.icon
	else:
		var img = Image.create(cell_size, cell_size, false, Image.FORMAT_RGBA8)
		img.fill(Color.GRAY)
		texture_rect.texture = ImageTexture.create_from_image(img)
		
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(texture_rect)
	
	_update_visual()

# ✅ HANDLE MOUSE INPUT (Drag & Context Menu)
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
		
		# Right Click - Context Menu
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_show_context_menu()

func _show_context_menu():
	var popup = PopupMenu.new()
	popup.add_item("Equip", 1)
	popup.add_item("Drop", 2)
	
	# Disable 'Equip' if not a weapon
	if not (inventory_item.data is WeaponData):
		popup.set_item_disabled(0, true)
	
	popup.id_pressed.connect(_on_context_menu_item_selected)
	add_child(popup)
	
	# Show at mouse position
	popup.position = Vector2(get_viewport().get_mouse_position())
	popup.popup()

func _on_context_menu_item_selected(id: int):
	match id:
		1: # Equip
			_equip_item()
		2: # Drop
			_drop_item()

func _equip_item():
	if inventory_item.data is WeaponData:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.equip_weapon(inventory_item)
		else:
			print("Error: Player node not found in group 'player'")

func _drop_item():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.drop_inventory_item(inventory_item)
	else:
		print("Error: Player node not found - cannot drop item")

# ✅ HANDLE R KEY FOR ROTATION
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_rotate_item_during_drag()
		get_viewport().set_input_as_handled()

# ✅ NEW ROTATION FUNCTION (allows rotation while dragging)
func _rotate_item_during_drag() -> void:
	if not inventory_item.data.can_rotate:
		print("Item cannot be rotated")
		return
	
	print("Rotating item - Before: ", inventory_item.get_size())
	inventory_item.rotate()
	print("After rotation: ", inventory_item.get_size())
	
	# Update visual immediately
	_update_visual()
	
	# If not dragging, check if it fits at current position
	if not is_dragging:
		var current_pos = inventory_item.position
		inventory_grid.items.erase(inventory_item)
		
		if inventory_grid.can_place_item(inventory_item, current_pos):
			inventory_grid.items.append(inventory_item)
		else:
			inventory_item.rotate()  # Rotate back
			_update_visual()
			inventory_grid.items.append(inventory_item)
			print("Cannot rotate - would overlap or go out of bounds")

func _update_visual() -> void:
	var item_size_slots = inventory_item.get_size()
	var pixel_size = Vector2(item_size_slots * cell_size)
	
	# 1. Update Container Size
	custom_minimum_size = pixel_size
	size = pixel_size
	
	# 2. Update Background
	if background_panel:
		background_panel.size = pixel_size
		
	# 3. Update Icon Rotation
	if texture_rect:
		if inventory_item.is_rotated:
			# If rotated, we show the unrotated texture rotated 90 degrees
			var original_slots = inventory_item.data.size
			var original_pixel_size = Vector2(original_slots * cell_size)
			
			texture_rect.size = original_pixel_size
			texture_rect.rotation_degrees = 90
			# Shift X by height (which corresponds to unrotated texture's height)
			texture_rect.position = Vector2(original_pixel_size.y, 0)
			
		else:
			texture_rect.rotation_degrees = 0
			texture_rect.size = pixel_size
			texture_rect.position = Vector2.ZERO

func _process(_delta):
	if is_dragging:
		position = get_parent().get_local_mouse_position() - drag_offset
		
		# Visual feedback (automatically uses rotated size)
		var grid_pos = _get_grid_position()
		if inventory_grid.can_place_item(inventory_item, grid_pos):
			modulate = Color.GREEN
		else:
			modulate = Color.RED

func _get_grid_position() -> Vector2i:
	return Vector2i(round(position.x / cell_size), round(position.y / cell_size))

func _try_place_at_mouse():
	var grid_pos = _get_grid_position()
	
	if inventory_grid.can_place_item(inventory_item, grid_pos):
		inventory_item.position = grid_pos
		position = Vector2(grid_pos * cell_size)
		modulate = Color.WHITE
	else:
		position = Vector2(inventory_item.position * cell_size)
		modulate = Color.WHITE
