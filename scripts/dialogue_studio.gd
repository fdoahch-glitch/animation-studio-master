extends RefCounted
class_name DialogueStudio

func create_recording_countdown(seconds: int = 3) -> Dictionary:
 var duration := clampi(seconds, 1, 10)
 return {"active": true, "remaining": duration, "started": false, "cancelled": false}

func advance_recording_countdown(state: Dictionary) -> Dictionary:
 var result := state.duplicate(true)
 if not bool(result.get("active", false)):
  return result
 result["remaining"] = maxi(0, int(result.get("remaining", 0)) - 1)
 result["active"] = int(result["remaining"]) > 0
 result["started"] = int(result["remaining"]) == 0
 return result

func cancel_recording_countdown(state: Dictionary) -> Dictionary:
 var result := state.duplicate(true)
 result["active"] = false
 result["remaining"] = 0
 result["started"] = false
 result["cancelled"] = true
 return result

func create_script(title := "Nuevo guion") -> Dictionary:
 return {"id":"script_%d" % Time.get_ticks_msec(),"title":title,"language":"es-CL","lines":[],"audio_tracks":[],"duration":0.0}

func add_line(script: Dictionary, speaker: String, text: String, start: float, end: float, character_id := "") -> Dictionary:
 var clean=text.strip_edges()
 if clean.is_empty() or speaker.strip_edges().is_empty(): return {"ok":false,"error":"Cada diálogo necesita personaje/locutor y texto."}
 if start<0.0 or end<=start: return {"ok":false,"error":"El intervalo del subtítulo no es válido."}
 var line={"id":"line_%d" % Time.get_ticks_msec(),"speaker":speaker.strip_edges(),"character_id":character_id,"text":clean,"start":start,"end":end}
 if not script.has("lines"): script["lines"]=[]
 script["lines"].append(line)
 script.lines.sort_custom(func(a,b): return float(a.start)<float(b.start))
 script.duration=maxf(float(script.get("duration",0.0)),end)
 return {"ok":true,"line":line}

func validate_script(script: Dictionary) -> Dictionary:
 var lines: Array=script.get("lines",[])
 var previous_start=-1.0
 for line in lines:
  if not line is Dictionary: return {"ok":false,"error":"Línea de guion inválida."}
  if str(line.get("text","")).strip_edges().is_empty(): return {"ok":false,"error":"Hay un subtítulo vacío."}
  var start=float(line.get("start",-1.0))
  var end=float(line.get("end",-1.0))
  if start<0.0 or end<=start: return {"ok":false,"error":"Hay un intervalo temporal inválido."}
  if start<previous_start: return {"ok":false,"error":"Las líneas no están ordenadas."}
  previous_start=start
 return {"ok":true,"line_count":lines.size(),"duration":float(script.get("duration",0.0))}

func add_take(script: Dictionary, line_id: String, audio_path: String, duration: float, take_number := 1, note := "") -> Dictionary:
 if line_id.is_empty() or audio_path.is_empty() or duration<=0.0: return {"ok":false,"error":"Toma incompleta."}
 var track={"id":"take_%d_%d" % [Time.get_ticks_msec(),take_number],"line_id":line_id,"audio_path":audio_path,"duration":duration,"take_number":take_number,"note":note,"muted":false,"gain_db":0.0,"offset":0.0}
 if not script.has("audio_tracks"): script["audio_tracks"]=[]
 script["audio_tracks"].append(track)
 return {"ok":true,"track":track}

func select_take(script: Dictionary, line_id: String, take_id: String) -> Dictionary:
 var found=false
 for track in script.get("audio_tracks",[]):
  if str(track.get("line_id",""))==line_id:
   track["selected"]=str(track.get("id",""))==take_id
   found=found or bool(track.selected)
 return {"ok":found,"error":"" if found else "No se encontró la toma."}

func update_take_mix(script: Dictionary, take_id: String, gain_db: float, offset: float, muted: bool) -> Dictionary:
 for index in range(script.get("audio_tracks", []).size()):
  var track: Dictionary = script["audio_tracks"][index]
  if str(track.get("id", "")) != take_id:
   continue
  track["gain_db"] = clampf(gain_db, -60.0, 12.0)
  track["offset"] = clampf(offset, 0.0, maxf(0.0, float(track.get("duration", 0.0))))
  track["muted"] = muted
  script["audio_tracks"][index] = track
  return {"ok": true, "track": track}
 return {"ok": false, "error": "No se encontró la toma de audio."}

func get_takes_for_line(script: Dictionary, line_id: String) -> Array:
 var result: Array = []
 for track in script.get("audio_tracks", []):
  if str(track.get("line_id", "")) == line_id:
   result.append(track.duplicate(true))
 result.sort_custom(func(a, b): return int(a.get("take_number", 0)) < int(b.get("take_number", 0)))
 return result

func attach_viseme_track(script: Dictionary, line_id: String, visemes: Array) -> Dictionary:
 for index in range(script.get("lines", []).size()):
  var line: Dictionary = script["lines"][index]
  if str(line.get("id", "")) != line_id:
   continue
  line["visemes"] = visemes.duplicate(true)
  script["lines"][index] = line
  return {"ok": true, "viseme_count": visemes.size()}
 return {"ok": false, "error": "No se encontró la línea de diálogo."}

func load_pcm_wav(path: String) -> AudioStreamWAV:
 var file := FileAccess.open(path, FileAccess.READ)
 if file == null or file.get_length() < 44:
  if file != null:
   file.close()
  return null
 if file.get_buffer(4).get_string_from_ascii() != "RIFF":
  file.close()
  return null
 file.get_32()
 if file.get_buffer(4).get_string_from_ascii() != "WAVE":
  file.close()
  return null
 var audio_format := 0
 var channels := 0
 var sample_rate := 0
 var bits_per_sample := 0
 var pcm_data := PackedByteArray()
 while file.get_position() + 8 <= file.get_length():
  var chunk_id := file.get_buffer(4).get_string_from_ascii()
  var chunk_size := int(file.get_32())
  var remaining := file.get_length() - file.get_position()
  if chunk_size < 0 or chunk_size > remaining:
   file.close()
   return null
  if chunk_id == "fmt ":
   if chunk_size < 16:
    file.close()
    return null
   audio_format = int(file.get_16())
   channels = int(file.get_16())
   sample_rate = int(file.get_32())
   file.get_32()
   file.get_16()
   bits_per_sample = int(file.get_16())
   var extra := chunk_size - 16
   if extra > 0:
    file.seek(file.get_position() + extra)
  elif chunk_id == "data" and pcm_data.is_empty():
   pcm_data = file.get_buffer(chunk_size)
  else:
   file.seek(file.get_position() + chunk_size)
  if chunk_size % 2 == 1 and file.get_position() < file.get_length():
   file.seek(file.get_position() + 1)
 file.close()
 if audio_format != 1 or channels < 1 or channels > 2 or sample_rate <= 0 or pcm_data.is_empty():
  return null
 var stream := AudioStreamWAV.new()
 stream.mix_rate = sample_rate
 stream.stereo = channels == 2
 if bits_per_sample == 16:
  if pcm_data.size() % (channels * 2) != 0:
   return null
  stream.format = AudioStreamWAV.FORMAT_16_BITS
  stream.data = pcm_data
 elif bits_per_sample == 8:
  if pcm_data.size() % channels != 0:
   return null
  var signed_pcm := PackedByteArray()
  signed_pcm.resize(pcm_data.size())
  for index in range(pcm_data.size()):
   var signed_value := int(pcm_data[index]) - 128
   if signed_value < 0:
    signed_value += 256
   signed_pcm[index] = signed_value
  stream.format = AudioStreamWAV.FORMAT_8_BITS
  stream.data = signed_pcm
 else:
  return null
 return stream

func build_viseme_track_from_wav(audio: AudioStreamWAV, start_time: float = 0.0, frame_rate: float = 30.0) -> Array:
 var result: Array = []
 if not is_instance_valid(audio) or audio.mix_rate <= 0 or frame_rate <= 0.0:
  return result
 var bytes_per_sample := 2 if audio.format == AudioStreamWAV.FORMAT_16_BITS else (1 if audio.format == AudioStreamWAV.FORMAT_8_BITS else 0)
 if bytes_per_sample == 0:
  return result
 var pcm_data: PackedByteArray = audio.data
 var channels := 2 if audio.stereo else 1
 var frame_stride := bytes_per_sample * channels
 var sample_count := int(pcm_data.size() / frame_stride)
 if sample_count <= 0:
  return result
 var samples_per_frame := maxi(1, int(round(float(audio.mix_rate) / frame_rate)))
 var frame_index := 0
 for sample_start in range(0, sample_count, samples_per_frame):
  var sample_end := mini(sample_count, sample_start + samples_per_frame)
  var peak := 0.0
  var total_square := 0.0
  var count := 0
  for sample_index in range(sample_start, sample_end):
   for channel in range(channels):
    var byte_index := sample_index * frame_stride + channel * bytes_per_sample
    var amplitude := 0.0
    if bytes_per_sample == 2:
     var raw := int(pcm_data[byte_index]) | (int(pcm_data[byte_index + 1]) << 8)
     if raw >= 32768:
      raw -= 65536
     amplitude = float(raw) / 32768.0
    else:
     var raw_8 := int(pcm_data[byte_index])
    if raw_8 >= 128:
     raw_8 -= 256
    amplitude = float(raw_8) / 128.0
    var absolute := absf(amplitude)
    peak = maxf(peak, absolute)
    total_square += amplitude * amplitude
    count += 1
  var rms := sqrt(total_square / float(maxi(1, count)))
  var viseme := "sil" if peak < 0.025 else ("A" if rms >= 0.48 else ("O" if rms >= 0.24 else "E"))
  result.append({"time": start_time + float(frame_index) / frame_rate, "viseme": viseme, "weight": clampf(peak * 1.7, 0.0, 1.0), "rms": rms})
  frame_index += 1
 return result

func build_viseme_track(samples: PackedVector2Array, sample_rate: int, start_time := 0.0, frame_rate := 30.0) -> Array:
 var result: Array=[]
 if sample_rate<=0 or frame_rate<=0.0: return result
 var window=maxi(1,int(float(sample_rate)/frame_rate))
 var frame=0
 for offset in range(0,samples.size(),window):
  var peak=0.0
  var finish=mini(samples.size(),offset+window)
  for i in range(offset,finish): peak=maxf(peak,absf(samples[i].x))
  var viseme="sil" if peak<0.025 else ("A" if peak>0.48 else ("O" if peak>0.24 else "E"))
  result.append({"time":start_time+float(frame)/frame_rate,"viseme":viseme,"weight":clampf(peak*1.7,0.0,1.0)})
  frame+=1
 return result

func validate_audio_track(track: Dictionary) -> Dictionary:
 if str(track.get("id","")).is_empty() or str(track.get("line_id","")).is_empty(): return {"ok":false,"error":"La pista no está vinculada a un diálogo."}
 if float(track.get("duration",0.0))<=0.0: return {"ok":false,"error":"La duración de audio debe ser positiva."}
 if not track.has("gain_db") or not track.has("offset"): return {"ok":false,"error":"Faltan controles de mezcla."}
 if not is_finite(float(track.get("gain_db", 0.0))) or float(track.get("gain_db", 0.0)) < -60.0 or float(track.get("gain_db", 0.0)) > 12.0: return {"ok":false,"error":"La ganancia debe estar entre -60 y +12 dB."}
 if not is_finite(float(track.get("offset", 0.0))) or float(track.get("offset", 0.0)) < 0.0: return {"ok":false,"error":"El offset de audio no puede ser negativo."}
 return {"ok":true}
