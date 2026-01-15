extends ItemData
class_name AmmoData

@export var ammo_type: String = "5.56x45"  # Matches weapon's ammo_type
@export var bullet_count: int = 30  # How many bullets per item
@export var penetration: float = 40.0  # Armor penetration
@export var damage_multiplier: float = 1.0
@export var model_path: String = ""  # Path to the 3D model .glb file
