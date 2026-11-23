extends Control
class_name IKDragOverlay

## Handles interactivos para arrastrar manos y pies en rigs 2D estándar y segmentados.
## El solver es geométrico y local: no usa IA, servicios ni procesos externos.
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

func _get_chain_data(handle_name: String) -> Dictionary:
	if not _is_supported_rig() or not handle_specs.has(handle_name):
		return {}
	var spec: Dictionary = handle_specs[handle_name]
	var segmented := str(rig.get_meta("rig_type", "")) == "2D_segmented_sprite_pivots"
	var root: Node2D
	var joint: Node2D
	var end_pivot: Node2D
	var upper_vector: Vector2
	var lower_vector: Vector2
	if segmented:
		root = rig.find_child(str(spec.seg_root), true, false) as Node2D
		joint = rig.find_child(str(spec.seg_joint), true, false) as Node2D
		end_pivot = rig.find_child(str(spec.seg_end), true, false) as Node2D
		if root == null or joint == null or end_pivot == null:
			return {}
		upper_vector = joint.position
		lower_vector = end_pivot.position
	else:
		root = rig.get_node_or_null(NodePath(str(spec.root))) as Node2D
		if root == null:
			return {}
		joint = root.get_node_or_null(str(spec.joint)) as Node2D
		var upper_line := root.get_node_or_null("Segmento") as Line2D
		var lower_line := joint.get_node_or_null("Segmento") as Line2D if joint != null else null
		if joint == null or upper_line == null or lower_line == null or upper_line.points.size() < 2 or lower_line.points.size() < 2:
			return {}
		upper_vector = upper_line.points[1]
		lower_vector = lower_line.points[1]
	var parent := root.get_parent() as Node2D
	if parent == null:
		return {}
	return {
		"root": root,
		"joint": joint,
		"end_pivot": end_pivot,
		"parent": parent,
		"upper_vector": upper_vector,
		"lower_vector": lower_vector,
		"side": float(spec.side),
		"segmented": segmented
	}

func _get_chain_end(spec: Dictionary) -> Vector2:
	var handle_name := ""
	for candidate in handle_specs.keys():
		if handle_specs[candidate] == spec:
			handle_name = str(candidate)
			break
	if handle_name == "":
		return Vector2(-10000, -10000)
	var chain := _get_chain_data(handle_name)
	if chain.is_empty():
		return Vector2(-10000, -10000)
	if bool(chain.segmented):
		return _canvas_point(chain.end_pivot)
	return _canvas_point(chain.joint, chain.lower_vector)

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
		draw_string(ThemeDB.fallback_font, point + Vector2(18, 4), str(handle_name), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#23384d"))
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
			nearest = str(handle_name)
	if nearest != "":
		active_handle = nearest
		if rig_builder != null and rig_builder.has_method("stop_animation"):
			rig_builder.stop_animation(rig)
		_apply_drag(pointer)
		accept_event()

func _clamp_rotation_degrees(pivot: Node2D, degrees: float) -> float:
	var normalized := wrapf(degrees, -180.0, 180.0)
	var minimum := float(pivot.get_meta("min_degrees", -150.0))
	var maximum := float(pivot.get_meta("max_degrees", 150.0))
	if minimum >= maximum:
		minimum = -150.0
		maximum = 150.0
	return clampf(normalized, minimum, maximum)

## Aplica un objetivo expresado en coordenadas locales del padre de la raíz IK.
## Es público para que las pruebas verifiquen el mismo camino que usa el arrastre.
func apply_handle_target(handle_name: String, target_in_parent: Vector2) -> Dictionary:
	if rig_builder == null or not rig_builder.has_method("solve_two_bone_ik"):
		return {"ok": false, "error": "No hay solver IK disponible."}
	var chain := _get_chain_data(handle_name)
	if chain.is_empty():
		return {"ok": false, "error": "La cadena IK no está disponible."}
	var root: Node2D = chain.root
	var joint: Node2D = chain.joint
	var parent: Node2D = chain.parent
	var upper_vector: Vector2 = chain.upper_vector
	var lower_vector: Vector2 = chain.lower_vector
	var solved: Dictionary = rig_builder.solve_two_bone_ik(
		root.position,
		target_in_parent,
		upper_vector.length(),
		lower_vector.length(),
		float(chain.side)
	)
	var solved_joint: Vector2 = solved.get("joint", root.position + upper_vector)
	var solved_end: Vector2 = solved.get("end", target_in_parent)
	var upper_direction := solved_joint - root.position
	var lower_direction := solved_end - solved_joint
	if upper_direction.length_squared() < 0.000001:
		upper_direction = upper_vector
	if lower_direction.length_squared() < 0.000001:
		lower_direction = lower_vector
	var desired_root_degrees := rad_to_deg(upper_direction.angle() - upper_vector.angle())
	var root_degrees := _clamp_rotation_degrees(root, desired_root_degrees)
	root.rotation = deg_to_rad(root_degrees)
	var desired_joint_degrees := rad_to_deg(lower_direction.angle() - root.rotation - lower_vector.angle())
	var joint_degrees := _clamp_rotation_degrees(joint, desired_joint_degrees)
	joint.rotation = deg_to_rad(joint_degrees)
	var actual_joint: Vector2 = parent.to_local(root.to_global(upper_vector))
	var actual_end: Vector2 = parent.to_local(joint.to_global(lower_vector))
	var limit_clamped := not is_equal_approx(root_degrees, wrapf(desired_root_degrees, -180.0, 180.0)) or not is_equal_approx(joint_degrees, wrapf(desired_joint_degrees, -180.0, 180.0))
	queue_redraw()
	return {
		"ok": true,
		"reachable": bool(solved.get("reachable", false)),
		"requested_target": target_in_parent,
		"actual_joint": actual_joint,
		"actual_end": actual_end,
		"root_degrees": root_degrees,
		"joint_degrees": joint_degrees,
		"limit_clamped": limit_clamped
	}

func _apply_drag(pointer: Vector2) -> void:
	if active_handle == "":
		return
	var chain := _get_chain_data(active_handle)
	if chain.is_empty():
		return
	var parent: Node2D = chain.parent
	var canvas_target: Vector2 = get_global_transform_with_canvas() * pointer
	var target_in_parent := parent.to_local(canvas_target)
	apply_handle_target(active_handle, target_in_parent)

func _process(_delta: float) -> void:
	if is_instance_valid(rig):
		queue_redraw()
