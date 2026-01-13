extends CharacterBody3D
class_name FPSController

#region Movement Configuration
@export_group("Movement")
@export var walk_speed: float = 2.0
@export var sprint_speed: float = 5.0
@export var jump_velocity: float = 4.0
@export var acceleration: float = 10.0
@export var deceleration: float = 12.0
@export_range(0.0, 1.0) var air_control: float = 0.3

@export_group("Camera")
@export var mouse_sensitivity: float = 0.003
@export var camera_pitch_limit: float = 1.5
#endregion

#region Stamina Configuration
@export_group("Stamina")
@export var max_stamina: float = 150.0
@export var stamina_drain_rate: float = 15.0
@export var stamina_regen_rate: float = 10.0
@export var stamina_regen_delay: float = 1.0
@export var stamina_min_to_sprint: float = 10.0
@export var stamina_jump_cost: float = 15.0
#endregion

#region Headbob Configuration
@export_group("Headbob")
@export var bob_frequency_walk: float = 2.0
@export var bob_frequency_sprint: float = 2.8
@export var bob_amplitude_walk: float = 0.05
@export var bob_amplitude_sprint: float = 0.1
@export var headbob_smoothing: float = 5.0
#endregion

#region State Variables
var current_speed: float = 0.0
var stamina: float = max_stamina
var stamina_regen_timer: float = 0.0
var is_exhausted: bool = false
var headbob_time: float = 0.0

#endregion

#region Constants
const MOVEMENT_THRESHOLD: float = 0.1
const COLOR_STAMINA_NORMAL: Color = Color(0.95, 0.8, 0.2, 1.0)
const COLOR_STAMINA_EXHAUSTED: Color = Color(0.9, 0.2, 0.2, 1.0)
#endregion

#region Node References
@onready var camera_pivot: Node3D = $Head
@onready var camera_3d: Camera3D = $Head/Camera3D
@onready var stamina_bar: ProgressBar = $CanvasLayer/StaminaBar

var inventory_layer: CanvasLayer
var inventory_ui: Control
var is_inventory_open: bool = false

# Health System
var health_system: HealthSystem
var health_ui: HealthUI
#endregion

#region Initialization
func _ready() -> void:
	_initialize_stamina_bar()
	_initialize_health_system()
	_initialize_inventory()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _initialize_stamina_bar() -> void:
	if stamina_bar:
		stamina_bar.max_value = max_stamina
		stamina_bar.value = stamina

func _initialize_health_system() -> void:
	# Create health system
	health_system = HealthSystem.new()
	add_child(health_system)
	
	# Create health UI
	var health_ui_class = load("res://Assets/World/Script/Health/health_ui.gd")
	health_ui = health_ui_class.new()
	health_ui.health_system = health_system
	health_ui.name = "HealthUI"
	
	# Add to CanvasLayer FIRST
	$CanvasLayer.add_child(health_ui)
	
	# Position at bottom-left using deferred call (after UI is ready)
	call_deferred("_position_health_ui")
	
	# Connect death signal
	health_system.player_died.connect(_on_player_died)
	
	print("Health System initialized")

func _position_health_ui() -> void:
	if not health_ui:
		return
	
	# Position at TOP-LEFT corner
	health_ui.position = Vector2(20, 20)
	health_ui.size = Vector2(160, 220)
	
	# Force visibility
	health_ui.visible = true
	health_ui.show()
	
	print("Health UI positioned at: ", health_ui.position)

func _on_player_died() -> void:
	print("Player has died!")
	# Disable movement
	set_physics_process(false)
	# You can add death screen, respawn logic, etc. later

func _initialize_inventory() -> void:
	# Create a CanvasLayer for UI
	inventory_layer = CanvasLayer.new()
	add_child(inventory_layer)
	
	# Instantiate the inventory UI
	var InventoryUIClass = load("res://Assets/World/Script/Inventory/inventory_ui.gd")
	inventory_ui = InventoryUIClass.new()
	
	# Set bigger cell size (64px instead of 32px)
	inventory_ui.cell_size = 64
	
	inventory_layer.add_child(inventory_ui)
	inventory_layer.visible = false
	
	# Center it AFTER adding to tree so we know viewport size
	call_deferred("_center_inventory")

func _center_inventory() -> void:
	if not inventory_ui:
		return
	
	# Get the actual size of the inventory UI
	var inventory_size = inventory_ui.size
	
	# Get viewport (screen) size
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Calculate center position
	var center_pos = (viewport_size - inventory_size) / 2.0
	
	inventory_ui.position = center_pos
	
	print("Viewport size: ", viewport_size)
	print("Inventory size: ", inventory_size)
	print("Centered at: ", center_pos)

#region Input Handling
func _input(event: InputEvent) -> void:
	# Handle inventory toggle
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		_toggle_inventory()
		return

	# If inventory is open, mouse should be visible and not control camera
	if is_inventory_open:
		# Maybe allow closing with other keys?
		return
	
	# TEST: Press number keys to damage body parts (for testing)
	if event is InputEventKey and event.pressed and health_system:
		_handle_health_test_input(event.keycode)

	# Handle mouse look
	if event is InputEventMouseMotion:
		_handle_mouse_look(event)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event is InputEventMouseButton and event.pressed:
		if not is_inventory_open:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _handle_health_test_input(keycode: int) -> void:
	match keycode:
		KEY_1:
			health_system.damage_part(BodyPart.PartType.HEAD, 10)
			print("Damaged HEAD - 10 damage")
		KEY_2:
			health_system.damage_part(BodyPart.PartType.THORAX, 15)
			print("Damaged THORAX - 15 damage")
		KEY_3:
			health_system.damage_part(BodyPart.PartType.STOMACH, 10)
			print("Damaged STOMACH - 10 damage")
		KEY_4:
			health_system.damage_part(BodyPart.PartType.LEFT_ARM, 10)
			print("Damaged LEFT ARM - 10 damage")
		KEY_5:
			health_system.damage_part(BodyPart.PartType.RIGHT_ARM, 10)
			print("Damaged RIGHT ARM - 10 damage")
		KEY_6:
			health_system.damage_part(BodyPart.PartType.LEFT_LEG, 10)
			print("Damaged LEFT LEG - 10 damage")
		KEY_7:
			health_system.damage_part(BodyPart.PartType.RIGHT_LEG, 10)
			print("Damaged RIGHT LEG - 10 damage")
		KEY_0:
			health_system.reset_health()
			set_physics_process(true)  # Re-enable movement
			print("Health RESET")

func _toggle_inventory() -> void:
	is_inventory_open = !is_inventory_open
	if inventory_layer:
		inventory_layer.visible = is_inventory_open
	
	if is_inventory_open:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)



func _handle_mouse_look(event: InputEventMouseMotion) -> void:
	rotate_y(-event.relative.x * mouse_sensitivity)
	camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -camera_pitch_limit, camera_pitch_limit)
#endregion

#region Physics Process
func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	
	var input_direction := _get_input_direction()
	var movement_direction := _calculate_movement_direction(input_direction)
	var is_moving := movement_direction.length() > MOVEMENT_THRESHOLD
	
	_handle_jump()
	
	var is_sprinting := _can_sprint(input_direction, is_moving)
	_update_stamina(delta, is_sprinting)
	_update_speed(is_sprinting)
	
	_apply_movement(movement_direction, delta)
	_apply_headbob(delta, is_moving)
	_update_ui()
	
	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
#endregion

#region Movement
func _get_input_direction() -> Vector2:
	return Input.get_vector("left", "right", "forward", "backward")

func _calculate_movement_direction(input_dir: Vector2) -> Vector3:
	return (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

func _update_speed(is_sprinting: bool) -> void:
	current_speed = sprint_speed if is_sprinting else walk_speed

func _apply_movement(direction: Vector3, delta: float) -> void:
	if is_on_floor():
		_apply_ground_movement(direction, delta)
	else:
		_apply_air_movement(direction, delta)

func _apply_ground_movement(direction: Vector3, delta: float) -> void:
	var is_moving := direction.length() > MOVEMENT_THRESHOLD
	var accel := acceleration if is_moving else deceleration
	var target_velocity := direction * current_speed if is_moving else Vector3.ZERO
	
	velocity.x = move_toward(velocity.x, target_velocity.x, accel * delta * current_speed)
	velocity.z = move_toward(velocity.z, target_velocity.z, accel * delta * current_speed)

func _apply_air_movement(direction: Vector3, delta: float) -> void:
	var air_acceleration := acceleration * air_control * delta
	var target_change := direction * current_speed * air_control
	
	velocity.x = move_toward(velocity.x, velocity.x + target_change.x, air_acceleration)
	velocity.z = move_toward(velocity.z, velocity.z + target_change.z, air_acceleration)
#endregion

#region Jump System
func _handle_jump() -> void:
	if not Input.is_action_just_pressed("ui_accept"):
		return
	if not is_on_floor():
		return
	if stamina < stamina_jump_cost or is_exhausted:
		return
	
	velocity.y = jump_velocity
	_consume_stamina(stamina_jump_cost)

func _consume_stamina(amount: float) -> void:
	stamina = max(0.0, stamina - amount)
	stamina_regen_timer = stamina_regen_delay
	
	if stamina <= 0.0:
		is_exhausted = true
#endregion

#region Stamina System
func _can_sprint(input_dir: Vector2, is_moving: bool) -> bool:
	var wants_to_sprint := Input.is_action_pressed("sprint") and input_dir.y < 0
	return wants_to_sprint and is_moving and stamina > 0 and not is_exhausted

func _update_stamina(delta: float, is_sprinting: bool) -> void:
	if is_sprinting:
		_drain_stamina(delta)
	else:
		_regenerate_stamina(delta)

func _drain_stamina(delta: float) -> void:
	stamina = max(0.0, stamina - stamina_drain_rate * delta)
	stamina_regen_timer = stamina_regen_delay
	
	if stamina <= 0.0:
		is_exhausted = true

func _regenerate_stamina(delta: float) -> void:
	# Mark as exhausted if below minimum threshold
	if stamina < stamina_min_to_sprint and not is_exhausted:
		is_exhausted = true
	
	# Regenerate after delay
	stamina_regen_timer -= delta
	if stamina_regen_timer <= 0.0:
		stamina = min(max_stamina, stamina + stamina_regen_rate * delta)
	
	# Clear exhaustion when stamina recovers
	if is_exhausted and stamina >= stamina_min_to_sprint:
		is_exhausted = false
#endregion

#region Headbob
func _apply_headbob(delta: float, is_moving: bool) -> void:
	if is_on_floor() and is_moving:
		_apply_active_headbob(delta)
	else:
		_reset_headbob(delta)

func _apply_active_headbob(delta: float) -> void:
	var is_sprinting := current_speed == sprint_speed
	var frequency := bob_frequency_sprint if is_sprinting else bob_frequency_walk
	var amplitude := bob_amplitude_sprint if is_sprinting else bob_amplitude_walk
	
	headbob_time += delta * velocity.length()
	camera_pivot.transform.origin = _calculate_headbob_offset(headbob_time, frequency, amplitude)

func _reset_headbob(delta: float) -> void:
	camera_pivot.transform.origin = camera_pivot.transform.origin.lerp(
		Vector3.ZERO, 
		delta * headbob_smoothing
	)

func _calculate_headbob_offset(time: float, frequency: float, amplitude: float) -> Vector3:
	return Vector3(
		cos(time * frequency * 0.5) * amplitude * 0.5,
		sin(time * frequency) * amplitude,
		0.0
	)
#endregion

#region UI Updates
func _update_ui() -> void:
	_update_stamina_bar()


func _update_stamina_bar() -> void:
	if not stamina_bar:
		return
	
	stamina_bar.value = stamina
	_update_stamina_bar_color()

func _update_stamina_bar_color() -> void:
	var fill_style := stamina_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if not fill_style:
		return
	
	var target_color := COLOR_STAMINA_EXHAUSTED if is_exhausted else COLOR_STAMINA_NORMAL
	if fill_style.bg_color != target_color:
		fill_style.bg_color = target_color
#endregion	