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
	if not _check(export_error == OK, "No se pudo serializar la escena GLB: " + error_string(export_error)):
		return
	var path := "user://resource_model_preview_test.glb"
	var write_error := export_document.write_to_filesystem(export_state, path)
	if not _check(write_error == OK, "No se pudo escribir el GLB: " + error_string(write_error)):
		return
	source_root.free()
	print("GLB_PREVIEW_EXPORT_OK")

	var preview = load("res://scripts/resource_model_preview.gd").new()
	root.add_child(preview)
	await process_frame
	var result: Dictionary = preview.load_model(path)
	if not _check(result.get("ok", false), "El visor no pudo cargar el GLB: " + str(result.get("error", ""))):
		return
	if not _check(preview.has_model(), "El visor debe mantener el modelo cargado"):
		return
	print("GLB_PREVIEW_LOAD_OK")

	if not _check(int(result.get("animation_count", 0)) >= 1, "El visor no detectó clips importados"):
		return
	if not _check(preview.get_animation_names().has("Move"), "No enumeró la animación importada Move"):
		return
	if not _check(preview.play_animation("Move"), "No pudo reproducir la animación importada"):
		return
	print("GLB_PREVIEW_ANIMATION_OK")

	preview.last_pointer = Vector2(100, 100)
	var initial_rotation: float = preview.model_pivot.rotation.y
	preview._rotate_from_pointer(Vector2(130, 100))
	if not _check(not is_equal_approx(preview.model_pivot.rotation.y, initial_rotation), "El modelo no giró al arrastrar"):
		return
	var initial_zoom: float = preview.preview_camera.position.length()
	preview._zoom_camera(0.88)
	if not _check(preview.preview_camera.position.length() < initial_zoom, "El zoom no acercó la cámara"):
		return
	preview.stop_animation()
	preview.clear_model()
	if not _check(not preview.has_model(), "Limpiar el visor debe liberar el modelo activo"):
		return
	preview.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("RESOURCE_MODEL_PREVIEW_TESTS_OK")
	quit(0)

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
