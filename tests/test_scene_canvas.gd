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
	canvas.zoom = 1.5
	assert(is_equal_approx(canvas._canvas_scale(), 1.5 * 800.0 / 1920.0), "Debe aplicar zoom")
	canvas.set_selected("actor")
	assert(canvas.selected_id == "actor", "Debe conservar selección")
	canvas.reset_view()
	assert(canvas.zoom == 1.0 and canvas.pan == Vector2.ZERO, "Debe reiniciar cámara")
	var dropped: Array = []
	canvas.asset_dropped.connect(func(kind: String, position: Vector2): dropped.append({"kind":kind,"position":position}))
	assert(canvas._can_drop_data(Vector2.ZERO, {"scene_asset_type":"character"}), "Debe aceptar tipos de recurso admitidos")
	assert(not canvas._can_drop_data(Vector2.ZERO, {"scene_asset_type":"audio"}), "Debe rechazar tipos no admitidos")
	canvas._drop_data(Vector2(400,300), {"scene_asset_type":"decoration"})
	assert(dropped.size() == 1 and dropped[0].kind == "decoration", "Debe emitir la colocación por arrastre")
	assert(dropped[0].position.distance_to(Vector2(960,540)) < 0.01, "Debe convertir la posición soltada al espacio de escena")
	print("SCENE_CANVAS_TESTS_OK")
	quit(0)
