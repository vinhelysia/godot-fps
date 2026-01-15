extends CharacterBody3D
class_name FPSController

#region Configuration
@export var config: PlayerConfig

# Fallback default config if none assigned
var _default_config: PlayerConfig

func _get_config() -> PlayerConfig:
	return config if config else _default_config
#endregion

#region State Variables
var current_speed: float = 0.0
var stamina: float = 0.0
var stamina_regen_timer: float = 0.0
var is_exhausted: bool = false
var headbob_time: float = 0.0

# Input buffering for better game feel
var coyote_counter: float = 0.0
var jump_buffer_counter: float = 0.0

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
	# Create default config if none assigned
	if not config:
		_default_config = PlayerConfig.new()
	
	# Initialize stamina to max
	stamina = _get_config().max_stamina
	
	_initialize_stamina_bar()
	_initialize_health_system()
	_initialize_inventory()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player") # ✅ Register for easy access

	_initialize_hand_socket()

func _initialize_stamina_bar() -> void:
	if stamina_bar:
		stamina_bar.max_value = _get_config().max_stamina
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

func _initialize_hand_socket() -> void:
	# Create a hand socket attached to the camera for FPS view
	if not hand_socket:
		hand_socket = Node3D.new()
		hand_socket.name = "HandSocket"
		camera_3d.add_child(hand_socket)
		# Position it slightly forward and to the right
		hand_socket.position = Vector3(0.5, -0.5, -0.7)
		print("HandSocket initialized")

#region Equipment
var equipped_weapon: InventoryItem = null
var current_weapon_instance: Node3D = null
var hand_socket: Node3D = null

func equip_weapon(item: InventoryItem) -> void:
	if equipped_weapon == item:
		return
		
	# Unequip current if any
	if equipped_weapon:
		unequip_weapon()
	
	equipped_weapon = item
	print("Equipping weapon: ", item.data.item_id)
	
	# Spawn 3D model
	if item.data.model_path and item.data.model_path != "":
		var model_scene = load(item.data.model_path)
		if model_scene:
			current_weapon_instance = model_scene.instantiate()
			hand_socket.add_child(current_weapon_instance)
			
			# Reset transform to ensure it aligns with socket
			current_weapon_instance.transform = Transform3D.IDENTITY
			# Rotate 180 degrees if the model is facing backwards (common with GLTF)
			current_weapon_instance.rotation_degrees.y = 90
			print("Weapon model spawned")
	
	# TODO: Play Equip Animation
	print("PLAY ANIMATION: Equip")

func unequip_weapon() -> void:
	if not equipped_weapon:
		return
		
	print("Unequipping: ", equipped_weapon.data.item_id)
	
	# Despawn model
	if current_weapon_instance:
		current_weapon_instance.queue_free()
		current_weapon_instance = null
	
	equipped_weapon = null
	
	# TODO: Play Unequip Animation
	print("PLAY ANIMATION: Unequip")

func drop_inventory_item(item: InventoryItem) -> void:
	print("Dropping item: ", item.data.item_id)
	
	# If equipped, unequip first
	if equipped_weapon == item:
		unequip_weapon()
	
	# Remove from inventory grid
	if inventory_ui and inventory_ui.inventory_grid:
		inventory_ui.inventory_grid.items.erase(item)
		inventory_ui.refresh_items()
	
	# Spawn pickup in world
	_spawn_pickup(item)

func _spawn_pickup(item: InventoryItem) -> void:
	var model_path = item.data.model_path
	if not model_path or model_path == "":
		# Fallback or just don't spawn visual (logic is handled)
		print("No model path for drop, skipping visual spawn")
		return
		
	var pickup_scene = load(model_path)
	if pickup_scene:
		var pickup_instance = pickup_scene.instantiate()
		get_parent().add_child(pickup_instance) # Add to world, not player
		
		# Position in front of player
		var spawn_pos = global_transform.origin - global_transform.basis.z * 1.5
		spawn_pos.y += 1.0 # Drop slightly above ground
		pickup_instance.global_transform.origin = spawn_pos
		
		print("Spawned pickup at: ", spawn_pos)
#endregion

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
	var cfg = _get_config()
	rotate_y(-event.relative.x * cfg.mouse_sensitivity)
	camera_pivot.rotate_x(-event.relative.y * cfg.mouse_sensitivity)
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -1.5, 1.5)
#endregion

#region Physics Process
func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	
	# Disable movement controls when inventory is open
	if is_inventory_open:
		# Still allow deceleration so player slows down naturally
		if is_on_floor():
			var cfg = _get_config()
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta * cfg.walk_speed)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta * cfg.walk_speed)
		_update_ui()
		move_and_slide()
		return
	
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
	var cfg = _get_config()
	current_speed = cfg.sprint_speed if is_sprinting else cfg.walk_speed

func _apply_movement(direction: Vector3, delta: float) -> void:
	if is_on_floor():
		_apply_ground_movement(direction, delta)
	else:
		_apply_air_movement(direction, delta)

func _apply_ground_movement(direction: Vector3, delta: float) -> void:
	var is_moving := direction.length() > MOVEMENT_THRESHOLD
	var accel := 10.0 if is_moving else 12.0  # acceleration/deceleration
	var target_velocity := direction * current_speed if is_moving else Vector3.ZERO
	
	velocity.x = move_toward(velocity.x, target_velocity.x, accel * delta * current_speed)
	velocity.z = move_toward(velocity.z, target_velocity.z, accel * delta * current_speed)

func _apply_air_movement(direction: Vector3, delta: float) -> void:
	var air_control := 0.3
	var air_acceleration := 10.0 * air_control * delta
	var target_change := direction * current_speed * air_control
	
	velocity.x = move_toward(velocity.x, velocity.x + target_change.x, air_acceleration)
	velocity.z = move_toward(velocity.z, velocity.z + target_change.z, air_acceleration)
#endregion

#region Jump System
func _handle_jump() -> void:
	var cfg = _get_config()
	var was_on_floor = is_on_floor()
	
	# Update coyote time (grace period after leaving ground)
	if was_on_floor:
		coyote_counter = cfg.coyote_time
	else:
		coyote_counter -= get_physics_process_delta_time()
	
	# Update jump buffer (remember jump input briefly)
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_counter = cfg.jump_buffer_time
	else:
		jump_buffer_counter -= get_physics_process_delta_time()
	
	# Can jump if recently grounded OR jump was buffered
	if jump_buffer_counter > 0.0 and coyote_counter > 0.0:
		if stamina >= cfg.stamina_jump_cost and not is_exhausted:
			velocity.y = cfg.jump_velocity
			_consume_stamina(cfg.stamina_jump_cost)
			jump_buffer_counter = 0.0  # Consume buffered input
			coyote_counter = 0.0  # Prevent double jump

func _consume_stamina(amount: float) -> void:
	var cfg = _get_config()
	stamina = max(0.0, stamina - amount)
	stamina_regen_timer = cfg.stamina_regen_delay
	
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
	var cfg = _get_config()
	stamina = max(0.0, stamina - cfg.stamina_sprint_drain * delta)
	stamina_regen_timer = cfg.stamina_regen_delay
	
	if stamina <= 0.0:
		is_exhausted = true

func _regenerate_stamina(delta: float) -> void:
	var cfg = _get_config()
	# Mark as exhausted if below minimum threshold
	if stamina < cfg.stamina_min_to_sprint and not is_exhausted:
		is_exhausted = true
	
	# Regenerate after delay
	stamina_regen_timer -= delta
	if stamina_regen_timer <= 0.0:
		stamina = min(cfg.max_stamina, stamina + cfg.stamina_regen_rate * delta)
	
	# Clear exhaustion when stamina recovers
	if is_exhausted and stamina >= cfg.stamina_min_to_sprint:
		is_exhausted = false
#endregion

#region Headbob
func _apply_headbob(delta: float, is_moving: bool) -> void:
	if is_on_floor() and is_moving:
		_apply_active_headbob(delta)
	else:
		_reset_headbob(delta)

func _apply_active_headbob(delta: float) -> void:
	var cfg = _get_config()
	var is_sprinting: bool = current_speed == cfg.sprint_speed
	var sprint_mult: float = cfg.headbob_sprint_multiplier if is_sprinting else 1.0
	var frequency: float = cfg.headbob_frequency * sprint_mult
	var amplitude: float = cfg.headbob_amplitude * sprint_mult
	
	headbob_time += delta * velocity.length()
	camera_pivot.transform.origin = _calculate_headbob_offset(headbob_time, frequency, amplitude)

func _reset_headbob(delta: float) -> void:
	camera_pivot.transform.origin = camera_pivot.transform.origin.lerp(
		Vector3.ZERO, 
		delta * 5.0  # headbob smoothing
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
