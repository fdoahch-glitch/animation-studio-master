# Animation Studio Manager

Estudio visual de animación por escenas, desarrollado con Godot 4.x y orientado a Windows 10/11 x64.

## Visión

Crear animaciones mediante un flujo visual de arrastrar, soltar y configurar: proyecto, escenas, personajes, fondos, elementos, decoraciones, tiempo/clima, animación, doblaje y exportación.

La especificación completa está en [docs/PRODUCT_BLUEPRINT.md](docs/PRODUCT_BLUEPRINT.md).

## Prototipo técnico actual

La primera base subida incluye:
- Proyecto Godot 4.x.
- Lienzo de dibujo con ratón.
- Fotogramas básicos y reproducción.
- Deshacer y limpiar trazos.
- Guardado y apertura local de datos JSON.

**Importante:** el prototipo todavía no implementa el estudio completo descrito en la visión. No incluye aún importación avanzada, biblioteca de personajes, IA de rigging, edición 2.5D/3D, grabación de voz ni exportación final de vídeo.

## Abrir y ejecutar

1. Instala Godot 4.x desde https://godotengine.org/download/.
2. Clona o descarga este repositorio.
3. En Godot, pulsa **Importar** y selecciona la carpeta que contiene `project.godot`.
4. Abre el proyecto y pulsa **F6/F5** o el botón Ejecutar.

## Exportar para Windows

1. Instala las plantillas desde **Editor > Administrar plantillas de exportación**.
2. Abre **Proyecto > Exportar**.
3. Añade un preset **Windows Desktop** (x86_64).
4. Exporta el ejecutable.

## Configuración de proyecto objetivo

Ejemplo solicitado: **1920 × 1080, 60 FPS**. La aplicación deberá permitir elegir resolución, orientación, FPS y modo visual (2D, 2.5D, 3D o Híbrido) antes de crear el lienzo.

## Próximo hito

Construir el asistente de nuevo proyecto y la interfaz principal por secciones, con inspector contextual y escenario preparado para arrastrar y soltar recursos.
