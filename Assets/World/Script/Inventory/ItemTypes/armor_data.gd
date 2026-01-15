extends ItemData
class_name ArmorData

enum ArmorSlot { HEAD, CHEST, LEGS }

@export var armor_slot: ArmorSlot = ArmorSlot.CHEST
@export var armor_class: int = 3  # 1-6 (like Tarkov)
@export var durability: float = 100.0
@export var max_durability: float = 100.0
@export var movement_penalty: float = 0.0  # Slows movement
@export var model_path: String = ""  # Path to the 3D model .glb file
