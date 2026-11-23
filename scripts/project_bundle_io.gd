extends RefCounted
class_name ProjectBundleIO

const FORMAT := "animation_studio_project_bundle"
const VERSION := 1
const MAX_ARCHIVE_FILES := 10000
const MAX_TOTAL_BYTES := 1024 * 1024 * 1024

func export_bundle(path: String, project: Dictionary) -> Dictionary:
	var writer: ZIPPacker = ZIPPacker.new()
	var error: int = writer.open(path)
	if error != OK:
		return {"ok": false, "error": "No se pudo crear el archivo ZIP: %s" % error}
	var manifest := {"format": FORMAT, "version": VERSION, "created_at": Time.get_datetime_string_from_system(true), "project": project.duplicate(true), "assets": []}
	var seen := {}
	var total := 0
	var sources: Array[Dictionary] = []
	for resource in project.get("resources", []):
		if not resource is Dictionary:
			writer.close()
			_remove_partial_bundle(path)
			return {"ok": false, "error": "La lista de recursos contiene una entrada inválida."}
		var resource_path := str(resource.get("path", ""))
		if not resource_path.is_empty():
			sources.append({"path": resource_path, "resource_id": str(resource.get("id", ""))})
	for dialogue_script in project.get("dialogue_scripts", []):
		if not dialogue_script is Dictionary:
			continue
		for take in dialogue_script.get("audio_tracks", []):
			if take is Dictionary:
				var audio_path := str(take.get("audio_path", ""))
				if not audio_path.is_empty():
					sources.append({"path": audio_path, "resource_id": ""})
	var video_timeline: Dictionary = project.get("video_timeline", {})
	for track in video_timeline.get("tracks", []):
		if not track is Dictionary:
			continue
		for clip in track.get("clips", []):
			if clip is Dictionary:
				var media_path := str(clip.get("source", ""))
				if not media_path.is_empty():
					sources.append({"path": media_path, "resource_id": ""})
	for source_item in sources:
		var source := str(source_item.get("path", ""))
		if source.is_empty() or seen.has(source):
			continue
		seen[source] = true
		if not FileAccess.file_exists(source):
			writer.close()
			_remove_partial_bundle(path)
			return {"ok": false, "error": "No se encuentra un archivo del proyecto: %s" % source}
		var bytes := FileAccess.get_file_as_bytes(source)
		if bytes.is_empty():
			writer.close()
			_remove_partial_bundle(path)
			return {"ok": false, "error": "No se pudo leer un archivo del proyecto: %s" % source}
		total += bytes.size()
		if total > MAX_TOTAL_BYTES:
			writer.close()
			_remove_partial_bundle(path)
			return {"ok": false, "error": "El proyecto supera el límite de 1 GB de recursos."}
		var entry := "assets/%04d_%s" % [manifest.assets.size(), source.get_file().validate_filename()]
		error = writer.start_file(entry)
		if error != OK:
			writer.close()
			_remove_partial_bundle(path)
			return {"ok": false, "error": "No se pudo iniciar la escritura de un archivo: %s" % error}
		error = writer.write_file(bytes)
		if error != OK:
			writer.close()
			_remove_partial_bundle(path)
			return {"ok": false, "error": "No se pudo escribir un archivo en el paquete: %s" % error}
		var digest := _sha256(bytes)
		if digest.is_empty():
			writer.close()
			_remove_partial_bundle(path)
			return {"ok": false, "error": "No se pudo calcular la huella de un recurso."}
		manifest.assets.append({"source_path": source, "entry": entry, "resource_id": str(source_item.get("resource_id", "")), "size_bytes": bytes.size(), "sha256": digest})
	error = writer.start_file("project_manifest.json")
	if error == OK:
		error = writer.write_file(JSON.stringify(manifest, "\t").to_utf8_buffer())
	writer.close()
	if error != OK:
		_remove_partial_bundle(path)
		return {"ok": false, "error": "No se pudo escribir el manifiesto del paquete: %s" % error}
	return {"ok": true, "asset_count": manifest.assets.size(), "bytes": total, "path": path}

func import_bundle(path: String, destination: String) -> Dictionary:
	var reader := ZIPReader.new()
	var error := reader.open(path)
	if error != OK:
		return {"ok": false, "error": "No se pudo abrir el paquete ZIP."}
	var names := reader.get_files()
	if names.size() > MAX_ARCHIVE_FILES or not names.has("project_manifest.json"):
		reader.close()
		return {"ok": false, "error": "Paquete inválido o con demasiados archivos."}
	var manifest_bytes := reader.read_file("project_manifest.json")
	if manifest_bytes.is_empty():
		reader.close()
		return {"ok": false, "error": "El manifiesto del paquete está vacío o no se puede leer."}
	var parsed: Variant = JSON.parse_string(manifest_bytes.get_string_from_utf8())
	if not parsed is Dictionary:
		reader.close()
		return {"ok": false, "error": "Manifiesto de proyecto incompatible."}
	var validation := validate_bundle_manifest(parsed)
	if not bool(validation.get("ok", false)):
		reader.close()
		return {"ok": false, "error": str(validation.get("error", "Manifiesto inválido."))}
	var project: Dictionary = parsed.project
	var assets: Array = parsed.assets
	if assets.size() > MAX_ARCHIVE_FILES - 1 or names.size() != assets.size() + 1:
		reader.close()
		return {"ok": false, "error": "El paquete contiene entradas no declaradas o demasiados recursos."}
	var seen_entries := {}
	var seen_sources := {}
	var total := 0
	var pending := []
	for item in assets:
		var entry := str(item.entry)
		var source := str(item.source_path)
		if not _is_safe_asset_entry(entry) or source.is_empty() or seen_entries.has(entry) or seen_sources.has(source) or not names.has(entry):
			reader.close()
			return {"ok": false, "error": "Ruta de recurso ausente, duplicada o no permitida en el paquete."}
		seen_entries[entry] = true
		seen_sources[source] = true
		var bytes := reader.read_file(entry)
		if bytes.is_empty():
			reader.close()
			return {"ok": false, "error": "No se pudo leer un recurso del paquete: %s" % entry}
		if item.has("size_bytes") and int(item.get("size_bytes", -1)) != bytes.size():
			reader.close()
			return {"ok": false, "error": "El tamaño de un recurso no coincide con el manifiesto: %s" % entry}
		if item.has("sha256") and str(item.get("sha256", "")).to_lower() != _sha256(bytes):
			reader.close()
			return {"ok": false, "error": "La huella SHA-256 de un recurso no coincide: %s" % entry}
		total += bytes.size()
		if total > MAX_TOTAL_BYTES:
			reader.close()
			return {"ok": false, "error": "Los recursos exceden el límite de 1 GB."}
		pending.append({"source": source, "entry": entry, "bytes": bytes})
	reader.close()

	var base := ProjectSettings.globalize_path(destination)
	if DirAccess.make_dir_recursive_absolute(base) != OK:
		return {"ok": false, "error": "No se pudo crear la carpeta de destino."}
	var restored := {}
	var created_files: Array[String] = []
	for asset in pending:
		var filename := str(asset.entry).get_file()
		var output := destination.path_join(filename)
		var absolute := ProjectSettings.globalize_path(output)
		if FileAccess.file_exists(output):
			_remove_created_bundle_files(created_files)
			return {"ok": false, "error": "Ya existe un archivo de destino y no se sobrescribirá: %s" % filename}
		var file := FileAccess.open(output, FileAccess.WRITE)
		if file == null:
			_remove_created_bundle_files(created_files)
			return {"ok": false, "error": "No se pudo restaurar un recurso del proyecto."}
		file.store_buffer(asset.bytes)
		var write_error := file.get_error()
		file.close()
		if write_error != OK:
			DirAccess.remove_absolute(absolute)
			_remove_created_bundle_files(created_files)
			return {"ok": false, "error": "Falló la escritura de un recurso restaurado."}
		created_files.append(absolute)
		restored[str(asset.source)] = output
	for resource in project.get("resources", []):
		if resource is Dictionary:
			var old := str(resource.get("path", ""))
			if restored.has(old):
				resource["path"] = restored[old]
	for dialogue_script in project.get("dialogue_scripts", []):
		if not dialogue_script is Dictionary:
			continue
		for take in dialogue_script.get("audio_tracks", []):
			if take is Dictionary:
				var old_audio := str(take.get("audio_path", ""))
				if restored.has(old_audio):
					take["audio_path"] = restored[old_audio]
	var imported_video_timeline: Dictionary = project.get("video_timeline", {})
	for track in imported_video_timeline.get("tracks", []):
		if not track is Dictionary:
			continue
		for clip in track.get("clips", []):
			if clip is Dictionary:
				var old_media := str(clip.get("source", ""))
				if restored.has(old_media):
					clip["source"] = restored[old_media]
	if project.has("video_timeline"):
		project["video_timeline"] = imported_video_timeline
	return {"ok": true, "project": project, "asset_count": restored.size(), "bytes": total, "restored_paths": restored}

func validate_bundle_manifest(manifest: Dictionary) -> Dictionary:
	if str(manifest.get("format", "")) != FORMAT or int(manifest.get("version", 0)) != VERSION:
		return {"ok": false, "error": "Formato o versión de paquete inválida."}
	if not manifest.get("project", {}) is Dictionary or not manifest.get("assets", []) is Array:
		return {"ok": false, "error": "Manifiesto incompleto."}
	var assets: Array = manifest.assets
	if assets.size() > MAX_ARCHIVE_FILES - 1:
		return {"ok": false, "error": "El manifiesto declara demasiados recursos."}
	var entries := {}
	var sources := {}
	for item in assets:
		if not item is Dictionary:
			return {"ok": false, "error": "El manifiesto contiene un recurso inválido."}
		var entry := str(item.get("entry", ""))
		var source := str(item.get("source_path", ""))
		if not _is_safe_asset_entry(entry) or source.is_empty() or entries.has(entry) or sources.has(source):
			return {"ok": false, "error": "El manifiesto contiene rutas vacías, duplicadas o no permitidas."}
		if item.has("size_bytes") and int(item.get("size_bytes", -1)) < 0:
			return {"ok": false, "error": "El manifiesto declara un tamaño de recurso inválido."}
		if item.has("sha256"):
			var digest := str(item.get("sha256", ""))
			if digest.length() != 64 or digest.to_lower() != digest or not digest.is_valid_hex_number(false):
				return {"ok": false, "error": "El manifiesto contiene una huella SHA-256 inválida."}
		entries[entry] = true
		sources[source] = true
	return {"ok": true}

func _is_safe_asset_entry(entry: String) -> bool:
	if not entry.begins_with("assets/") or entry.contains("\\") or entry.contains("..") or entry.contains(":"):
		return false
	var filename := entry.trim_prefix("assets/")
	return not filename.is_empty() and not filename.contains("/") and filename != "." and filename != ".." and filename == filename.validate_filename()

func _sha256(bytes: PackedByteArray) -> String:
	var hashing := HashingContext.new()
	if hashing.start(HashingContext.HASH_SHA256) != OK:
		return ""
	if hashing.update(bytes) != OK:
		return ""
	return hashing.finish().hex_encode()

func _remove_partial_bundle(path: String) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _remove_created_bundle_files(paths: Array[String]) -> void:
	for path in paths:
		DirAccess.remove_absolute(path)
