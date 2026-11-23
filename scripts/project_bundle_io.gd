extends RefCounted
class_name ProjectBundleIO

const FORMAT := "animation_studio_project_bundle"
const VERSION := 1
const MAX_ARCHIVE_FILES := 10000
const MAX_TOTAL_BYTES := 1024 * 1024 * 1024

func export_bundle(path: String, project: Dictionary) -> Dictionary:
 var writer=ZIPWriter.new()
 var error=writer.open(path)
 if error!=OK: return {"ok":false,"error":"No se pudo crear el archivo ZIP: %s" % error}
 var manifest={"format":FORMAT,"version":VERSION,"created_at":Time.get_datetime_string_from_system(true),"project":project.duplicate(true),"assets":[]}
 var seen={}
 var total=0
 for resource in project.get("resources",[]):
  if not resource is Dictionary: continue
  var source=str(resource.get("path",""))
  if source.is_empty() or seen.has(source): continue
  seen[source]=true
  if not FileAccess.file_exists(source): continue
  var bytes=FileAccess.get_file_as_bytes(source)
  if bytes.is_empty(): continue
  total+=bytes.size()
  if total>MAX_TOTAL_BYTES:
   writer.close()
   DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
   return {"ok":false,"error":"El proyecto supera el límite de 1 GB de recursos."}
  var entry="assets/%04d_%s" % [manifest.assets.size(),source.get_file().validate_filename()]
  writer.start_file(entry)
  writer.write_file(bytes)
  manifest.assets.append({"source_path":source,"entry":entry,"resource_id":str(resource.get("id",""))})
 writer.start_file("project_manifest.json")
 writer.write_file(JSON.stringify(manifest,"\t").to_utf8_buffer())
 writer.close()
 return {"ok":true,"asset_count":manifest.assets.size(),"bytes":total,"path":path}

func import_bundle(path: String, destination: String) -> Dictionary:
 var reader=ZIPReader.new()
 var error=reader.open(path)
 if error!=OK: return {"ok":false,"error":"No se pudo abrir el paquete ZIP."}
 var names=reader.get_files()
 if names.size()>MAX_ARCHIVE_FILES or not names.has("project_manifest.json"):
  reader.close()
  return {"ok":false,"error":"Paquete inválido o con demasiados archivos."}
 var parsed=JSON.parse_string(reader.read_file("project_manifest.json").get_string_from_utf8())
 if not parsed is Dictionary or str(parsed.get("format",""))!=FORMAT or int(parsed.get("version",0))!=VERSION:
  reader.close()
  return {"ok":false,"error":"Manifiesto de proyecto incompatible."}
 var project: Variant=parsed.get("project",{})
 if not project is Dictionary:
  reader.close()
  return {"ok":false,"error":"El documento del proyecto está dañado."}
 var base=ProjectSettings.globalize_path(destination)
 if DirAccess.make_dir_recursive_absolute(base)!=OK:
  reader.close()
  return {"ok":false,"error":"No se pudo crear la carpeta de destino."}
 var restored={}
 var total=0
 for item in parsed.get("assets",[]):
  if not item is Dictionary: continue
  var entry=str(item.get("entry",""))
  if not names.has(entry) or not entry.begins_with("assets/") or entry.contains("..") or entry.begins_with("/"):
   reader.close()
   return {"ok":false,"error":"Ruta de recurso no permitida en el paquete."}
  var bytes=reader.read_file(entry)
  total+=bytes.size()
  if total>MAX_TOTAL_BYTES:
   reader.close()
   return {"ok":false,"error":"Los recursos exceden el límite de 1 GB."}
  var filename=entry.get_file().validate_filename()
  var output=destination.path_join(filename)
  var absolute=ProjectSettings.globalize_path(output)
  var file=FileAccess.open(output,FileAccess.WRITE)
  if file==null:
   reader.close()
   return {"ok":false,"error":"No se pudo restaurar un recurso del proyecto."}
  file.store_buffer(bytes)
  file.close()
  restored[str(item.get("source_path",""))]=output
 reader.close()
 for resource in project.get("resources",[]):
  if resource is Dictionary:
   var old=str(resource.get("path",""))
   if restored.has(old): resource["path"]=restored[old]
 return {"ok":true,"project":project,"asset_count":restored.size(),"bytes":total,"restored_paths":restored}

func validate_bundle_manifest(manifest: Dictionary) -> Dictionary:
 if str(manifest.get("format",""))!=FORMAT or int(manifest.get("version",0))!=VERSION:
  return {"ok":false,"error":"Formato o versión de paquete inválida."}
 if not manifest.get("project",{}) is Dictionary or not manifest.get("assets",[]) is Array:
  return {"ok":false,"error":"Manifiesto incompleto."}
 return {"ok":true}
