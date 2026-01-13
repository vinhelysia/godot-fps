extends Resource
class_name BodyPart

enum PartType {
	HEAD,
	THORAX,
	STOMACH,
	LEFT_ARM,
	RIGHT_ARM,
	LEFT_LEG,
	RIGHT_LEG
}

@export var part_type: PartType
@export var part_name: String = ""
@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var is_critical: bool = false  # Head and Thorax are critical

signal health_changed(part: BodyPart, new_health: float, max_health: float)
signal part_destroyed(part: BodyPart)

func _init(type: PartType = PartType.HEAD):
	part_type = type
	_setup_part_stats()

func _setup_part_stats() -> void:
	match part_type:
		PartType.HEAD:
			part_name = "Head"
			max_health = 35.0
			is_critical = true
		PartType.THORAX:
			part_name = "Thorax"
			max_health = 85.0
			is_critical = true
		PartType.STOMACH:
			part_name = "Stomach"
			max_health = 70.0
			is_critical = false
		PartType.LEFT_ARM:
			part_name = "Left Arm"
			max_health = 60.0
			is_critical = false
		PartType.RIGHT_ARM:
			part_name = "Right Arm"
			max_health = 60.0
			is_critical = false
		PartType.LEFT_LEG:
			part_name = "Left Leg"
			max_health = 65.0
			is_critical = false
		PartType.RIGHT_LEG:
			part_name = "Right Leg"
			max_health = 65.0
			is_critical = false
	
	current_health = max_health

func take_damage(amount: float) -> void:
	var old_health = current_health
	current_health = max(0.0, current_health - amount)
	
	health_changed.emit(self, current_health, max_health)
	
	if current_health <= 0.0 and old_health > 0.0:
		part_destroyed.emit(self)

func heal(amount: float) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(self, current_health, max_health)

func get_health_percentage() -> float:
	return (current_health / max_health) * 100.0

func is_destroyed() -> bool:
	return current_health <= 0.0

func get_health_state() -> String:
	var percent = get_health_percentage()
	if percent >= 75.0:
		return "Healthy"
	if percent >= 50.0:
		return "Damaged"
	if percent >= 25.0:
		return "Badly Damaged"
	if percent > 0.0:
		return "Critical"
	return "Destroyed"

func get_health_color() -> Color:
	var percent = get_health_percentage()
	if percent >= 75.0:
		return Color(0.0, 1.0, 0.0)  # Green
	if percent >= 50.0:
		return Color(1.0, 1.0, 0.0)  # Yellow
	if percent >= 25.0:
		return Color(1.0, 0.6, 0.0)  # Orange
	if percent > 0.0:
		return Color(1.0, 0.0, 0.0)  # Red
	return Color(0.3, 0.0, 0.0)  # Dark Red/Black
