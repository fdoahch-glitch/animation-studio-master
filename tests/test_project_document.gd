extends SceneTree

const PROJECT_IO = preload("res://scripts/project_document_io.gd")

func _initialize() -> void:
	var io = PROJECT_IO.new()
	var legacy := {
		"schema_version": 1,
		"name": "Prueba de proyecto",
		"width": 1920,
		"height": 1080,
		"fps": 60,
		"scenes": [{"name":"Escena inicial","duration_seconds":12.0}]
	}
	var validation: Dictionary = io.validate_project(legacy)
	assert(validation.get("ok", false), "El proyecto legado válido debe pasar")
	var normalized: Dictionary = io.normalize_project(legacy)
	assert(normalized.schema_version == PROJECT_IO.CURRENT_SCHEMA)
	assert(normalized.scenes.size() == 1)
	assert(normalized.scenes[0].id == "scene_001")
	assert(normalized.scenes[0].duration_seconds == 12.0)
	var path := "user://project_document_roundtrip.amsproj"
	var saved: Dictionary = io.save_project(path, legacy)
	assert(saved.get("ok", false), "Debe guardar el proyecto")
	var loaded: Dictionary = io.load_project(path)
	assert(loaded.get("ok", false), "Debe cargar el proyecto guardado")
	assert(loaded.project.name == "Prueba de proyecto")
	assert(loaded.project.scenes.size() == 1)
	var invalid := io.validate_project({"name":"mal","width":100,"height":100,"fps":240})
	assert(not invalid.get("ok", true), "Debe rechazar FPS fuera de rango")
	var invalid_resolution := io.validate_project({"name":"Resolución inválida","width":100,"height":1080,"fps":60})
	assert(not invalid_resolution.get("ok", true), "Debe rechazar resoluciones inferiores al mínimo")
	var invalid_name := io.validate_project({"name":"   ","width":1920,"height":1080,"fps":60})
	assert(not invalid_name.get("ok", true), "Debe rechazar nombres vacíos")
	var invalid_assets := io.validate_project({"name":"Proyecto","width":1920,"height":1080,"fps":60,"assets":{}})
	assert(not invalid_assets.get("ok", true), "Debe rechazar una lista de recursos con formato incorrecto")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("PROJECT_DOCUMENT_TESTS_OK")
	quit(0)
