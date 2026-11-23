extends RefCounted
class_name ResourceLibrary

## Biblioteca local de recursos del proyecto. Los archivos originales se copian
## a user:// y el documento conserva metadatos y rutas relativas.

const CATEGORIES := ["character", "background", "element", "decoration"]
const IMAGE_EXTENSIONS := ["png", "jpg", "jpeg", "webp"]
const MODEL_EXTENSIONS := ["glb", "gltf"]

func normalize_category(value: String) -> String:
	var key := value.to_lower().strip_edges()
	var aliases := {"personajes":"character", "personaje":"character", "fondos":"background", "fondo":"background", "elementos":"element", "elemento":"element", "decoraciones":"decoration", "decoracion":"decoration", "decoración":"decoration"}
	return str(aliases.get(key, key))

func supported_extensions(category: String) -> Array:
	var key := normalize_category(category)
	if key == "character":
		return IMAGE_EXTENSIONS + MODEL_EXTENSIONS
	if key == "background":
		return IMAGE_EXTENSIONS
	if key == "element" or key == "decoration":
		return IMAGE_EXTENSIONS + MODEL_EXTENSIONS
	return []

func import_file(source_path: String, category: String, display_name := "", tags: Array = [], visual_mode := "2D") -> Dictionary:
	var key := normalize_category(category)
	if not CATEGORIES.has(key):
		return {"ok": false, "error": "Categoría no compatible."}
	var extension := source_path.get_extension().to_lower()
	if not supported_extensions(key).has(extension):
		return {"ok": false, "error": "Formato no compatible para esta biblioteca: ." + extension}
	if not FileAccess.file_exists(source_path):
		return {"ok": false, "error": "No se encuentra el archivo seleccionado."}
	var file := FileAccess.open(source_path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "No se pudo leer el archivo."}
	var bytes := file.get_length()
	file.close()
	if bytes <= 0 or bytes > 256 * 1024 * 1024:
		return {"ok": false, "error": "El archivo está vacío o supera el límite de 256 MB."}
	var id := "asset_%d_%d" % [Time.get_unix_time_from_system(), Time.get_ticks_msec() % 100000]
	var safe_name := (display_name.strip_edges() if not display_name.strip_edges().is_empty() else source_path.get_file().get_basename()).validate_filename()
	if safe_name.is_empty():
		safe_name = id
	var folder := "user://animation_studio_assets/" + key
	var absolute_folder := ProjectSettings.globalize_path(folder)
	var make_dir := DirAccess.make_dir_recursive_absolute(absolute_folder)
	if make_dir != OK and make_dir != ERR_ALREADY_EXISTS:
		return {"ok": false, "error": "No se pudo crear la carpeta de recursos."}
	var relative_path := folder + "/" + id + "." + extension
	var copy_error := DirAccess.copy_absolute(ProjectSettings.globalize_path(source_path), ProjectSettings.globalize_path(relative_path))
	if copy_error != OK:
		return {"ok": false, "error": "No se pudo copiar el recurso al almacenamiento del proyecto."}
	var resource := {
		"id": id,
		"name": safe_name,
		"category": key,
		"source_name": source_path.get_file(),
		"path": relative_path,
		"extension": extension,
		"mime_group": "image" if IMAGE_EXTENSIONS.has(extension) else ("model_3d" if MODEL_EXTENSIONS.has(extension) else "unknown"),
		"bytes": bytes,
		"tags": _clean_tags(tags),
		"visual_mode": visual_mode,
		"compatible_modes": _compatible_modes(extension),
		"created_unix": Time.get_unix_time_from_system(),
		"thumbnail_path": relative_path if IMAGE_EXTENSIONS.has(extension) else ""
	}
	return {"ok": true, "resource": resource}

func remove_resource(resource: Dictionary) -> Dictionary:
	var path := str(resource.get("path", ""))
	const managed_prefix := "user://animation_studio_assets/"
	if path.is_empty() or not path.begins_with(managed_prefix) or path.contains("\\"):
		return {"ok": false, "error": "La ruta del recurso no pertenece a la biblioteca gestionada."}
	var relative_path := path.trim_prefix(managed_prefix)
	var path_parts := relative_path.split("/", false)
	if path_parts.size() != 2 or not CATEGORIES.has(path_parts[0]) or path_parts[1].is_empty() or path_parts[1] == "." or path_parts[1] == "..":
		return {"ok": false, "error": "La ruta del recurso no es una ubicación válida de la biblioteca."}
	if FileAccess.file_exists(path):
		var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		if error != OK:
			return {"ok": false, "error": "No se pudo eliminar el archivo administrado."}
	return {"ok": true}

func search(resources: Array, query: String, category := "") -> Array:
	var result: Array = []
	var needle := query.strip_edges().to_lower()
	var category_key := normalize_category(category)
	for item in resources:
		if not item is Dictionary:
			continue
		if not category_key.is_empty() and str(item.get("category", "")) != category_key:
			continue
		var haystack := (str(item.get("name", "")) + " " + str(item.get("source_name", "")) + " " + " ".join(PackedStringArray(item.get("tags", [])))).to_lower()
		if needle.is_empty() or haystack.contains(needle):
			result.append(item.duplicate(true))
	return result

func validate_resource(resource: Dictionary) -> Dictionary:
	for key in ["id", "name", "category", "path", "extension"]:
		if str(resource.get(key, "")).strip_edges().is_empty():
			return {"ok": false, "error": "Falta el campo obligatorio: " + key}
	var category := str(resource.get("category", ""))
	if not CATEGORIES.has(category):
		return {"ok": false, "error": "Categoría inválida."}
	var extension := str(resource.get("extension", "")).to_lower().trim_prefix(".")
	if not supported_extensions(category).has(extension):
		return {"ok": false, "error": "La extensión no corresponde a la categoría."}
	var path := str(resource.get("path", ""))
	var managed_prefix := "user://animation_studio_assets/" + category + "/"
	if not path.begins_with(managed_prefix) or path.contains("\\"):
		return {"ok": false, "error": "La ruta no pertenece a la carpeta de su categoría."}
	var filename := path.get_file()
	if filename.is_empty() or filename == "." or filename == ".." or path.trim_prefix(managed_prefix).contains("/"):
		return {"ok": false, "error": "La ruta del recurso no es válida."}
	if filename.get_extension().to_lower() != extension:
		return {"ok": false, "error": "La extensión declarada no coincide con el archivo."}
	return {"ok": true}

func is_compatible(resource: Dictionary, visual_mode: String) -> bool:
	var modes_value: Variant = resource.get("compatible_modes", ["2D", "2.5D", "3D", "Híbrido"])
	if not modes_value is Array:
		return visual_mode == "Híbrido"
	return modes_value.has(visual_mode) or visual_mode == "Híbrido"

func _clean_tags(tags: Array) -> Array:
	var result: Array = []
	for tag in tags:
		var value := str(tag).strip_edges().to_lower()
		if not value.is_empty() and not result.has(value):
			result.append(value)
	return result

func _compatible_modes(extension: String) -> Array:
	if IMAGE_EXTENSIONS.has(extension):
		return ["2D", "2.5D", "Híbrido"]
	return ["3D", "Híbrido"]
