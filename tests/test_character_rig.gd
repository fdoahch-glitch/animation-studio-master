extends SceneTree

const RIG_BUILDER = preload("res://scripts/character_rig_builder.gd")
const IMAGE_PROCESSOR = preload("res://scripts/character_image_processor.gd")
const SPATIAL_BUILDER = preload("res://scripts/character_spatial_rig_builder.gd")
const SPATIAL_ANIMATOR = preload("res://scripts/character_spatial_animator.gd")
const PACKAGE_IO = preload("res://scripts/character_package_io.gd")
const PROCEDURAL_ANIMATOR = preload("res://scripts/character_procedural_animator.gd")
const IK_DRAG_OVERLAY = preload("res://scripts/ik_drag_overlay.gd")
const ANIMATION_TIMELINE = preload("res://scripts/animation_timeline.gd")

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
	if captured_pose.is_empty() or not captured_pose.has("head") or not captured_pose.has("neck") or not captured_pose.has("pelvis"):
		push_error("No se pudo capturar la pose manual del rig estándar.")
		quit(1)
		return
	if builder.apply_procedural_pose(procedural_rig, {"neck": 12.0, "pelvis": -5.0}) < 2:
		push_error("No se pudieron ajustar cuello y pelvis en el editor de articulaciones.")
		quit(1)
		return
	if builder.add_procedural_animation_set(procedural_rig, clips) < 18:
		push_error("No se pudieron instalar los ciclos procedurales en el rig.")
		quit(1)
		return
	var existing_animation_count := procedural_rig.get_node("AnimationPlayer").get_animation_library("base").get_animation_list().size()
	var invalid_clips := [
		{"name":"Tiempo inválido","duration":1.0,"keyframes":[{"time":INF,"joint_angles":{"head":20.0}}]},
		{"name":"Ángulo inválido","duration":1.0,"keyframes":[{"time":0.0,"joint_angles":{"head":NAN}}]},
		{"name":"Fuera de orden","duration":1.0,"keyframes":[{"time":0.8,"joint_angles":{"head":10.0}},{"time":0.2,"joint_angles":{"head":20.0}}]}
	]
	assert(builder.add_procedural_animation_set(procedural_rig, invalid_clips) == 0, "Debe rechazar clips procedurales corruptos")
	assert(procedural_rig.get_node("AnimationPlayer").get_animation_library("base").get_animation_list().size() == existing_animation_count, "Los clips inválidos no deben modificar la biblioteca")
	if not builder.play_animation(procedural_rig, "proc_caminar", 1.4):
		push_error("No se pudo reproducir el ciclo procedural Caminar.")
		quit(1)
		return

	var timeline = ANIMATION_TIMELINE.new()
	var keys: Array = timeline.insert_keyframe([], 0.0, {"head": 0.0, "torso": 0.0})
	keys = timeline.insert_keyframe(keys, 2.0, {"head": 90.0, "torso": 30.0})
	keys = timeline.insert_keyframe(keys, 1.0, {"head": 45.0, "torso": 15.0})
	if keys.size() != 3 or not is_equal_approx(float(keys[1].time), 1.0):
		push_error("La línea de tiempo no ordena correctamente los fotogramas clave.")
		quit(1)
		return
	var mid_pose: Dictionary = timeline.sample_pose({"keyframes": keys}, 1.5)
	if not is_equal_approx(float(mid_pose.get("head", 0.0)), 67.5):
		push_error("La interpolación de poses no coincide con el valor esperado.")
		quit(1)
		return
	var spatial_keys: Array = timeline.insert_keyframe([], 0.0, {"Head":[0.0,0.0,0.0]}, "bone_rotations_degrees")
	spatial_keys = timeline.insert_keyframe(spatial_keys, 2.0, {"Head":[0.0,0.0,90.0]}, "bone_rotations_degrees")
	var spatial_mid: Dictionary = timeline.sample_pose({"keyframes":spatial_keys}, 1.0, "bone_rotations_degrees")
	var spatial_head: Array = spatial_mid.get("Head", [])
	if spatial_head.size() < 3 or not is_equal_approx(float(spatial_head[2]), 45.0):
		push_error("La línea de tiempo no interpola las rotaciones vectoriales 3D.")
		quit(1)
		return
	keys = timeline.remove_keyframe(keys, 1)
	if keys.size() != 2:
		push_error("No se pudo eliminar un fotograma clave.")
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
	var zero_distance_ik: Dictionary = builder.solve_two_bone_ik(Vector2.ZERO, Vector2.ZERO, 55.0, 45.0)
	var zero_joint: Vector2 = zero_distance_ik.get("joint", Vector2.ZERO)
	var zero_end: Vector2 = zero_distance_ik.get("end", Vector2.ZERO)
	if not is_finite(zero_joint.x) or not is_finite(zero_joint.y) or not is_finite(zero_end.x) or not is_finite(zero_end.y):
		push_error("El solver IK no manejó de forma estable un objetivo coincidente con la raíz.")
		quit(1)
		return

	var standard_overlay = IK_DRAG_OVERLAY.new()
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

	builder.stop_animation(procedural_rig)
	for handle_name in standard_overlay.handle_specs.keys():
		var chain: Dictionary = standard_overlay._get_chain_data(str(handle_name))
		var chain_root: Node2D = chain.get("root") as Node2D
		var upper_vector: Vector2 = chain.get("upper_vector", Vector2.ZERO)
		var lower_vector: Vector2 = chain.get("lower_vector", Vector2.ZERO)
		var target := chain_root.position + upper_vector + lower_vector
		var drag_result: Dictionary = standard_overlay.apply_handle_target(str(handle_name), target)
		var actual_end: Vector2 = drag_result.get("actual_end", Vector2.ZERO)
		if not bool(drag_result.get("ok", false)) or actual_end.distance_to(target) > 0.1:
			push_error("El arrastre IK estándar no alcanzó el objetivo de " + str(handle_name) + ": " + str(drag_result))
			quit(1)
			return

	var standard_arm: Dictionary = standard_overlay._get_chain_data("Mano izquierda")
	var standard_arm_root: Node2D = standard_arm.root
	var standard_arm_joint: Node2D = standard_arm.joint
	var standard_arm_target := standard_arm_root.position + Vector2(-30.0, 55.0)
	if not builder.set_joint_limits(procedural_rig, NodePath("Pelvis/Spine/Chest/Shoulder_L/Elbow_L"), -2.0, 2.0):
		push_error("No se pudieron configurar límites articulares para la prueba IK.")
		quit(1)
		return
	var limited_arm: Dictionary = standard_overlay.apply_handle_target("Mano izquierda", standard_arm_target)
	if not bool(limited_arm.get("ok", false)) or not bool(limited_arm.get("limit_clamped", false)) or not is_equal_approx(rad_to_deg(standard_arm_joint.rotation), -2.0):
		push_error("El IK estándar no respetó el límite del codo: " + str(limited_arm))
		quit(1)
		return
	builder.set_joint_limits(procedural_rig, NodePath("Pelvis/Spine/Chest/Shoulder_L/Elbow_L"), -10.0, 150.0)
	if not builder.set_joint_limits(procedural_rig, NodePath("Pelvis/Spine/Chest/Shoulder_L"), -1.0, 1.0):
		push_error("No se pudieron configurar límites para el hombro.")
		quit(1)
		return
	var limited_shoulder: Dictionary = standard_overlay.apply_handle_target("Mano izquierda", standard_arm_root.position + Vector2(-40.0, 50.0))
	if not bool(limited_shoulder.get("limit_clamped", false)) or absf(rad_to_deg(standard_arm_root.rotation)) > 1.001:
		push_error("El IK estándar no respetó el límite del hombro: " + str(limited_shoulder))
		quit(1)
		return
	builder.set_joint_limits(procedural_rig, NodePath("Pelvis/Spine/Chest/Shoulder_L"), -150.0, 150.0)

	var standard_leg: Dictionary = standard_overlay._get_chain_data("Pie izquierdo")
	var standard_leg_root: Node2D = standard_leg.root
	var standard_leg_joint: Node2D = standard_leg.joint
	if not builder.set_joint_limits(procedural_rig, NodePath("Pelvis/Hip_L/Knee_L"), -1.0, 1.0):
		push_error("No se pudieron configurar límites para la rodilla.")
		quit(1)
		return
	var limited_leg: Dictionary = standard_overlay.apply_handle_target("Pie izquierdo", standard_leg_root.position + Vector2(8.0, 70.0))
	if not bool(limited_leg.get("limit_clamped", false)) or not is_equal_approx(rad_to_deg(standard_leg_joint.rotation), -1.0):
		push_error("El IK estándar no respetó el límite de la rodilla: " + str(limited_leg))
		quit(1)
		return
	builder.set_joint_limits(procedural_rig, NodePath("Pelvis/Hip_L/Knee_L"), -5.0, 150.0)

	var saved_ik_pose: Dictionary = builder.capture_procedural_pose(procedural_rig)
	if not saved_ik_pose.has("shoulder_left") or not saved_ik_pose.has("elbow_left"):
		push_error("La pose ajustada con IK no se pudo guardar.")
		quit(1)
		return
	builder.apply_procedural_pose(procedural_rig, {"shoulder_left": 0.0, "elbow_left": 0.0})
	builder.apply_procedural_pose(procedural_rig, saved_ik_pose)
	if not is_equal_approx(rad_to_deg(standard_arm_root.rotation), float(saved_ik_pose.shoulder_left)) or not is_equal_approx(rad_to_deg(standard_arm_joint.rotation), float(saved_ik_pose.elbow_left)):
		push_error("La pose IK guardada no se pudo reaplicar.")
		quit(1)
		return

	var unreachable_target := standard_arm_root.position + Vector2(1000.0, 0.0)
	var unreachable_result: Dictionary = standard_overlay.apply_handle_target("Mano izquierda", unreachable_target)
	if not bool(unreachable_result.get("ok", false)) or bool(unreachable_result.get("reachable", true)):
		push_error("El IK no informó correctamente un objetivo fuera del alcance.")
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
	var adjusted_path: String = processor.create_adjusted_texture(source_path, 0.1, 1.1, 1.2)
	if adjusted_path.is_empty() or not FileAccess.file_exists(adjusted_path):
		push_error("No se pudo generar una textura ajustada localmente.")
		quit(1)
		return
	var prepared: Dictionary = processor.process_character_image(source_path, 0.16)
	if not bool(prepared.get("ok", false)) or prepared.get("parts", []).is_empty():
		push_error("Falló la preparación local de imagen.")
		quit(1)
		return

	var segmented_parts: Array = []
	var part_rects := {
		"pelvis": [45, 150, 38, 42], "torso": [40, 60, 48, 100],
		"upper_arm_left": [18, 65, 22, 60], "lower_arm_left": [8, 110, 22, 55], "hand_left": [8, 155, 22, 30],
		"upper_arm_right": [88, 65, 22, 60], "lower_arm_right": [98, 110, 22, 55], "hand_right": [98, 155, 22, 30],
		"upper_leg_left": [40, 150, 22, 55], "lower_leg_left": [38, 200, 22, 45], "foot_left": [30, 230, 35, 20],
		"upper_leg_right": [65, 150, 22, 55], "lower_leg_right": [68, 200, 22, 45], "foot_right": [65, 230, 35, 20]
	}
	for part_name in part_rects.keys():
		segmented_parts.append({"name": part_name, "path": source_path, "rect": part_rects[part_name]})
	var sprite_rig: Node2D = builder.build_segmented_sprite_rig(segmented_parts, {}, Vector2i(128, 256))
	root.add_child(sprite_rig)
	var segmented_overlay = IK_DRAG_OVERLAY.new()
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

	for handle_name in segmented_overlay.handle_specs.keys():
		var chain: Dictionary = segmented_overlay._get_chain_data(str(handle_name))
		var chain_root: Node2D = chain.get("root") as Node2D
		var upper_vector: Vector2 = chain.get("upper_vector", Vector2.ZERO)
		var lower_vector: Vector2 = chain.get("lower_vector", Vector2.ZERO)
		var target := chain_root.position + upper_vector + lower_vector
		var drag_result: Dictionary = segmented_overlay.apply_handle_target(str(handle_name), target)
		var actual_end: Vector2 = drag_result.get("actual_end", Vector2.ZERO)
		if not bool(drag_result.get("ok", false)) or actual_end.distance_to(target) > 0.1:
			push_error("El arrastre IK segmentado no alcanzó el objetivo de " + str(handle_name) + ": " + str(drag_result))
			quit(1)
			return

	var segmented_arm: Dictionary = segmented_overlay._get_chain_data("Mano izquierda")
	var segmented_arm_root: Node2D = segmented_arm.root
	var segmented_arm_joint: Node2D = segmented_arm.joint
	segmented_arm_joint.set_meta("min_degrees", -0.5)
	segmented_arm_joint.set_meta("max_degrees", 0.5)
	var segmented_limited: Dictionary = segmented_overlay.apply_handle_target("Mano izquierda", segmented_arm_root.position + Vector2(-15.0, 80.0))
	if not bool(segmented_limited.get("limit_clamped", false)) or not is_equal_approx(rad_to_deg(segmented_arm_joint.rotation), -0.5):
		push_error("El IK segmentado no respetó el límite del codo: " + str(segmented_limited))
		quit(1)
		return
	segmented_arm_joint.remove_meta("min_degrees")
	segmented_arm_joint.remove_meta("max_degrees")
	var left_hand_root := sprite_rig.find_child("Pivot_shoulder_left", true, false) as Node2D
	var left_hand_joint := sprite_rig.find_child("Pivot_elbow_left", true, false) as Node2D
	var left_hand_end := sprite_rig.find_child("Pivot_wrist_left", true, false) as Node2D
	if left_hand_root == null or left_hand_joint == null or left_hand_end == null or left_hand_joint.position.length() < 1.0 or left_hand_end.position.length() < 1.0:
		push_error("La cadena IK segmentada no tiene longitudes válidas.")
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
	var spatial_animator = SPATIAL_ANIMATOR.new()
	spatial_rig.add_child(spatial_animator)
	spatial_animator.configure(skeleton)
	var ik_math: Dictionary = spatial_animator.solve_two_bone_ik(Vector3.ZERO, Vector3(1.0, 1.0, 0.0), 1.0, 1.0, Vector3(0,0,1))
	if not bool(ik_math.get("ok", false)) or not ik_math.has("joint"):
		push_error("El solver matemático IK 3D no calculó la articulación intermedia.")
		quit(1)
		return
	var spatial_poses: Array = spatial_animator.generate_pose_library(1.0)
	var spatial_clips: Array = spatial_animator.generate_animation_library(1.0)
	if spatial_poses.size() < 18 or spatial_clips.size() < 8:
		push_error("El generador 3D no creó suficientes poses y ciclos.")
		quit(1)
		return
	if spatial_animator.apply_pose(spatial_poses[1]) < 1:
		push_error("No se pudo aplicar una pose al Skeleton3D.")
		quit(1)
		return
	if skeleton.find_bone("Jaw") < 0 or spatial_animator.apply_pose({"bone_rotations_degrees":{"Jaw":[18.0,0.0,0.0]}}) < 1:
		push_error("No se pudo aplicar una pose de mandíbula al rig humanoide.")
		quit(1)
		return
	if not spatial_animator.play_animation("walk", 1.0, 1.0):
		push_error("No se pudo iniciar el ciclo procedural 3D.")
		quit(1)
		return
	spatial_animator._process(0.1)
	if spatial_animator.capture_pose().is_empty():
		push_error("El animador 3D no pudo capturar la pose resultante.")
		quit(1)
		return
	var chain_ik: Dictionary = spatial_animator.apply_two_bone_ik("arm_right", Vector3(0.6, 1.4, 0.1))
	if not bool(chain_ik.get("ok", false)) or not chain_ik.has("actual_end"):
		push_error("No se pudo aplicar IK 3D a la cadena del brazo derecho: " + str(chain_ik))
		quit(1)
		return
	if not spatial_animator.play_clip(spatial_clips[1], 1.0):
		push_error("No se pudo reproducir un clip 3D generado desde fotogramas.")
		quit(1)
		return
	spatial_animator._process(0.08)
	if spatial_animator.capture_pose().is_empty():
		push_error("El clip 3D no aplicó las rotaciones de sus fotogramas clave.")
		quit(1)
		return
	if spatial_animator.bake_clips_to_animation_player(spatial_rig, spatial_clips) != spatial_clips.size():
		push_error("No se pudieron convertir todos los ciclos procedurales a pistas AnimationPlayer.")
		quit(1)
		return
	var baked_player := spatial_rig.get_node_or_null("ProceduralAnimationPlayer") as AnimationPlayer
	if baked_player == null or not baked_player.has_animation("procedural/walk"):
		push_error("No se generó la animación 3D nativa para exportación.")
		quit(1)
		return
	var quadruped_builder = SPATIAL_BUILDER.new()
	var quadruped_rig: Node3D = quadruped_builder.build_quadruped_3d("Dinosaurio_CI")
	root.add_child(quadruped_rig)
	var quadruped_skeleton := quadruped_rig.get_node_or_null("Skeleton3D") as Skeleton3D
	if quadruped_skeleton == null or quadruped_skeleton.find_bone("Tail_04") < 0 or quadruped_skeleton.find_bone("Jaw") < 0:
		push_error("No se construyó el rig 3D cuadrúpedo con cola.")
		quit(1)
		return
	var quadruped_animator = SPATIAL_ANIMATOR.new()
	quadruped_rig.add_child(quadruped_animator)
	quadruped_animator.configure(quadruped_skeleton)
	var quadruped_poses: Array = quadruped_animator.generate_pose_library(1.0)
	var quadruped_clips: Array = quadruped_animator.generate_animation_library(1.0)
	if quadruped_poses.size() < 18 or quadruped_clips.size() < 8:
		push_error("El generador de dinosaurios no creó suficientes poses o ciclos.")
		quit(1)
		return
	if not quadruped_animator.play_animation("roar", 1.0, 1.0):
		push_error("No se pudo iniciar el ciclo procedural de rugido.")
		quit(1)
		return
	quadruped_animator._process(0.12)
	var quadruped_ik: Dictionary = quadruped_animator.apply_two_bone_ik("front_leg_left", Vector3(0.6, 0.5, 0.1))
	if not bool(quadruped_ik.get("ok", false)):
		push_error("No se pudo aplicar IK a la pata delantera del dinosaurio: " + str(quadruped_ik))
		quit(1)
		return

	print("RIG_TEST: antes de exportar glTF")
	var gltf_exporter := GLTFDocument.new()
	var gltf_export_state := GLTFState.new()
	if gltf_exporter.append_from_scene(spatial_rig, gltf_export_state) != OK:
		push_error("No se pudo preparar el rig 3D para exportación glTF.")
		quit(1)
		return
	print("RIG_TEST: append_from_scene completado")
	var glb_buffer: PackedByteArray = gltf_exporter.generate_buffer(gltf_export_state)
	if glb_buffer.is_empty():
		push_error("La exportación glTF no generó datos binarios.")
		quit(1)
		return
	print("RIG_TEST: generate_buffer completado (%d bytes)" % glb_buffer.size())
	var gltf_importer := GLTFDocument.new()
	var gltf_import_state := GLTFState.new()
	if gltf_importer.append_from_buffer(glb_buffer, "", gltf_import_state) != OK:
		push_error("No se pudo reimportar el buffer GLB generado.")
		quit(1)
		return
	print("RIG_TEST: append_from_buffer completado")
	var gltf_roundtrip_scene := gltf_importer.generate_scene(gltf_import_state)
	if gltf_roundtrip_scene == null:
		push_error("El ciclo glTF no pudo reconstruir la escena 3D.")
		quit(1)
		return

	print("RIG_TEST: generate_scene completado")
	var package_io = PACKAGE_IO.new()
	var package_3d: Dictionary = package_io.build_package(
		{"name":"Heroe 3D CI"}, "3D_imported_skeleton", {}, [], [], [], {},
		[{"name":"Saludo","bone_rotations_degrees":{"Head":[0.0,0.0,15.0]}}],
		[{"name":"wave","duration":1.0,"loop":true,"keyframes":[
			{"time":0.0,"bone_rotations_degrees":{"Head":[0.0,0.0,0.0]}},
			{"time":1.0,"bone_rotations_degrees":{"Head":[0.0,0.0,30.0]}}
		]}],
		{"Head":[0.0,0.0,12.0]}
	)
	var package_3d_result: Dictionary = package_io.decode_package(package_io.encode_package(package_3d))
	if not bool(package_3d_result.get("ok", false)):
		push_error("No se pudo serializar e importar el paquete de animación 3D.")
		quit(1)
		return
	var restored_3d: Dictionary = package_3d_result["package"]
	if restored_3d.get("spatial_poses", []).size() != 1 or restored_3d.get("spatial_animation_clips", []).size() != 1:
		push_error("El paquete no conservó poses o clips 3D.")
		quit(1)
		return
	if not is_equal_approx(float(restored_3d.rig.bone_rotations_degrees.get("Head", [0.0,0.0,0.0])[2]), 12.0):
		push_error("El paquete no conservó las rotaciones del esqueleto 3D.")
		quit(1)
		return

	print("PASS: rig 2D, animaciones base y procedurales, poses, IK, preparación de imagen, rig de sprites y Skeleton3D.")
	quit(0)
