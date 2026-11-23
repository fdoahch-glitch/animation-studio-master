extends SceneTree

const CANVAS = preload("res://scripts/scene_canvas.gd")

func _initialize() -> void:
	var canvas = CANVAS.new()
	canvas.size = Vector2(800, 600)
	var scene := {
		"id": "scene_canvas_test",
		"objects": [
			{"id":"bg","type":"background","name":"Fondo","transform":{"x":960.0,"y":540.0,"scale_x":1.0,"scale_y":1.0,"rotation":0.0,"depth":0.0,"visible":true}},
			{"id":"actor","type":"character","name":"Actor","transform":{"x":960.0,"y":540.0,"scale_x":1.0,"scale_y":1.0,"rotation":0.0,"depth":1.0,"visible":true}}
		]
	}
	canvas.set_scene_data(scene, 1920.0, 1080.0)
	assert(is_equal_approx(canvas._canvas_scale(), 800.0 / 1920.0), "Debe ajustar el lienzo al contenedor")
	var center := canvas._scene_to_screen(Vector2(960.0,540.0))
	var restored := canvas._screen_to_scene(center)
	assert(restored.distance_to(Vector2(960.0,540.0)) < 0.01, "Debe convertir coordenadas sin pérdida")
	canvas._zoom_at(Vector2(400, 300), 1.5)
	assert(is_equal_approx(canvas._canvas_scale(), 1.5 * 800.0 / 1920.0), "Debe aplicar zoom")
	assert(canvas._screen_to_scene(Vector2(400, 300)).distance_to(Vector2(960, 540)) < 0.01, "El zoom debe conservar el punto bajo el cursor")
	var cursor_scene_before := canvas._screen_to_scene(Vector2(520, 360))
	canvas._zoom_at(Vector2(520, 360), 1.12)
	assert(canvas._screen_to_scene(Vector2(520, 360)).distance_to(cursor_scene_before) < 0.01, "El zoom debe anclarse a la posición del cursor")
	canvas.set_selected("actor")
	assert(canvas.selected_id == "actor", "Debe conservar selección")
	var camera_scene := scene.duplicate(true)
	camera_scene["camera"] = {"x": 960.0, "y": 540.0, "zoom": 2.0, "rotation": 0.0}
	canvas.set_scene_data(camera_scene, 1920.0, 1080.0)
	var camera_center := canvas._scene_to_screen(Vector2(960.0, 540.0))
	var camera_right := canvas._scene_to_screen(Vector2(1000.0, 540.0))
	assert(camera_center.distance_to(canvas._canvas_rect().get_center()) < 0.01, "El centro de cámara debe quedar en el centro de la composición")
	assert(is_equal_approx(camera_right.x - camera_center.x, 40.0 * canvas._canvas_scale() * 2.0), "El zoom de cámara debe ampliar el encuadre")
	assert(canvas._screen_to_scene(camera_right).distance_to(Vector2(1000.0, 540.0)) < 0.01, "La cámara debe invertir coordenadas correctamente")
	camera_scene["camera"]["rotation"] = 90.0
	canvas.set_scene_data(camera_scene, 1920.0, 1080.0)
	var rotated_right := canvas._scene_to_screen(Vector2(1000.0, 540.0))
	assert(absf(rotated_right.x - camera_center.x) < 0.01 and rotated_right.y < camera_center.y, "La rotación de cámara debe rotar el encuadre y conservar el centro")
	canvas.pan = Vector2(35, -20)
	canvas.reset_view()
	assert(canvas.zoom == 1.0 and canvas.pan == Vector2.ZERO, "Debe reiniciar cámara")
	var dropped: Array = []
	canvas.asset_dropped.connect(func(kind: String, position: Vector2): dropped.append({"kind":kind,"position":position}))
	assert(canvas._can_drop_data(Vector2.ZERO, {"scene_asset_type":"character"}), "Debe aceptar tipos de recurso admitidos")
	assert(not canvas._can_drop_data(Vector2.ZERO, {"scene_asset_type":"audio"}), "Debe rechazar tipos no admitidos")
	canvas._drop_data(Vector2(400,300), {"scene_asset_type":"decoration"})
	assert(dropped.size() == 1 and dropped[0].kind == "decoration", "Debe emitir la colocación por arrastre")
	assert(dropped[0].position.distance_to(Vector2(960,540)) < 0.01, "Debe convertir la posición soltada al espacio de escena")
	var interactive = CANVAS.new()
	interactive.size = Vector2(800, 600)
	var interactive_scene := {
		"id": "drag_test",
		"objects": [
			{"id":"back","type":"background","name":"Fondo","transform":{"x":960.0,"y":540.0,"scale_x":1.0,"scale_y":1.0,"rotation":0.0,"depth":0.0,"visible":true}},
			{"id":"move_me","type":"character","name":"Mover","transform":{"x":960.0,"y":540.0,"scale_x":1.0,"scale_y":1.0,"rotation":0.0,"depth":1.0,"visible":true}}
		]
	}
	root.add_child(interactive)
	interactive.set_scene_data(interactive_scene, 1920.0, 1080.0)
	var pan_event := InputEventMouseButton.new()
	pan_event.button_index = MOUSE_BUTTON_RIGHT
	pan_event.pressed = true
	pan_event.position = Vector2(400, 300)
	interactive._gui_input(pan_event)
	var pan_motion := InputEventMouseMotion.new()
	pan_motion.position = Vector2(435, 325)
	interactive._gui_input(pan_motion)
	var pan_release := InputEventMouseButton.new()
	pan_release.button_index = MOUSE_BUTTON_RIGHT
	pan_release.pressed = false
	pan_release.position = Vector2(435, 325)
	interactive._gui_input(pan_release)
	assert(interactive.pan == Vector2(35, 25), "El botón derecho debe desplazar la cámara")
	interactive.reset_view()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(400, 300)
	interactive._gui_input(press)
	assert(interactive.selected_id == "move_me", "Debe seleccionar el objeto superior")
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(450, 320)
	interactive._gui_input(motion)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(450, 320)
	interactive._gui_input(release)
	assert(float(interactive_scene.objects[1].transform.x) > 960.0, "Debe mover el objeto al arrastrar")
	assert(float(interactive_scene.objects[1].transform.y) > 540.0, "Debe mover el objeto verticalmente")
	interactive.queue_free()
	var environment_canvas = CANVAS.new()
	root.add_child(environment_canvas)
	environment_canvas.set_environment_data({"sky_color":[0.1,0.2,0.3],"weather":"rain","weather_intensity":0.5,"background_layers":[]})
	assert(environment_canvas.environment_data.weather == "rain" and environment_canvas.is_processing(), "La vista debe activar la animación de clima")
	environment_canvas.set_environment_data({"sky_color":[0.2,0.3,0.4],"weather":"clear","weather_intensity":0.0})
	assert(not environment_canvas.is_processing(), "El clima despejado no debe consumir ciclo de actualización")
	environment_canvas.queue_free()
	print("SCENE_CANVAS_TESTS_OK")
	quit(0)
