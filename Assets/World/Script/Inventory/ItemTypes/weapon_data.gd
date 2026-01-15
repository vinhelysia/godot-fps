extends ItemData
class_name WeaponData

enum WeaponType { RIFLE, PISTOL, SHOTGUN, MELEE }
enum FireMode { SEMI, AUTO, BURST }

@export var weapon_type: WeaponType = WeaponType.RIFLE
@export var damage: float = 30.0
@export var fire_rate: float = 600.0  # Rounds per minute
@export var fire_mode: FireMode = FireMode.SEMI
@export var magazine_size: int = 30
@export var reload_time: float = 2.5
@export var ammo_type: String = "5.56x45"  # What ammo it uses
@export var recoil: float = 1.0
@export var accuracy: float = 0.9
@export var model_path: String = ""  # Path to the 3D model .glb file
