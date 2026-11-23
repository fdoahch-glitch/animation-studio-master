extends SceneTree

const SPATIAL_BUILDER = preload("res://scripts/character_spatial_rig_builder.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var builder = SPATIAL_BUILDER.new()
	var source_root := Node3D.new()
	source_root.name = "SkinnedGLBFixture"

	var humanoid_root: Node3D = builder.build_humanoid_3d("ImportedHumanoid")
	var humanoid_skeleton: Skeleton3D = humanoid_root.get_node("Skeleton3D")
	_remove_segment_attachments(humanoid_skeleton)
	source_root.add_child(humanoid_root)
	_add_skinned_triangle(source_root, humanoid_skeleton, NodePath("../" + humanoid_root.name + "/Skeleton3D"), "HumanoidSkin")

	var quadruped_root: Node3D = builder.build_quadruped_3d("ImportedQuadruped")
	quadruped_root.position = Vector3(2.0, 0.0, 0.0)
	var quadruped_skeleton: Skeleton3D = quadruped_root.get_node("Skeleton3D")
	_remove_segment_attachments(quadruped_skeleton)
	source_root.add_child(quadruped_root)
	_add_skinned_triangle(source_root, quadruped_skeleton, NodePath("../" + quadruped_root.name + "/Skeleton3D"), "QuadrupedSkin")

	root.add_child(source_root)
	await process_frame
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var export_error := document.append_from_scene(source_root, state)
	if not _check(export_error == OK, "No se pudo exportar el GLB con mallas skinned: " + error_string(export_error)):
		return
	var path := "user://stage5_skinned_skeleton_test.glb"
	var write_error := document.write_to_filesystem(state, path)
	if not _check(write_error == OK, "No se pudo escribir el GLB skinned: " + error_string(write_error)):
		return
	print("SKINNED_GLB_EXPORT_OK")

	var preview = load("res://scripts/resource_model_preview.gd").new()
	root.add_child(preview)
	await process_frame
	var result: Dictionary = preview.load_model(path)
	if not _check(result.get("ok", false), "El visor no pudo importar el GLB skinned: " + str(result.get("error", ""))):
		return
	var summaries: Array = preview.get_skeleton_summaries()
	if not _check(summaries.size() >= 2, "El GLB importado debe conservar dos esqueletos; detectados: " + str(summaries.size())):
		return
	var found_humanoid := false
	var found_quadruped := false
	for summary in summaries:
		found_humanoid = found_humanoid or float(summary.get("humanoid_coverage", 0.0)) >= 0.65
		found_quadruped = found_quadruped or float(summary.get("quadruped_coverage", 0.0)) >= 0.65
	if not _check(found_humanoid, "No se reconoció la cobertura del esqueleto humanoide"):
		return
	if not _check(found_quadruped, "No se reconoció la cobertura del esqueleto cuadrúpedo"):
		return
	print("SKINNED_GLB_SKELETON_IMPORT_OK")
	preview.clear_model()
	preview.free()
	source_root.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("STAGE5_SKINNED_GLB_TESTS_OK")
	quit(0)

func _remove_segment_attachments(skeleton: Skeleton3D) -> void:
	for child in skeleton.get_children():
		child.free()

func _add_skinned_triangle(parent: Node3D, skeleton: Skeleton3D, skeleton_path: NodePath, node_name: String) -> void:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		Vector3(0.0, 0.0, 0.0),
		Vector3(0.35, 0.0, 0.0),
		Vector3(0.0, 0.35, 0.0)
	])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK])
	arrays[Mesh.ARRAY_BONES] = PackedInt32Array([
		0,0,0,0,
		0,0,0,0,
		0,0,0,0
	])
	arrays[Mesh.ARRAY_WEIGHTS] = PackedFloat32Array([
		1.0,0.0,0.0,0.0,
		1.0,0.0,0.0,0.0,
		1.0,0.0,0.0,0.0
	])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2])
	var skinned_mesh := ArrayMesh.new()
	skinned_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = skinned_mesh
	parent.add_child(instance)
	instance.skeleton = skeleton_path
	instance.skin = skeleton.create_skin_from_rest_transforms()
