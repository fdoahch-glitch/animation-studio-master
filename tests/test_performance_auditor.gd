extends SceneTree
const AUDITOR=preload("res://scripts/performance_auditor.gd")
func _initialize():
 var auditor=AUDITOR.new()
 var project={"name":"Test","scenes":[{"id":"s1","name":"Escena","objects":[{},{}]}],"resources":[]}
 var report=auditor.audit_project(project)
 assert(report.passed)
 assert(report.summary.object_count==2)
 assert(auditor.estimate_texture_memory(100,100,4,false)==40000)
 assert(is_equal_approx(auditor.recommend_render_scale(30.0,60.0,1.0,0.65),0.95))
 assert(is_equal_approx(auditor.recommend_render_scale(5.0,60.0,0.95,0.65),0.97))
 var constrained=auditor.audit_project(project,{"objects_per_scene":1})
 assert(not constrained.passed and not constrained.warnings.is_empty())
 print("PERFORMANCE_AUDITOR_TESTS_OK")
 quit(0)
