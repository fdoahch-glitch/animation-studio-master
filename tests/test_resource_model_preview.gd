extends SceneTree

const PREVIEW = preload("res://scripts/resource_model_preview.gd")

func _initialize() -> void:
	_run_test()

func _run_test() -> void:
	var preview = PREVIEW.new()
	preview.custom_minimum_size = Vector2(256, 192)
	preview._ready()
	print("PREVIEW_TEST_READY")
	var sample_root := Node3D.new()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = BoxMesh.new()
	sample_root.add_child(mesh_instance)
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	print("PREVIEW_TEST_EXPORTING")
	var append_error := document.append_from_scene(sample_root, state)
	if append_error != OK:
		push_error("No se pudo serializar la escena de prueba a glTF: " + error_string(append_error))
		quit(1)
		return
	var path := "user://resource_model_preview_test.glb"
	var write_error := document.write_to_filesystem(state, path)
	if write_error != OK:
		push_error("No se pudo crear el GLB de prueba: " + error_string(write_error))
		quit(1)
		return
	sample_root.free()
	print("PREVIEW_TEST_IMPORTING")
	var result: Dictionary = preview.load_model(path)
	if not bool(result.get("ok", false)):
		push_error("No se pudo cargar el GLB en la vista previa: " + str(result.get("error", "")))
		quit(1)
		return
	if not preview.has_model():
		push_error("La vista previa no conservó el modelo cargado.")
		quit(1)
		return
	preview.clear_model()
	if preview.has_model():
		push_error("La vista previa no liberó el modelo.")
		quit(1)
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("RESOURCE_MODEL_PREVIEW_TESTS_OK")
	quit(0)
