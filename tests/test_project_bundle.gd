extends SceneTree
const BUNDLE=preload("res://scripts/project_bundle_io.gd")
func _initialize():
 var io=BUNDLE.new()
 var manifest={"format":"animation_studio_project_bundle","version":1,"project":{"name":"Test","scenes":[]},"assets":[]}
 assert(io.validate_bundle_manifest(manifest).ok)
 manifest.format="bad"
 assert(not io.validate_bundle_manifest(manifest).ok)
 print("PROJECT_BUNDLE_TESTS_OK")
 quit(0)
