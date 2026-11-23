extends SceneTree

const LIBRARY = preload("res://scripts/resource_library.gd")

func _initialize() -> void:
	var library = LIBRARY.new()
	assert(library.normalize_category("Personajes") == "character")
	assert(library.normalize_category("Fondos") == "background")
	assert(library.supported_extensions("character").has("glb"))
	assert(not library.supported_extensions("background").has("glb"))
	var valid := {"id":"a1","name":"Bosque","category":"background","path":"user://animation_studio_assets/background/a1.webp","extension":"webp"}
	assert(library.validate_resource(valid).ok)
	assert(not library.validate_resource({"id":"bad","category":"unknown"}).ok)
	var wrong_folder := valid.duplicate(true)
	wrong_folder.path = "user://animation_studio_assets/character/a1.webp"
	assert(not library.validate_resource(wrong_folder).ok, "Debe rechazar recursos guardados en otra categoría")
	var wrong_extension := valid.duplicate(true)
	wrong_extension.extension = "png"
	assert(not library.validate_resource(wrong_extension).ok, "Debe rechazar extensiones que no coinciden con el archivo")
	var traversal_resource := valid.duplicate(true)
	traversal_resource.path = "user://animation_studio_assets/background/../a1.webp"
	assert(not library.validate_resource(traversal_resource).ok, "Debe rechazar rutas con traversal")
	var invalid_tags := valid.duplicate(true)
	invalid_tags.tags = "not-an-array"
	assert(not library.validate_resource(invalid_tags).ok, "Debe exigir etiquetas en formato de lista")
	var invalid_size := valid.duplicate(true)
	invalid_size.bytes = 300 * 1024 * 1024
	assert(not library.validate_resource(invalid_size).ok, "Debe rechazar tamaños declarados fuera del límite")
	var invalid_modes := valid.duplicate(true)
	invalid_modes.compatible_modes = "2D"
	assert(not library.validate_resource(invalid_modes).ok, "Debe exigir modos compatibles en formato de lista")
	var traversal := library.remove_resource({"path":"user://animation_studio_assets/../../important.cfg"})
	assert(not traversal.ok)
	var wrong_category_path := library.remove_resource({"path":"user://animation_studio_assets/unknown/file.webp"})
	assert(not wrong_category_path.ok)
	var records := [
		valid,
		{"id":"a2","name":"Árbol","category":"decoration","tags":["jungle","tree"]}
	]
	assert(library.search(records, "jungla").is_empty())
	assert(library.search(records, "tree").size() == 1)
	assert(library.search(records, "", "Fondos").size() == 1)
	var tag_record := {"id":"tagged","name":"Bosque","category":"background","path":"user://animation_studio_assets/background/tagged.webp","extension":"webp","tags":[]}
	var tag_result: Dictionary = library.update_tags(tag_record, ["Jungla", " bosque ", "JUNGLA", ""])
	assert(tag_result.ok and tag_result.tags.size() == 2, "Las etiquetas deben normalizarse, deduplicarse y omitir valores vacíos")
	assert(tag_record.tags == ["jungla", "bosque"], "Las etiquetas normalizadas deben quedar en el recurso")
	assert(not library.update_tags(tag_record, "texto").ok, "La actualización debe rechazar etiquetas que no sean una lista")
	assert(library.is_compatible({"compatible_modes":["2D"]}, "2D"))
	assert(not library.is_compatible({"compatible_modes":["3D"]}, "2D"))
	var temp_image_path := "user://resource_library_thumbnail_source.png"
	var temp_image := Image.create(320, 160, false, Image.FORMAT_RGBA8)
	temp_image.fill(Color("#e9a23b"))
	assert(temp_image.save_png(temp_image_path) == OK)
	var imported: Dictionary = library.import_file(temp_image_path, "background", "Prueba miniatura")
	assert(imported.ok, "La importación de imagen debe completarse")
	var imported_resource: Dictionary = imported.resource
	var generated_thumbnail := str(imported_resource.get("thumbnail_path", ""))
	assert(not generated_thumbnail.is_empty() and FileAccess.file_exists(generated_thumbnail), "La biblioteca debe generar una miniatura PNG")
	var thumbnail_image := Image.new()
	assert(thumbnail_image.load(generated_thumbnail) == OK)
	assert(thumbnail_image.get_width() == 160 and thumbnail_image.get_height() == 120, "Las miniaturas deben usar un lienzo de 160×120 sin deformar la imagen")
	assert(library.remove_resource(imported_resource).ok, "Eliminar el recurso debe limpiar también su miniatura")
	assert(not FileAccess.file_exists(generated_thumbnail), "La miniatura no debe quedar huérfana")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_image_path))
	print("RESOURCE_LIBRARY_TESTS_OK")
	quit(0)
