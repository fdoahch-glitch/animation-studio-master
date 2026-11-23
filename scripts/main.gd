extends Control

const CHARACTER_BLUEPRINT_BUILDER = preload("res://scripts/character_blueprint_builder.gd")
const CHARACTER_RIG_BUILDER = preload("res://scripts/character_rig_builder.gd")
const CHARACTER_IMAGE_PROCESSOR = preload("res://scripts/character_image_processor.gd")
const CHARACTER_PROCEDURAL_ANIMATOR = preload("res://scripts/character_procedural_animator.gd")
const CHARACTER_SPATIAL_RIG_BUILDER = preload("res://scripts/character_spatial_rig_builder.gd")
const CHARACTER_SPATIAL_ANIMATOR = preload("res://scripts/character_spatial_animator.gd")
const IK_DRAG_OVERLAY = preload("res://scripts/ik_drag_overlay.gd")
const ANIMATION_TIMELINE = preload("res://scripts/animation_timeline.gd")
const VIDEO_TIMELINE = preload("res://scripts/video_timeline.gd")
const CHARACTER_PACKAGE_IO = preload("res://scripts/character_package_io.gd")
const PROJECT_DOCUMENT_IO = preload("res://scripts/project_document_io.gd")
const SCENE_COMPOSITION_MODEL = preload("res://scripts/scene_composition_model.gd")
const SCENE_CANVAS = preload("res://scripts/scene_canvas.gd")
const SCENE_ASSET_BUTTON = preload("res://scripts/scene_asset_button.gd")
const RESOURCE_LIBRARY = preload("res://scripts/resource_library.gd")
const ANIMATION_RETARGETER = preload("res://scripts/animation_retargeter.gd")
const ENVIRONMENT_DIRECTOR = preload("res://scripts/environment_director.gd")
const DIALOGUE_STUDIO = preload("res://scripts/dialogue_studio.gd")
const PROJECT_BUNDLE_IO = preload("res://scripts/project_bundle_io.gd")
const PERFORMANCE_AUDITOR = preload("res://scripts/performance_auditor.gd")
const DEFAULT_PROJECT := {"name":"Mi primera animación","width":1920,"height":1080,"fps":60,"orientation":"Horizontal","visual_mode":"2D","background_mode":"Vacío"}

var project_data: Dictionary = DEFAULT_PROJECT.duplicate(true)
var blueprint_builder
var rig_builder
var spatial_builder
var runtime_spatial_rig: Node3D
var runtime_spatial_animator
var runtime_imported_3d_animation_player: AnimationPlayer
var imported_3d_model_path := ""
var spatial_subviewport: SubViewport
var spatial_container: SubViewportContainer
var rig_2d_container: SubViewportContainer
var image_processor
var procedural_animator
var imported_source_path := ""
var image_dialog: FileDialog
var model_3d_dialog: FileDialog
var model_3d_export_dialog: FileDialog
var imported_preview: TextureRect
var image_result_output: RichTextLabel
var build_segmented_button: Button
var animation_controls: GridContainer
var pose_controls: GridContainer
var animation_speed_slider: HSlider
var motion_intensity_slider: HSlider
var custom_pose_name_input: LineEdit
var joint_picker: OptionButton
var joint_axis_picker: OptionButton
var ik_chain_picker: OptionButton
var ik_target_x: SpinBox
var ik_target_y: SpinBox
var ik_target_z: SpinBox
var joint_angle_slider: HSlider
var joint_angle_spin: SpinBox
var joint_undo_stack: Array[Dictionary] = []
var joint_redo_stack: Array[Dictionary] = []
var joint_editor_syncing := false
var timeline_model
var package_io
var project_io
var project_bundle_io
var performance_auditor
var project_bundle_export_dialog: FileDialog
var project_bundle_import_dialog: FileDialog
var project_save_dialog: FileDialog
var project_open_dialog: FileDialog
var current_project_path := ""
var scene_list: ItemList
var scene_name_input: LineEdit
var scene_duration_input: SpinBox
var scene_notes_input: TextEdit
var selected_scene_index := -1
var scene_model
var scene_canvas
var selected_instance_id := ""
var object_x: SpinBox
var object_y: SpinBox
var object_scale_x: SpinBox
var object_scale_y: SpinBox
var object_rotation: SpinBox
var object_depth: SpinBox
var object_visible: CheckBox
var transition_picker: OptionButton
var transition_duration: SpinBox
var layer_list: ItemList
var scene_canvas_guard := false
var resource_library
var resource_list: ItemList
var resource_category := "character"
var selected_resource_id := ""
var resource_file_dialog: FileDialog
var resource_search: LineEdit
var director_track_list: ItemList
var director_target_picker: OptionButton
var director_property_picker: OptionButton
var director_time_input: SpinBox
var director_value_input: SpinBox
var director_easing_picker: OptionButton
var director_playhead: HSlider
var director_selected_track := -1
var package_export_dialog: FileDialog
var package_import_dialog: FileDialog
var spritesheet_export_dialog: FileDialog
var timeline_clip_picker: OptionButton
var timeline_key_list: ItemList
var timeline_duration: SpinBox
var timeline_playhead: HSlider
var timeline_loop: CheckBox
var timeline_name_input: LineEdit
var timeline_time_input: SpinBox
var video_timeline_model
var video_track_list: ItemList
var video_clip_list: ItemList
var video_playhead: SpinBox
var video_clip_start: SpinBox
var video_clip_end: SpinBox
var video_media_dialog: FileDialog
var video_selected_track := -1
var video_selected_clip := -1
var texture_brightness: HSlider
var texture_contrast: HSlider
var texture_saturation: HSlider
var background_tolerance: HSlider
var imported_character_data: Dictionary = {}
var procedural_poses: Array = []
var runtime_rig: Node2D
var rig_subviewport: SubViewport
var ik_drag_overlay
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
var spatial_rig_archetype: OptionButton
var character_view: OptionButton
var character_preview
var character_output: RichTextLabel
var skeleton_output: RichTextLabel
var generated_character: Dictionary = {}
var environment_director
var dialogue_studio
var active_environment: Dictionary = {}
var active_script: Dictionary = {}
var dialogue_line_list: ItemList

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
		var sf: float = minf(size.x / 420.0, size.y / 560.0)
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
		var shoulder_y: float = top + 132.0 * sf
		var hip_y: float = top + 300.0 * sf
		var span: float = (25.0 if side else 42.0) * sf
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
	blueprint_builder = CHARACTER_BLUEPRINT_BUILDER.new()
	rig_builder = CHARACTER_RIG_BUILDER.new()
	spatial_builder = CHARACTER_SPATIAL_RIG_BUILDER.new()
	environment_director = ENVIRONMENT_DIRECTOR.new()
	dialogue_studio = DIALOGUE_STUDIO.new()
	image_processor = CHARACTER_IMAGE_PROCESSOR.new()
	procedural_animator = CHARACTER_PROCEDURAL_ANIMATOR.new()
	package_io = CHARACTER_PACKAGE_IO.new()
	resource_library = RESOURCE_LIBRARY.new()
	project_io = PROJECT_DOCUMENT_IO.new()
	project_bundle_io = PROJECT_BUNDLE_IO.new()
	performance_auditor = PERFORMANCE_AUDITOR.new()
	_build_shell()
	project_save_dialog = FileDialog.new()
	project_save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	project_save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	project_save_dialog.filters = PackedStringArray(["*.amsproj, *.json ; Proyecto Animation Studio"])
	project_save_dialog.current_file = "mi_proyecto.amsproj"
	project_save_dialog.file_selected.connect(_save_project_to_path)
	add_child(project_save_dialog)
	project_open_dialog = FileDialog.new()
	project_open_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	project_open_dialog.access = FileDialog.ACCESS_FILESYSTEM
	project_open_dialog.filters = PackedStringArray(["*.amsproj, *.json ; Proyecto Animation Studio"])
	project_open_dialog.file_selected.connect(_load_project_from_path)
	add_child(project_open_dialog)
	project_bundle_export_dialog = FileDialog.new()
	project_bundle_export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	project_bundle_export_dialog.access = FileDialog.ACCESS_FILESYSTEM
	project_bundle_export_dialog.filters = PackedStringArray(["*.asbundle ; Proyecto portable Animation Studio"])
	project_bundle_export_dialog.current_file = "proyecto_animation_studio.asbundle"
	project_bundle_export_dialog.file_selected.connect(_export_project_bundle)
	add_child(project_bundle_export_dialog)
	project_bundle_import_dialog = FileDialog.new()
	project_bundle_import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	project_bundle_import_dialog.access = FileDialog.ACCESS_FILESYSTEM
	project_bundle_import_dialog.filters = PackedStringArray(["*.asbundle ; Proyecto portable Animation Studio"])
	project_bundle_import_dialog.file_selected.connect(_import_project_bundle)
	add_child(project_bundle_import_dialog)
	image_dialog = FileDialog.new()
	image_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	image_dialog.access = FileDialog.ACCESS_FILESYSTEM
	image_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Imágenes de personaje"])
	image_dialog.file_selected.connect(_on_character_image_selected)
	add_child(image_dialog)
	model_3d_dialog = FileDialog.new()
	model_3d_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	model_3d_dialog.access = FileDialog.ACCESS_FILESYSTEM
	model_3d_dialog.filters = PackedStringArray(["*.glb, *.gltf ; Modelos 3D glTF/GLB"])
	model_3d_dialog.file_selected.connect(_on_3d_model_selected)
	add_child(model_3d_dialog)
	model_3d_export_dialog = FileDialog.new()
	model_3d_export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	model_3d_export_dialog.access = FileDialog.ACCESS_FILESYSTEM
	model_3d_export_dialog.filters = PackedStringArray(["*.glb ; Modelo 3D glTF binario"])
	model_3d_export_dialog.current_file = "personaje_animation_studio.glb"
	model_3d_export_dialog.file_selected.connect(_export_3d_model_to_path)
	add_child(model_3d_export_dialog)
	package_export_dialog = FileDialog.new()
	package_export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	package_export_dialog.access = FileDialog.ACCESS_FILESYSTEM
	package_export_dialog.filters = PackedStringArray(["*.json ; Paquete de personaje JSON"])
	package_export_dialog.current_file = "personaje_animation_studio.json"
	package_export_dialog.file_selected.connect(_export_character_package_to_path)
	add_child(package_export_dialog)
	package_import_dialog = FileDialog.new()
	package_import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	package_import_dialog.access = FileDialog.ACCESS_FILESYSTEM
	package_import_dialog.filters = PackedStringArray(["*.json ; Paquete de personaje JSON"])
	package_import_dialog.file_selected.connect(_import_character_package_from_path)
	add_child(package_import_dialog)
	spritesheet_export_dialog = FileDialog.new()
	spritesheet_export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	spritesheet_export_dialog.access = FileDialog.ACCESS_FILESYSTEM
	spritesheet_export_dialog.filters = PackedStringArray(["*.png ; Hoja de sprites PNG"])
	spritesheet_export_dialog.current_file = "animacion_spritesheet.png"
	spritesheet_export_dialog.file_selected.connect(_export_timeline_spritesheet)
	add_child(spritesheet_export_dialog)
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
	_add_button(header, "Abrir proyecto", _open_project_dialog)
	_add_button(header, "Guardar proyecto", _save_project)
	_add_button(header, "Guardar como", _open_save_project_dialog)
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
	current_project_path = ""
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
	for section in ["Escenas","Personajes","Fondos","Elementos","Decoraciones","Tiempo y clima","Animación","Edición de vídeo","Audio y doblaje","Exportar"]:
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
	if section == "Escenas":
		_show_scene_manager()
		return
	if section == "Personajes":
		_show_resource_library("character")
		return
	if section == "Fondos":
		_show_resource_library("background")
		return
	if section == "Elementos":
		_show_resource_library("element")
		return
	if section == "Decoraciones":
		_show_resource_library("decoration")
		return
	if section == "Animación":
		_show_director_timeline()
		return
	if section == "Edición de vídeo":
		_show_video_editor()
		return
	if section == "Tiempo y clima":
		_show_environment_studio()
		return
	if section == "Audio y doblaje":
		_show_dialogue_studio()
		return
	if section == "Exportar":
		_show_export_workspace()
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
		"Exportar": info.text = "Paquete portable del proyecto, informe de rendimiento y exportación de recursos."
		_: info.text = "Organiza escenas, capítulos, duración y transiciones."
	page.add_child(info)
	_add_button(page, "Volver al escenario", _show_workspace)
	_set_status(section + " · interfaz inicial; funciones avanzadas pendientes.")


func _resource_category_label(category: String) -> String:
	return {"character":"Personajes","background":"Fondos","element":"Elementos","decoration":"Decoraciones"}.get(category, category)

func _show_resource_library(category: String) -> void:
	resource_category = category
	_clear_content()
	var page := VBoxContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("separation", 8)
	content.add_child(page)
	_add_heading(page, "Biblioteca · " + _resource_category_label(category), "Importa archivos al almacenamiento local del proyecto. Las rutas y metadatos se guardan en el documento.")
	var toolbar := HBoxContainer.new()
	page.add_child(toolbar)
	resource_search = LineEdit.new()
	resource_search.placeholder_text = "Buscar por nombre o etiqueta…"
	resource_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_search.text_changed.connect(_refresh_resource_list)
	toolbar.add_child(resource_search)
	_add_button(toolbar, "Importar archivos", _open_resource_import_dialog)
	_add_button(toolbar, "Volver", _show_workspace)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(body)
	resource_list = ItemList.new()
	resource_list.custom_minimum_size.x = 280
	resource_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	resource_list.item_selected.connect(_on_resource_selected)
	body.add_child(resource_list)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(details)
	_add_heading(details, "Detalles del recurso", "Selecciona un elemento para revisar sus metadatos.")
	_add_button(details, "Añadir recurso seleccionado a escena", _add_selected_resource_to_scene)
	_add_button(details, "Eliminar recurso seleccionado", _delete_selected_resource)
	_add_button(details, "Abrir estudio de personajes", _show_character_lab)
	_refresh_resource_list()

func _open_resource_import_dialog() -> void:
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	var filters := PackedStringArray()
	if resource_category == "background":
		filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Imágenes de fondo"])
	elif resource_category == "character":
		filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Imágenes de personaje", "*.glb, *.gltf ; Modelos 3D"])
	else:
		filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Imágenes", "*.glb, *.gltf ; Modelos 3D"])
	dialog.filters = filters
	dialog.files_selected.connect(_on_resource_files_selected)
	add_child(dialog)
	dialog.popup_centered_ratio(0.82)

func _on_resource_files_selected(paths: PackedStringArray) -> void:
	if not project_data.has("resources"):
		project_data["resources"] = []
	var imported := 0
	var failures: Array[String] = []
	for path in paths:
		var result: Dictionary = resource_library.import_file(path, resource_category, path.get_file().get_basename(), [], str(project_data.get("visual_mode","2D")))
		if bool(result.get("ok", false)):
			project_data["resources"].append(result.resource)
			imported += 1
		else:
			failures.append(path.get_file() + ": " + str(result.get("error","Error")))
	_save_project()
	_refresh_resource_list()
	var message := "%d recurso(s) importado(s)." % imported
	if not failures.is_empty():
		message += " Errores: " + " | ".join(failures)
	_set_status(message)

func _refresh_resource_list(_query := "") -> void:
	if not is_instance_valid(resource_list):
		return
	resource_list.clear()
	var query := resource_search.text if is_instance_valid(resource_search) else ""
	var items: Array = resource_library.search(project_data.get("resources", []), query, resource_category)
	for item in items:
		var icon := "🖼" if str(item.get("mime_group","")) == "image" else "🧊"
		resource_list.add_item("%s  %s  ·  %s" % [icon, str(item.get("name","Recurso")), str(item.get("extension","")).to_upper()])
		resource_list.set_item_metadata(resource_list.item_count-1, str(item.get("id","")))
	if items.is_empty():
		_set_status("No hay recursos en esta categoría. Importa PNG, JPG, WebP o GLB/glTF según corresponda.")

func _on_resource_selected(index: int) -> void:
	if not is_instance_valid(resource_list) or index < 0:
		return
	selected_resource_id = str(resource_list.get_item_metadata(index))
	for item in project_data.get("resources", []):
		if str(item.get("id","")) == selected_resource_id:
			_set_status("%s · %s · %s · %d bytes · modos: %s" % [item.get("name",""), item.get("source_name",""), item.get("path",""), int(item.get("bytes",0)), ", ".join(PackedStringArray(item.get("compatible_modes",[])))])
			return

func _add_selected_resource_to_scene() -> void:
	if scene_model == null:
		scene_model = SCENE_COMPOSITION_MODEL.new()
	var resource: Dictionary = _find_project_resource(selected_resource_id)
	if resource.is_empty():
		_set_status("Selecciona primero un recurso de la biblioteca.")
		return
	if not resource_library.is_compatible(resource, str(project_data.get("visual_mode","2D"))):
		_set_status("Este recurso no es compatible con el modo visual del proyecto.")
		return
	if _active_scene().is_empty():
		_create_scene()
	var position := Vector2(float(project_data.get("width",1920))*0.5,float(project_data.get("height",1080))*0.5)
	var instance: Dictionary = scene_model.create_instance(str(resource.id), str(resource.category), str(resource.name), position)
	var added: Dictionary = scene_model.add_instance(_active_scene(), instance)
	if not bool(added.get("ok",false)):
		_set_status(str(added.get("error","No se pudo añadir el recurso.")))
		return
	project_data["scenes"][selected_scene_index] = _active_scene()
	_save_project()
	_show_scene_manager()
	_set_status("Recurso «%s» añadido a la escena." % resource.name)

func _find_project_resource(resource_id: String) -> Dictionary:
	for item in project_data.get("resources", []):
		if str(item.get("id","")) == resource_id:
			return item.duplicate(true)
	return {}

func _delete_selected_resource() -> void:
	var resource := _find_project_resource(selected_resource_id)
	if resource.is_empty():
		return
	var result: Dictionary = resource_library.remove_resource(resource)
	if not bool(result.get("ok",false)):
		_set_status(str(result.get("error","No se pudo eliminar el recurso.")))
		return
	var resources: Array = project_data.get("resources", [])
	for index in range(resources.size()-1,-1,-1):
		if str(resources[index].get("id","")) == selected_resource_id:
			resources.remove_at(index)
	selected_resource_id = ""
	_save_project()
	_refresh_resource_list()
	_set_status("Recurso eliminado de la biblioteca.")

func _show_director_timeline() -> void:
	_clear_content()
	if timeline_model == null:
		timeline_model = ANIMATION_TIMELINE.new()
	var page := VBoxContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("separation", 8)
	content.add_child(page)
	_add_heading(page, "Timeline · Dirección de escena", "Anima transformaciones de objetos de la escena mediante pistas y curvas; no requiere un rig de personaje.")
	var controls := HBoxContainer.new()
	page.add_child(controls)
	director_target_picker = OptionButton.new()
	director_target_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for object in _active_scene().get("objects", []):
		director_target_picker.add_item(str(object.get("name","Objeto")))
		director_target_picker.set_item_metadata(director_target_picker.item_count-1, str(object.get("id","")))
	controls.add_child(director_target_picker)
	director_property_picker = OptionButton.new()
	for property in ["x","y","scale_x","scale_y","rotation","depth"]:
		director_property_picker.add_item(property)
	controls.add_child(director_property_picker)
	_add_button(controls, "Crear pista", _director_create_track)
	var edit := HBoxContainer.new()
	page.add_child(edit)
	director_time_input = SpinBox.new()
	director_time_input.min_value = 0.0
	director_time_input.max_value = 600.0
	director_time_input.step = 0.01
	director_time_input.prefix = "Tiempo "
	edit.add_child(director_time_input)
	director_value_input = SpinBox.new()
	director_value_input.min_value = -100000.0
	director_value_input.max_value = 100000.0
	director_value_input.step = 0.1
	director_value_input.prefix = "Valor "
	edit.add_child(director_value_input)
	director_easing_picker = OptionButton.new()
	for easing in ["linear","ease_in","ease_out","ease_in_out","step"]:
		director_easing_picker.add_item(easing)
	edit.add_child(director_easing_picker)
	_add_button(edit, "Añadir keyframe", _director_add_keyframe)
	_add_button(edit, "Eliminar pista", _director_delete_track)
	director_track_list = ItemList.new()
	director_track_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	director_track_list.item_selected.connect(_on_director_track_selected)
	page.add_child(director_track_list)
	director_playhead = HSlider.new()
	director_playhead.min_value = 0.0
	director_playhead.max_value = 10.0
	director_playhead.step = 0.01
	director_playhead.value_changed.connect(_on_director_playhead_changed)
	page.add_child(director_playhead)
	var footer := HBoxContainer.new()
	page.add_child(footer)
	_add_button(footer, "Abrir editor de escenas", _show_scene_manager)
	_add_button(footer, "Guardar timeline", _save_project)
	_add_button(footer, "Volver", _show_workspace)
	_refresh_director_tracks()

func _director_tracks() -> Array:
	if not project_data.has("scene_animation_tracks"):
		project_data["scene_animation_tracks"] = {}
	var scene_id := str(_active_scene().get("id","default"))
	if not project_data["scene_animation_tracks"].has(scene_id):
		project_data["scene_animation_tracks"][scene_id] = []
	return project_data["scene_animation_tracks"][scene_id]

func _director_create_track() -> void:
	if not is_instance_valid(director_target_picker) or director_target_picker.selected < 0:
		_set_status("Crea o selecciona un objeto en la escena antes de crear una pista.")
		return
	var target_id := str(director_target_picker.get_item_metadata(director_target_picker.selected))
	var property := director_property_picker.get_item_text(director_property_picker.selected)
	var track: Dictionary = timeline_model.create_track("track_%d_%d" % [Time.get_ticks_msec(),_director_tracks().size()], property + " · " + director_target_picker.get_item_text(director_target_picker.selected), target_id, property)
	if track.is_empty():
		return
	_director_tracks().append(track)
	_refresh_director_tracks()
	_save_project()
	_set_status("Pista de %s creada." % property)

func _refresh_director_tracks() -> void:
	if not is_instance_valid(director_track_list):
		return
	director_track_list.clear()
	for track in _director_tracks():
		director_track_list.add_item("%s · %d claves" % [str(track.get("name","Pista")), track.get("keyframes",[]).size()])

func _on_director_track_selected(index: int) -> void:
	director_selected_track = index
	var tracks := _director_tracks()
	if index >= 0 and index < tracks.size():
		var frames: Array = tracks[index].get("keyframes",[])
		if not frames.is_empty():
			director_time_input.value = float(frames[-1].get("time",0.0))
			director_value_input.value = float(frames[-1].get("value",0.0))
		_refresh_director_tracks()

func _director_add_keyframe() -> void:
	var tracks := _director_tracks()
	if director_selected_track < 0 or director_selected_track >= tracks.size():
		_set_status("Selecciona una pista antes de añadir keyframes.")
		return
	var track: Dictionary = tracks[director_selected_track]
	var easing := director_easing_picker.get_item_text(director_easing_picker.selected)
	var result: Dictionary = timeline_model.insert_property_keyframe(track, director_time_input.value, director_value_input.value, easing)
	if not bool(result.get("ok",false)):
		_set_status(str(result.get("error","No se pudo añadir el keyframe.")))
		return
	tracks[director_selected_track] = track
	_refresh_director_tracks()
	_save_project()
	_set_status("Keyframe guardado en %.2f s." % director_time_input.value)

func _director_delete_track() -> void:
	var tracks := _director_tracks()
	if director_selected_track < 0 or director_selected_track >= tracks.size():
		return
	tracks.remove_at(director_selected_track)
	director_selected_track = -1
	_refresh_director_tracks()
	_save_project()

func _on_director_playhead_changed(value: float) -> void:
	var scene := _active_scene()
	var tracks := _director_tracks()
	for track in tracks:
		var sampled: Variant = timeline_model.sample_track(track, value)
		if sampled == null:
			continue
		for object_index in range(scene.get("objects",[]).size()):
			var object: Dictionary = scene["objects"][object_index]
			if str(object.get("id","")) != str(track.get("target_id","")):
				continue
			var transform: Dictionary = object.get("transform",{}).duplicate(true)
			transform[str(track.get("property","x"))] = sampled
			object["transform"] = transform
			scene["objects"][object_index] = object
		project_data["scenes"][selected_scene_index] = scene
	if is_instance_valid(scene_canvas):
		_refresh_scene_canvas()

func _show_scene_manager() -> void:
	_clear_content()
	if scene_model == null:
		scene_model = SCENE_COMPOSITION_MODEL.new()
	var layout := HBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 10)
	content.add_child(layout)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 190
	layout.add_child(left)
	_add_heading(left, "Escenas", "Orden y duración.")
	scene_list = ItemList.new()
	scene_list.custom_minimum_size.y = 180
	scene_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene_list.item_selected.connect(_on_scene_selected)
	left.add_child(scene_list)
	var actions := GridContainer.new()
	actions.columns = 2
	left.add_child(actions)
	_add_button(actions, "Nueva", _create_scene)
	_add_button(actions, "Duplicar", _duplicate_scene)
	_add_button(actions, "Eliminar", _delete_scene)
	_add_button(actions, "Subir escena", _move_scene_up)
	_add_button(actions, "Bajar escena", _move_scene_down)
	_add_button(left, "Volver", _show_workspace)
	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(center)
	_add_heading(center, "Lienzo de composición", "Selecciona y arrastra objetos. Rueda: zoom; botón derecho o central: desplazar.")
	var add_row := HBoxContainer.new()
	center.add_child(add_row)
	_add_scene_asset_button(add_row, "+ Personaje", "character")
	_add_scene_asset_button(add_row, "+ Fondo", "background")
	_add_scene_asset_button(add_row, "+ Elemento", "element")
	_add_scene_asset_button(add_row, "+ Decoración", "decoration")
	_add_button(add_row, "Ajustar vista", _reset_scene_canvas)
	var frame := PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(frame)
	scene_canvas = SCENE_CANVAS.new()
	scene_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene_canvas.custom_minimum_size = Vector2(420, 300)
	scene_canvas.selection_changed.connect(_on_canvas_selection_changed)
	scene_canvas.composition_changed.connect(_on_canvas_composition_changed)
	scene_canvas.asset_dropped.connect(_on_canvas_asset_dropped)
	frame.add_child(scene_canvas)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 245
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 225
	right.add_theme_constant_override("separation", 6)
	scroll.add_child(right)
	_add_heading(right, "Inspector", "Propiedades del objeto seleccionado.")
	layer_list = ItemList.new()
	layer_list.custom_minimum_size.y = 110
	layer_list.item_selected.connect(_on_layer_selected)
	right.add_child(layer_list)
	_add_button(right, "Subir capa", _raise_selected_layer)
	_add_button(right, "Bajar capa", _lower_selected_layer)
	_add_button(right, "Eliminar objeto", _delete_selected_object)
	_add_scene_numeric_field(right, "Posición X", "x")
	_add_scene_numeric_field(right, "Posición Y", "y")
	_add_scene_numeric_field(right, "Escala X", "sx")
	_add_scene_numeric_field(right, "Escala Y", "sy")
	_add_scene_numeric_field(right, "Rotación °", "rotation")
	_add_scene_numeric_field(right, "Profundidad", "depth")
	object_visible = CheckBox.new()
	object_visible.text = "Visible"
	object_visible.toggled.connect(_on_scene_visibility_changed)
	right.add_child(object_visible)
	_add_heading(right, "Transición", "Salida a la siguiente escena.")
	transition_picker = OptionButton.new()
	for option in ["cut", "fade", "dissolve", "wipe"]:
		transition_picker.add_item(option)
	right.add_child(transition_picker)
	transition_duration = SpinBox.new()
	transition_duration.min_value = 0.0
	transition_duration.max_value = 30.0
	transition_duration.step = 0.1
	transition_duration.value = 1.0
	right.add_child(transition_duration)
	_add_button(right, "Aplicar transición", _apply_scene_transition)
	_add_heading(right, "Escena activa", "Datos generales.")
	scene_name_input = LineEdit.new()
	scene_name_input.placeholder_text = "Nombre de escena"
	right.add_child(scene_name_input)
	scene_duration_input = SpinBox.new()
	scene_duration_input.min_value = 0.1
	scene_duration_input.max_value = 86400.0
	scene_duration_input.step = 0.5
	scene_duration_input.value = 10.0
	right.add_child(scene_duration_input)
	scene_notes_input = TextEdit.new()
	scene_notes_input.custom_minimum_size.y = 65
	scene_notes_input.placeholder_text = "Notas de producción"
	right.add_child(scene_notes_input)
	_add_button(right, "Guardar escena", _save_scene_properties)
	_refresh_scene_list()
	_refresh_scene_canvas()
	_set_status("Editor de escenas: lienzo, selección, transformaciones, capas y transiciones.")

func _add_scene_numeric_field(parent: Node, label_text: String, key: String) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 92
	row.add_child(label)
	var field := SpinBox.new()
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.step = 1.0 if key in ["x", "y", "depth"] else 0.1
	field.min_value = 0.01 if key in ["sx", "sy"] else -100000.0
	field.max_value = 100000.0
	field.value = 1.0 if key in ["sx", "sy"] else 0.0
	field.value_changed.connect(_on_scene_transform_changed.bind(key))
	row.add_child(field)
	match key:
		"x": object_x = field
		"y": object_y = field
		"sx": object_scale_x = field
		"sy": object_scale_y = field
		"rotation": object_rotation = field
		"depth": object_depth = field

func _active_scene() -> Dictionary:
	var scenes: Array = project_data.get("scenes", [])
	if selected_scene_index < 0 or selected_scene_index >= scenes.size():
		return {}
	return scenes[selected_scene_index]

func _refresh_scene_canvas() -> void:
	if not is_instance_valid(scene_canvas): return
	var scene := _active_scene()
	scene_canvas.set_resource_catalog(project_data.get("resources", []))
	scene_canvas.set_scene_data(scene, float(project_data.get("width", 1920)), float(project_data.get("height", 1080)))
	_refresh_layer_list()
	_update_scene_inspector()
	var transition: Dictionary = scene.get("transitions", {})
	var transition_type := str(transition.get("type", "cut"))
	for i in range(transition_picker.item_count):
		if transition_picker.get_item_text(i) == transition_type:
			transition_picker.select(i)
			break
	transition_duration.value = float(transition.get("duration_seconds", 1.0))

func _refresh_layer_list() -> void:
	if not is_instance_valid(layer_list): return
	layer_list.clear()
	var objects: Array = _active_scene().get("objects", [])
	for i in range(objects.size()):
		var item: Dictionary = objects[i]
		layer_list.add_item("%02d · %s [%s]" % [i + 1, str(item.get("name", "Objeto")), str(item.get("type", ""))])
		if str(item.get("id", "")) == selected_instance_id: layer_list.select(i)

func _find_selected_instance() -> Dictionary:
	for item in _active_scene().get("objects", []):
		if str(item.get("id", "")) == selected_instance_id: return item
	return {}

func _update_scene_inspector() -> void:
	if not is_instance_valid(object_x): return
	var item := _find_selected_instance()
	var enabled := not item.is_empty()
	for field in [object_x, object_y, object_scale_x, object_scale_y, object_rotation, object_depth]: field.editable = enabled
	object_visible.disabled = not enabled
	if not enabled:
		selected_instance_id = ""
		return
	var t: Dictionary = item.get("transform", {})
	scene_canvas_guard = true
	object_x.value = float(t.get("x", 0.0))
	object_y.value = float(t.get("y", 0.0))
	object_scale_x.value = float(t.get("scale_x", 1.0))
	object_scale_y.value = float(t.get("scale_y", 1.0))
	object_rotation.value = float(t.get("rotation", 0.0))
	object_depth.value = float(t.get("depth", 0.0))
	object_visible.button_pressed = bool(t.get("visible", true))
	scene_canvas_guard = false

func _add_scene_asset_button(parent: Node, label_text: String, kind: String) -> void:
	var button = SCENE_ASSET_BUTTON.new()
	button.text = label_text
	button.resource_kind = kind
	button.custom_minimum_size.y = 36
	button.pressed.connect(_add_scene_object.bind(kind))
	parent.add_child(button)

func _on_canvas_asset_dropped(kind: String, position: Vector2) -> void:
	_add_scene_object(kind, position)

func _add_scene_object(kind: String, drop_position := Vector2(-1.0, -1.0)) -> void:
	if _active_scene().is_empty(): _create_scene()
	var scene := _active_scene()
	var labels := {"character": "Personaje nuevo", "background": "Fondo de escena", "element": "Elemento nuevo", "decoration": "Decoración nueva"}
	var rid := "builtin:" + kind + ":" + str(Time.get_ticks_msec())
	var position := drop_position if drop_position.x >= 0.0 and drop_position.y >= 0.0 else Vector2(float(project_data.get("width", 1920)) * 0.5, float(project_data.get("height", 1080)) * 0.5)
	var instance: Dictionary = scene_model.create_instance(rid, kind, labels[kind], position)
	var result: Dictionary = scene_model.add_instance(scene, instance)
	if not result.ok:
		_set_status(str(result.get("error", "No se pudo añadir el objeto.")))
		return
	project_data["scenes"][selected_scene_index] = scene
	selected_instance_id = str(instance.get("id", ""))
	_refresh_scene_canvas()
	scene_canvas.set_selected(selected_instance_id)
	_save_project()
	_set_status("Marcador añadido. En la etapa de bibliotecas se conectarán los recursos importados.")

func _add_scene_character() -> void: _add_scene_object("character")
func _add_scene_background() -> void: _add_scene_object("background")
func _add_scene_element() -> void: _add_scene_object("element")
func _add_scene_decoration() -> void: _add_scene_object("decoration")

func _on_canvas_selection_changed(instance_id: String) -> void:
	selected_instance_id = instance_id
	_update_scene_inspector()
	_refresh_layer_list()

func _on_canvas_composition_changed() -> void:
	if selected_scene_index < 0: return
	project_data["scenes"][selected_scene_index] = _active_scene()
	_update_scene_inspector()
	_save_project()

func _on_scene_transform_changed(value: float, key: String) -> void:
	if scene_canvas_guard or selected_instance_id == "": return
	var changes := {}
	match key:
		"x": changes["x"] = value
		"y": changes["y"] = value
		"sx": changes["scale_x"] = value
		"sy": changes["scale_y"] = value
		"rotation": changes["rotation"] = value
		"depth": changes["depth"] = value
	var scene := _active_scene()
	var result: Dictionary = scene_model.update_transform(scene, selected_instance_id, changes)
	if result.ok:
		project_data["scenes"][selected_scene_index] = scene
		scene_canvas.queue_redraw()
		_save_project()

func _on_scene_visibility_changed(value: bool) -> void:
	if scene_canvas_guard or selected_instance_id == "": return
	var scene := _active_scene()
	var result: Dictionary = scene_model.update_transform(scene, selected_instance_id, {"visible": value})
	if result.ok:
		project_data["scenes"][selected_scene_index] = scene
		scene_canvas.queue_redraw()
		_save_project()

func _on_layer_selected(index: int) -> void:
	var objects: Array = _active_scene().get("objects", [])
	if index < 0 or index >= objects.size(): return
	selected_instance_id = str(objects[index].get("id", ""))
	scene_canvas.set_selected(selected_instance_id)
	_update_scene_inspector()

func _move_selected_layer(offset: int) -> void:
	if selected_instance_id == "": return
	var scene := _active_scene()
	var objects: Array = scene.get("objects", [])
	var current := -1
	for i in range(objects.size()):
		if str(objects[i].get("id", "")) == selected_instance_id: current = i
	if current < 0: return
	var result: Dictionary = scene_model.reorder_instance(scene, selected_instance_id, current + offset)
	if result.ok:
		project_data["scenes"][selected_scene_index] = scene
		_refresh_scene_canvas()
		_save_project()
func _raise_selected_layer() -> void: _move_selected_layer(1)
func _lower_selected_layer() -> void: _move_selected_layer(-1)

func _delete_selected_object() -> void:
	if selected_instance_id == "": return
	var scene := _active_scene()
	var result: Dictionary = scene_model.remove_instance(scene, selected_instance_id)
	if result.ok:
		project_data["scenes"][selected_scene_index] = scene
		selected_instance_id = ""
		scene_canvas.set_selected("")
		_refresh_scene_canvas()
		_save_project()

func _apply_scene_transition() -> void:
	var scene := _active_scene()
	if scene.is_empty(): return
	var result: Dictionary = scene_model.set_transition(scene, transition_picker.get_item_text(transition_picker.selected), transition_duration.value)
	if result.ok:
		project_data["scenes"][selected_scene_index] = scene
		_save_project()
		_set_status("Transición guardada: " + str(scene.get("transitions", {}).get("type", "")))

func _reset_scene_canvas() -> void:
	if is_instance_valid(scene_canvas): scene_canvas.reset_view()
func _refresh_scene_list() -> void:
	if not is_instance_valid(scene_list):
		return
	scene_list.clear()
	var scenes: Array = project_data.get("scenes", [])
	for index in range(scenes.size()):
		var scene: Dictionary = scenes[index]
		scene_list.add_item("%02d · %s  (%.1f s)" % [index + 1, str(scene.get("name", "Escena")), float(scene.get("duration_seconds", 10.0))])
	if not scenes.is_empty():
		selected_scene_index = clampi(selected_scene_index, 0, scenes.size() - 1)
		scene_list.select(selected_scene_index)
		_on_scene_selected(selected_scene_index)
	else:
		selected_scene_index = -1
		scene_name_input.text = ""
		scene_duration_input.value = 10.0
		scene_notes_input.text = ""

func _create_scene() -> void:
	if not project_data.get("scenes", []) is Array:
		project_data["scenes"] = []
	var index: int = project_data["scenes"].size() + 1
	var scene_id := "scene_%d_%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_msec() % 100000]
	project_data["scenes"].append({"id": scene_id, "name": "Escena %d" % index, "duration_seconds": 10.0, "notes": "", "objects": [], "transitions": {}})
	selected_scene_index = project_data["scenes"].size() - 1
	_refresh_scene_list()
	_save_project()
	_set_status("Escena creada.")

func _duplicate_scene() -> void:
	var scenes: Array = project_data.get("scenes", [])
	if selected_scene_index < 0 or selected_scene_index >= scenes.size():
		_set_status("Selecciona una escena para duplicar.")
		return
	var copy: Dictionary = scenes[selected_scene_index].duplicate(true)
	copy["id"] = "scene_%d_%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_msec() % 100000]
	copy["name"] = str(copy.get("name", "Escena")) + " (copia)"
	scenes.insert(selected_scene_index + 1, copy)
	project_data["scenes"] = scenes
	selected_scene_index += 1
	_refresh_scene_list()
	_save_project()
	_set_status("Escena duplicada.")

func _delete_scene() -> void:
	var scenes: Array = project_data.get("scenes", [])
	if selected_scene_index < 0 or selected_scene_index >= scenes.size():
		_set_status("Selecciona una escena para eliminar.")
		return
	scenes.remove_at(selected_scene_index)
	project_data["scenes"] = scenes
	selected_scene_index = mini(selected_scene_index, scenes.size() - 1)
	_refresh_scene_list()
	_save_project()
	_set_status("Escena eliminada.")

func _move_scene(offset: int) -> void:
	var scenes: Array = project_data.get("scenes", [])
	var target := selected_scene_index + offset
	if selected_scene_index < 0 or target < 0 or target >= scenes.size(): return
	var item = scenes.pop_at(selected_scene_index)
	scenes.insert(target, item)
	project_data["scenes"] = scenes
	selected_scene_index = target
	_refresh_scene_list()
	_refresh_scene_canvas()
	_save_project()
func _move_scene_up() -> void: _move_scene(-1)
func _move_scene_down() -> void: _move_scene(1)

func _on_scene_selected(index: int) -> void:
	var scenes: Array = project_data.get("scenes", [])
	if index < 0 or index >= scenes.size():
		return
	selected_scene_index = index
	var scene: Dictionary = scenes[index]
	scene_name_input.text = str(scene.get("name", ""))
	scene_duration_input.value = float(scene.get("duration_seconds", 10.0))
	scene_notes_input.text = str(scene.get("notes", ""))
	if is_instance_valid(scene_canvas):
		selected_instance_id = ""
		_refresh_scene_canvas()

func _save_scene_properties() -> void:
	var scenes: Array = project_data.get("scenes", [])
	if selected_scene_index < 0 or selected_scene_index >= scenes.size():
		_set_status("Crea o selecciona una escena antes de guardar sus propiedades.")
		return
	var scene: Dictionary = scenes[selected_scene_index]
	var cleaned_name := scene_name_input.text.strip_edges()
	scene["name"] = cleaned_name if not cleaned_name.is_empty() else "Escena %d" % (selected_scene_index + 1)
	scene["duration_seconds"] = scene_duration_input.value
	scene["notes"] = scene_notes_input.text
	scenes[selected_scene_index] = scene
	project_data["scenes"] = scenes
	_refresh_scene_list()
	_save_project()
	_set_status("Propiedades de escena guardadas.")

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
	spatial_rig_archetype = _add_option(form, "Arquetipo de esqueleto 3D", ["Humanoide","Dinosaurio / cuadrúpedo"], 0)
	character_view = _add_option(form, "Vista previa", ["Frente","Perfil","Espalda","Tres cuartos"], 0)
	character_view.item_selected.connect(_on_character_view_changed)
	_add_button(form, "Importar imagen y preparar piezas", _open_character_image_dialog)
	_add_button(form, "Importar modelo 3D (GLB / glTF)", _open_3d_model_dialog)
	_add_button(form, "Exportar modelo 3D (GLB)", _open_3d_model_export_dialog)
	_add_button(form, "Auditar esqueleto 3D actual", _audit_current_spatial_rig)
	_add_button(form, "Crear perfil de retargeting", _create_retarget_profile)
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
	var ik_help := Label.new()
	ik_help.text = "IK: arrastra los círculos de manos y pies para posar el personaje."
	ik_help.add_theme_color_override("font_color", Color("#536779"))
	right.add_child(ik_help)
	animation_controls = GridContainer.new()
	animation_controls.columns = 3
	right.add_child(animation_controls)
	for animation_name in ["idle","walk","run","jump","talk","wave"]:
		_add_button(animation_controls, animation_name.capitalize(), _play_rig_animation.bind(animation_name))
	var speed_row := HBoxContainer.new()
	right.add_child(speed_row)
	var speed_label := Label.new()
	speed_label.text = "Velocidad de animación"
	speed_label.custom_minimum_size.x = 150
	speed_row.add_child(speed_label)
	animation_speed_slider = HSlider.new()
	animation_speed_slider.min_value = 0.25
	animation_speed_slider.max_value = 2.5
	animation_speed_slider.step = 0.05
	animation_speed_slider.value = 1.0
	animation_speed_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speed_row.add_child(animation_speed_slider)
	var speed_value := Label.new()
	speed_value.text = "1.00×"
	speed_row.add_child(speed_value)
	animation_speed_slider.value_changed.connect(func(value: float) -> void:
		speed_value.text = "%.2f×" % value
	)
	var intensity_row := HBoxContainer.new()
	right.add_child(intensity_row)
	var intensity_label := Label.new()
	intensity_label.text = "Intensidad de movimiento"
	intensity_label.custom_minimum_size.x = 150
	intensity_row.add_child(intensity_label)
	motion_intensity_slider = HSlider.new()
	motion_intensity_slider.min_value = 0.5
	motion_intensity_slider.max_value = 1.75
	motion_intensity_slider.step = 0.05
	motion_intensity_slider.value = 1.0
	motion_intensity_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intensity_row.add_child(motion_intensity_slider)
	var intensity_value := Label.new()
	intensity_value.text = "1.00×"
	intensity_row.add_child(intensity_value)
	motion_intensity_slider.value_changed.connect(func(value: float) -> void:
		intensity_value.text = "%.2f×" % value
	)
	var pose_title := Label.new()
	pose_title.text = "BIBLIOTECA DE POSES PROCEDURALES"
	right.add_child(pose_title)
	pose_controls = GridContainer.new()
	pose_controls.columns = 3
	right.add_child(pose_controls)
	custom_pose_name_input = LineEdit.new()
	custom_pose_name_input.placeholder_text = "Nombre para guardar tu pose"
	right.add_child(custom_pose_name_input)
	_add_button(right, "Guardar pose manual actual", _save_current_procedural_pose)
	var joint_title := Label.new()
	joint_title.text = "AJUSTE MANUAL DE ARTICULACIONES"
	right.add_child(joint_title)
	var joint_picker_row := HBoxContainer.new()
	right.add_child(joint_picker_row)
	var joint_picker_label := Label.new()
	joint_picker_label.text = "Articulación"
	joint_picker_label.custom_minimum_size.x = 145
	joint_picker_row.add_child(joint_picker_label)
	joint_picker = OptionButton.new()
	joint_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var joint_options := [
		["Pelvis", "pelvis"], ["Torso", "torso"], ["Cuello", "neck"], ["Cabeza", "head"], ["Mandíbula", "jaw"],
		["Hombro izquierdo", "shoulder_left"], ["Codo izquierdo", "elbow_left"], ["Muñeca izquierda", "wrist_left"],
		["Hombro derecho", "shoulder_right"], ["Codo derecho", "elbow_right"], ["Muñeca derecha", "wrist_right"],
		["Cadera izquierda", "hip_left"], ["Rodilla izquierda", "knee_left"], ["Tobillo izquierdo", "ankle_left"],
		["Cadera derecha", "hip_right"], ["Rodilla derecha", "knee_right"], ["Tobillo derecho", "ankle_right"],
		["Pata delantera izq.", "front_hip_left"], ["Rodilla delantera izq.", "front_knee_left"], ["Tobillo delantero izq.", "front_ankle_left"],
		["Pata delantera der.", "front_hip_right"], ["Rodilla delantera der.", "front_knee_right"], ["Tobillo delantero der.", "front_ankle_right"],
		["Pata trasera izq.", "back_hip_left"], ["Rodilla trasera izq.", "back_knee_left"], ["Tobillo trasero izq.", "back_ankle_left"],
		["Pata trasera der.", "back_hip_right"], ["Rodilla trasera der.", "back_knee_right"], ["Tobillo trasero der.", "back_ankle_right"],
		["Cola base", "tail_01"], ["Cola segmento 2", "tail_02"], ["Cola segmento 3", "tail_03"], ["Cola punta", "tail_04"]
	]
	for option in joint_options:
		joint_picker.add_item(str(option[0]))
		joint_picker.set_item_metadata(joint_picker.item_count - 1, str(option[1]))
	joint_picker.item_selected.connect(_on_joint_editor_selection_changed)
	joint_picker_row.add_child(joint_picker)
	var joint_axis_row := HBoxContainer.new()
	right.add_child(joint_axis_row)
	var joint_axis_label := Label.new()
	joint_axis_label.text = "Eje 3D"
	joint_axis_label.custom_minimum_size.x = 145
	joint_axis_row.add_child(joint_axis_label)
	joint_axis_picker = OptionButton.new()
	joint_axis_picker.add_item("X")
	joint_axis_picker.add_item("Y")
	joint_axis_picker.add_item("Z")
	joint_axis_picker.select(2)
	joint_axis_picker.item_selected.connect(func(_axis: int) -> void:
		_on_joint_editor_selection_changed(joint_picker.selected if is_instance_valid(joint_picker) else 0)
	)
	joint_axis_row.add_child(joint_axis_picker)
	var ik_title := Label.new()
	ik_title.text = "IK 3D · POSICIÓN OBJETIVO EN COORDENADAS DEL ESQUELETO"
	right.add_child(ik_title)
	var ik_chain_row := HBoxContainer.new()
	right.add_child(ik_chain_row)
	ik_chain_picker = OptionButton.new()
	ik_chain_picker.add_item("Brazo izquierdo")
	ik_chain_picker.set_item_metadata(0, "arm_left")
	ik_chain_picker.add_item("Brazo derecho")
	ik_chain_picker.set_item_metadata(1, "arm_right")
	ik_chain_picker.add_item("Pierna izquierda")
	ik_chain_picker.set_item_metadata(2, "leg_left")
	ik_chain_picker.add_item("Pierna derecha")
	ik_chain_picker.set_item_metadata(3, "leg_right")
	ik_chain_picker.add_item("Pata delantera izquierda")
	ik_chain_picker.set_item_metadata(4, "front_leg_left")
	ik_chain_picker.add_item("Pata delantera derecha")
	ik_chain_picker.set_item_metadata(5, "front_leg_right")
	ik_chain_picker.add_item("Pata trasera izquierda")
	ik_chain_picker.set_item_metadata(6, "back_leg_left")
	ik_chain_picker.add_item("Pata trasera derecha")
	ik_chain_picker.set_item_metadata(7, "back_leg_right")
	ik_chain_picker.select(1)
	ik_chain_row.add_child(ik_chain_picker)
	ik_target_x = _add_ik_target_axis(ik_chain_row, "X", 0.65)
	ik_target_y = _add_ik_target_axis(ik_chain_row, "Y", 1.4)
	ik_target_z = _add_ik_target_axis(ik_chain_row, "Z", 0.0)
	_add_button(ik_chain_row, "Aplicar IK 3D", _apply_3d_ik_target)
	var joint_angle_row := HBoxContainer.new()
	right.add_child(joint_angle_row)
	joint_angle_slider = HSlider.new()
	joint_angle_slider.min_value = -180.0
	joint_angle_slider.max_value = 180.0
	joint_angle_slider.step = 1.0
	joint_angle_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	joint_angle_slider.value_changed.connect(_on_joint_editor_angle_changed)
	joint_angle_row.add_child(joint_angle_slider)
	joint_angle_spin = SpinBox.new()
	joint_angle_spin.min_value = -180.0
	joint_angle_spin.max_value = 180.0
	joint_angle_spin.step = 1.0
	joint_angle_spin.suffix = "°"
	joint_angle_spin.custom_minimum_size.x = 82
	joint_angle_spin.value_changed.connect(_on_joint_editor_angle_changed)
	joint_angle_row.add_child(joint_angle_spin)
	var joint_action_row := HBoxContainer.new()
	right.add_child(joint_action_row)
	_add_button(joint_action_row, "Deshacer", _undo_joint_edit)
	_add_button(joint_action_row, "Rehacer", _redo_joint_edit)
	_add_button(joint_action_row, "Restablecer articulación", _reset_selected_joint)
	_add_button(joint_action_row, "Restablecer todo", _reset_all_joints)
	var timeline_title := Label.new()
	timeline_title.text = "LÍNEA DE TIEMPO · FOTOGRAMAS CLAVE"
	right.add_child(timeline_title)
	var timeline_create_row := HBoxContainer.new()
	right.add_child(timeline_create_row)
	timeline_name_input = LineEdit.new()
	timeline_name_input.placeholder_text = "Nombre del clip"
	timeline_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timeline_create_row.add_child(timeline_name_input)
	_add_button(timeline_create_row, "Nuevo clip", _create_timeline_clip)
	timeline_clip_picker = OptionButton.new()
	timeline_clip_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timeline_clip_picker.item_selected.connect(_on_timeline_clip_selected)
	right.add_child(timeline_clip_picker)
	var timeline_settings := HBoxContainer.new()
	right.add_child(timeline_settings)
	timeline_duration = SpinBox.new()
	timeline_duration.min_value = 0.1
	timeline_duration.max_value = 120.0
	timeline_duration.step = 0.1
	timeline_duration.value = 2.0
	timeline_duration.suffix = " s"
	timeline_duration.value_changed.connect(_on_timeline_duration_changed)
	timeline_settings.add_child(timeline_duration)
	timeline_loop = CheckBox.new()
	timeline_loop.text = "Repetir"
	timeline_loop.button_pressed = true
	timeline_loop.toggled.connect(_on_timeline_loop_changed)
	timeline_settings.add_child(timeline_loop)
	timeline_playhead = HSlider.new()
	timeline_playhead.min_value = 0.0
	timeline_playhead.max_value = 2.0
	timeline_playhead.step = 0.01
	timeline_playhead.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timeline_playhead.value_changed.connect(_on_timeline_playhead_changed)
	right.add_child(timeline_playhead)
	var timeline_key_row := HBoxContainer.new()
	right.add_child(timeline_key_row)
	timeline_time_input = SpinBox.new()
	timeline_time_input.min_value = 0.0
	timeline_time_input.max_value = 120.0
	timeline_time_input.step = 0.05
	timeline_time_input.suffix = " s"
	timeline_key_row.add_child(timeline_time_input)
	_add_button(timeline_key_row, "Capturar pose", _capture_timeline_keyframe)
	_add_button(timeline_key_row, "Eliminar clave", _delete_timeline_keyframe)
	timeline_key_list = ItemList.new()
	timeline_key_list.custom_minimum_size.y = 90
	timeline_key_list.item_selected.connect(_on_timeline_key_selected)
	right.add_child(timeline_key_list)
	var timeline_actions := HBoxContainer.new()
	right.add_child(timeline_actions)
	_add_button(timeline_actions, "Reproducir clip", _play_timeline_clip)
	_add_button(timeline_actions, "Detener", _stop_timeline_clip)
	_add_button(timeline_actions, "Guardar clips", _save_timeline_clips)
	_add_button(timeline_actions, "Exportar personaje JSON", _open_package_export_dialog)
	_add_button(timeline_actions, "Importar paquete JSON", _open_package_import_dialog)
	_add_button(timeline_actions, "Exportar hoja de sprites PNG", _open_spritesheet_export_dialog)
	if timeline_model == null:
		timeline_model = ANIMATION_TIMELINE.new()
	_refresh_timeline_ui()
	var position_title := Label.new()
	position_title.text = "POSICIÓN DE PIVOTES (X / Y)"
	right.add_child(position_title)
	_add_pivot_offset_control(right, "Hombro izquierdo X", "shoulder_left", "x")
	_add_pivot_offset_control(right, "Hombro izquierdo Y", "shoulder_left", "y")
	_add_pivot_offset_control(right, "Codo izquierdo X", "elbow_left", "x")
	_add_pivot_offset_control(right, "Codo izquierdo Y", "elbow_left", "y")
	_add_pivot_offset_control(right, "Hombro derecho X", "shoulder_right", "x")
	_add_pivot_offset_control(right, "Hombro derecho Y", "shoulder_right", "y")
	var texture_title := Label.new()
	texture_title.text = "AJUSTE DE TEXTURA E SEGMENTACIÓN"
	right.add_child(texture_title)
	_add_image_adjustment_slider(right, "Brillo", "brightness", -1.0, 1.0, 0.0)
	_add_image_adjustment_slider(right, "Contraste", "contrast", 0.5, 1.8, 1.0)
	_add_image_adjustment_slider(right, "Saturación", "saturation", 0.0, 2.0, 1.0)
	_add_image_adjustment_slider(right, "Tolerancia del fondo", "tolerance", 0.03, 0.45, 0.16)
	_add_button(right, "Aplicar textura y regenerar recortes", _apply_texture_adjustments)
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


func _add_image_adjustment_slider(parent: Node, label_text: String, key: String, minimum: float, maximum: float, initial: float) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 145
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = 0.01
	slider.value = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	match key:
		"brightness": texture_brightness = slider
		"contrast": texture_contrast = slider
		"saturation": texture_saturation = slider
		"tolerance": background_tolerance = slider

func _apply_texture_adjustments() -> void:
	if imported_source_path.is_empty():
		_set_status("Primero importa una imagen de personaje.")
		return
	var adjusted_path: String = image_processor.create_adjusted_texture(
		imported_source_path,
		texture_brightness.value if is_instance_valid(texture_brightness) else 0.0,
		texture_contrast.value if is_instance_valid(texture_contrast) else 1.0,
		texture_saturation.value if is_instance_valid(texture_saturation) else 1.0
	)
	if adjusted_path.is_empty():
		_set_status("No se pudo generar la textura ajustada.")
		return
	var result: Dictionary = image_processor.process_character_image(
		adjusted_path,
		background_tolerance.value if is_instance_valid(background_tolerance) else 0.16
	)
	if not bool(result.get("ok", false)):
		_set_status("No se pudieron regenerar los recortes: " + str(result.get("error", "")))
		return
	result["original_source"] = imported_source_path
	result["adjusted_source"] = adjusted_path
	imported_character_data = result
	if is_instance_valid(build_segmented_button):
		build_segmented_button.disabled = false
	var preview_image := Image.new()
	if preview_image.load(str(result.get("processed_image", ""))) == OK:
		imported_preview.texture = ImageTexture.create_from_image(preview_image)
	var lines := PackedStringArray()
	lines.append("Textura ajustada: brillo %.2f · contraste %.2f · saturación %.2f" % [texture_brightness.value, texture_contrast.value, texture_saturation.value])
	lines.append("Tolerancia de fondo: %.2f" % background_tolerance.value)
	lines.append("Píxeles de fondo retirados: %d" % int(result.get("background_removed_pixels", 0)))
	lines.append("Recortes regenerados: %d" % result.get("parts", []).size())
	lines.append("Los cambios se aplican de forma local y no modifican el archivo original.")
	image_result_output.text = "\n".join(lines)
	if not project_data.has("image_imports"):
		project_data["image_imports"] = []
	project_data["image_imports"].append(result)
	_save_project()
	_set_status("Textura ajustada y recortes regenerados. Ya puedes reconstruir el rig.")


func _open_3d_model_export_dialog() -> void:
	if not is_instance_valid(runtime_spatial_rig):
		_set_status("Primero importa o construye un modelo 3D.")
		return
	if is_instance_valid(model_3d_export_dialog):
		var base_name := str(generated_character.get("name", "personaje")).validate_filename()
		model_3d_export_dialog.current_file = (base_name if base_name != "" else "personaje") + ".glb"
		model_3d_export_dialog.popup_centered_ratio(0.82)

func _export_3d_model_to_path(path: String) -> void:
	if not is_instance_valid(runtime_spatial_rig):
		_set_status("No hay un modelo 3D activo para exportar.")
		return
	if is_instance_valid(runtime_spatial_animator):
		runtime_spatial_animator.stop_animation()
	if is_instance_valid(runtime_imported_3d_animation_player):
		runtime_imported_3d_animation_player.stop()
	var baked_count := 0
	if is_instance_valid(runtime_spatial_animator):
		var spatial_clips: Array = project_data.get("spatial_animation_clips", [])
		if spatial_clips.is_empty():
			spatial_clips = runtime_spatial_animator.generate_animation_library(motion_intensity_slider.value if is_instance_valid(motion_intensity_slider) else 1.0)
			project_data["spatial_animation_clips"] = spatial_clips
		baked_count = runtime_spatial_animator.bake_clips_to_animation_player(runtime_spatial_rig, spatial_clips)
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var append_error := document.append_from_scene(runtime_spatial_rig, state)
	if append_error != OK:
		_set_status("No se pudo preparar la escena para GLB. Código: %d" % append_error)
		return
	_append_imported_3d_animation_buttons()
	var write_error := document.write_to_filesystem(state, path)
	if write_error != OK:
		_set_status("No se pudo escribir el modelo GLB. Código: %d" % write_error)
		return
	_set_status("Modelo 3D exportado a GLB con %d clips procedurales nativos. El paquete JSON conserva además poses y datos editables." % baked_count)

func _open_3d_model_dialog() -> void:
	if is_instance_valid(model_3d_dialog):
		model_3d_dialog.popup_centered_ratio(0.82)


func _audit_current_spatial_rig() -> void:
	if not is_instance_valid(runtime_spatial_rig):
		_set_status("Importa o genera un personaje 3D antes de auditar.")
		return
	var skeleton := _find_skeleton_in_node(runtime_spatial_rig)
	if skeleton == null:
		_set_status("El modelo actual no contiene Skeleton3D.")
		return
	var archetype := "quadruped" if spatial_rig_archetype.selected == 1 else "humanoid"
	var report: Dictionary = spatial_builder.validate_skeleton(skeleton, archetype)
	var missing: Array = report.get("missing", [])
	var hierarchy: Array = report.get("hierarchy_errors", [])
	var summary := "Auditoría %s · %d huesos · cobertura anatómica %.0f%%" % [archetype, int(report.get("bone_count",0)), float(report.get("coverage",0.0))*100.0]
	if not missing.is_empty():
		summary += " · faltan: " + ", ".join(PackedStringArray(missing))
	if not hierarchy.is_empty():
		summary += " · jerarquía: " + ", ".join(PackedStringArray(hierarchy))
	if is_instance_valid(skeleton_output):
		skeleton_output.text = summary
	_set_status(summary)

func _create_retarget_profile() -> void:
	if not is_instance_valid(runtime_spatial_rig):
		_set_status("Importa primero un modelo 3D con Skeleton3D.")
		return
	var source := _find_skeleton_in_node(runtime_spatial_rig)
	if source == null:
		_set_status("El modelo no contiene un esqueleto de origen.")
		return
	var archetype := "quadruped" if spatial_rig_archetype.selected == 1 else "humanoid"
	var target_root: Node3D = spatial_builder.build_quadruped_3d("RetargetTarget") if archetype == "quadruped" else spatial_builder.build_humanoid_3d("RetargetTarget")
	var target := target_root.get_node_or_null("Skeleton3D") as Skeleton3D
	var retargeter = ANIMATION_RETARGETER.new()
	var profile: Dictionary = retargeter.create_profile(source, target, str(runtime_spatial_rig.name) + " → " + archetype)
	target_root.free()
	if not bool(profile.get("ok",false)):
		_set_status(str(profile.get("error","No se pudo crear el perfil de retargeting.")))
		return
	if not project_data.has("retarget_profiles"):
		project_data["retarget_profiles"] = []
	project_data["retarget_profiles"].append(profile)
	_save_project()
	var summary := "Perfil guardado · %d huesos mapeados · cobertura origen %.0f%% · sin equivalencia: %s" % [int(profile.get("mapped_bone_count",0)),float(profile.get("coverage",0.0))*100.0,", ".join(PackedStringArray(profile.get("unmapped",[])))]
	if is_instance_valid(skeleton_output):
		skeleton_output.text = summary
	_set_status(summary)

func _on_3d_model_selected(path: String) -> void:
	_load_3d_model_from_path(path, true)

func _load_3d_model_from_path(path: String, update_status: bool = true) -> bool:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var parse_error := document.append_from_file(path, state)
	if parse_error != OK:
		if update_status:
			_set_status("No se pudo importar el modelo glTF/GLB. Código: %d" % parse_error)
		return false
	var generated_scene := document.generate_scene(state)
	if generated_scene == null:
		if update_status:
			_set_status("El archivo 3D se leyó, pero no se pudo construir la escena.")
		return false
	if is_instance_valid(runtime_rig):
		runtime_rig.queue_free()
		runtime_rig = null
	if is_instance_valid(runtime_spatial_rig):
		runtime_spatial_rig.queue_free()
	runtime_spatial_animator = null
	runtime_imported_3d_animation_player = null
	var model_root: Node3D
	if generated_scene is Node3D:
		model_root = generated_scene as Node3D
	else:
		model_root = Node3D.new()
		model_root.add_child(generated_scene)
	model_root.name = "Imported3D_" + path.get_file().get_basename().validate_filename()
	model_root.set_meta("rig_type", "3D_imported_skeleton")
	spatial_subviewport.add_child(model_root)
	_fit_imported_3d_model(model_root)
	runtime_spatial_rig = model_root
	rig_2d_container.visible = false
	spatial_container.visible = true
	character_mode.select(2)
	imported_3d_model_path = path
	if generated_character.is_empty():
		generated_character = {
			"name": path.get_file().get_basename(),
			"description": "Modelo 3D importado desde glTF/GLB",
			"rig": {"type":"3D_imported_skeleton"}
		}
	var imported_skeleton := _find_skeleton_in_node(model_root)
	runtime_imported_3d_animation_player = _find_animation_player_in_node(model_root)
	if imported_skeleton != null:
		runtime_spatial_animator = CHARACTER_SPATIAL_ANIMATOR.new()
		runtime_spatial_animator.name = "Procedural3DAnimator"
		model_root.add_child(runtime_spatial_animator)
		runtime_spatial_animator.configure(imported_skeleton, runtime_imported_3d_animation_player, model_root)
		runtime_spatial_animator.play_animation("idle")
		if is_instance_valid(animation_controls):
			for child in animation_controls.get_children():
				child.queue_free()
			_add_button(animation_controls, "Idle procedural", _play_rig_animation.bind("idle"))
			_append_imported_3d_animation_buttons()
		_append_facial_expression_buttons()
		character_output.text = "Modelo 3D importado con Skeleton3D. Se conservan sus mallas, materiales y texturas; puedes reproducir sus animaciones originales y generar poses procedurales usando equivalencias de huesos humanoides."
		if update_status:
			_set_status("Modelo 3D con esqueleto importado. Animaciones originales disponibles y rig procedural conectado.")
	else:
		if is_instance_valid(animation_controls):
			for child in animation_controls.get_children():
				child.queue_free()
			_append_imported_3d_animation_buttons()
		character_output.text = "Modelo 3D importado sin Skeleton3D. Se conservan mallas, materiales y posibles animaciones de nodos; no se pueden generar poses de huesos."
		if update_status:
			_set_status("Modelo 3D importado. No contiene Skeleton3D; se revisaron las animaciones originales disponibles.")
	_refresh_timeline_ui()
	return true

func _fit_imported_3d_model(model_root: Node3D) -> void:
	var found_mesh := false
	var bounds := AABB()
	for node in model_root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var relative_transform := model_root.global_transform.affine_inverse() * mesh_instance.global_transform
		var transformed_bounds: AABB = relative_transform * mesh_instance.get_aabb()
		if not found_mesh:
			bounds = transformed_bounds
			found_mesh = true
		else:
			bounds = bounds.merge(transformed_bounds)
	if not found_mesh:
		return
	var maximum_extent := maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	if maximum_extent <= 0.0001:
		return
	var fit_scale := 2.0 / maximum_extent
	model_root.scale *= fit_scale
	model_root.position = Vector3(0.0, 1.0, 0.0) - bounds.get_center() * fit_scale

func _append_imported_3d_animation_buttons() -> void:
	if not is_instance_valid(animation_controls):
		return
	if is_instance_valid(runtime_imported_3d_animation_player):
		for animation_name in runtime_imported_3d_animation_player.get_animation_list():
			var original_key := str(animation_name)
			if original_key.to_upper() == "RESET":
				continue
			var original_label := "Original: " + original_key
			if not _animation_button_exists(original_label):
				_add_button(animation_controls, original_label, _play_imported_3d_animation.bind(original_key))
	var baked_player: AnimationPlayer = runtime_spatial_rig.get_node_or_null("ProceduralAnimationPlayer") as AnimationPlayer if is_instance_valid(runtime_spatial_rig) else null
	if is_instance_valid(baked_player):
		for animation_name in baked_player.get_animation_list():
			var baked_key := str(animation_name)
			var baked_label := "GLB: " + baked_key
			if not _animation_button_exists(baked_label):
				_add_button(animation_controls, baked_label, _play_baked_3d_animation.bind(baked_key))

func _append_facial_expression_buttons() -> void:
	if not is_instance_valid(animation_controls) or not is_instance_valid(runtime_spatial_animator):
		return
	if not runtime_spatial_animator.has_facial_expressions():
		return
	var separator := HSeparator.new()
	separator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	animation_controls.add_child(separator)
	var heading := Label.new()
	heading.text = "EXPRESIONES FACIALES"
	heading.add_theme_color_override("font_color", Color("#315b83"))
	animation_controls.add_child(heading)
	for expression_name in runtime_spatial_animator.get_facial_expression_names():
		_add_button(animation_controls, str(expression_name), _apply_facial_expression.bind(str(expression_name)))
	var available_shapes := ", ".join(runtime_spatial_animator.get_blend_shape_names())
	var info := Label.new()
	info.text = "Blend shapes detectados: " + available_shapes
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	animation_controls.add_child(info)

func _apply_facial_expression(expression_name: String) -> void:
	if not is_instance_valid(runtime_spatial_animator):
		return
	runtime_spatial_animator.stop_animation()
	var changed: int = runtime_spatial_animator.apply_facial_expression(expression_name)
	if changed > 0:
		_set_status("Expresión «%s» aplicada a %d controles faciales." % [expression_name, changed])
	else:
		_set_status("No se encontró un blend shape compatible con «%s» en este modelo." % expression_name)

func _animation_button_exists(label: String) -> bool:
	if not is_instance_valid(animation_controls):
		return false
	for child in animation_controls.get_children():
		if child is Button and child.text == label:
			return true
	return false

func _play_baked_3d_animation(animation_name: String) -> void:
	if not is_instance_valid(runtime_spatial_rig):
		return
	var baked_player := runtime_spatial_rig.get_node_or_null("ProceduralAnimationPlayer") as AnimationPlayer
	if not is_instance_valid(baked_player) or not baked_player.has_animation(animation_name):
		_set_status("La animación GLB ya no está disponible.")
		return
	if is_instance_valid(runtime_spatial_animator):
		runtime_spatial_animator.stop_animation()
	if is_instance_valid(runtime_imported_3d_animation_player):
		runtime_imported_3d_animation_player.stop()
	baked_player.play(animation_name)
	_set_status("Reproduciendo clip GLB «%s»." % animation_name)

func _play_imported_3d_animation(animation_name: String) -> void:
	if not is_instance_valid(runtime_imported_3d_animation_player) or not runtime_imported_3d_animation_player.has_animation(animation_name):
		_set_status("La animación original ya no está disponible.")
		return
	if is_instance_valid(runtime_spatial_animator):
		runtime_spatial_animator.stop_animation()
	runtime_imported_3d_animation_player.play(animation_name)
	_set_status("Reproduciendo animación original «%s»." % animation_name)

func _find_skeleton_in_node(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton_in_node(child)
		if found != null:
			return found
	return null

func _find_animation_player_in_node(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer and node.name != "ProceduralAnimationPlayer":
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player_in_node(child)
		if found != null:
			return found
	return null

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
	if not is_instance_valid(runtime_rig):
		var selected_mode := character_mode.get_item_text(character_mode.selected)
		if selected_mode == "3D esqueleto":
			if not is_instance_valid(runtime_spatial_rig):
				_generate_character()
			if is_instance_valid(runtime_spatial_animator):
				_generate_spatial_pose_set()
			else:
				_set_status("No se pudo inicializar el animador del esqueleto 3D.")
			return
		if selected_mode == "2.5D por planos" and imported_preview.texture != null:
			_set_status("El plano 2.5D no tiene articulaciones independientes. Usa el modo 3D esqueleto o un rig 2D.")
			return
		_generate_character()
	if procedural_animator == null:
		procedural_animator = CHARACTER_PROCEDURAL_ANIMATOR.new()
	var intensity := motion_intensity_slider.value if is_instance_valid(motion_intensity_slider) else 1.0
	var generated: Dictionary = procedural_animator.generate_pose_library(intensity)
	procedural_poses = generated.get("poses", [])
	var clips: Array = generated.get("animations", [])
	var added := 0
	var applied := 0
	if is_instance_valid(runtime_rig):
		added = rig_builder.add_procedural_animation_set(runtime_rig, clips)
		if not procedural_poses.is_empty():
			applied = rig_builder.apply_procedural_pose(runtime_rig, procedural_poses[0].get("joint_angles", {}))
	if is_instance_valid(pose_controls):
		for child in pose_controls.get_children():
			child.queue_free()
		for pose in procedural_poses:
			_add_button(pose_controls, str(pose.get("name", "Pose")), _apply_generated_pose.bind(pose))
		for pose in project_data.get("custom_procedural_poses", []):
			_add_button(pose_controls, str(pose.get("name", "Pose propia")), _apply_generated_pose.bind(pose))
	if is_instance_valid(animation_controls):
		for child in animation_controls.get_children():
			child.queue_free()
		for clip in clips:
			var clip_key := "proc_" + str(clip.get("name", "generated")).validate_filename().to_lower()
			_add_button(animation_controls, str(clip.get("name", "Animación")), _play_rig_animation.bind(clip_key))
	var record := {"character": character_name.text if is_instance_valid(character_name) else "Personaje", "poses": procedural_poses, "animations": clips, "intensity": intensity, "generator": "procedural_v1"}
	if not project_data.has("procedural_pose_sets"):
		project_data["procedural_pose_sets"] = []
	project_data["procedural_pose_sets"].append(record)
	_save_project()
	var lines := PackedStringArray()
	lines.append("GENERACIÓN PROCEDURAL COMPLETADA")
	lines.append("Poses listas: %d" % procedural_poses.size())
	lines.append("Ciclos de animación creados: %d" % clips.size())
	lines.append("Intensidad aplicada: %.2f×" % intensity)
	lines.append("Clips añadidos al rig actual: %d" % added)
	lines.append("Primera pose aplicada: %d articulaciones" % applied)
	lines.append("")
	var pose_names := PackedStringArray()
	for pose in procedural_poses:
		pose_names.append(str(pose.get("name", "Pose")))
	var clip_names := PackedStringArray()
	for clip in clips:
		clip_names.append(str(clip.get("name", "Animación")))
	lines.append("Poses: " + ", ".join(pose_names))
	lines.append("Animaciones: " + ", ".join(clip_names))
	lines.append("Cálculo local determinista: curvas matemáticas y keyframes; sin conexión, modelos ni procesos externos.")
	if is_instance_valid(image_result_output):
		image_result_output.text = "\n".join(lines)
	_set_status("Generador procedural: %d poses y %d animaciones guardadas." % [procedural_poses.size(), clips.size()])

func _generate_spatial_pose_set() -> void:
	if not is_instance_valid(runtime_spatial_animator):
		return
	var intensity := motion_intensity_slider.value if is_instance_valid(motion_intensity_slider) else 1.0
	procedural_poses = runtime_spatial_animator.generate_pose_library(intensity)
	for custom_pose in project_data.get("spatial_custom_poses", []):
		procedural_poses.append(custom_pose.duplicate(true))
	var clips: Array = runtime_spatial_animator.generate_animation_library(intensity)
	if not procedural_poses.is_empty():
		runtime_spatial_animator.apply_pose(procedural_poses[0])
	if is_instance_valid(pose_controls):
		for child in pose_controls.get_children():
			child.queue_free()
		for pose in procedural_poses:
			_add_button(pose_controls, str(pose.get("name", "Pose")), _apply_generated_pose.bind(pose))
	if is_instance_valid(animation_controls):
		for child in animation_controls.get_children():
			child.queue_free()
		for clip in clips:
			_add_button(animation_controls, str(clip.get("name", "Animación")).capitalize(), _play_rig_animation.bind(str(clip.get("name", ""))))
		_append_imported_3d_animation_buttons()
		_append_facial_expression_buttons()
	project_data["spatial_animation_clips"] = clips
	_refresh_timeline_ui()
	project_data["spatial_procedural_poses"] = procedural_poses.duplicate(true)
	project_data["spatial_pose_sets"] = project_data.get("spatial_pose_sets", [])
	project_data["spatial_pose_sets"].append({
		"character": str(generated_character.get("name", "Personaje 3D")),
		"poses": procedural_poses,
		"animations": clips,
		"intensity": intensity,
		"generator": "spatial_procedural_v1"
	})
	_save_project()
	_set_status("Animación 3D procedural: %d poses y %d ciclos creados." % [procedural_poses.size(), clips.size()])

func _apply_generated_pose(pose: Dictionary) -> void:
	if is_instance_valid(runtime_spatial_animator) and not is_instance_valid(runtime_rig):
		var applied_3d: int = runtime_spatial_animator.apply_pose(pose)
		_set_status("Pose 3D «%s» aplicada en %d huesos." % [str(pose.get("name", "Pose")), applied_3d])
		return
	if not is_instance_valid(runtime_rig):
		_set_status("Primero crea el esqueleto del personaje.")
		return
	rig_builder.stop_animation(runtime_rig)
	var angles: Dictionary = pose.get("joint_angles", {})
	var applied: int = rig_builder.apply_procedural_pose(runtime_rig, angles)
	_set_status("Pose «%s» aplicada en %d articulaciones." % [str(pose.get("name", "Pose")), applied])


func _timeline_clips() -> Array:
	if is_instance_valid(runtime_spatial_animator) or (is_instance_valid(character_mode) and character_mode.selected == 2):
		if not project_data.has("spatial_animation_clips"):
			project_data["spatial_animation_clips"] = []
		return project_data["spatial_animation_clips"]
	if not project_data.has("animation_clips"):
		project_data["animation_clips"] = []
	return project_data["animation_clips"]

func _active_timeline_clip() -> Dictionary:
	var clips := _timeline_clips()
	if not is_instance_valid(timeline_clip_picker) or timeline_clip_picker.selected < 0 or timeline_clip_picker.selected >= clips.size():
		return {}
	return clips[timeline_clip_picker.selected]

func _refresh_timeline_ui() -> void:
	if not is_instance_valid(timeline_clip_picker):
		return
	var selected := timeline_clip_picker.selected
	timeline_clip_picker.clear()
	var clips := _timeline_clips()
	for clip in clips:
		timeline_clip_picker.add_item(str(clip.get("name", "Clip")))
	if not clips.is_empty():
		timeline_clip_picker.select(clampi(selected, 0, clips.size() - 1))
		_on_timeline_clip_selected(timeline_clip_picker.selected)
	else:
		timeline_key_list.clear()
		timeline_playhead.value = 0.0

func _create_timeline_clip() -> void:
	var clip_name := timeline_name_input.text.strip_edges()
	if clip_name.is_empty():
		clip_name = "Animación %d" % (_timeline_clips().size() + 1)
	var clip := {"name": clip_name, "duration": 2.0, "loop": true, "interpolation": "linear", "keyframes": []}
	_timeline_clips().append(clip)
	timeline_name_input.clear()
	_refresh_timeline_ui()
	_set_status("Clip «%s» creado. Captura poses en distintos tiempos." % clip_name)

func _on_timeline_clip_selected(index: int) -> void:
	var clip := _active_timeline_clip()
	if clip.is_empty():
		return
	timeline_duration.set_value_no_signal(float(clip.get("duration", 2.0)))
	timeline_loop.set_pressed_no_signal(bool(clip.get("loop", true)))
	timeline_playhead.max_value = float(clip.get("duration", 2.0))
	timeline_time_input.max_value = timeline_playhead.max_value
	_refresh_timeline_keys()

func _on_timeline_duration_changed(value: float) -> void:
	var clip := _active_timeline_clip()
	if clip.is_empty():
		return
	clip["duration"] = value
	timeline_playhead.max_value = value
	timeline_time_input.max_value = value
	timeline_playhead.value = minf(timeline_playhead.value, value)

func _on_timeline_loop_changed(enabled: bool) -> void:
	var clip := _active_timeline_clip()
	if not clip.is_empty():
		clip["loop"] = enabled

func _refresh_timeline_keys() -> void:
	if not is_instance_valid(timeline_key_list):
		return
	timeline_key_list.clear()
	var clip := _active_timeline_clip()
	for frame in clip.get("keyframes", []):
		var count: int = frame.get("bone_rotations_degrees", frame.get("joint_angles", {})).size()
		timeline_key_list.add_item("%.2f s · %d articulaciones" % [float(frame.get("time", 0.0)), count])

func _on_timeline_playhead_changed(value: float) -> void:
	if is_instance_valid(timeline_time_input):
		timeline_time_input.set_value_no_signal(value)
	var clip := _active_timeline_clip()
	if clip.is_empty() or (not is_instance_valid(runtime_rig) and not is_instance_valid(runtime_spatial_animator)):
		return
	if is_instance_valid(runtime_spatial_animator):
		var spatial_pose: Dictionary = timeline_model.sample_pose(clip, value, "bone_rotations_degrees")
		if not spatial_pose.is_empty():
			runtime_spatial_animator.apply_pose({"bone_rotations_degrees": spatial_pose})
	elif is_instance_valid(runtime_rig):
		var pose: Dictionary = timeline_model.sample_pose(clip, value)
		if not pose.is_empty():
			rig_builder.stop_animation(runtime_rig)
			rig_builder.apply_procedural_pose(runtime_rig, pose)

func _on_timeline_key_selected(index: int) -> void:
	var clip := _active_timeline_clip()
	var frames: Array = clip.get("keyframes", [])
	if index >= 0 and index < frames.size():
		timeline_playhead.value = float(frames[index].get("time", 0.0))

func _capture_timeline_keyframe() -> void:
	var clip := _active_timeline_clip()
	if clip.is_empty() or (not is_instance_valid(runtime_rig) and not is_instance_valid(runtime_spatial_animator)):
		_set_status("Crea un clip y un rig antes de capturar fotogramas.")
		return
	var at := clampf(timeline_time_input.value, 0.0, float(clip.get("duration", 2.0)))
	var pose: Dictionary
	if is_instance_valid(runtime_spatial_animator):
		pose = runtime_spatial_animator.capture_pose()
		if pose.is_empty():
			return
		clip["keyframes"] = timeline_model.insert_keyframe(clip.get("keyframes", []), at, pose, "bone_rotations_degrees")
	else:
		pose = rig_builder.capture_procedural_pose(runtime_rig)
		if pose.is_empty():
			return
		clip["keyframes"] = timeline_model.insert_keyframe(clip.get("keyframes", []), at, pose)
	timeline_playhead.value = at
	_refresh_timeline_keys()
	_set_status("Fotograma clave guardado en %.2f segundos." % at)

func _delete_timeline_keyframe() -> void:
	var clip := _active_timeline_clip()
	if clip.is_empty() or timeline_key_list.get_selected_items().is_empty():
		return
	var index: int = timeline_key_list.get_selected_items()[0]
	clip["keyframes"] = timeline_model.remove_keyframe(clip.get("keyframes", []), index)
	_refresh_timeline_keys()

func _play_timeline_clip() -> void:
	var clip := _active_timeline_clip()
	if clip.is_empty() or clip.get("keyframes", []).is_empty() or (not is_instance_valid(runtime_rig) and not is_instance_valid(runtime_spatial_animator)):
		_set_status("El clip necesita al menos un fotograma clave y un rig.")
		return
	var speed := animation_speed_slider.value if is_instance_valid(animation_speed_slider) else 1.0
	if is_instance_valid(runtime_spatial_animator):
		if runtime_spatial_animator.play_clip(clip, speed):
			_set_status("Reproduciendo clip 3D «%s»." % clip.get("name", "Clip"))
		else:
			_set_status("El clip 3D no contiene fotogramas de huesos válidos.")
		return
	var installed: int = rig_builder.add_procedural_animation_set(runtime_rig, [clip])
	var key := "proc_" + str(clip.get("name", "clip")).validate_filename().to_lower()
	if installed > 0 and rig_builder.play_animation(runtime_rig, key, speed):
		_set_status("Reproduciendo «%s»." % clip.get("name", "Clip"))
	else:
		_set_status("No se pudo reproducir el clip. Comprueba que las claves tengan articulaciones compatibles.")

func _stop_timeline_clip() -> void:
	if is_instance_valid(runtime_rig):
		rig_builder.stop_animation(runtime_rig)
	if is_instance_valid(runtime_spatial_animator):
		runtime_spatial_animator.stop_animation()
	if is_instance_valid(runtime_imported_3d_animation_player):
		runtime_imported_3d_animation_player.stop()
	if is_instance_valid(runtime_spatial_rig):
		var baked_player := runtime_spatial_rig.get_node_or_null("ProceduralAnimationPlayer") as AnimationPlayer
		if is_instance_valid(baked_player):
			baked_player.stop()
	_set_status("Reproducción detenida.")

func _save_timeline_clips() -> void:
	_save_project()
	_set_status("Biblioteca de clips guardada en el proyecto.")

func _save_current_procedural_pose() -> void:
	var pose_name := custom_pose_name_input.text.strip_edges() if is_instance_valid(custom_pose_name_input) else ""
	if is_instance_valid(runtime_spatial_animator) and not is_instance_valid(runtime_rig):
		var bone_rotations: Dictionary = runtime_spatial_animator.capture_pose()
		if bone_rotations.is_empty():
			_set_status("No se encontraron huesos para guardar.")
			return
		if pose_name == "":
			pose_name = "Pose 3D personalizada %d" % (project_data.get("spatial_custom_poses", []).size() + 1)
		var spatial_pose := {"name":pose_name,"bone_rotations_degrees":bone_rotations,"custom":true}
		if not project_data.has("spatial_custom_poses"):
			project_data["spatial_custom_poses"] = []
		project_data["spatial_custom_poses"].append(spatial_pose)
		if not project_data.has("spatial_procedural_poses"):
			project_data["spatial_procedural_poses"] = []
		project_data["spatial_procedural_poses"].append(spatial_pose.duplicate(true))
		procedural_poses.append(spatial_pose.duplicate(true))
		if is_instance_valid(pose_controls):
			_add_button(pose_controls, pose_name, _apply_generated_pose.bind(spatial_pose))
		if is_instance_valid(custom_pose_name_input):
			custom_pose_name_input.clear()
		_save_project()
		_set_status("Pose 3D «%s» guardada en la biblioteca personalizada." % pose_name)
		return
	if not is_instance_valid(runtime_rig):
		_set_status("Primero crea o construye un rig.")
		return
	var angles: Dictionary = rig_builder.capture_procedural_pose(runtime_rig)
	if angles.is_empty():
		_set_status("No se encontraron articulaciones para guardar.")
		return
	if pose_name == "":
		pose_name = "Pose personalizada %d" % (project_data.get("custom_procedural_poses", []).size() + 1)
	var pose := {"name": pose_name, "joint_angles": angles, "custom": true}
	if not project_data.has("custom_procedural_poses"):
		project_data["custom_procedural_poses"] = []
	project_data["custom_procedural_poses"].append(pose)
	if is_instance_valid(pose_controls):
		_add_button(pose_controls, pose_name, _apply_generated_pose.bind(pose))
	if is_instance_valid(custom_pose_name_input):
		custom_pose_name_input.clear()
	_save_project()
	_set_status("Pose «%s» guardada en tu biblioteca personalizada." % pose_name)

func _generate_character() -> void:
	var label := character_name.text.strip_edges()
	if label == "":
		label = "Personaje nuevo"
	generated_character = blueprint_builder.build_character_blueprint(label, character_description.text.strip_edges(), character_mode.get_item_text(character_mode.selected))
	character_preview.character_label = label
	character_preview.rig_data = generated_character.rig
	character_preview.queue_redraw()
	character_output.text = "Ficha creada: %s\nEstilo: %s\nVistas de referencia: frente, perfil, espalda y tres cuartos. El dibujo visible es una guía esquemática; las poses se generan con el sistema procedural integrado." % [label,character_style.get_item_text(character_style.selected)]
	skeleton_output.text = blueprint_builder.format_rig_summary(generated_character.rig)
	_build_runtime_character()
	if not project_data.has("characters"):
		project_data["characters"] = []
	project_data["characters"].append(generated_character)
	_save_project()
	_set_status("Ficha y esqueleto procedural creados y guardados. Revisa articulaciones antes de animar.")

func _build_runtime_character() -> void:
	if rig_subviewport == null:
		return
	joint_undo_stack.clear()
	joint_redo_stack.clear()
	if is_instance_valid(ik_drag_overlay):
		ik_drag_overlay.queue_free()
		ik_drag_overlay = null
	if is_instance_valid(runtime_rig):
		runtime_rig.queue_free()
	if is_instance_valid(runtime_spatial_rig):
		runtime_spatial_rig.queue_free()
	runtime_spatial_animator = null
	runtime_imported_3d_animation_player = null
	imported_3d_model_path = ""
	var label := str(generated_character.get("name", character_name.text if character_name != null else "Personaje"))
	var selected_mode := character_mode.get_item_text(character_mode.selected)
	if selected_mode == "3D esqueleto":
		rig_2d_container.visible = false
		spatial_container.visible = true
		if is_instance_valid(spatial_rig_archetype) and spatial_rig_archetype.selected == 1:
			runtime_spatial_rig = spatial_builder.build_quadruped_3d(label)
		else:
			runtime_spatial_rig = spatial_builder.build_humanoid_3d(label)
		spatial_subviewport.add_child(runtime_spatial_rig)
		var spatial_skeleton := runtime_spatial_rig.get_node_or_null("Skeleton3D") as Skeleton3D
		runtime_spatial_animator = CHARACTER_SPATIAL_ANIMATOR.new()
		runtime_spatial_animator.name = "Procedural3DAnimator"
		runtime_spatial_rig.add_child(runtime_spatial_animator)
		runtime_spatial_animator.configure(spatial_skeleton, null, runtime_spatial_rig)
		runtime_spatial_animator.play_animation("idle")
		character_output.text = "Rig espacial 3D creado con Skeleton3D, articulaciones independientes y animación procedural local. Genera poses y ciclos desde el botón de animación."
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
			_attach_ik_overlay()
			rig_builder.play_animation(runtime_rig, "idle")
			character_output.text = "Importa una imagen para crear el plano 2.5D; se muestra temporalmente el rig 2D."
	else:
		rig_2d_container.visible = true
		spatial_container.visible = false
		runtime_rig = rig_builder.build_runtime_rig(label, 1.0)
		runtime_rig.position = Vector2(210, 145)
		rig_subviewport.add_child(runtime_rig)
		_attach_ik_overlay()
		rig_builder.play_animation(runtime_rig, "idle")
	_refresh_timeline_ui()

func _attach_ik_overlay() -> void:
	if is_instance_valid(ik_drag_overlay):
		ik_drag_overlay.queue_free()
	ik_drag_overlay = IK_DRAG_OVERLAY.new()
	ik_drag_overlay.name = "IKDragOverlay"
	rig_subviewport.add_child(ik_drag_overlay)
	ik_drag_overlay.configure(runtime_rig, rig_builder)

func _build_imported_segment_rig() -> void:
	joint_undo_stack.clear()
	joint_redo_stack.clear()
	var parts: Array = imported_character_data.get("parts", [])
	if parts.is_empty():
		_set_status("No hay piezas recortadas para construir el rig.")
		return
	var joints: Dictionary = {}
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
	_attach_ik_overlay()
	rig_builder.play_animation(runtime_rig, "idle")
	character_output.text = "Rig construido con regiones proporcionales locales. Son recortes aproximados, no segmentación semántica; ajusta los pivotes y las piezas manualmente si es necesario."
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

func _add_ik_target_axis(parent: Node, axis_label: String, initial: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = -5.0
	spin.max_value = 5.0
	spin.step = 0.05
	spin.value = initial
	spin.prefix = axis_label + " "
	spin.custom_minimum_size.x = 92
	parent.add_child(spin)
	return spin

func _apply_3d_ik_target() -> void:
	if not is_instance_valid(runtime_spatial_animator):
		_set_status("Construye o importa un rig 3D con Skeleton3D para usar IK.")
		return
	var before: Dictionary = runtime_spatial_animator.capture_pose()
	if not before.is_empty():
		joint_undo_stack.append(before.duplicate(true))
		if joint_undo_stack.size() > 50:
			joint_undo_stack.pop_front()
		joint_redo_stack.clear()
	var chain := str(ik_chain_picker.get_item_metadata(ik_chain_picker.selected))
	var target := Vector3(ik_target_x.value, ik_target_y.value, ik_target_z.value)
	var result: Dictionary = runtime_spatial_animator.apply_two_bone_ik(chain, target)
	if not bool(result.get("ok", false)):
		_set_status(str(result.get("error", "No se pudo resolver la cadena IK 3D.")))
		return
	var error_distance := float(result.get("error_distance", 0.0))
	_set_status("IK 3D aplicado. Error de alcance: %.3f unidades." % error_distance)
	_on_joint_editor_selection_changed(joint_picker.selected if is_instance_valid(joint_picker) else 0)

func _spatial_bone_name(joint_key: String) -> String:
	var names := {
		"pelvis":"Pelvis", "torso":"Chest", "neck":"Neck", "head":"Head", "jaw":"Jaw",
		"shoulder_left":"Shoulder_L", "elbow_left":"Elbow_L", "wrist_left":"Wrist_L",
		"shoulder_right":"Shoulder_R", "elbow_right":"Elbow_R", "wrist_right":"Wrist_R",
		"hip_left":"Hip_L", "knee_left":"Knee_L", "ankle_left":"Ankle_L",
		"hip_right":"Hip_R", "knee_right":"Knee_R", "ankle_right":"Ankle_R",
		"front_hip_left":"FrontHip_L", "front_knee_left":"FrontKnee_L", "front_ankle_left":"FrontAnkle_L",
		"front_hip_right":"FrontHip_R", "front_knee_right":"FrontKnee_R", "front_ankle_right":"FrontAnkle_R",
		"back_hip_left":"BackHip_L", "back_knee_left":"BackKnee_L", "back_ankle_left":"BackAnkle_L",
		"back_hip_right":"BackHip_R", "back_knee_right":"BackKnee_R", "back_ankle_right":"BackAnkle_R",
		"tail_01":"Tail_01", "tail_02":"Tail_02", "tail_03":"Tail_03", "tail_04":"Tail_04"
	}
	return str(names.get(joint_key, ""))

func _capture_joint_editor_pose() -> Dictionary:
	if is_instance_valid(runtime_rig):
		return rig_builder.capture_procedural_pose(runtime_rig)
	if is_instance_valid(runtime_spatial_animator):
		return runtime_spatial_animator.capture_pose()
	return {}

func _apply_joint_editor_pose(snapshot: Dictionary) -> void:
	if is_instance_valid(runtime_rig):
		rig_builder.stop_animation(runtime_rig)
		rig_builder.apply_procedural_pose(runtime_rig, snapshot)
	elif is_instance_valid(runtime_spatial_animator):
		runtime_spatial_animator.apply_pose({"bone_rotations_degrees": snapshot})

func _on_joint_editor_selection_changed(index: int) -> void:
	if not is_instance_valid(joint_picker):
		return
	var key := str(joint_picker.get_item_metadata(index))
	var value := 0.0
	if is_instance_valid(runtime_rig):
		value = float(rig_builder.capture_procedural_pose(runtime_rig).get(key, 0.0))
	elif is_instance_valid(runtime_spatial_animator):
		var bone_name := _spatial_bone_name(key)
		var rotations: Dictionary = runtime_spatial_animator.capture_pose()
		var angles: Array = rotations.get(bone_name, [0.0, 0.0, 0.0])
		var axis_index := joint_axis_picker.selected if is_instance_valid(joint_axis_picker) else 2
		value = float(angles[axis_index]) if angles.size() > axis_index else 0.0
	else:
		return
	joint_editor_syncing = true
	joint_angle_slider.value = value
	joint_angle_spin.value = value
	joint_editor_syncing = false

func _on_joint_editor_angle_changed(value: float) -> void:
	if joint_editor_syncing or not is_instance_valid(joint_picker):
		return
	var key := str(joint_picker.get_item_metadata(joint_picker.selected))
	var before := _capture_joint_editor_pose()
	if before.is_empty():
		return
	joint_undo_stack.append(before.duplicate(true))
	if joint_undo_stack.size() > 50:
		joint_undo_stack.pop_front()
	joint_redo_stack.clear()
	joint_editor_syncing = true
	joint_angle_slider.value = value
	joint_angle_spin.value = value
	joint_editor_syncing = false
	if is_instance_valid(runtime_rig):
		var applied: int = rig_builder.apply_procedural_pose(runtime_rig, {key: value})
		if applied == 0:
			_set_status("Esta articulación no existe en el rig actual.")
			return
	elif is_instance_valid(runtime_spatial_animator):
		var bone_name := _spatial_bone_name(key)
		if bone_name == "":
			_set_status("Esta articulación no existe en el rig 3D actual.")
			return
		var rotations := before.duplicate(true)
		var bone_angles: Array = rotations.get(bone_name, [0.0, 0.0, 0.0]).duplicate()
		var axis_index := joint_axis_picker.selected if is_instance_valid(joint_axis_picker) else 2
		bone_angles[axis_index] = clampf(value, -180.0, 180.0)
		rotations[bone_name] = bone_angles
		runtime_spatial_animator.apply_pose({"bone_rotations_degrees": rotations})
	_set_status("Articulación %s ajustada a %.0f°." % [joint_picker.get_item_text(joint_picker.selected), value])

func _restore_joint_snapshot(snapshot: Dictionary) -> void:
	_apply_joint_editor_pose(snapshot)
	_on_joint_editor_selection_changed(joint_picker.selected if is_instance_valid(joint_picker) else 0)

func _undo_joint_edit() -> void:
	if joint_undo_stack.is_empty():
		return
	var current := _capture_joint_editor_pose()
	if current.is_empty():
		return
	joint_redo_stack.append(current)
	var snapshot: Dictionary = joint_undo_stack.pop_back()
	_restore_joint_snapshot(snapshot)
	_set_status("Último ajuste de articulación deshecho.")

func _redo_joint_edit() -> void:
	if joint_redo_stack.is_empty():
		return
	var current := _capture_joint_editor_pose()
	if current.is_empty():
		return
	joint_undo_stack.append(current)
	var snapshot: Dictionary = joint_redo_stack.pop_back()
	_restore_joint_snapshot(snapshot)
	_set_status("Ajuste de articulación rehecho.")

func _reset_selected_joint() -> void:
	if not is_instance_valid(joint_picker):
		return
	var key := str(joint_picker.get_item_metadata(joint_picker.selected))
	var before := _capture_joint_editor_pose()
	if before.is_empty():
		return
	joint_undo_stack.append(before.duplicate(true))
	joint_redo_stack.clear()
	if is_instance_valid(runtime_rig):
		rig_builder.stop_animation(runtime_rig)
		if rig_builder.apply_procedural_pose(runtime_rig, {key: 0.0}) > 0:
			_on_joint_editor_selection_changed(joint_picker.selected)
			_set_status("Articulación restablecida a 0°.")
	elif is_instance_valid(runtime_spatial_animator):
		var bone_name := _spatial_bone_name(key)
		if bone_name != "":
			var rotations := before.duplicate(true)
			var bone_angles: Array = rotations.get(bone_name, [0.0, 0.0, 0.0]).duplicate()
			var axis_index := joint_axis_picker.selected if is_instance_valid(joint_axis_picker) else 2
			bone_angles[axis_index] = 0.0
			rotations[bone_name] = bone_angles
			runtime_spatial_animator.apply_pose({"bone_rotations_degrees": rotations})
			_on_joint_editor_selection_changed(joint_picker.selected)
			_set_status("Articulación 3D restablecida a 0°.")

func _reset_all_joints() -> void:
	var before := _capture_joint_editor_pose()
	if before.is_empty():
		return
	joint_undo_stack.append(before.duplicate(true))
	joint_redo_stack.clear()
	if is_instance_valid(runtime_rig):
		var neutral: Dictionary = {}
		for key in before.keys():
			neutral[key] = 0.0
		rig_builder.stop_animation(runtime_rig)
		rig_builder.apply_procedural_pose(runtime_rig, neutral)
	elif is_instance_valid(runtime_spatial_animator):
		var neutral_3d: Dictionary = {}
		for key in before.keys():
			neutral_3d[key] = [0.0, 0.0, 0.0]
		runtime_spatial_animator.apply_pose({"bone_rotations_degrees": neutral_3d})
	_on_joint_editor_selection_changed(joint_picker.selected if is_instance_valid(joint_picker) else 0)
	_set_status("Todas las articulaciones se restablecieron a 0°.")

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
	var speed := animation_speed_slider.value if is_instance_valid(animation_speed_slider) else 1.0
	var intensity := motion_intensity_slider.value if is_instance_valid(motion_intensity_slider) else 1.0
	if is_instance_valid(runtime_rig):
		rig_builder.play_animation(runtime_rig, animation_name, speed)
	elif is_instance_valid(runtime_spatial_rig):
		for clip in project_data.get("spatial_animation_clips", []):
			if str(clip.get("name", "")).to_lower() == animation_name.to_lower() and is_instance_valid(runtime_spatial_animator):
				if runtime_spatial_animator.play_clip(clip, speed):
					_set_status("Reproduciendo animación 3D «%s»." % animation_name.capitalize())
				return
		if is_instance_valid(runtime_imported_3d_animation_player) and runtime_imported_3d_animation_player.has_animation(animation_name):
			if is_instance_valid(runtime_spatial_animator):
				runtime_spatial_animator.stop_animation()
			runtime_imported_3d_animation_player.play(animation_name)
			_set_status("Reproduciendo animación original «%s»." % animation_name)
			return
		if is_instance_valid(runtime_spatial_animator) and runtime_spatial_animator.play_animation(animation_name, speed, intensity):
			_set_status("Reproduciendo animación 3D «%s»." % animation_name.capitalize())



func _open_spritesheet_export_dialog() -> void:
	var clip := _active_timeline_clip()
	if clip.is_empty() or clip.get("keyframes", []).is_empty():
		_set_status("Crea un clip con fotogramas clave antes de exportar la hoja de sprites.")
		return
	if not is_instance_valid(runtime_rig) or not is_instance_valid(rig_subviewport):
		_set_status("Construye un rig 2D para generar la hoja de sprites.")
		return
	spritesheet_export_dialog.current_file = str(clip.get("name", "animacion")).validate_filename() + "_spritesheet.png"
	spritesheet_export_dialog.popup_centered(Vector2i(760, 520))

func _export_timeline_spritesheet(path: String) -> void:
	var clip := _active_timeline_clip()
	if clip.is_empty() or not is_instance_valid(runtime_rig) or not is_instance_valid(rig_subviewport):
		_set_status("No hay un clip o rig disponible para exportar.")
		return
	var frame_count := 12
	var columns := 4
	var rows := 3
	var frame_size := rig_subviewport.size
	var sheet := Image.create(frame_size.x * columns, frame_size.y * rows, true, Image.FORMAT_RGBA8)
	var previous_pose: Dictionary = rig_builder.capture_procedural_pose(runtime_rig)
	var previous_transparency := rig_subviewport.transparent_bg
	var background := rig_subviewport.find_child("ColorRect", false, false) as ColorRect
	var background_was_visible := background.visible if is_instance_valid(background) else false
	if is_instance_valid(background):
		background.visible = false
	rig_subviewport.transparent_bg = true
	rig_builder.stop_animation(runtime_rig)
	var duration := maxf(float(clip.get("duration", 1.0)), 0.05)
	for frame_index in range(frame_count):
		var sample_time := duration * float(frame_index) / float(frame_count)
		var pose: Dictionary = timeline_model.sample_pose(clip, sample_time)
		if not pose.is_empty():
			rig_builder.apply_procedural_pose(runtime_rig, pose)
		await RenderingServer.frame_post_draw
		var rendered := rig_subviewport.get_texture().get_image()
		if rendered != null and not rendered.is_empty():
			var destination := Vector2i((frame_index % columns) * frame_size.x, int(frame_index / columns) * frame_size.y)
			sheet.blit_rect(rendered, Rect2i(Vector2i.ZERO, frame_size), destination)
	if is_instance_valid(background):
		background.visible = background_was_visible
	rig_subviewport.transparent_bg = previous_transparency
	if not previous_pose.is_empty():
		rig_builder.apply_procedural_pose(runtime_rig, previous_pose)
	if sheet.save_png(path) != OK:
		_set_status("No se pudo guardar la hoja de sprites PNG.")
		return
	var metadata := {
		"format": "animation_studio_spritesheet",
		"version": 1,
		"clip_name": str(clip.get("name", "Animación")),
		"frame_count": frame_count,
		"columns": columns,
		"rows": rows,
		"frame_width": frame_size.x,
		"frame_height": frame_size.y,
		"duration_seconds": duration,
		"frames_per_second": float(frame_count) / duration,
		"alpha": true
	}
	var metadata_file := FileAccess.open(path.get_basename() + ".json", FileAccess.WRITE)
	if metadata_file != null:
		metadata_file.store_string(JSON.stringify(metadata, "\t"))
		metadata_file.close()
	_set_status("Hoja de sprites exportada: 12 fotogramas PNG (4×3) y metadatos JSON.")

func _open_package_export_dialog() -> void:
	if not is_instance_valid(package_export_dialog):
		return
	package_export_dialog.current_file = (str(generated_character.get("name", "personaje")).validate_filename() if not generated_character.is_empty() else "personaje") + "_animation_studio.json"
	package_export_dialog.popup_centered(Vector2i(760, 520))

func _open_package_import_dialog() -> void:
	if is_instance_valid(package_import_dialog):
		package_import_dialog.popup_centered(Vector2i(760, 520))

func _export_character_package_to_path(path: String) -> void:
	var character := generated_character.duplicate(true)
	if character.is_empty() and not project_data.get("characters", []).is_empty():
		character = project_data["characters"][-1].duplicate(true)
	var angles: Dictionary = rig_builder.capture_procedural_pose(runtime_rig) if is_instance_valid(runtime_rig) else {}
	var rig_type := "not_built"
	if is_instance_valid(runtime_spatial_rig):
		rig_type = str(runtime_spatial_rig.get_meta("rig_type", "3D_segmented_skeleton"))
	elif is_instance_valid(runtime_rig):
		rig_type = str(runtime_rig.get_meta("rig_type", "2D_pivot_hierarchy"))
	else:
		rig_type = str(character.get("rig", {}).get("type", "not_built"))
	var package: Dictionary = package_io.build_package(
		character, rig_type, angles,
		procedural_poses,
		project_data.get("custom_procedural_poses", []),
		project_data.get("animation_clips", []),
		imported_character_data,
		project_data.get("spatial_procedural_poses", []),
		project_data.get("spatial_animation_clips", []),
		runtime_spatial_animator.capture_pose() if is_instance_valid(runtime_spatial_animator) else {},
		imported_3d_model_path
	)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_set_status("No se pudo crear el paquete JSON en la ubicación seleccionada.")
		return
	file.store_string(package_io.encode_package(package))
	file.close()
	var embedded_assets: Dictionary = package.get("assets", {})
	var asset_status := " Recursos gráficos incrustados." if not embedded_assets.is_empty() else " Sin imágenes incrustadas; si el personaje usa texturas, copia los archivos fuente."
	_set_status("Paquete exportado: personaje, rig, poses y clips 2D/3D." + asset_status)

func _import_character_package_from_path(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_set_status("No se pudo abrir el paquete seleccionado.")
		return
	var json_text := file.get_as_text()
	file.close()
	var decoded: Dictionary = package_io.decode_package(json_text)
	if not bool(decoded.get("ok", false)):
		_set_status(str(decoded.get("error", "Paquete inválido.")))
		return
	var package: Dictionary = decoded["package"]
	generated_character = package.get("character", {}).duplicate(true)
	procedural_poses = package.get("procedural_poses", []).duplicate(true)
	project_data["custom_procedural_poses"] = package.get("custom_poses", []).duplicate(true)
	project_data["animation_clips"] = package.get("animation_clips", []).duplicate(true)
	project_data["spatial_procedural_poses"] = package.get("spatial_poses", []).duplicate(true)
	project_data["spatial_custom_poses"] = []
	for imported_pose in project_data["spatial_procedural_poses"]:
		if bool(imported_pose.get("custom", false)):
			project_data["spatial_custom_poses"].append(imported_pose.duplicate(true))
	project_data["spatial_animation_clips"] = package.get("spatial_animation_clips", []).duplicate(true)
	project_data["imported_character_package"] = {
		"rig_type": str(package.get("rig", {}).get("type", "")),
		"joint_angles_degrees": package.get("rig", {}).get("joint_angles_degrees", {}).duplicate(true)
	}
	var asset_dir := "user://imported_character_packages/" + str(Time.get_unix_time_from_system()) + "_" + str(Time.get_ticks_msec())
	imported_character_data = package_io.restore_image_assets(package, asset_dir)
	imported_3d_model_path = str(imported_character_data.get("model_path", ""))
	if not generated_character.is_empty():
		if not project_data.has("characters"):
			project_data["characters"] = []
		project_data["characters"].append(generated_character.duplicate(true))
		if is_instance_valid(character_preview):
			character_preview.character_label = str(generated_character.get("name", "Personaje"))
			character_preview.rig_data = generated_character.get("rig", {})
			character_preview.queue_redraw()
		var imported_rig_type := str(project_data["imported_character_package"].get("rig_type", ""))
		if imported_rig_type.begins_with("3D"):
			character_mode.select(2)
			if imported_rig_type.contains("quadruped"):
				spatial_rig_archetype.select(1)
			else:
				spatial_rig_archetype.select(0)
			procedural_poses = project_data["spatial_procedural_poses"].duplicate(true)
			var restored_model_loaded := false
			if imported_3d_model_path != "":
				restored_model_loaded = _load_3d_model_from_path(imported_3d_model_path, false)
			if not restored_model_loaded:
				_build_runtime_character()
			if is_instance_valid(runtime_spatial_animator):
				runtime_spatial_animator.apply_pose({"bone_rotations_degrees": package.get("rig", {}).get("bone_rotations_degrees", {})})
			if is_instance_valid(pose_controls):
				for child in pose_controls.get_children():
					child.queue_free()
				for pose in procedural_poses:
					_add_button(pose_controls, str(pose.get("name", "Pose")), _apply_generated_pose.bind(pose))
			if is_instance_valid(animation_controls):
				for child in animation_controls.get_children():
					child.queue_free()
				for clip in project_data["spatial_animation_clips"]:
					_add_button(animation_controls, str(clip.get("name", "Animación")).capitalize(), _play_rig_animation.bind(str(clip.get("name", ""))))
				_append_imported_3d_animation_buttons()
		elif is_instance_valid(rig_subviewport):
			character_mode.select(0)
			if not imported_character_data.get("parts", []).is_empty():
				_build_imported_segment_rig()
				if is_instance_valid(runtime_rig):
					rig_builder.apply_procedural_pose(runtime_rig, project_data["imported_character_package"]["joint_angles_degrees"])
			else:
				_build_runtime_character()
				if is_instance_valid(runtime_rig):
					rig_builder.apply_procedural_pose(runtime_rig, project_data["imported_character_package"]["joint_angles_degrees"])
	_refresh_timeline_ui()
	_save_project()
	var texture_message := ""
	if not imported_character_data.get("parts", []).is_empty():
		texture_message = " Las imágenes y recortes se restauraron."
	elif imported_3d_model_path != "":
		texture_message = " El modelo 3D y sus recursos se restauraron."
	else:
		texture_message = " Este paquete no contiene recursos gráficos incrustados."
	_set_status("Paquete importado: ficha, poses y clips recuperados." + texture_message)

func _save_project() -> void:
	var target := current_project_path if not current_project_path.is_empty() else "user://animation_studio_manager_project.amsproj"
	var result: Dictionary = project_io.save_project(target, project_data)
	if not bool(result.get("ok", false)):
		_set_status(str(result.get("error", "No se pudo guardar el proyecto.")))
		return
	project_data = result.get("project", project_data)
	_set_status("Proyecto guardado: " + target)

func _open_save_project_dialog() -> void:
	if is_instance_valid(project_save_dialog):
		project_save_dialog.current_file = str(project_data.get("name", "mi_proyecto")).validate_filename() + ".amsproj"
		project_save_dialog.popup_centered_ratio(0.82)

func _open_project_dialog() -> void:
	if is_instance_valid(project_open_dialog):
		project_open_dialog.popup_centered_ratio(0.82)

func _save_project_to_path(path: String) -> void:
	var result: Dictionary = project_io.save_project(path, project_data)
	if not bool(result.get("ok", false)):
		_set_status(str(result.get("error", "No se pudo guardar el proyecto.")))
		return
	current_project_path = path
	project_data = result.get("project", project_data)
	_set_status("Proyecto portable guardado: " + path)

func _load_project_from_path(path: String) -> void:
	var result: Dictionary = project_io.load_project(path)
	if not bool(result.get("ok", false)):
		_set_status(str(result.get("error", "No se pudo abrir el proyecto.")))
		return
	project_data = result.get("project", {}).duplicate(true)
	current_project_path = path
	_show_workspace()
	_set_status("Proyecto abierto: %s · %d escenas." % [str(project_data.get("name", "Proyecto")), project_data.get("scenes", []).size()])



func _export_project_bundle(path: String) -> void:
	var result=project_bundle_io.export_bundle(path,project_data)
	if not result.ok:
		_set_status(str(result.error))
		return
	_set_status("Proyecto portable exportado · %d recursos · %.1f MB." % [int(result.asset_count),float(result.bytes)/1048576.0])

func _import_project_bundle(path: String) -> void:
	var destination="user://restored_projects/"+str(Time.get_unix_time_from_system())
	var result=project_bundle_io.import_bundle(path,destination)
	if not result.ok:
		_set_status(str(result.error))
		return
	var validation=project_io.validate_project(result.project)
	if not validation.ok:
		_set_status("El paquete se abrió, pero el documento no pasó validación: "+str(validation.error))
		return
	project_data=project_io.normalize_project(result.project)
	current_project_path=""
	_show_workspace()
	_save_project()
	_set_status("Proyecto portable importado · %d recursos restaurados." % int(result.asset_count))

func _video_timeline() -> Dictionary:
	if not project_data.has("video_timeline") or not project_data["video_timeline"] is Dictionary:
		project_data["video_timeline"] = VIDEO_TIMELINE.new().create_timeline(int(project_data.get("fps", 30)))
	return project_data["video_timeline"]

func _show_video_editor() -> void:
	_clear_content()
	video_timeline_model = VIDEO_TIMELINE.new()
	var page := VBoxContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("separation", 8)
	content.add_child(page)
	_add_heading(page, "Editor de vídeo · Montaje multipista", "Organiza vídeo, audio, títulos, superposiciones y efectos en una línea de tiempo común.")
	var toolbar := HBoxContainer.new()
	page.add_child(toolbar)
	_add_button(toolbar, "+ Vídeo", _video_add_track.bind("video"))
	_add_button(toolbar, "+ Audio", _video_add_track.bind("audio"))
	_add_button(toolbar, "+ Títulos", _video_add_track.bind("title"))
	_add_button(toolbar, "+ Superposición", _video_add_track.bind("overlay"))
	_add_button(toolbar, "+ Efectos", _video_add_track.bind("effect"))
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(columns)
	var track_panel := VBoxContainer.new()
	track_panel.custom_minimum_size.x = 240
	columns.add_child(track_panel)
	var track_heading := Label.new()
	track_heading.text = "PISTAS"
	track_panel.add_child(track_heading)
	video_track_list = ItemList.new()
	video_track_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	video_track_list.item_selected.connect(_video_select_track)
	track_panel.add_child(video_track_list)
	var clip_panel := VBoxContainer.new()
	clip_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(clip_panel)
	var clip_heading := Label.new()
	clip_heading.text = "CLIPS DE LA PISTA"
	clip_panel.add_child(clip_heading)
	video_clip_list = ItemList.new()
	video_clip_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	video_clip_list.item_selected.connect(_video_select_clip)
	clip_panel.add_child(video_clip_list)
	var edit_row := HBoxContainer.new()
	page.add_child(edit_row)
	video_playhead = SpinBox.new()
	video_playhead.min_value = 0.0
	video_playhead.max_value = 86400.0
	video_playhead.step = 0.01
	video_playhead.suffix = " s · cabezal"
	edit_row.add_child(video_playhead)
	video_clip_start = SpinBox.new()
	video_clip_start.min_value = 0.0
	video_clip_start.max_value = 86400.0
	video_clip_start.step = 0.01
	video_clip_start.prefix = "Inicio "
	edit_row.add_child(video_clip_start)
	video_clip_end = SpinBox.new()
	video_clip_end.min_value = 0.04
	video_clip_end.max_value = 86400.0
	video_clip_end.step = 0.01
	video_clip_end.prefix = "Fin "
	edit_row.add_child(video_clip_end)
	var actions := HBoxContainer.new()
	page.add_child(actions)
	_add_button(actions, "Importar medio a pista", _video_open_media_dialog)
	_add_button(actions, "Mover al cabezal", _video_move_clip)
	_add_button(actions, "Recortar", _video_trim_clip)
	_add_button(actions, "Dividir en cabezal", _video_split_clip)
	_add_button(actions, "Duplicar", _video_duplicate_clip)
	_add_button(actions, "Eliminar clip", _video_remove_clip)
	var footer := HBoxContainer.new()
	page.add_child(footer)
	_add_button(footer, "Guardar montaje", _save_project)
	_add_button(footer, "Volver al estudio", _show_workspace)
	video_media_dialog = FileDialog.new()
	video_media_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	video_media_dialog.access = FileDialog.ACCESS_FILESYSTEM
	video_media_dialog.filters = PackedStringArray(["*.mp4, *.mov, *.mkv, *.webm, *.avi ; Vídeo", "*.wav, *.mp3, *.ogg, *.flac, *.m4a ; Audio", "*.png, *.jpg, *.jpeg, *.webp ; Imagen"])
	video_media_dialog.file_selected.connect(_video_media_selected)
	add_child(video_media_dialog)
	_video_refresh_tracks()
	if _video_timeline().get("tracks", []).is_empty():
		_video_add_track("video")
		_video_add_track("audio")
	_set_status("Editor multipista listo. El montaje se guarda dentro del proyecto.")

func _video_add_track(track_type: String) -> void:
	var result: Dictionary = video_timeline_model.create_track(_video_timeline(), track_type)
	if not result.get("ok", false):
		_set_status(str(result.get("error", "No se pudo crear la pista.")))
		return
	video_selected_track = _video_timeline().tracks.size() - 1
	_video_refresh_tracks()
	_save_project()

func _video_refresh_tracks() -> void:
	if not is_instance_valid(video_track_list):
		return
	video_track_list.clear()
	var tracks: Array = _video_timeline().get("tracks", [])
	for track in tracks:
		video_track_list.add_item("%s · %s · %d clips" % [str(track.get("type", "")).to_upper(), str(track.get("name", "Pista")), track.get("clips", []).size()])
	if not tracks.is_empty():
		video_selected_track = clampi(video_selected_track, 0, tracks.size() - 1)
		video_track_list.select(video_selected_track)
		_video_refresh_clips()
	else:
		video_clip_list.clear()

func _video_select_track(index: int) -> void:
	video_selected_track = index
	video_selected_clip = -1
	_video_refresh_clips()

func _video_refresh_clips() -> void:
	if not is_instance_valid(video_clip_list):
		return
	video_clip_list.clear()
	var tracks: Array = _video_timeline().get("tracks", [])
	if video_selected_track < 0 or video_selected_track >= tracks.size():
		return
	for clip in tracks[video_selected_track].get("clips", []):
		video_clip_list.add_item("%s · %.2f → %.2f s" % [str(clip.get("name", "Clip")), float(clip.get("start", 0.0)), float(clip.get("start", 0.0)) + float(clip.get("duration", 0.0))])

func _video_select_clip(index: int) -> void:
	video_selected_clip = index
	var track: Dictionary = _video_selected_track_data()
	var clips: Array = track.get("clips", [])
	if index < 0 or index >= clips.size():
		return
	var clip: Dictionary = clips[index]
	video_clip_start.value = float(clip.get("start", 0.0))
	video_clip_end.value = float(clip.get("start", 0.0)) + float(clip.get("duration", 0.0))
	video_playhead.value = float(clip.get("start", 0.0))

func _video_selected_track_data() -> Dictionary:
	var tracks: Array = _video_timeline().get("tracks", [])
	if video_selected_track < 0 or video_selected_track >= tracks.size():
		return {}
	return tracks[video_selected_track]

func _video_open_media_dialog() -> void:
	if _video_selected_track_data().is_empty():
		_set_status("Crea o selecciona una pista antes de importar medios.")
		return
	video_media_dialog.popup_centered_ratio(0.82)

func _video_media_selected(path: String) -> void:
	var track := _video_selected_track_data()
	if track.is_empty():
		return
	var result: Dictionary = video_timeline_model.add_clip(track, path, video_playhead.value, 5.0)
	if not result.get("ok", false):
		_set_status(str(result.get("error", "No se pudo añadir el medio.")))
		return
	_video_refresh_tracks()
	_save_project()
	_set_status("Medio añadido al montaje. Ajusta su duración y posición en la pista.")

func _video_move_clip() -> void:
	var track := _video_selected_track_data()
	var clips: Array = track.get("clips", [])
	if video_selected_clip < 0 or video_selected_clip >= clips.size():
		return
	var result: Dictionary = video_timeline_model.move_clip(track, str(clips[video_selected_clip].id), video_clip_start.value)
	if result.get("ok", false):
		_video_refresh_tracks()
		_save_project()

func _video_trim_clip() -> void:
	var track := _video_selected_track_data()
	var clips: Array = track.get("clips", [])
	if video_selected_clip < 0 or video_selected_clip >= clips.size():
		return
	var clip_id := str(clips[video_selected_clip].id)
	var result: Dictionary = video_timeline_model.trim_clip(track, clip_id, video_clip_start.value, video_clip_end.value)
	if result.get("ok", false):
		_video_refresh_tracks()
		_save_project()
	else:
		_set_status(str(result.get("error", "No se pudo recortar el clip.")))

func _video_split_clip() -> void:
	var track := _video_selected_track_data()
	var clips: Array = track.get("clips", [])
	if video_selected_clip < 0 or video_selected_clip >= clips.size():
		return
	var result: Dictionary = video_timeline_model.split_clip(track, str(clips[video_selected_clip].id), video_playhead.value)
	if result.get("ok", false):
		_video_refresh_tracks()
		_save_project()
	else:
		_set_status(str(result.get("error", "No se pudo dividir el clip.")))

func _video_duplicate_clip() -> void:
	var track := _video_selected_track_data()
	var clips: Array = track.get("clips", [])
	if video_selected_clip < 0 or video_selected_clip >= clips.size():
		return
	var result: Dictionary = video_timeline_model.duplicate_clip(track, str(clips[video_selected_clip].id))
	if result.get("ok", false):
		_video_refresh_tracks()
		_save_project()

func _video_remove_clip() -> void:
	var track := _video_selected_track_data()
	var clips: Array = track.get("clips", [])
	if video_selected_clip < 0 or video_selected_clip >= clips.size():
		return
	if video_timeline_model.remove_clip(track, str(clips[video_selected_clip].id)):
		video_selected_clip = -1
		_video_refresh_tracks()
		_save_project()

func _show_export_workspace() -> void:
	_clear_content()
	var page=VBoxContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("separation",10)
	content.add_child(page)
	_add_heading(page,"Exportación y control de calidad","Empaqueta todo el proyecto con sus recursos y revisa sus presupuestos antes de distribuirlo.")
	_add_button(page,"Exportar proyecto completo (.asbundle)",func(): project_bundle_export_dialog.current_file=str(project_data.get("name","proyecto")).validate_filename()+".asbundle"; project_bundle_export_dialog.popup_centered_ratio(0.82))
	_add_button(page,"Importar proyecto portable (.asbundle)",func(): project_bundle_import_dialog.popup_centered_ratio(0.82))
	_add_button(page,"Generar auditoría de rendimiento",_export_performance_audit)
	_add_button(page,"Guardar proyecto editable (.amsproj)",_open_save_project_dialog)
	_add_button(page,"Exportar paquete del personaje (.json)",_open_package_export_dialog)
	_add_button(page,"Volver al escenario",_show_workspace)

func _export_performance_audit() -> void:
	var report=performance_auditor.audit_project(project_data)
	var path="user://performance_audit_"+str(Time.get_unix_time_from_system())+".json"
	var file=FileAccess.open(path,FileAccess.WRITE)
	if file==null:
		_set_status("No se pudo escribir el informe de rendimiento.")
		return
	file.store_string(JSON.stringify(report,"\\t"))
	file.close()
	_set_status("Auditoría guardada: %s · %d escenas · %d objetos · %d recursos · %d advertencias." % [path,int(report.summary.scene_count),int(report.summary.object_count),int(report.summary.resource_count),report.warnings.size()])

func _ensure_environment() -> void:
	if active_environment.is_empty():
		var environments: Array=project_data.get("environments",[])
		active_environment=environments[0].duplicate(true) if not environments.is_empty() else environment_director.create_environment()
		if environments.is_empty(): project_data["environments"]=[active_environment.duplicate(true)]

func _show_environment_studio() -> void:
	_ensure_environment()
	_clear_content()
	var page=VBoxContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("separation",8)
	content.add_child(page)
	_add_heading(page,"Escenarios · iluminación, tiempo y clima","Configura la atmósfera y capas de fondo del proyecto.")
	var presets=HBoxContainer.new()
	page.add_child(presets)
	for preset in ["dawn","morning","noon","afternoon","sunset","night"]:
		_add_button(presets,{"dawn":"Amanecer","morning":"Mañana","noon":"Mediodía","afternoon":"Tarde","sunset":"Atardecer","night":"Noche"}[preset],_apply_environment_preset.bind(preset))
	var hour=HSlider.new()
	hour.min_value=0
	hour.max_value=23.99
	hour.step=0.25
	hour.value=float(active_environment.get("hour",12.0))
	_labeled_control(page,"Hora del día",hour)
	hour.value_changed.connect(func(v): active_environment["hour"]=v; active_environment["sun_energy"]=clampf(1.0-absf(v-12.0)/15.0,0.12,1.15); _save_environment())
	var weather=OptionButton.new()
	var weather_names=["clear","rain","snow","wind","fog","dust"]
	for w in weather_names: weather.add_item({"clear":"Despejado","rain":"Lluvia","snow":"Nieve","wind":"Viento","fog":"Niebla","dust":"Polvo"}[w])
	weather.select(maxi(0,weather_names.find(str(active_environment.get("weather","clear")))))
	_labeled_control(page,"Clima",weather)
	var intensity=HSlider.new()
	intensity.min_value=0
	intensity.max_value=1
	intensity.step=0.01
	intensity.value=float(active_environment.get("weather_intensity",0.0))
	_labeled_control(page,"Intensidad",intensity)
	_add_button(page,"Aplicar clima",func(): environment_director.set_weather(active_environment,weather_names[weather.selected],intensity.value); _save_environment(); _set_status("Perfil de clima aplicado: "+weather_names[weather.selected]))
	_add_button(page,"Añadir keyframe ambiental",func(): var result=environment_director.add_keyframe(active_environment,float(active_environment.hour)*60.0,{"sun_energy":float(active_environment.get("sun_energy",1.0)),"weather_intensity":float(active_environment.get("weather_intensity",0.0))}); _save_environment(); _set_status("Keyframe guardado." if result.ok else str(result.error)))
	_add_button(page,"Añadir capa parallax del fondo seleccionado",func(): var result=environment_director.add_background_layer(active_environment,selected_resource_id,float(active_environment.background_layers.size()),0.35); _save_environment(); _set_status("Capa añadida." if result.ok else str(result.error)))
	_add_button(page,"Guardar ambiente",_save_environment)
	var summary=Label.new()
	summary.text="Capas: %d · Luz solar: %.2f · Ambiente: %.2f" % [active_environment.background_layers.size(),float(active_environment.get("sun_energy",1.0)),float(active_environment.get("ambient_energy",1.0))]
	page.add_child(summary)
	_add_button(page,"Volver",_show_workspace)

func _labeled_control(parent: Node, label_text: String, control: Control) -> HBoxContainer:
	var row=HBoxContainer.new()
	var label=Label.new()
	label.text=label_text
	label.custom_minimum_size.x=150
	row.add_child(label)
	control.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(control)
	parent.add_child(row)
	return row

func _apply_environment_preset(preset: String) -> void:
	var result=environment_director.set_time_preset(active_environment,preset)
	if result.ok:
		_save_environment()
		_set_status("Preset horario aplicado: " + preset)

func _save_environment() -> void:
	var result=environment_director.validate_environment(active_environment)
	if not result.ok:
		_set_status(str(result.error))
		return
	project_data["environments"]=[active_environment.duplicate(true)]
	_save_project()

func _ensure_dialogue_script() -> void:
	if active_script.is_empty():
		var scripts: Array=project_data.get("dialogue_scripts",[])
		active_script=scripts[0].duplicate(true) if not scripts.is_empty() else dialogue_studio.create_script()
		if scripts.is_empty(): project_data["dialogue_scripts"]=[active_script.duplicate(true)]

func _show_dialogue_studio() -> void:
	_ensure_dialogue_script()
	_clear_content()
	var scroll=ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(scroll)
	var page=VBoxContainer.new()
	page.custom_minimum_size.x=620
	page.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation",8)
	scroll.add_child(page)
	_add_heading(page,"Guion, diálogos y doblaje","Crea líneas de diálogo y subtítulos sincronizados; registra tomas de voz importadas.")
	var speaker=LineEdit.new()
	speaker.placeholder_text="Personaje / locutor"
	page.add_child(speaker)
	var line_text=TextEdit.new()
	line_text.placeholder_text="Texto del diálogo"
	line_text.custom_minimum_size.y=90
	page.add_child(line_text)
	var times=HBoxContainer.new()
	page.add_child(times)
	var start=SpinBox.new()
	start.min_value=0
	start.max_value=36000
	start.step=0.1
	start.prefix="Inicio "
	times.add_child(start)
	var finish=SpinBox.new()
	finish.min_value=0.1
	finish.max_value=36000
	finish.step=0.1
	finish.value=2.5
	finish.prefix="Fin "
	times.add_child(finish)
	_add_button(page, "Añadir diálogo / subtítulo", func():
		var result: Dictionary = dialogue_studio.add_line(active_script, speaker.text, line_text.text, start.value, finish.value)
		if result.ok:
			line_text.clear()
			_refresh_dialogue_lines()
			_save_dialogue_script()
		else:
			_set_status(str(result.error))
	)
	dialogue_line_list=ItemList.new()
	dialogue_line_list.custom_minimum_size.y=180
	page.add_child(dialogue_line_list)
	_refresh_dialogue_lines()
	_add_button(page,"Registrar toma de audio importada",_register_dialogue_take)
	_add_button(page,"Validar y guardar guion",_save_dialogue_script)
	var note=Label.new()
	note.text="La captura directa del micrófono, cuenta regresiva y monitorización aún requieren integración y pruebas específicas en Android y Windows."
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	page.add_child(note)
	_add_button(page,"Volver",_show_workspace)

func _refresh_dialogue_lines() -> void:
	if not is_instance_valid(dialogue_line_list): return
	dialogue_line_list.clear()
	for line in active_script.get("lines",[]): dialogue_line_list.add_item("[%0.2f–%0.2f] %s: %s" % [float(line.start),float(line.end),str(line.speaker),str(line.text)])

func _register_dialogue_take() -> void:
	if active_script.get("lines", []).is_empty():
		_set_status("Añade primero un diálogo.")
		return
	var dialog=FileDialog.new()
	dialog.file_mode=FileDialog.FILE_MODE_OPEN_FILE
	dialog.access=FileDialog.ACCESS_FILESYSTEM
	dialog.filters=PackedStringArray(["*.wav, *.ogg, *.mp3 ; Audio"])
	dialog.file_selected.connect(func(path: String):
		var duration=1.0
		if path.get_extension().to_lower()=="wav":
			duration = _wav_duration_from_file(path)
		var line_id=str(active_script.lines[-1].id)
		var result=dialogue_studio.add_take(active_script,line_id,path,duration,active_script.audio_tracks.size()+1,"Toma importada")
		_save_dialogue_script()
		_set_status("Toma registrada." if result.ok else str(result.error))
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.8)


func _wav_duration_from_file(path: String) -> float:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() < 44:
		if file != null:
			file.close()
		return 1.0
	if file.get_buffer(4).get_string_from_ascii() != "RIFF":
		file.close()
		return 1.0
	file.get_32()
	if file.get_buffer(4).get_string_from_ascii() != "WAVE":
		file.close()
		return 1.0
	var byte_rate := 0
	var data_size := 0
	while file.get_position() + 8 <= file.get_length():
		var chunk_id := file.get_buffer(4).get_string_from_ascii()
		var chunk_size: int = file.get_32()
		var remaining := file.get_length() - file.get_position()
		if chunk_size < 0 or chunk_size > remaining:
			break
		if chunk_id == "fmt ":
			if chunk_size < 12:
				break
			var format_header := file.get_buffer(12)
			if format_header.size() != 12:
				break
			byte_rate = int(format_header.decode_u32(8))
			var extra_size := chunk_size - 12
			if extra_size > 0:
				file.seek(file.get_position() + extra_size)
		elif chunk_id == "data":
			data_size = chunk_size
			break
		else:
			file.seek(file.get_position() + chunk_size)
		if chunk_size % 2 == 1 and file.get_position() < file.get_length():
			file.seek(file.get_position() + 1)
	file.close()
	if byte_rate <= 0 or data_size <= 0:
		return 1.0
	return float(data_size) / float(byte_rate)

func _save_dialogue_script() -> void:
	var result=dialogue_studio.validate_script(active_script)
	if not result.ok:
		_set_status(str(result.error))
		return
	project_data["dialogue_scripts"]=[active_script.duplicate(true)]
	_save_project()
	_set_status("Guion guardado · %d líneas · %.2f s." % [result.line_count,result.duration])

func _set_status(message: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = message
