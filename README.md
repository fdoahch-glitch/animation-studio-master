# Animation Studio Master

Animation Studio Master es un creador de animaciones por escenas desarrollado con Godot 4.x para Windows 10/11 x64. El flujo principal está orientado a diseñar escenas, preparar personajes, animar propiedades y articulaciones, organizar recursos y guardar proyectos portables. No pretende ser un editor de vídeo tradicional.

## Funciones implementadas

- Asistente de proyectos con resolución, orientación, FPS y modos 2D, 2.5D, 3D e híbrido.
- Proyectos editables .amsproj/JSON, migración de esquema y guardado/carga.
- Editor de escenas con creación, duplicación, eliminación y reordenación.
- Lienzo con selección, arrastrar/soltar marcadores, movimiento, zoom anclado, desplazamiento, rotación, escala, profundidad, visibilidad, capas e inspector.
- Biblioteca local con importación de PNG, JPG, JPEG, WebP, GLB y glTF según categoría; búsqueda, etiquetas, metadatos y vínculo de recursos a escenas.
- Timeline de animación por objeto y propiedad, con fotogramas, keyframes, curvas linear/ease_in/ease_out/ease_in_out/step, reproducción y edición/eliminación de claves en el fotograma seleccionado.
- Timeline de poses para rigs 2D/3D y generación procedural de poses y ciclos.
- Preparación de personajes 2D, pivotes, controles de articulación e IK por arrastre para rigs compatibles.
- Herramientas de referencia y rig 3D, auditoría de esqueletos y retargeting básico de poses.
- Paquetes portables .asbundle, paquetes de personaje JSON y exportación de spritesheet PNG.
- Modelos de dirección ambiental, presets horarios, clima, capas parallax y keyframes ambientales.
- Guiones, subtítulos temporizados, grabación directa de micrófono a WAV, registro de tomas importadas y estimación básica de visemas.
- Auditoría de recursos, rutas faltantes y presupuestos de rendimiento.
- Herramientas audiovisuales multipista heredadas, conservadas como módulo secundario.

## Límites conocidos que siguen en desarrollo

- La previsualización y el procesamiento completo de modelos GLB/glTF externos requieren validación adicional; catalogar un modelo no equivale a un visor 3D terminado.
- El rig 3D de referencia no realiza todavía skinning automático de mallas artísticas.
- El retargeting actual se centra en equivalencias y transferencia de poses; no convierte de forma completa clips AnimationPlayer ni resuelve todo el root motion y los offsets de bind pose.
- El sistema ambiental conserva parámetros y perfiles; la conexión completa a luces, partículas y render final requiere trabajo adicional.
- La grabación directa de micrófono guarda tomas WAV y las vincula a líneas del guion; la monitorización avanzada y la sincronización labial fonética completa siguen pendientes.
- El paquete portable de proyecto no sustituye una exportación final de vídeo.
- La exportación profesional de vídeo MP4 con codecs acelerados y fallback CPU todavía no está certificada ni debe anunciarse como disponible.
- El instalador Windows y la prueba de instalación limpia aún requieren implementación y validación.

La animación procedural opera sobre las articulaciones disponibles: no inventa píxeles, no reconstruye partes ocultas ni genera ilustraciones nuevas. La calidad final depende de los recursos y de la preparación anatómica del personaje.

## Desarrollo y validación

El proyecto utiliza Godot 4.3 o superior. Las pruebas automatizadas están en `tests/` y GitHub Actions valida la importación, ejecución headless, modelos, timeline, rigs, portabilidad y rendimiento. La compilación Windows se ejecuta en el workflow **Windows desktop build**.

Comandos locales de referencia:

```bash
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/test_timeline_tracks.gd
```

## Windows

Las versiones preliminares verificadas se publican en GitHub Releases con `AnimationStudioMaster.exe` y el paquete ZIP x64. Se debe comprobar que el workflow **Windows desktop build** correspondiente al último commit haya terminado correctamente y que los archivos estén cargados antes de considerar disponible una compilación.

## Documentación

- Diseño funcional: `docs/PRODUCT_BLUEPRINT.md`
- Flujo de producción: `docs/UX_AND_PRODUCTION_WORKFLOW.md`
- Composición de escenas: `docs/SCENE_COMPOSITION.md`
- Sistema de personajes: `docs/CHARACTER_SYSTEM_DESIGN.md`
- Rig en tiempo real: `docs/RIG_RUNTIME.md`
- Rig espacial y retargeting: `docs/SPATIAL_RIG_AND_RETARGETING.md`
- Portabilidad y calidad: `docs/STAGES_9_10_PORTABILITY_QUALITY.md`

El archivo `project_data/roadmap_10_etapas.json` conserva el registro técnico del desarrollo. El supervisor no reemplaza la implementación ni las pruebas funcionales.
