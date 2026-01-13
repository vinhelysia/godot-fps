extends Control
class_name HealthUI

var health_system: HealthSystem

# UI Components
var body_part_displays: Dictionary = {}  # PartType -> Display data
var main_panel: Panel

# Layout settings
const MARGIN: float = 20.0
const PART_WIDTH: float = 70.0
const PART_HEIGHT: float = 55.0
const BAR_HEIGHT: float = 12.0
const SPACING: float = 8.0

func _ready() -> void:
	if not health_system:
		push_error("HealthUI: No health_system assigned!")
		return
	
	_create_ui()
	_connect_signals()
	_update_all_displays()
	
	# Force size and visibility
	custom_minimum_size = Vector2(260, 320)
	size = Vector2(260, 320)
	visible = true
	show()
	
	print("=== HEALTH UI READY ===")
	print("Children: ", get_child_count())
	print("Panel exists: ", main_panel != null)

func _create_ui() -> void:
	# Main panel container
	main_panel = Panel.new()
	main_panel.custom_minimum_size = Vector2(260, 320)
	main_panel.size = Vector2(260, 320)  # Force size
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.45, 0.5)  # Brighter border
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	main_panel.add_theme_stylebox_override("panel", style)
	
	add_child(main_panel)
	
	# Title label
	var title = Label.new()
	title.text = "HEALTH STATUS"
	title.position = Vector2(MARGIN, 10)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	main_panel.add_child(title)
	
	# Create body part displays in Tarkov-style layout
	var y_offset = 40.0
	
	# HEAD (center top)
	_create_part_display(BodyPart.PartType.HEAD, Vector2(95, y_offset), main_panel)
	y_offset += PART_HEIGHT + SPACING
	
	# ARMS + THORAX (row)
	var arm_y = y_offset
	_create_part_display(BodyPart.PartType.LEFT_ARM, Vector2(15, arm_y), main_panel)
	_create_part_display(BodyPart.PartType.THORAX, Vector2(95, arm_y), main_panel)
	_create_part_display(BodyPart.PartType.RIGHT_ARM, Vector2(175, arm_y), main_panel)
	y_offset += PART_HEIGHT + SPACING
	
	# STOMACH (center)
	_create_part_display(BodyPart.PartType.STOMACH, Vector2(95, y_offset), main_panel)
	y_offset += PART_HEIGHT + SPACING
	
	# LEGS (row)
	_create_part_display(BodyPart.PartType.LEFT_LEG, Vector2(55, y_offset), main_panel)
	_create_part_display(BodyPart.PartType.RIGHT_LEG, Vector2(135, y_offset), main_panel)

func _create_part_display(part_type: BodyPart.PartType, pos: Vector2, parent: Control) -> void:
	var part = health_system.get_part(part_type)
	if not part:
		return
	
	var container = VBoxContainer.new()
	container.position = pos
	container.custom_minimum_size = Vector2(PART_WIDTH, PART_HEIGHT)
	container.add_theme_constant_override("separation", 2)
	
	# Part name label
	var label = Label.new()
	label.text = part.part_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	label.custom_minimum_size.x = PART_WIDTH
	container.add_child(label)
	
	# Health numbers label
	var health_label = Label.new()
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.add_theme_font_size_override("font_size", 11)
	health_label.custom_minimum_size.x = PART_WIDTH
	container.add_child(health_label)
	
	# Progress bar for health
	var progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(PART_WIDTH, BAR_HEIGHT)
	progress_bar.max_value = part.max_health
	progress_bar.value = part.current_health
	progress_bar.show_percentage = false
	
	# Style the progress bar background
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.18)
	bg_style.corner_radius_top_left = 2
	bg_style.corner_radius_top_right = 2
	bg_style.corner_radius_bottom_left = 2
	bg_style.corner_radius_bottom_right = 2
	progress_bar.add_theme_stylebox_override("background", bg_style)
	
	container.add_child(progress_bar)
	parent.add_child(container)
	
	# Store reference for updates
	body_part_displays[part_type] = {
		"container": container,
		"label": label,
		"health_label": health_label,
		"progress_bar": progress_bar
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
	
	# Update health text
	display.health_label.text = "%d/%d" % [int(part.current_health), int(part.max_health)]
	
	# Update progress bar value
	display.progress_bar.value = part.current_health
	
	# Get health color
	var color = part.get_health_color()
	
	# Update progress bar fill color
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = color
	fill_style.corner_radius_top_left = 2
	fill_style.corner_radius_top_right = 2
	fill_style.corner_radius_bottom_left = 2
	fill_style.corner_radius_bottom_right = 2
	display.progress_bar.add_theme_stylebox_override("fill", fill_style)
	
	# Update health label color
	display.health_label.add_theme_color_override("font_color", color)

func _update_all_displays() -> void:
	for part_type in body_part_displays.keys():
		_update_part_display(part_type)

func _on_player_died() -> void:
	print("=== PLAYER DIED ===")
	# Can add death screen effects here later
