extends RefCounted
class_name DialogueStudio

func create_script(title := "Nuevo guion") -> Dictionary:
 return {"id":"script_%d" % Time.get_ticks_msec(),"title":title,"language":"es-CL","lines":[],"audio_tracks":[],"duration":0.0}

func add_line(script: Dictionary, speaker: String, text: String, start: float, end: float, character_id := "") -> Dictionary:
 var clean=text.strip_edges()
 if clean.is_empty() or speaker.strip_edges().is_empty(): return {"ok":false,"error":"Cada diálogo necesita personaje/locutor y texto."}
 if start<0.0 or end<=start: return {"ok":false,"error":"El intervalo del subtítulo no es válido."}
 var line={"id":"line_%d" % Time.get_ticks_msec(),"speaker":speaker.strip_edges(),"character_id":character_id,"text":clean,"start":start,"end":end}
 script.setdefault("lines",[]).append(line)
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
 script.setdefault("audio_tracks",[]).append(track)
 return {"ok":true,"track":track}

func select_take(script: Dictionary, line_id: String, take_id: String) -> Dictionary:
 var found=false
 for track in script.get("audio_tracks",[]):
  if str(track.get("line_id",""))==line_id:
   track["selected"]=str(track.get("id",""))==take_id
   found=found or bool(track.selected)
 return {"ok":found,"error":"" if found else "No se encontró la toma."}

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
 return {"ok":true}
