extends ItemData
class_name MedicalData

@export var heal_amount: float = 50.0
@export var use_time: float = 3.0  # Seconds to use
@export var heals_body_part: bool = true  # Can target specific body part
@export var stops_bleeding: bool = false
@export var removes_fracture: bool = false
@export var model_path: String = ""  # Path to the 3D model .glb file
