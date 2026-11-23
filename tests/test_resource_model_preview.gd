extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var source_root := Node3D.new()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "PreviewMesh"
	mesh_instance.mesh = BoxMesh.new()
	source_root.add_child(mesh_instance)
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	source_root.add_child(player)
	var library := AnimationLibrary.new()
	var clip := Animation.new()
	clip.length = 1.0
	var value_track := clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(value_track, NodePath("PreviewMesh:position"))
	clip.track_insert_key(value_track, 0.0, Vector3.ZERO)
	clip.track_insert_key(value_track, 1.0, Vector3.UP)
	library.add_animation("Move", clip)
	player.add_animation_library("", library)

	var export_document := GLTFDocument.new()
	var export_state := GLTFState.new()
	var export_error := export_document.append_from_scene(source_root, export_state)
	if export_error != OK:
		_fail("No se pudo serializar la escena de prueba: " + error_string(export_error))
		return
	var path := "user://resource_model_preview_test.glb"
	var write_error := export_document.write_to_filesystem(export_state, path)
	if write_error != OK:
		_fail("No se pudo escribir el GLB de prueba: " + error_string(write_error))
		return
	source_root.free()

	var preview = load("res://scripts/resource_model_preview.gd").new()
	root.add_child(preview)
	await process_frame
	var result: Dictionary = preview.load_model(path)
	assert(result.get("ok", false), "La vista previa debe cargar el GLB real: " + str(result.get("error", "")))
	assert(preview.has_model(), "La vista previa debe mantener el modelo cargado")
	assert(int(result.get("animation_count", 0)) >= 1, "Debe detectar clips importados")
	assert(preview.get_animation_names().has("Move"), "Debe enumerar la animación importada")
	assert(preview.play_animation("Move"), "Debe reproducir la animación importada")

	preview.last_pointer = Vector2(100, 100)
	var initial_rotation: float = preview.model_pivot.rotation.y
	preview._rotate_from_pointer(Vector2(130, 100))
	assert(not is_equal_approx(preview.model_pivot.rotation.y, initial_rotation), "El modelo debe girar al arrastrar el puntero")
	var initial_zoom := preview.preview_camera.position.length()
	preview._zoom_camera(0.88)
	assert(preview.preview_camera.position.length() < initial_zoom, "El zoom debe acercar la cámara")
	preview.stop_animation()
	preview.clear_model()
	assert(not preview.has_model(), "Limpiar la vista previa debe liberar el modelo activo")
	preview.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("RESOURCE_MODEL_PREVIEW_TESTS_OK")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
