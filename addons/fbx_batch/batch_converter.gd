@tool
extends EditorScript

const SOURCE_DIR = "res://addons/fbx_batch/FBX/"
const OUTPUT_DIR = "res://addons/fbx_batch/Converted/"
const SUPPORTED_EXTENSIONS = [".fbx", ".dae", ".glb"]

func _run():
	print("=== FBX/DAE Batch Converter Started ===")
	
	if not DirAccess.dir_exists_absolute(OUTPUT_DIR):
		DirAccess.open("res://").make_dir_recursive(OUTPUT_DIR)
		print("Created output directory: ", OUTPUT_DIR)
	
	var model_files = find_model_files(SOURCE_DIR)
	print("Found ", model_files.size(), " model files (FBX/DAE) to convert")
	
	if model_files.is_empty():
		print("No FBX or DAE files found in: ", SOURCE_DIR)
		return
	
	var converted_count = 0
	for model_path in model_files:
		if convert_model_to_tscn(model_path):
			converted_count += 1
	
	print("=== Conversion Complete ===")
	print("Successfully converted ", converted_count, " out of ", model_files.size(), " files")

func find_model_files(directory: String) -> Array[String]:
	var model_files: Array[String] = []
	var dir = DirAccess.open(directory)
	
	if not dir:
		print("ERROR: Could not open directory: ", directory)
		return model_files
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = directory.path_join(file_name)
		
		if dir.current_is_dir() and not file_name.begins_with("."):
			model_files.append_array(find_model_files(full_path))
		elif is_supported_model_file(file_name):
			model_files.append(full_path)
			print("Found model: ", file_name)
		
		file_name = dir.get_next()
	
	return model_files

func is_supported_model_file(file_name: String) -> bool:
	var lower_name = file_name.to_lower()
	for ext in SUPPORTED_EXTENSIONS:
		if lower_name.ends_with(ext):
			return true
	return false

func print_node_tree(node: Node, indent: int):
	var indent_str = ""
	for i in range(indent):
		indent_str += "  "
	print(indent_str, node.name, " [", node.get_class(), "]")
	for child in node.get_children():
		print_node_tree(child, indent + 1)

func convert_model_to_tscn(model_path: String) -> bool:
	print("\n--- Converting: ", model_path.get_file(), " ---")
	
	var model_resource: PackedScene = ResourceLoader.load(model_path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE)
	if not model_resource:
		print("ERROR: Failed to load model: ", model_path)
		return false
	
	var model_instance: Node = model_resource.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	if not model_instance:
		print("ERROR: Failed to instantiate model scene: ", model_path)
		return false
	
	print("=== Model Node Tree ===")
	print_node_tree(model_instance, 0)
	print("=======================")
	
	var all_mesh_instances = find_all_mesh_instances(model_instance)
	if all_mesh_instances.is_empty():
		print("WARNING: No MeshInstance3D found in model, skipping: ", model_path.get_file())
		model_instance.queue_free()
		return false
	
	print("Found ", all_mesh_instances.size(), " mesh instances")
	
	var root_node = Node3D.new()
	var base_name = model_path.get_file().get_basename()
	root_node.name = base_name.capitalize().replace("_", "").replace("-", "")
	var static_body = StaticBody3D.new()
	static_body.name = "StaticBody3D"
	root_node.add_child(static_body)
	static_body.owner = root_node
	
	for original_mesh in all_mesh_instances:
		var new_mesh_instance = MeshInstance3D.new()
		new_mesh_instance.name = original_mesh.name
		new_mesh_instance.mesh = original_mesh.mesh.duplicate(true)
		# Calculate accumulated transform by walking up parent chain to model root
		new_mesh_instance.transform = get_accumulated_transform(original_mesh, model_instance)
		
		preserve_original_materials(original_mesh, new_mesh_instance)
		
		static_body.add_child(new_mesh_instance)
		new_mesh_instance.owner = root_node
		
		print("Added mesh: ", original_mesh.name)
	create_collision_shape_from_all_meshes(all_mesh_instances, static_body, root_node, model_instance)
	var success = save_scene(root_node, base_name)
	model_instance.queue_free()
	root_node.queue_free()
	
	return success

func find_all_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var mesh_instances: Array[MeshInstance3D] = []
	
	if node is MeshInstance3D:
		mesh_instances.append(node)
	
	for child in node.get_children():
		mesh_instances.append_array(find_all_mesh_instances(child))
	
	return mesh_instances

func get_accumulated_transform(node: Node3D, root: Node) -> Transform3D:
	# Walk up the parent chain and multiply transforms to get world transform
	var accumulated = Transform3D.IDENTITY
	var current = node
	while current != null and current != root:
		if current is Node3D:
			accumulated = current.transform * accumulated
		current = current.get_parent()
	return accumulated

func preserve_original_materials(original: MeshInstance3D, new_instance: MeshInstance3D):
	if original.get_surface_override_material_count() > 0:
		for surface_idx in range(original.get_surface_override_material_count()):
			var original_material = original.get_surface_override_material(surface_idx)
			if original_material:
				new_instance.set_surface_override_material(surface_idx, original_material)
				print("Preserved surface material ", surface_idx)

	elif original.material_override:
		new_instance.material_override = original.material_override
		print("Preserved material override")
	
	else:
		print("Using mesh built-in materials")

func create_collision_shape_from_all_meshes(mesh_instances: Array[MeshInstance3D], static_body: StaticBody3D, root_node: Node3D, model_root: Node):
	var all_faces: PackedVector3Array = PackedVector3Array()
	var total_face_count = 0
	
	for mesh_instance in mesh_instances:
		if mesh_instance.mesh == null:
			continue
			
		var mesh_faces = mesh_instance.mesh.get_faces()
		if mesh_faces.size() == 0:
			continue
			
		# Get accumulated transform for this mesh
		var mesh_transform = get_accumulated_transform(mesh_instance, model_root)
		
		# Transform faces by the accumulated transform
		var transformed_faces: PackedVector3Array = PackedVector3Array()
		for i in range(0, mesh_faces.size(), 3):
			# Transform each triangle vertex
			var v1 = mesh_transform * mesh_faces[i]
			var v2 = mesh_transform * mesh_faces[i + 1]
			var v3 = mesh_transform * mesh_faces[i + 2]
			
			transformed_faces.append(v1)
			transformed_faces.append(v2)
			transformed_faces.append(v3)
		
		all_faces.append_array(transformed_faces)
		var mesh_face_count = mesh_faces.size() / 3
		total_face_count += mesh_face_count
		print("Added ", mesh_face_count, " faces from: ", mesh_instance.name)
	
	if all_faces.size() == 0:
		print("WARNING: No faces found in any mesh instances")
		return
	
	var collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	
	var concave_shape = ConcavePolygonShape3D.new()
	concave_shape.set_faces(all_faces)
	collision_shape.shape = concave_shape
	
	static_body.add_child(collision_shape)
	collision_shape.owner = root_node
	
	print("Created combined collision shape with ", total_face_count, " total faces")

func save_scene(root_node: Node3D, base_name: String) -> bool:
	var scene_path = OUTPUT_DIR.path_join(root_node.name + ".tscn")
	
	var packed_scene = PackedScene.new()
	var pack_result = packed_scene.pack(root_node)
	
	if pack_result != OK:
		print("ERROR: Failed to pack scene for: ", base_name)
		return false
	
	var save_flags = ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS | ResourceSaver.FLAG_RELATIVE_PATHS
	var save_result = ResourceSaver.save(packed_scene, scene_path, save_flags)
	
	if save_result != OK:
		print("ERROR: Failed to save scene: ", scene_path)
		return false
	
	print("SUCCESS: Saved scene to: ", scene_path)
	return true
