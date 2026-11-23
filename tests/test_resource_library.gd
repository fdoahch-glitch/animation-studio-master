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
