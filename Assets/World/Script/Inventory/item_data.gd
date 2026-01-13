extends Resource
class_name ItemData

@export var item_id: String = ""           # Unique identifier like "ak47"
@export var item_name: String = ""         # Display name like "AK-47 Rifle"
@export var icon: Texture2D                # Picture of the item
@export var size: Vector2i = Vector2i(1,1) # How many cells it takes (width, height)
@export var max_stack: int = 1             # Can you stack it? (1 = no stacking)
@export var can_rotate: bool = true        # Can you rotate it with right-click?
