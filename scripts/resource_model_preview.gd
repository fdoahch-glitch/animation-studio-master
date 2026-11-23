extends SubViewportContainer
class_name ResourceModelPreview

const VIEWPORT_SIZE := Vector2i(512, 384)

var preview_viewport: SubViewport
var preview_world: Node3D
var model_pivot: Node3D
var preview_camera: Camera3D
var is_dragging := false
var last_pointer := Vector2.ZERO
var loaded_path := ""

func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	preview_viewport = SubViewport.new()
	preview_viewport.size = VIEWPORT_SIZE
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(preview_viewport)
	preview_world = Node3D.new()
	preview_viewport.add_child(preview_world)
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#172536")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#dce8f4")
	environment.ambient_light_energy = 0.85
	world_environment.environment = environment
	preview_world.add_child(world_environment)
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-32.0, -35.0, 0.0)
	key_light.light_energy = 1.35
	preview_world.add_child(key_light)
	var fill_light := DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(-18.0, 145.0, 0.0)
	fill_light.light_energy = 0.45
	preview_world.add_child(fill_light)
	preview_camera = Camera3D.new()
	preview_camera.current = true
	preview_camera.fov = 42.0
	preview_world.add_child(preview_camera)
	preview_camera.position = Vector3(2.5, 1.8, 4.5)
	preview_camera.look_at(Vector3.ZERO, Vector3.UP)

func load_model(path: String) -> Dictionary:
	if not is_inside_tree():
		return {"ok": false, "error": "La vista previa todavía no está dentro del árbol de escena."}
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "No existe el archivo GLB/glTF seleccionado."}
	clear_model()
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error := document.append_from_file(path, state)
	if error != OK:
		return {"ok": false, "error": "Godot no pudo importar el archivo: %s" % error_string(error)}
	var generated: Node = document.generate_scene(state)
	if generated == null:
		return {"ok": false, "error": "El archivo no generó una escena 3D válida."}
	model_pivot = Node3D.new()
	model_pivot.name = "PreviewModelPivot"
	preview_world.add_child(model_pivot)
	model_pivot.add_child(generated)
	loaded_path = path
	_fit_camera(generated)
	return {"ok": true, "path": path, "node_count": generated.get_child_count()}

func has_model() -> bool:
	return is_instance_valid(model_pivot) and not loaded_path.is_empty()

func clear_model() -> void:
	if is_instance_valid(model_pivot):
		preview_world.remove_child(model_pivot)
		model_pivot.free()
	model_pivot = null
	loaded_path = ""

func _fit_camera(model_root: Node) -> void:
	var minimum := Vector3(INF, INF, INF)
	var maximum := Vector3(-INF, -INF, -INF)
	var found_mesh := false
	var meshes := model_root.find_children("*", "MeshInstance3D", true, false)
	for candidate in meshes:
		var mesh_instance := candidate as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var local_bounds := mesh_instance.get_aabb()
		for corner_index in range(8):
			var point := mesh_instance.global_transform * local_bounds.get_endpoint(corner_index)
			minimum = minimum.min(point)
			maximum = maximum.max(point)
			found_mesh = true
	if not found_mesh:
		minimum = Vector3(-0.5, -0.5, -0.5)
		maximum = Vector3(0.5, 0.5, 0.5)
	var center := (minimum + maximum) * 0.5
	var dimensions := maximum - minimum
	var largest_dimension := maxf(dimensions.x, maxf(dimensions.y, dimensions.z))
	model_pivot.position = -center
	var distance := maxf(1.5, largest_dimension * 1.85)
	preview_camera.position = Vector3(distance * 0.9, distance * 0.58, distance * 1.85)
	preview_camera.look_at(Vector3.ZERO, Vector3.UP)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			last_pointer = event.position
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_camera(0.88)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_camera(1.14)
			accept_event()
	elif event is InputEventMouseMotion and is_dragging and is_instance_valid(model_pivot):
		var delta := event.position - last_pointer
		model_pivot.rotate_y(-delta.x * 0.012)
		last_pointer = event.position
		accept_event()

func _zoom_camera(factor: float) -> void:
	if not is_instance_valid(preview_camera):
		return
	preview_camera.position *= factor
	var distance := preview_camera.position.length()
	if distance < 0.6:
		preview_camera.position = preview_camera.position.normalized() * 0.6
	elif distance > 80.0:
		preview_camera.position = preview_camera.position.normalized() * 80.0
	preview_camera.look_at(Vector3.ZERO, Vector3.UP)
