extends SceneTree

func _initialize() -> void:
	var source_root := Node3D.new()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = BoxMesh.new()
	source_root.add_child(mesh_instance)
	var export_document := GLTFDocument.new()
	var export_state := GLTFState.new()
	var export_error := export_document.append_from_scene(source_root, export_state)
	if export_error != OK:
		push_error("No se pudo serializar la escena de prueba: " + error_string(export_error))
		quit(1)
		return
	var path := "user://resource_model_preview_test.glb"
	var write_error := export_document.write_to_filesystem(export_state, path)
	if write_error != OK:
		push_error("No se pudo escribir el GLB de prueba: " + error_string(write_error))
		quit(1)
		return
	source_root.free()
	var import_document := GLTFDocument.new()
	var import_state := GLTFState.new()
	var import_error := import_document.append_from_file(path, import_state)
	if import_error != OK:
		push_error("No se pudo importar el GLB de prueba: " + error_string(import_error))
		quit(1)
		return
	var generated: Node = import_document.generate_scene(import_state)
	if generated == null:
		push_error("La importación no generó una escena 3D.")
		quit(1)
		return
	var meshes := generated.find_children("*", "MeshInstance3D", true, false)
	if meshes.is_empty():
		push_error("La escena GLB importada no conserva su malla.")
		generated.free()
		quit(1)
		return
	generated.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("RESOURCE_MODEL_PREVIEW_TESTS_OK")
	quit(0)
