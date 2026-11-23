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

func set_time_preset(environment: Dictionary, preset: String) -> Dictionary:
 if not PRESETS.has(preset): return {"ok":false,"error":"Preset horario desconocido."}
 for key in PRESETS[preset]: environment[key]=PRESETS[preset][key].duplicate(true) if PRESETS[preset][key] is Array else PRESETS[preset][key]
 return {"ok":true}

func set_weather(environment: Dictionary, weather: String, intensity: float) -> Dictionary:
 if not WEATHER_TYPES.has(weather): return {"ok":false,"error":"Tipo de clima desconocido."}
 environment.weather=weather
 environment.weather_intensity=clampf(intensity,0.0,1.0)
 if weather=="fog": environment.fog_density=environment.weather_intensity*0.08
 if weather=="wind": environment.wind_strength=environment.weather_intensity
 return {"ok":true,"particle_profile":get_particle_profile(weather,environment.weather_intensity)}

func get_particle_profile(weather: String, intensity: float) -> Dictionary:
 var amount=clampf(intensity,0.0,1.0)
 var profiles={"rain":{"rate":900.0,"velocity":[0.0, -850.0, -180.0],"size":0.045},"snow":{"rate":260.0,"velocity":[-25.0,-90.0,0.0],"size":0.11},"dust":{"rate":180.0,"velocity":[-70.0,15.0,0.0],"size":0.08},"wind":{"rate":90.0,"velocity":[-240.0,0.0,0.0],"size":0.04},"fog":{"rate":35.0,"velocity":[-8.0,0.0,0.0],"size":0.8}}
 if not profiles.has(weather): return {"enabled":false,"amount":0.0}
 var result: Dictionary=profiles[weather].duplicate(true)
 result.amount=amount
 result.emission_rate=float(result.rate)*amount
 result.enabled=amount>0.001
 return result

func add_keyframe(environment: Dictionary, time_seconds: float, values: Dictionary) -> Dictionary:
 if time_seconds<0.0: return {"ok":false,"error":"El tiempo no puede ser negativo."}
 var allowed=["hour","sun_energy","ambient_energy","weather_intensity","wind_strength","fog_density"]
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
  if after.values.has(key):
   result[key]=lerpf(float(before.values[key]),float(after.values[key]),amount)
 return result

func validate_environment(environment: Dictionary) -> Dictionary:
 for key in ["id","name","hour","weather","background_layers","keyframes"]:
  if not environment.has(key): return {"ok":false,"error":"Falta campo ambiental: "+key}
 if not WEATHER_TYPES.has(str(environment.weather)): return {"ok":false,"error":"Clima inválido."}
 if float(environment.hour)<0.0 or float(environment.hour)>=24.0: return {"ok":false,"error":"La hora debe estar entre 0 y 24."}
 for layer in environment.background_layers:
  if not layer is Dictionary or str(layer.get("resource_id","")).is_empty(): return {"ok":false,"error":"Capa parallax inválida."}
 return {"ok":true}
