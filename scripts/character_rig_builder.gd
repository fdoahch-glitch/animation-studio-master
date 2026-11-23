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
