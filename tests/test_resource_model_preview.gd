extends SceneTree

const PREVIEW = preload("res://scripts/resource_model_preview.gd")

func _initialize() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var preview = PREVIEW.new()
	preview.custom_minimum_size = Vector2(256, 192)
	root.add_child(preview)
	var sample_root := Node3D.new()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = BoxMesh.new()
	sample_root.add_child(mesh_instance)
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	assert(document.append_from_scene(sample_root, state) == OK, "Debe serializar la escena de prueba a glTF")
	var path := "user://resource_model_preview_test.glb"
	assert(document.write_to_filesystem(state, path) == OK, "Debe crear el GLB de prueba")
	sample_root.free()
	var result: Dictionary = preview.load_model(path)
	assert(result.get("ok", false), "Debe cargar el GLB en la vista previa: " + str(result.get("error", "")))
	assert(preview.has_model(), "La vista previa debe conservar el modelo cargado")
	preview.clear_model()
	assert(not preview.has_model(), "La vista previa debe poder liberar el modelo")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("RESOURCE_MODEL_PREVIEW_TESTS_OK")
	quit(0)
