extends RefCounted
class_name CharacterRigBuilder

## Constructor de rigs 2D editables. Cada articulación es un pivote Node2D
## y cada segmento es una pieza Line2D hija; las animaciones usan AnimationPlayer.

const SKIN := Color("#e5a878")
const CLOTH := Color("#2878b8")
const DARK := Color("#23384d")
const ACCENT := Color("#e0a43b")

func build_runtime_rig(character_name: String = "Personaje", scale_factor: float = 1.0) -> Node2D:
	var rig := Node2D.new()
	rig.name = "Rig_" + _safe_name(character_name)
	rig.scale = Vector2.ONE * clampf(scale_factor, 0.25, 3.0)
	rig.set_meta("rig_type", "2D_pivot_hierarchy")
	rig.set_meta("editable", true)

	var pelvis := _segment(rig, "Pelvis", Vector2.ZERO, Vector2(0, 20), 27.0, DARK)
	var spine := _segment(pelvis, "Spine", Vector2(0, -18), Vector2(0, -36), 18.0, CLOTH)
	var chest := _segment(spine, "Chest", Vector2(0, -36), Vector2(0, -24), 25.0, CLOTH)
	var neck := _segment(chest, "Neck", Vector2(0, -24), Vector2(0, -16), 9.0, SKIN)
	var head := Node2D.new()
	head.name = "Head"
	head.position = Vector2(0, -19)
	neck.add_child(head)
	_add_head_shape(head)

	var shoulder_l := _segment(chest, "Shoulder_L", Vector2(-20, -4), Vector2(-25, 30), 12.0, SKIN)
	_segment(shoulder_l, "Elbow_L", Vector2(-25, 30), Vector2(-7, 30), 9.0, SKIN)
	var shoulder_r := _segment(chest, "Shoulder_R", Vector2(20, -4), Vector2(25, 30), 12.0, SKIN)
	_segment(shoulder_r, "Elbow_R", Vector2(25, 30), Vector2(7, 30), 9.0, SKIN)

	var leg_l := _segment(pelvis, "Hip_L", Vector2(-11, 18), Vector2(-2, 39), 15.0, DARK)
	_segment(leg_l, "Knee_L", Vector2(-2, 39), Vector2(2, 38), 12.0, DARK)
	var leg_r := _segment(pelvis, "Hip_R", Vector2(11, 18), Vector2(2, 39), 15.0, DARK)
	_segment(leg_r, "Knee_R", Vector2(2, 39), Vector2(-2, 38), 12.0, DARK)

	set_joint_limits(rig, NodePath("Pelvis/Spine/Chest/Shoulder_L/Elbow_L"), -10.0, 150.0)
	set_joint_limits(rig, NodePath("Pelvis/Spine/Chest/Shoulder_R/Elbow_R"), -10.0, 150.0)
	set_joint_limits(rig, NodePath("Pelvis/Hip_L/Knee_L"), -5.0, 150.0)
	set_joint_limits(rig, NodePath("Pelvis/Hip_R/Knee_R"), -5.0, 150.0)
	_add_animation_player(rig)
	return rig

func _segment(parent: Node2D, pivot_name: String, pivot_position: Vector2, end_point: Vector2, line_width: float, color: Color) -> Node2D:
	var pivot := Node2D.new()
	pivot.name = pivot_name
	pivot.position = pivot_position
	parent.add_child(pivot)

	var line := Line2D.new()
	line.name = "Segmento"
	line.points = PackedVector2Array([Vector2.ZERO, end_point])
	line.width = line_width
	line.default_color = color
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	pivot.add_child(line)

	var joint := Polygon2D.new()
	joint.name = "Articulacion"
	joint.polygon = _circle_points(7.0)
	joint.color = ACCENT
	pivot.add_child(joint)
	return pivot

func _add_head_shape(parent: Node2D) -> void:
	var shape := Polygon2D.new()
	shape.name = "Cabeza"
	shape.polygon = _ellipse_points(Vector2(0, -5), Vector2(17, 21))
	shape.color = SKIN
	parent.add_child(shape)
	var eye := Polygon2D.new()
	eye.name = "Ojo"
	eye.polygon = _ellipse_points(Vector2(6, -8), Vector2(2.0, 2.8))
	eye.color = DARK
	parent.add_child(eye)

func _circle_points(radius: float) -> PackedVector2Array:
	return _ellipse_points(Vector2.ZERO, Vector2(radius, radius), 12)

func _ellipse_points(center: Vector2, radii: Vector2, steps: int = 20) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(steps):
		var angle := TAU * float(i) / float(steps)
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points

func _add_animation_player(rig: Node2D) -> void:
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	player.root_node = NodePath("..")
	rig.add_child(player)

	var library := AnimationLibrary.new()
	library.add_animation("idle", _make_animation({
		"Spine": [0.0, 0.025, 0.0],
		"Head": [0.0, -0.025, 0.0]
	}, 1.2, true))
	library.add_animation("walk", _make_animation({
		"Hip_L": [-0.48, 0.48, -0.48],
		"Hip_R": [0.48, -0.48, 0.48],
		"Shoulder_L": [0.35, -0.35, 0.35],
		"Shoulder_R": [-0.35, 0.35, -0.35],
		"Elbow_L": [-0.12, -0.35, -0.12],
		"Elbow_R": [-0.35, -0.12, -0.35],
		"Spine": [0.035, -0.035, 0.035]
	}, 0.9, true))
	library.add_animation("run", _make_animation({
		"Hip_L": [-0.85, 0.85, -0.85],
		"Hip_R": [0.85, -0.85, 0.85],
		"Shoulder_L": [0.7, -0.7, 0.7],
		"Shoulder_R": [-0.7, 0.7, -0.7],
		"Elbow_L": [-0.65, -0.2, -0.65],
		"Elbow_R": [-0.2, -0.65, -0.2],
		"Spine": [0.12, -0.12, 0.12]
	}, 0.55, true))
	library.add_animation("jump", _make_animation({
		"Hip_L": [-0.55, 0.1, -0.55],
		"Hip_R": [0.55, -0.1, 0.55],
		"Shoulder_L": [-1.0, -0.7, -1.0],
		"Shoulder_R": [1.0, 0.7, 1.0],
		"Spine": [-0.12, 0.08, -0.12]
	}, 0.8, false))
	library.add_animation("talk", _make_animation({
		"Head": [0.0, -0.06, 0.0],
		"Spine": [0.0, 0.025, 0.0],
		"Shoulder_L": [0.04, 0.0, 0.04],
		"Shoulder_R": [-0.04, 0.0, -0.04]
	}, 1.0, true))
	library.add_animation("wave", _make_animation({
		"Shoulder_R": [-1.0, -1.15, -1.0],
		"Elbow_R": [-0.8, -1.2, -0.8],
		"Head": [0.0, 0.04, 0.0]
	}, 0.7, true))
	player.add_animation_library("base", library)

func _make_animation(pose_data: Dictionary, duration: float, looping: bool) -> Animation:
	var animation := Animation.new()
	animation.length = duration
	animation.loop_mode = Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE
	for bone_name in pose_data.keys():
		var values: Array = pose_data[bone_name]
		var track := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, NodePath(_bone_path(str(bone_name)) + ":rotation"))
		animation.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
		animation.track_insert_key(track, 0.0, float(values[0]))
		animation.track_insert_key(track, duration * 0.5, float(values[1]))
		animation.track_insert_key(track, duration, float(values[2]))
	return animation

func play_animation(rig: Node2D, animation_name: String, custom_speed: float = 1.0) -> bool:
	var player := rig.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player == null or not player.has_animation("base/" + animation_name):
		return false
	player.speed_scale = clampf(custom_speed, 0.1, 4.0)
	player.play("base/" + animation_name)
	return true

func stop_animation(rig: Node2D) -> void:
	var player := rig.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player != null:
		player.stop()

func list_animations() -> Array[String]:
	return ["idle", "walk", "run", "jump", "talk", "wave"]

func _bone_path(bone_name: String) -> String:
	var paths := {
		"Pelvis": "Pelvis",
		"Spine": "Pelvis/Spine",
		"Chest": "Pelvis/Spine/Chest",
		"Neck": "Pelvis/Spine/Chest/Neck",
		"Head": "Pelvis/Spine/Chest/Neck/Head",
		"Shoulder_L": "Pelvis/Spine/Chest/Shoulder_L",
		"Elbow_L": "Pelvis/Spine/Chest/Shoulder_L/Elbow_L",
		"Shoulder_R": "Pelvis/Spine/Chest/Shoulder_R",
		"Elbow_R": "Pelvis/Spine/Chest/Shoulder_R/Elbow_R",
		"Hip_L": "Pelvis/Hip_L",
		"Knee_L": "Pelvis/Hip_L/Knee_L",
		"Hip_R": "Pelvis/Hip_R",
		"Knee_R": "Pelvis/Hip_R/Knee_R"
	}
	return str(paths.get(bone_name, bone_name))

func _safe_name(value: String) -> String:
	var result := value.strip_edges().replace(" ", "_")
	return result if result != "" else "Personaje"

func set_joint_rotation(rig: Node2D, joint_path: NodePath, degrees: float) -> bool:
	var joint := rig.get_node_or_null(joint_path) as Node2D
	if joint == null:
		return false
	var minimum := float(joint.get_meta("min_degrees", -150.0))
	var maximum := float(joint.get_meta("max_degrees", 150.0))
	joint.rotation = deg_to_rad(clampf(degrees, minimum, maximum))
	return true

func set_joint_limits(rig: Node2D, joint_path: NodePath, minimum_degrees: float, maximum_degrees: float) -> bool:
	var joint := rig.get_node_or_null(joint_path) as Node2D
	if joint == null or minimum_degrees >= maximum_degrees:
		return false
	joint.set_meta("min_degrees", minimum_degrees)
	joint.set_meta("max_degrees", maximum_degrees)
	return true

func solve_two_bone_ik(root_position: Vector2, target_position: Vector2, upper_length: float, lower_length: float, bend_direction: float = 1.0) -> Dictionary:
	var a := maxf(upper_length, 0.001)
	var b := maxf(lower_length, 0.001)
	var delta := target_position - root_position
	var distance := clampf(delta.length(), absf(a - b) + 0.001, a + b - 0.001)
	var direction := delta.normalized()
	var along := (a * a - b * b + distance * distance) / (2.0 * distance)
	var height := sqrt(maxf(a * a - along * along, 0.0))
	var perpendicular := Vector2(-direction.y, direction.x) * signf(bend_direction)
	var joint_position := root_position + direction * along + perpendicular * height
	var clamped_target := root_position + direction * distance
	return {"root": root_position, "joint": joint_position, "end": clamped_target, "reachable": is_equal_approx(distance, delta.length())}

func build_segmented_sprite_rig(parts: Array, joints: Dictionary, source_size: Vector2i, target_size: Vector2 = Vector2(210, 245)) -> Node2D:
	var rig := Node2D.new()
	rig.name = "Rig_Imagen_Segmentada"
	rig.set_meta("rig_type", "2D_segmented_sprite_pivots")
	rig.set_meta("editable", true)
	var source_center := Vector2(source_size) * 0.5
	var scale_factor := minf(target_size.x / maxf(float(source_size.x), 1.0), target_size.y / maxf(float(source_size.y), 1.0))
	rig.scale = Vector2.ONE * scale_factor

	var records: Dictionary = {}
	for part in parts:
		var part_path := str(part.get("path", ""))
		var part_name := str(part.get("name", "part"))
		var rect_data: Array = part.get("rect", [])
		if part_path == "" or rect_data.size() != 4:
			continue
		var rect := Rect2(Vector2(float(rect_data[0]), float(rect_data[1])), Vector2(float(rect_data[2]), float(rect_data[3])))
		var pivot_key := _part_pivot_key(part_name)
		var joint_point := _resolve_joint_point(joints, pivot_key, rect)
		if not records.has(pivot_key):
			records[pivot_key] = {"joint": joint_point, "parts": []}
		records[pivot_key].parts.append({"path": part_path, "name": part_name, "rect": rect})

	var parent_map := {
		"pelvis": "",
		"torso": "pelvis",
		"head": "torso",
		"shoulder_left": "torso",
		"elbow_left": "shoulder_left",
		"wrist_left": "elbow_left",
		"shoulder_right": "torso",
		"elbow_right": "shoulder_right",
		"wrist_right": "elbow_right",
		"hip_left": "pelvis",
		"knee_left": "hip_left",
		"ankle_left": "knee_left",
		"hip_right": "pelvis",
		"knee_right": "hip_right",
		"ankle_right": "knee_right"
	}
	var order := ["pelvis", "torso", "head", "shoulder_left", "elbow_left", "wrist_left", "shoulder_right", "elbow_right", "wrist_right", "hip_left", "knee_left", "ankle_left", "hip_right", "knee_right", "ankle_right"]
	var pivots: Dictionary = {}
	var global_joint_points: Dictionary = {}
	for pivot_key in order:
		if not records.has(pivot_key):
			continue
		var record: Dictionary = records[pivot_key]
		var parent_key := str(parent_map.get(pivot_key, ""))
		var parent_node: Node2D = rig if parent_key == "" or not pivots.has(parent_key) else pivots[parent_key]
		var parent_point: Vector2 = Vector2.ZERO if parent_key == "" or not global_joint_points.has(parent_key) else global_joint_points[parent_key]
		var pivot := Node2D.new()
		pivot.name = "Pivot_" + pivot_key
		pivot.position = record.joint - parent_point
		parent_node.add_child(pivot)
		pivots[pivot_key] = pivot
		global_joint_points[pivot_key] = record.joint
		for part_record in record.parts:
			var part_image := Image.new()
			if part_image.load(str(part_record.path)) != OK:
				continue
			part_image.convert(Image.FORMAT_RGBA8)
			var sprite := Sprite2D.new()
			sprite.name = "Sprite_" + str(part_record.name).validate_filename()
			sprite.texture = ImageTexture.create_from_image(part_image)
			sprite.centered = true
			sprite.position = part_record.rect.get_center() - record.joint
			pivot.add_child(sprite)

	_add_segmented_animation_player(rig)
	return rig

func _part_pivot_key(part_name: String) -> String:
	var name := part_name.to_lower()
	if name.contains("head") or name.contains("hair"):
		return "head"
	if name.contains("neck"):
		return "torso"
	if name.contains("clothing") or name.contains("accessory"):
		return "torso"
	if name.contains("torso") or name.contains("chest"):
		return "torso"
	if name.contains("pelvis"):
		return "pelvis"
	if name.contains("lower_arm_left") or name.contains("forearm_left"):
		return "elbow_left"
	if name.contains("upper_arm_left") or name.contains("arm_left"):
		return "shoulder_left"
	if name.contains("hand_left"):
		return "wrist_left"
	if name.contains("lower_arm_right") or name.contains("forearm_right"):
		return "elbow_right"
	if name.contains("upper_arm_right") or name.contains("arm_right"):
		return "shoulder_right"
	if name.contains("hand_right"):
		return "wrist_right"
	if name.contains("lower_leg_left") or name.contains("calf_left"):
		return "knee_left"
	if name.contains("upper_leg_left") or name.contains("leg_left"):
		return "hip_left"
	if name.contains("foot_left"):
		return "ankle_left"
	if name.contains("lower_leg_right") or name.contains("calf_right"):
		return "knee_right"
	if name.contains("upper_leg_right") or name.contains("leg_right"):
		return "hip_right"
	if name.contains("foot_right"):
		return "ankle_right"
	return name.replace(" ", "_")

func _resolve_joint_point(joints: Dictionary, pivot_key: String, rect: Rect2) -> Vector2:
	var aliases := [pivot_key, pivot_key.replace("_", ""), pivot_key.replace("_left", "_l").replace("_right", "_r")]
	if pivot_key == "head":
		aliases.append("neck")
	if pivot_key == "torso":
		aliases.append("spine")
	for alias in aliases:
		if joints.has(alias):
			var value: Variant = joints[alias]
			if value is Array and value.size() == 2:
				return Vector2(float(value[0]), float(value[1]))
	match pivot_key:
		"head", "shoulder_left", "shoulder_right", "hip_left", "hip_right":
			return Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y * 0.18)
		"elbow_left", "elbow_right", "knee_left", "knee_right":
			return Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y * 0.15)
		"wrist_left", "wrist_right", "ankle_left", "ankle_right":
			return Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y * 0.12)
		"pelvis":
			return Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y * 0.85)
		_:
			return Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y * 0.5)

func _add_segmented_animation_player(rig: Node2D) -> void:
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	player.root_node = NodePath("..")
	rig.add_child(player)
	var library := AnimationLibrary.new()
	var poses := {
		"idle": {"head":[0.0,-0.025,0.0],"torso":[0.0,0.018,0.0]},
		"walk": {"shoulder_left":[0.35,-0.35,0.35],"shoulder_right":[-0.35,0.35,-0.35],"hip_left":[-0.45,0.45,-0.45],"hip_right":[0.45,-0.45,0.45],"elbow_left":[-0.1,-0.3,-0.1],"elbow_right":[-0.3,-0.1,-0.3]},
		"run": {"shoulder_left":[0.65,-0.65,0.65],"shoulder_right":[-0.65,0.65,-0.65],"hip_left":[-0.8,0.8,-0.8],"hip_right":[0.8,-0.8,0.8],"elbow_left":[-0.55,-0.2,-0.55],"elbow_right":[-0.2,-0.55,-0.2]},
		"jump": {"shoulder_left":[-0.8,-0.5,-0.8],"shoulder_right":[0.8,0.5,0.8],"hip_left":[-0.5,0.1,-0.5],"hip_right":[0.5,-0.1,0.5]},
		"talk": {"head":[0.0,-0.06,0.0],"torso":[0.0,0.02,0.0]},
		"wave": {"shoulder_right":[-1.0,-1.2,-1.0],"elbow_right":[-0.7,-1.1,-0.7]}
	}
	for animation_name in poses.keys():
		library.add_animation(animation_name, _make_pivot_animation(poses[animation_name], 0.8, animation_name != "jump"))
	player.add_animation_library("base", library)

func _make_pivot_animation(pose_data: Dictionary, duration: float, looping: bool) -> Animation:
	var animation := Animation.new()
	animation.length = duration
	animation.loop_mode = Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE
	for pivot_name in pose_data.keys():
		var values: Array = pose_data[pivot_name]
		var track := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, NodePath(_segmented_pivot_path(str(pivot_name)) + ":rotation"))
		animation.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
		animation.track_insert_key(track, 0.0, float(values[0]))
		animation.track_insert_key(track, duration * 0.5, float(values[1]))
		animation.track_insert_key(track, duration, float(values[2]))
	return animation

func apply_segment_pose(rig: Node2D, joint_angles_degrees: Dictionary) -> int:
	var applied := 0
	for joint_name in joint_angles_degrees.keys():
		var pivot := rig.find_child("Pivot_" + str(joint_name), true, false) as Node2D
		if pivot == null:
			continue
		pivot.rotation = deg_to_rad(clampf(float(joint_angles_degrees[joint_name]), -180.0, 180.0))
		applied += 1
	return applied

func _segmented_pivot_path(pivot_name: String) -> String:
	var paths := {
		"pelvis": "Pivot_pelvis",
		"torso": "Pivot_pelvis/Pivot_torso",
		"head": "Pivot_pelvis/Pivot_torso/Pivot_head",
		"shoulder_left": "Pivot_pelvis/Pivot_torso/Pivot_shoulder_left",
		"elbow_left": "Pivot_pelvis/Pivot_torso/Pivot_shoulder_left/Pivot_elbow_left",
		"wrist_left": "Pivot_pelvis/Pivot_torso/Pivot_shoulder_left/Pivot_elbow_left/Pivot_wrist_left",
		"shoulder_right": "Pivot_pelvis/Pivot_torso/Pivot_shoulder_right",
		"elbow_right": "Pivot_pelvis/Pivot_torso/Pivot_shoulder_right/Pivot_elbow_right",
		"wrist_right": "Pivot_pelvis/Pivot_torso/Pivot_shoulder_right/Pivot_elbow_right/Pivot_wrist_right",
		"hip_left": "Pivot_pelvis/Pivot_hip_left",
		"knee_left": "Pivot_pelvis/Pivot_hip_left/Pivot_knee_left",
		"ankle_left": "Pivot_pelvis/Pivot_hip_left/Pivot_knee_left/Pivot_ankle_left",
		"hip_right": "Pivot_pelvis/Pivot_hip_right",
		"knee_right": "Pivot_pelvis/Pivot_hip_right/Pivot_knee_right",
		"ankle_right": "Pivot_pelvis/Pivot_hip_right/Pivot_knee_right/Pivot_ankle_right"
	}
	return str(paths.get(pivot_name, "Pivot_" + pivot_name))

func add_ai_animation_set(rig: Node2D, clips: Array) -> int:
	var player := rig.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player == null or not player.has_animation_library("base"):
		return 0
	var library := player.get_animation_library("base")
	var added := 0
	for clip in clips:
		if not clip is Dictionary:
			continue
		var clip_name := "ai_" + str(clip.get("name", "generated")).validate_filename().to_lower()
		var duration := clampf(float(clip.get("duration", 1.0)), 0.05, 60.0)
		var keyframes: Array = clip.get("keyframes", [])
		if keyframes.is_empty():
			continue
		var animation := Animation.new()
		animation.length = duration
		animation.loop_mode = Animation.LOOP_LINEAR if bool(clip.get("loop", true)) else Animation.LOOP_NONE
		var tracks: Dictionary = {}
		for keyframe in keyframes:
			if not keyframe is Dictionary:
				continue
			var time := clampf(float(keyframe.get("time", 0.0)), 0.0, duration)
			var angles: Dictionary = keyframe.get("joint_angles", {})
			for joint_name in angles.keys():
				var key := str(joint_name)
				if not tracks.has(key):
					var pivot := rig.find_child("Pivot_" + key, true, false)
					var track_path := _segmented_pivot_path(key) if pivot != null else _bone_path(key)
					var track := animation.add_track(Animation.TYPE_VALUE)
					animation.track_set_path(track, NodePath(track_path + ":rotation"))
					animation.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
					tracks[key] = track
				animation.track_insert_key(int(tracks[key]), time, deg_to_rad(clampf(float(angles[joint_name]), -180.0, 180.0)))
		if animation.get_track_count() > 0:
			if library.has_animation(clip_name):
				library.remove_animation(clip_name)
			library.add_animation(clip_name, animation)
			added += 1
	return added
