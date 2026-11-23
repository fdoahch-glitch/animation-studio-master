# Formato de exportación de personajes

## Paquete JSON

El editor exporta archivos con:

- `format`: `animation_studio_character_package`
- `format_version`: versión del esquema (actualmente 1)
- `character`: ficha del personaje y definición del esqueleto.
- `rig`: tipo de rig, ángulos 2D y rotaciones 3D de los huesos en grados.
- `procedural_poses` y `custom_poses`: poses guardadas para rigs 2D.
- `animation_clips`: clips 2D con duración, repetición y fotogramas clave.
- `spatial_poses` y `spatial_animation_clips`: poses y ciclos para Skeleton3D, con rotaciones X/Y/Z por hueso.
- `image_import`: tamaño de la imagen y rectángulos de recortes.
- `assets`: imágenes fuente, imagen procesada, recortes y, si se importó, el modelo GLB/glTF codificado en Base64.

Los recursos se incluyen cuando están disponibles y el conjunto no supera 20 MB sin codificar. Los modelos GLB/glTF se pueden importar con sus mallas, materiales, texturas, esqueleto y animaciones originales; al exportar un paquete se incrusta el archivo 3D si cabe en ese límite. El paquete completo admite hasta 32 MB. Los paquetes de versiones desconocidas, estructura inválida o recursos que exceden el límite se rechazan.

Cada fotograma 2D contiene `time` (segundos) y `joint_angles` (grados). Los fotogramas 3D usan `bone_rotations_degrees`, con vectores `[X, Y, Z]` por hueso. Los nombres de articulaciones y huesos se conservan como claves de texto, por ejemplo `head`, `torso`, `elbow_left`, `knee_right` o `Shoulder_L`.

El editor permite importar modelos GLB/glTF con esqueleto, reconocer nombres humanoides habituales (incluidos nombres de huesos tipo Mixamo), conservar las animaciones originales y añadir movimiento procedural. El editor 3D genera 19 poses base y ocho ciclos procedurales (idle, walk, run, jump, wave, talk, dance y sneak). Los clips se pueden reproducir desde sus fotogramas exportados y volver a importar en el editor. El rig actual usa piezas geométricas ancladas a huesos; todavía no aplica skinning automático a mallas artísticas externas.

## Hoja de sprites PNG

La exportación desde la línea de tiempo crea:

- Una hoja PNG transparente con 12 fotogramas en una cuadrícula de 4 columnas × 3 filas.
- Un archivo JSON compañero con dimensiones, cantidad de fotogramas, duración y FPS calculados.

El PNG puede importarse como textura en Godot, Unity, Unreal, Three.js u otros motores. El archivo compañero describe el corte de cada fotograma; no impone un sistema de animación específico.

## JavaScript para proyectos web

`examples/web/character_package_loader.js` carga el paquete, crea URLs temporales para las imágenes incrustadas y permite muestrear los ángulos de cualquier clip. La función `dispose()` revoca esas URLs cuando el personaje deja de utilizarse.

El editor también puede exportar la escena 3D activa a GLB; conserva mallas, materiales, texturas, esqueleto y animaciones nativas compatibles. Los ciclos procedurales se conservan en el paquete JSON y deben exportarse junto al GLB para reutilizarlos. El adaptador permite muestrear clips 2D (`sampleClip`) y 3D (`sampleSpatialClip`). Para 3D devuelve vectores de rotación `[X, Y, Z]` en grados. Entrega datos y texturas; no crea automáticamente un esqueleto artístico ni hace skinning de una malla 3D. El proyecto destino debe mapear los nombres de articulación o hueso a su propio rig.
