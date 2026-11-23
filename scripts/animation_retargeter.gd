extends RefCounted
class_name AnimationRetargeter

## Retargeting local: equivalencias anatómicas y transferencia de poses entre Skeleton3D.

const ALIASES := {
 "Root":["root","armature","master","scene"],
 "Pelvis":["pelvis","hips","hip"],
 "Spine":["spine","spine0","spine1"],
 "Chest":["chest","spine2","upperchest"],
 "Neck":["neck"], "Head":["head"],
 "Jaw":["jaw","jawbone","lowerjaw","mandible"],
 "Shoulder_L":["leftshoulder","shoulderleft","leftupperarm","upperarmleft","leftarm"],
 "Elbow_L":["leftelbow","elbowleft","leftforearm","forearmleft","leftlowerarm"],
 "Wrist_L":["leftwrist","wristleft","lefthand","handleft"],
 "Shoulder_R":["rightshoulder","shoulderright","rightupperarm","upperarmright","rightarm"],
 "Elbow_R":["rightelbow","elbowright","rightforearm","forearmright","rightlowerarm"],
 "Wrist_R":["rightwrist","wristright","righthand","handright"],
 "Hip_L":["lefthip","hipleft","leftupleg","leftthigh","thighleft","upperlegleft"],
 "Knee_L":["leftknee","kneeleft","leftleg","leftcalf","calfleft","lowerlegleft"],
 "Ankle_L":["leftankle","ankleleft","leftfoot","footleft"],
 "Hip_R":["righthip","hipright","rightupleg","rightthigh","thighright","upperlegright"],
 "Knee_R":["rightknee","kneeright","rightleg","rightcalf","calfright","lowerlegright"],
 "Ankle_R":["rightankle","ankleright","rightfoot","footright"],
 "FrontHip_L":["leftfrontleg","frontlegleft","frontshoulderleft","fronthipleft"],
 "FrontKnee_L":["leftfrontknee","frontkneeleft","leftfrontlowerleg"],
 "FrontAnkle_L":["leftfrontfoot","frontfootleft","frontankleleft"],
 "FrontHip_R":["rightfrontleg","frontrighleg","frontshoulderright","fronthipright"],
 "FrontKnee_R":["rightfrontknee","frontkneeright","rightfrontlowerleg"],
 "FrontAnkle_R":["rightfrontfoot","frontfootright","frontankleright"],
 "BackHip_L":["leftbackleg","backlegleft","backhipleft","leftbackhip"],
 "BackKnee_L":["leftbackknee","backkneeleft","leftbacklowerleg"],
 "BackAnkle_L":["leftbackfoot","backfootleft","backankleleft"],
 "BackHip_R":["rightbackleg","backlegright","backhipright","rightbackhip"],
 "BackKnee_R":["rightbackknee","backkneeright","rightbacklowerleg"],
 "BackAnkle_R":["rightbackfoot","backfootright","backankleright"],
 "Tail_01":["tail1","tailbase","tailroot","tail"],
 "Tail_02":["tail2","tailmid1"],
 "Tail_03":["tail3","tailmid2"],
 "Tail_04":["tail4","tailtip"]
}

func normalize_bone_name(value: String) -> String:
 var result := value.to_lower()
 for token in ["mixamorig:", "mixamorig", "armature|", "_", " ", "-", ":", ".", "|"]:
  result = result.replace(token, "")
 return result

func canonical_name(value: String) -> String:
 var normalized := normalize_bone_name(value)
 for canonical in ALIASES:
  if normalized == normalize_bone_name(canonical) or ALIASES[canonical].has(normalized):
   return str(canonical)
 return ""

func build_bone_map(source: Skeleton3D, target: Skeleton3D) -> Dictionary:
 if not is_instance_valid(source) or not is_instance_valid(target):
  return {"ok":false,"error":"Se necesitan esqueletos de origen y destino válidos."}
 var target_by_canonical := {}
 for index in range(target.get_bone_count()):
  var target_name := target.get_bone_name(index)
  var canonical := canonical_name(target_name)
  if canonical != "" and not target_by_canonical.has(canonical):
   target_by_canonical[canonical] = target_name
 var mapping := {}
 var unmapped: Array[String] = []
 for index in range(source.get_bone_count()):
  var source_name := source.get_bone_name(index)
  var canonical := canonical_name(source_name)
  if canonical != "" and target_by_canonical.has(canonical):
   mapping[source_name] = target_by_canonical[canonical]
  else:
   unmapped.append(source_name)
 return {"ok":true,"mapping":mapping,"unmapped":unmapped,"source_count":source.get_bone_count(),"target_count":target.get_bone_count(),"mapped_count":mapping.size(),"coverage":float(mapping.size()) / maxf(1.0,float(source.get_bone_count()))}

func retarget_pose(source_pose: Dictionary, mapping: Dictionary, rotation_scale := Vector3.ONE, rotation_offset := Vector3.ZERO) -> Dictionary:
 var result := {}
 for source_name in mapping:
  if not source_pose.has(source_name):
   continue
  var value: Variant = source_pose[source_name]
  var rotation := _as_vector3(value)
  rotation = rotation * rotation_scale + rotation_offset
  result[str(mapping[source_name])] = [rotation.x,rotation.y,rotation.z]
 return result

func retarget_animation_clip(clip: Dictionary, profile: Dictionary, rotation_scale := Vector3.ONE, rotation_offset := Vector3.ZERO) -> Dictionary:
 var profile_report := validate_profile(profile)
 if not bool(profile_report.get("ok", false)):
  return profile_report
 var source_frames: Variant = clip.get("keyframes", [])
 if not source_frames is Array or source_frames.is_empty():
  return {"ok": false, "error": "El clip no contiene keyframes retargetables."}
 var mapping: Dictionary = profile.get("mapping", {})
 var canonical_mapping: Dictionary = {}
 for source_name in mapping.keys():
  var canonical := canonical_name(str(source_name))
  if not canonical.is_empty() and not canonical_mapping.has(canonical):
   canonical_mapping[canonical] = str(mapping[source_name])
 var retargeted_frames: Array = []
 var mapped_bones: Dictionary = {}
 var unmapped_bones: Dictionary = {}
 for source_frame in source_frames:
  if not source_frame is Dictionary:
   return {"ok": false, "error": "El clip contiene un keyframe inválido."}
  var source_pose: Variant = source_frame.get("bone_rotations_degrees", {})
  if not source_pose is Dictionary:
   return {"ok": false, "error": "El keyframe no contiene un mapa de rotaciones."}
  var target_pose: Dictionary = {}
  for source_bone in source_pose.keys():
   var target_bone := str(mapping.get(str(source_bone), canonical_mapping.get(canonical_name(str(source_bone)), "")))
   if target_bone.is_empty():
    unmapped_bones[str(source_bone)] = true
    continue
   var rotation := _as_vector3(source_pose[source_bone]) * rotation_scale + rotation_offset
   target_pose[target_bone] = [snappedf(rotation.x, 0.001), snappedf(rotation.y, 0.001), snappedf(rotation.z, 0.001)]
   mapped_bones[target_bone] = true
  var target_frame := {"time": maxf(0.0, float(source_frame.get("time", 0.0))), "bone_rotations_degrees": target_pose}
  if source_frame.has("easing"):
   target_frame["easing"] = source_frame["easing"]
  retargeted_frames.append(target_frame)
 if mapped_bones.is_empty():
  return {"ok": false, "error": "Ningún hueso del clip coincide con el perfil de retargeting."}
 var result := clip.duplicate(true)
 result["source_name"] = str(clip.get("name", "Animación"))
 result["name"] = str(clip.get("name", "Animación")) + " · Retarget"
 result["keyframes"] = retargeted_frames
 result["retarget_profile"] = str(profile.get("name", "Retarget profile"))
 result["mapped_bone_count"] = mapped_bones.size()
 result["unmapped_bones"] = unmapped_bones.keys()
 return {"ok": true, "clip": result, "mapped_bone_count": mapped_bones.size(), "unmapped_bones": unmapped_bones.keys()}

func create_profile(source: Skeleton3D, target: Skeleton3D, label := "Retarget profile") -> Dictionary:
 var report := build_bone_map(source,target)
 if not report.get("ok",false):
  return report
 return {"ok":true,"name":label,"version":1,"mapping":report.mapping,"unmapped":report.unmapped,"source_bone_count":report.source_count,"target_bone_count":report.target_count,"mapped_bone_count":report.mapped_count,"coverage":report.coverage}

func validate_profile(profile: Dictionary) -> Dictionary:
 var mapping: Variant = profile.get("mapping",{})
 if not mapping is Dictionary or mapping.is_empty():
  return {"ok":false,"error":"El perfil no contiene equivalencias de huesos."}
 for source_name in mapping:
  if str(source_name).is_empty() or str(mapping[source_name]).is_empty():
   return {"ok":false,"error":"El perfil contiene nombres de huesos vacíos."}
 return {"ok":true,"mapped_count":mapping.size()}

func _as_vector3(value: Variant) -> Vector3:
 if value is Vector3:
  return value
 if value is Array and value.size() >= 3:
  return Vector3(float(value[0]),float(value[1]),float(value[2]))
 return Vector3.ZERO
