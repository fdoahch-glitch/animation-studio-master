extends RefCounted
class_name AnimationTimeline

## Modelo local de línea de tiempo: clips, pistas, keyframes y muestreo interpolado.

const EASINGS := ["linear", "ease_in", "ease_out", "ease_in_out", "step"]

func seconds_to_frame(seconds: float, fps: int) -> int:
	return maxi(0, int(round(maxf(0.0, seconds) * float(maxi(1, fps)))))

func frame_to_seconds(frame: int, fps: int) -> float:
	return float(maxi(0, frame)) / float(maxi(1, fps))

func snap_time_to_frame(seconds: float, fps: int) -> float:
	return frame_to_seconds(seconds_to_frame(seconds, fps), fps)

func create_track(track_id: String, label: String, target_id: String, property: String, value_type := "number") -> Dictionary:
	if track_id.strip_edges().is_empty() or target_id.strip_edges().is_empty() or property.strip_edges().is_empty():
		return {}
	return {"id":track_id, "name":label, "target_id":target_id, "property":property, "value_type":value_type, "keyframes":[]}

func insert_property_keyframe(track: Dictionary, time: float, value: Variant, easing := "linear") -> Dictionary:
	if track.is_empty() or not EASINGS.has(easing):
		return {"ok":false, "error":"Pista o interpolación no válida."}
	if not _is_finite_number(time) or time < 0.0 or not _is_finite_key_value(value):
		return {"ok":false, "error":"El tiempo y el valor del fotograma deben ser válidos y finitos."}
	var frames: Array = track.get("keyframes", []).duplicate(true)
	var frame := {"time":maxf(0.0,time), "value":value, "easing":easing}
	var replaced := false
	for index in range(frames.size()):
		if absf(float(frames[index].get("time",0.0)) - float(frame.time)) <= 0.0001:
			frames[index] = frame
			replaced = true
			break
	if not replaced:
		frames.append(frame)
	frames.sort_custom(func(a: Dictionary,b: Dictionary)->bool: return float(a.time) < float(b.time))
	track["keyframes"] = frames
	return {"ok":true,"track":track}

func remove_property_keyframe(track: Dictionary, time: float, tolerance := 0.0001) -> Dictionary:
	if track.is_empty() or not _is_finite_number(time) or not _is_finite_number(tolerance) or tolerance < 0.0:
		return {"ok": false, "error": "Pista, tiempo o tolerancia no válidos."}
	var frames: Array = track.get("keyframes", []).duplicate(true)
	var match_index := -1
	var nearest := INF
	for index in range(frames.size()):
		var distance := absf(float(frames[index].get("time", -1.0)) - time)
		if distance <= tolerance and distance < nearest:
			nearest = distance
			match_index = index
	if match_index < 0:
		return {"ok": false, "error": "No existe un keyframe en el fotograma seleccionado."}
	frames.remove_at(match_index)
	track["keyframes"] = frames
	return {"ok": true, "track": track, "removed_index": match_index}

func apply_tracks_to_scene(scene: Dictionary, tracks: Array, time: float) -> Dictionary:
	var preview: Dictionary = scene.duplicate(true)
	if not _is_finite_number(time):
		return preview
	var objects: Array = preview.get("objects", [])
	for track in tracks:
		if not track is Dictionary:
			continue
		var sampled: Variant = sample_track(track, time)
		if sampled == null:
			continue
		var target_id := str(track.get("target_id", ""))
		var property := str(track.get("property", "x"))
		if target_id == "__camera__":
			var camera: Dictionary = preview.get("camera", {"x": 960.0, "y": 540.0, "zoom": 1.0, "rotation": 0.0}).duplicate(true)
			if property == "position" and sampled is Array and sampled.size() >= 2:
				camera["x"] = sampled[0]
				camera["y"] = sampled[1]
			elif ["x", "y", "zoom", "rotation"].has(property):
				camera[property] = sampled
			preview["camera"] = camera
			continue
		for object_index in range(objects.size()):
			var object: Dictionary = objects[object_index]
			if str(object.get("id", "")) != target_id:
				continue
			var transform: Dictionary = object.get("transform", {}).duplicate(true)
			if property == "position" and sampled is Array and sampled.size() >= 2:
				transform["x"] = sampled[0]
				transform["y"] = sampled[1]
			else:
				transform[property] = sampled
			object["transform"] = transform
			objects[object_index] = object
	preview["objects"] = objects
	return preview

func sample_track(track: Dictionary, time: float) -> Variant:
	if not _is_finite_number(time):
		return null
	var frames: Array = track.get("keyframes", [])
	if frames.is_empty():
		return null
	if frames.size() == 1 or time <= float(frames[0].time):
		return frames[0].get("value")
	var last: Dictionary = frames[-1]
	if time >= float(last.time):
		return last.get("value")
	for index in range(frames.size()-1):
		var left: Dictionary = frames[index]
		var right: Dictionary = frames[index+1]
		if time >= float(left.time) and time <= float(right.time):
			var span := maxf(0.0001, float(right.time)-float(left.time))
			var amount := clampf((time-float(left.time))/span,0.0,1.0)
			amount = _ease(amount, str(left.get("easing","linear")))
			var a: Variant = left.get("value")
			var b: Variant = right.get("value")
			if a is Array and b is Array and a.size() >= 2 and b.size() >= 2:
				var result: Array = []
				for axis in range(mini(a.size(), b.size())):
					result.append(lerpf(float(a[axis]),float(b[axis]),amount))
				return result
			if a is float or a is int:
				return lerpf(float(a),float(b),amount)
			return a if amount < 1.0 else b
	return last.get("value")

func validate_track(track: Dictionary) -> Dictionary:
	if str(track.get("id","")).is_empty() or str(track.get("target_id","")).is_empty():
		return {"ok":false,"error":"La pista necesita ID y destino."}
	var previous := -1.0
	for frame in track.get("keyframes", []):
		if not frame is Dictionary:
			return {"ok":false,"error":"La pista contiene un fotograma inválido."}
		var at := float(frame.get("time",-1.0))
		if not _is_finite_number(at) or at < 0.0 or at <= previous or not _is_finite_key_value(frame.get("value")):
			return {"ok":false,"error":"Los fotogramas deben tener tiempos ordenados y valores finitos."}
		if not EASINGS.has(str(frame.get("easing","linear"))):
			return {"ok":false,"error":"Curva de interpolación no admitida."}
		previous = at
	return {"ok":true,"count":track.get("keyframes",[]).size()}

func _ease(value: float, mode: String) -> float:
	match mode:
		"ease_in": return value * value
		"ease_out": return 1.0 - (1.0-value)*(1.0-value)
		"ease_in_out": return value * value * (3.0 - 2.0 * value)
		"step": return 0.0 if value < 1.0 else 1.0
		_: return value

func insert_keyframe(frames: Array, time: float, pose_data: Dictionary, pose_key: String = "joint_angles") -> Array:
	var result: Array = frames.duplicate(true)
	var frame_time := maxf(0.0, time)
	var replacement := {"time": frame_time}
	replacement[pose_key] = pose_data.duplicate(true)
	var replaced := false
	for i in range(result.size()):
		if absf(float(result[i].get("time", 0.0)) - frame_time) <= 0.0001:
			result[i] = replacement
			replaced = true
			break
	if not replaced:
		result.append(replacement)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("time", 0.0)) < float(b.get("time", 0.0)))
	return result

func remove_keyframe(frames: Array, index: int) -> Array:
	var result: Array = frames.duplicate(true)
	if index >= 0 and index < result.size():
		result.remove_at(index)
	return result

func sample_pose(clip: Dictionary, time: float, pose_key: String = "joint_angles") -> Dictionary:
	var frames: Array = clip.get("keyframes", [])
	if frames.is_empty():
		return {}
	if frames.size() == 1 or time <= float(frames[0].get("time", 0.0)):
		return frames[0].get(pose_key, {}).duplicate(true)
	var last: Dictionary = frames[-1]
	if time >= float(last.get("time", 0.0)):
		return last.get(pose_key, {}).duplicate(true)
	for i in range(frames.size() - 1):
		var left: Dictionary = frames[i]
		var right: Dictionary = frames[i + 1]
		var start := float(left.get("time", 0.0))
		var finish := float(right.get("time", start))
		if time >= start and time <= finish:
			var amount := clampf((time-start)/maxf(0.0001,finish-start),0.0,1.0)
			var a: Dictionary = left.get(pose_key, {})
			var b: Dictionary = right.get(pose_key, {})
			var pose := {}
			var keys := {}
			for key in a.keys(): keys[key] = true
			for key in b.keys(): keys[key] = true
			for key in keys.keys():
				var av: Variant = a.get(key,b.get(key,0.0))
				var bv: Variant = b.get(key,a.get(key,0.0))
				if av is Array and bv is Array and av.size() >= 3 and bv.size() >= 3:
					var value := Vector3(float(av[0]),float(av[1]),float(av[2])).lerp(Vector3(float(bv[0]),float(bv[1]),float(bv[2])),amount)
					pose[key] = [value.x,value.y,value.z]
				else:
					pose[key] = lerpf(float(av),float(bv),amount)
			return pose
	return last.get(pose_key, {}).duplicate(true)

func _is_finite_number(value: float) -> bool:
	return not is_nan(value) and not is_inf(value)

func _is_finite_key_value(value: Variant) -> bool:
	if value is int or value is float:
		return _is_finite_number(float(value))
	if value is Array:
		for component in value:
			if not (component is int or component is float) or not _is_finite_number(float(component)):
				return false
	return true
