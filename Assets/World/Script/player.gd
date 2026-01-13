extends CharacterBody3D

# Movement speeds
var speed: float
const SPEED_WALK = 4.0
const SPEED_SPRINT = 7.0
const JUMP_VELOCITY = 4.0
const MOUSE_SENSITIVITY = 0.003

# Standard FPS movement
const ACCELERATION = 10.0       # How quickly player reaches target speed
const DECELERATION = 12.0       # How quickly player stops
const AIR_CONTROL = 0.3         # Reduced control in air (0-1)

# Stamina system
const MAX_STAMINA = 100.0
const STAMINA_DRAIN_RATE = 15.0      # Stamina consumed per second while sprinting
const STAMINA_REGEN_RATE = 10.0      # Stamina recovered per second while not sprinting
const STAMINA_REGEN_DELAY = 1.0      # Seconds to wait before stamina starts regenerating
const STAMINA_MIN_TO_SPRINT = 10.0   # Minimum stamina required to start sprinting
const STAMINA_JUMP_COST = 15.0       # Stamina consumed per jump
var stamina: float = MAX_STAMINA
var stamina_regen_timer: float = 0.0
var is_exhausted: bool = false       # True when stamina depleted, prevents sprint until threshold

# Headbob
const BOB_FREQ_WALK = 2.0
const BOB_FREQ_SPRINT = 2.8
const BOB_AMP_WALK = 0.05
const BOB_AMP_SPRINT = 0.1
var t_bob = 0.0

@onready var camera_pivot = $Head
@onready var camara3d = $Head/Camera3Ds
@onready var speed_label = $CanvasLayer/SpeedLabel
@onready var stamina_bar = $CanvasLayer/StaminaBar

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -1.5, 1.5)
	
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Jump (single press, no bunny hop, costs stamina)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		if stamina >= STAMINA_JUMP_COST and not is_exhausted:
			velocity.y = JUMP_VELOCITY
			stamina -= STAMINA_JUMP_COST
			stamina_regen_timer = STAMINA_REGEN_DELAY
			if stamina <= 0:
				stamina = 0
				is_exhausted = true
	
	# Get input direction
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Determine if we can sprint
	var wants_to_sprint = Input.is_action_pressed("sprint") and input_dir.y < 0  # Only sprint when moving forward
	var can_sprint = stamina > 0 and not is_exhausted and wants_to_sprint
	
	# Handle stamina
	_update_stamina(delta, can_sprint and direction.length() > 0.1)
	
	# Set speed based on sprint state
	if can_sprint and direction.length() > 0.1:
		speed = SPEED_SPRINT
	else:
		speed = SPEED_WALK
	
	# Movement
	if is_on_floor():
		_ground_move(direction, delta)
	else:
		_air_move(direction, delta)
	
	# Headbob (different intensity for walk vs sprint)
	if is_on_floor() and direction.length() > 0.1:
		var bob_freq = BOB_FREQ_SPRINT if speed == SPEED_SPRINT else BOB_FREQ_WALK
		var bob_amp = BOB_AMP_SPRINT if speed == SPEED_SPRINT else BOB_AMP_WALK
		t_bob += delta * velocity.length()
		camera_pivot.transform.origin = _headbob(t_bob, bob_freq, bob_amp)
	else:
		# Smoothly return to center when not moving
		camera_pivot.transform.origin = camera_pivot.transform.origin.lerp(Vector3.ZERO, delta * 5.0)
	
	# Speed & stamina display
	var current_speed = Vector2(velocity.x, velocity.z).length()
	if speed_label:
		speed_label.text = "Speed: %.1f" % current_speed
	if stamina_bar:
		stamina_bar.value = stamina
		# Change color based on exhaustion state
		var fill_style = stamina_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if fill_style:
			if is_exhausted:
				fill_style.bg_color = Color(0.9, 0.2, 0.2, 1)  # Red when exhausted
			else:
				fill_style.bg_color = Color(0.95, 0.8, 0.2, 1)  # Yellow normally
	
	move_and_slide()

func _update_stamina(delta: float, is_sprinting: bool) -> void:
	if is_sprinting:
		# Drain stamina while sprinting
		stamina -= STAMINA_DRAIN_RATE * delta
		stamina_regen_timer = STAMINA_REGEN_DELAY
		
		if stamina <= 0:
			stamina = 0
			is_exhausted = true  # Only exhaust when fully depleted while sprinting
	else:
		# Check for exhaustion when stopping consumption while below minimum
		if stamina < STAMINA_MIN_TO_SPRINT and not is_exhausted:
			is_exhausted = true
		
		# Regenerate stamina when not sprinting (after delay)
		stamina_regen_timer -= delta
		if stamina_regen_timer <= 0:
			stamina += STAMINA_REGEN_RATE * delta
			stamina = min(stamina, MAX_STAMINA)
		
		# Allow sprinting again once stamina recovers
		if is_exhausted and stamina >= STAMINA_MIN_TO_SPRINT:
			is_exhausted = false

func _ground_move(direction: Vector3, delta: float) -> void:
	var target_velocity = direction * speed
	
	if direction.length() > 0.1:
		# Accelerate towards target
		velocity.x = move_toward(velocity.x, target_velocity.x, ACCELERATION * delta * speed)
		velocity.z = move_toward(velocity.z, target_velocity.z, ACCELERATION * delta * speed)
	else:
		# Decelerate to stop
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta * speed)
		velocity.z = move_toward(velocity.z, 0, DECELERATION * delta * speed)

func _air_move(direction: Vector3, delta: float) -> void:
	# Limited air control
	var target_velocity = direction * speed * AIR_CONTROL
	velocity.x = move_toward(velocity.x, velocity.x + target_velocity.x, ACCELERATION * AIR_CONTROL * delta)
	velocity.z = move_toward(velocity.z, velocity.z + target_velocity.z, ACCELERATION * AIR_CONTROL * delta)

func _headbob(time: float, frequency: float, amplitude: float) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * frequency) * amplitude
	pos.x = cos(time * frequency * 0.5) * amplitude * 0.5
	return pos
