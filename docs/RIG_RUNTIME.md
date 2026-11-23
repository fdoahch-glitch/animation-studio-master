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

## Flujo de imagen y rig por sprites

El Estudio de personajes permite importar PNG, JPG o WebP. El procesador local elimina aproximadamente el color de fondo conectado a los bordes, calcula la silueta y exporta regiones proporcionales iniciales de cabeza, torso, pelvis, brazos y piernas. Guarda la imagen original y los recortes para que el usuario pueda revisarlos. No realiza segmentación semántica automática.

El botón «Construir rig con las piezas recortadas» monta las regiones como Sprite2D independientes, centradas alrededor de pivotes aproximados. La biblioteca procedural puede aplicar poses y ciclos a los pivotes que existan en el rig. Los recortes pueden solaparse o no coincidir con la anatomía; es necesario corregirlos manualmente para obtener resultados limpios.

## Generador procedural integrado

El módulo `scripts/character_procedural_animator.gd` crea 20 poses y 20 ciclos de movimiento mediante funciones matemáticas y keyframes interpolados. Incluye respiración, caminar, correr, saltar, saludo, conversación, celebración, baile, sigilo, estiramiento, sueño, tropiezo, caminar hacia atrás, miedo, pensamiento y deslizamiento, entre otros.

Las poses se aplican directamente al rig 2D y los ciclos se instalan en su `AnimationPlayer`. La velocidad de reproducción (0,25× a 2,5×) y la intensidad de los movimientos (0,5× a 1,75×) se ajustan desde los controles del estudio. Todo se calcula dentro del programa, sin llamadas de red, claves API, modelos, servidores o procesos residentes. El generador anima articulaciones existentes; no crea píxeles nuevos ni reconstruye partes ocultas de una ilustración.

## Rig espacial

`scripts/character_spatial_rig_builder.gd` crea un `Skeleton3D` humanoide con huesos para torso, cabeza, brazos, caderas, rodillas y tobillos. Cada segmento visible se adjunta a un hueso mediante `BoneAttachment3D`. También incluye una utilidad para colocar una imagen en un plano 2.5D.

Este módulo es un esqueleto espacial de referencia. No equivale a un modelo 3D de alta calidad, no calcula pesos de skinning y no incluye aún un sistema de animación 3D. El giro 360° de un personaje 2D sigue requiriendo vistas multivista o reconstrucción 3D.
