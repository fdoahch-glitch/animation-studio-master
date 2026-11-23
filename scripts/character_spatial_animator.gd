extends Node
class_name CharacterSpatialAnimator

## Animador 3D procedural local para Skeleton3D. No usa modelos externos ni servicios de IA.

var skeleton: Skeleton3D
var current_cycle := ""
var elapsed := 0.0
var playback_speed := 1.0
var motion_intensity := 1.0
var playing := false

const CYCLE_NAMES := ["idle", "walk", "run", "jump", "wave", "talk", "dance", "sneak"]

func configure(target_skeleton: Skeleton3D) -> void:
	skeleton = target_skeleton
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
	playing = false
	current_cycle = ""
	_reset_skeleton_pose()
	var rotations: Variant = pose.get("bone_rotations_degrees", pose)
	if not rotations is Dictionary:
		return 0
	var applied := 0
	for bone_name in rotations.keys():
		var index := skeleton.find_bone(str(bone_name))
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
		var name := skeleton.get_bone_name(index)
		var euler := skeleton.get_bone_pose_rotation(index).get_euler() * (180.0 / PI)
		if euler.length_squared() > 0.0001:
			result[name] = [snappedf(euler.x, 0.01), snappedf(euler.y, 0.01), snappedf(euler.z, 0.01)]
	return result

func play_animation(animation_name: String, custom_speed: float = 1.0, intensity: float = 1.0) -> bool:
	var key := animation_name.to_lower().strip_edges()
	if not CYCLE_NAMES.has(key) or not is_instance_valid(skeleton):
		return false
	current_cycle = key
	elapsed = 0.0
	playback_speed = clampf(custom_speed, 0.1, 4.0)
	motion_intensity = clampf(intensity, 0.5, 1.75)
	playing = true
	set_process(true)
	return true

func stop_animation() -> void:
	playing = false
	current_cycle = ""
	_reset_skeleton_pose()

func is_playing() -> bool:
	return playing

func _process(delta: float) -> void:
	if not playing or not is_instance_valid(skeleton):
		return
	elapsed += delta * playback_speed
	var pose := _sample_cycle(current_cycle, elapsed, motion_intensity)
	_apply_runtime_rotations(pose)
	if current_cycle == "jump" and elapsed >= 1.2:
		playing = false
		_reset_skeleton_pose()

func _apply_runtime_rotations(pose: Dictionary) -> void:
	_reset_skeleton_pose()
	for bone_name in pose.keys():
		var index := skeleton.find_bone(str(bone_name))
		if index >= 0:
			var euler: Vector3 = pose[bone_name]
			skeleton.set_bone_pose_rotation(index, Quaternion.from_euler(euler * (PI / 180.0)))

func _reset_skeleton_pose() -> void:
	for index in range(skeleton.get_bone_count()):
		skeleton.set_bone_pose_rotation(index, Quaternion.IDENTITY)

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
	return _scale_pose(pose, factor)

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
