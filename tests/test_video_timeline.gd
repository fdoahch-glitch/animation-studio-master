extends SceneTree

const MODEL = preload("res://scripts/video_timeline.gd")

func _initialize() -> void:
	var model = MODEL.new()
	var timeline: Dictionary = model.create_timeline(30)
	var video: Dictionary = model.create_track(timeline, "video", "Vídeo principal").track
	var audio: Dictionary = model.create_track(timeline, "audio").track
	assert(model.add_clip(video, "res://shot_a.mp4", 0.0, 8.0).ok)
	var original: Dictionary = video.clips[0]
	assert(model.move_clip(video, original.id, 1.0).ok)
	assert(is_equal_approx(float(video.clips[0].start), 1.0))
	assert(model.trim_clip(video, original.id, 2.0, 7.0).ok)
	assert(is_equal_approx(float(video.clips[0].source_in), 1.0))
	assert(is_equal_approx(float(video.clips[0].duration), 5.0))
	var split: Dictionary = model.split_clip(video, original.id, 4.0)
	assert(split.ok)
	assert(video.clips.size() == 2)
	assert(is_equal_approx(float(video.clips[1].source_in), 3.0))
	var duplicate: Dictionary = model.duplicate_clip(video, str(split.right.id), 12.0)
	assert(duplicate.ok and video.clips.size() == 3)
	assert(model.add_clip(audio, "res://voice.wav", 0.5, 3.0, {"volume": 0.8}).ok)
	assert(is_equal_approx(model.timeline_duration(timeline), 17.0))
	assert(is_equal_approx(model.snap_time(1.01, 30), 1.0))
	assert(model.validate_timeline(timeline).ok)
	audio.locked = true
	assert(not model.remove_clip(audio, str(audio.clips[0].id)))
	print("VIDEO_TIMELINE_TESTS_OK")
	quit(0)
