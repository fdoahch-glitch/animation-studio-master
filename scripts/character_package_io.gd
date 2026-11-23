extends RefCounted
class_name CharacterPackageIO

const FORMAT_ID := "animation_studio_character_package"
const FORMAT_VERSION := 1
const MAX_FILE_BYTES := 32 * 1024 * 1024
const MAX_ASSET_BYTES := 20 * 1024 * 1024

func build_package(character: Dictionary, rig_type: String, joint_angles: Dictionary, procedural_poses: Array, custom_poses: Array, clips: Array, image_data: Dictionary = {}, spatial_poses: Array = [], spatial_clips: Array = [], spatial_bone_rotations: Dictionary = {}, model_path: String = "") -> Dictionary:
	return {
		"format": FORMAT_ID,
		"format_version": FORMAT_VERSION,
		"application": "Animation Studio Manager",
		"created_at": Time.get_datetime_string_from_system(true),
		"character": character.duplicate(true),
		"rig": {
			"type": rig_type,
			"joint_angles_degrees": _clean_angles(joint_angles),
			"bone_rotations_degrees": _clean_bone_rotations(spatial_bone_rotations),
			"model_asset": _model_asset_key(image_data, model_path)
		},
		"procedural_poses": procedural_poses.duplicate(true),
		"custom_poses": custom_poses.duplicate(true),
		"animation_clips": clips.duplicate(true),
		"spatial_poses": _clean_spatial_poses(spatial_poses),
		"spatial_animation_clips": _clean_spatial_clips(spatial_clips),
		"image_import": _portable_image_metadata(image_data),
		"assets": _collect_image_assets(image_data, model_path),
		"asset_note": "Las imágenes y modelos GLB autocontenidos se incluyen si caben en el límite. Los archivos glTF externos requieren conservar sus archivos acompañantes."
	}

func encode_package(package_data: Dictionary) -> String:
	return JSON.stringify(package_data, "\t", false)

func decode_package(json_text: String) -> Dictionary:
	if json_text.is_empty() or json_text.to_utf8_buffer().size() > MAX_FILE_BYTES:
		return {"ok": false, "error": "El archivo está vacío o supera el límite de 8 MB."}
	var parsed: Variant = JSON.parse_string(json_text)
	if not parsed is Dictionary:
		return {"ok": false, "error": "El archivo no contiene un paquete JSON válido."}
	if str(parsed.get("format", "")) != FORMAT_ID:
		return {"ok": false, "error": "El archivo no es un paquete de personaje de Animation Studio."}
	var version := int(parsed.get("format_version", 0))
	if version < 1 or version > FORMAT_VERSION:
		return {"ok": false, "error": "Versión de paquete no compatible: %d." % version}
	var character: Variant = parsed.get("character", {})
	var rig: Variant = parsed.get("rig", {})
	if not character is Dictionary or not rig is Dictionary:
		return {"ok": false, "error": "La estructura del personaje o del rig está dañada."}
	var clips: Variant = parsed.get("animation_clips", [])
	var poses: Variant = parsed.get("procedural_poses", [])
	var custom: Variant = parsed.get("custom_poses", [])
	var assets: Variant = parsed.get("assets", {})
	var spatial_poses: Variant = parsed.get("spatial_poses", [])
	var spatial_clips: Variant = parsed.get("spatial_animation_clips", [])
	if not clips is Array or not poses is Array or not custom is Array or not assets is Dictionary or not spatial_poses is Array or not spatial_clips is Array:
		return {"ok": false, "error": "Las bibliotecas de poses o animaciones tienen un formato inválido."}
	var normalized := parsed.duplicate(true)
	normalized["rig"]["joint_angles_degrees"] = _clean_angles(rig.get("joint_angles_degrees", {}))
	normalized["rig"]["bone_rotations_degrees"] = _clean_bone_rotations(rig.get("bone_rotations_degrees", {}))
	normalized["spatial_poses"] = _clean_spatial_poses(spatial_poses)
	normalized["spatial_animation_clips"] = _clean_spatial_clips(spatial_clips)
	normalized["animation_clips"] = _clean_clips(clips)
	normalized["procedural_poses"] = _clean_poses(poses)
	normalized["custom_poses"] = _clean_poses(custom)
	var asset_total := 0
	for asset_key in assets.keys():
		if not assets[asset_key] is String:
			return {"ok": false, "error": "Un recurso gráfico tiene un formato inválido."}
		var decoded_bytes := Marshalls.base64_to_raw(str(assets[asset_key]))
		asset_total += decoded_bytes.size()
		if decoded_bytes.is_empty() or asset_total > MAX_ASSET_BYTES:
			return {"ok": false, "error": "Los recursos gráficos están vacíos o superan el límite de 20 MB."}
	return {"ok": true, "package": normalized}


func _clean_bone_rotations(value: Variant) -> Dictionary:
	var result := {}
	if not value is Dictionary:
		return result
	for bone_name in value.keys():
		var rotation_value: Variant = value[bone_name]
		if rotation_value is Array and rotation_value.size() >= 3:
			result[str(bone_name).left(64)] = [
				clampf(float(rotation_value[0]), -180.0, 180.0),
				clampf(float(rotation_value[1]), -180.0, 180.0),
				clampf(float(rotation_value[2]), -180.0, 180.0)
			]
	return result

func _clean_spatial_poses(value: Array) -> Array:
	var result: Array = []
	for item in value:
		if item is Dictionary:
			result.append({
				"name": str(item.get("name", "Pose 3D")).left(80),
				"bone_rotations_degrees": _clean_bone_rotations(item.get("bone_rotations_degrees", {})),
				"custom": bool(item.get("custom", false))
			})
	return result

func _clean_spatial_clips(value: Array) -> Array:
	var result: Array = []
	for item in value:
		if not item is Dictionary:
			continue
		var duration := clampf(float(item.get("duration", 1.0)), 0.05, 120.0)
		var frames: Array = []
		var raw_frames: Variant = item.get("keyframes", [])
		if raw_frames is Array:
			for frame in raw_frames:
				if frame is Dictionary:
					frames.append({
						"time": clampf(float(frame.get("time", 0.0)), 0.0, duration),
						"bone_rotations_degrees": _clean_bone_rotations(frame.get("bone_rotations_degrees", {}))
					})
		result.append({
			"name": str(item.get("name", "Animación 3D")).left(80),
			"duration": duration,
			"loop": bool(item.get("loop", true)),
			"keyframes": frames
		})
	return result

func _clean_angles(value: Variant) -> Dictionary:
	var result := {}
	if not value is Dictionary:
		return result
	for key in value.keys():
		if str(key).length() > 64:
			continue
		var angle := float(value[key])
		if is_finite(angle):
			result[str(key)] = clampf(angle, -180.0, 180.0)
	return result

func _clean_clips(value: Array) -> Array:
	var result: Array = []
	for item in value:
		if not item is Dictionary:
			continue
		var duration := clampf(float(item.get("duration", 1.0)), 0.05, 120.0)
		var frames: Array = []
		var raw_frames: Variant = item.get("keyframes", [])
		if raw_frames is Array:
			for frame in raw_frames:
				if frame is Dictionary:
					frames.append({
						"time": clampf(float(frame.get("time", 0.0)), 0.0, duration),
						"joint_angles": _clean_angles(frame.get("joint_angles", {}))
					})
		result.append({
			"name": str(item.get("name", "Animación")).left(80),
			"duration": duration,
			"loop": bool(item.get("loop", true)),
			"keyframes": frames
		})
	return result

func _clean_poses(value: Array) -> Array:
	var result: Array = []
	for item in value:
		if item is Dictionary:
			result.append({
				"name": str(item.get("name", "Pose")).left(80),
				"joint_angles": _clean_angles(item.get("joint_angles", {})),
				"custom": bool(item.get("custom", false))
			})
	return result


func _model_asset_key(image_data: Dictionary, model_path: String) -> String:
	if model_path == "" or model_path.get_extension().to_lower() != "glb":
		return ""
	var index := 0
	if str(image_data.get("source", "")) != "":
		index += 1
	if str(image_data.get("processed_image", "")) != "":
		index += 1
	for part in image_data.get("parts", []):
		if part is Dictionary and str(part.get("path", "")) != "":
			index += 1
	return "asset_%02d_%s" % [index, model_path.get_file().validate_filename()]

func _collect_image_assets(image_data: Dictionary, model_path: String = "") -> Dictionary:
	var assets := {}
	var candidates: Array[String] = []
	var source_path := str(image_data.get("source", ""))
	var processed_path := str(image_data.get("processed_image", ""))
	if source_path != "":
		candidates.append(source_path)
	if processed_path != "":
		candidates.append(processed_path)
	for part in image_data.get("parts", []):
		if part is Dictionary and str(part.get("path", "")) != "":
			candidates.append(str(part.get("path", "")))
	if model_path != "" and model_path.get_extension().to_lower() == "glb":
		candidates.append(model_path)
	var total_bytes := 0
	for index in range(candidates.size()):
		var source := candidates[index]
		var bytes := FileAccess.get_file_as_bytes(source)
		if bytes.is_empty():
			continue
		total_bytes += bytes.size()
		if total_bytes > MAX_ASSET_BYTES:
			return {}
		var key := "asset_%02d_%s" % [index, source.get_file().validate_filename()]
		assets[key] = Marshalls.raw_to_base64(bytes)
	return assets

func restore_image_assets(package_data: Dictionary, target_directory: String) -> Dictionary:
	var metadata: Dictionary = package_data.get("image_import", {})
	var assets: Dictionary = package_data.get("assets", {})
	if assets.is_empty():
		return {}
	var absolute_dir := ProjectSettings.globalize_path(target_directory)
	if DirAccess.make_dir_recursive_absolute(absolute_dir) != OK:
		return {}
	var restored_paths := {}
	for key in assets.keys():
		var safe_name := str(key).validate_filename()
		if safe_name == "":
			continue
		var output_path := target_directory.path_join(safe_name)
		var bytes := Marshalls.base64_to_raw(str(assets[key]))
		if bytes.is_empty():
			continue
		var file := FileAccess.open(output_path, FileAccess.WRITE)
		if file == null:
			continue
		file.store_buffer(bytes)
		file.close()
		restored_paths[str(key)] = output_path
	var result := {
		"width": int(metadata.get("width", 0)),
		"height": int(metadata.get("height", 0)),
		"output_dir": target_directory,
		"parts": [],
		"model_path": ""
	}
	var source_key := str(metadata.get("source_asset", ""))
	var processed_key := str(metadata.get("processed_asset", ""))
	result["source"] = str(restored_paths.get(source_key, ""))
	result["processed_image"] = str(restored_paths.get(processed_key, ""))
	var model_asset_key := str(package_data.get("rig", {}).get("model_asset", ""))
	result["model_path"] = str(restored_paths.get(model_asset_key, ""))
	for part in metadata.get("parts", []):
		if part is Dictionary:
			var part_copy: Dictionary = part.duplicate(true)
			part_copy["path"] = str(restored_paths.get(str(part.get("asset", "")), ""))
			if part_copy["path"] != "":
				result["parts"].append(part_copy)
	return result

func _portable_image_metadata(value: Dictionary) -> Dictionary:
	if value.is_empty():
		return {}
	var parts: Array = []
	var source_index := 0 if str(value.get("source", "")) != "" else -1
	var processed_index := 1 if str(value.get("source", "")) != "" and str(value.get("processed_image", "")) != "" else (0 if str(value.get("processed_image", "")) != "" else -1)
	var next_asset_index := 0
	if source_index >= 0:
		next_asset_index += 1
	if processed_index >= 0:
		next_asset_index += 1
	for part in value.get("parts", []):
		if part is Dictionary:
			var part_record := {
				"name": str(part.get("name", "")),
				"rect": part.get("rect", []).duplicate(true) if part.get("rect", []) is Array else [],
				"asset": "asset_%02d_%s" % [next_asset_index, str(part.get("path", "")).get_file().validate_filename()]
			}
			parts.append(part_record)
			next_asset_index += 1
	return {
		"width": int(value.get("width", 0)),
		"height": int(value.get("height", 0)),
		"parts": parts,
		"source_asset": "asset_00_%s" % str(value.get("source", "").get_file().validate_filename()) if source_index >= 0 else "",
		"processed_asset": "asset_%02d_%s" % [processed_index, str(value.get("processed_image", "").get_file().validate_filename())] if processed_index >= 0 else ""
	}
