# Animation Studio Manager

Estudio visual de animación por escenas, desarrollado con Godot 4.x y orientado a Windows 10/11 x64.

## Novedades del prototipo
- Asistente inicial antes de abrir el espacio de trabajo.
- Presets de resolución hasta 4K, orientación y 24/25/30/50/60 FPS.
- Modos 2D, 2.5D, 3D e Híbrido.
- Secciones de Escenas, Personajes, Fondos, Elementos, Decoraciones, Tiempo y clima, Animación, Audio y doblaje y Exportar.
- Estudio de personajes con ficha, estilo y tipo de rig.
- Constructor de rig 2D editable en tiempo de ejecución, con pivotes y controles manuales de articulaciones.
- Importación de imagen, eliminación local aproximada de fondo plano y exportación de recortes anatómicos proporcionales.
- Generador procedural integrado de 20 poses expresivas y 20 ciclos de animación (respirar, caminar, correr, saltar, saludar, hablar, celebrar, bailar y más).
- Keyframes calculados matemáticamente, curvas suaves y aplicación directa a rigs 2D estándar y segmentados.
- Funcionamiento sin Internet, claves API, servidores, modelos externos ni procesos IA en segundo plano.
- Constructor de esqueleto 3D con Skeleton3D y piezas geométricas de referencia; utilidad de planos 2.5D.
- Animaciones base reproducibles desde el estudio: reposo, caminar, correr, saltar, hablar y saludar.
- Vista previa real del rig dentro de un SubViewport y controles para probar cada ciclo.
- Selector de vistas de referencia: frente, perfil, espalda y tres cuartos.
- Seis ciclos de animación 2D base y controles de ajuste manual de articulaciones.
- Control de velocidad de reproducción entre 0,25× y 2,5× e intensidad de movimiento ajustable.

## Animación procedural integrada

La generación de poses y ciclos ya no depende de IA externa ni local. El módulo `scripts/character_procedural_animator.gd` crea 20 poses editables y 20 clips con keyframes calculados mediante funciones matemáticas (senos, cosenos, fases, amplitudes y curvas interpoladas). Los clips se instalan en el AnimationPlayer de los rigs 2D estándar y segmentados. No requiere conexión, claves, modelos, GPU adicional ni un proceso residente.

La generación procedural anima las articulaciones disponibles; no inventa píxeles, no reconstruye partes ocultas y no crea ilustraciones nuevas ni vistas 3D reales. La calidad visual depende del personaje importado y de la corrección de sus recortes y pivotes. La preparación local de imagen sigue siendo aproximada: elimina fondos planos conectados a los bordes y propone regiones proporcionales. El rig 3D actual continúa siendo una estructura geométrica de referencia sin skinning de malla artística ni clips 3D.

## Abrir y ejecutar
1. Instala Godot 4.x desde https://godotengine.org/download/.
2. Descarga o clona este repositorio.
3. Importa la carpeta que contiene project.godot.
4. Abre el proyecto y ejecuta con F6/F5.

## Validar el proyecto y sus rigs

Con Godot 4.3 o superior, ejecuta desde la carpeta del proyecto:

```bash
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/test_character_rig.gd
```

GitHub Actions ejecuta estas comprobaciones en cada cambio de `main`.

## Exportar para Windows
1. Instala las plantillas de exportación en Godot.
2. Abre Proyecto > Exportar.
3. Añade Windows Desktop (x86_64).
4. Exporta el ejecutable.

La compilación del ejecutable todavía no se ha ejecutado ni verificado en CI.

## Documentación
- Diseño funcional: docs/PRODUCT_BLUEPRINT.md
- Diseño del sistema de personajes: docs/CHARACTER_AI_DESIGN.md
- Rig en tiempo real: docs/RIG_RUNTIME.md
- Generador procedural: scripts/character_procedural_animator.gd
