extends RefCounted
class_name VideoTimeline

## Modelo de montaje audiovisual multipista. Los tiempos se expresan en segundos.

const TRACK_TYPES := ["video", "audio", "title", "overlay", "effect"]
const MIN_CLIP_DURATION := 0.04

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
	var clip_duration := maxf(MIN_CLIP_DURATION, duration)
	var clip := {"id": "clip_%d" % Time.get_ticks_usec(), "source": source, "name": str(options.get("name", source.get_file() if source.contains("/") else source)), "start": maxf(0.0, start), "duration": clip_duration, "source_in": maxf(0.0, float(options.get("source_in", 0.0))), "volume": clampf(float(options.get("volume", 1.0)), 0.0, 2.0), "opacity": clampf(float(options.get("opacity", 1.0)), 0.0, 1.0), "enabled": true, "metadata": options.get("metadata", {}).duplicate(true)}
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
	right["id"] = "clip_%d" % Time.get_ticks_usec()
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
	copy["id"] = "clip_%d" % Time.get_ticks_usec()
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
	var ids := {}
	for track in timeline.get("tracks", []):
		var track_id := str(track.get("id", ""))
		if track_id.is_empty() or ids.has(track_id) or not TRACK_TYPES.has(str(track.get("type", ""))):
			return {"ok": false, "error": "Hay una pista con ID duplicado o tipo inválido."}
		ids[track_id] = true
		var clip_ids := {}
		for clip in track.get("clips", []):
			var clip_id := str(clip.get("id", ""))
			var start := float(clip.get("start", -1.0))
			var duration := float(clip.get("duration", 0.0))
			if clip_id.is_empty() or clip_ids.has(clip_id) or start < 0.0 or duration < MIN_CLIP_DURATION:
				return {"ok": false, "error": "Hay un clip con ID o duración inválida."}
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
