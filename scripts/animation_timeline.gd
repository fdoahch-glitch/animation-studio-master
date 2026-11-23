extends RefCounted
class_name AnimationTimeline

## Modelo local de línea de tiempo: fotogramas ordenados, edición y muestreo interpolado.

func insert_keyframe(frames: Array, time: float, pose_data: Dictionary, pose_key: String = "joint_angles") -> Array:
	var result: Array = frames.duplicate(true)
	var frame_time := maxf(0.0, time)
	var replacement := {"time": frame_time, pose_key: pose_data.duplicate(true)}
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

func sample_pose(clip: Dictionary, time: float, pose_key: String = "joint_angles") -> Dictionary:
	var frames: Array = clip.get("keyframes", [])
	if frames.is_empty():
		return {}
	if frames.size() == 1 or time <= float(frames[0].get("time", 0.0)):
		return frames[0].get(pose_key, {}).duplicate(true)
	var last: Dictionary = frames[frames.size() - 1]
	if time >= float(last.get("time", 0.0)):
		return last.get(pose_key, {}).duplicate(true)
	for i in range(frames.size() - 1):
		var left: Dictionary = frames[i]
		var right: Dictionary = frames[i + 1]
		var start := float(left.get("time", 0.0))
		var finish := float(right.get("time", start))
		if time >= start and time <= finish:
			var span := maxf(0.0001, finish - start)
			var amount := clampf((time - start) / span, 0.0, 1.0)
			var a: Dictionary = left.get(pose_key, {})
			var b: Dictionary = right.get(pose_key, {})
			var pose := {}
			var keys: Dictionary = {}
			for key in a.keys():
				keys[key] = true
			for key in b.keys():
				keys[key] = true
			for key in keys.keys():
				var av: Variant = a.get(key, b.get(key, 0.0))
				var bv: Variant = b.get(key, a.get(key, 0.0))
				if av is Array and bv is Array and av.size() >= 3 and bv.size() >= 3:
					var first := Vector3(float(av[0]), float(av[1]), float(av[2]))
					var second := Vector3(float(bv[0]), float(bv[1]), float(bv[2]))
					var value := first.lerp(second, amount)
					pose[key] = [value.x, value.y, value.z]
				else:
					pose[key] = lerpf(float(av), float(bv), amount)
			return pose
	return last.get(pose_key, {}).duplicate(true)
