# Formato de exportación de personajes

## Paquete JSON

El editor exporta archivos con:

- `format`: `animation_studio_character_package`
- `format_version`: versión del esquema (actualmente 1)
- `character`: ficha del personaje y definición del esqueleto.
- `rig`: tipo de rig y ángulos actuales de articulaciones en grados.
- `procedural_poses` y `custom_poses`: poses guardadas.
- `animation_clips`: clips con duración, repetición y fotogramas clave.
- `image_import`: tamaño de la imagen y rectángulos de recortes.
- `assets`: imágenes fuente, imagen procesada y recortes codificados en Base64.

Los recursos se incluyen cuando están disponibles y el conjunto no supera 20 MB sin codificar. El paquete completo admite hasta 32 MB. Los paquetes de versiones desconocidas, estructura inválida o recursos que exceden el límite se rechazan.

Cada fotograma contiene `time` (segundos) y `joint_angles` (grados). Los nombres de articulaciones se conservan como claves de texto, por ejemplo `head`, `torso`, `elbow_left` o `knee_right`.

## Hoja de sprites PNG

La exportación desde la línea de tiempo crea:

- Una hoja PNG transparente con 12 fotogramas en una cuadrícula de 4 columnas × 3 filas.
- Un archivo JSON compañero con dimensiones, cantidad de fotogramas, duración y FPS calculados.

El PNG puede importarse como textura en Godot, Unity, Unreal, Three.js u otros motores. El archivo compañero describe el corte de cada fotograma; no impone un sistema de animación específico.

## JavaScript para proyectos web

`examples/web/character_package_loader.js` carga el paquete, crea URLs temporales para las imágenes incrustadas y permite muestrear los ángulos de cualquier clip. La función `dispose()` revoca esas URLs cuando el personaje deja de utilizarse.

El adaptador entrega datos y texturas; no crea automáticamente un esqueleto artístico ni hace skinning de una malla 3D. El proyecto destino debe mapear los nombres de articulación a su propio rig.
