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

const CYCLE_NAMES := ["idle", "walk", "run", "jump", "wave", "talk", "dance", "sneak"]

func configure(target_skeleton: Skeleton3D, target_animation_player: AnimationPlayer = null) -> void:
	skeleton = target_skeleton
	imported_animation_player = target_animation_player
	elapsed = 0.0
	playing = false
	set_process(is_instance_valid(skeleton))

func generate_pose_library(intensity: float = 1.0) -> Array:
	var factor := clampf(intensity, 0.5, 1.75)
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
		["Conversación", {"Head":[-5,0,0],"Shoulder_L":[0,0,12],"Shoulder_R":[0,0,-24],"Elbow_R":[0,0,32]}]
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
	var definitions := [
		{"name":"idle","duration":2.4,"loop":true},
		{"name":"walk","duration":1.1,"loop":true},
		{"name":"run","duration":0.62,"loop":true},
		{"name":"jump","duration":1.2,"loop":false},
		{"name":"wave","duration":1.8,"loop":true},
		{"name":"talk","duration":1.6,"loop":true},
		{"name":"dance","duration":2.0,"loop":true},
		{"name":"sneak","duration":1.5,"loop":true}
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

func play_animation(animation_name: String, custom_speed: float = 1.0, intensity: float = 1.0) -> bool:
	var key := animation_name.to_lower().strip_edges()
	if not CYCLE_NAMES.has(key) or not is_instance_valid(skeleton):
		return false
	_stop_imported_animation()
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
	_reset_skeleton_pose()

func play_clip(clip: Dictionary, custom_speed: float = 1.0) -> bool:
	if not is_instance_valid(skeleton) or clip.get("keyframes", []).is_empty():
		return false
	_stop_imported_animation()
	active_clip = clip.duplicate(true)
	current_cycle = ""
	elapsed = 0.0
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
		if elapsed >= duration:
			if looping:
				elapsed = fposmod(elapsed, duration)
			else:
				elapsed = duration
				_apply_runtime_rotations(_sample_clip_pose(active_clip, elapsed))
				playing = false
				return
		_apply_runtime_rotations(_sample_clip_pose(active_clip, elapsed))
		return
	var pose := _sample_cycle(current_cycle, elapsed, motion_intensity)
	_apply_runtime_rotations(pose)
	if current_cycle == "jump" and elapsed >= 1.2:
		playing = false
		_reset_skeleton_pose()

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

func apply_two_bone_ik(chain_name: String, target_position: Vector3, pole_position: Vector3 = Vector3(0, 0, 1)) -> Dictionary:
	if not is_instance_valid(skeleton):
		return {"ok":false,"error":"No hay un Skeleton3D activo."}
	var chains := {
		"arm_left":["Shoulder_L","Elbow_L","Wrist_L"],
		"arm_right":["Shoulder_R","Elbow_R","Wrist_R"],
		"leg_left":["Hip_L","Knee_L","Ankle_L"],
		"leg_right":["Hip_R","Knee_R","Ankle_R"]
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
	var rotated_middle := root_position + root_delta * (middle_position - root_position)
	var rotated_end := root_position + root_delta * (end_position - root_position)
	var root_rotation := root_delta * root_transform.basis.get_rotation_quaternion()
	skeleton.set_bone_global_pose(root_index, Transform3D(Basis(root_rotation), root_position))
	var middle_current_direction := rotated_end - rotated_middle
	var solved_end: Vector3 = solution["end"]
	var middle_target_direction: Vector3 = solved_end - rotated_middle
	if middle_current_direction.length_squared() > 0.0001 and middle_target_direction.length_squared() > 0.0001:
		var middle_delta := Quaternion(middle_current_direction.normalized(), middle_target_direction.normalized())
		var middle_rotation := middle_delta * root_delta * middle_transform.basis.get_rotation_quaternion()
		skeleton.set_bone_global_pose(middle_index, Transform3D(Basis(middle_rotation), rotated_middle))
	solution["actual_end"] = solved_end
	solution["error_distance"] = solved_end.distance_to(target_position)
	return solution

func _get_bone_global_transform(bone_index: int) -> Transform3D:
	var current := skeleton.get_bone_global_pose(bone_index)
	var rest := skeleton.get_bone_global_rest(bone_index)
	if current.origin.length_squared() < 0.000001 and rest.origin.length_squared() > 0.000001:
		return rest
	return current

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
		"Ankle_R":["ankleright","rightankle","rightfoot","footright"]
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
			pose = {"Head":Vector3(4.0 * wave,0,3.0 * secondary),"Neck":Vector3(2.0 * secondary,0,0),"Shoulder_R":Vector3(0,0,-12.0 * maxf(0.0,wave)),"Elbow_R":Vector3(0,0,18.0 * maxf(0.0,wave))}
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
