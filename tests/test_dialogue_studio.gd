extends SceneTree

const STUDIO = preload("res://scripts/dialogue_studio.gd")
const SPATIAL_BUILDER = preload("res://scripts/character_spatial_rig_builder.gd")
const SPATIAL_ANIMATOR = preload("res://scripts/character_spatial_animator.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var studio = STUDIO.new()
	var script = studio.create_script("Piloto")
	var line = studio.add_line(script, "Narrador", "Una nueva aventura comienza.", 0.0, 2.5, "char_1")
	if not _check(line.ok, "Debe crear la primera línea"):
		return
	var second_line = studio.add_line(script, "Protagonista", "Estoy listo.", 2.5, 4.0, "char_2")
	if not _check(second_line.ok, "Debe crear la segunda línea"):
		return
	var countdown: Dictionary = studio.create_recording_countdown(3)
	for expected in [2, 1]:
		countdown = studio.advance_recording_countdown(countdown)
		if not _check(countdown.active and countdown.remaining == expected, "La cuenta regresiva debe avanzar"):
			return
	countdown = studio.advance_recording_countdown(countdown)
	if not _check(not countdown.active and countdown.started, "La cuenta debe activar la grabación al llegar a cero"):
		return
	var cancelled: Dictionary = studio.cancel_recording_countdown(studio.create_recording_countdown(3))
	if not _check(cancelled.cancelled and not cancelled.active and not cancelled.started, "Debe poder cancelar la cuenta"):
		return
	if not _check(studio.validate_script(script).ok, "El guion base debe validar"):
		return
	var take = studio.add_take(script, line.line.id, "user://voice/take_01.wav", 2.4, 1, "Toma inicial")
	if not _check(take.ok and studio.validate_audio_track(take.track).ok, "Debe registrar una toma"):
		return
	if not _check(studio.update_take_mix(script, take.track.id, 3.0, 0.25, false).ok, "Debe guardar la mezcla"):
		return
	var takes = studio.get_takes_for_line(script, line.line.id)
	if not _check(takes.size() == 1 and is_equal_approx(float(takes[0].gain_db), 3.0), "Debe devolver la mezcla guardada"):
		return
	if not _check(studio.select_take(script, line.line.id, take.track.id).ok, "Debe seleccionar una toma"):
		return
	print("DIALOGUE_TEST_TAKE_OK")

	var wav := AudioStreamWAV.new()
	wav.mix_rate = 44100
	wav.stereo = false
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.data = PackedByteArray([0,0,1,0,255,255,0,0])
	var record_path := "user://dialogue_recording_roundtrip_test.wav"
	if not _check(wav.save_to_wav(record_path) == OK, "Debe guardar una toma WAV"):
		return
	var saved_bytes := FileAccess.get_file_as_bytes(record_path)
	if not _check(saved_bytes.size() > 44, "El WAV debe contener cabecera y muestras"):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(record_path))
	print("DIALOGUE_TEST_WAV_WRITE_OK")

	var pcm := PackedByteArray()
	for group in range(3):
		var sample_value := 0 if group == 0 else (8000 if group == 1 else 24000)
		for sample_index in range(1000):
			pcm.append(sample_value & 255)
			pcm.append((sample_value >> 8) & 255)
	var viseme_wav := AudioStreamWAV.new()
	viseme_wav.mix_rate = 30000
	viseme_wav.stereo = false
	viseme_wav.format = AudioStreamWAV.FORMAT_16_BITS
	viseme_wav.data = pcm
	var viseme_path := "user://dialogue_viseme_test.wav"
	if not _check(viseme_wav.save_to_wav(viseme_path) == OK, "Debe escribir WAV PCM para visemas"):
		return
	var loaded_wav: AudioStreamWAV = studio.load_pcm_wav(viseme_path)
	if not _check(loaded_wav != null and not loaded_wav.data.is_empty(), "Debe volver a abrir el WAV PCM"):
		return
	var pcm_visemes: Array = studio.build_viseme_track_from_wav(loaded_wav, 0.0, 30.0)
	if not _check(pcm_visemes.size() == 3 and pcm_visemes[0].viseme == "sil" and pcm_visemes[2].viseme == "A", "Debe generar visemas temporizados desde PCM"):
		return
	if not _check(studio.attach_viseme_track(script, line.line.id, pcm_visemes).ok, "Debe asociar visemas a la línea"):
		return
	print("DIALOGUE_TEST_PCM_VISEMES_OK")

	var rig = SPATIAL_BUILDER.new().build_humanoid_3d("VisemeTestRig")
	var skeleton: Skeleton3D = rig.get_node("Skeleton3D")
	var face_mesh := ArrayMesh.new()
	face_mesh.add_blend_shape("viseme_aa")
	face_mesh.add_blend_shape("viseme_oh")
	face_mesh.add_blend_shape("viseme_ee")
	var base_arrays: Array = []
	base_arrays.resize(Mesh.ARRAY_MAX)
	base_arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.UP])
	base_arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK])
	base_arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2])
	var blend_a: Array = base_arrays.duplicate()
	blend_a[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3(1.0,0.2,0.0), Vector3(0.0,1.2,0.0)])
	var blend_o: Array = base_arrays.duplicate()
	blend_o[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3(0.9,0.0,0.0), Vector3(0.0,0.9,0.0)])
	var blend_e: Array = base_arrays.duplicate()
	blend_e[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3(1.1,0.0,0.0), Vector3(0.0,1.1,0.0)])
	face_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, base_arrays, [blend_a, blend_o, blend_e])
	var face := MeshInstance3D.new()
	face.mesh = face_mesh
	rig.add_child(face)
	var animator = SPATIAL_ANIMATOR.new()
	animator.configure(skeleton, null, rig)
	if not _check(animator.apply_viseme("A", 0.75) > 0, "Debe aplicar el blend shape del visema A"):
		return
	if not _check(is_equal_approx(float(face.get_blend_shape_value(0)), 0.75), "Debe respetar intensidad del visema"):
		return
	if not _check(animator.play_viseme_track(pcm_visemes, 0.1, false), "Debe iniciar reproducción temporizada de visemas"):
		return
	animator._process(0.05)
	if not _check(not animator.active_viseme_track.is_empty(), "La pista debe seguir activa antes del final"):
		return
	animator._process(0.1)
	if not _check(animator.active_viseme_track.is_empty(), "La pista debe terminar al alcanzar su duración"):
		return
	animator.stop_animation()
	if not _check(script.lines[0].has("visemes") or script.lines[1].has("visemes"), "La línea debe conservar su pista de visemas"):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(viseme_path))
	print("DIALOGUE_STUDIO_TESTS_OK")
	quit(0)

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
