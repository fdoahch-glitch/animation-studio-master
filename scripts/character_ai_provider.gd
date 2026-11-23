extends Node
class_name CharacterAIProvider

## Adaptador opcional para un servicio de IA compatible con el contrato JSON de este proyecto.
## No contiene claves ni presupone un proveedor concreto. El usuario configura el endpoint.

signal request_completed(result: Dictionary)
signal request_failed(message: String)

var endpoint: String = ""
var api_key: String = ""

func configure(service_endpoint: String, secret_key: String = "") -> bool:
	var candidate := service_endpoint.strip_edges()
	var local_host := candidate == "http://localhost" or candidate.begins_with("http://localhost:") or candidate.begins_with("http://localhost/")
	var local_ip := candidate == "http://127.0.0.1" or candidate.begins_with("http://127.0.0.1:") or candidate.begins_with("http://127.0.0.1/")
	if not candidate.begins_with("https://") and not local_host and not local_ip:
		request_failed.emit("Usa HTTPS o un endpoint local exacto en localhost/127.0.0.1.")
		return false
	endpoint = candidate.trim_suffix("/")
	api_key = secret_key.strip_edges()
	return true

func is_configured() -> bool:
	return endpoint != ""

func request_segmentation(image_path: String, http_request: HTTPRequest, visual_mode: String = "2D") -> Error:
	if not is_configured():
		request_failed.emit("Configura primero un endpoint de IA.")
		return ERR_UNCONFIGURED
	var image := Image.new()
	var err := image.load(image_path)
	if err != OK:
		request_failed.emit("No se pudo leer la imagen para enviarla al servicio.")
		return err
	image.convert(Image.FORMAT_RGBA8)
	var payload := {
		"task": "character_part_segmentation",
		"schema_version": 1,
		"visual_mode": visual_mode,
		"image_mime": "image/png",
		"image_base64": Marshalls.raw_to_base64(image.save_png_to_buffer()),
		"requested_parts": [
			"head", "neck", "torso", "pelvis",
			"upper_arm_left", "lower_arm_left", "hand_left",
			"upper_arm_right", "lower_arm_right", "hand_right",
			"upper_leg_left", "lower_leg_left", "foot_left",
			"upper_leg_right", "lower_leg_right", "foot_right",
			"hair", "clothing", "accessories"
		],
		"requested_outputs": ["masks", "joint_points", "confidence", "view_consistency"]
	}
	var headers := PackedStringArray(["Content-Type: application/json"])
	if api_key != "":
		headers.append("Authorization: Bearer " + api_key)
	if not http_request.request_completed.is_connected(_on_request_completed):
		http_request.request_completed.connect(_on_request_completed)
	return http_request.request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))

func request_turnaround_generation(description: String, style: String, http_request: HTTPRequest, reference_image_path: String = "") -> Error:
	if not is_configured():
		request_failed.emit("Configura primero un endpoint de IA.")
		return ERR_UNCONFIGURED
	var payload := {
		"task": "character_turnaround_generation",
		"schema_version": 1,
		"description": description,
		"art_style": style,
		"views": ["front", "profile", "back", "three_quarter"],
		"consistency": "same character identity, anatomy, costume, palette and proportions",
		"output_format": "png_base64"
	}
	if reference_image_path != "":
		var reference := Image.new()
		if reference.load(reference_image_path) == OK:
			reference.convert(Image.FORMAT_RGBA8)
			payload["reference_image_base64"] = Marshalls.raw_to_base64(reference.save_png_to_buffer())
	return _post_json(http_request, payload)

func request_pose_generation(description: String, rig_type: String, http_request: HTTPRequest) -> Error:
	if not is_configured():
		request_failed.emit("Configura primero un endpoint de IA.")
		return ERR_UNCONFIGURED
	var payload := {
		"task": "character_pose_generation",
		"schema_version": 1,
		"character_description": description,
		"rig_type": rig_type,
		"requested_poses": ["idle", "walk", "run", "jump", "talk", "wave", "sit", "turn"],
		"requested_outputs": ["joint_angles", "keyframes", "duration", "loop"]
	}
	return _post_json(http_request, payload)

func _post_json(http_request: HTTPRequest, payload: Dictionary) -> Error:
	var headers := PackedStringArray(["Content-Type: application/json"])
	if api_key != "":
		headers.append("Authorization: Bearer " + api_key)
	if not http_request.request_completed.is_connected(_on_request_completed):
		http_request.request_completed.connect(_on_request_completed)
	return http_request.request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		request_failed.emit("Falló la conexión con el proveedor de IA. Código: " + str(result))
		return
	if response_code < 200 or response_code >= 300:
		request_failed.emit("El proveedor respondió HTTP " + str(response_code) + ".")
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Dictionary:
		request_failed.emit("Respuesta inválida: se esperaba un objeto JSON.")
		return
	if int(parsed.get("schema_version", 0)) != 1:
		request_failed.emit("Respuesta incompatible: schema_version debe ser 1.")
		return
	var task := str(parsed.get("task", "character_part_segmentation"))
	if task == "character_part_segmentation" and not parsed.has("segments"):
		request_failed.emit("Respuesta de segmentación sin segments.")
		return
	if task == "character_turnaround_generation" and not parsed.has("views"):
		request_failed.emit("Respuesta de vistas sin views.")
		return
	if task == "character_pose_generation" and not parsed.has("poses"):
		request_failed.emit("Respuesta de poses sin poses.")
		return
	request_completed.emit(parsed)

func validate_segmentation_result(data: Dictionary, image_size: Vector2i) -> Dictionary:
	var segments: Array = data.get("segments", [])
	var accepted: Array[Dictionary] = []
	var rejected: Array[String] = []
	for segment in segments:
		if not segment is Dictionary:
			rejected.append("segmento sin estructura")
			continue
		var part_name := str(segment.get("name", ""))
		var rect_data: Array = segment.get("rect", [])
		if part_name == "" or rect_data.size() != 4:
			rejected.append("segmento con nombre o rectángulo inválido")
			continue
		var rect := Rect2i(int(rect_data[0]), int(rect_data[1]), int(rect_data[2]), int(rect_data[3]))
		if rect.size.x <= 0 or rect.size.y <= 0 or rect.position.x < 0 or rect.position.y < 0:
			rejected.append(part_name + ": rectángulo no válido")
			continue
		if rect.end.x > image_size.x or rect.end.y > image_size.y:
			rejected.append(part_name + ": fuera de los límites de la imagen")
			continue
		var accepted_segment := {"name": part_name, "rect": rect, "confidence": clampf(float(segment.get("confidence", 0.0)), 0.0, 1.0)}
		if segment.has("mask_png_base64"):
			accepted_segment["mask_png_base64"] = str(segment.mask_png_base64)
		accepted.append(accepted_segment)
	var joints: Dictionary = {}
	var raw_joints: Variant = data.get("joints", {})
	if raw_joints is Dictionary:
		for joint_name in raw_joints.keys():
			var point_data: Variant = raw_joints[joint_name]
			if point_data is Array and point_data.size() == 2:
				var point := Vector2(float(point_data[0]), float(point_data[1]))
				if point.x >= 0.0 and point.y >= 0.0 and point.x < image_size.x and point.y < image_size.y:
					joints[str(joint_name)] = [point.x, point.y]
	return {"accepted": accepted, "rejected": rejected, "joints": joints, "valid": not accepted.is_empty()}
