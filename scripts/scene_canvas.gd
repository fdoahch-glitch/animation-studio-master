extends Control
class_name SceneCanvas

signal selection_changed(instance_id: String)
signal composition_changed

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

func set_scene_data(value: Dictionary, width: float, height: float) -> void:
	scene_data = value
	scene_width = maxf(width, 1.0)
	scene_height = maxf(height, 1.0)
	queue_redraw()

func set_selected(instance_id: String) -> void:
	selected_id = instance_id
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
	var objects: Array = scene_data.get("objects", [])
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
		var fill := Color("#e5a33d")
		match kind:
			"background": fill = Color("#9bc7df")
			"character": fill = Color("#46a6a0")
			"decoration": fill = Color("#6ca66b")
			"element": fill = Color("#d59b58")
		draw_set_transform(center, deg_to_rad(float(transform.get("rotation",0.0))), Vector2.ONE)
		draw_rect(Rect2(-extent * 0.5, extent), fill, true)
		draw_rect(Rect2(-extent * 0.5, extent), Color("#23384d"), false, 2.0)
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
	var objects: Array = scene_data.get("objects", [])
	for i in range(objects.size()-1, -1, -1):
		var item: Dictionary = objects[i]
		if not bool(item.get("transform", {}).get("visible", true)):
			continue
		var t: Dictionary = item.get("transform", {})
		var center := _scene_to_screen(Vector2(float(t.get("x",scene_width*0.5)),float(t.get("y",scene_height*0.5))))
		var extent := _object_size(item) * Vector2(float(t.get("scale_x",1.0)),float(t.get("scale_y",1.0))) * _canvas_scale()
		if Rect2(center-extent*0.5,extent).has_point(screen_point):
			return str(item.get("id",""))
	return ""

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom = clampf(zoom * 1.12, 0.2, 4.0)
			queue_redraw()
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom = clampf(zoom / 1.12, 0.2, 4.0)
			queue_redraw()
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
			composition_changed.emit()
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
		composition_changed.emit()

func reset_view() -> void:
	zoom = 1.0
	pan = Vector2.ZERO
	queue_redraw()
