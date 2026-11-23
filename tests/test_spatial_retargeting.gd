extends SceneTree

const RETARGET = preload("res://scripts/animation_retargeter.gd")
const BUILDER = preload("res://scripts/character_spatial_rig_builder.gd")
const ANIMATOR = preload("res://scripts/character_spatial_animator.gd")

func _initialize() -> void:
 var retargeter = RETARGET.new()
 var builder = BUILDER.new()
 var source_root: Node3D = builder.build_humanoid_3d("Source")
 var target_root: Node3D = builder.build_humanoid_3d("Target")
 var source: Skeleton3D = source_root.get_node("Skeleton3D")
 assert(builder.validate_skeleton(source, "humanoid").ok)
 assert(not builder.validate_skeleton(source, "bird").ok, "Debe rechazar arquetipos no admitidos")
 var target: Skeleton3D = target_root.get_node("Skeleton3D")
 var report: Dictionary = retargeter.build_bone_map(source,target)
 assert(report.ok)
 assert(report.mapped_count >= 15)
 var profile: Dictionary = retargeter.create_profile(source,target,"Humanoid")
 assert(retargeter.validate_profile(profile).ok)
 var pose := {"Pelvis":[1.0,2.0,3.0],"Head":[10.0,20.0,30.0]}
 var converted: Dictionary = retargeter.retarget_pose(pose,profile.mapping,Vector3(1.0,1.0,1.0),Vector3(0.0,5.0,0.0))
 assert(converted.has("Pelvis") and converted.has("Head"))
 assert(is_equal_approx(float(converted["Head"][1]),25.0))
 var quadruped_root: Node3D = builder.build_quadruped_3d("Dino")
 var quadruped: Skeleton3D = quadruped_root.get_node("Skeleton3D")
 assert(builder.validate_skeleton(quadruped, "quadruped").ok)
 var quad_animator = ANIMATOR.new()
 quad_animator.configure(quadruped)
 assert(quad_animator.generate_pose_library().size() >= 18)
 assert(quad_animator.generate_animation_library().size() == 8)
 assert(quad_animator.play_animation("walk"))
 quad_animator.stop_animation()
 var humanoid_animator = ANIMATOR.new()
 humanoid_animator.configure(source)
 assert(humanoid_animator.generate_pose_library().size() >= 19)
 assert(humanoid_animator.generate_animation_library().size() == 8)
 assert(humanoid_animator.play_animation("run"))
 humanoid_animator.stop_animation()
 var clip := {
  "name": "walk",
  "duration": 1.0,
  "loop": true,
  "keyframes": [
   {"time": 0.0, "bone_rotations_degrees": {"Pelvis": [0.0, 10.0, 0.0], "Spine": [0.0, 0.0, 20.0], "Head": [1.0, 2.0, 3.0]}},
   {"time": 1.0, "bone_rotations_degrees": {"Pelvis": [0.0, 20.0, 0.0], "Spine": [0.0, 0.0, 30.0], "Head": [2.0, 3.0, 4.0]}}
  ]
 }
 var clip_profile := {"name": "Humanoid target", "mapping": {"mixamorig:Hips": "Pelvis", "mixamorig:Spine": "Spine"}}
 var converted_clip_result: Dictionary = retargeter.retarget_animation_clip(clip, clip_profile, Vector3.ONE, Vector3(0.0, 5.0, 0.0))
 assert(converted_clip_result.ok and converted_clip_result.mapped_bone_count == 2, "Debe convertir clips completos usando equivalencias canónicas")
 assert(converted_clip_result.clip.keyframes[0].bone_rotations_degrees.has("Pelvis"), "Debe renombrar el hueso de origen al hueso destino")
 assert(is_equal_approx(float(converted_clip_result.clip.keyframes[0].bone_rotations_degrees.Pelvis[1]), 15.0), "Debe conservar la escala y aplicar el offset de rotación")
 assert(converted_clip_result.unmapped_bones.has("Head"), "Debe informar huesos sin equivalencia")
 assert(clip.keyframes[0].bone_rotations_degrees.has("Pelvis"), "El retargeting no debe modificar el clip original")
 var retargeted_animator = ANIMATOR.new()
 var blend_sample: Dictionary = retargeted_animator.blend_pose({"Pelvis": [0.0, 0.0, 0.0]}, {"Pelvis": [0.0, 90.0, 0.0]}, 0.5)
 assert(is_equal_approx(float(blend_sample.Pelvis[1]), 45.0), "Las poses deben interpolarse suavemente")
 var blended_out: Dictionary = retargeted_animator.blend_pose({"Tail": [0.0, 30.0, 0.0]}, {}, 0.5)
 assert(is_equal_approx(float(blended_out.Tail[1]), 15.0), "Los huesos sin destino deben desvanecerse hacia la pose neutra")
 retargeted_animator.configure(source)
 assert(retargeted_animator.play_clip(converted_clip_result.clip), "El clip retargeteado debe poder reproducirse en un esqueleto compatible")
 assert(retargeted_animator.blend_active, "El cambio de clip debe iniciar el fundido cruzado")
 retargeted_animator._apply_blended_pose(converted_clip_result.clip.keyframes[0].bone_rotations_degrees, 0.09)
 assert(retargeted_animator.blend_active, "El fundido debe permanecer activo durante su duración")
 retargeted_animator._apply_blended_pose(converted_clip_result.clip.keyframes[0].bone_rotations_degrees, 0.1)
 assert(not retargeted_animator.blend_active, "El fundido debe finalizar al completar su duración")
 retargeted_animator.stop_animation()
 assert(not retargeter.retarget_animation_clip({"keyframes": []}, clip_profile).ok, "Debe rechazar clips vacíos")
 source_root.free()
 target_root.free()
 quadruped_root.free()
 print("SPATIAL_RIG_AND_RETARGET_TESTS_OK")
 quit(0)
