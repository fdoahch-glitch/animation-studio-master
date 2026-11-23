# Flujo de trabajo e interfaz de Animation Studio Master

## Principio de producto

Animation Studio Master es un creador de animaciones por escenas. El centro de trabajo es el lienzo, los personajes, los rigs, las pistas de animación, los keyframes y el sonido sincronizado. La edición audiovisual multipista se conserva como herramienta heredada de compatibilidad, no como navegación principal.

## Inicio del proyecto

El asistente inicial configura nombre, resolución, FPS, orientación y modo visual. El panel de inicio muestra el proyecto actual, sus escenas y recursos, y ofrece accesos directos al flujo de producción.

## Flujo recomendado

1. **Escenas y composición:** crear escenas, añadir recursos, mover objetos en el lienzo, organizar capas y definir transiciones.
2. **Personajes:** importar imágenes o modelos, preparar articulaciones, construir rigs y probar acciones procedurales.
3. **Biblioteca:** clasificar y reutilizar personajes, fondos, elementos y decoraciones.
4. **Animación:** crear pistas vinculadas a objetos y propiedades, insertar keyframes y seleccionar interpolación.
5. **Diálogo y sonido:** organizar líneas, subtítulos, tomas y datos de visemas.
6. **Ambiente:** configurar hora, clima y dirección ambiental.
7. **Exportación:** preparar el proyecto y acceder a los formatos que estén realmente implementados y validados.

## Mejoras de usabilidad aplicadas

- Panel de inicio por tareas, con descripciones breves y botones de acción directa.
- Orden de producción claro, desde escenas y personajes hasta animación y exportación.
- Menos navegación simultánea: las herramientas se agrupan por finalidad.
- La edición audiovisual tradicional sale de la navegación principal y queda accesible en herramientas heredadas.
- Se conserva el acceso a todos los módulos y datos existentes.

## Adaptación de Atrapacuentos Studio

Se toman como referencias de arquitectura y experiencia, no como código o motor para copiar indiscriminadamente:

- flujo de producción por escenas;
- organización de personajes, guion, diálogos y tomas;
- sincronización temporal de voz y visemas;
- exportación cuadro a cuadro con progreso, validación de capacidades y diagnóstico;
- guardado seguro, versiones de recuperación y detección de cierres inesperados;
- métricas de etapas de render y codificación para diagnosticar cuellos de botella.

La exportación de Atrapacuentos está construida alrededor de WebCodecs/FFmpeg y un núcleo Rust/wgpu. Animation Studio Master utiliza Godot 4.3; por tanto, esa arquitectura debe adaptarse al renderizador de Godot y a un codificador FFmpeg integrado de forma verificable. No se debe presentar como integrada una ruta de exportación que todavía no exista.

## Próximas prioridades técnicas

- timeline visual por fotogramas, con escala de tiempo, pistas legibles y selección de fotograma;
- exposición de dibujos y animación fotograma a fotograma;
- curvas de interpolación editables y rutas de movimiento;
- guardado automático y recuperación de proyectos;
- render determinista de escenas a secuencias de imágenes;
- codificación MP4/WebM/GIF y audio sincronizado;
- pruebas automatizadas de cada etapa y pruebas visuales de interfaz.

## Estado y límites

La interfaz de inicio organiza módulos ya presentes; no convierte en funcionales por sí sola las capacidades pendientes. El compositor actual usa marcadores para recursos sin imagen asociada, el rig 3D sigue siendo una estructura de referencia y la exportación final de película necesita un pipeline de render/codificación integrado y validado.
