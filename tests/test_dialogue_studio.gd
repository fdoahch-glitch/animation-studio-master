extends SceneTree
const STUDIO=preload("res://scripts/dialogue_studio.gd")
func _initialize():
 var studio=STUDIO.new()
 var script=studio.create_script("Piloto")
 var line=studio.add_line(script,"Narrador","Una nueva aventura comienza.",0.0,2.5,"char_1")
 assert(line.ok)
 assert(studio.validate_script(script).ok)
 var take=studio.add_take(script,line.line.id,"user://voice/take_01.wav",2.4,1,"Toma inicial")
 assert(take.ok)
 assert(studio.validate_audio_track(take.track).ok)
 assert(studio.select_take(script,line.line.id,take.track.id).ok)
 var wav := AudioStreamWAV.new()
 wav.mix_rate = 44100
 wav.stereo = false
 wav.format = AudioStreamWAV.FORMAT_16_BITS
 wav.data = PackedByteArray([0,0,1,0,255,255,0,0])
 var wav_path := "user://dialogue_recording_roundtrip_test.wav"
 assert(wav.save_to_wav(wav_path) == OK, "Debe guardar una toma WAV")
 var loaded_wav := AudioStreamWAV.load_from_file(wav_path)
 assert(loaded_wav != null and loaded_wav.data.size() == wav.data.size(), "Debe poder volver a abrir la toma WAV")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(wav_path))
 var visemes=studio.build_viseme_track(PackedVector2Array([Vector2(0.0,0),Vector2(0.4,0),Vector2(0.8,0)]),30)
 assert(visemes.size()==3)
 assert(not studio.add_line(script,"","",0,1).ok)
 print("DIALOGUE_STUDIO_TESTS_OK")
 quit(0)
