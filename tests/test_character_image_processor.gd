extends SceneTree

const PROCESSOR = preload("res://scripts/character_image_processor.gd")

func _initialize() -> void:
	var processor = PROCESSOR.new()
	var source_path := "user://character_image_processor_test.png"
	var image := Image.create(128, 160, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	for y in range(18, 145):
		for x in range(28, 101):
			var dx := (float(x) - 64.0) / 34.0
			var dy := (float(y) - 82.0) / 63.0
			if dx * dx + dy * dy <= 1.0:
				image.set_pixel(x, y, Color("#2478b8"))
	assert(image.save_png(source_path) == OK, "Debe crear la imagen sintética de prueba")

	var adjusted_path: String = processor.create_adjusted_texture(source_path, 0.05, 1.1, 1.15)
	assert(not adjusted_path.is_empty(), "Debe generar una textura ajustada sin modificar el original")
	assert(FileAccess.file_exists(source_path), "La imagen original debe conservarse")
	assert(FileAccess.file_exists(adjusted_path), "La textura ajustada debe existir")

	var result: Dictionary = processor.process_character_image(adjusted_path, 0.16)
	assert(result.get("ok", false), "Debe procesar la silueta sintética: " + str(result.get("error", "")))
	assert(int(result.get("background_removed_pixels", 0)) > 0, "Debe retirar el fondo conectado al borde")
	assert(result.get("parts", []).size() == 7, "Debe preparar las siete regiones anatómicas aproximadas")
	assert(FileAccess.file_exists(str(result.get("processed_image", ""))), "Debe guardar la imagen recortada")
	for part in result.get("parts", []):
		assert(FileAccess.file_exists(str(part.get("path", ""))), "Cada región anatómica debe guardarse")

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
