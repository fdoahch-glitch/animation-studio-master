extends Control
class_name SceneCanvas

signal selection_changed(instance_id: String)
signal composition_changed
signal asset_dropped(resource_type: String, scene_position: Vector2)

var scene_data: Dictionary = {}
var scene_width := 1920.0
var scene_height := 1080.0
var selected_id := ""
var zoom := 1.0
var pan := Vector2.ZERO
var dragging := false
var panning := false
var drag_origin := Vector2.ZERO
var drag_object_origin := Vector2.ZERO
var pan_origin := Vector2.ZERO
var grid_enabled := true
var interaction_enabled := true
var resource_textures: Dictionary = {}

func set_scene_data(value: Dictionary, width: float, height: float) -> void:
	scene_data = value
	scene_width = maxf(width, 1.0)
	scene_height = maxf(height, 1.0)
	queue_redraw()

func set_selected(instance_id: String) -> void:
	selected_id = instance_id
	queue_redraw()

func set_resource_catalog(resources: Array) -> void:
	var active_ids: Dictionary = {}
	for resource in resources:
		if not resource is Dictionary or str(resource.get("mime_group","")) != "image":
			continue
		var resource_id := str(resource.get("id",""))
		var path := str(resource.get("path",""))
		if resource_id.is_empty() or path.is_empty():
			continue
		active_ids[resource_id] = true
		if resource_textures.has(resource_id) or not FileAccess.file_exists(path):
			continue
		var source := Image.new()
		if source.load(path) == OK and not source.is_empty():
			resource_textures[resource_id] = ImageTexture.create_from_image(source)
	for cached_id in resource_textures.keys():
		if not active_ids.has(cached_id):
			resource_textures.erase(cached_id)
	queue_redraw()

func _canvas_scale() -> float:
	return minf(size.x / scene_width, size.y / scene_height) * zoom

func _canvas_rect() -> Rect2:
	var scale_value := _canvas_scale()
	var extent := Vector2(scene_width, scene_height) * scale_value
	return Rect2((size - extent) * 0.5 + pan, extent)

func _scene_to_screen(point: Vector2) -> Vector2:
	var rect := _canvas_rect()
	return rect.position + point * _canvas_scale()

func _screen_to_scene(point: Vector2) -> Vector2:
	return (point - _canvas_rect().position) / maxf(_canvas_scale(), 0.0001)

func _zoom_at(screen_point: Vector2, factor: float) -> void:
	var scene_point := _screen_to_scene(screen_point)
	zoom = clampf(zoom * factor, 0.2, 4.0)
	var extent := Vector2(scene_width, scene_height) * _canvas_scale()
	pan = screen_point - (size - extent) * 0.5 - scene_point * _canvas_scale()
	queue_redraw()

func _object_size(item: Dictionary) -> Vector2:
	var kind := str(item.get("type", "element"))
	match kind:
		"background": return Vector2(scene_width, scene_height)
		"character": return Vector2(150, 260)
		"decoration": return Vector2(110, 90)
		_: return Vector2(130, 110)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#172536"), true)
	var frame := _canvas_rect()
	draw_rect(frame.grow(2), Color("#07111c"), true)
	draw_rect(frame, Color("#f4f7fb"), true)
	if grid_enabled and _canvas_scale() > 0.12:
		var step := 100.0 * _canvas_scale()
		var x := fposmod(frame.position.x, step)
		while x < frame.end.x:
			draw_line(Vector2(x, frame.position.y), Vector2(x, frame.end.y), Color(0.35,0.43,0.52,0.13), 1.0)
			x += step
		var y := fposmod(frame.position.y, step)
		while y < frame.end.y:
			draw_line(Vector2(frame.position.x, y), Vector2(frame.end.x, y), Color(0.35,0.43,0.52,0.13), 1.0)
			y += step
	var objects: Array = scene_data.get("objects", []).duplicate(true)
	objects.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_depth := float(a.get("transform", {}).get("depth", 0.0))
		var b_depth := float(b.get("transform", {}).get("depth", 0.0))
		if str(a.get("type", "")) == "background": a_depth -= 100000.0
		if str(b.get("type", "")) == "background": b_depth -= 100000.0
		return a_depth < b_depth
	)
	for item in objects:
		if not bool(item.get("transform", {}).get("visible", true)):
			continue
		var transform: Dictionary = item.get("transform", {})
		var center := _scene_to_screen(Vector2(float(transform.get("x", scene_width * 0.5)), float(transform.get("y", scene_height * 0.5))))
		var base_size := _object_size(item)
		var scale_value := _canvas_scale()
		var extent := base_size * Vector2(float(transform.get("scale_x",1.0)), float(transform.get("scale_y",1.0))) * scale_value
		var rect := Rect2(center - extent * 0.5, extent)
		var kind := str(item.get("type", "element"))
		var resource_id := str(item.get("resource_id",""))
		var texture: Texture2D = resource_textures.get(resource_id)
		var fill := Color("#e5a33d")
		match kind:
			"background": fill = Color("#9bc7df")
			"character": fill = Color("#46a6a0")
			"decoration": fill = Color("#6ca66b")
			"element": fill = Color("#d59b58")
		draw_set_transform(center, deg_to_rad(float(transform.get("rotation",0.0))), Vector2.ONE)
		var local_rect := Rect2(-extent * 0.5, extent)
		if is_instance_valid(texture):
			draw_texture_rect(texture, local_rect, false)
		else:
			match kind:
				"background":
					draw_rect(local_rect, fill, true)
					draw_line(Vector2(-extent.x * 0.5, extent.y * 0.18), Vector2(extent.x * 0.5, extent.y * 0.18), Color("#5b927b"), maxf(2.0, 3.0 * scale_value))
					draw_circle(Vector2(extent.x * 0.31, -extent.y * 0.28), extent.y * 0.07, Color("#f6d879"))
				"character":
					draw_line(Vector2(0, -extent.y * 0.08), Vector2(-extent.x * 0.18, extent.y * 0.30), Color("#263c54"), maxf(5.0, extent.x * 0.07))
					draw_line(Vector2(0, -extent.y * 0.08), Vector2(extent.x * 0.18, extent.y * 0.30), Color("#263c54"), maxf(5.0, extent.x * 0.07))
					draw_line(Vector2(-extent.x * 0.12, -extent.y * 0.17), Vector2(-extent.x * 0.34, extent.y * 0.05), fill.lightened(0.15), maxf(4.0, extent.x * 0.055))
					draw_line(Vector2(extent.x * 0.12, -extent.y * 0.17), Vector2(extent.x * 0.34, extent.y * 0.05), fill.lightened(0.15), maxf(4.0, extent.x * 0.055))
					draw_rect(Rect2(-extent.x * 0.18, -extent.y * 0.22, extent.x * 0.36, extent.y * 0.43), fill, true)
					draw_circle(Vector2(0, -extent.y * 0.34), extent.x * 0.19, Color("#e8b48b"))
					draw_circle(Vector2(-extent.x * 0.06, -extent.y * 0.36), maxf(2.0, extent.x * 0.025), Color("#26384a"))
					draw_circle(Vector2(extent.x * 0.06, -extent.y * 0.36), maxf(2.0, extent.x * 0.025), Color("#26384a"))
				"decoration":
					draw_rect(Rect2(-extent.x * 0.07, extent.y * 0.03, extent.x * 0.14, extent.y * 0.43), Color("#795438"), true)
					draw_circle(Vector2(0, -extent.y * 0.12), extent.x * 0.32, fill)
					draw_circle(Vector2(-extent.x * 0.18, -extent.y * 0.02), extent.x * 0.22, fill.lightened(0.12))
					draw_circle(Vector2(extent.x * 0.18, -extent.y * 0.02), extent.x * 0.22, fill.lightened(0.08))
				_:
					draw_rect(local_rect, fill, true)
					draw_rect(local_rect.grow(-extent.x * 0.12), fill.lightened(0.2), false, maxf(1.0, 2.0 * scale_value))
					draw_circle(Vector2.ZERO, minf(extent.x, extent.y) * 0.12, Color("#fff1c7"))
		draw_rect(local_rect, Color("#23384d"), false, 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var label := str(item.get("name", kind))
		draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, rect.position.y - 7), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#1d3044"))
		if str(item.get("id","")) == selected_id:
			draw_rect(rect.grow(5), Color("#1688ff"), false, 2.0)
			for corner in [rect.position, Vector2(rect.end.x,rect.position.y), rect.end, Vector2(rect.position.x,rect.end.y)]:
				draw_circle(corner, 4.0, Color.WHITE)
				draw_arc(corner, 4.0, 0.0, TAU, 16, Color("#1688ff"), 1.5)
	draw_rect(frame, Color("#24384b"), false, 2.0)

func _hit_test(screen_point: Vector2) -> String:
	var objects: Array = scene_data.get("objects", []).duplicate(true)
	objects.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_depth := float(a.get("transform", {}).get("depth", 0.0))
		var b_depth := float(b.get("transform", {}).get("depth", 0.0))
		if str(a.get("type", "")) == "background": a_depth -= 100000.0
		if str(b.get("type", "")) == "background": b_depth -= 100000.0
		return a_depth < b_depth
	)
	for i in range(objects.size() - 1, -1, -1):
		var item: Dictionary = objects[i]
		if not bool(item.get("transform", {}).get("visible", true)):
			continue
		var t: Dictionary = item.get("transform", {})
		var center := _scene_to_screen(Vector2(float(t.get("x", scene_width * 0.5)), float(t.get("y", scene_height * 0.5))))
		var extent := _object_size(item) * Vector2(float(t.get("scale_x", 1.0)), float(t.get("scale_y", 1.0))) * _canvas_scale()
		var local_point := (screen_point - center).rotated(-deg_to_rad(float(t.get("rotation", 0.0))))
		if Rect2(-extent * 0.5, extent).has_point(local_point):
			return str(item.get("id", ""))
	return ""

func _gui_input(event: InputEvent) -> void:
	if not interaction_enabled:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_at(event.position, 1.12)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_at(event.position, 1.0 / 1.12)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			panning = event.pressed
			pan_origin = event.position - pan
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var hit := _hit_test(event.position)
				selected_id = hit
				selection_changed.emit(selected_id)
				if hit != "":
					dragging = true
					drag_origin = _screen_to_scene(event.position)
					for item in scene_data.get("objects", []):
						if str(item.get("id","")) == hit:
							var t: Dictionary = item.get("transform",{})
							drag_object_origin = Vector2(float(t.get("x",0.0)),float(t.get("y",0.0)))
							break
				queue_redraw()
			else:
				if dragging:
					dragging = false
					composition_changed.emit()
				accept_event()
	elif event is InputEventMouseMotion:
		if panning:
			pan = event.position - pan_origin
			queue_redraw()
		elif dragging and selected_id != "":
			var point := _screen_to_scene(event.position)
			for item in scene_data.get("objects", []):
				if str(item.get("id","")) == selected_id:
					item["transform"]["x"] = drag_object_origin.x + point.x - drag_origin.x
					item["transform"]["y"] = drag_object_origin.y + point.y - drag_origin.y
					break
			queue_redraw()
	elif event is InputEventScreenTouch:
		if event.pressed:
			var hit := _hit_test(event.position)
			selected_id = hit
			selection_changed.emit(selected_id)
			if hit != "":
				dragging = true
				drag_origin = _screen_to_scene(event.position)
				for item in scene_data.get("objects", []):
					if str(item.get("id","")) == hit:
						drag_object_origin = Vector2(float(item["transform"].get("x",0.0)),float(item["transform"].get("y",0.0)))
						break
		else:
			if dragging:
				dragging = false
				composition_changed.emit()
		queue_redraw()
	elif event is InputEventScreenDrag and dragging:
		var point := _screen_to_scene(event.position)
		for item in scene_data.get("objects", []):
			if str(item.get("id","")) == selected_id:
				item["transform"]["x"] = drag_object_origin.x + point.x - drag_origin.x
				item["transform"]["y"] = drag_object_origin.y + point.y - drag_origin.y
				break
		queue_redraw()

func reset_view() -> void:
	zoom = 1.0
	pan = Vector2.ZERO
	queue_redraw()

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and ["character", "background", "element", "decoration"].has(str(data.get("scene_asset_type", "")))

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(at_position, data):
		return
	asset_dropped.emit(str(data.get("scene_asset_type", "")), _screen_to_scene(at_position))
