extends SceneTree

const RIG_BUILDER = preload("res://scripts/character_rig_builder.gd")
const IMAGE_PROCESSOR = preload("res://scripts/character_image_processor.gd")
const SPATIAL_BUILDER = preload("res://scripts/character_spatial_rig_builder.gd")
const PROCEDURAL_ANIMATOR = preload("res://scripts/character_procedural_animator.gd")

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
	var library: Dictionary = animator.generate_pose_library()
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

	var sprite_rig: Node2D = builder.build_segmented_sprite_rig(prepared.parts, {}, Vector2i(128, 256))
	root.add_child(sprite_rig)
	if not builder.play_animation(sprite_rig, "walk"):
		push_error("No se pudo reproducir la animación walk del rig segmentado.")
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
