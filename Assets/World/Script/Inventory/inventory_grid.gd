extends Resource
class_name InventoryGrid

@export var grid_size: Vector2i = Vector2i(10, 8)  # 10 columns, 8 rows
var items: Array[InventoryItem] = []               # All items currently in inventory

# CHECK: Can we place this item at this position?
func can_place_item(item: InventoryItem, pos: Vector2i) -> bool:
	var item_size := item.get_size()
	
	# CHECK 1: Is it inside the grid boundaries?
	if pos.x < 0 or pos.y < 0:
		return false
	if pos.x + item_size.x > grid_size.x:  # Goes off right edge?
		return false
	if pos.y + item_size.y > grid_size.y:  # Goes off bottom edge?
		return false
	
	# CHECK 2: Does it overlap any existing items?
	for existing_item in items:
		if existing_item == item:  # Skip the item we're moving
			continue
		if _rectangles_overlap(pos, item_size, existing_item.position, existing_item.get_size()):
			return false
	
	return true  # All checks passed!

# ADD: Put item in inventory at position
func add_item(item: InventoryItem, pos: Vector2i) -> bool:
	if not can_place_item(item, pos):
		return false
	
	item.position = pos
	items.append(item)
	return true

# HELPER: Do two rectangles overlap?
func _rectangles_overlap(pos1: Vector2i, size1: Vector2i, pos2: Vector2i, size2: Vector2i) -> bool:
	# Rectangle 1: from pos1 to (pos1 + size1)
	# Rectangle 2: from pos2 to (pos2 + size2)
	# They DON'T overlap if one is completely to the side of the other
	
	var no_overlap = (pos1.x + size1.x <= pos2.x or   # Rect1 is left of Rect2
					  pos2.x + size2.x <= pos1.x or   # Rect1 is right of Rect2
					  pos1.y + size1.y <= pos2.y or   # Rect1 is above Rect2
					  pos2.y + size2.y <= pos1.y)     # Rect1 is below Rect2
	
	return not no_overlap  # If they DON'T not-overlap, they overlap
