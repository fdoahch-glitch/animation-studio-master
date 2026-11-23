extends RefCounted
class_name VideoTimeline

## Modelo de montaje audiovisual multipista. Los tiempos se expresan en segundos.

const TRACK_TYPES := ["video", "audio", "title", "overlay", "effect"]
const MIN_CLIP_DURATION := 0.04

var _clip_sequence: int = 0

func create_timeline(fps: int = 30) -> Dictionary:
	return {"version": 1, "fps": clampi(fps, 1, 120), "tracks": [], "duration": 0.0}

func create_track(timeline: Dictionary, track_type: String, label: String = "") -> Dictionary:
	if not TRACK_TYPES.has(track_type):
		return {"ok": false, "error": "Tipo de pista no admitido."}
	var tracks: Array = timeline.get("tracks", [])
	var track := {"id": "track_%d" % Time.get_ticks_usec(), "name": label.strip_edges() if not label.strip_edges().is_empty() else _default_track_name(track_type, tracks), "type": track_type, "muted": false, "locked": false, "visible": true, "clips": []}
	tracks.append(track)
	timeline["tracks"] = tracks
	return {"ok": true, "track": track}

func add_clip(track: Dictionary, source: String, start: float, duration: float, options: Dictionary = {}) -> Dictionary:
	if bool(track.get("locked", false)):
		return {"ok": false, "error": "La pista está bloqueada."}
	if not TRACK_TYPES.has(str(track.get("type", ""))):
		return {"ok": false, "error": "La pista no tiene un tipo válido."}
	if source.strip_edges().is_empty() or not _is_finite(start) or not _is_finite(duration):
		return {"ok": false, "error": "El origen y los tiempos del clip deben ser válidos y finitos."}
	var source_in := float(options.get("source_in", 0.0))
	var volume := float(options.get("volume", 1.0))
	var opacity := float(options.get("opacity", 1.0))
	if not _is_finite(source_in) or not _is_finite(volume) or not _is_finite(opacity):
		return {"ok": false, "error": "Los parámetros de origen y mezcla deben ser finitos."}
	var metadata_value: Variant = options.get("metadata", {})
	if not metadata_value is Dictionary:
		return {"ok": false, "error": "Los metadatos del clip deben ser un objeto."}
	var clip_duration := maxf(MIN_CLIP_DURATION, duration)
	var clip := {"id": _next_clip_id(), "source": source, "name": str(options.get("name", source.get_file() if source.contains("/") else source)), "start": maxf(0.0, start), "duration": clip_duration, "source_in": maxf(0.0, source_in), "volume": clampf(volume, 0.0, 2.0), "opacity": clampf(opacity, 0.0, 1.0), "enabled": true, "metadata": metadata_value.duplicate(true)}
	var clips: Array = track.get("clips", [])
	clips.append(clip)
	clips.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("start", 0.0)) < float(b.get("start", 0.0)))
	track["clips"] = clips
	return {"ok": true, "clip": clip}

func move_clip(track: Dictionary, clip_id: String, new_start: float) -> Dictionary:
	var index := _find_clip(track, clip_id)
	if index < 0:
		return {"ok": false, "error": "No se encontró el clip."}
	if bool(track.get("locked", false)):
		return {"ok": false, "error": "La pista está bloqueada."}
	if not _is_finite(new_start):
		return {"ok": false, "error": "La posición del clip debe ser finita."}
	var clips: Array = track.get("clips", [])
	clips[index]["start"] = maxf(0.0, new_start)
	clips.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("start", 0.0)) < float(b.get("start", 0.0)))
	track["clips"] = clips
	return {"ok": true, "clip": clips[_find_clip(track, clip_id)]}

func trim_clip(track: Dictionary, clip_id: String, new_start: float, new_end: float) -> Dictionary:
	var index := _find_clip(track, clip_id)
	if index < 0:
		return {"ok": false, "error": "No se encontró el clip."}
	if bool(track.get("locked", false)):
		return {"ok": false, "error": "La pista está bloqueada."}
	if not _is_finite(new_start) or not _is_finite(new_end):
		return {"ok": false, "error": "Los límites del recorte deben ser finitos."}
	var start := maxf(0.0, new_start)
	var finish := maxf(start + MIN_CLIP_DURATION, new_end)
	var clip: Dictionary = track["clips"][index]
	var old_start := float(clip.get("start", 0.0))
	var old_end := old_start + float(clip.get("duration", MIN_CLIP_DURATION))
	var delta_in := maxf(0.0, start - old_start)
	clip["source_in"] = float(clip.get("source_in", 0.0)) + delta_in
	clip["start"] = start
	clip["duration"] = finish - start
	if finish > old_end:
		clip["duration"] = finish - start
	track["clips"][index] = clip
	return {"ok": true, "clip": clip}

func split_clip(track: Dictionary, clip_id: String, at_time: float) -> Dictionary:
	var index := _find_clip(track, clip_id)
	if index < 0:
		return {"ok": false, "error": "No se encontró el clip."}
	if bool(track.get("locked", false)):
		return {"ok": false, "error": "La pista está bloqueada."}
	var clips: Array = track.get("clips", [])
	var original: Dictionary = clips[index].duplicate(true)
	var start := float(original.get("start", 0.0))
	var finish := start + float(original.get("duration", 0.0))
	if at_time <= start + MIN_CLIP_DURATION or at_time >= finish - MIN_CLIP_DURATION:
		return {"ok": false, "error": "El corte debe quedar dentro del clip."}
	var left := original.duplicate(true)
	var right := original.duplicate(true)
	left["duration"] = at_time - start
	right["id"] = _next_clip_id()
	right["start"] = at_time
	right["duration"] = finish - at_time
	right["source_in"] = float(original.get("source_in", 0.0)) + at_time - start
	right["name"] = str(original.get("name", "Clip")) + " (corte)"
	clips[index] = left
	clips.insert(index + 1, right)
	track["clips"] = clips
	return {"ok": true, "left": left, "right": right}

func duplicate_clip(track: Dictionary, clip_id: String, new_start: float = -1.0) -> Dictionary:
	var index := _find_clip(track, clip_id)
	if index < 0:
		return {"ok": false, "error": "No se encontró el clip."}
	if bool(track.get("locked", false)):
		return {"ok": false, "error": "La pista está bloqueada."}
	var clips: Array = track.get("clips", [])
	var copy: Dictionary = clips[index].duplicate(true)
	copy["id"] = _next_clip_id()
	if new_start >= 0.0:
		copy["start"] = new_start
	else:
		copy["start"] = float(copy.get("start", 0.0)) + float(copy.get("duration", 0.0))
	copy["name"] = str(copy.get("name", "Clip")) + " (copia)"
	clips.append(copy)
	clips.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("start", 0.0)) < float(b.get("start", 0.0)))
	track["clips"] = clips
	return {"ok": true, "clip": copy}

func remove_clip(track: Dictionary, clip_id: String) -> bool:
	if bool(track.get("locked", false)):
		return false
	var index := _find_clip(track, clip_id)
	if index < 0:
		return false
	track["clips"].remove_at(index)
	return true

func timeline_duration(timeline: Dictionary) -> float:
	var finish := 0.0
	for track in timeline.get("tracks", []):
		for clip in track.get("clips", []):
			finish = maxf(finish, float(clip.get("start", 0.0)) + float(clip.get("duration", 0.0)))
	return finish

func snap_time(time: float, fps: int) -> float:
	return snappedf(maxf(0.0, time), 1.0 / float(clampi(fps, 1, 120)))

func validate_timeline(timeline: Dictionary) -> Dictionary:
	var fps := int(timeline.get("fps", 0))
	if fps < 1 or fps > 120:
		return {"ok": false, "error": "La frecuencia del montaje debe estar entre 1 y 120 FPS."}
	var ids := {}
	for track in timeline.get("tracks", []):
		if not track is Dictionary or not track.get("clips", []) is Array:
			return {"ok": false, "error": "La estructura de pista o clips no es válida."}
		var track_id := str(track.get("id", ""))
		if track_id.is_empty() or ids.has(track_id) or not TRACK_TYPES.has(str(track.get("type", ""))):
			return {"ok": false, "error": "Hay una pista con ID duplicado o tipo inválido."}
		ids[track_id] = true
		var clip_ids := {}
		for clip in track.get("clips", []):
			if not clip is Dictionary:
				return {"ok": false, "error": "La pista contiene un clip con estructura inválida."}
			var clip_id := str(clip.get("id", ""))
			var start := float(clip.get("start", -1.0))
			var duration := float(clip.get("duration", 0.0))
			var source_in := float(clip.get("source_in", 0.0))
			var volume := float(clip.get("volume", 1.0))
			var opacity := float(clip.get("opacity", 1.0))
			if clip_id.is_empty() or clip_ids.has(clip_id) or not _is_finite(start) or not _is_finite(duration) or not _is_finite(source_in) or not _is_finite(volume) or not _is_finite(opacity) or start < 0.0 or duration < MIN_CLIP_DURATION or source_in < 0.0 or volume < 0.0 or volume > 2.0 or opacity < 0.0 or opacity > 1.0 or str(clip.get("source", "")).strip_edges().is_empty():
				return {"ok": false, "error": "Hay un clip con origen, tiempo o parámetros de mezcla inválidos."}
			clip_ids[clip_id] = true
	return {"ok": true, "duration": timeline_duration(timeline), "tracks": ids.size()}

func _find_clip(track: Dictionary, clip_id: String) -> int:
	var clips: Array = track.get("clips", [])
	for index in range(clips.size()):
		if str(clips[index].get("id", "")) == clip_id:
			return index
	return -1

func _default_track_name(track_type: String, tracks: Array) -> String:
	var names := {"video": "Vídeo", "audio": "Audio", "title": "Títulos", "overlay": "Superposición", "effect": "Efectos"}
	var count := 1
	for track in tracks:
		if str(track.get("type", "")) == track_type:
			count += 1
	return "%s %d" % [names.get(track_type, "Pista"), count]

func _next_clip_id() -> String:
	_clip_sequence += 1
	return "clip_%d_%d" % [Time.get_ticks_usec(), _clip_sequence]

func _is_finite(value: float) -> bool:
	return not is_nan(value) and not is_inf(value)
