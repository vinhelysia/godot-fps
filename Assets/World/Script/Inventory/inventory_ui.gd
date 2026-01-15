extends Control
class_name InventoryUI

@export var inventory_grid: InventoryGrid
@export var cell_size: int = 64  # ✅ CHANGE FROM 32 TO 64

var slots: Array[Panel] = []

func _ready():
	# If no grid provided, create one for testing
	if not inventory_grid:
		inventory_grid = InventoryGrid.new()
	
	_create_grid()
	
	# Run test setup deferred to ensure UI is ready
	call_deferred("test")

func _create_grid():
	var grid_container = GridContainer.new()
	grid_container.columns = inventory_grid.grid_size.x
	grid_container.add_theme_constant_override("h_separation", 0)
	grid_container.add_theme_constant_override("v_separation", 0)
	add_child(grid_container)
	
	for y in range(inventory_grid.grid_size.y):
		for x in range(inventory_grid.grid_size.x):
			var slot = Panel.new()
			slot.custom_minimum_size = Vector2(cell_size, cell_size)  # ✅ Uses 64 now
			
			# Style the slot
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
			style.border_width_left = 1
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1
			style.border_color = Color(0.3, 0.3, 0.3)
			slot.add_theme_stylebox_override("panel", style)
			
			slots.append(slot)
			grid_container.add_child(slot)
	
	# ✅ ADD THIS: Calculate and set the total size of the inventory UI
	var total_size = Vector2(
		inventory_grid.grid_size.x * cell_size,
		inventory_grid.grid_size.y * cell_size
	)
	custom_minimum_size = total_size
	size = total_size
	
	print("Inventory UI size set to: ", size)

func refresh_items():
	# Clear existing DraggableItems
	for child in get_children():
		if child is DraggableItem:
			child.queue_free()
			
	# Create visuals for all items
	for item in inventory_grid.items:
		var draggable = DraggableItem.new()
		draggable.setup(item, inventory_grid, cell_size)
		draggable.position = Vector2(item.position * cell_size)
		add_child(draggable)

func test():
	# Use the database to spawn items instead of manual creation
	var ak47 = ItemDB.create_inventory_item("ak47", Vector2i(0, 0))
	var m4a1 = ItemDB.create_inventory_item("m4a1", Vector2i(0, 3))  # M4 below AK47
	var ammo = ItemDB.create_inventory_item("ammo_762", Vector2i(5, 0))
	var medkit = ItemDB.create_inventory_item("medkit", Vector2i(7, 0))
	
	# Add to grid
	if ak47:
		inventory_grid.add_item(ak47, ak47.position)
	if m4a1:
		inventory_grid.add_item(m4a1, m4a1.position)
	if ammo:
		inventory_grid.add_item(ammo, ammo.position)
	if medkit:
		inventory_grid.add_item(medkit, medkit.position)
	
	refresh_items()
	
	print("Loaded items from database")

