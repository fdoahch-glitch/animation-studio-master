extends RefCounted
class_name CharacterPackageIO

const FORMAT_ID := "animation_studio_character_package"
const FORMAT_VERSION := 1
const MAX_FILE_BYTES := 8 * 1024 * 1024

func build_package(character: Dictionary, rig_type: String, joint_angles: Dictionary, procedural_poses: Array, custom_poses: Array, clips: Array, image_data: Dictionary = {}) -> Dictionary:
	return {
		"format": FORMAT_ID,
		"format_version": FORMAT_VERSION,
		"application": "Animation Studio Manager",
		"created_at": Time.get_datetime_string_from_system(true),
		"character": character.duplicate(true),
		"rig": {
			"type": rig_type,
			"joint_angles_degrees": _clean_angles(joint_angles)
		},
		"procedural_poses": procedural_poses.duplicate(true),
		"custom_poses": custom_poses.duplicate(true),
		"animation_clips": clips.duplicate(true),
		"image_import": _portable_image_metadata(image_data),
		"asset_note": "Las rutas de imágenes son locales al equipo de origen. Copia los archivos fuente por separado para conservar las texturas."
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
	if not clips is Array or not poses is Array or not custom is Array:
		return {"ok": false, "error": "Las bibliotecas de poses o animaciones tienen un formato inválido."}
	var normalized := parsed.duplicate(true)
	normalized["rig"]["joint_angles_degrees"] = _clean_angles(rig.get("joint_angles_degrees", {}))
	normalized["animation_clips"] = _clean_clips(clips)
	normalized["procedural_poses"] = _clean_poses(poses)
	normalized["custom_poses"] = _clean_poses(custom)
	return {"ok": true, "package": normalized}

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

func _portable_image_metadata(value: Dictionary) -> Dictionary:
	if value.is_empty():
		return {}
	var parts: Array = []
	for part in value.get("parts", []):
		if part is Dictionary:
			parts.append({
				"name": str(part.get("name", "")),
				"rect": part.get("rect", []).duplicate(true) if part.get("rect", []) is Array else []
			})
	return {
		"width": int(value.get("width", 0)),
		"height": int(value.get("height", 0)),
		"parts": parts,
		"source_file_name": str(value.get("source_path", "")).get_file()
	}
