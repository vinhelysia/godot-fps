extends Object
class_name InventoryItem

var data: ItemData              # What kind of item is this?
var position: Vector2i          # Where in grid? (x, y coordinates)
var is_rotated: bool = false    # Is it rotated 90 degrees?
var stack_count: int = 1        # How many in this stack?

func _init(item_data: ItemData, pos: Vector2i = Vector2i.ZERO):
	data = item_data
	position = pos
	stack_count = 1

# When rotated, swap width/height
func get_size() -> Vector2i:
	if is_rotated and data.can_rotate:
		return Vector2i(data.size.y, data.size.x)  # Swap X and Y
	return data.size

func rotate() -> void:
	if data.can_rotate:
		is_rotated = !is_rotated
