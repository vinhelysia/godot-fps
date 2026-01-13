extends Node
class_name HealthSystem

signal player_died()
signal critical_part_destroyed(part_name: String)

var body_parts: Dictionary = {}  # PartType -> BodyPart

func _init():
	_create_body_parts()

func _create_body_parts() -> void:
	body_parts[BodyPart.PartType.HEAD] = BodyPart.new(BodyPart.PartType.HEAD)
	body_parts[BodyPart.PartType.THORAX] = BodyPart.new(BodyPart.PartType.THORAX)
	body_parts[BodyPart.PartType.STOMACH] = BodyPart.new(BodyPart.PartType.STOMACH)
	body_parts[BodyPart.PartType.LEFT_ARM] = BodyPart.new(BodyPart.PartType.LEFT_ARM)
	body_parts[BodyPart.PartType.RIGHT_ARM] = BodyPart.new(BodyPart.PartType.RIGHT_ARM)
	body_parts[BodyPart.PartType.LEFT_LEG] = BodyPart.new(BodyPart.PartType.LEFT_LEG)
	body_parts[BodyPart.PartType.RIGHT_LEG] = BodyPart.new(BodyPart.PartType.RIGHT_LEG)
	
	# Connect signals
	for part in body_parts.values():
		part.part_destroyed.connect(_on_part_destroyed)

func damage_part(part_type: BodyPart.PartType, amount: float) -> void:
	if part_type in body_parts:
		body_parts[part_type].take_damage(amount)

func heal_part(part_type: BodyPart.PartType, amount: float) -> void:
	if part_type in body_parts:
		body_parts[part_type].heal(amount)

func get_part(part_type: BodyPart.PartType) -> BodyPart:
	return body_parts.get(part_type)

func get_total_health() -> float:
	var total = 0.0
	for part in body_parts.values():
		total += part.current_health
	return total

func get_max_total_health() -> float:
	var total = 0.0
	for part in body_parts.values():
		total += part.max_health
	return total

func is_alive() -> bool:
	# Player dies if any critical part is destroyed
	for part in body_parts.values():
		if part.is_critical and part.is_destroyed():
			return false
	return true

func _on_part_destroyed(part: BodyPart) -> void:
	print("Body part destroyed: ", part.part_name)
	
	if part.is_critical:
		critical_part_destroyed.emit(part.part_name)
		player_died.emit()

func reset_health() -> void:
	for part in body_parts.values():
		part.current_health = part.max_health
		part.health_changed.emit(part, part.current_health, part.max_health)
