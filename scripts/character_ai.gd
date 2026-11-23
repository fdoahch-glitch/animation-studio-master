extends Node
class_name CharacterAI

## Plantillas procedurales y preparación de prompts. La generación visual requiere un proveedor externo configurado.

func build_character_blueprint(character_name: String, description: String, rig_type: String) -> Dictionary:
	return {
		"id": "character_" + str(Time.get_unix_time_from_system()),
		"name": character_name,
		"description": description,
		"rig_type": rig_type,
		"views": ["front", "profile", "back", "three_quarter"],
		"poses": ["idle", "walk", "run", "jump", "talk", "turn", "wave", "sit"],
		"rig": {"type": rig_type, "bones": _build_humanoid_bones(), "constraints": [
			{"type":"hinge","bone":"elbow_L","min_degrees":-5,"max_degrees":145},
			{"type":"hinge","bone":"elbow_R","min_degrees":-5,"max_degrees":145},
			{"type":"hinge","bone":"knee_L","min_degrees":-5,"max_degrees":150},
			{"type":"hinge","bone":"knee_R","min_degrees":-5,"max_degrees":150}
		]},
		"generation": {"image_generation":"not_connected","rig_generation":"procedural_template","requires_review":true}
	}

func _build_humanoid_bones() -> Array:
	return [
		{"name":"root","parent":"","position":[0.0,0.0]},
		{"name":"pelvis","parent":"root","position":[0.0,-0.48]},
		{"name":"spine","parent":"pelvis","position":[0.0,-0.18]},
		{"name":"chest","parent":"spine","position":[0.0,-0.2]},
		{"name":"neck","parent":"chest","position":[0.0,-0.16]},
		{"name":"head","parent":"neck","position":[0.0,-0.18]},
		{"name":"clavicle_L","parent":"chest","position":[-0.18,-0.05]},
		{"name":"upper_arm_L","parent":"clavicle_L","position":[-0.16,0.08]},
		{"name":"elbow_L","parent":"upper_arm_L","position":[-0.15,0.2]},
		{"name":"wrist_L","parent":"elbow_L","position":[-0.12,0.19]},
		{"name":"clavicle_R","parent":"chest","position":[0.18,-0.05]},
		{"name":"upper_arm_R","parent":"clavicle_R","position":[0.16,0.08]},
		{"name":"elbow_R","parent":"upper_arm_R","position":[0.15,0.2]},
		{"name":"wrist_R","parent":"elbow_R","position":[0.12,0.19]},
		{"name":"hip_L","parent":"pelvis","position":[-0.12,0.0]},
		{"name":"knee_L","parent":"hip_L","position":[0.0,0.25]},
		{"name":"ankle_L","parent":"knee_L","position":[0.0,0.24]},
		{"name":"hip_R","parent":"pelvis","position":[0.12,0.0]},
		{"name":"knee_R","parent":"hip_R","position":[0.0,0.25]},
		{"name":"ankle_R","parent":"knee_R","position":[0.0,0.24]}
	]

func build_character_prompt(character_name: String, description: String, style: String, rig_type: String) -> String:
	return """Create an original production-ready character design sheet.
Character: %s
Description: %s
Art direction: %s
Target rig: %s
Create consistent orthographic views: front, exact side profile, back, and three-quarter.
Keep anatomy, proportions, costume, colors, markings and accessories identical across views.
Include neutral A-pose, clear silhouette, separated limbs, visible joints, clean outlines,
consistent studio lighting, plain neutral background, no text, no watermark.
Also provide expression and mouth-viseme references.""" % [character_name,description,style,rig_type]

func format_rig_summary(rig: Dictionary) -> String:
	var lines := PackedStringArray()
	lines.append("Rig: " + str(rig.get("type","2D esquelético")))
	lines.append("Huesos: " + str(rig.get("bones",[]).size()))
	lines.append("Cadena central: root → pelvis → spine → chest → neck → head")
	lines.append("Brazos: clavícula → brazo → codo → muñeca (ambos lados)")
	lines.append("Piernas: cadera → rodilla → tobillo (ambos lados)")
	lines.append("Incluye límites angulares iniciales para codos y rodillas.")
	lines.append("Pesos, pivotes y deformaciones requieren revisión manual.")
	return "\n".join(lines)
