# Rig 2D editable y animaciones base

## Qué hace esta primera implementación

El script `scripts/character_rig_builder.gd` crea un árbol de nodos real de Godot:
- Un pivote raíz y pivotes jerárquicos para pelvis, columna, pecho, cuello y cabeza.
- Pivotes separados para hombros, codos, caderas y rodillas.
- Segmentos visuales unidos a sus pivotes para comprobar la estructura.
- Un `AnimationPlayer` con ciclos de reposo, caminar, correr, saltar, hablar y saludar.
- Una función pública para reproducir o detener ciclos y ajustar su velocidad.

El Estudio de personajes crea este rig y lo muestra en un `SubViewport`. Los botones de animación permiten probar los ciclos sin salir del editor.

## Cómo se construye

1. El asistente de personaje crea la ficha y el blueprint de articulaciones.
2. `CharacterRigBuilder.build_runtime_rig()` construye los pivotes y segmentos.
3. El constructor añade el `AnimationPlayer` y sus pistas de rotación.
4. La interfaz presenta el rig y permite probar cada animación.

## Qué falta para que sea rigging automático de una imagen

Esta etapa todavía no corta una ilustración importada ni asigna automáticamente cada región de píxeles a un hueso. Tampoco calcula pesos de deformación. Para eso se necesita un modelo de segmentación de partes del cuerpo, una etapa de asociación de piezas con articulaciones y un sistema de deformación (por ejemplo, sprites por pieza con mallas 2D y pesos, o recortes con solapamiento y pivotes).

La siguiente etapa debe incorporar:
- Importación de una imagen de personaje.
- Segmentación de cabeza, torso, brazos, antebrazos, manos, muslos, piernas, pies, cabello, ropa y accesorios.
- Máscaras y recortes independientes con transparencia.
- Detección de puntos articulares y asignación a pivotes.
- Editor manual para corregir máscaras, pivotes y jerarquías.
- Deformación de piezas y prevención de huecos al doblar articulaciones.
- Generación y revisión de poses y vistas coherentes.

## Límites de esta versión

- El rig construido es 2D y procedural; no es un rig 3D.
- Los segmentos visibles son geometría de referencia, no arte final.
- Los ciclos son animaciones base de rotación; todavía no incluyen IK, física, captura de movimiento, lipsync fonético ni deformación de una ilustración importada.
- La reconstrucción 2.5D/3D requiere otro pipeline, geometría y rig específicos.
