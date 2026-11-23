extends SceneTree
const STUDIO=preload("res://scripts/dialogue_studio.gd")
func _initialize():
 var studio=STUDIO.new()
 var script=studio.create_script("Piloto")
 var line=studio.add_line(script,"Narrador","Una nueva aventura comienza.",0.0,2.5,"char_1")
 assert(line.ok)
 var second_line=studio.add_line(script,"Protagonista","Estoy listo.",2.5,4.0,"char_2")
 assert(second_line.ok)
 var countdown: Dictionary = studio.create_recording_countdown(3)
 assert(countdown.active and countdown.remaining == 3 and not countdown.started)
 countdown = studio.advance_recording_countdown(countdown)
 assert(countdown.active and countdown.remaining == 2)
 countdown = studio.advance_recording_countdown(countdown)
 assert(countdown.active and countdown.remaining == 1)
 countdown = studio.advance_recording_countdown(countdown)
 assert(not countdown.active and countdown.remaining == 0 and countdown.started, "La cuenta debe activar la grabación al llegar a cero")
 var cancelled: Dictionary = studio.cancel_recording_countdown(studio.create_recording_countdown(3))
 assert(cancelled.cancelled and not cancelled.active and not cancelled.started)
 assert(studio.validate_script(script).ok)
 var take=studio.add_take(script,line.line.id,"user://voice/take_01.wav",2.4,1,"Toma inicial")
 assert(take.ok)
 assert(studio.validate_audio_track(take.track).ok)
 assert(studio.update_take_mix(script,take.track.id,3.0,0.25,false).ok)
 assert(is_equal_approx(float(take.track.gain_db),0.0), "La actualización de mezcla debe modificar el registro del guion, no la copia de retorno")
 var takes=studio.get_takes_for_line(script,line.line.id)
 assert(takes.size()==1 and is_equal_approx(float(takes[0].gain_db),3.0))
 assert(studio.select_take(script,line.line.id,take.track.id).ok)
 var wav := AudioStreamWAV.new()
 wav.mix_rate = 44100
 wav.stereo = false
 wav.format = AudioStreamWAV.FORMAT_16_BITS
 wav.data = PackedByteArray([0,0,1,0,255,255,0,0])
 var wav_path := "user://dialogue_recording_roundtrip_test.wav"
 assert(wav.save_to_wav(wav_path) == OK, "Debe guardar una toma WAV")
 var saved_bytes := FileAccess.get_file_as_bytes(wav_path)
 assert(saved_bytes.size() > 44, "El archivo WAV guardado debe contener cabecera y muestras")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(wav_path))
 var visemes=studio.build_viseme_track(PackedVector2Array([Vector2(0.0,0),Vector2(0.4,0),Vector2(0.8,0)]),30)
 assert(visemes.size()==3)
 var pcm := PackedByteArray()
 for sample in [0,0,0,8000,8000,8000,24000,24000,24000]:
  pcm.append(int(sample) & 255)
  pcm.append((int(sample) >> 8) & 255)
 var viseme_wav := AudioStreamWAV.new()
 viseme_wav.mix_rate = 90
 viseme_wav.stereo = false
 viseme_wav.format = AudioStreamWAV.FORMAT_16_BITS
 viseme_wav.data = pcm
 var pcm_visemes: Array = studio.build_viseme_track_from_wav(viseme_wav, 1.0, 30.0)
 assert(pcm_visemes.size()==3 and pcm_visemes[0].viseme=="sil" and pcm_visemes[2].viseme=="A", "Debe generar visemas temporizados desde PCM WAV")
 assert(studio.attach_viseme_track(script,line.line.id,pcm_visemes).ok, "Debe asociar visemas a la línea")
 assert(script.lines[0].has("visemes") or script.lines[1].has("visemes"), "La línea debe conservar su pista de visemas")
 assert(not studio.add_line(script,"","",0,1).ok)
 print("DIALOGUE_STUDIO_TESTS_OK")
 quit(0)
