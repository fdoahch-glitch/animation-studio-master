extends Control
class_name VideoTimelineView

signal track_selected(track_index: int)
signal clip_selected(track_index: int, clip_index: int)
signal clip_moved(track_index: int, clip_id: String, new_start: float)
signal clip_trimmed(track_index: int, clip_id: String, new_start: float, new_end: float)
signal time_selected(seconds: float)

const HEADER_HEIGHT := 30.0
const ROW_HEIGHT := 38.0
const LABEL_WIDTH := 150.0
const PIXELS_PER_SECOND := 48.0
const MIN_VISIBLE_SECONDS := 15.0

var timeline: Dictionary = {}
var playhead := 0.0
var selected_track := -1
var selected_clip := -1
var dragging := false
var drag_changed := false
var drag_track := -1
var drag_clip_id := ""
var drag_mode := "move"
var drag_origin := 0.0
var drag_original_end := 0.0
var drag_offset := 0.0
var drag_preview_start := 0.0
var drag_preview_end := 0.0

func configure(value: Dictionary, current_time: float = 0.0, active_track: int = -1, active_clip: int = -1) -> void:
	timeline = value.duplicate(true)
	playhead = maxf(0.0, current_time)
	selected_track = active_track
	selected_clip = active_clip
	var duration := MIN_VISIBLE_SECONDS
	for track in timeline.get("tracks", []):
		for clip in track.get("clips", []):
			duration = maxf(duration, float(clip.get("start", 0.0)) + float(clip.get("duration", 0.0)) + 2.0)
	duration = minf(duration, 600.0)
	custom_minimum_size = Vector2(LABEL_WIDTH + duration * PIXELS_PER_SECOND, HEADER_HEIGHT + maxf(1.0, float(timeline.get("tracks", []).size())) * ROW_HEIGHT + 4.0)
	queue_redraw()

func _time_x(seconds: float) -> float:
	return LABEL_WIDTH + maxf(0.0, seconds) * PIXELS_PER_SECOND

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#101d2b"), true)
	draw_rect(Rect2(0.0, 0.0, size.x, HEADER_HEIGHT), Color("#1c3044"), true)
	draw_rect(Rect2(0.0, 0.0, LABEL_WIDTH, size.y), Color("#182a3b"), true)
	draw_string(ThemeDB.fallback_font, Vector2(10.0, 20.0), "PISTAS", HORIZONTAL_ALIGNMENT_LEFT, LABEL_WIDTH - 16.0, 11, Color("#b8c9d8"))
	var seconds_visible := int(ceil((size.x - LABEL_WIDTH) / PIXELS_PER_SECOND))
	for second in range(0, seconds_visible + 1):
		var x := _time_x(float(second))
		var major := second % 5 == 0
		draw_line(Vector2(x, HEADER_HEIGHT - (7.0 if major else 3.0)), Vector2(x, size.y), Color(0.65, 0.75, 0.85, 0.22 if major else 0.09), 1.0)
		if major:
			draw_string(ThemeDB.fallback_font, Vector2(x + 3.0, 19.0), "%d s" % second, HORIZONTAL_ALIGNMENT_LEFT, 42.0, 10, Color("#d0deea"))
	var tracks: Array = timeline.get("tracks", [])
	for track_index in range(tracks.size()):
		var y := HEADER_HEIGHT + float(track_index) * ROW_HEIGHT
		if track_index == selected_track:
			draw_rect(Rect2(0.0, y, size.x, ROW_HEIGHT), Color(0.12, 0.28, 0.40, 0.24), true)
		draw_line(Vector2(0.0, y + ROW_HEIGHT), Vector2(size.x, y + ROW_HEIGHT), Color(0.55, 0.66, 0.76, 0.14), 1.0)
		var track: Dictionary = tracks[track_index]
		var track_name := str(track.get("name", "Pista"))
		draw_string(ThemeDB.fallback_font, Vector2(10.0, y + 24.0), track_name, HORIZONTAL_ALIGNMENT_LEFT, LABEL_WIDTH - 18.0, 11, Color("#e0eaf2"))
		var clip_index := 0
		for clip in track.get("clips", []):
			var start := float(clip.get("start", 0.0))
			var finish := start + float(clip.get("duration", 0.1))
			if dragging and track_index == drag_track and str(clip.get("id", "")) == drag_clip_id:
				if drag_mode == "move":
					start = drag_preview_start
					finish = start + float(clip.get("duration", 0.1))
				elif drag_mode == "left":
					start = drag_preview_start
					finish = drag_original_end
				else:
					start = drag_origin
					finish = drag_preview_end
			var rect := Rect2(_time_x(start), y + 5.0, maxf(8.0, (finish - start) * PIXELS_PER_SECOND), ROW_HEIGHT - 10.0)
			var color := _track_color(str(track.get("type", "")))
			if track_index == selected_track and clip_index == selected_clip:
				draw_rect(rect.grow(2.0), Color("#f7d774"), false, 2.0)
			draw_rect(rect, color, true)
			draw_rect(rect, color.lightened(0.28), false, 1.0)
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(6.0, rect.size.y * 0.5 + 4.0), str(clip.get("name", "Clip")), HORIZONTAL_ALIGNMENT_LEFT, maxf(0.0, rect.size.x - 10.0), 10, Color("#ffffff"))
			clip_index += 1
	var head_x := _time_x(playhead)
	draw_line(Vector2(head_x, HEADER_HEIGHT), Vector2(head_x, size.y), Color("#ff6b6b"), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(head_x - 6.0, HEADER_HEIGHT), Vector2(head_x + 6.0, HEADER_HEIGHT), Vector2(head_x, HEADER_HEIGHT + 9.0)]), Color("#ff6b6b"))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if event.position.y < HEADER_HEIGHT:
				time_selected.emit(_x_time(event.position.x))
				accept_event()
				return
			var row := int(floor((event.position.y - HEADER_HEIGHT) / ROW_HEIGHT))
			var tracks: Array = timeline.get("tracks", [])
			if row < 0 or row >= tracks.size():
				return
			if event.position.x < LABEL_WIDTH:
				track_selected.emit(row)
				accept_event()
				return
			var clip_index := _hit_clip(row, event.position)
			if clip_index >= 0:
				var track: Dictionary = tracks[row]
				var clip: Dictionary = track.get("clips", [])[clip_index]
				clip_selected.emit(row, clip_index)
				dragging = true
				drag_changed = false
				drag_track = row
				drag_clip_id = str(clip.get("id", ""))
				drag_origin = float(clip.get("start", 0.0))
				drag_original_end = drag_origin + float(clip.get("duration", 0.1))
				drag_preview_start = drag_origin
				drag_preview_end = drag_original_end
				var local_time := _x_time(event.position.x)
				var left_distance := absf(event.position.x - _time_x(drag_origin))
				var right_distance := absf(event.position.x - _time_x(drag_original_end))
				drag_mode = "left" if left_distance <= 8.0 else ("right" if right_distance <= 8.0 else "move")
				drag_offset = local_time - drag_origin
				accept_event()
				return
			time_selected.emit(_x_time(event.position.x))
			track_selected.emit(row)
			accept_event()
			return
		if dragging:
			if drag_changed:
				if drag_mode == "move":
					clip_moved.emit(drag_track, drag_clip_id, drag_preview_start)
				else:
					clip_trimmed.emit(drag_track, drag_clip_id, drag_preview_start, drag_preview_end)
			dragging = false
			drag_changed = false
			drag_track = -1
			drag_clip_id = ""
			drag_mode = "move"
			queue_redraw()
			accept_event()
			return
	if event is InputEventMouseMotion and dragging:
		var pointer_time := _x_time(event.position.x)
		if drag_mode == "move":
			drag_preview_start = maxf(0.0, pointer_time - drag_offset)
			drag_changed = absf(drag_preview_start - drag_origin) >= 0.02
		elif drag_mode == "left":
			drag_preview_start = clampf(pointer_time, 0.0, drag_original_end - 0.04)
			drag_changed = absf(drag_preview_start - drag_origin) >= 0.02
		else:
			drag_preview_end = maxf(drag_origin + 0.04, pointer_time)
			drag_changed = absf(drag_preview_end - drag_original_end) >= 0.02
		queue_redraw()
		accept_event()

func _x_time(x: float) -> float:
	return maxf(0.0, (x - LABEL_WIDTH) / PIXELS_PER_SECOND)

func _hit_clip(track_index: int, position: Vector2) -> int:
	var clips: Array = timeline.get("tracks", [])[track_index].get("clips", [])
	var time := _x_time(position.x)
	for index in range(clips.size() - 1, -1, -1):
		var clip: Dictionary = clips[index]
		var start := float(clip.get("start", 0.0))
		var finish := start + float(clip.get("duration", 0.0))
		if time >= start and time <= finish:
			return index
	return -1

func _track_color(track_type: String) -> Color:
	match track_type:
		"video": return Color("#2879b9")
		"audio": return Color("#248b72")
		"title": return Color("#9867c5")
		"overlay": return Color("#b77a35")
		"effect": return Color("#b94d62")
		_: return Color("#52677b")
