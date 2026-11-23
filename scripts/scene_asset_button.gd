extends Button
class_name SceneAssetButton

var resource_kind := "element"

func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview := Label.new()
	preview.text = "＋ " + text
	preview.add_theme_color_override("font_color", Color("#ffffff"))
	set_drag_preview(preview)
	return {"scene_asset_type": resource_kind}
