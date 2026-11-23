extends SceneTree
const BUNDLE=preload("res://scripts/project_bundle_io.gd")
func _initialize():
 var io=BUNDLE.new()
 var manifest={"format":"animation_studio_project_bundle","version":1,"project":{"name":"Test","scenes":[]},"assets":[]}
 assert(io.validate_bundle_manifest(manifest).ok)
 manifest.format="bad"
 assert(not io.validate_bundle_manifest(manifest).ok)
 manifest.format="animation_studio_project_bundle"
 manifest.assets=[{"source_path":"user://safe.png","entry":"assets/safe.png"}]
 assert(io.validate_bundle_manifest(manifest).ok, "Debe aceptar una entrada segura")
 manifest.assets=[{"source_path":"user://safe.png","entry":"assets/../escape.png"}]
 assert(not io.validate_bundle_manifest(manifest).ok, "Debe rechazar traversal en el manifiesto")
 manifest.assets=[{"source_path":"user://safe.png","entry":"assets\\\\escape.png"}]
 assert(not io.validate_bundle_manifest(manifest).ok, "Debe rechazar separadores alternativos")
 manifest.assets=[{"source_path":"user://safe.png","entry":"assets/safe.png"},{"source_path":"user://other.png","entry":"assets/safe.png"}]
 assert(not io.validate_bundle_manifest(manifest).ok, "Debe rechazar entradas duplicadas")
 manifest.assets=[]
 var source="user://bundle_roundtrip_source.asbundle"
 var exported=io.export_bundle(source,{"name":"Roundtrip","width":1920,"height":1080,"fps":60,"scenes":[],"resources":[]})
 assert(exported.ok)
 var imported=io.import_bundle(source,"user://bundle_roundtrip_restored")
 assert(imported.ok)
 assert(str(imported.project.name)=="Roundtrip")
 var missing_export=io.export_bundle("user://bundle_missing_asset.asbundle",{"name":"Broken","resources":[{"id":"missing","path":"user://does_not_exist.png"}]})
 assert(not missing_export.ok)
 var audio_source := "user://bundle_dialogue_audio_%d.wav" % Time.get_ticks_msec()
 var audio_file := FileAccess.open(audio_source, FileAccess.WRITE)
 audio_file.store_buffer(PackedByteArray([82,73,70,70,4,0,0,0,87,65,86,69]))
 audio_file.close()
 var audio_project := {
  "name":"Audio portable",
  "resources":[],
  "dialogue_scripts":[{"id":"script_audio","audio_tracks":[{"id":"take_audio","audio_path":audio_source,"duration":1.0}]}]
 }
 var audio_bundle := "user://bundle_audio_%d.asbundle" % Time.get_ticks_msec()
 var audio_export := io.export_bundle(audio_bundle, audio_project)
 assert(audio_export.ok and audio_export.asset_count == 1, "Debe incluir los audios de doblaje en el paquete")
 var archive_reader := ZIPReader.new()
 assert(archive_reader.open(audio_bundle) == OK)
 var manifest_bytes := archive_reader.read_file("project_manifest.json")
 var audio_manifest: Dictionary = JSON.parse_string(manifest_bytes.get_string_from_utf8())
 assert(audio_manifest.assets[0].sha256.length() == 64 and int(audio_manifest.assets[0].size_bytes) == 12, "El manifiesto debe incluir tamaño y SHA-256")
 var asset_entry := str(audio_manifest.assets[0].entry)
 var original_asset_bytes := archive_reader.read_file(asset_entry)
 archive_reader.close()
 var altered_asset_bytes := original_asset_bytes.duplicate()
 altered_asset_bytes[0] = (int(altered_asset_bytes[0]) + 1) % 256
 var tampered_bundle := "user://bundle_audio_tampered_%d.asbundle" % Time.get_ticks_msec()
 var tampered_writer := ZIPPacker.new()
 assert(tampered_writer.open(tampered_bundle) == OK)
 assert(tampered_writer.start_file("project_manifest.json") == OK)
 assert(tampered_writer.write_file(manifest_bytes) == OK)
 assert(tampered_writer.start_file(asset_entry) == OK)
 assert(tampered_writer.write_file(altered_asset_bytes) == OK)
 tampered_writer.close()
 assert(not io.import_bundle(tampered_bundle, "user://bundle_tampered_restore").ok, "Debe rechazar recursos cuyo SHA-256 no coincide")
 var audio_destination := "user://bundle_audio_restore_%d" % Time.get_ticks_msec()
 var audio_import := io.import_bundle(audio_bundle, audio_destination)
 assert(audio_import.ok, "Debe restaurar el paquete con audio")
 var restored_audio := str(audio_import.project.dialogue_scripts[0].audio_tracks[0].audio_path)
 assert(FileAccess.file_exists(restored_audio), "La ruta de la toma debe actualizarse a su archivo restaurado")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(audio_source))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(restored_audio))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(audio_bundle))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(tampered_bundle))
 print("PROJECT_BUNDLE_TESTS_OK")
 quit(0)
