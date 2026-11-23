extends RefCounted
class_name PerformanceAuditor

const DEFAULT_BUDGETS={"scenes":100,"objects_per_scene":500,"resources":2000,"resource_bytes":536870912,"total_project_objects":5000}

func audit_project(project: Dictionary, budgets: Dictionary = {}) -> Dictionary:
 var limits=DEFAULT_BUDGETS.duplicate(true)
 for key in budgets: limits[key]=budgets[key]
 var scenes: Array=project.get("scenes",[])
 var resources: Array=project.get("resources",[])
 var object_total=0
 var max_scene_objects=0
 var scene_report=[]
 for scene in scenes:
  if not scene is Dictionary: continue
  var objects=scene.get("objects",[])
  var count=objects.size() if objects is Array else 0
  object_total+=count
  max_scene_objects=maxi(max_scene_objects,count)
  scene_report.append({"id":str(scene.get("id","")),"name":str(scene.get("name","Escena")),"objects":count,"duration_seconds":float(scene.get("duration_seconds",0.0))})
 var resource_bytes=0
 var missing=[]
 var extensions={}
 for resource in resources:
  if not resource is Dictionary: continue
  var path=str(resource.get("path",""))
  var size=int(resource.get("bytes",0))
  if path!="" and FileAccess.file_exists(path):
   var resource_file=FileAccess.open(path,FileAccess.READ)
   if resource_file!=null:
    size=resource_file.get_length()
    resource_file.close()
  elif path!="":
   missing.append(path)
  resource_bytes+=size
  var ext=str(resource.get("extension",path.get_extension())).to_lower()
  extensions[ext]=int(extensions.get(ext,0))+1
 var warnings=[]
 if scenes.size()>int(limits.scenes): warnings.append("El proyecto supera el presupuesto de escenas.")
 if max_scene_objects>int(limits.objects_per_scene): warnings.append("Una escena supera el presupuesto de objetos.")
 if resources.size()>int(limits.resources): warnings.append("El proyecto supera el presupuesto de recursos.")
 if resource_bytes>int(limits.resource_bytes): warnings.append("Los recursos superan el presupuesto de almacenamiento.")
 if object_total>int(limits.total_project_objects): warnings.append("El total de objetos supera el presupuesto.")
 if not missing.is_empty(): warnings.append("Hay rutas de recursos que no se encuentran.")
 return {"format":"animation_studio_performance_audit","version":1,"project_name":str(project.get("name","Proyecto")),"summary":{"scene_count":scenes.size(),"resource_count":resources.size(),"object_count":object_total,"max_objects_per_scene":max_scene_objects,"resource_bytes":resource_bytes,"missing_resources":missing.size()},"scenes":scene_report,"resource_extensions":extensions,"missing_resources":missing,"budgets":limits,"warnings":warnings,"passed":warnings.is_empty()}

func estimate_texture_memory(width: int, height: int, bytes_per_pixel := 4, mipmaps := true) -> int:
 if width<=0 or height<=0 or bytes_per_pixel<=0: return 0
 var base=width*height*bytes_per_pixel
 return int(ceil(float(base)*1.3333333)) if mipmaps else base

func recommend_render_scale(frame_time_ms: float, target_fps := 60.0, current_scale := 1.0, floor_scale := 0.65) -> float:
 if target_fps<=0.0: return clampf(current_scale,floor_scale,1.0)
 var budget=1000.0/target_fps
 if frame_time_ms>budget*1.08: return maxf(floor_scale,current_scale-0.05)
 if frame_time_ms<budget*0.78: return minf(1.0,current_scale+0.02)
 return clampf(current_scale,floor_scale,1.0)
