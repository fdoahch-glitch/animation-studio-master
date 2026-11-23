# Animation Studio Master

Estudio visual de animación por escenas, desarrollado con Godot 4.x y orientado a Windows 10/11 x64.

## Novedades del prototipo
- Asistente inicial antes de abrir el espacio de trabajo.
- Presets de resolución hasta 4K, orientación y 24/25/30/50/60 FPS.
- Modos 2D, 2.5D, 3D e Híbrido.
- Panel de producción por tareas: Escenas, Personajes, Biblioteca, Animación, Diálogos, Ambiente y Exportación.
- Timeline visual de animación con regla de fotogramas, pistas y keyframes; el usuario selecciona el tiempo por fotograma y el motor lo convierte usando los FPS del proyecto.
- La edición audiovisual multipista se conserva en Herramientas audiovisuales heredadas y no es el centro del flujo de trabajo.
- Estudio de personajes con ficha, estilo y tipo de rig.
- Constructor de rig 2D editable en tiempo de ejecución, con pivotes, controles manuales de articulaciones y manejadores IK por arrastre para manos y pies (rig estándar y por sprites segmentados).
- Importación de imagen, eliminación local aproximada de fondo plano y exportación de recortes anatómicos proporcionales.
- Generador procedural integrado de 20 poses expresivas y 20 ciclos de animación (respirar, caminar, correr, saltar, saludar, hablar, celebrar, bailar y más).
- Keyframes calculados matemáticamente, curvas suaves y aplicación directa a rigs 2D estándar y segmentados.
- Funcionamiento sin Internet, claves API, servidores, modelos externos ni procesos IA en segundo plano.
- Constructor de esqueleto 3D con Skeleton3D y piezas geométricas de referencia; utilidad de planos 2.5D.
- Animaciones base reproducibles desde el estudio: reposo, caminar, correr, saltar, hablar y saludar.
- Vista previa real del rig dentro de un SubViewport y controles para probar cada ciclo.
- Selector de vistas de referencia: frente, perfil, espalda y tres cuartos.
- Seis ciclos de animación 2D base y controles de ajuste manual de articulaciones.
- Control de velocidad de reproducción entre 0,25× y 2,5× e intensidad de movimiento ajustable y guardado de poses manuales personalizadas.

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

## Descargar el ejecutable para Windows

El repositorio incluye `export_presets.cfg` y el workflow **Windows desktop build**. Cada push a `main` y cada ejecución manual del workflow compilan el proyecto con Godot 4.3 para Windows x64 y publican el archivo `AnimationStudioMaster.exe` como artefacto de GitHub Actions.

Para descargarlo:
1. Abre la pestaña **Actions** del repositorio.
2. Entra en la ejecución **Windows desktop build** más reciente y espera a que termine correctamente.
3. Al final de la página, en **Artifacts**, descarga `AnimationStudioMaster-Windows-x64`.
4. Descomprime el ZIP y ejecuta `AnimationStudioMaster.exe` en Windows 10/11 de 64 bits.

La validación del proyecto y la compilación de Windows son workflows separados. Un resultado verde en **Godot project validation** no genera por sí solo un ejecutable. El archivo solo debe considerarse disponible cuando **Windows desktop build** termine correctamente y el artefacto aparezca en esa ejecución.

## Documentación
- Diseño funcional: docs/PRODUCT_BLUEPRINT.md
- Diseño del sistema de personajes: docs/CHARACTER_SYSTEM_DESIGN.md
- Rig en tiempo real: docs/RIG_RUNTIME.md
- Generador procedural: scripts/character_procedural_animator.gd


## Progreso verificable y supervisor de etapas

El avance global se registra en `project_data/roadmap_10_etapas.json`. El plan está dividido en diez entregables y se ejecuta en pares consecutivos (1–2, 3–4, 5–6, 7–8 y 9–10), sin saltar una etapa incompleta.

El workflow **Roadmap supervisor** comprueba que existan las diez etapas, que la numeración sea continua y que ninguna etapa posterior se active antes de cerrar la anterior. Una etapa solo puede marcarse como terminada cuando tiene pruebas, evidencia de aceptación y SHA de commit. Esta comprobación es determinista; no es un agente de IA autónomo y no programa cambios por sí sola.

### Proyectos y escenas

- Los proyectos pueden guardarse como archivos portables `.amsproj` o JSON y abrirse desde el explorador de archivos.
- El formato está versionado y migra documentos antiguos al esquema actual.
- El gestor de escenas permite crear, duplicar, eliminar y editar nombre, duración y notas; los cambios se guardan dentro del documento del proyecto.
- La persistencia tiene pruebas headless en `tests/test_project_document.gd`.

El editor de escenas todavía no equivale a un compositor visual completo: arrastrar/soltar recursos sobre el lienzo, inspector de objetos, cámara y transiciones siguen pendientes de implementación y validación.


## Descargas para Windows

Cada compilación correcta del workflow **Windows desktop build** publica automáticamente una versión preliminar en la sección **Releases** con el ejecutable `AnimationStudioMaster.exe` y el paquete `AnimationStudioMaster-Windows-x64.zip`. También conserva el artefacto en Actions durante 30 días.
