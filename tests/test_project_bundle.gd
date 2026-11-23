extends SceneTree
const BUNDLE=preload("res://scripts/project_bundle_io.gd")
func _initialize():
 var io=BUNDLE.new()
 var manifest={"format":"animation_studio_project_bundle","version":1,"project":{"name":"Test","scenes":[]},"assets":[]}
 assert(io.validate_bundle_manifest(manifest).ok)
 manifest.format="bad"
 assert(not io.validate_bundle_manifest(manifest).ok)
 var source="user://bundle_roundtrip_source.asbundle"
 var exported=io.export_bundle(source,{"name":"Roundtrip","width":1920,"height":1080,"fps":60,"scenes":[],"resources":[]})
 assert(exported.ok)
 var imported=io.import_bundle(source,"user://bundle_roundtrip_restored")
 assert(imported.ok)
 assert(str(imported.project.name)=="Roundtrip")
 var missing_export=io.export_bundle("user://bundle_missing_asset.asbundle",{"name":"Broken","resources":[{"id":"missing","path":"user://does_not_exist.png"}]})
 assert(not missing_export.ok)
 print("PROJECT_BUNDLE_TESTS_OK")
 quit(0)
