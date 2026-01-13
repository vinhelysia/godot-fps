extends Control
class_name HealthUI

var health_system: HealthSystem

# UI Components
var body_part_displays: Dictionary = {}  # PartType -> {rect, health_label}
var main_panel: Panel

# Layout settings - Body part rectangle sizes
const MARGIN: float = 10.0
const RECT_SPACING: float = 0.5
const HEAD_SIZE: Vector2 = Vector2(32, 32)
const THORAX_SIZE: Vector2 = Vector2(44, 52)
const ARM_SIZE: Vector2 = Vector2(20, 52)
const STOMACH_SIZE: Vector2 = Vector2(44, 36)
const LEG_SIZE: Vector2 = Vector2(20, 56)

func _ready() -> void:
	if not health_system:
		push_error("HealthUI: No health_system assigned!")
		return
	
	_create_ui()
	_connect_signals()
	_update_all_displays()
	
	# Force size and visibility
	custom_minimum_size = Vector2(160, 220)
	size = Vector2(160, 220)
	visible = true
	show()
	
	print("=== HEALTH UI READY ===")
	print("Body figure UI created")

func _create_ui() -> void:
	# Main container (transparent - no background)
	main_panel = Panel.new()
	main_panel.custom_minimum_size = Vector2(160, 220)
	main_panel.size = Vector2(160, 220)
	
	# Make panel fully transparent
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)  # Fully transparent
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	main_panel.add_theme_stylebox_override("panel", style)
	
	add_child(main_panel)
	
	# Calculate center X for body alignment
	var center_x = 80.0  # Panel width / 2
	
	# HEAD (centered at top)
	var head_x = center_x - HEAD_SIZE.x / 2
	_create_part_rect(BodyPart.PartType.HEAD, Vector2(head_x, 10), HEAD_SIZE)
	
	# ARMS + THORAX row (below head)
	var torso_y = 10 + HEAD_SIZE.y + RECT_SPACING
	var thorax_x = center_x - THORAX_SIZE.x / 2
	var left_arm_x = thorax_x - ARM_SIZE.x - RECT_SPACING
	var right_arm_x = thorax_x + THORAX_SIZE.x + RECT_SPACING
	
	_create_part_rect(BodyPart.PartType.LEFT_ARM, Vector2(left_arm_x, torso_y), ARM_SIZE)
	_create_part_rect(BodyPart.PartType.THORAX, Vector2(thorax_x, torso_y), THORAX_SIZE)
	_create_part_rect(BodyPart.PartType.RIGHT_ARM, Vector2(right_arm_x, torso_y), ARM_SIZE)
	
	# STOMACH (centered, below thorax)
	var stomach_y = torso_y + THORAX_SIZE.y + RECT_SPACING
	var stomach_x = center_x - STOMACH_SIZE.x / 2
	_create_part_rect(BodyPart.PartType.STOMACH, Vector2(stomach_x, stomach_y), STOMACH_SIZE)
	
	# LEGS (below stomach)
	var legs_y = stomach_y + STOMACH_SIZE.y + RECT_SPACING
	var left_leg_x = center_x - LEG_SIZE.x - RECT_SPACING / 2
	var right_leg_x = center_x + RECT_SPACING / 2
	
	_create_part_rect(BodyPart.PartType.LEFT_LEG, Vector2(left_leg_x, legs_y), LEG_SIZE)
	_create_part_rect(BodyPart.PartType.RIGHT_LEG, Vector2(right_leg_x, legs_y), LEG_SIZE)

func _create_part_rect(part_type: BodyPart.PartType, pos: Vector2, rect_size: Vector2) -> void:
	var part = health_system.get_part(part_type)
	if not part:
		return
	
	# Create colored rectangle for body part
	var rect = ColorRect.new()
	rect.position = pos
	rect.size = rect_size
	rect.color = part.get_health_color()
	
	# Add border styling via a Panel child
	var border_panel = Panel.new()
	border_panel.position = Vector2.ZERO
	border_panel.size = rect_size
	border_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var border_style = StyleBoxFlat.new()
	border_style.bg_color = Color(0, 0, 0, 0)  # Transparent background
	border_style.border_width_left = 2
	border_style.border_width_top = 2
	border_style.border_width_right = 2
	border_style.border_width_bottom = 2
	border_style.border_color = Color(0.2, 0.2, 0.25)
	border_style.corner_radius_top_left = 3
	border_style.corner_radius_top_right = 3
	border_style.corner_radius_bottom_left = 3
	border_style.corner_radius_bottom_right = 3
	border_panel.add_theme_stylebox_override("panel", border_style)
	rect.add_child(border_panel)
	main_panel.add_child(rect)
	
	# Store reference for updates
	body_part_displays[part_type] = {
		"rect": rect
	}

func _connect_signals() -> void:
	for part in health_system.body_parts.values():
		part.health_changed.connect(_on_part_health_changed)
	
	health_system.player_died.connect(_on_player_died)

func _on_part_health_changed(part: BodyPart, _new_health: float, _m_health: float) -> void:
	_update_part_display(part.part_type)

func _update_part_display(part_type: BodyPart.PartType) -> void:
	if not part_type in body_part_displays:
		return
	
	var part = health_system.get_part(part_type)
	var display = body_part_displays[part_type]
	
	# Update rectangle color based on health
	display.rect.color = part.get_health_color()

func _update_all_displays() -> void:
	for part_type in body_part_displays.keys():
		_update_part_display(part_type)

func _on_player_died() -> void:
	print("=== PLAYER DIED ===")
