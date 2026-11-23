extends Control
class_name IKDragOverlay

## Handles interactivos para arrastrar manos y pies en rigs 2D estándar y segmentados.
var rig: Node2D
var rig_builder
var active_handle := ""
var handle_specs := {
	"Mano izquierda": {"root": "Pelvis/Spine/Chest/Shoulder_L", "joint": "Elbow_L", "seg_root": "Pivot_shoulder_left", "seg_joint": "Pivot_elbow_left", "seg_end": "Pivot_wrist_left", "side": 1.0},
	"Mano derecha": {"root": "Pelvis/Spine/Chest/Shoulder_R", "joint": "Elbow_R", "seg_root": "Pivot_shoulder_right", "seg_joint": "Pivot_elbow_right", "seg_end": "Pivot_wrist_right", "side": -1.0},
	"Pie izquierdo": {"root": "Pelvis/Hip_L", "joint": "Knee_L", "seg_root": "Pivot_hip_left", "seg_joint": "Pivot_knee_left", "seg_end": "Pivot_ankle_left", "side": 1.0},
	"Pie derecho": {"root": "Pelvis/Hip_R", "joint": "Knee_R", "seg_root": "Pivot_hip_right", "seg_joint": "Pivot_knee_right", "seg_end": "Pivot_ankle_right", "side": -1.0}
}
var handle_colors := [Color("#e0a43b"), Color("#2878b8"), Color("#29a36a"), Color("#d65b69")]

func configure(target_rig: Node2D, builder) -> void:
	rig = target_rig
	rig_builder = builder
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()

func _canvas_point(node: Node2D, local_point: Vector2 = Vector2.ZERO) -> Vector2:
	var canvas_point: Vector2 = node.get_global_transform_with_canvas() * local_point
	return get_global_transform_with_canvas().affine_inverse() * canvas_point

func _is_supported_rig() -> bool:
	if not is_instance_valid(rig):
		return false
	var rig_type := str(rig.get_meta("rig_type", ""))
	return rig_type == "2D_pivot_hierarchy" or rig_type == "2D_segmented_sprite_pivots"

func _get_chain_end(spec: Dictionary) -> Vector2:
	if not _is_supported_rig():
		return Vector2(-10000, -10000)
	if str(rig.get_meta("rig_type", "")) == "2D_segmented_sprite_pivots":
		var end_pivot := rig.find_child(str(spec.seg_end), true, false) as Node2D
		return _canvas_point(end_pivot) if end_pivot != null else Vector2(-10000, -10000)
	var root := rig.get_node_or_null(NodePath(str(spec.root))) as Node2D
	if root == null:
		return Vector2(-10000, -10000)
	var joint := root.get_node_or_null(str(spec.joint)) as Node2D
	if joint == null:
		return Vector2(-10000, -10000)
	var line := joint.get_node_or_null("Segmento") as Line2D
	if line == null or line.points.size() < 2:
		return Vector2(-10000, -10000)
	return _canvas_point(joint, line.points[1])

func _draw() -> void:
	if not _is_supported_rig():
		return
	var index := 0
	for handle_name in handle_specs.keys():
		var point := _get_chain_end(handle_specs[handle_name])
		if point.x < -1000.0:
			index += 1
			continue
		draw_circle(point, 13.0, handle_colors[index % handle_colors.size()])
		draw_arc(point, 17.0, 0.0, TAU, 24, Color.WHITE, 2.0)
		draw_string(ThemeDB.fallback_font, point + Vector2(18, 4), handle_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#23384d"))
		index += 1

func _gui_input(event: InputEvent) -> void:
	if not _is_supported_rig():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(event.position)
		else:
			active_handle = ""
			accept_event()
	elif event is InputEventMouseMotion and active_handle != "":
		_apply_drag(event.position)
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_begin_drag(event.position)
		else:
			active_handle = ""
			accept_event()
	elif event is InputEventScreenDrag and active_handle != "":
		_apply_drag(event.position)
		accept_event()

func _begin_drag(pointer: Vector2) -> void:
	var nearest := ""
	var nearest_distance := 28.0
	for handle_name in handle_specs.keys():
		var handle_point := _get_chain_end(handle_specs[handle_name])
		if handle_point.x < -1000.0:
			continue
		var distance := pointer.distance_to(handle_point)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = handle_name
	if nearest != "":
		active_handle = nearest
		rig_builder.stop_animation(rig)
		_apply_drag(pointer)
		accept_event()

func _apply_drag(pointer: Vector2) -> void:
	var spec: Dictionary = handle_specs.get(active_handle, {})
	if spec.is_empty():
		return
	var segmented := str(rig.get_meta("rig_type", "")) == "2D_segmented_sprite_pivots"
	var root: Node2D
	var joint: Node2D
	var upper_vector: Vector2
	var lower_vector: Vector2
	if segmented:
		root = rig.find_child(str(spec.seg_root), true, false) as Node2D
		joint = rig.find_child(str(spec.seg_joint), true, false) as Node2D
		var end_pivot := rig.find_child(str(spec.seg_end), true, false) as Node2D
		if root == null or joint == null or end_pivot == null:
			return
		upper_vector = joint.position
		lower_vector = end_pivot.position
	else:
		root = rig.get_node_or_null(NodePath(str(spec.root))) as Node2D
		if root == null:
			return
		joint = root.get_node_or_null(str(spec.joint)) as Node2D
		var line: Line2D = joint.get_node_or_null("Segmento") as Line2D if joint != null else null
		var upper_line := root.get_node_or_null("Segmento") as Line2D
		if joint == null or line == null or upper_line == null or upper_line.points.size() < 2 or line.points.size() < 2:
			return
		upper_vector = upper_line.points[1]
		lower_vector = line.points[1]
	var canvas_target: Vector2 = get_global_transform_with_canvas() * pointer
	var parent := root.get_parent() as Node2D
	if parent == null:
		return
	var target := parent.to_local(canvas_target)
	var root_position := root.position
	var solved: Dictionary = rig_builder.solve_two_bone_ik(root_position, target, upper_vector.length(), lower_vector.length(), float(spec.side))
	var elbow_point: Vector2 = solved.joint
	var upper_direction := elbow_point - root_position
	var solved_end: Vector2 = solved.get("end", target)
	var lower_direction := solved_end - elbow_point
	root.rotation = upper_direction.angle() - upper_vector.angle()
	joint.rotation = lower_direction.angle() - root.rotation - lower_vector.angle()
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()
