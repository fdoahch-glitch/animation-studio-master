extends RefCounted
class_name CharacterImageProcessor

## Herramientas locales de preparación de imágenes. Elimina fondos planos conectados
## al borde y exporta recortes anatómicos aproximados para corrección manual.
## No sustituye un modelo de segmentación semántica.

const MAX_PIXELS := 16000000

func create_adjusted_texture(source_path: String, brightness: float = 1.0, contrast: float = 1.0, saturation: float = 1.0) -> String:
	var image := Image.new()
	if image.load(source_path) != OK:
		return ""
	image.convert(Image.FORMAT_RGBA8)
	if image.get_width() * image.get_height() > MAX_PIXELS:
		return ""
	image.adjust_bcs(clampf(brightness, 0.0, 2.0), clampf(contrast, 0.5, 1.8), clampf(saturation, 0.0, 2.0))
	var output_dir := "user://character_parts/" + str(Time.get_unix_time_from_system()) + "_texture"
	var absolute_dir := ProjectSettings.globalize_path(output_dir)
	if DirAccess.make_dir_recursive_absolute(absolute_dir) != OK:
		return ""
	var output_path := output_dir.path_join("character_texture_adjusted.png")
	return output_path if image.save_png(output_path) == OK else ""

func process_character_image(source_path: String, tolerance: float = 0.16) -> Dictionary:
	var image := Image.new()
	var err := image.load(source_path)
	if err != OK:
		return {"ok": false, "error": "No se pudo abrir la imagen. Código: " + str(err)}
	image.convert(Image.FORMAT_RGBA8)
	var size := image.get_size()
	if size.x < 32 or size.y < 64:
		return {"ok": false, "error": "La imagen es demasiado pequeña para preparar un personaje."}
	if size.x * size.y > MAX_PIXELS:
		return {"ok": false, "error": "La imagen supera el límite seguro de 16 megapíxeles."}

	var background_color := _sample_corner_color(image)
	var removed := _remove_connected_background(image, background_color, clampf(tolerance, 0.03, 0.45))
	var bounds := _find_alpha_bounds(image)
	if bounds.size.x < 8 or bounds.size.y < 16:
		return {"ok": false, "error": "No se detectó una silueta útil. Prueba con fondo uniforme y personaje completo."}

	var output_dir := "user://character_parts/" + str(Time.get_unix_time_from_system())
	var absolute_dir := ProjectSettings.globalize_path(output_dir)
	DirAccess.make_dir_recursive_absolute(absolute_dir)
	var regions := _build_regions(bounds)
	var saved_parts: Array[Dictionary] = []
	for region in regions:
		var rect: Rect2i = region.rect
		var part_image := image.get_region(rect)
		var filename := str(region.name) + ".png"
		var save_path := output_dir.path_join(filename)
		var save_error := part_image.save_png(save_path)
		if save_error == OK:
			saved_parts.append({
				"name": region.name,
				"label": region.label,
				"path": save_path,
				"rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
				"normalized_rect": [float(rect.position.x) / size.x, float(rect.position.y) / size.y, float(rect.size.x) / size.x, float(rect.size.y) / size.y]
			})

	var processed_path := output_dir.path_join("character_cutout.png")
	var image_error := image.save_png(processed_path)
	return {
		"ok": image_error == OK,
		"source": source_path,
		"processed_image": processed_path,
		"output_dir": output_dir,
		"width": size.x,
		"height": size.y,
		"background_removed_pixels": removed,
		"silhouette_bounds": [bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y],
		"parts": saved_parts,
		"method": "connected_edge_background_removal_and_proportional_regions",
		"requires_manual_review": true
	}

func _sample_corner_color(image: Image) -> Color:
	var w := image.get_width()
	var h := image.get_height()
	var points := [Vector2i(0, 0), Vector2i(w - 1, 0), Vector2i(0, h - 1), Vector2i(w - 1, h - 1)]
	var total := Color(0, 0, 0, 0)
	for point in points:
		total += image.get_pixelv(point)
	return total / float(points.size())

func _remove_connected_background(image: Image, reference: Color, tolerance: float) -> int:
	var w := image.get_width()
	var h := image.get_height()
	var visited := PackedByteArray()
	visited.resize(w * h)
	var stack: Array[Vector2i] = []
	for x in range(w):
		stack.append(Vector2i(x, 0))
		stack.append(Vector2i(x, h - 1))
	for y in range(1, h - 1):
		stack.append(Vector2i(0, y))
		stack.append(Vector2i(w - 1, y))
	var removed := 0
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h:
			continue
		var index := p.y * w + p.x
		if visited[index] == 1:
			continue
		visited[index] = 1
		var color := image.get_pixelv(p)
		if color.a <= 0.01:
			continue
		if _color_distance(color, reference) > tolerance:
			continue
		color.a = 0.0
		image.set_pixelv(p, color)
		removed += 1
		stack.append(Vector2i(p.x + 1, p.y))
		stack.append(Vector2i(p.x - 1, p.y))
		stack.append(Vector2i(p.x, p.y + 1))
		stack.append(Vector2i(p.x, p.y - 1))
	return removed

func _color_distance(a: Color, b: Color) -> float:
	return sqrt(pow(a.r - b.r, 2.0) + pow(a.g - b.g, 2.0) + pow(a.b - b.b, 2.0))

func _find_alpha_bounds(image: Image) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.05:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func _build_regions(bounds: Rect2i) -> Array[Dictionary]:
	var x := bounds.position.x
	var y := bounds.position.y
	var w := bounds.size.x
	var h := bounds.size.y
	var definitions := [
		["head", "Cabeza", 0.28, 0.00, 0.44, 0.25],
		["torso", "Torso", 0.22, 0.20, 0.56, 0.38],
		["pelvis", "Pelvis", 0.28, 0.48, 0.44, 0.22],
		["arm_left", "Brazo izquierdo (zona)", 0.00, 0.20, 0.34, 0.43],
		["arm_right", "Brazo derecho (zona)", 0.66, 0.20, 0.34, 0.43],
		["leg_left", "Pierna izquierda (zona)", 0.18, 0.55, 0.34, 0.45],
		["leg_right", "Pierna derecha (zona)", 0.48, 0.55, 0.34, 0.45]
	]
	var result: Array[Dictionary] = []
	for definition in definitions:
		var rx := clampi(x + int(w * float(definition[2])), 0, image_limit_x(bounds))
		var ry := clampi(y + int(h * float(definition[3])), 0, image_limit_y(bounds))
		var rw := maxi(1, mini(int(w * float(definition[4])), x + w - rx))
		var rh := maxi(1, mini(int(h * float(definition[5])), y + h - ry))
		result.append({"name": definition[0], "label": definition[1], "rect": Rect2i(rx, ry, rw, rh)})
	return result

func image_limit_x(bounds: Rect2i) -> int:
	return bounds.position.x + bounds.size.x

func image_limit_y(bounds: Rect2i) -> int:
	return bounds.position.y + bounds.size.y

