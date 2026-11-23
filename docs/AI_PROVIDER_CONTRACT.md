# Contrato del proveedor de IA de personajes

Animation Studio Manager incluye un adaptador HTTP configurable. No trae un modelo generativo ni un servidor de segmentación incorporado. Para usar las funciones IA hay que desplegar o contratar un servicio compatible y pegar su endpoint en el Estudio de personajes.

## Seguridad y privacidad

- Se acepta HTTPS o servicios locales en `localhost` / `127.0.0.1`.
- La clave se mantiene en memoria durante la sesión; no se añade al JSON del proyecto ni al repositorio.
- La imagen se envía únicamente cuando el usuario pulsa una acción de IA.
- No incluyas claves API en commits ni en archivos del proyecto.
- Para imágenes privadas, se recomienda un servicio local.

## Solicitud de segmentación

Método: POST JSON al endpoint configurado.

```json
{
  "task": "character_part_segmentation",
  "schema_version": 1,
  "visual_mode": "2D esquelético",
  "image_mime": "image/png",
  "image_base64": "<PNG en base64>",
  "requested_parts": ["head", "torso", "upper_arm_left"],
  "requested_outputs": ["masks", "joint_points", "confidence", "view_consistency"]
}
```

Respuesta mínima:

```json
{
  "task": "character_part_segmentation",
  "schema_version": 1,
  "segments": [
    {
      "name": "head",
      "rect": [120, 30, 180, 210],
      "confidence": 0.98,
      "mask_png_base64": "<máscara PNG opcional, del mismo tamaño que rect>"
    }
  ],
  "joints": {
    "neck": [210, 225],
    "shoulder_left": [145, 270],
    "elbow_left": [105, 360],
    "wrist_left": [80, 445],
    "shoulder_right": [275, 270],
    "elbow_right": [315, 360],
    "wrist_right": [340, 445],
    "pelvis": [210, 520],
    "hip_left": [175, 545],
    "knee_left": [165, 680],
    "ankle_left": [160, 810],
    "hip_right": [245, 545],
    "knee_right": [255, 680],
    "ankle_right": [260, 810]
  }
}
```

Las coordenadas son píxeles absolutos de la imagen original. `rect` es [x, y, ancho, alto]. La máscara opcional debe ser PNG y tener exactamente el ancho y alto del rectángulo; los píxeles blancos/opacos se conservan y los negros/transparentes se eliminan. Los recortes se guardan como imágenes independientes. Las articulaciones se usan como pivotes del rig 2D.

Nombres recomendados de piezas: `head`, `torso`, `pelvis`, `upper_arm_left`, `lower_arm_left`, `hand_left`, `upper_arm_right`, `lower_arm_right`, `hand_right`, `upper_leg_left`, `lower_leg_left`, `foot_left`, `upper_leg_right`, `lower_leg_right`, `foot_right`.

## Solicitud de vistas

Tarea: `character_turnaround_generation`.

La respuesta debe incluir `views`, un arreglo de objetos con `name` y `image_png_base64`. Nombres recomendados: `front`, `profile`, `back`, `three_quarter`. Las imágenes se guardan localmente y se deben revisar para comprobar continuidad de identidad y vestuario.

## Solicitud de poses

Tarea: `character_pose_generation`.

La respuesta debe incluir `poses`, un arreglo de objetos:
- `name`: nombre de la pose/acción.
- `joint_angles`: mapa de nombre de pivote a ángulo en grados.

Pivotes soportados por el rig de sprites: `head`, `torso`, `pelvis`, `shoulder_left`, `elbow_left`, `wrist_left`, `shoulder_right`, `elbow_right`, `wrist_right`, `hip_left`, `knee_left`, `ankle_left`, `hip_right`, `knee_right`, `ankle_right`.

El primer resultado se aplica a la vista actual si existe un rig de sprites. Todos los resultados se guardan en el proyecto para inspección.

## Estado de integración

El cliente HTTP, la validación de respuestas, el guardado de recortes, el uso de máscaras, los pivotes y el flujo de vistas/poses están implementados. No se proporciona un modelo servidor, sus pesos ni una URL de inferencia. Sin un endpoint compatible, las funciones IA no pueden producir resultados. El modo local de preparación de imagen solo elimina un fondo plano conectado a los bordes y crea regiones proporcionales aproximadas; no debe confundirse con segmentación semántica.
