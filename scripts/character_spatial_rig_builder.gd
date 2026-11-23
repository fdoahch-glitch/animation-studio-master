extends RefCounted
class_name CharacterSpatialRigBuilder

## Esqueleto espacial 3D con piezas geométricas independientes ancladas a huesos.
## Es una base de rig por segmentos; no realiza skinning de una malla artística importada.

const MATERIAL_SKIN := Color("#e5a878")
const MATERIAL_CLOTH := Color("#2878b8")
const MATERIAL_DARK := Color("#23384d")

func build_humanoid_3d(character_name: String = "Personaje") -> Node3D:
	var root := Node3D.new()
	root.name = "Rig3D_" + character_name.validate_filename()
	root.set_meta("rig_type", "3D_segmented_skeleton")
	var skeleton := Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	root.add_child(skeleton)

	var definitions := [
		{"name":"Root","parent":"","offset":Vector3.ZERO,"length":0.0,"radius":0.01,"color":MATERIAL_DARK},
		{"name":"Pelvis","parent":"Root","offset":Vector3(0,0.95,0),"length":0.25,"radius":0.22,"color":MATERIAL_DARK},
		{"name":"Spine","parent":"Pelvis","offset":Vector3(0,0.22,0),"length":0.30,"radius":0.15,"color":MATERIAL_CLOTH},
		{"name":"Chest","parent":"Spine","offset":Vector3(0,0.30,0),"length":0.32,"radius":0.23,"color":MATERIAL_CLOTH},
		{"name":"Neck","parent":"Chest","offset":Vector3(0,0.32,0),"length":0.13,"radius":0.07,"color":MATERIAL_SKIN},
		{"name":"Head","parent":"Neck","offset":Vector3(0,0.15,0),"length":0.30,"radius":0.16,"color":MATERIAL_SKIN},
		{"name":"Shoulder_L","parent":"Chest","offset":Vector3(-0.23,0.23,0),"length":0.25,"radius":0.085,"color":MATERIAL_SKIN},
		{"name":"Elbow_L","parent":"Shoulder_L","offset":Vector3(-0.25,-0.02,0),"length":0.25,"radius":0.065,"color":MATERIAL_SKIN},
		{"name":"Wrist_L","parent":"Elbow_L","offset":Vector3(-0.24,0,0),"length":0.12,"radius":0.055,"color":MATERIAL_SKIN},
		{"name":"Shoulder_R","parent":"Chest","offset":Vector3(0.23,0.23,0),"length":0.25,"radius":0.085,"color":MATERIAL_SKIN},
		{"name":"Elbow_R","parent":"Shoulder_R","offset":Vector3(0.25,-0.02,0),"length":0.25,"radius":0.065,"color":MATERIAL_SKIN},
		{"name":"Wrist_R","parent":"Elbow_R","offset":Vector3(0.24,0,0),"length":0.12,"radius":0.055,"color":MATERIAL_SKIN},
		{"name":"Hip_L","parent":"Pelvis","offset":Vector3(-0.12,-0.12,0),"length":0.38,"radius":0.105,"color":MATERIAL_DARK},
		{"name":"Knee_L","parent":"Hip_L","offset":Vector3(0,-0.38,0),"length":0.38,"radius":0.085,"color":MATERIAL_DARK},
		{"name":"Ankle_L","parent":"Knee_L","offset":Vector3(0,-0.38,0),"length":0.16,"radius":0.07,"color":MATERIAL_DARK},
		{"name":"Hip_R","parent":"Pelvis","offset":Vector3(0.12,-0.12,0),"length":0.38,"radius":0.105,"color":MATERIAL_DARK},
		{"name":"Knee_R","parent":"Hip_R","offset":Vector3(0,-0.38,0),"length":0.38,"radius":0.085,"color":MATERIAL_DARK},
		{"name":"Ankle_R","parent":"Knee_R","offset":Vector3(0,-0.38,0),"length":0.16,"radius":0.07,"color":MATERIAL_DARK}
	]
	var indices: Dictionary = {}
	for definition in definitions:
		var bone_name := str(definition.name)
		var bone_index := skeleton.add_bone(bone_name)
		indices[bone_name] = bone_index
		var parent_name := str(definition.parent)
		if parent_name != "":
			skeleton.set_bone_parent(bone_index, int(indices[parent_name]))
		var rest := Transform3D(Basis.IDENTITY, definition.offset)
		skeleton.set_bone_rest(bone_index, rest)

	for definition in definitions:
		var bone_name := str(definition.name)
		var length := float(definition.length)
		if length <= 0.0:
			continue
		var attachment := BoneAttachment3D.new()
		attachment.name = "Attachment_" + bone_name
		attachment.bone_name = bone_name
		skeleton.add_child(attachment)
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "Segment_" + bone_name
		var capsule := CapsuleMesh.new()
		capsule.radius = float(definition.radius)
		capsule.height = maxf(length, capsule.radius * 2.0)
		mesh_instance.mesh = capsule
		mesh_instance.position.y = -length * 0.5
		var material := StandardMaterial3D.new()
		material.albedo_color = definition.color
		material.roughness = 0.78
		mesh_instance.material_override = material
		attachment.add_child(mesh_instance)
	return root

func create_2_5d_plane(texture: Texture2D, plane_name: String, depth: float = 0.0) -> Node3D:
	var plane := MeshInstance3D.new()
	plane.name = plane_name
	var quad := QuadMesh.new()
	var aspect := float(texture.get_width()) / maxf(float(texture.get_height()), 1.0)
	quad.size = Vector2(aspect, 1.0)
	plane.mesh = quad
	plane.position.z = depth
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	plane.material_override = material
	return plane
