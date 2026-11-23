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
	assert(library.is_compatible({"compatible_modes":["2D"]}, "2D"))
	assert(not library.is_compatible({"compatible_modes":["3D"]}, "2D"))
	print("RESOURCE_LIBRARY_TESTS_OK")
	quit(0)
