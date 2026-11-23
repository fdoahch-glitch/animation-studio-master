extends RefCounted
class_name ProjectDocumentIO

const CURRENT_SCHEMA := 2
const REQUIRED_DEFAULTS := {
	"name": "Mi primera animación",
	"width": 1920,
	"height": 1080,
	"fps": 60,
	"orientation": "Horizontal",
	"visual_mode": "2D",
	"background_mode": "Vacío",
	"scenes": [],
	"characters": [],
	"assets": []
}

func normalize_project(source: Dictionary) -> Dictionary:
	var result := source.duplicate(true)
	for key in REQUIRED_DEFAULTS:
		if not result.has(key):
			result[key] = REQUIRED_DEFAULTS[key].duplicate(true) if REQUIRED_DEFAULTS[key] is Array or REQUIRED_DEFAULTS[key] is Dictionary else REQUIRED_DEFAULTS[key]
	result["schema_version"] = CURRENT_SCHEMA
	result["name"] = str(result.get("name", "Mi animación")).strip_edges()
	if result["name"].is_empty():
		result["name"] = "Mi animación"
	result["width"] = clampi(int(result.get("width", 1920)), 320, 7680)
	result["height"] = clampi(int(result.get("height", 1080)), 320, 7680)
	result["fps"] = clampi(int(result.get("fps", 60)), 1, 120)
	if not result["scenes"] is Array:
		result["scenes"] = []
	if not result["characters"] is Array:
		result["characters"] = []
	if not result["assets"] is Array:
		result["assets"] = []
	var normalized_scenes: Array = []
	for index in range(result["scenes"].size()):
		var raw: Variant = result["scenes"][index]
		if not raw is Dictionary:
			continue
		var scene: Dictionary = raw.duplicate(true)
		scene["id"] = str(scene.get("id", "scene_%03d" % (index + 1)))
		scene["name"] = str(scene.get("name", "Escena %d" % (index + 1))).strip_edges()
		if scene["name"].is_empty():
			scene["name"] = "Escena %d" % (index + 1)
		scene["duration_seconds"] = clampf(float(scene.get("duration_seconds", 10.0)), 0.1, 86400.0)
		if not scene.get("objects", []) is Array:
			scene["objects"] = []
		normalized_scenes.append(scene)
	result["scenes"] = normalized_scenes
	return result

func validate_project(source: Variant) -> Dictionary:
	if not source is Dictionary:
		return {"ok": false, "error": "El documento raíz debe ser un objeto JSON."}
	var version := int(source.get("schema_version", 1))
	if version < 1 or version > CURRENT_SCHEMA:
		return {"ok": false, "error": "Versión de proyecto no compatible: %d." % version}
	for key in ["name", "width", "height", "fps"]:
		if not source.has(key):
			return {"ok": false, "error": "Falta el campo obligatorio: %s." % key}
	if int(source.get("width", 0)) < 1 or int(source.get("height", 0)) < 1:
		return {"ok": false, "error": "La resolución debe ser positiva."}
	if int(source.get("fps", 0)) < 1 or int(source.get("fps", 0)) > 120:
		return {"ok": false, "error": "Los FPS deben estar entre 1 y 120."}
	if source.has("scenes") and not source["scenes"] is Array:
		return {"ok": false, "error": "La lista de escenas debe ser un arreglo."}
	return {"ok": true, "error": ""}

func save_project(path: String, source: Dictionary) -> Dictionary:
	var normalized := normalize_project(source)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "No se pudo escribir el archivo: %s." % path}
	file.store_string(JSON.stringify(normalized, "\t"))
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		return {"ok": false, "error": "No se pudo completar la escritura del proyecto: %s." % path}
	return {"ok": true, "project": normalized, "path": path}

func load_project(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "El archivo no existe: %s." % path}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "No se pudo abrir el archivo: %s." % path}
	var text := file.get_as_text()
	file.close()
	var parser := JSON.new()
	var parse_error := parser.parse(text)
	if parse_error != OK:
		return {"ok": false, "error": "JSON inválido en línea %d: %s." % [parser.get_error_line(), parser.get_error_message()]}
	var validation := validate_project(parser.data)
	if not bool(validation.get("ok", false)):
		return validation
	return {"ok": true, "project": normalize_project(parser.data), "path": path}
