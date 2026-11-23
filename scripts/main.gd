extends Control

const CHARACTER_AI = preload("res://scripts/character_ai.gd")
const CHARACTER_RIG_BUILDER = preload("res://scripts/character_rig_builder.gd")
const CHARACTER_IMAGE_PROCESSOR = preload("res://scripts/character_image_processor.gd")
const CHARACTER_PROCEDURAL_ANIMATOR = preload("res://scripts/character_procedural_animator.gd")
const CHARACTER_SPATIAL_RIG_BUILDER = preload("res://scripts/character_spatial_rig_builder.gd")
const DEFAULT_PROJECT := {"name":"Mi primera animación","width":1920,"height":1080,"fps":60,"orientation":"Horizontal","visual_mode":"2D","background_mode":"Vacío"}

var project_data: Dictionary = DEFAULT_PROJECT.duplicate(true)
var ai
var rig_builder
var spatial_builder
var runtime_spatial_rig: Node3D
var spatial_subviewport: SubViewport
var spatial_container: SubViewportContainer
var rig_2d_container: SubViewportContainer
var image_processor
var procedural_animator
var imported_source_path := ""
var image_dialog: FileDialog
var imported_preview: TextureRect
var image_result_output: RichTextLabel
var build_segmented_button: Button
var animation_controls: GridContainer
var pose_controls: GridContainer
var imported_character_data: Dictionary = {}
var ai_generated_poses: Array = []
var runtime_rig: Node2D
var rig_subviewport: SubViewport
var root_ui: VBoxContainer
var content: Control
var status_label: Label
var wizard_name: LineEdit
var wizard_width: OptionButton
var wizard_height: OptionButton
var wizard_fps: OptionButton
var wizard_mode: OptionButton
var wizard_orientation: OptionButton
var wizard_background: OptionButton
var character_name: LineEdit
var character_description: TextEdit
var character_style: OptionButton
var character_mode: OptionButton
var character_view: OptionButton
var character_preview
var character_output: RichTextLabel
var skeleton_output: RichTextLabel
var generated_character: Dictionary = {}

class CharacterPreview:
	extends Control
	var view_name := "Frente"
	var character_label := "Personaje"
	var rig_data: Dictionary = {}
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#f4f7fb"), true)
		for x in range(0, int(size.x), 40):
			draw_line(Vector2(x, 0), Vector2(x, size.y), Color("#e5ebf2"), 1.0)
		for y in range(0, int(size.y), 40):
			draw_line(Vector2(0, y), Vector2(size.x, y), Color("#e5ebf2"), 1.0)
		var cx := size.x * 0.5
		var top := size.y * 0.14
		var sf := min(size.x / 420.0, size.y / 560.0)
		var skin := Color("#e5a878")
		var cloth := Color("#2878b8")
		var dark := Color("#23384d")
		var side := view_name == "Perfil"
		var back := view_name == "Espalda"
		var head := Vector2(cx, top + 58 * sf)
		draw_circle(head, (38.0 if side or back else 52.0) * sf, skin)
		if not back:
			draw_circle(head + Vector2(-10 if not side else 6, -2) * sf, 3.5 * sf, dark)
			if not side:
				draw_circle(head + Vector2(10, -2) * sf, 3.5 * sf, dark)
		var shoulder_y := top + 132 * sf
		var hip_y := top + 300 * sf
		var span := (25.0 if side else 42.0) * sf
		draw_colored_polygon(PackedVector2Array([Vector2(cx-span,shoulder_y),Vector2(cx+span,shoulder_y),Vector2(cx+31*sf,hip_y),Vector2(cx-31*sf,hip_y)]), cloth)
		for sign in [-1.0, 1.0]:
			var shoulder := Vector2(cx + sign * span * 0.8, shoulder_y)
			var elbow := shoulder + Vector2(sign * 25 * sf, 75 * sf)
			var wrist := elbow + Vector2(sign * 8 * sf, 65 * sf)
			draw_line(shoulder, elbow, skin, 10 * sf)
			draw_line(elbow, wrist, skin, 8 * sf)
			var hip := Vector2(cx + sign * 19 * sf, hip_y)
			var knee := hip + Vector2(sign * 8 * sf, 82 * sf)
			var ankle := knee + Vector2(-sign * 4 * sf, 76 * sf)
			draw_line(hip, knee, dark, 13 * sf)
			draw_line(knee, ankle, dark, 11 * sf)
		draw_string(ThemeDB.fallback_font, Vector2(16, size.y-18), view_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#42566b"))

func _ready() -> void:
	ai = CHARACTER_AI.new()
	rig_builder = CHARACTER_RIG_BUILDER.new()
	spatial_builder = CHARACTER_SPATIAL_RIG_BUILDER.new()
	image_processor = CHARACTER_IMAGE_PROCESSOR.new()
	procedural_animator = CHARACTER_PROCEDURAL_ANIMATOR.new()
	ai.name = "CharacterAI"
	add_child(ai)
	_build_shell()
	image_dialog = FileDialog.new()
	image_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	image_dialog.access = FileDialog.ACCESS_FILESYSTEM
	image_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Imágenes de personaje"])
	image_dialog.file_selected.connect(_on_character_image_selected)
	add_child(image_dialog)
	_show_wizard()

func _build_shell() -> void:
	root_ui = VBoxContainer.new()
	root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.add_theme_constant_override("separation", 0)
	add_child(root_ui)
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 58
	root_ui.add_child(header)
	var brand := Label.new()
	brand.text = "  ANIMATION STUDIO MANAGER"
	brand.add_theme_font_size_override("font_size", 20)
	brand.add_theme_color_override("font_color", Color("#17324d"))
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)
	_add_button(header, "Nuevo proyecto", _show_wizard)
	_add_button(header, "Guardar proyecto", _save_project)
	_add_button(header, "Estudio de personajes", _show_character_lab)
	root_ui.add_child(HSeparator.new())
	content = Control.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_ui.add_child(content)
	status_label = Label.new()
	status_label.text = "Bienvenido. Crea un proyecto para comenzar."
	status_label.custom_minimum_size.y = 28
	status_label.add_theme_color_override("font_color", Color("#536779"))
	root_ui.add_child(status_label)

func _clear_content() -> void:
	for child in content.get_children():
		child.queue_free()

func _add_button(parent: Node, label_text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size.y = 36
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _add_heading(parent: Node, heading: String, subheading := "") -> void:
	var box := VBoxContainer.new()
	parent.add_child(box)
	var title := Label.new()
	title.text = heading
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("#17324d"))
	box.add_child(title)
	if subheading != "":
		var detail := Label.new()
		detail.text = subheading
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_theme_color_override("font_color", Color("#61758a"))
		box.add_child(detail)

func _add_option(parent: Node, label_text: String, options: Array, selected := 0) -> OptionButton:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 170
	row.add_child(label)
	var picker := OptionButton.new()
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for item in options:
		picker.add_item(str(item))
	picker.select(selected)
	row.add_child(picker)
	return picker

func _show_wizard() -> void:
	_clear_content()
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(scroll)
	var page := VBoxContainer.new()
	page.custom_minimum_size = Vector2(680, 0)
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 12)
	scroll.add_child(page)
	_add_heading(page, "Crear un nuevo proyecto", "Configura tu película o serie antes de abrir el lienzo.")
	var name_row := HBoxContainer.new()
	page.add_child(name_row)
	var name_label := Label.new()
	name_label.text = "Nombre del proyecto"
	name_label.custom_minimum_size.x = 170
	name_row.add_child(name_label)
	wizard_name = LineEdit.new()
	wizard_name.text = str(project_data.get("name", "Mi animación"))
	wizard_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(wizard_name)
	wizard_width = _add_option(page, "Ancho", ["1280","1920","2560","3840"], 1)
	wizard_height = _add_option(page, "Alto", ["720","1080","1440","2160"], 1)
	wizard_fps = _add_option(page, "Fotogramas por segundo", ["24","25","30","50","60"], 4)
	wizard_orientation = _add_option(page, "Orientación", ["Horizontal","Vertical","Cuadrada"], 0)
	wizard_mode = _add_option(page, "Espacio de trabajo", ["2D","2.5D","3D","Híbrido"], 0)
	wizard_background = _add_option(page, "Fondo inicial", ["Vacío","Biblioteca","Importar imagen","Capas manuales"], 0)
	var note := Label.new()
	note.text = "Recomendado: 1920 × 1080 · 60 FPS. El modo elegido filtrará los recursos y herramientas disponibles."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", Color("#2878b8"))
	page.add_child(note)
	_add_button(page, "Crear proyecto y abrir estudio", _create_project)

func _create_project() -> void:
	var widths := [1280,1920,2560,3840]
	var heights := [720,1080,1440,2160]
	var fps_values := [24,25,30,50,60]
	project_data = {
		"schema_version": 1,
		"name": wizard_name.text.strip_edges() if wizard_name.text.strip_edges() != "" else "Mi animación",
		"width": widths[wizard_width.selected],
		"height": heights[wizard_height.selected],
		"fps": fps_values[wizard_fps.selected],
		"orientation": wizard_orientation.get_item_text(wizard_orientation.selected),
		"visual_mode": wizard_mode.get_item_text(wizard_mode.selected),
		"background_mode": wizard_background.get_item_text(wizard_background.selected),
		"scenes": [], "characters": [], "assets": []
	}
	_save_project()
	_show_workspace()
	_set_status("Proyecto creado: %d × %d a %d FPS · %s" % [project_data.width,project_data.height,project_data.fps,project_data.visual_mode])

func _show_workspace() -> void:
	_clear_content()
	var layout := HBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(layout)
	var nav := VBoxContainer.new()
	nav.custom_minimum_size.x = 190
	nav.add_theme_constant_override("separation", 5)
	layout.add_child(nav)
	for section in ["Escenas","Personajes","Fondos","Elementos","Decoraciones","Tiempo y clima","Animación","Audio y doblaje","Exportar"]:
		_add_button(nav, section, _open_section.bind(section))
	var main_panel := VBoxContainer.new()
	main_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_panel.add_theme_constant_override("separation", 12)
	layout.add_child(main_panel)
	_add_heading(main_panel, str(project_data.name), "%d × %d · %d FPS · %s" % [project_data.width,project_data.height,project_data.fps,project_data.visual_mode])
	var card := PanelContainer.new()
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_panel.add_child(card)
	var instruction := Label.new()
	instruction.text = "ESCENARIO DE TRABAJO\n\nArrastra aquí personajes, fondos, elementos y decoraciones.\nSelecciona un recurso para abrir su inspector y definir acciones."
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instruction.size_flags_vertical = Control.SIZE_EXPAND_FILL
	instruction.add_theme_font_size_override("font_size", 19)
	card.add_child(instruction)
	_add_button(main_panel, "Abrir asistente de personajes", _show_character_lab)

func _open_section(section: String) -> void:
	if section == "Personajes":
		_show_character_lab()
		return
	_clear_content()
	var page := VBoxContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("separation", 10)
	content.add_child(page)
	_add_heading(page, section, "Panel de trabajo del proyecto: " + str(project_data.name))
	var info := Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	match section:
		"Fondos": info.text = "Biblioteca e importación de fondos. Próximo módulo: segmentación asistida, planos de profundidad, máscaras y parallax."
		"Elementos": info.text = "Biblioteca de objetos del mundo, puntos de anclaje, colisiones y acciones."
		"Decoraciones": info.text = "Vegetación, partículas, viento, agua, nubes, polvo y detalles ambientales."
		"Tiempo y clima": info.text = "Amanecer, mañana, mediodía, tarde, atardecer o noche; hora exacta, lluvia, nieve, viento y niebla."
		"Animación": info.text = "Línea de tiempo por pistas, keyframes, rutas, curvas y cámara."
		"Audio y doblaje": info.text = "Estudio de grabación por escenas: cuenta atrás 3-2-1, subtítulos guía, tomas y pistas sincronizadas."
		"Exportar": info.text = "Exportación final con resolución, FPS, vídeo, audio y subtítulos."
		_: info.text = "Organiza escenas, capítulos, duración y transiciones."
	page.add_child(info)
	_add_button(page, "Volver al escenario", _show_workspace)
	_set_status(section + " · interfaz inicial; funciones avanzadas pendientes.")

func _show_character_lab() -> void:
	_clear_content()
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(scroll)
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 10)
	scroll.add_child(page)
	_add_heading(page, "Estudio de personajes", "Diseña una ficha, prepara vistas y crea una propuesta de esqueleto editable.")
	var columns := HBoxContainer.new()
	page.add_child(columns)
	var form := VBoxContainer.new()
	form.custom_minimum_size.x = 350
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(form)
	var name_row := HBoxContainer.new()
	form.add_child(name_row)
	var name_label := Label.new()
	name_label.text = "Nombre"
	name_label.custom_minimum_size.x = 100
	name_row.add_child(name_label)
	character_name = LineEdit.new()
	character_name.placeholder_text = "Ej. Lía"
	character_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(character_name)
	form.add_child(Label.new())
	var desc_label := Label.new()
	desc_label.text = "Describe el personaje"
	form.add_child(desc_label)
	character_description = TextEdit.new()
	character_description.custom_minimum_size.y = 110
	character_description.placeholder_text = "Personalidad, ropa, colores, proporciones, accesorios..."
	form.add_child(character_description)
	character_style = _add_option(form, "Estilo", ["Cartoon 3D","2D ilustrado","Anime original","Realista estilizado"], 0)
	character_mode = _add_option(form, "Tipo de rig", ["2D esquelético","2.5D por planos","3D esqueleto","Híbrido"], 0)
	character_view = _add_option(form, "Vista previa", ["Frente","Perfil","Espalda","Tres cuartos"], 0)
	character_view.item_selected.connect(_on_character_view_changed)
	_add_button(form, "Importar imagen y preparar piezas", _open_character_image_dialog)
	build_segmented_button = _add_button(form, "Construir rig con las piezas recortadas", _build_imported_segment_rig)
	build_segmented_button.disabled = true
	_add_button(form, "Generar poses y animaciones procedurales", _generate_procedural_pose_set)
	_add_button(form, "Crear diseño base + esqueleto", _generate_character)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.custom_minimum_size.x = 420
	columns.add_child(right)
	character_preview = CharacterPreview.new()
	character_preview.custom_minimum_size = Vector2(420,300)
	character_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(character_preview)
	var rig_title := Label.new()
	rig_title.text = "RIG 2D EDITABLE · VISTA EN TIEMPO REAL"
	right.add_child(rig_title)
	rig_2d_container = SubViewportContainer.new()
	var rig_container := rig_2d_container
	rig_container.custom_minimum_size = Vector2(420,280)
	rig_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rig_container.stretch = true
	right.add_child(rig_container)
	rig_subviewport = SubViewport.new()
	rig_subviewport.size = Vector2i(420,280)
	rig_subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	rig_subviewport.transparent_bg = false
	rig_container.add_child(rig_subviewport)
	spatial_container = SubViewportContainer.new()
	spatial_container.custom_minimum_size = Vector2(420, 280)
	spatial_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spatial_container.stretch = true
	spatial_container.visible = false
	right.add_child(spatial_container)
	spatial_subviewport = SubViewport.new()
	spatial_subviewport.size = Vector2i(420, 280)
	spatial_subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	spatial_subviewport.own_world_3d = true
	spatial_container.add_child(spatial_subviewport)
	var spatial_camera := Camera3D.new()
	spatial_camera.position = Vector3(0, 1.2, 3.6)
	spatial_camera.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	spatial_camera.current = true
	spatial_subviewport.add_child(spatial_camera)
	var spatial_light := DirectionalLight3D.new()
	spatial_light.rotation_degrees = Vector3(-25, -25, 0)
	spatial_subviewport.add_child(spatial_light)
	var rig_background := ColorRect.new()
	rig_background.color = Color("#f4f7fb")
	rig_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rig_subviewport.add_child(rig_background)
	animation_controls = GridContainer.new()
	animation_controls.columns = 3
	right.add_child(animation_controls)
	for animation_name in ["idle","walk","run","jump","talk","wave"]:
		_add_button(animation_controls, animation_name.capitalize(), _play_rig_animation.bind(animation_name))
	var pose_title := Label.new()
	pose_title.text = "BIBLIOTECA DE POSES PROCEDURALES"
	right.add_child(pose_title)
	pose_controls = GridContainer.new()
	pose_controls.columns = 3
	right.add_child(pose_controls)
	var joint_title := Label.new()
	joint_title.text = "AJUSTE MANUAL DE ARTICULACIONES"
	right.add_child(joint_title)
	_add_joint_control(right, "Hombro izquierdo", "Pelvis/Spine/Chest/Shoulder_L", -120.0, 120.0)
	_add_joint_control(right, "Codo izquierdo", "Pelvis/Spine/Chest/Shoulder_L/Elbow_L", -10.0, 150.0)
	_add_joint_control(right, "Hombro derecho", "Pelvis/Spine/Chest/Shoulder_R", -120.0, 120.0)
	_add_joint_control(right, "Codo derecho", "Pelvis/Spine/Chest/Shoulder_R/Elbow_R", -10.0, 150.0)
	_add_joint_control(right, "Cadera izquierda", "Pelvis/Hip_L", -100.0, 100.0)
	_add_joint_control(right, "Rodilla izquierda", "Pelvis/Hip_L/Knee_L", -5.0, 150.0)
	_add_joint_control(right, "Cadera derecha", "Pelvis/Hip_R", -100.0, 100.0)
	_add_joint_control(right, "Rodilla derecha", "Pelvis/Hip_R/Knee_R", -5.0, 150.0)
	var position_title := Label.new()
	position_title.text = "POSICIÓN DE PIVOTES (X / Y)"
	right.add_child(position_title)
	_add_pivot_offset_control(right, "Hombro izquierdo X", "shoulder_left", "x")
	_add_pivot_offset_control(right, "Hombro izquierdo Y", "shoulder_left", "y")
	_add_pivot_offset_control(right, "Codo izquierdo X", "elbow_left", "x")
	_add_pivot_offset_control(right, "Codo izquierdo Y", "elbow_left", "y")
	_add_pivot_offset_control(right, "Hombro derecho X", "shoulder_right", "x")
	_add_pivot_offset_control(right, "Hombro derecho Y", "shoulder_right", "y")
	imported_preview = TextureRect.new()
	imported_preview.custom_minimum_size = Vector2(420, 220)
	imported_preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	imported_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	right.add_child(imported_preview)
	image_result_output = RichTextLabel.new()
	image_result_output.fit_content = true
	image_result_output.custom_minimum_size.y = 100
	image_result_output.text = "Importa una ilustración PNG/JPG/WebP para eliminar un fondo plano y preparar recortes anatómicos aproximados."
	right.add_child(image_result_output)
	character_output = RichTextLabel.new()
	character_output.fit_content = true
	character_output.custom_minimum_size.y = 75
	character_output.text = "Vista esquemática de referencia. El arte final se importa; las poses y animaciones se generan dentro del programa."
	right.add_child(character_output)
	page.add_child(Label.new())
	var skeleton_title := Label.new()
	skeleton_title.text = "ESQUELETO PROPUESTO"
	skeleton_title.add_theme_color_override("font_color", Color("#2878b8"))
	page.add_child(skeleton_title)
	skeleton_output = RichTextLabel.new()
	skeleton_output.fit_content = true
	skeleton_output.custom_minimum_size.y = 110
	skeleton_output.text = "Genera un personaje para ver huesos, articulaciones y pivotes sugeridos."
	page.add_child(skeleton_output)
	_add_button(page, "Volver al escenario", _show_workspace)

func _on_character_view_changed(index: int) -> void:
	if is_instance_valid(character_preview):
		character_preview.view_name = character_view.get_item_text(index)
		character_preview.queue_redraw()

func _open_character_image_dialog() -> void:
	if image_dialog != null:
		image_dialog.popup_centered_ratio(0.82)

func _on_character_image_selected(path: String) -> void:
	_set_status("Analizando imagen y preparando recortes...")
	var result: Dictionary = image_processor.process_character_image(path, 0.16)
	if not bool(result.get("ok", false)):
		image_result_output.text = "No se pudo preparar la imagen: " + str(result.get("error", "Error desconocido"))
		_set_status("La preparación de imagen no se completó.")
		return
	imported_character_data = result
	imported_source_path = path
	if is_instance_valid(build_segmented_button):
		build_segmented_button.disabled = false
	var preview_image := Image.new()
	var load_error := preview_image.load(str(result.get("processed_image", "")))
	if load_error == OK:
		imported_preview.texture = ImageTexture.create_from_image(preview_image)
	var parts: Array = result.get("parts", [])
	var lines := PackedStringArray()
	lines.append("Imagen: %s × %s" % [result.width, result.height])
	lines.append("Píxeles de fondo retirados: %s" % result.background_removed_pixels)
	lines.append("Recortes preparados: %d" % parts.size())
	for part in parts:
		lines.append("• %s — %s" % [part.label, part.path])
	lines.append("Método: eliminación de fondo conectado + regiones proporcionales.")
	lines.append("IMPORTANTE: los recortes son aproximados; revisa y corrige las máscaras antes de riggear.")
	image_result_output.text = "\n".join(lines)
	if not project_data.has("image_imports"):
		project_data["image_imports"] = []
	project_data["image_imports"].append(result)
	_save_project()
	_set_status("Imagen preparada. Revisa los recortes y corrige las zonas antes de animar.")

func _generate_procedural_pose_set() -> void:
	if procedural_animator == null:
		procedural_animator = CHARACTER_PROCEDURAL_ANIMATOR.new()
	var generated: Dictionary = procedural_animator.generate_pose_library()
	ai_generated_poses = generated.get("poses", [])
	var clips: Array = generated.get("animations", [])
	var added := 0
	var applied := 0
	if is_instance_valid(runtime_rig):
		added = rig_builder.add_procedural_animation_set(runtime_rig, clips)
		if not ai_generated_poses.is_empty():
			applied = rig_builder.apply_procedural_pose(runtime_rig, ai_generated_poses[0].get("joint_angles", {}))
	if is_instance_valid(pose_controls):
		for child in pose_controls.get_children():
			child.queue_free()
		for pose in ai_generated_poses:
			_add_button(pose_controls, str(pose.get("name", "Pose")), _apply_generated_pose.bind(pose))
	if is_instance_valid(animation_controls):
		for child in animation_controls.get_children():
			child.queue_free()
		for clip in clips:
			var clip_key := "ai_" + str(clip.get("name", "generated")).validate_filename().to_lower()
			_add_button(animation_controls, str(clip.get("name", "Animación")), _play_rig_animation.bind(clip_key))
	var record := {"character": character_name.text if is_instance_valid(character_name) else "Personaje", "poses": ai_generated_poses, "animations": clips, "generator": "procedural_v1"}
	if not project_data.has("procedural_pose_sets"):
		project_data["procedural_pose_sets"] = []
	project_data["procedural_pose_sets"].append(record)
	_save_project()
	var lines := PackedStringArray()
	lines.append("GENERACIÓN PROCEDURAL COMPLETADA")
	lines.append("Poses listas: %d" % ai_generated_poses.size())
	lines.append("Ciclos de animación creados: %d" % clips.size())
	lines.append("Clips añadidos al rig actual: %d" % added)
	lines.append("Primera pose aplicada: %d articulaciones" % applied)
	lines.append("")
	lines.append("Poses: reposo, atención, feliz, triste, enojado, sorprendido, saludo, brazos arriba, brazos cruzados, señalar, agachado y preparado para correr.")
	lines.append("Animaciones: respirar, caminar, correr, saltar, saludar, hablar, celebrar, bailar, caminar lento, cojear, rebotar y mirar alrededor.")
	lines.append("Cálculo local determinista: curvas matemáticas y keyframes; sin conexión, modelos ni procesos externos.")
	if is_instance_valid(image_result_output):
		image_result_output.text = "\n".join(lines)
	_set_status("Generador procedural: %d poses y %d animaciones guardadas." % [ai_generated_poses.size(), clips.size()])

func _apply_generated_pose(pose: Dictionary) -> void:
	if not is_instance_valid(runtime_rig):
		_set_status("Primero crea el esqueleto del personaje.")
		return
	rig_builder.stop_animation(runtime_rig)
	var angles: Dictionary = pose.get("joint_angles", {})
	var applied := rig_builder.apply_procedural_pose(runtime_rig, angles)
	_set_status("Pose «%s» aplicada en %d articulaciones." % [str(pose.get("name", "Pose")), applied])

func _generate_character() -> void:
	var label := character_name.text.strip_edges()
	if label == "":
		label = "Personaje nuevo"
	generated_character = ai.build_character_blueprint(label, character_description.text.strip_edges(), character_mode.get_item_text(character_mode.selected))
	character_preview.character_label = label
	character_preview.rig_data = generated_character.rig
	character_preview.queue_redraw()
	character_output.text = "Ficha creada: %s\nEstilo: %s\nVistas de referencia: frente, perfil, espalda y tres cuartos. El dibujo visible es una guía esquemática; las poses se generan con el sistema procedural integrado." % [label,character_style.get_item_text(character_style.selected)]
	skeleton_output.text = ai.format_rig_summary(generated_character.rig)
	_build_runtime_character()
	if not project_data.has("characters"):
		project_data["characters"] = []
	project_data["characters"].append(generated_character)
	_save_project()
	_set_status("Ficha y esqueleto procedural creados y guardados. Revisa articulaciones antes de animar.")

func _build_runtime_character() -> void:
	if rig_subviewport == null:
		return
	if is_instance_valid(runtime_rig):
		runtime_rig.queue_free()
	if is_instance_valid(runtime_spatial_rig):
		runtime_spatial_rig.queue_free()
	var label := str(generated_character.get("name", character_name.text if character_name != null else "Personaje"))
	var selected_mode := character_mode.get_item_text(character_mode.selected)
	if selected_mode == "3D esqueleto":
		rig_2d_container.visible = false
		spatial_container.visible = true
		runtime_spatial_rig = spatial_builder.build_humanoid_3d(label)
		spatial_subviewport.add_child(runtime_spatial_rig)
		character_output.text = "Rig espacial 3D creado con Skeleton3D y piezas geométricas ancladas a huesos. Es una estructura de referencia; falta skinning de mallas artísticas y clips de animación 3D."
	elif selected_mode == "2.5D por planos":
		rig_2d_container.visible = false
		spatial_container.visible = true
		if imported_preview != null and imported_preview.texture != null:
			runtime_spatial_rig = Node3D.new()
			runtime_spatial_rig.name = "Character_2_5D"
			runtime_spatial_rig.add_child(spatial_builder.create_2_5d_plane(imported_preview.texture, "CharacterPlane", 0.0))
			spatial_subviewport.add_child(runtime_spatial_rig)
			character_output.text = "Plano 2.5D creado desde la imagen importada. La profundidad y el parallax se pueden ampliar con más capas."
		else:
			rig_2d_container.visible = true
			spatial_container.visible = false
			runtime_rig = rig_builder.build_runtime_rig(label, 1.0)
			runtime_rig.position = Vector2(210, 145)
			rig_subviewport.add_child(runtime_rig)
			rig_builder.play_animation(runtime_rig, "idle")
			character_output.text = "Importa una imagen para crear el plano 2.5D; se muestra temporalmente el rig 2D."
	else:
		rig_2d_container.visible = true
		spatial_container.visible = false
		runtime_rig = rig_builder.build_runtime_rig(label, 1.0)
		runtime_rig.position = Vector2(210, 145)
		rig_subviewport.add_child(runtime_rig)
		rig_builder.play_animation(runtime_rig, "idle")

func _build_imported_segment_rig() -> void:
	var parts: Array = imported_character_data.get("ai_segments", imported_character_data.get("parts", []))
	if parts.is_empty():
		_set_status("No hay piezas recortadas para construir el rig.")
		return
	var joints: Dictionary = imported_character_data.get("ai_joints", {})
	var source_size := Vector2i(int(imported_character_data.get("width", 1)), int(imported_character_data.get("height", 1)))
	if is_instance_valid(runtime_rig):
		runtime_rig.queue_free()
	if is_instance_valid(runtime_spatial_rig):
		runtime_spatial_rig.queue_free()
	rig_2d_container.visible = true
	spatial_container.visible = false
	runtime_rig = rig_builder.build_segmented_sprite_rig(parts, joints, source_size, Vector2(210, 245))
	runtime_rig.position = Vector2(210, 145)
	rig_subviewport.add_child(runtime_rig)
	rig_builder.play_animation(runtime_rig, "idle")
	if imported_character_data.has("ai_segments"):
		character_output.text = "Rig construido con recortes locales y pivotes estimados. Revisa las máscaras, pivotes y solapamientos; las piezas aún pueden requerir corrección."
	else:
		character_output.text = "Rig de prueba construido con regiones proporcionales. Son recortes aproximados, no segmentación semántica; ajusta los pivotes y las piezas manualmente si es necesario."
	_set_status("Rig de imagen creado. Prueba las animaciones y corrige los pivotes.")

func _add_joint_control(parent: Node, label_text: String, joint_path: String, minimum: float, maximum: float) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 145
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = 1.0
	slider.value = 0.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_joint_slider_changed.bind(joint_path))
	row.add_child(slider)

func _add_pivot_offset_control(parent: Node, label_text: String, pivot_name: String, axis: String) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 145
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = -60.0
	slider.max_value = 60.0
	slider.step = 1.0
	slider.value = 0.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_pivot_offset_changed.bind(pivot_name, axis))
	row.add_child(slider)

func _on_pivot_offset_changed(value: float, pivot_name: String, axis: String) -> void:
	if is_instance_valid(runtime_rig):
		rig_builder.set_pivot_offset(runtime_rig, pivot_name, axis, value)

func _on_joint_slider_changed(value: float, joint_path: String) -> void:
	if not is_instance_valid(runtime_rig):
		return
	rig_builder.stop_animation(runtime_rig)
	var normalized := joint_path.to_lower()
	var pivot_key := ""
	if normalized.contains("shoulder_l"):
		pivot_key = "shoulder_left"
	elif normalized.contains("shoulder_r"):
		pivot_key = "shoulder_right"
	elif normalized.contains("elbow_l"):
		pivot_key = "elbow_left"
	elif normalized.contains("elbow_r"):
		pivot_key = "elbow_right"
	elif normalized.contains("hip_l"):
		pivot_key = "hip_left"
	elif normalized.contains("hip_r"):
		pivot_key = "hip_right"
	elif normalized.contains("knee_l"):
		pivot_key = "knee_left"
	elif normalized.contains("knee_r"):
		pivot_key = "knee_right"
	if pivot_key != "" and runtime_rig.find_child("Pivot_" + pivot_key, true, false) != null:
		rig_builder.apply_segment_pose(runtime_rig, {pivot_key: value})
	else:
		rig_builder.set_joint_rotation(runtime_rig, NodePath(joint_path), value)

func _play_rig_animation(animation_name: String) -> void:
	if is_instance_valid(runtime_rig):
		rig_builder.play_animation(runtime_rig, animation_name)

func _save_project() -> void:
	var file := FileAccess.open("user://animation_studio_manager_project.json", FileAccess.WRITE)
	if file == null:
		_set_status("No se pudo guardar el proyecto.")
		return
	file.store_string(JSON.stringify(project_data, "\t"))
	file.close()
	_set_status("Proyecto guardado localmente.")

func _set_status(message: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = message
