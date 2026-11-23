extends Control

class DrawingCanvas:
	extends Control

	var strokes: Array[PackedVector2Array] = []
	var current_stroke := PackedVector2Array()
	var is_drawing := false

	func _ready() -> void:
		custom_minimum_size = Vector2(900, 620)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_drawing = true
				current_stroke = PackedVector2Array([event.position])
				queue_redraw()
			else:
				is_drawing = false
				if current_stroke.size() > 1:
					strokes.append(current_stroke)
				current_stroke = PackedVector2Array()
				queue_redraw()
		elif event is InputEventMouseMotion and is_drawing:
			current_stroke.append(event.position)
			queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#fffdf8"), true)
		var grid_step := 32
		for x in range(0, int(size.x), grid_step):
			draw_line(Vector2(x, 0), Vector2(x, size.y), Color("#edf0f2"), 1.0)
		for y in range(0, int(size.y), grid_step):
			draw_line(Vector2(0, y), Vector2(size.x, y), Color("#edf0f2"), 1.0)
		for stroke in strokes:
			if stroke.size() > 1:
				draw_polyline(stroke, Color("#263238"), 4.0, true)
		if current_stroke.size() > 1:
			draw_polyline(current_stroke, Color("#263238"), 4.0, true)

	func clear_canvas() -> void:
		strokes.clear()
		current_stroke = PackedVector2Array()
		queue_redraw()

	func undo() -> void:
		if not strokes.is_empty():
			strokes.pop_back()
			queue_redraw()

	func to_data() -> Array:
		var result: Array = []
		for stroke in strokes:
			var points: Array = []
			for point in stroke:
				points.append([point.x, point.y])
			result.append(points)
		return result

	func from_data(data: Array) -> void:
		strokes.clear()
		for stroke_data in data:
			var stroke := PackedVector2Array()
			for point in stroke_data:
				if point is Array and point.size() >= 2:
					stroke.append(Vector2(float(point[0]), float(point[1])))
			if not stroke.is_empty():
				strokes.append(stroke)
		queue_redraw()


var canvas: DrawingCanvas
var frames: Array = []
var current_frame := 0
var play_timer: Timer
var status_label: Label
var frame_label: Label
var is_playing := false
var layer_list: VBoxContainer


func _ready() -> void:
	_build_interface()
	frames = [[]]
	_load_frame(0)
	play_timer = Timer.new()
	play_timer.wait_time = 0.12
	play_timer.timeout.connect(_on_play_tick)
	add_child(play_timer)
	_update_timeline()


func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 54
	header.add_theme_constant_override("separation", 10)
	root.add_child(header)

	var title := Label.new()
	title.text = "  ANIMATION STUDIO MANAGER"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#17324d"))
	header.add_child(title)

	_add_button(header, "Nuevo fotograma", _on_add_frame)
	_add_button(header, "Reproducir", _on_play)
	_add_button(header, "Guardar", _on_save)
	_add_button(header, "Abrir", _on_open)

	var separator := HSeparator.new()
	root.add_child(separator)

	var workspace := HBoxContainer.new()
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.add_theme_constant_override("separation", 8)
	root.add_child(workspace)

	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size.x = 190
	workspace.add_child(left_panel)
	var left_box := VBoxContainer.new()
	left_box.add_theme_constant_override("separation", 8)
	left_panel.add_child(left_box)
	var tools_title := Label.new()
	tools_title.text = "HERRAMIENTAS"
	tools_title.add_theme_color_override("font_color", Color("#25618a"))
	left_box.add_child(tools_title)
	_add_button(left_box, "Lápiz", func(): _set_status("Lápiz activo: dibuja con el botón izquierdo."))
	_add_button(left_box, "Deshacer trazo", _on_undo)
	_add_button(left_box, "Limpiar lienzo", _on_clear)
	left_box.add_child(HSeparator.new())
	var layers_title := Label.new()
	layers_title.text = "CAPAS"
	layers_title.add_theme_color_override("font_color", Color("#25618a"))
	left_box.add_child(layers_title)
	layer_list = VBoxContainer.new()
	left_box.add_child(layer_list)
	var layer_item := Label.new()
	layer_item.text = "  ◉ Capa 1"
	layer_list.add_child(layer_item)
	var layer_note := Label.new()
	layer_note.text = "Capas múltiples: próxima etapa"
	layer_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layer_note.add_theme_font_size_override("font_size", 11)
	layer_note.add_theme_color_override("font_color", Color("#788796"))
	left_box.add_child(layer_note)

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.add_child(center)
	var canvas_header := HBoxContainer.new()
	center.add_child(canvas_header)
	var canvas_title := Label.new()
	canvas_title.text = "LIENZO"
	canvas_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas_title.add_theme_color_override("font_color", Color("#25618a"))
	canvas_header.add_child(canvas_title)
	frame_label = Label.new()
	canvas_header.add_child(frame_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(scroll)
	canvas = DrawingCanvas.new()
	scroll.add_child(canvas)

	var timeline_panel := PanelContainer.new()
	timeline_panel.custom_minimum_size.y = 132
	root.add_child(timeline_panel)
	var timeline_box := VBoxContainer.new()
	timeline_panel.add_child(timeline_box)
	var timeline_header := HBoxContainer.new()
	timeline_box.add_child(timeline_header)
	var timeline_title := Label.new()
	timeline_title.text = "LÍNEA DE TIEMPO"
	timeline_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timeline_title.add_theme_color_override("font_color", Color("#25618a"))
	timeline_header.add_child(timeline_title)
	_add_button(timeline_header, "＋ Fotograma", _on_add_frame)
	var timeline_scroll := ScrollContainer.new()
	timeline_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	timeline_box.add_child(timeline_scroll)
	var timeline_row := HBoxContainer.new()
	timeline_row.name = "FrameButtons"
	timeline_scroll.add_child(timeline_row)

	status_label = Label.new()
	status_label.text = "Listo. Dibuja en el lienzo para comenzar."
	status_label.custom_minimum_size.y = 24
	status_label.add_theme_color_override("font_color", Color("#607080"))
	root.add_child(status_label)


func _add_button(parent: Node, text_value: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size.y = 34
	button.pressed.connect(callback)
	parent.add_child(button)


func _set_status(message: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = message


func _sync_current_frame() -> void:
	if frames.is_empty():
		frames.append(canvas.to_data())
	else:
		frames[current_frame] = canvas.to_data()


func _load_frame(index: int) -> void:
	if index < 0 or index >= frames.size():
		return
	current_frame = index
	canvas.from_data(frames[current_frame])
	if is_instance_valid(frame_label):
		frame_label.text = "Fotograma %d / %d" % [current_frame + 1, frames.size()]
	_update_timeline()


func _update_timeline() -> void:
	if not is_instance_valid(frame_label):
		return
	frame_label.text = "Fotograma %d / %d" % [current_frame + 1, frames.size()]
	var row := get_node_or_null("VBoxContainer/PanelContainer/VBoxContainer/ScrollContainer/FrameButtons")
	if row == null:
		row = _find_frame_button_row(self)
	if row == null:
		return
	for child in row.get_children():
		child.queue_free()
	for i in range(frames.size()):
		var frame_button := Button.new()
		frame_button.text = str(i + 1)
		frame_button.custom_minimum_size = Vector2(54, 42)
		frame_button.modulate = Color("#cce8ff") if i == current_frame else Color.WHITE
		frame_button.pressed.connect(_select_frame.bind(i))
		row.add_child(frame_button)


func _find_frame_button_row(node: Node) -> Node:
	if node.name == "FrameButtons":
		return node
	for child in node.get_children():
		var found := _find_frame_button_row(child)
		if found != null:
			return found
	return null


func _select_frame(index: int) -> void:
	_sync_current_frame()
	_load_frame(index)


func _on_add_frame() -> void:
	_sync_current_frame()
	frames.append([])
	_load_frame(frames.size() - 1)
	_set_status("Nuevo fotograma creado.")


func _on_undo() -> void:
	canvas.undo()
	_sync_current_frame()


func _on_clear() -> void:
	canvas.clear_canvas()
	_sync_current_frame()
	_set_status("Lienzo limpiado.")


func _on_play() -> void:
	if frames.size() < 2:
		_set_status("Agrega al menos dos fotogramas para reproducir.")
		return
	_sync_current_frame()
	is_playing = not is_playing
	if is_playing:
		play_timer.start()
		_set_status("Reproduciendo animación…")
	else:
		play_timer.stop()
		_set_status("Reproducción pausada.")


func _on_play_tick() -> void:
	if frames.is_empty():
		return
	_load_frame((current_frame + 1) % frames.size())


func _on_save() -> void:
	_sync_current_frame()
	var project_data := {
		"format": "AnimationStudioManager",
		"version": 1,
		"fps": 8,
		"frames": frames
	}
	var file := FileAccess.open("user://animation_studio_project.json", FileAccess.WRITE)
	if file == null:
		_set_status("No se pudo guardar el proyecto.")
		return
	file.store_string(JSON.stringify(project_data, "\t"))
	file.close()
	_set_status("Proyecto guardado en user://animation_studio_project.json")


func _on_open() -> void:
	var path := "user://animation_studio_project.json"
	if not FileAccess.file_exists(path):
		_set_status("Todavía no existe un proyecto guardado.")
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_set_status("No se pudo abrir el archivo.")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("frames"):
		_set_status("El archivo de proyecto no tiene un formato válido.")
		return
	frames = parsed["frames"]
	if frames.is_empty():
		frames = [[]]
	_load_frame(0)
	_set_status("Proyecto cargado correctamente.")
