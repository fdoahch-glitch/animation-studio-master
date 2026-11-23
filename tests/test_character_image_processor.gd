extends SceneTree

const PROCESSOR = preload("res://scripts/character_image_processor.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var processor = PROCESSOR.new()
	var source_path := "user://character_image_processor_test.png"
	var image := Image.create(64, 96, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	for y in range(12, 85):
		for x in range(18, 47):
			image.set_pixel(x, y, Color("#2478b8"))
	if not _check(image.save_png(source_path) == OK, "No se pudo crear la imagen sintética"):
		return
	print("IMAGE_TEST_SOURCE_OK")

	var adjusted_path: String = processor.create_adjusted_texture(source_path, 0.05, 1.1, 1.15)
	if not _check(not adjusted_path.is_empty(), "No se pudo generar la textura ajustada"):
		return
	if not _check(FileAccess.file_exists(source_path) and FileAccess.file_exists(adjusted_path), "Debe conservar el original y crear la textura ajustada"):
		return
	print("IMAGE_TEST_ADJUSTMENT_OK")

	var result: Dictionary = processor.process_character_image(source_path, 0.16)
	if not _check(result.get("ok", false), "Falló el procesamiento: " + str(result.get("error", ""))):
		return
	print("IMAGE_TEST_PROCESS_OK")
	if not _check(int(result.get("background_removed_pixels", 0)) > 0, "No retiró el fondo conectado al borde"):
		return
	if not _check(result.get("parts", []).size() == 7, "No generó las siete regiones anatómicas; cantidad: " + str(result.get("parts", []).size())):
		return
	if not _check(FileAccess.file_exists(str(result.get("processed_image", ""))), "No guardó la imagen recortada"):
		return
	for part in result.get("parts", []):
		if not _check(FileAccess.file_exists(str(part.get("path", ""))), "No guardó la región: " + str(part.get("name", ""))):
			return
	print("IMAGE_TEST_REGIONS_OK")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(source_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(adjusted_path))
	var output_dir := str(result.get("output_dir", ""))
	if not output_dir.is_empty():
		for part in result.get("parts", []):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(str(part.get("path", ""))))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(str(result.get("processed_image", ""))))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(output_dir))
	print("CHARACTER_IMAGE_PROCESSOR_TESTS_OK")
	quit(0)

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
