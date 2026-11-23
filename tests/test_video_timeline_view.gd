extends SceneTree

const MODEL = preload("res://scripts/video_timeline.gd")
const VIEW = preload("res://scripts/video_timeline_view.gd")

func _initialize() -> void:
	var model = MODEL.new()
	var timeline: Dictionary = model.create_timeline(30)
	var video: Dictionary = model.create_track(timeline, "video", "Vídeo principal").track
	var audio: Dictionary = model.create_track(timeline, "audio", "Voz").track
	assert(model.add_clip(video, "res://shot_a.mp4", 1.0, 5.0).ok)
	assert(model.add_clip(audio, "res://voice.wav", 0.0, 2.0).ok)
	var view = VIEW.new()
	root.add_child(view)
	view.size = Vector2(1000, 160)
	view.configure(timeline, 0.0, 0, 0)
	var moved: Array = []
	view.clip_moved.connect(func(track_index: int, clip_id: String, new_start: float) -> void:
		moved.append({"track": track_index, "id": clip_id, "start": new_start})
	)
	var clip_start := float(video.clips[0].start)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(150.0 + (clip_start + 0.5) * 48.0, 30.0 + 19.0)
	view._gui_input(press)
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(150.0 + (clip_start + 2.5) * 48.0, 30.0 + 19.0)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	view._gui_input(motion)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = motion.position
	view._gui_input(release)
	assert(moved.size() == 1, "Arrastrar un clip debe emitir un único cambio")
	assert(moved[0].track == 0 and moved[0].id == str(video.clips[0].id), "El arrastre debe conservar la pista y el ID del clip")
	assert(is_equal_approx(float(moved[0].start), clip_start + 2.0), "El clip debe moverse manteniendo el punto de agarre")
	view.queue_free()
	print("VIDEO_TIMELINE_VIEW_TESTS_OK")
	quit(0)
