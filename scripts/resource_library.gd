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
	var thumbnail_path := ""
	if IMAGE_EXTENSIONS.has(extension):
		thumbnail_path = folder + "/" + id + ".thumb.png"
		if not _create_thumbnail(relative_path, thumbnail_path):
			thumbnail_path = ""
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
		"thumbnail_path": thumbnail_path
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
	var thumbnail_path := str(resource.get("thumbnail_path", ""))
	var thumbnail_prefix := "user://animation_studio_assets/" + path_parts[0] + "/"
	if thumbnail_path.begins_with(thumbnail_prefix) and not thumbnail_path.contains("\\") and not thumbnail_path.trim_prefix(thumbnail_prefix).contains("/") and thumbnail_path.get_extension().to_lower() == "png" and FileAccess.file_exists(thumbnail_path):
		var thumbnail_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(thumbnail_path))
		if thumbnail_error != OK:
			return {"ok": false, "error": "Se eliminó el recurso, pero no se pudo limpiar su miniatura."}
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
	var bytes_value: Variant = resource.get("bytes", 0)
	if not (bytes_value is int or bytes_value is float) or float(bytes_value) < 0.0 or float(bytes_value) > 256.0 * 1024.0 * 1024.0:
		return {"ok": false, "error": "El tamaño declarado del recurso no es válido."}
	var tags_value: Variant = resource.get("tags", [])
	if not tags_value is Array:
		return {"ok": false, "error": "Las etiquetas deben ser una lista."}
	for tag in tags_value:
		if str(tag).strip_edges().is_empty():
			return {"ok": false, "error": "Las etiquetas no pueden estar vacías."}
	var modes_value: Variant = resource.get("compatible_modes", _compatible_modes(extension))
	if not modes_value is Array:
		return {"ok": false, "error": "Los modos compatibles deben ser una lista."}
	var managed_prefix := "user://animation_studio_assets/" + category + "/"
	if not path.begins_with(managed_prefix) or path.contains("\\"):
		return {"ok": false, "error": "La ruta no pertenece a la carpeta de su categoría."}
	var filename := path.get_file()
	if filename.is_empty() or filename == "." or filename == ".." or path.trim_prefix(managed_prefix).contains("/") or filename.contains(":") or filename.contains("%"):
		return {"ok": false, "error": "La ruta del recurso no es válida."}
	if filename.get_extension().to_lower() != extension:
		return {"ok": false, "error": "La extensión declarada no coincide con el archivo."}
	return {"ok": true}

func update_tags(resource: Dictionary, tags: Array) -> Dictionary:
	if resource.is_empty() or not tags is Array:
		return {"ok": false, "error": "Selecciona un recurso y proporciona una lista de etiquetas."}
	var normalized := _clean_tags(tags)
	resource["tags"] = normalized
	var validation := validate_resource(resource)
	if not bool(validation.get("ok", false)):
		return validation
	return {"ok": true, "tags": normalized}

func is_compatible(resource: Dictionary, visual_mode: String) -> bool:
	var modes_value: Variant = resource.get("compatible_modes", ["2D", "2.5D", "3D", "Híbrido"])
	if not modes_value is Array:
		return visual_mode == "Híbrido"
	return modes_value.has(visual_mode) or visual_mode == "Híbrido"

func _create_thumbnail(source_path: String, thumbnail_path: String) -> bool:
	var source := Image.new()
	if source.load(source_path) != OK or source.is_empty():
		return false
	var source_size := source.get_size()
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		return false
	var scale := minf(1.0, minf(160.0 / source_size.x, 120.0 / source_size.y))
	var target_size := Vector2i(maxi(1, int(round(source_size.x * scale))), maxi(1, int(round(source_size.y * scale))))
	if source_size.x != float(target_size.x) or source_size.y != float(target_size.y):
		source.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
	var thumbnail := Image.create(160, 120, false, Image.FORMAT_RGBA8)
	thumbnail.fill(Color("#17283a"))
	var offset := Vector2i((160 - target_size.x) / 2, (120 - target_size.y) / 2)
	thumbnail.blit_rect(source, Rect2i(Vector2i.ZERO, target_size), offset)
	return thumbnail.save_png(thumbnail_path) == OK

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
