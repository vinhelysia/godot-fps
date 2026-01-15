extends Resource
class_name PlayerConfig

## Movement Configuration
@export_group("Movement")
@export var walk_speed: float = 2.0
@export var sprint_speed: float = 5.0
@export var jump_velocity: float = 4.0
@export var air_acceleration: float = 0.5
@export var mouse_sensitivity: float = 0.002

## Stamina Configuration
@export_group("Stamina")
@export var max_stamina: float = 100.0
@export var stamina_regen_rate: float = 20.0
@export var stamina_regen_delay: float = 1.0
@export var stamina_sprint_drain: float = 10.0
@export var stamina_jump_cost: float = 15.0
@export var stamina_min_to_sprint: float = 20.0

## Headbob Configuration
@export_group("Headbob")
@export var headbob_frequency: float = 2.0
@export var headbob_amplitude: float = 0.05
@export var headbob_sprint_multiplier: float = 1.5

## Input Feel Configuration
@export_group("Input Feel")
@export var coyote_time: float = 0.15  # Grace period after leaving ground
@export var jump_buffer_time: float = 0.1  # Early jump input window
