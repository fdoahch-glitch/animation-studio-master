# Animation Studio Manager

Editor de animación 2D para Windows 10/11 x64, desarrollado con Godot 4.x.

## Estado actual

Esta primera base ejecutable incluye:
- Interfaz de escritorio con área de trabajo.
- Lienzo 2D con dibujo mediante ratón.
- Deshacer el último trazo y limpiar el lienzo.
- Línea de tiempo con creación y selección de fotogramas.
- Reproducción básica de la secuencia.
- Guardado y apertura de un proyecto JSON local.

## Abrir y ejecutar

1. Instala Godot 4.x desde https://godotengine.org/download/.
2. Descarga o clona este repositorio.
3. En Godot, pulsa **Importar** y selecciona la carpeta que contiene `project.godot`.
4. Abre el proyecto y pulsa **F6/F5** o el botón Ejecutar.

## Exportar para Windows

1. En Godot, instala las plantillas de exportación desde **Editor > Administrar plantillas de exportación**.
2. Abre **Proyecto > Exportar**.
3. Añade un preset **Windows Desktop** (x86_64).
4. Exporta el ejecutable.

## Formato de proyecto

La primera versión guarda los trazos y fotogramas en JSON dentro de la carpeta de datos de usuario, con el nombre `animation_studio_project.json`.

## Próximas etapas previstas

- Capas reales múltiples y propiedades por capa.
- Herramientas de selección, formas, relleno, borrador y paleta.
- Onion skin (papel cebolla), FPS configurable y atajos.
- Formato de proyecto propio `.amsproj`.
- Importación de imágenes y personajes.
- Biblioteca de fondos, personajes y objetos.
- Exportación de secuencias y vídeo MP4 mediante FFmpeg.
- Asistente para historias y herramientas de IA.
- Flujo de exportación de alta resolución, hasta 4K.

Las funciones de la lista anterior son objetivos de desarrollo; no se presentan como implementadas en esta primera base.
