extends RefCounted
class_name SceneCompositionModel

## Modelo de composición de escenas: instancias, transformaciones, capas y transiciones.
## Mantiene los recursos como referencias/metadatos; no duplica archivos originales.

const OBJECT_TYPES := ["character", "background", "element", "decoration"]
const DEFAULT_TRANSFORM := {"x": 0.0, "y": 0.0, "scale_x": 1.0, "scale_y": 1.0, "rotation": 0.0, "depth": 0.0, "visible": true}

var _instance_sequence: int = 0

func create_instance(resource_id: String, resource_type: String, display_name: String, position := Vector2.ZERO) -> Dictionary:
	if resource_id.strip_edges().is_empty() or not OBJECT_TYPES.has(resource_type):
		return {}
	_instance_sequence += 1
	var item := {
		"id": "instance_%d_%d" % [Time.get_ticks_usec(), _instance_sequence],
		"resource_id": resource_id,
		"type": resource_type,
		"name": display_name.strip_edges() if not display_name.strip_edges().is_empty() else resource_id,
		"transform": DEFAULT_TRANSFORM.duplicate(true),
		"actions": [],
		"metadata": {}
	}
	item["transform"]["x"] = position.x
	item["transform"]["y"] = position.y
	return item

func add_instance(scene: Dictionary, instance: Dictionary) -> Dictionary:
	if instance.is_empty():
		return {"ok": false, "error": "Instancia inválida."}
	var objects: Array = scene.get("objects", []).duplicate(true)
	if _find_index(objects, str(instance.get("id", ""))) >= 0:
		return {"ok": false, "error": "Ya existe una instancia con ese ID."}
	objects.append(instance.duplicate(true))
	scene["objects"] = objects
	return {"ok": true, "scene": scene}

func update_transform(scene: Dictionary, instance_id: String, changes: Dictionary) -> Dictionary:
	var objects: Array = scene.get("objects", []).duplicate(true)
	var index := _find_index(objects, instance_id)
	if index < 0:
		return {"ok": false, "error": "No se encontró la instancia."}
	var item: Dictionary = objects[index].duplicate(true)
	var transform: Dictionary = item.get("transform", DEFAULT_TRANSFORM).duplicate(true)
	for key in changes:
		if DEFAULT_TRANSFORM.has(key):
			transform[key] = changes[key]
	transform["scale_x"] = clampf(float(transform.get("scale_x", 1.0)), 0.01, 100.0)
	transform["scale_y"] = clampf(float(transform.get("scale_y", 1.0)), 0.01, 100.0)
	transform["rotation"] = fposmod(float(transform.get("rotation", 0.0)), 360.0)
	item["transform"] = transform
	objects[index] = item
	scene["objects"] = objects
	return {"ok": true, "scene": scene, "instance": item}

func remove_instance(scene: Dictionary, instance_id: String) -> Dictionary:
	var objects: Array = scene.get("objects", []).duplicate(true)
	var index := _find_index(objects, instance_id)
	if index < 0:
		return {"ok": false, "error": "No se encontró la instancia."}
	objects.remove_at(index)
	scene["objects"] = objects
	return {"ok": true, "scene": scene}

func reorder_instance(scene: Dictionary, instance_id: String, target_index: int) -> Dictionary:
	var objects: Array = scene.get("objects", []).duplicate(true)
	var index := _find_index(objects, instance_id)
	if index < 0:
		return {"ok": false, "error": "No se encontró la instancia."}
	var item: Dictionary = objects.pop_at(index)
	objects.insert(clampi(target_index, 0, objects.size()), item)
	scene["objects"] = objects
	return {"ok": true, "scene": scene}

func set_transition(scene: Dictionary, transition_type: String, duration: float, direction := "in_out") -> Dictionary:
	var allowed := ["cut", "fade", "dissolve", "wipe"]
	if not allowed.has(transition_type):
		return {"ok": false, "error": "Tipo de transición no compatible."}
	scene["transitions"] = {
		"type": transition_type,
		"duration_seconds": clampf(duration, 0.0, 30.0),
		"direction": direction
	}
	return {"ok": true, "scene": scene}

func validate_scene(scene: Dictionary) -> Dictionary:
	var objects: Variant = scene.get("objects", [])
	if not objects is Array:
		return {"ok": false, "error": "objects debe ser una lista."}
	var seen := {}
	for item in objects:
		if not item is Dictionary or str(item.get("id", "")).is_empty():
			return {"ok": false, "error": "Cada instancia necesita un ID y metadatos válidos."}
		var id := str(item["id"])
		if seen.has(id):
			return {"ok": false, "error": "ID de instancia duplicado: " + id}
		seen[id] = true
		if not OBJECT_TYPES.has(str(item.get("type", ""))):
			return {"ok": false, "error": "Tipo de instancia no compatible: " + str(item.get("type", ""))}
	return {"ok": true, "count": objects.size()}

func _find_index(objects: Array, instance_id: String) -> int:
	for index in range(objects.size()):
		if str(objects[index].get("id", "")) == instance_id:
			return index
	return -1
