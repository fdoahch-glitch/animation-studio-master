# Sistema de personajes y animación procedural

## Objetivo
Crear fichas de personaje, esqueletos 2D editables y animaciones reutilizables sin depender de modelos de IA, servidores ni servicios externos.

## Funciones integradas
- Constructor local de ficha de personaje.
- Plantilla humanoide con jerarquía de pivotes y límites angulares iniciales.
- Importación de PNG, JPG y WebP.
- Eliminación aproximada de fondos planos conectados a los bordes.
- Recortes proporcionales de cabeza, torso, pelvis, brazos y piernas, con revisión manual.
- Rig 2D de referencia y rig por sprites independientes.
- Biblioteca de 20 poses expresivas.
- Biblioteca de 20 ciclos de animación con keyframes interpolados.
- Controles de intensidad de movimiento y velocidad de reproducción.
- Ajuste manual de articulaciones y pivotes.
- Captura, guardado y reutilización de poses manuales personalizadas.

## Cómo funciona la generación
El módulo `scripts/character_procedural_animator.gd` construye las poses y ciclos mediante funciones trigonométricas, fases, amplitudes y curvas interpoladas. Los ángulos se convierten en pistas de rotación del `AnimationPlayer`. Los rigs 2D estándar y segmentados pueden reproducir los ciclos y recibir poses.

El sistema es determinista y ligero: no ejecuta modelos, no requiere GPU adicional, no abre conexiones de red y no mantiene procesos en segundo plano.

## Límites importantes
- La animación mueve articulaciones que ya existen; no dibuja nuevos píxeles ni inventa partes ocultas.
- Los recortes de imagen son aproximados y no constituyen segmentación anatómica semántica.
- Los pivotes de los recortes deben revisarse y corregirse manualmente.
- Las vistas frontal, perfil, espalda y tres cuartos son referencias esquemáticas; no se reconstruyen automáticamente desde una única imagen.
- El rig 3D es una estructura geométrica de referencia, todavía sin skinning de mallas artísticas ni clips 3D.

## Próximas mejoras
- Editor visual de huesos y pivotes con arrastre.
- Guardado de poses personalizadas y biblioteca de acciones por personaje.
- Cinemática inversa conectada a controles de arrastre.
- Deformación 2D de mallas para reducir huecos en articulaciones.
- Sistema independiente de animación 3D cuando exista un modelo 3D con skinning.
