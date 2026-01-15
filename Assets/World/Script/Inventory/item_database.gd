extends Node

# Preload item type classes for static analysis
const WeaponDataClass = preload("res://Assets/World/Script/Inventory/ItemTypes/weapon_data.gd")
const AmmoDataClass = preload("res://Assets/World/Script/Inventory/ItemTypes/ammo_data.gd")
const MedicalDataClass = preload("res://Assets/World/Script/Inventory/ItemTypes/medical_data.gd")
const ArmorDataClass = preload("res://Assets/World/Script/Inventory/ItemTypes/armor_data.gd")

# Central registry of all items
var items: Dictionary = {}  # item_id -> ItemData

func _ready() -> void:
	_register_all_items()
	print("Item Database loaded: ", items.size(), " items")

# Register all items in the game
func _register_all_items() -> void:
	# WEAPONS
	_register_weapon("ak47", "AK-47", Vector2i(4, 2), {
		"damage": 40.0,
		"fire_rate": 600.0,
		"ammo_type": "7.62x39",
		"magazine_size": 30,
		"weapon_type": WeaponData.WeaponType.RIFLE,
		"fire_mode": WeaponData.FireMode.AUTO,
		"icon_path": "res://Assets/World/Model&Etc/Weapon/Firearms/AssaultRifle/AK47/ak.47 (1).png",
		"model_path": "res://Assets/World/Model&Etc/Weapon/Firearms/AssaultRifle/AK47/ak_47.glb"
	})
	
	_register_weapon("m4a1", "M4A1", Vector2i(4, 2), {
		"damage": 35.0,
		"fire_rate": 800.0,
		"ammo_type": "5.56x45",
		"magazine_size": 30,
		"weapon_type": WeaponData.WeaponType.RIFLE,
		"fire_mode": WeaponData.FireMode.AUTO,
		"icon_path": "res://Assets/World/Model&Etc/Weapon/Firearms/AssaultRifle/M4A1/m4.png",
		"model_path": "res://Assets/World/Model&Etc/Weapon/Firearms/AssaultRifle/M4A1/m4.glb"
	})
	
	_register_weapon("glock17", "Glock 17", Vector2i(2, 2), {
		"damage": 25.0,
		"fire_rate": 400.0,
		"ammo_type": "9x19",
		"magazine_size": 17,
		"weapon_type": WeaponData.WeaponType.PISTOL,
		"fire_mode": WeaponData.FireMode.SEMI,
		"icon_path": "",  # TODO: Add icon when model is added
		"model_path": ""  # TODO: Add model path
	})
	
	# AMMO
	_register_ammo("ammo_762", "7.62x39 Ammo", Vector2i(1, 1), {
		"ammo_type": "7.62x39",
		"bullet_count": 30,
		"penetration": 40.0
	})
	
	_register_ammo("ammo_556", "5.56x45 Ammo", Vector2i(1, 1), {
		"ammo_type": "5.56x45",
		"bullet_count": 30,
		"penetration": 35.0
	})
	
	_register_ammo("ammo_9mm", "9x19 Ammo", Vector2i(1, 1), {
		"ammo_type": "9x19",
		"bullet_count": 50,
		"penetration": 20.0
	})
	
	# MEDICAL
	_register_medical("bandage", "Bandage", Vector2i(1, 1), {
		"heal_amount": 20.0,
		"use_time": 2.0,
		"stops_bleeding": true
	})
	
	_register_medical("medkit", "Medical Kit", Vector2i(2, 2), {
		"heal_amount": 100.0,
		"use_time": 5.0,
		"heals_body_part": true
	})
	
	_register_medical("painkillers", "Painkillers", Vector2i(1, 1), {
		"heal_amount": 30.0,
		"use_time": 1.5,
		"removes_fracture": true
	})
	
	# ARMOR
	_register_armor("helmet_lvl3", "Level 3 Helmet", Vector2i(2, 2), {
		"armor_class": 3,
		"durability": 50.0,
		"armor_slot": ArmorData.ArmorSlot.HEAD
	})
	
	_register_armor("vest_lvl4", "Level 4 Vest", Vector2i(3, 3), {
		"armor_class": 4,
		"durability": 80.0,
		"armor_slot": ArmorData.ArmorSlot.CHEST,
		"movement_penalty": 0.1
	})

# Helper functions to register items
func _register_weapon(id: String, item_name: String, size: Vector2i, props: Dictionary) -> void:
	var weapon = WeaponData.new()
	weapon.item_id = id
	weapon.item_name = item_name
	weapon.size = size
	weapon.can_rotate = true
	weapon.max_stack = 1
	
	# Load icon from path
	if props.has("icon_path") and props.icon_path != "":
		var icon_resource = load(props.icon_path)
		if icon_resource:
			weapon.icon = icon_resource
		else:
			push_warning("Failed to load icon for weapon: " + id)
	
	# Store model path for spawning in 3D world
	if props.has("model_path"):
		weapon.model_path = props.model_path
	
	# Set weapon-specific properties
	if props.has("damage"):
		weapon.damage = props.damage
	if props.has("fire_rate"):
		weapon.fire_rate = props.fire_rate
	if props.has("ammo_type"):
		weapon.ammo_type = props.ammo_type
	if props.has("magazine_size"):
		weapon.magazine_size = props.magazine_size
	if props.has("weapon_type"):
		weapon.weapon_type = props.weapon_type
	if props.has("fire_mode"):
		weapon.fire_mode = props.fire_mode
	if props.has("reload_time"):
		weapon.reload_time = props.reload_time
	if props.has("recoil"):
		weapon.recoil = props.recoil
	if props.has("accuracy"):
		weapon.accuracy = props.accuracy
	
	items[id] = weapon

func _register_ammo(id: String, item_name: String, size: Vector2i, props: Dictionary) -> void:
	var ammo = AmmoData.new()
	ammo.item_id = id
	ammo.item_name = item_name
	ammo.size = size
	ammo.can_rotate = false
	ammo.max_stack = 60  # Can stack ammo
	
	# Load icon from path
	if props.has("icon_path") and props.icon_path != "":
		var icon_resource = load(props.icon_path)
		if icon_resource:
			ammo.icon = icon_resource
		else:
			push_warning("Failed to load icon for ammo: " + id)
	
	# Store model path for spawning in 3D world
	if props.has("model_path"):
		ammo.model_path = props.model_path
	
	if props.has("ammo_type"):
		ammo.ammo_type = props.ammo_type
	if props.has("bullet_count"):
		ammo.bullet_count = props.bullet_count
	if props.has("penetration"):
		ammo.penetration = props.penetration
	if props.has("damage_multiplier"):
		ammo.damage_multiplier = props.damage_multiplier
	
	items[id] = ammo

func _register_medical(id: String, item_name: String, size: Vector2i, props: Dictionary) -> void:
	var medical = MedicalData.new()
	medical.item_id = id
	medical.item_name = item_name
	medical.size = size
	medical.can_rotate = false
	medical.max_stack = 5
	
	# Load icon from path
	if props.has("icon_path") and props.icon_path != "":
		var icon_resource = load(props.icon_path)
		if icon_resource:
			medical.icon = icon_resource
		else:
			push_warning("Failed to load icon for medical: " + id)
	
	# Store model path for spawning in 3D world
	if props.has("model_path"):
		medical.model_path = props.model_path
	
	if props.has("heal_amount"):
		medical.heal_amount = props.heal_amount
	if props.has("use_time"):
		medical.use_time = props.use_time
	if props.has("stops_bleeding"):
		medical.stops_bleeding = props.stops_bleeding
	if props.has("heals_body_part"):
		medical.heals_body_part = props.heals_body_part
	if props.has("removes_fracture"):
		medical.removes_fracture = props.removes_fracture
	
	items[id] = medical

func _register_armor(id: String, item_name: String, size: Vector2i, props: Dictionary) -> void:
	var armor = ArmorData.new()
	armor.item_id = id
	armor.item_name = item_name
	armor.size = size
	armor.can_rotate = false
	armor.max_stack = 1
	
	# Load icon from path
	if props.has("icon_path") and props.icon_path != "":
		var icon_resource = load(props.icon_path)
		if icon_resource:
			armor.icon = icon_resource
		else:
			push_warning("Failed to load icon for armor: " + id)
	
	# Store model path for spawning in 3D world
	if props.has("model_path"):
		armor.model_path = props.model_path
	
	if props.has("armor_class"):
		armor.armor_class = props.armor_class
	if props.has("durability"):
		armor.durability = props.durability
		armor.max_durability = props.durability
	if props.has("max_durability"):
		armor.max_durability = props.max_durability
	if props.has("armor_slot"):
		armor.armor_slot = props.armor_slot
	if props.has("movement_penalty"):
		armor.movement_penalty = props.movement_penalty
	
	items[id] = armor

# ==================== PUBLIC API ====================

# Get item by ID
func get_item(item_id: String) -> ItemData:
	if items.has(item_id):
		return items[item_id]
	push_error("Item not found: " + item_id)
	return null

# Get all items of a specific type
func get_items_by_type(type: String) -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item in items.values():
		if item is WeaponData and type == "weapon":
			result.append(item)
		elif item is AmmoData and type == "ammo":
			result.append(item)
		elif item is MedicalData and type == "medical":
			result.append(item)
		elif item is ArmorData and type == "armor":
			result.append(item)
	return result

# Create an inventory item from ID
func create_inventory_item(item_id: String, grid_position: Vector2i = Vector2i.ZERO) -> InventoryItem:
	var item_data = get_item(item_id)
	if item_data:
		return InventoryItem.new(item_data, grid_position)
	return null

# Check if item exists
func has_item(item_id: String) -> bool:
	return items.has(item_id)

# Get all item IDs
func get_all_item_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in items.keys():
		ids.append(id)
	return ids
