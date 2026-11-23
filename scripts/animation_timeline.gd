extends RefCounted
class_name AnimationTimeline

## Modelo local de línea de tiempo: fotogramas ordenados, edición y muestreo interpolado.

func insert_keyframe(frames: Array, time: float, joint_angles: Dictionary) -> Array:
	var result: Array = frames.duplicate(true)
	var frame_time := maxf(0.0, time)
	var replacement := {"time": frame_time, "joint_angles": joint_angles.duplicate(true)}
	var replaced := false
	for i in range(result.size()):
		if absf(float(result[i].get("time", 0.0)) - frame_time) <= 0.0001:
			result[i] = replacement
			replaced = true
			break
	if not replaced:
		result.append(replacement)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("time", 0.0)) < float(b.get("time", 0.0))
	)
	return result

func remove_keyframe(frames: Array, index: int) -> Array:
	var result: Array = frames.duplicate(true)
	if index >= 0 and index < result.size():
		result.remove_at(index)
	return result

func sample_pose(clip: Dictionary, time: float) -> Dictionary:
	var frames: Array = clip.get("keyframes", [])
	if frames.is_empty():
		return {}
	if frames.size() == 1 or time <= float(frames[0].get("time", 0.0)):
		return frames[0].get("joint_angles", {}).duplicate(true)
	var last: Dictionary = frames[frames.size() - 1]
	if time >= float(last.get("time", 0.0)):
		return last.get("joint_angles", {}).duplicate(true)
	for i in range(frames.size() - 1):
		var left: Dictionary = frames[i]
		var right: Dictionary = frames[i + 1]
		var start := float(left.get("time", 0.0))
		var finish := float(right.get("time", start))
		if time >= start and time <= finish:
			var span := maxf(0.0001, finish - start)
			var t := clampf((time - start) / span, 0.0, 1.0)
			var a: Dictionary = left.get("joint_angles", {})
			var b: Dictionary = right.get("joint_angles", {})
			var pose := {}
			var keys: Dictionary = {}
			for key in a.keys():
				keys[key] = true
			for key in b.keys():
				keys[key] = true
			for key in keys.keys():
				var av := float(a.get(key, b.get(key, 0.0)))
				var bv := float(b.get(key, a.get(key, 0.0)))
				pose[key] = lerpf(av, bv, t)
			return pose
	return last.get("joint_angles", {}).duplicate(true)
