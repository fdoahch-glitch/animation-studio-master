extends Control
class_name AnimationTimelineView

signal frame_selected(frame: int)
signal track_selected(index: int)
signal keyframe_moved(track_index: int, old_time: float, new_frame: int)

const HEADER_HEIGHT := 30.0
const ROW_HEIGHT := 32.0
const LABEL_WIDTH := 210.0
const RIGHT_MARGIN := 18.0

var tracks: Array = []
var fps := 24
var frame_count := 240
var current_frame := 0
var selected_track := -1
var dragging_keyframe := false
var dragged_track := -1
var dragged_key_time := 0.0
var drag_frame := 0

func configure(value_tracks: Array, project_fps: int, total_frames: int, playhead: int, selected_index: int) -> void:
	tracks = value_tracks.duplicate(true)
	fps = maxi(1, project_fps)
	frame_count = maxi(1, total_frames)
	current_frame = clampi(playhead, 0, frame_count)
	selected_track = selected_index
	queue_redraw()

func _frame_x(frame: int) -> float:
	var usable := maxf(1.0, size.x - LABEL_WIDTH - RIGHT_MARGIN)
	return LABEL_WIDTH + usable * float(frame) / float(frame_count)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#101d2b"), true)
	draw_rect(Rect2(0, 0, size.x, HEADER_HEIGHT), Color("#1c3044"), true)
	draw_rect(Rect2(0, 0, LABEL_WIDTH - 1, size.y), Color("#182a3b"), true)
	draw_line(Vector2(LABEL_WIDTH, 0), Vector2(LABEL_WIDTH, size.y), Color("#40566b"), 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(12, 20), "PISTA / OBJETO", HORIZONTAL_ALIGNMENT_LEFT, LABEL_WIDTH - 18, 11, Color("#b8c9d8"))
	var step_frames := maxi(1, int(round(float(fps) / 2.0)))
	for frame in range(0, frame_count + 1, step_frames):
		var x := _frame_x(frame)
		draw_line(Vector2(x, HEADER_HEIGHT - 5), Vector2(x, size.y), Color(0.65, 0.75, 0.85, 0.16), 1.0)
		if frame % maxi(1, fps) == 0:
			draw_string(ThemeDB.fallback_font, Vector2(x + 3, 19), str(frame), HORIZONTAL_ALIGNMENT_LEFT, 45, 10, Color("#d0deea"))
	for index in range(tracks.size()):
		var y := HEADER_HEIGHT + float(index) * ROW_HEIGHT
		if y + ROW_HEIGHT > size.y:
			break
		if index == selected_track:
			draw_rect(Rect2(0, y, size.x, ROW_HEIGHT), Color("#234766"), true)
		elif index % 2 == 0:
			draw_rect(Rect2(0, y, size.x, ROW_HEIGHT), Color(1, 1, 1, 0.025), true)
		draw_line(Vector2(0, y + ROW_HEIGHT), Vector2(size.x, y + ROW_HEIGHT), Color(0.55, 0.66, 0.76, 0.12), 1.0)
		var track: Dictionary = tracks[index]
		draw_string(ThemeDB.fallback_font, Vector2(12, y + 21), str(track.get("name", "Pista")), HORIZONTAL_ALIGNMENT_LEFT, LABEL_WIDTH - 22, 11, Color("#e0eaf2"))
		draw_line(Vector2(LABEL_WIDTH + 4, y + ROW_HEIGHT * 0.5), Vector2(size.x - RIGHT_MARGIN, y + ROW_HEIGHT * 0.5), Color("#54718a"), 2.0)
		for key in track.get("keyframes", []):
			var key_time := float(key.get("time", 0.0))
			if dragging_keyframe and index == dragged_track and absf(key_time - dragged_key_time) <= 0.0001:
				continue
			var frame := clampi(int(round(key_time * float(fps))), 0, frame_count)
			var x := _frame_x(frame)
			var cy := y + ROW_HEIGHT * 0.5
			var diamond := PackedVector2Array([Vector2(x, cy - 6), Vector2(x + 6, cy), Vector2(x, cy + 6), Vector2(x - 6, cy)])
			draw_colored_polygon(diamond, Color("#ffc857"))
		if dragging_keyframe and index == dragged_track:
			var x := _frame_x(drag_frame)
			var cy := y + ROW_HEIGHT * 0.5
			var diamond := PackedVector2Array([Vector2(x, cy - 8), Vector2(x + 8, cy), Vector2(x, cy + 8), Vector2(x - 8, cy)])
			draw_colored_polygon(diamond, Color("#6ee7b7"))
	var play_x := _frame_x(current_frame)
	draw_line(Vector2(play_x, HEADER_HEIGHT), Vector2(play_x, size.y), Color("#ff6b6b"), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(play_x - 6, HEADER_HEIGHT), Vector2(play_x + 6, HEADER_HEIGHT), Vector2(play_x, HEADER_HEIGHT + 9)]), Color("#ff6b6b"))
	if tracks.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(LABEL_WIDTH + 14, HEADER_HEIGHT + 32), "Crea una pista para empezar a animar esta escena.", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#aabccc"))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if event.position.y < HEADER_HEIGHT:
				frame_selected.emit(_frame_from_x(event.position.x))
				accept_event()
				return
			var row := int(floor((event.position.y - HEADER_HEIGHT) / ROW_HEIGHT))
			if row < 0 or row >= tracks.size():
				return
			track_selected.emit(row)
			if event.position.x >= LABEL_WIDTH:
				var hit := _find_keyframe_at(row, event.position)
				if hit >= 0:
					dragging_keyframe = true
					dragged_track = row
					dragged_key_time = float(tracks[row].get("keyframes", [])[hit].get("time", 0.0))
					drag_frame = _frame_from_x(event.position.x)
					frame_selected.emit(clampi(int(round(dragged_key_time * float(fps))), 0, frame_count))
					queue_redraw()
					accept_event()
					return
				frame_selected.emit(_frame_from_x(event.position.x))
			accept_event()
			return
		if dragging_keyframe:
			var final_frame := _frame_from_x(event.position.x)
			keyframe_moved.emit(dragged_track, dragged_key_time, final_frame)
			dragging_keyframe = false
			dragged_track = -1
			queue_redraw()
			accept_event()
			return
	if event is InputEventMouseMotion and dragging_keyframe:
		drag_frame = _frame_from_x(event.position.x)
		queue_redraw()
		accept_event()

func _frame_from_x(x: float) -> int:
	var amount := (x - LABEL_WIDTH) / maxf(1.0, size.x - LABEL_WIDTH - RIGHT_MARGIN)
	return clampi(int(round(amount * float(frame_count))), 0, frame_count)

func _find_keyframe_at(track_index: int, position: Vector2) -> int:
	var keyframes: Array = tracks[track_index].get("keyframes", [])
	var row_y := HEADER_HEIGHT + float(track_index) * ROW_HEIGHT + ROW_HEIGHT * 0.5
	if absf(position.y - row_y) > ROW_HEIGHT * 0.5:
		return -1
	var nearest_index := -1
	var nearest_distance := 10.0
	for index in range(keyframes.size()):
		var key_time := float(keyframes[index].get("time", 0.0))
		var key_x := _frame_x(clampi(int(round(key_time * float(fps))), 0, frame_count))
		var distance := absf(position.x - key_x)
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest_index = index
	return nearest_index
