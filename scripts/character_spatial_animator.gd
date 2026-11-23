extends Node
class_name CharacterSpatialAnimator

## Animador 3D procedural local para Skeleton3D. No usa modelos externos ni servicios de IA.

var skeleton: Skeleton3D
var imported_animation_player: AnimationPlayer
var current_cycle := ""
var elapsed := 0.0
var playback_speed := 1.0
var motion_intensity := 1.0
var playing := false
var active_clip: Dictionary = {}
var model_root: Node3D
var blend_shape_targets: Array[Dictionary] = []
var facial_expression_values: Dictionary = {}
var blend_from_pose: Dictionary = {}
var blend_elapsed := 0.0
var blend_duration := 0.0
var blend_active := false
var root_motion_base_position := Vector3.ZERO
var contact_ik_enabled := true

const FACIAL_EXPRESSIONS := {
	"Neutral": {"neutral": 1.0},
	"Sonrisa": {"smile": 1.0, "happy": 1.0, "mouthsmile": 1.0},
	"Parpadeo": {"blink": 1.0, "eyeclose": 1.0, "closeeyes": 1.0},
	"Sorpresa": {"surprise": 1.0, "wideeyes": 0.85, "mouthopen": 0.65},
	"Enojo": {"angry": 1.0, "browdown": 0.8, "frown": 0.7},
	"Tristeza": {"sad": 1.0, "frown": 0.8},
	"Hablar": {"mouthopen": 0.55, "jawopen": 0.55, "visemeaa": 0.65},
	"Risa": {"laugh": 1.0, "smile": 0.9, "mouthopen": 0.45}
}

const HUMANOID_CYCLE_NAMES := ["idle", "walk", "run", "jump", "wave", "talk", "dance", "sneak"]
const QUADRUPED_CYCLE_NAMES := ["idle", "walk", "run", "jump", "roar", "tail_sway", "stomp", "look_around"]

func configure(target_skeleton: Skeleton3D, target_animation_player: AnimationPlayer = null, target_model_root: Node3D = null) -> void:
	skeleton = target_skeleton
	imported_animation_player = target_animation_player
	model_root = target_model_root if is_instance_valid(target_model_root) else (target_skeleton.get_parent() as Node3D if is_instance_valid(target_skeleton) else null)
	_rebuild_blend_shape_targets()
	elapsed = 0.0
	playing = false
	set_process(is_instance_valid(skeleton))

func generate_pose_library(intensity: float = 1.0) -> Array:
	var factor := clampf(intensity, 0.5, 1.75)
	if _is_quadruped():
		return _generate_quadruped_pose_library(factor)
	var definitions := [
		["Neutral", {"Head":[0,0,0],"Chest":[0,0,0]}],
		["Saludo", {"Shoulder_R":[0,0,-65],"Elbow_R":[0,0,85],"Wrist_R":[0,0,18],"Head":[0,0,8]}],
		["Brazos abiertos", {"Shoulder_L":[0,0,65],"Shoulder_R":[0,0,-65],"Elbow_L":[0,0,-8],"Elbow_R":[0,0,8]}],
		["Brazos cruzados", {"Shoulder_L":[0,0,-48],"Shoulder_R":[0,0,48],"Elbow_L":[0,0,82],"Elbow_R":[0,0,-82]}],
		["Salto", {"Shoulder_L":[0,0,48],"Shoulder_R":[0,0,-48],"Hip_L":[0,0,-24],"Hip_R":[0,0,24],"Knee_L":[0,0,32],"Knee_R":[0,0,-32]}],
		["Aterrizaje", {"Chest":[12,0,0],"Hip_L":[0,0,28],"Hip_R":[0,0,-28],"Knee_L":[0,0,-55],"Knee_R":[0,0,55]}],
		["Correr", {"Shoulder_L":[0,0,-42],"Shoulder_R":[0,0,42],"Hip_L":[0,0,38],"Hip_R":[0,0,-38],"Knee_L":[0,0,-30],"Knee_R":[0,0,30]}],
		["Caminar", {"Shoulder_L":[0,0,-22],"Shoulder_R":[0,0,22],"Hip_L":[0,0,22],"Hip_R":[0,0,-22]}],
		["Agacharse", {"Chest":[18,0,0],"Hip_L":[0,0,22],"Hip_R":[0,0,-22],"Knee_L":[0,0,-72],"Knee_R":[0,0,72]}],
		["Señalar", {"Shoulder_R":[0,0,-72],"Elbow_R":[0,0,12],"Head":[0,0,-12]}],
		["Celebrar", {"Shoulder_L":[0,0,105],"Shoulder_R":[0,0,-105],"Elbow_L":[0,0,-25],"Elbow_R":[0,0,25]}],
		["Mirar izquierda", {"Head":[0,-28,0],"Neck":[0,-12,0]}],
		["Mirar derecha", {"Head":[0,28,0],"Neck":[0,12,0]}],
		["Inclinar adelante", {"Chest":[22,0,0],"Head":[-12,0,0]}],
		["Inclinar atrás", {"Chest":[-18,0,0],"Head":[10,0,0]}],
		["Patada", {"Hip_R":[0,0,-55],"Knee_R":[0,0,68],"Shoulder_L":[0,0,24],"Shoulder_R":[0,0,-24]}],
		["Puñetazo", {"Shoulder_R":[0,0,-78],"Elbow_R":[0,0,18],"Chest":[0,-12,0]}],
		["Equilibrio", {"Shoulder_L":[0,0,70],"Shoulder_R":[0,0,-70],"Hip_L":[0,0,-12],"Hip_R":[0,0,32]}],
		["Sigilo", {"Chest":[12,0,0],"Hip_L":[0,0,14],"Hip_R":[0,0,-14],"Knee_L":[0,0,-35],"Knee_R":[0,0,35]}],
		["Conversación", {"Head":[-5,0,0],"Jaw":[22,0,0],"Shoulder_L":[0,0,12],"Shoulder_R":[0,0,-24],"Elbow_R":[0,0,32]}]
	]
	var result: Array = []
	for definition in definitions:
		result.append({
			"name": str(definition[0]),
			"bone_rotations_degrees": _scale_pose(definition[1], factor),
			"custom": false
		})
	return result

func generate_animation_library(intensity: float = 1.0) -> Array:
	var factor := clampf(intensity, 0.5, 1.75)
	var definitions: Array = [
		{"name":"idle","duration":2.4,"loop":true},
		{"name":"walk","duration":1.1,"loop":true},
		{"name":"run","duration":0.62,"loop":true},
		{"name":"jump","duration":1.2,"loop":false},
		{"name":"wave","duration":1.8,"loop":true},
		{"name":"talk","duration":1.6,"loop":true},
		{"name":"dance","duration":2.0,"loop":true},
		{"name":"sneak","duration":1.5,"loop":true}
	]
	if _is_quadruped():
		definitions = [
			{"name":"idle","duration":2.4,"loop":true},
			{"name":"walk","duration":1.2,"loop":true},
			{"name":"run","duration":0.72,"loop":true},
			{"name":"jump","duration":1.25,"loop":false},
			{"name":"roar","duration":1.8,"loop":false},
			{"name":"tail_sway","duration":2.0,"loop":true},
			{"name":"stomp","duration":1.1,"loop":false},
			{"name":"look_around","duration":2.2,"loop":true}
		]
	var result: Array = []
	for definition in definitions:
		var duration := float(definition.duration)
		var frames: Array = []
		var frame_count := 16
		for index in range(frame_count + 1):
			var time := duration * float(index) / float(frame_count)
			var pose := _sample_cycle(str(definition.name), time, factor)
			frames.append({"time":time,"bone_rotations_degrees":_pose_to_arrays(pose)})
		result.append({
			"name": str(definition.name),
			"duration": duration,
			"loop": bool(definition.loop),
			"keyframes": frames
		})
	return result

func apply_pose(pose: Dictionary) -> int:
	if not is_instance_valid(skeleton):
		return 0
	_stop_imported_animation()
	playing = false
	active_clip.clear()
	current_cycle = ""
	_clear_pose_blend()
	_reset_skeleton_pose()
	var rotations: Variant = pose.get("bone_rotations_degrees", pose)
	if not rotations is Dictionary:
		return 0
	var applied := 0
	for bone_name in rotations.keys():
		var index := _find_bone_index(str(bone_name))
		if index < 0:
			continue
		var euler := _as_vector3(rotations[bone_name])
		skeleton.set_bone_pose_rotation(index, Quaternion.from_euler(euler * (PI / 180.0)))
		applied += 1
	return applied

func capture_pose() -> Dictionary:
	var result := {}
	if not is_instance_valid(skeleton):
		return result
	for index in range(skeleton.get_bone_count()):
		var actual_name := skeleton.get_bone_name(index)
		var name := _canonical_bone_name(actual_name)
		if name == "":
			name = actual_name
		var euler := skeleton.get_bone_pose_rotation(index).get_euler() * (180.0 / PI)
		result[name] = [snappedf(euler.x, 0.01), snappedf(euler.y, 0.01), snappedf(euler.z, 0.01)]
	return result

func play_animation(animation_name: String, custom_speed: float = 1.0, intensity: float = 1.0, crossfade_seconds: float = 0.18) -> bool:
	var key := animation_name.to_lower().strip_edges()
	var available_cycles := QUADRUPED_CYCLE_NAMES if _is_quadruped() else HUMANOID_CYCLE_NAMES
	if not available_cycles.has(key) or not is_instance_valid(skeleton):
		return false
	var starting_pose := capture_pose()
	_stop_imported_animation()
	_begin_pose_blend(starting_pose, crossfade_seconds)
	current_cycle = key
	active_clip.clear()
	elapsed = 0.0
	playback_speed = clampf(custom_speed, 0.1, 4.0)
	motion_intensity = clampf(intensity, 0.5, 1.75)
	playing = true
	set_process(true)
	return true

func stop_animation() -> void:
	_stop_imported_animation()
	playing = false
	current_cycle = ""
	active_clip.clear()
	_clear_pose_blend()
	_reset_skeleton_pose()

func play_clip(clip: Dictionary, custom_speed: float = 1.0, crossfade_seconds: float = 0.18) -> bool:
	if not is_instance_valid(skeleton) or clip.get("keyframes", []).is_empty():
		return false
	var starting_pose := capture_pose()
	_stop_imported_animation()
	_begin_pose_blend(starting_pose, crossfade_seconds)
	active_clip = clip.duplicate(true)
	current_cycle = ""
	elapsed = 0.0
	root_motion_base_position = model_root.position if is_instance_valid(model_root) else Vector3.ZERO
	playback_speed = clampf(custom_speed, 0.1, 4.0)
	playing = true
	set_process(true)
	return true

func is_playing() -> bool:
	return playing

func _process(delta: float) -> void:
	if not playing or not is_instance_valid(skeleton):
		return
	elapsed += delta * playback_speed
	if not active_clip.is_empty():
		var duration := maxf(float(active_clip.get("duration", 1.0)), 0.05)
		var looping := bool(active_clip.get("loop", true))
		var sample_time := elapsed
		var loop_cycles := 0
		if elapsed >= duration:
			if looping:
				loop_cycles = int(floor(elapsed / duration))
				sample_time = fposmod(elapsed, duration)
			else:
				sample_time = duration
				_apply_blended_pose(_sample_clip_pose(active_clip, sample_time), delta)
				_apply_clip_root_motion(active_clip, sample_time, 0)
				_apply_clip_contact_ik(active_clip, sample_time)
				playing = false
				return
		_apply_blended_pose(_sample_clip_pose(active_clip, sample_time), delta)
		_apply_clip_root_motion(active_clip, sample_time, loop_cycles)
		_apply_clip_contact_ik(active_clip, sample_time)
		return
	var pose := _sample_cycle(current_cycle, elapsed, motion_intensity)
	_apply_blended_pose(pose, delta)
	_update_cycle_facial_expression(current_cycle, elapsed)
	if current_cycle == "jump" and elapsed >= 1.2:
		playing = false
		_reset_skeleton_pose()

func set_contact_ik_enabled(enabled: bool) -> void:
	contact_ik_enabled = enabled

func _sample_clip_frame_pair(clip: Dictionary, time: float) -> Dictionary:
	var frames: Array = clip.get("keyframes", [])
	if frames.is_empty():
		return {}
	var left: Dictionary = frames[0]
	var right: Dictionary = frames[frames.size() - 1]
	if time <= float(frames[0].get("time", 0.0)):
		right = frames[0]
	elif time >= float(frames[frames.size() - 1].get("time", 0.0)):
		left = right
	else:
		for index in range(frames.size() - 1):
			var first: Dictionary = frames[index]
			var second: Dictionary = frames[index + 1]
			if time >= float(first.get("time", 0.0)) and time <= float(second.get("time", 0.0)):
				left = first
				right = second
				break
	var span := float(right.get("time", 0.0)) - float(left.get("time", 0.0))
	var amount := clampf((time - float(left.get("time", 0.0))) / span, 0.0, 1.0) if span > 0.0001 else 0.0
	return {"left": left, "right": right, "amount": amount}

func _sample_clip_vector_track(clip: Dictionary, time: float, key: String) -> Vector3:
	var pair := _sample_clip_frame_pair(clip, time)
	if pair.is_empty():
		return Vector3.ZERO
	var left: Dictionary = pair.left
	var right: Dictionary = pair.right
	return _as_vector3(left.get(key, Vector3.ZERO)).lerp(_as_vector3(right.get(key, left.get(key, Vector3.ZERO))), float(pair.amount))

func _apply_clip_root_motion(clip: Dictionary, time: float, loop_cycles: int) -> void:
	if not is_instance_valid(model_root):
		return
	var first := _sample_clip_vector_track(clip, 0.0, "root_motion")
	var last := _sample_clip_vector_track(clip, maxf(float(clip.get("duration", 1.0)), 0.05), "root_motion")
	if first == Vector3.ZERO and last == Vector3.ZERO:
		return
	var sample := _sample_clip_vector_track(clip, time, "root_motion")
	model_root.position = root_motion_base_position + (sample - first) + (last - first) * float(loop_cycles)

func _sample_clip_contact_targets(clip: Dictionary, time: float) -> Dictionary:
	var pair := _sample_clip_frame_pair(clip, time)
	if pair.is_empty():
		return {}
	var left_targets: Dictionary = pair.left.get("ik_targets", {})
	var right_targets: Dictionary = pair.right.get("ik_targets", {})
	var amount: float = pair.amount
	var result: Dictionary = {}
	var chain_names: Dictionary = {}
	for chain_name in left_targets:
		chain_names[str(chain_name)] = true
	for chain_name in right_targets:
		chain_names[str(chain_name)] = true
	for chain_name in chain_names:
		var left_data: Variant = left_targets.get(chain_name, right_targets.get(chain_name, {}))
		var right_data: Variant = right_targets.get(chain_name, left_data)
		var left_position := _as_vector3(left_data.get("position", Vector3.ZERO)) if left_data is Dictionary else _as_vector3(left_data)
		var right_position := _as_vector3(right_data.get("position", left_position)) if right_data is Dictionary else _as_vector3(right_data)
		var left_pole := _as_vector3(left_data.get("pole", Vector3(0.0,0.0,1.0))) if left_data is Dictionary else Vector3(0.0,0.0,1.0)
		var right_pole := _as_vector3(right_data.get("pole", left_pole)) if right_data is Dictionary else left_pole
		result[str(chain_name)] = {"position": left_position.lerp(right_position, amount), "pole": left_pole.lerp(right_pole, amount)}
	return result

func _apply_clip_contact_ik(clip: Dictionary, time: float) -> void:
	if not contact_ik_enabled:
		return
	var targets := _sample_clip_contact_targets(clip, time)
	for chain_name in targets:
		var target: Dictionary = targets[chain_name]
		apply_two_bone_ik(str(chain_name), target.position, target.pole, false)

func apply_contact_targets(targets: Dictionary) -> int:
	var applied := 0
	for chain_name in targets:
		var target: Variant = targets[chain_name]
		var position := _as_vector3(target.get("position", Vector3.ZERO)) if target is Dictionary else _as_vector3(target)
		var pole := _as_vector3(target.get("pole", Vector3(0.0,0.0,1.0))) if target is Dictionary else Vector3(0.0,0.0,1.0)
		var result := apply_two_bone_ik(str(chain_name), position, pole, false)
		if bool(result.get("ok", false)):
			applied += 1
	return applied

func _sample_clip_pose(clip: Dictionary, time: float) -> Dictionary:
	var frames: Array = clip.get("keyframes", [])
	if frames.is_empty():
		return {}
	var left: Dictionary = frames[0]
	var right: Dictionary = frames[frames.size() - 1]
	if time <= float(frames[0].get("time", 0.0)):
		right = frames[0]
	elif time >= float(frames[frames.size() - 1].get("time", 0.0)):
		left = right
	else:
		for index in range(frames.size() - 1):
			var first: Dictionary = frames[index]
			var second: Dictionary = frames[index + 1]
			if time >= float(first.get("time", 0.0)) and time <= float(second.get("time", 0.0)):
				left = first
				right = second
				break
	var a: Dictionary = left.get("bone_rotations_degrees", {})
	var b: Dictionary = right.get("bone_rotations_degrees", {})
	var span := float(right.get("time", 0.0)) - float(left.get("time", 0.0))
	var amount := clampf((time - float(left.get("time", 0.0))) / span, 0.0, 1.0) if span > 0.0001 else 0.0
	var result := {}
	for bone_name in a.keys():
		var start := _as_vector3(a[bone_name])
		var finish := _as_vector3(b.get(bone_name, a[bone_name]))
		result[str(bone_name)] = start.lerp(finish, amount)
	for bone_name in b.keys():
		if not result.has(bone_name):
			result[str(bone_name)] = _as_vector3(b[bone_name])
	return result

func blend_pose(source_pose: Dictionary, target_pose: Dictionary, amount: float) -> Dictionary:
	var weight := clampf(amount, 0.0, 1.0)
	var result := {}
	var bone_names: Dictionary = {}
	for bone_name in source_pose.keys():
		bone_names[str(bone_name)] = true
	for bone_name in target_pose.keys():
		bone_names[str(bone_name)] = true
	for bone_name in bone_names.keys():
		var source_rotation := _as_vector3(source_pose.get(bone_name, Vector3.ZERO))
		var target_rotation := _as_vector3(target_pose.get(bone_name, Vector3.ZERO))
		result[str(bone_name)] = source_rotation.lerp(target_rotation, weight)
	return result

func _begin_pose_blend(source_pose: Dictionary, duration: float) -> void:
	blend_from_pose = source_pose.duplicate(true)
	blend_elapsed = 0.0
	blend_duration = maxf(0.0, duration)
	blend_active = blend_duration > 0.001 and not blend_from_pose.is_empty()

func _clear_pose_blend() -> void:
	blend_from_pose.clear()
	blend_elapsed = 0.0
	blend_duration = 0.0
	blend_active = false

func _apply_blended_pose(target_pose: Dictionary, delta: float) -> void:
	if not blend_active:
		_apply_runtime_rotations(target_pose)
		return
	blend_elapsed += maxf(0.0, delta)
	var amount := clampf(blend_elapsed / maxf(blend_duration, 0.001), 0.0, 1.0)
	_apply_runtime_rotations(blend_pose(blend_from_pose, target_pose, amount))
	if amount >= 1.0:
		_clear_pose_blend()

func _apply_runtime_rotations(pose: Dictionary) -> void:
	_reset_skeleton_pose()
	for bone_name in pose.keys():
		var index := _find_bone_index(str(bone_name))
		if index >= 0:
			var euler := _as_vector3(pose[bone_name])
			skeleton.set_bone_pose_rotation(index, Quaternion.from_euler(euler * (PI / 180.0)))

func _reset_skeleton_pose() -> void:
	for index in range(skeleton.get_bone_count()):
		skeleton.set_bone_pose_rotation(index, Quaternion.IDENTITY)

func _rebuild_blend_shape_targets() -> int:
	blend_shape_targets.clear()
	if not is_instance_valid(model_root):
		return 0
	var meshes: Array[Node] = []
	if model_root is MeshInstance3D:
		meshes.append(model_root)
	meshes.append_array(model_root.find_children("*", "MeshInstance3D", true, false))
	for node in meshes:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		for index in range(mesh_instance.get_blend_shape_count()):
			var shape_name: String = str(mesh_instance.mesh.get_blend_shape_name(index)) if mesh_instance.mesh is ArrayMesh else ""
			if shape_name.is_empty():
				continue
			blend_shape_targets.append({"node":mesh_instance,"index":index,"name":shape_name,"normalized":_normalize_expression_name(shape_name)})
	return blend_shape_targets.size()

func get_facial_expression_names() -> Array:
	return FACIAL_EXPRESSIONS.keys()

func get_blend_shape_names() -> Array:
	var names: Array = []
	for target in blend_shape_targets:
		names.append(str(target.get("name", "")))
	return names

func has_facial_expressions() -> bool:
	return not blend_shape_targets.is_empty()

func apply_facial_expression(expression_name: String, intensity: float = 1.0) -> int:
	if blend_shape_targets.is_empty():
		return 0
	var definition: Dictionary = FACIAL_EXPRESSIONS.get(expression_name, {})
	if definition.is_empty():
		return 0
	var applied := 0
	var amount_scale := clampf(intensity, 0.0, 1.0)
	for target in blend_shape_targets:
		var mesh_instance := target.get("node") as MeshInstance3D
		if not is_instance_valid(mesh_instance):
			continue
		var normalized := str(target.get("normalized", ""))
		var value := 0.0
		var matched := false
		for alias in definition.keys():
			if normalized.contains(str(alias)):
				value = maxf(value, float(definition[alias]) * amount_scale)
				matched = true
		mesh_instance.set_blend_shape_value(int(target.get("index", -1)), value)
		if matched:
			applied += 1
	facial_expression_values = capture_facial_expression()
	return applied

func capture_facial_expression() -> Dictionary:
	var result := {}
	for target in blend_shape_targets:
		var mesh_instance := target.get("node") as MeshInstance3D
		if is_instance_valid(mesh_instance):
			result[str(target.get("name", ""))] = snappedf(float(mesh_instance.get_blend_shape_value(int(target.get("index", -1)))), 0.001)
	return result

func apply_captured_facial_expression(values: Dictionary) -> int:
	var applied := 0
	for target in blend_shape_targets:
		var mesh_instance := target.get("node") as MeshInstance3D
		if not is_instance_valid(mesh_instance):
			continue
		var shape_name := str(target.get("name", ""))
		if values.has(shape_name):
			mesh_instance.set_blend_shape_value(int(target.get("index", -1)), clampf(float(values[shape_name]), 0.0, 1.0))
			applied += 1
	return applied

func _update_cycle_facial_expression(cycle_name: String, time: float) -> void:
	if blend_shape_targets.is_empty():
		return
	if cycle_name == "talk" or cycle_name == "roar":
		var pulse := maxf(0.0, sin(time * TAU * (3.2 if cycle_name == "talk" else 1.7)))
		apply_facial_expression("Hablar" if cycle_name == "talk" else "Sorpresa", pulse)
	elif cycle_name == "dance":
		apply_facial_expression("Sonrisa", 0.65 + 0.25 * sin(time * TAU))
	elif cycle_name == "idle":
		var blink_phase := fposmod(time, 3.7)
		if blink_phase < 0.13:
			apply_facial_expression("Parpadeo", sin(PI * blink_phase / 0.13))
		else:
			apply_facial_expression("Neutral")

func _normalize_expression_name(value: String) -> String:
	var normalized := value.to_lower()
	for token in ["mixamorig", "blendshape", "blend_shape", "face", "facial", "mesh", "head", "_", "-", " ", ".", ":", "|"]:
		normalized = normalized.replace(token, "")
	return normalized




func solve_two_bone_ik(root_position: Vector3, target_position: Vector3, first_length: float, second_length: float, pole_position: Vector3 = Vector3(0, 0, 1)) -> Dictionary:
	var direction_vector := target_position - root_position
	var raw_distance := direction_vector.length()
	if raw_distance < 0.0001 or first_length <= 0.0001 or second_length <= 0.0001:
		return {"ok":false,"error":"Distancia o longitud de cadena inválida.","distance":raw_distance,"first_length":first_length,"second_length":second_length}
	var minimum_distance := absf(first_length - second_length) + 0.0001
	var maximum_distance := maxf(minimum_distance, first_length + second_length - 0.0001)
	var distance := clampf(raw_distance, minimum_distance, maximum_distance)
	var direction := direction_vector / raw_distance
	var along := (first_length * first_length - second_length * second_length + distance * distance) / (2.0 * distance)
	var height := sqrt(maxf(0.0, first_length * first_length - along * along))
	var pole_direction := pole_position - direction * pole_position.dot(direction)
	if pole_direction.length_squared() < 0.0001:
		pole_direction = Vector3(0, 0, 1) - direction * Vector3(0, 0, 1).dot(direction)
	if pole_direction.length_squared() < 0.0001:
		pole_direction = Vector3(0, 1, 0) - direction * Vector3(0, 1, 0).dot(direction)
	var joint_position := root_position + direction * along + pole_direction.normalized() * height
	var solved_end := root_position + direction * distance
	return {"ok":true,"joint":joint_position,"end":solved_end,"target":target_position,"reachable":raw_distance <= maximum_distance}

func apply_two_bone_ik(chain_name: String, target_position: Vector3, pole_position: Vector3 = Vector3(0, 0, 1), interrupt_playback: bool = true) -> Dictionary:
	if not is_instance_valid(skeleton):
		return {"ok":false,"error":"No hay un Skeleton3D activo."}
	if interrupt_playback:
		playing = false
		current_cycle = ""
		active_clip.clear()
		_stop_imported_animation()
	var chains := {
		"arm_left":["Shoulder_L","Elbow_L","Wrist_L"],
		"arm_right":["Shoulder_R","Elbow_R","Wrist_R"],
		"leg_left":["Hip_L","Knee_L","Ankle_L"],
		"leg_right":["Hip_R","Knee_R","Ankle_R"],
		"front_leg_left":["FrontHip_L","FrontKnee_L","FrontAnkle_L"],
		"front_leg_right":["FrontHip_R","FrontKnee_R","FrontAnkle_R"],
		"back_leg_left":["BackHip_L","BackKnee_L","BackAnkle_L"],
		"back_leg_right":["BackHip_R","BackKnee_R","BackAnkle_R"]
	}
	if not chains.has(chain_name):
		return {"ok":false,"error":"Cadena IK desconocida."}
	var chain: Array = chains[chain_name]
	var root_index := _find_bone_index(str(chain[0]))
	var middle_index := _find_bone_index(str(chain[1]))
	var end_index := _find_bone_index(str(chain[2]))
	if root_index < 0 or middle_index < 0 or end_index < 0:
		return {"ok":false,"error":"El modelo no contiene todos los huesos de esta cadena."}
	var root_transform := _get_bone_global_transform(root_index)
	var middle_transform := _get_bone_global_transform(middle_index)
	var end_transform := _get_bone_global_transform(end_index)
	var root_position: Vector3 = root_transform.origin
	var middle_position: Vector3 = middle_transform.origin
	var end_position: Vector3 = end_transform.origin
	var first_length := root_position.distance_to(middle_position)
	var second_length := middle_position.distance_to(end_position)
	if first_length <= 0.0001 or second_length <= 0.0001:
		return {"ok":false,"error":"Longitudes de hueso no disponibles.","root":root_position,"middle":middle_position,"end":end_position,"first_length":first_length,"second_length":second_length}
	var solution := solve_two_bone_ik(root_position, target_position, first_length, second_length, pole_position)
	if not bool(solution.get("ok", false)):
		return solution
	var root_delta := Quaternion((middle_position - root_position).normalized(), (solution["joint"] - root_position).normalized())
	var root_rotation := root_delta * root_transform.basis.get_rotation_quaternion()
	_set_bone_global_rotation(root_index, root_rotation)
	var middle_after_root := _get_bone_global_transform(middle_index)
	var end_after_root := _get_bone_global_transform(end_index)
	var solved_end: Vector3 = solution["end"]
	var middle_current_direction := end_after_root.origin - middle_after_root.origin
	var middle_target_direction := solved_end - middle_after_root.origin
	if middle_current_direction.length_squared() > 0.0001 and middle_target_direction.length_squared() > 0.0001:
		var middle_delta := Quaternion(middle_current_direction.normalized(), middle_target_direction.normalized())
		var middle_rotation := middle_delta * middle_after_root.basis.get_rotation_quaternion()
		_set_bone_global_rotation(middle_index, middle_rotation)
	var final_end := _get_bone_global_transform(end_index).origin
	solution["actual_end"] = final_end
	solution["error_distance"] = final_end.distance_to(target_position)
	return solution

func _get_bone_global_transform(bone_index: int) -> Transform3D:
	var chain: Array = []
	var current_index := bone_index
	while current_index >= 0:
		chain.push_front(current_index)
		current_index = skeleton.get_bone_parent(current_index)
	var global_transform := Transform3D.IDENTITY
	for index in chain:
		var rest_transform := skeleton.get_bone_rest(index)
		var pose_rotation := skeleton.get_bone_pose_rotation(index)
		var pose_position := skeleton.get_bone_pose_position(index)
		var pose_scale := skeleton.get_bone_pose_scale(index)
		var pose_transform := Transform3D(Basis(pose_rotation).scaled(pose_scale), pose_position)
		global_transform = global_transform * rest_transform * pose_transform
	return global_transform

func _set_bone_global_rotation(bone_index: int, desired_global_rotation: Quaternion) -> void:
	var parent_index := skeleton.get_bone_parent(bone_index)
	var parent_rotation := Quaternion.IDENTITY
	if parent_index >= 0:
		parent_rotation = _get_bone_global_transform(parent_index).basis.get_rotation_quaternion()
	var rest_rotation := skeleton.get_bone_rest(bone_index).basis.get_rotation_quaternion()
	var local_pose_rotation := rest_rotation.inverse() * parent_rotation.inverse() * desired_global_rotation
	skeleton.set_bone_pose_rotation(bone_index, local_pose_rotation)

func _rotate_bone_towards(bone_index: int, bone_origin: Vector3, child_position: Vector3, desired_child_position: Vector3) -> void:
	var current_direction := child_position - bone_origin
	var desired_direction := desired_child_position - bone_origin
	if current_direction.length_squared() < 0.0001 or desired_direction.length_squared() < 0.0001:
		return
	var delta_rotation := Quaternion(current_direction.normalized(), desired_direction.normalized())
	var current_global_rotation := skeleton.get_bone_global_pose(bone_index).basis.get_rotation_quaternion()
	var desired_global_rotation := delta_rotation * current_global_rotation
	var parent_index := skeleton.get_bone_parent(bone_index)
	var parent_global_rotation := Quaternion.IDENTITY
	if parent_index >= 0:
		parent_global_rotation = skeleton.get_bone_global_pose(parent_index).basis.get_rotation_quaternion()
	skeleton.set_bone_pose_rotation(bone_index, parent_global_rotation.inverse() * desired_global_rotation)

func bake_clips_to_animation_player(root: Node3D, clips: Array, player_name: String = "ProceduralAnimationPlayer") -> int:
	if not is_instance_valid(root) or not is_instance_valid(skeleton):
		return 0
	var animation_player := root.get_node_or_null(player_name) as AnimationPlayer
	if animation_player == null:
		animation_player = AnimationPlayer.new()
		animation_player.name = player_name
		root.add_child(animation_player)
	animation_player.root_node = NodePath("..")
	var library := AnimationLibrary.new()
	var baked_count := 0
	var skeleton_path := str(root.get_path_to(skeleton))
	for clip in clips:
		if not clip is Dictionary:
			continue
		var frames: Array = clip.get("keyframes", [])
		if frames.is_empty():
			continue
		var animation := Animation.new()
		animation.length = maxf(float(clip.get("duration", 1.0)), 0.05)
		animation.loop_mode = Animation.LOOP_LINEAR if bool(clip.get("loop", true)) else Animation.LOOP_NONE
		var bone_names: Dictionary = {}
		for frame in frames:
			if frame is Dictionary:
				var rotations: Dictionary = frame.get("bone_rotations_degrees", {})
				for bone_name in rotations.keys():
					bone_names[str(bone_name)] = true
		for bone_name in bone_names.keys():
			var bone_index := _find_bone_index(str(bone_name))
			if bone_index < 0:
				continue
			var actual_bone_name := skeleton.get_bone_name(bone_index)
			var track_index := animation.add_track(Animation.TYPE_ROTATION_3D)
			animation.track_set_path(track_index, NodePath(skeleton_path + ":" + actual_bone_name))
			animation.track_set_interpolation_type(track_index, Animation.INTERPOLATION_LINEAR)
			for frame in frames:
				if not frame is Dictionary:
					continue
				var rotations: Dictionary = frame.get("bone_rotations_degrees", {})
				if not rotations.has(bone_name):
					continue
				var euler := _as_vector3(rotations[bone_name]) * (PI / 180.0)
				animation.rotation_track_insert_key(track_index, float(frame.get("time", 0.0)), Quaternion.from_euler(euler))
		if animation.get_track_count() == 0:
			continue
		var animation_name := str(clip.get("name", "animation")).validate_filename().to_lower()
		if animation_name == "":
			animation_name = "animation_%d" % baked_count
		library.add_animation(animation_name, animation)
		baked_count += 1
	if baked_count == 0:
		return 0
	if animation_player.has_animation_library("procedural"):
		animation_player.remove_animation_library("procedural")
	var add_error := animation_player.add_animation_library("procedural", library)
	return baked_count if add_error == OK else 0


func _is_quadruped() -> bool:
	return is_instance_valid(skeleton) and _find_bone_index("Tail_01") >= 0

func _generate_quadruped_pose_library(factor: float) -> Array:
	var definitions := [
		["Neutral", {"Chest":[0,0,0]}],
		["Caminar", {"FrontHip_L":[0,0,22],"FrontHip_R":[0,0,-22],"BackHip_L":[0,0,-22],"BackHip_R":[0,0,22]}],
		["Correr", {"FrontHip_L":[0,0,38],"FrontHip_R":[0,0,-38],"BackHip_L":[0,0,-38],"BackHip_R":[0,0,38],"FrontKnee_L":[0,0,28],"BackKnee_R":[0,0,28]}],
		["Salto", {"FrontHip_L":[0,0,35],"FrontHip_R":[0,0,35],"BackHip_L":[0,0,-30],"BackHip_R":[0,0,-30],"FrontKnee_L":[0,0,-35],"FrontKnee_R":[0,0,-35]}],
		["Rugido", {"Neck":[0,0,-25],"Head":[0,0,-18],"Jaw":[0,0,32],"Chest":[0,0,-8]}],
		["Cola izquierda", {"Tail_01":[0,0,14],"Tail_02":[0,0,22],"Tail_03":[0,0,28],"Tail_04":[0,0,32]}],
		["Cola derecha", {"Tail_01":[0,0,-14],"Tail_02":[0,0,-22],"Tail_03":[0,0,-28],"Tail_04":[0,0,-32]}],
		["Pisotón", {"BackHip_L":[0,0,28],"BackKnee_L":[0,0,-42],"BackAnkle_L":[0,0,15]}],
		["Mirar arriba", {"Neck":[0,0,18],"Head":[0,0,22]}],
		["Mirar abajo", {"Neck":[0,0,-12],"Head":[0,0,-25]}],
		["Agacharse", {"Chest":[0,0,-18],"FrontHip_L":[0,0,-20],"FrontHip_R":[0,0,-20],"BackKnee_L":[0,0,25],"BackKnee_R":[0,0,25]}],
		["Equilibrio", {"Tail_01":[0,0,10],"Tail_02":[0,0,18],"FrontHip_L":[0,0,-15],"FrontHip_R":[0,0,-15]}],
		["Paso frontal", {"FrontHip_L":[0,0,42],"FrontKnee_L":[0,0,-25]}],
		["Paso trasero", {"BackHip_L":[0,0,42],"BackKnee_L":[0,0,-25]}],
		["Cuello extendido", {"Neck":[0,0,28],"Head":[0,0,10]}],
		["Cola elevada", {"Tail_01":[0,0,20],"Tail_02":[0,0,28],"Tail_03":[0,0,30]}],
		["Cabeza girada", {"Head":[0,25,8],"Neck":[0,12,4]}],
		["Descanso", {"Chest":[0,0,-4],"Head":[0,0,-6],"Tail_01":[0,0,4],"Tail_02":[0,0,6]}]
	]
	var result: Array = []
	for definition in definitions:
		result.append({"name":str(definition[0]),"bone_rotations_degrees":_scale_pose(definition[1],factor),"custom":false})
	return result

func _sample_quadruped_cycle(name: String, time: float, factor: float) -> Dictionary:
	var frequency := 1.0
	var amplitude := 1.0
	if name == "run":
		frequency = 2.0
		amplitude = 1.5
	elif name == "sneak":
		frequency = 0.65
		amplitude = 0.65
	var phase := time * TAU * frequency
	var swing_a := sin(phase)
	var swing_b := sin(phase + PI)
	var secondary := sin(phase * 2.0)
	var pose := {}
	match name:
		"idle":
			pose = {"Chest":Vector3(0,0,1.5 * swing_a),"Head":Vector3(0,0,1.8 * swing_b),"Tail_01":Vector3(0,0,3.0 * swing_a),"Tail_02":Vector3(0,0,5.0 * swing_b),"Tail_03":Vector3(0,0,7.0 * swing_a)}
		"walk", "run":
			pose = {
				"FrontHip_L":Vector3(0,0,22.0 * swing_a * amplitude),
				"FrontHip_R":Vector3(0,0,22.0 * swing_b * amplitude),
				"FrontKnee_L":Vector3(0,0,30.0 * maxf(0.0,-swing_a) * amplitude),
				"FrontKnee_R":Vector3(0,0,30.0 * maxf(0.0,-swing_b) * amplitude),
				"BackHip_L":Vector3(0,0,-24.0 * swing_b * amplitude),
				"BackHip_R":Vector3(0,0,-24.0 * swing_a * amplitude),
				"BackKnee_L":Vector3(0,0,35.0 * maxf(0.0,swing_b) * amplitude),
				"BackKnee_R":Vector3(0,0,35.0 * maxf(0.0,swing_a) * amplitude),
				"Tail_01":Vector3(0,0,6.0 * sin(phase * 0.5)),
				"Tail_02":Vector3(0,0,10.0 * sin(phase * 0.5 + 0.4)),
				"Tail_03":Vector3(0,0,12.0 * sin(phase * 0.5 + 0.8)),
				"Neck":Vector3(0,0,3.0 * swing_a)
			}
		"jump":
			var jump_height := sin(clampf(time / 1.25,0.0,1.0) * PI)
			pose = {"FrontHip_L":Vector3(0,0,38.0 * jump_height),"FrontHip_R":Vector3(0,0,38.0 * jump_height),"FrontKnee_L":Vector3(0,0,-32.0 * jump_height),"FrontKnee_R":Vector3(0,0,-32.0 * jump_height),"BackHip_L":Vector3(0,0,-28.0 * jump_height),"BackHip_R":Vector3(0,0,-28.0 * jump_height),"BackKnee_L":Vector3(0,0,35.0 * jump_height),"BackKnee_R":Vector3(0,0,35.0 * jump_height),"Tail_01":Vector3(0,0,16.0 * jump_height),"Tail_02":Vector3(0,0,20.0 * jump_height)}
		"roar":
			pose = {"Neck":Vector3(0,0,-25.0 + 3.0 * swing_a),"Head":Vector3(0,0,-18.0 + 5.0 * swing_b),"Jaw":Vector3(0,0,28.0 * maxf(0.0,sin(phase * 1.5))),"Chest":Vector3(0,0,-8.0),"Tail_01":Vector3(0,0,8.0 * swing_a),"Tail_02":Vector3(0,0,12.0 * swing_b)}
		"tail_sway":
			pose = {"Tail_01":Vector3(0,0,16.0 * swing_a),"Tail_02":Vector3(0,0,22.0 * sin(phase - 0.35)),"Tail_03":Vector3(0,0,28.0 * sin(phase - 0.7)),"Tail_04":Vector3(0,0,32.0 * sin(phase - 1.0))}
		"stomp":
			var stomp := maxf(0.0, sin(phase))
			pose = {"BackHip_L":Vector3(0,0,32.0 * stomp),"BackKnee_L":Vector3(0,0,-48.0 * stomp),"BackAnkle_L":Vector3(0,0,18.0 * stomp),"Chest":Vector3(0,0,-4.0 * stomp)}
		"look_around":
			pose = {"Neck":Vector3(0,0,10.0 * swing_a),"Head":Vector3(0,0,18.0 * swing_b),"Tail_01":Vector3(0,0,4.0 * secondary)}
	return _scale_runtime_pose(pose, factor)

func _stop_imported_animation() -> void:
	if is_instance_valid(imported_animation_player):
		imported_animation_player.stop()

func _normalize_bone_name(value: String) -> String:
	var normalized := value.to_lower()
	normalized = normalized.replace("mixamorig:", "").replace("mixamorig", "")
	normalized = normalized.replace("_", "").replace(" ", "").replace("-", "").replace(":", "")
	return normalized

func _canonical_bone_name(actual_name: String) -> String:
	var normalized := _normalize_bone_name(actual_name)
	var aliases := {
		"Pelvis":["pelvis","hips","hip"],
		"Spine":["spine","spine0"],
		"Chest":["chest","spine1","spine2","upperchest"],
		"Neck":["neck"],
		"Head":["head"],
		"Jaw":["jaw","jawbone","lowerjaw","mandible"],
		"Shoulder_L":["shoulderleft","leftshoulder","leftarm","upperarmleft","leftupperarm"],
		"Elbow_L":["elbowleft","leftelbow","leftforearm","forearmleft","leftlowerarm"],
		"Wrist_L":["wristleft","leftwrist","lefthand","handleft"],
		"Shoulder_R":["shoulderright","rightshoulder","rightarm","upperarmright","rightupperarm"],
		"Elbow_R":["elbowright","rightelbow","rightforearm","forearmright","rightlowerarm"],
		"Wrist_R":["wristright","rightwrist","righthand","handright"],
		"Hip_L":["hipleft","lefthip","leftupleg","leftthigh","thighleft","upperlegleft"],
		"Knee_L":["kneeleft","leftknee","leftleg","leftcalf","calfleft","lowerlegleft"],
		"Ankle_L":["ankleleft","leftankle","leftfoot","footleft"],
		"Hip_R":["hipright","righthip","rightupleg","rightthigh","thighright","upperlegright"],
		"Knee_R":["kneeright","rightknee","rightleg","rightcalf","calfright","lowerlegright"],
		"Ankle_R":["ankleright","rightankle","rightfoot","footright"],
		"FrontHip_L":["fronthipleft","leftfronthip","leftfrontleg","frontshoulderleft"],
		"FrontKnee_L":["frontkneeleft","leftfrontknee","leftfrontlowerleg"],
		"FrontAnkle_L":["frontankleleft","leftfrontfoot","frontfootleft"],
		"FrontHip_R":["fronthipright","rightfronthip","rightfrontleg","frontshoulderright"],
		"FrontKnee_R":["frontkneeright","rightfrontknee","rightfrontlowerleg"],
		"FrontAnkle_R":["frontankleright","rightfrontfoot","frontfootright"],
		"BackHip_L":["backhipleft","leftbackhip","leftbackleg","leftthighback"],
		"BackKnee_L":["backkneeleft","leftbackknee","leftbacklowerleg"],
		"BackAnkle_L":["backankleleft","leftbackfoot","backfootleft"],
		"BackHip_R":["backhipright","rightbackhip","rightbackleg","rightthighback"],
		"BackKnee_R":["backkneeright","rightbackknee","rightbacklowerleg"],
		"BackAnkle_R":["backankleright","rightbackfoot","backfootright"],
		"Tail_01":["tail1","tailbase","tailroot"],
		"Tail_02":["tail2","tailmid1"],
		"Tail_03":["tail3","tailmid2"],
		"Tail_04":["tail4","tailtip"]
	}
	for canonical in aliases.keys():
		if normalized in aliases[canonical]:
			return str(canonical)
	return ""

func _find_bone_index(requested_name: String) -> int:
	var exact := skeleton.find_bone(requested_name)
	if exact >= 0:
		return exact
	var normalized := _normalize_bone_name(requested_name)
	for index in range(skeleton.get_bone_count()):
		if _normalize_bone_name(skeleton.get_bone_name(index)) == normalized:
			return index
	var canonical := _canonical_bone_name(requested_name)
	if canonical == "":
		return -1
	for index in range(skeleton.get_bone_count()):
		if _canonical_bone_name(skeleton.get_bone_name(index)) == canonical:
			return index
	return -1

func _sample_cycle(name: String, time: float, factor: float) -> Dictionary:
	if _is_quadruped():
		return _sample_quadruped_cycle(name, time, factor)
	var frequency := 1.0
	var amplitude := 1.0
	if name == "run":
		frequency = 2.0
		amplitude = 1.45
	elif name == "sneak":
		frequency = 0.68
		amplitude = 0.68
	var phase := time * TAU * frequency
	var wave := sin(phase)
	var opposite := sin(phase + PI)
	var secondary := sin(phase * 2.0)
	var pose := {}
	match name:
		"idle":
			pose = {"Chest":Vector3(1.8 * sin(phase * 0.5),0,0),"Head":Vector3(1.5 * sin(phase * 0.7),0,1.2 * sin(phase)),"Shoulder_L":Vector3.ZERO,"Shoulder_R":Vector3.ZERO}
		"walk", "run", "sneak":
			pose = {
				"Shoulder_L":Vector3(0,0,22.0 * wave * amplitude),
				"Shoulder_R":Vector3(0,0,22.0 * opposite * amplitude),
				"Elbow_L":Vector3(0,0,-12.0 * maxf(0.0,wave)),
				"Elbow_R":Vector3(0,0,-12.0 * maxf(0.0,opposite)),
				"Hip_L":Vector3(0,0,-24.0 * wave * amplitude),
				"Hip_R":Vector3(0,0,-24.0 * opposite * amplitude),
				"Knee_L":Vector3(0,0,32.0 * maxf(0.0,-wave) * amplitude),
				"Knee_R":Vector3(0,0,32.0 * maxf(0.0,-opposite) * amplitude),
				"Chest":Vector3(2.0 * absf(wave),0,0)
			}
		"jump":
			var jump_phase := clampf(time / 1.2, 0.0, 1.0)
			var jump_height := sin(jump_phase * PI)
			pose = {
				"Shoulder_L":Vector3(0,0,58.0 * jump_height),
				"Shoulder_R":Vector3(0,0,-58.0 * jump_height),
				"Elbow_L":Vector3(0,0,-18.0 * jump_height),
				"Elbow_R":Vector3(0,0,18.0 * jump_height),
				"Hip_L":Vector3(0,0,-24.0 * jump_height),
				"Hip_R":Vector3(0,0,24.0 * jump_height),
				"Knee_L":Vector3(0,0,35.0 * jump_height),
				"Knee_R":Vector3(0,0,-35.0 * jump_height)
			}
		"wave":
			pose = {"Shoulder_R":Vector3(0,0,-72.0),"Elbow_R":Vector3(0,0,42.0 + 22.0 * wave),"Wrist_R":Vector3(0,0,18.0 * secondary),"Head":Vector3(0,0,5.0 * wave)}
		"talk":
			pose = {"Head":Vector3(4.0 * wave,0,3.0 * secondary),"Neck":Vector3(2.0 * secondary,0,0),"Jaw":Vector3(20.0 * maxf(0.0,sin(phase * 2.0)),0,0),"Shoulder_R":Vector3(0,0,-12.0 * maxf(0.0,wave)),"Elbow_R":Vector3(0,0,18.0 * maxf(0.0,wave))}
		"dance":
			pose = {"Shoulder_L":Vector3(0,0,65.0 * wave),"Shoulder_R":Vector3(0,0,-65.0 * opposite),"Hip_L":Vector3(0,0,24.0 * opposite),"Hip_R":Vector3(0,0,24.0 * wave),"Chest":Vector3(0,10.0 * wave,8.0 * secondary),"Head":Vector3(0,0,12.0 * secondary)}
	return _scale_runtime_pose(pose, factor)

func _scale_runtime_pose(pose: Dictionary, factor: float) -> Dictionary:
	var result := {}
	for bone_name in pose.keys():
		result[str(bone_name)] = _as_vector3(pose[bone_name]) * factor
	return result

func _scale_pose(pose: Dictionary, factor: float) -> Dictionary:
	var result := {}
	for bone_name in pose.keys():
		var value: Variant = pose[bone_name]
		var vector := _as_vector3(value) * factor
		result[str(bone_name)] = [snappedf(vector.x, 0.01), snappedf(vector.y, 0.01), snappedf(vector.z, 0.01)]
	return result

func _pose_to_arrays(pose: Dictionary) -> Dictionary:
	var result := {}
	for bone_name in pose.keys():
		var value: Vector3 = pose[bone_name]
		result[str(bone_name)] = [snappedf(value.x, 0.01), snappedf(value.y, 0.01), snappedf(value.z, 0.01)]
	return result

func _as_vector3(value: Variant) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return Vector3.ZERO
