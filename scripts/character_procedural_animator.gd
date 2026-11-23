extends RefCounted
class_name CharacterProceduralAnimator

## Generador determinista de poses y ciclos 2D. No usa modelos, red, GPU ni servicios externos.

const JOINTS := ["head", "torso", "shoulder_left", "elbow_left", "shoulder_right", "elbow_right", "hip_left", "knee_left", "hip_right", "knee_right"]

func generate_pose_library() -> Dictionary:
	var poses: Array[Dictionary] = [
		_pose("Reposo", {"head": 0, "torso": 0, "shoulder_left": 8, "shoulder_right": -8}),
		_pose("Atención", {"head": -8, "torso": -3, "shoulder_left": 12, "shoulder_right": -12, "elbow_left": 18, "elbow_right": 18}),
		_pose("Feliz", {"head": -5, "torso": -7, "shoulder_left": -38, "elbow_left": -55, "shoulder_right": 38, "elbow_right": 55}),
		_pose("Triste", {"head": 22, "torso": 10, "shoulder_left": 28, "elbow_left": 12, "shoulder_right": -28, "elbow_right": -12}),
		_pose("Enojado", {"head": -12, "torso": -5, "shoulder_left": -22, "elbow_left": -75, "shoulder_right": 22, "elbow_right": 75}),
		_pose("Sorprendido", {"head": -18, "shoulder_left": -105, "elbow_left": -25, "shoulder_right": 105, "elbow_right": 25}),
		_pose("Saludo", {"shoulder_right": -105, "elbow_right": -95, "head": -8}),
		_pose("Brazos arriba", {"shoulder_left": -145, "elbow_left": -15, "shoulder_right": 145, "elbow_right": 15}),
		_pose("Brazos cruzados", {"shoulder_left": 48, "elbow_left": -105, "shoulder_right": -48, "elbow_right": 105}),
		_pose("Señalar", {"shoulder_right": -72, "elbow_right": 4, "head": -12}),
		_pose("Agachado", {"torso": 18, "hip_left": -38, "hip_right": 38, "knee_left": 72, "knee_right": 72}),
		_pose("Preparado para correr", {"torso": -12, "shoulder_left": -35, "shoulder_right": 35, "hip_left": -25, "hip_right": 25, "knee_left": 28, "knee_right": 28}),
		_pose("Pensando", {"head": -18, "shoulder_right": -38, "elbow_right": -82, "shoulder_left": 12, "elbow_left": 24}),
		_pose("Durmiendo", {"head": 24, "torso": 8, "shoulder_left": 22, "elbow_left": 30, "shoulder_right": -22, "elbow_right": -30}),
		_pose("Miedo", {"head": -20, "torso": -14, "shoulder_left": -105, "elbow_left": -45, "shoulder_right": 105, "elbow_right": 45, "hip_left": -18, "hip_right": 18}),
		_pose("Estiramiento", {"torso": -8, "shoulder_left": -155, "shoulder_right": 155, "elbow_left": -12, "elbow_right": 12}),
		_pose("Sentado", {"torso": 5, "hip_left": -82, "hip_right": 82, "knee_left": 88, "knee_right": 88}),
		_pose("Sigilo", {"torso": 22, "head": -12, "hip_left": -35, "hip_right": 35, "knee_left": 55, "knee_right": 55, "shoulder_left": -18, "shoulder_right": 18}),
		_pose("Caída", {"torso": 48, "head": 30, "shoulder_left": -90, "shoulder_right": 90, "hip_left": 35, "hip_right": -35}),
		_pose("Victoria", {"torso": -8, "shoulder_left": -150, "shoulder_right": 150, "elbow_left": -28, "elbow_right": 28}),
		_pose("Desconfiado", {"head": 16, "torso": 4, "shoulder_left": 18, "elbow_left": -35, "shoulder_right": -8, "elbow_right": 15})
	]
	var clips: Array[Dictionary] = []
	clips.append(_cycle("Respirar", 2.4, "breath", true))
	clips.append(_cycle("Caminar", 0.95, "walk", true))
	clips.append(_cycle("Correr", 0.55, "run", true))
	clips.append(_cycle("Saltar", 0.85, "jump", false))
	clips.append(_cycle("Saludar", 1.25, "wave", false))
	clips.append(_cycle("Hablar", 1.8, "talk", true))
	clips.append(_cycle("Celebrar", 1.5, "celebrate", false))
	clips.append(_cycle("Bailar", 1.8, "dance", true))
	clips.append(_cycle("Caminar lento", 1.5, "slow_walk", true))
	clips.append(_cycle("Cojeando", 1.1, "limp", true))
	clips.append(_cycle("Rebotar", 0.9, "bounce", true))
	clips.append(_cycle("Mirar alrededor", 2.2, "look", true))
	clips.append(_cycle("Escabullirse", 1.35, "sneak", true))
	clips.append(_cycle("Estirarse", 2.0, "stretch", false))
	clips.append(_cycle("Dormir", 3.0, "sleep", true))
	clips.append(_cycle("Tropezar", 0.8, "stumble", false))
	clips.append(_cycle("Caminar hacia atrás", 1.1, "backwalk", true))
	clips.append(_cycle("Asustarse", 1.1, "fear", false))
	clips.append(_cycle("Pensar", 2.0, "think", true))
	clips.append(_cycle("Deslizarse", 1.0, "slide", false))
	return {"poses": poses, "animations": clips}

func _pose(label: String, angles: Dictionary) -> Dictionary:
	return {"name": label, "joint_angles": angles.duplicate(true)}

func _cycle(label: String, duration: float, style: String, looping: bool) -> Dictionary:
	var frames: Array[Dictionary] = []
	var samples := 16
	for i in range(samples + 1):
		var phase := TAU * float(i) / float(samples)
		frames.append({"time": duration * float(i) / float(samples), "joint_angles": _angles_for(style, phase)})
	return {"name": label, "duration": duration, "loop": looping, "keyframes": frames}

func _angles_for(style: String, p: float) -> Dictionary:
	var s := sin(p)
	var c := cos(p)
	var a := {}
	match style:
		"breath":
			a = {"torso": 2.5 * s, "head": 1.2 * s, "shoulder_left": 2.0 * s, "shoulder_right": -2.0 * s}
		"walk", "slow_walk", "run", "limp":
			var amp := 28.0 if style == "walk" else (48.0 if style == "slow_walk" else (72.0 if style == "run" else 34.0))
			var leg_amp := 30.0 if style == "walk" else (50.0 if style == "slow_walk" else (76.0 if style == "run" else 38.0))
			a = {"hip_left": leg_amp * s, "hip_right": -leg_amp * s, "knee_left": maxf(0.0, 24.0 * c), "knee_right": maxf(0.0, -24.0 * c), "shoulder_left": -amp * s, "shoulder_right": amp * s, "elbow_left": -22.0 - 12.0 * c, "elbow_right": -22.0 + 12.0 * c, "torso": -3.0 + 3.0 * absf(s)}
			if style == "limp":
				a["hip_left"] = leg_amp * s * 0.55
				a["shoulder_right"] = amp * s * 0.45
		"jump":
			a = {"torso": -10.0 * maxf(0.0, s), "shoulder_left": -95.0 * maxf(0.0, s), "shoulder_right": 95.0 * maxf(0.0, s), "elbow_left": -25.0, "elbow_right": 25.0, "hip_left": -35.0 * maxf(0.0, s), "hip_right": 35.0 * maxf(0.0, s), "knee_left": 42.0 * maxf(0.0, s), "knee_right": 42.0 * maxf(0.0, s)}
		"wave":
			a = {"shoulder_right": -105.0 + 12.0 * s, "elbow_right": -85.0 + 28.0 * s, "head": -5.0 + 3.0 * s, "shoulder_left": 8.0}
		"talk":
			a = {"head": 2.0 * s, "torso": 1.5 * s, "shoulder_left": 5.0 + 4.0 * s, "shoulder_right": -5.0 - 4.0 * s, "elbow_left": -18.0 + 10.0 * s, "elbow_right": -18.0 - 10.0 * s}
		"celebrate":
			a = {"shoulder_left": -125.0 + 12.0 * s, "shoulder_right": 125.0 - 12.0 * s, "elbow_left": -25.0, "elbow_right": 25.0, "hip_left": 8.0 * s, "hip_right": -8.0 * s, "torso": -5.0 * absf(s)}
		"dance":
			a = {"torso": 13.0 * s, "head": -8.0 * s, "shoulder_left": -65.0 * c, "shoulder_right": 65.0 * c, "elbow_left": -35.0 + 18.0 * s, "elbow_right": -35.0 - 18.0 * s, "hip_left": 22.0 * s, "hip_right": -22.0 * s}
		"bounce":
			a = {"torso": -7.0 * maxf(0.0, s), "hip_left": -12.0 * maxf(0.0, s), "hip_right": 12.0 * maxf(0.0, s), "knee_left": 22.0 * maxf(0.0, s), "knee_right": 22.0 * maxf(0.0, s), "shoulder_left": -15.0 * s, "shoulder_right": 15.0 * s}
		"look":
			a = {"head": 18.0 * s, "torso": 3.0 * c, "shoulder_left": 5.0 * s, "shoulder_right": -5.0 * s}
		"sneak":
			a = {"torso": 18.0 + 3.0 * s, "head": -10.0 + 4.0 * c, "hip_left": 22.0 * s, "hip_right": -22.0 * s, "knee_left": 35.0 + 12.0 * maxf(0.0, c), "knee_right": 35.0 + 12.0 * maxf(0.0, -c), "shoulder_left": -18.0 * s, "shoulder_right": 18.0 * s, "elbow_left": -35.0, "elbow_right": -35.0}
		"stretch":
			a = {"torso": -8.0 * maxf(0.0, s), "shoulder_left": -150.0 + 12.0 * s, "shoulder_right": 150.0 - 12.0 * s, "elbow_left": -8.0, "elbow_right": 8.0, "head": -4.0 * s}
		"sleep":
			a = {"head": 22.0 + 2.0 * s, "torso": 5.0 * s, "shoulder_left": 18.0 + 2.0 * s, "shoulder_right": -18.0 - 2.0 * s, "elbow_left": 25.0, "elbow_right": -25.0}
		"stumble":
			a = {"torso": 24.0 * s, "head": -18.0 * s, "shoulder_left": -85.0 * c, "shoulder_right": 65.0 * c, "elbow_left": -35.0, "elbow_right": 28.0, "hip_left": 48.0 * s, "hip_right": -18.0 * s, "knee_left": 35.0 * maxf(0.0, c), "knee_right": 20.0 * maxf(0.0, -c)}
		"backwalk":
			a = {"hip_left": -26.0 * s, "hip_right": 26.0 * s, "knee_left": maxf(0.0, 20.0 * c), "knee_right": maxf(0.0, -20.0 * c), "shoulder_left": 22.0 * s, "shoulder_right": -22.0 * s, "elbow_left": -18.0, "elbow_right": -18.0, "torso": 4.0}
		"fear":
			a = {"head": -16.0 + 5.0 * s, "torso": -12.0 + 3.0 * s, "shoulder_left": -105.0 + 12.0 * s, "shoulder_right": 105.0 - 12.0 * s, "elbow_left": -40.0, "elbow_right": 40.0, "hip_left": -12.0 * s, "hip_right": 12.0 * s}
		"think":
			a = {"head": -14.0 + 3.0 * s, "torso": -2.0 * s, "shoulder_right": -40.0, "elbow_right": -88.0 + 8.0 * s, "shoulder_left": 8.0, "elbow_left": 20.0}
		"slide":
			a = {"torso": 35.0, "head": -10.0, "hip_left": -55.0, "hip_right": 55.0, "knee_left": 82.0, "knee_right": 82.0, "shoulder_left": -45.0 * s, "shoulder_right": 45.0 * s}
	return a
