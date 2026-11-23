extends SceneTree

const RIG_BUILDER = preload("res://scripts/character_rig_builder.gd")
const IMAGE_PROCESSOR = preload("res://scripts/character_image_processor.gd")
const SPATIAL_BUILDER = preload("res://scripts/character_spatial_rig_builder.gd")
const PROCEDURAL_ANIMATOR = preload("res://scripts/character_procedural_animator.gd")
const IK_DRAG_OVERLAY = preload("res://scripts/ik_drag_overlay.gd")

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var builder = RIG_BUILDER.new()
	var procedural_rig: Node2D = builder.build_runtime_rig("CI_Test")
	root.add_child(procedural_rig)
	if not builder.play_animation(procedural_rig, "walk"):
		push_error("No se pudo reproducir la animación walk del rig 2D.")
		quit(1)
		return

	var animator = PROCEDURAL_ANIMATOR.new()
	var library: Dictionary = animator.generate_pose_library(1.25)
	if not is_equal_approx(float(library.get("intensity", 0.0)), 1.25):
		push_error("No se aplicó el control de intensidad procedural.")
		quit(1)
		return
	var poses: Array = library.get("poses", [])
	var clips: Array = library.get("animations", [])
	if poses.size() < 20 or clips.size() < 20:
		push_error("El generador procedural no creó suficientes poses y ciclos.")
		quit(1)
		return
	if builder.apply_procedural_pose(procedural_rig, poses[1].get("joint_angles", {})) < 1:
		push_error("No se pudo aplicar una pose procedural al rig estándar.")
		quit(1)
		return
	var captured_pose: Dictionary = builder.capture_procedural_pose(procedural_rig)
	if captured_pose.is_empty() or not captured_pose.has("head"):
		push_error("No se pudo capturar la pose manual del rig estándar.")
		quit(1)
		return
	if builder.add_procedural_animation_set(procedural_rig, clips) < 18:
		push_error("No se pudieron instalar los ciclos procedurales en el rig.")
		quit(1)
		return
	if not builder.play_animation(procedural_rig, "proc_caminar", 1.4):
		push_error("No se pudo reproducir el ciclo procedural Caminar.")
		quit(1)
		return

	var ik: Dictionary = builder.solve_two_bone_ik(Vector2.ZERO, Vector2(80, 20), 55.0, 45.0)
	if not ik.has("joint") or not ik.has("end"):
		push_error("El solver IK no devolvió articulaciones.")
		quit(1)
		return

	var ik_joint: Vector2 = ik.joint
	var ik_end: Vector2 = ik.end
	if not is_equal_approx(ik_joint.distance_to(Vector2.ZERO), 55.0) or not is_equal_approx(ik_end.distance_to(ik_joint), 45.0):
		push_error("El solver IK no respeta las longitudes de los dos segmentos.")
		quit(1)
		return

	var standard_overlay: Control = IK_DRAG_OVERLAY.new()
	root.add_child(standard_overlay)
	standard_overlay.configure(procedural_rig, builder)
	if not standard_overlay._is_supported_rig():
		push_error("El editor IK no reconoce el rig 2D estándar.")
		quit(1)
		return
	for handle_name in standard_overlay.handle_specs.keys():
		if standard_overlay._get_chain_end(standard_overlay.handle_specs[handle_name]).x < -1000.0:
			push_error("Falta un punto IK arrastrable en el rig estándar: " + str(handle_name))
			quit(1)
			return

	var image := Image.create(128, 256, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	for y in range(25, 245):
		for x in range(38, 92):
			image.set_pixel(x, y, Color("#2878b8"))
	for y in range(18, 58):
		for x in range(47, 83):
			image.set_pixel(x, y, Color("#e5a878"))
	var source_path := "user://ci_character_test.png"
	if image.save_png(source_path) != OK:
		push_error("No se pudo crear imagen de prueba.")
		quit(1)
		return

	var processor = IMAGE_PROCESSOR.new()
	var prepared: Dictionary = processor.process_character_image(source_path, 0.16)
	if not bool(prepared.get("ok", false)) or prepared.get("parts", []).is_empty():
		push_error("Falló la preparación local de imagen.")
		quit(1)
		return

	var segmented_parts: Array = []
	for part_name in ["pelvis", "torso", "upper_arm_left", "lower_arm_left", "hand_left", "upper_arm_right", "lower_arm_right", "hand_right", "upper_leg_left", "lower_leg_left", "foot_left", "upper_leg_right", "lower_leg_right", "foot_right"]:
		segmented_parts.append({"name": part_name, "path": source_path, "rect": [20, 20, 70, 100]})
	var sprite_rig: Node2D = builder.build_segmented_sprite_rig(segmented_parts, {}, Vector2i(128, 256))
	root.add_child(sprite_rig)
	var segmented_overlay: Control = IK_DRAG_OVERLAY.new()
	root.add_child(segmented_overlay)
	segmented_overlay.configure(sprite_rig, builder)
	if not segmented_overlay._is_supported_rig():
		push_error("El editor IK no reconoce el rig segmentado.")
		quit(1)
		return
	for handle_name in segmented_overlay.handle_specs.keys():
		if segmented_overlay._get_chain_end(segmented_overlay.handle_specs[handle_name]).x < -1000.0:
			push_error("Falta un punto IK arrastrable en el rig segmentado: " + str(handle_name))
			quit(1)
			return
	if not builder.play_animation(sprite_rig, "walk"):
		push_error("No se pudo reproducir la animación walk del rig segmentado.")
		quit(1)
		return
	if builder.apply_procedural_pose(sprite_rig, poses[2].get("joint_angles", {})) < 1:
		push_error("No se pudo aplicar una pose al rig de sprites segmentado.")
		quit(1)
		return
	if builder.add_procedural_animation_set(sprite_rig, clips) < 15:
		push_error("No se pudieron instalar ciclos procedurales en el rig segmentado.")
		quit(1)
		return
	if not builder.play_animation(sprite_rig, "proc_caminar", 1.2):
		push_error("No se pudo reproducir el ciclo procedural en el rig segmentado.")
		quit(1)
		return

	var spatial_builder = SPATIAL_BUILDER.new()
	var spatial_rig: Node3D = spatial_builder.build_humanoid_3d("CI_Test_3D")
	root.add_child(spatial_rig)
	var skeleton := spatial_rig.get_node_or_null("Skeleton3D") as Skeleton3D
	if skeleton == null or skeleton.get_bone_count() < 15:
		push_error("No se construyó el esqueleto Skeleton3D esperado.")
		quit(1)
		return

	print("PASS: rig 2D, animaciones base y procedurales, poses, IK, preparación de imagen, rig de sprites y Skeleton3D.")
	quit(0)
