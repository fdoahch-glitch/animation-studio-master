extends RefCounted
class_name EnvironmentDirector

const WEATHER_TYPES := ["clear", "rain", "snow", "fog", "wind", "dust"]
const TIMES := ["dawn", "morning", "noon", "afternoon", "sunset", "night"]

const PRESETS := {
 "dawn":{"hour":6.0,"sun_energy":0.55,"ambient_energy":0.72,"sun_color":[1.0,0.66,0.43],"sky_color":[0.35,0.42,0.62]},
 "morning":{"hour":9.0,"sun_energy":0.9,"ambient_energy":0.85,"sun_color":[1.0,0.91,0.76],"sky_color":[0.43,0.68,0.88]},
 "noon":{"hour":12.0,"sun_energy":1.15,"ambient_energy":1.0,"sun_color":[1.0,0.98,0.9],"sky_color":[0.36,0.66,0.96]},
 "afternoon":{"hour":16.0,"sun_energy":0.95,"ambient_energy":0.9,"sun_color":[1.0,0.77,0.52],"sky_color":[0.55,0.63,0.8]},
 "sunset":{"hour":19.0,"sun_energy":0.62,"ambient_energy":0.68,"sun_color":[1.0,0.39,0.22],"sky_color":[0.26,0.28,0.48]},
 "night":{"hour":23.0,"sun_energy":0.12,"ambient_energy":0.32,"sun_color":[0.3,0.38,0.62],"sky_color":[0.035,0.055,0.12]}
}

func create_environment(name := "Escenario") -> Dictionary:
 return {"id":"environment_%d" % Time.get_ticks_msec(),"name":name,"background_layers":[],"hour":12.0,"sun_energy":1.0,"ambient_energy":1.0,"sun_color":[1.0,0.96,0.86],"sky_color":[0.35,0.62,0.9],"weather":"clear","weather_intensity":0.0,"wind_strength":0.0,"fog_density":0.0,"particles_enabled":true,"keyframes":[]}

func add_background_layer(environment: Dictionary, resource_id: String, depth: float, parallax: float, opacity := 1.0) -> Dictionary:
 if resource_id.strip_edges().is_empty(): return {"ok":false,"error":"Selecciona un recurso de fondo."}
 var layer={"id":"layer_%d" % Time.get_ticks_msec(),"resource_id":resource_id,"depth":depth,"parallax":clampf(parallax,0.0,2.0),"opacity":clampf(opacity,0.0,1.0),"visible":true}
 if not environment.has("background_layers"): environment["background_layers"]=[]
 environment["background_layers"].append(layer)
 environment.background_layers.sort_custom(func(a,b): return float(a.depth)<float(b.depth))
 return {"ok":true,"layer":layer}

func set_hour(environment: Dictionary, hour: float) -> Dictionary:
 if not is_finite(hour):
  return {"ok":false,"error":"La hora debe ser finita."}
 var normalized_hour := fposmod(hour, 24.0)
 var points := [
  {"hour":6.0,"preset":"dawn"},
  {"hour":9.0,"preset":"morning"},
  {"hour":12.0,"preset":"noon"},
  {"hour":16.0,"preset":"afternoon"},
  {"hour":19.0,"preset":"sunset"},
  {"hour":23.0,"preset":"night"},
  {"hour":30.0,"preset":"dawn"}
 ]
 var sample_hour := normalized_hour + 24.0 if normalized_hour < 6.0 else normalized_hour
 var left: Dictionary = points[0]
 var right: Dictionary = points[-1]
 for index in range(points.size() - 1):
  if sample_hour >= float(points[index].hour) and sample_hour <= float(points[index + 1].hour):
   left = points[index]
   right = points[index + 1]
   break
 var first: Dictionary = PRESETS[str(left.preset)]
 var second: Dictionary = PRESETS[str(right.preset)]
 var span := float(right.hour) - float(left.hour)
 var amount := clampf((sample_hour - float(left.hour)) / span, 0.0, 1.0) if span > 0.0001 else 0.0
 environment["hour"] = normalized_hour
 for key in ["sun_energy", "ambient_energy"]:
  environment[key] = lerpf(float(first[key]), float(second[key]), amount)
 for key in ["sun_color", "sky_color"]:
  var a: Array = first[key]
  var b: Array = second[key]
  environment[key] = [lerpf(float(a[0]), float(b[0]), amount), lerpf(float(a[1]), float(b[1]), amount), lerpf(float(a[2]), float(b[2]), amount)]
 return {"ok":true,"hour":normalized_hour,"from":str(left.preset),"to":str(right.preset),"blend":amount}

func set_time_preset(environment: Dictionary, preset: String) -> Dictionary:
 if not PRESETS.has(preset): return {"ok":false,"error":"Preset horario desconocido."}
 for key in PRESETS[preset]: environment[key]=PRESETS[preset][key].duplicate(true) if PRESETS[preset][key] is Array else PRESETS[preset][key]
 return {"ok":true}

func set_weather(environment: Dictionary, weather: String, intensity: float) -> Dictionary:
 if not WEATHER_TYPES.has(weather):
  return {"ok":false,"error":"Tipo de clima no válido."}
 var value := 0.0 if weather == "clear" else clampf(intensity, 0.0, 1.0)
 environment["weather"] = weather
 environment["weather_intensity"] = value
 environment["wind_strength"] = 0.0
 environment["fog_density"] = 0.0
 if weather == "wind" or weather == "dust":
  environment["wind_strength"] = value
 if weather == "fog":
  environment["fog_density"] = value
 return {"ok":true,"weather":weather,"intensity":value}


func get_particle_profile(weather: String, intensity: float) -> Dictionary:
 var amount=clampf(intensity,0.0,1.0)
 var profiles={"rain":{"rate":900.0,"velocity":[0.0, -850.0, -180.0],"size":0.045},"snow":{"rate":260.0,"velocity":[-25.0,-90.0,0.0],"size":0.11},"dust":{"rate":180.0,"velocity":[-70.0,15.0,0.0],"size":0.08},"wind":{"rate":90.0,"velocity":[-240.0,0.0,0.0],"size":0.04},"fog":{"rate":35.0,"velocity":[-8.0,0.0,0.0],"size":0.8}}
 if not profiles.has(weather): return {"enabled":false,"amount":0.0}
 var result: Dictionary=profiles[weather].duplicate(true)
 result.amount=amount
 result.emission_rate=float(result.rate)*amount
 result.enabled=amount>0.001
 return result

func set_lighting(environment: Dictionary, sun_energy: float, ambient_energy: float, sun_color: Color, sky_color: Color) -> Dictionary:
 environment["sun_energy"] = clampf(sun_energy, 0.0, 1.5)
 environment["ambient_energy"] = clampf(ambient_energy, 0.0, 1.5)
 environment["sun_color"] = [sun_color.r, sun_color.g, sun_color.b]
 environment["sky_color"] = [sky_color.r, sky_color.g, sky_color.b]
 return {"ok": true}

func update_background_layer(environment: Dictionary, layer_id: String, values: Dictionary) -> Dictionary:
 var layers: Array = environment.get("background_layers", [])
 for index in range(layers.size()):
  var layer: Dictionary = layers[index]
  if str(layer.get("id", "")) != layer_id:
   continue
  if values.has("depth"): layer["depth"] = clampf(float(values.depth), -10000.0, 10000.0)
  if values.has("parallax"): layer["parallax"] = clampf(float(values.parallax), 0.0, 2.0)
  if values.has("opacity"): layer["opacity"] = clampf(float(values.opacity), 0.0, 1.0)
  if values.has("visible"): layer["visible"] = bool(values.visible)
  layers[index] = layer
  layers.sort_custom(func(a, b): return float(a.get("depth", 0.0)) < float(b.get("depth", 0.0)))
  environment["background_layers"] = layers
  return {"ok": true, "layer": layer}
 return {"ok": false, "error": "No se encontró la capa ambiental."}

func remove_background_layer(environment: Dictionary, layer_id: String) -> Dictionary:
 var layers: Array = environment.get("background_layers", [])
 var before := layers.size()
 layers = layers.filter(func(layer): return str(layer.get("id", "")) != layer_id)
 environment["background_layers"] = layers
 return {"ok": layers.size() < before, "error": "" if layers.size() < before else "No se encontró la capa ambiental."}

func remove_keyframe(environment: Dictionary, time_seconds: float) -> Dictionary:
 var frames: Array = environment.get("keyframes", [])
 var before := frames.size()
 frames = frames.filter(func(frame): return not is_equal_approx(float(frame.get("time", -1.0)), time_seconds))
 environment["keyframes"] = frames
 return {"ok": frames.size() < before, "error": "" if frames.size() < before else "No se encontró el keyframe."}

func add_keyframe(environment: Dictionary, time_seconds: float, values: Dictionary) -> Dictionary:
 if time_seconds<0.0: return {"ok":false,"error":"El tiempo no puede ser negativo."}
 var allowed=["hour","sun_energy","ambient_energy","weather_intensity","wind_strength","fog_density","sun_color","sky_color"]
 var clean={}
 for key in values:
  if allowed.has(str(key)): clean[key]=values[key]
 if clean.is_empty(): return {"ok":false,"error":"No hay propiedades ambientales válidas."}
 var frames: Array=environment.get("keyframes",[])
 for i in range(frames.size()):
  if is_equal_approx(float(frames[i].time),time_seconds):
   frames[i]={"time":time_seconds,"values":clean}
   environment.keyframes=frames
   return {"ok":true,"replaced":true}
 frames.append({"time":time_seconds,"values":clean})
 frames.sort_custom(func(a,b): return float(a.time)<float(b.time))
 environment.keyframes=frames
 return {"ok":true,"replaced":false}

func sample_environment(environment: Dictionary, time_seconds: float) -> Dictionary:
 var frames: Array=environment.get("keyframes",[])
 if frames.is_empty(): return environment.duplicate(true)
 var before: Dictionary=frames[0]
 var after: Dictionary=frames[-1]
 for frame in frames:
  if float(frame.time)<=time_seconds: before=frame
  if float(frame.time)>=time_seconds:
   after=frame
   break
 var result=environment.duplicate(true)
 var span=float(after.time)-float(before.time)
 var amount=0.0 if span<=0.0 else clampf((time_seconds-float(before.time))/span,0.0,1.0)
 for key in before.values:
  if not after.values.has(key):
   continue
  var first: Variant = before.values[key]
  var second: Variant = after.values[key]
  if first is Array and second is Array and first.size() >= 3 and second.size() >= 3:
   result[key] = [
    lerpf(float(first[0]), float(second[0]), amount),
    lerpf(float(first[1]), float(second[1]), amount),
    lerpf(float(first[2]), float(second[2]), amount)
   ]
  elif first is int or first is float:
   if second is int or second is float:
    result[key] = lerpf(float(first), float(second), amount)
  elif amount >= 0.5:
   result[key] = second
 return result

func validate_environment(environment: Dictionary) -> Dictionary:
 for key in ["id","name","hour","weather","background_layers","keyframes"]:
  if not environment.has(key): return {"ok":false,"error":"Falta campo ambiental: "+key}
 if not WEATHER_TYPES.has(str(environment.weather)): return {"ok":false,"error":"Clima inválido."}
 if float(environment.hour)<0.0 or float(environment.hour)>=24.0: return {"ok":false,"error":"La hora debe estar entre 0 y 24."}
 for layer in environment.background_layers:
  if not layer is Dictionary or str(layer.get("resource_id","")).is_empty(): return {"ok":false,"error":"Capa parallax inválida."}
 return {"ok":true}
