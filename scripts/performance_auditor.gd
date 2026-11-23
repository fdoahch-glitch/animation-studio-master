extends RefCounted
class_name PerformanceAuditor

const DEFAULT_BUDGETS = {"scenes": 100, "objects_per_scene": 500, "resources": 2000, "resource_bytes": 536870912, "total_project_objects": 5000}

func audit_project(project: Dictionary, budgets: Dictionary = {}) -> Dictionary:
	var limits: Dictionary = DEFAULT_BUDGETS.duplicate(true)
	for key in budgets:
		limits[key] = budgets[key]
	var warnings: Array[String] = []
	var scenes_value: Variant = project.get("scenes", [])
	var resources_value: Variant = project.get("resources", [])
	var scenes: Array = scenes_value if scenes_value is Array else []
	var resources: Array = resources_value if resources_value is Array else []
	if not scenes_value is Array:
		warnings.append("La lista de escenas no tiene un formato válido.")
	if not resources_value is Array:
		warnings.append("La lista de recursos no tiene un formato válido.")
	var object_total := 0
	var max_scene_objects := 0
	var scene_report: Array = []
	for scene in scenes:
		if not scene is Dictionary:
			warnings.append("Se encontró una escena con formato inválido.")
			continue
		var objects: Variant = scene.get("objects", [])
		if not objects is Array:
			warnings.append("Una escena contiene una lista de objetos inválida: %s." % str(scene.get("name", "Escena")))
			continue
		var count := objects.size()
		object_total += count
		max_scene_objects = maxi(max_scene_objects, count)
		scene_report.append({"id": str(scene.get("id", "")), "name": str(scene.get("name", "Escena")), "objects": count, "duration_seconds": maxf(0.0, float(scene.get("duration_seconds", 0.0)))})
	var resource_bytes := 0
	var missing: Array[String] = []
	var extensions: Dictionary = {}
	for resource in resources:
		if not resource is Dictionary:
			warnings.append("Se encontró un recurso con formato inválido.")
			continue
		var path := str(resource.get("path", ""))
		var size := maxi(0, int(resource.get("bytes", 0)))
		if int(resource.get("bytes", 0)) < 0:
			warnings.append("Un recurso declara un tamaño negativo.")
		if not path.is_empty() and FileAccess.file_exists(path):
			var resource_file := FileAccess.open(path, FileAccess.READ)
			if resource_file != null:
				size = int(resource_file.get_length())
				resource_file.close()
			else:
				warnings.append("No se pudo leer el tamaño de un recurso: %s." % path)
		elif not path.is_empty():
			missing.append(path)
		resource_bytes += size
		var ext := str(resource.get("extension", path.get_extension())).to_lower()
		extensions[ext] = int(extensions.get(ext, 0)) + 1
	if scenes.size() > int(limits.scenes):
		warnings.append("El proyecto supera el presupuesto de escenas.")
	if max_scene_objects > int(limits.objects_per_scene):
		warnings.append("Una escena supera el presupuesto de objetos.")
	if resources.size() > int(limits.resources):
		warnings.append("El proyecto supera el presupuesto de recursos.")
	if resource_bytes > int(limits.resource_bytes):
		warnings.append("Los recursos superan el presupuesto de almacenamiento.")
	if object_total > int(limits.total_project_objects):
		warnings.append("El total de objetos supera el presupuesto.")
	if not missing.is_empty():
		warnings.append("Hay rutas de recursos que no se encuentran.")
	return {"format": "animation_studio_performance_audit", "version": 1, "project_name": str(project.get("name", "Proyecto")), "summary": {"scene_count": scenes.size(), "resource_count": resources.size(), "object_count": object_total, "max_objects_per_scene": max_scene_objects, "resource_bytes": resource_bytes, "missing_resources": missing.size()}, "scenes": scene_report, "resource_extensions": extensions, "missing_resources": missing, "budgets": limits, "warnings": warnings, "passed": warnings.is_empty()}

func estimate_texture_memory(width: int, height: int, bytes_per_pixel := 4, mipmaps := true) -> int:
	if width <= 0 or height <= 0 or bytes_per_pixel <= 0:
		return 0
	var base := width * height * bytes_per_pixel
	return int(ceil(float(base) * 1.3333333)) if mipmaps else base

func recommend_render_scale(frame_time_ms: float, target_fps := 60.0, current_scale := 1.0, floor_scale := 0.65) -> float:
	var safe_floor := clampf(floor_scale, 0.1, 1.0)
	var safe_scale := clampf(current_scale, safe_floor, 1.0)
	if target_fps <= 0.0 or frame_time_ms <= 0.0:
		return safe_scale
	var budget := 1000.0 / target_fps
	if frame_time_ms > budget * 1.08:
		return maxf(safe_floor, safe_scale - 0.05)
	if frame_time_ms < budget * 0.78:
		return minf(1.0, safe_scale + 0.02)
	return safe_scale
