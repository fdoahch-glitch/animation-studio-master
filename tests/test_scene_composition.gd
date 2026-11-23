extends SceneTree

const MODEL = preload("res://scripts/scene_composition_model.gd")

func _initialize() -> void:
	var model = MODEL.new()
	var scene := {"id":"scene_test","objects":[],"transitions":{}}
	var actor: Dictionary = model.create_instance("char_01", "character", "Lía", Vector2(120, 240))
	assert(not actor.is_empty(), "Debe crear una instancia de personaje")
	var added: Dictionary = model.add_instance(scene, actor)
	assert(added.ok and scene.objects.size() == 1, "Debe añadir la instancia")
	var duplicate: Dictionary = model.add_instance(scene, actor)
	assert(not duplicate.ok, "Debe rechazar IDs duplicados")
	var moved: Dictionary = model.update_transform(scene, actor.id, {"x":300.0,"y":180.0,"scale_x":150.0,"rotation":-30.0})
	assert(moved.ok, "Debe actualizar transformaciones")
	var transform: Dictionary = scene.objects[0].transform
	assert(transform.x == 300.0 and transform.y == 180.0)
	assert(transform.scale_x == 100.0, "Debe limitar escalas inseguras")
	assert(transform.rotation == 330.0, "Debe normalizar rotación")
	var prop: Dictionary = model.create_instance("prop_01", "element", "Mesa")
	assert(actor.id != prop.id, "Cada instancia debe recibir un ID único")
	assert(model.add_instance(scene, prop).ok)
	assert(model.reorder_instance(scene, prop.id, 0).ok)
	assert(scene.objects[0].id == prop.id, "Debe reordenar capas")
	assert(model.set_transition(scene, "fade", 1.25).ok)
	assert(scene.transitions.type == "fade" and scene.transitions.duration_seconds == 1.25)
	assert(not model.set_transition(scene, "unknown", 1.0).ok)
	assert(model.validate_scene(scene).ok)
	var usage := model.find_resource_references([scene], "char_01")
	assert(usage.size() == 1 and usage[0].instance_id == actor.id, "Debe localizar recursos usados por escenas")
	assert(model.find_resource_references([scene], "unused_asset").is_empty(), "No debe reportar recursos sin referencias")

	var missing_resource := actor.duplicate(true)
	missing_resource["resource_id"] = "  "
	var invalid_resource_scene := {"objects": [missing_resource], "transitions": {}}
	assert(not model.validate_scene(invalid_resource_scene).ok, "Debe rechazar instancias sin recurso vinculado")

	var invalid_transform := actor.duplicate(true)
	invalid_transform["transform"]["x"] = INF
	var invalid_transform_scene := {"objects": [invalid_transform], "transitions": {}}
	assert(not model.validate_scene(invalid_transform_scene).ok, "Debe rechazar coordenadas infinitas")

	var invalid_scale := actor.duplicate(true)
	invalid_scale["transform"]["scale_y"] = 0.0
	var invalid_scale_scene := {"objects": [invalid_scale], "transitions": {}}
	assert(not model.validate_scene(invalid_scale_scene).ok, "Debe rechazar escalas nulas")

	var invalid_visibility := actor.duplicate(true)
	invalid_visibility["transform"]["visible"] = "yes"
	var invalid_visibility_scene := {"objects": [invalid_visibility], "transitions": {}}
	assert(not model.validate_scene(invalid_visibility_scene).ok, "Debe exigir visibilidad booleana")

	assert(not model.validate_scene({"objects": [], "transitions": {"type": "teleport", "duration_seconds": 1.0}}).ok, "Debe rechazar transiciones desconocidas")
	assert(not model.validate_scene({"objects": [], "transitions": {"type": "fade", "duration_seconds": INF}}).ok, "Debe rechazar duraciones no finitas")
	assert(model.remove_instance(scene, actor.id).ok)
	assert(scene.objects.size() == 1)
	print("SCENE_COMPOSITION_TESTS_OK")
	quit(0)
