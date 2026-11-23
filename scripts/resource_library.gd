extends RefCounted
class_name ResourceLibrary

## Biblioteca local de recursos del proyecto. Los archivos originales se copian
## a user:// y el documento conserva metadatos y rutas relativas.

const CATEGORIES := ["character", "background", "element", "decoration"]
const IMAGE_EXTENSIONS := ["png", "jpg", "jpeg", "webp"]
const MODEL_EXTENSIONS := ["glb", "gltf"]
const MAX_RESOURCE_BYTES := 256 * 1024 * 1024

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
	if not is_resource_size_allowed(bytes):
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
	var dependency_paths: Array = []
	var total_bytes := bytes
	if extension == "gltf":
		var dependency_result: Dictionary = _copy_gltf_dependencies(source_path, relative_path, folder, id, bytes)
		if not bool(dependency_result.get("ok", false)):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(relative_path))
			return dependency_result
		dependency_paths = dependency_result.get("paths", [])
		total_bytes += int(dependency_result.get("bytes", 0))
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
		"bytes": total_bytes,
		"dependency_paths": dependency_paths,
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
	var dependency_paths: Variant = resource.get("dependency_paths", [])
	if dependency_paths is Array:
		for dependency in dependency_paths:
			var dependency_path := str(dependency)
			if dependency_path.begins_with(thumbnail_prefix) and not dependency_path.contains("\\") and not dependency_path.trim_prefix(thumbnail_prefix).contains("../") and FileAccess.file_exists(dependency_path):
				var dependency_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(dependency_path))
				if dependency_error != OK:
					return {"ok": false, "error": "No se pudo limpiar una dependencia del modelo GLTF."}
	var dependency_folder := path.get_base_dir() + "/" + path.get_file().get_basename() + "_deps"
	if dependency_folder.begins_with(thumbnail_prefix) and DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dependency_folder)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dependency_folder))
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

func is_resource_size_allowed(total_bytes: int) -> bool:
	return total_bytes > 0 and total_bytes <= MAX_RESOURCE_BYTES

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
	var dependency_paths: Variant = resource.get("dependency_paths", [])
	if not dependency_paths is Array:
		return {"ok": false, "error": "Las dependencias del recurso deben ser una lista."}
	var dependency_prefix := "user://animation_studio_assets/" + category + "/"
	for dependency in dependency_paths:
		var dependency_path := str(dependency)
		if not dependency_path.begins_with(dependency_prefix) or dependency_path.contains("\\") or dependency_path.contains("../"):
			return {"ok": false, "error": "Una dependencia apunta fuera de la biblioteca administrada."}
	var managed_prefix := "user://animation_studio_assets/" + category + "/"
	if not path.begins_with(managed_prefix) or path.contains("\\"):
		return {"ok": false, "error": "La ruta no pertenece a la carpeta de su categoría."}
	var filename := path.get_file()
	if filename.is_empty() or filename == "." or filename == ".." or path.trim_prefix(managed_prefix).contains("/") or filename.contains(":") or filename.contains("%"):
		return {"ok": false, "error": "La ruta del recurso no es válida."}
	if filename.get_extension().to_lower() != extension:
		return {"ok": false, "error": "La extensión declarada no coincide con el archivo."}
	return {"ok": true}

func update_tags(resource: Dictionary, tags: Variant) -> Dictionary:
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

func _copy_gltf_dependencies(source_path: String, destination_path: String, folder: String, resource_id: String, source_bytes: int) -> Dictionary:
	var source_file := FileAccess.open(source_path, FileAccess.READ)
	if source_file == null:
		return {"ok": false, "error": "No se pudo leer el archivo GLTF."}
	var parsed: Variant = JSON.parse_string(source_file.get_as_text())
	source_file.close()
	if not parsed is Dictionary:
		return {"ok": false, "error": "El archivo GLTF no contiene un documento JSON válido."}
	var dependency_folder := folder + "/" + resource_id + "_deps"
	var copied_paths: Array[String] = []
	var total_bytes := 0
	for section_name in ["buffers", "images"]:
		var section: Variant = parsed.get(section_name, [])
		if not section is Array:
			return _rollback_gltf_dependencies(copied_paths, dependency_folder, "La sección %s del GLTF no es válida." % section_name)
		for entry in section:
			if not entry is Dictionary:
				return _rollback_gltf_dependencies(copied_paths, dependency_folder, "El GLTF contiene una dependencia con estructura inválida.")
			var uri_value := str(entry.get("uri", ""))
			if uri_value.is_empty() or uri_value.begins_with("data:"):
				continue
			var decoded_uri := uri_value.uri_decode()
			if decoded_uri.begins_with("/") or decoded_uri.contains("\\") or decoded_uri.contains(":") or decoded_uri.contains("?") or decoded_uri.contains("#"):
				return _rollback_gltf_dependencies(copied_paths, dependency_folder, "El GLTF contiene una ruta externa o no segura: " + uri_value)
			for segment in decoded_uri.split("/", false):
				if segment == "." or segment == "..":
					return _rollback_gltf_dependencies(copied_paths, dependency_folder, "El GLTF intenta salir de la carpeta de origen: " + uri_value)
			var source_dependency := source_path.get_base_dir().path_join(decoded_uri)
			if not FileAccess.file_exists(source_dependency):
				return _rollback_gltf_dependencies(copied_paths, dependency_folder, "No se encuentra la dependencia GLTF: " + decoded_uri)
			var dependency_file := FileAccess.open(source_dependency, FileAccess.READ)
			if dependency_file == null:
				return _rollback_gltf_dependencies(copied_paths, dependency_folder, "No se pudo leer la dependencia GLTF: " + decoded_uri)
			var dependency_bytes := dependency_file.get_length()
			dependency_file.close()
			total_bytes += dependency_bytes
			if not is_resource_size_allowed(source_bytes + total_bytes):
				return _rollback_gltf_dependencies(copied_paths, dependency_folder, "El modelo GLTF y sus dependencias superan el límite total de 256 MB.")
			var make_dir := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dependency_folder))
			if make_dir != OK and make_dir != ERR_ALREADY_EXISTS:
				return _rollback_gltf_dependencies(copied_paths, dependency_folder, "No se pudo crear la carpeta de dependencias GLTF.")
			var safe_filename := "%d_%s" % [hash(decoded_uri), decoded_uri.get_file().validate_filename()]
			var destination_dependency := dependency_folder + "/" + safe_filename
			var copy_error := DirAccess.copy_absolute(ProjectSettings.globalize_path(source_dependency), ProjectSettings.globalize_path(destination_dependency))
			if copy_error != OK:
				return _rollback_gltf_dependencies(copied_paths, dependency_folder, "No se pudo copiar la dependencia GLTF: " + decoded_uri)
			copied_paths.append(destination_dependency)
			entry["uri"] = resource_id + "_deps/" + safe_filename
		parsed[section_name] = section
	var output := FileAccess.open(destination_path, FileAccess.WRITE)
	if output == null:
		return _rollback_gltf_dependencies(copied_paths, dependency_folder, "No se pudo actualizar el documento GLTF importado.")
	output.store_string(JSON.stringify(parsed))
	output.close()
	return {"ok": true, "paths": copied_paths, "bytes": total_bytes}

func _rollback_gltf_dependencies(paths: Array[String], dependency_folder: String, error_message: String) -> Dictionary:
	for dependency_path in paths:
		if FileAccess.file_exists(dependency_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(dependency_path))
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dependency_folder)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dependency_folder))
	return {"ok": false, "error": error_message}

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
