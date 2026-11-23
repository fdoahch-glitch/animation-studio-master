# Animation Studio Manager

Estudio visual de animación por escenas, desarrollado con Godot 4.x y orientado a Windows 10/11 x64.

## Novedades del prototipo
- Asistente inicial antes de abrir el espacio de trabajo.
- Presets de resolución hasta 4K, orientación y 24/25/30/50/60 FPS.
- Modos 2D, 2.5D, 3D e Híbrido.
- Secciones de Escenas, Personajes, Fondos, Elementos, Decoraciones, Tiempo y clima, Animación, Audio y doblaje y Exportar.
- Estudio de personajes con ficha, estilo y tipo de rig.
- Constructor de rig 2D editable en tiempo de ejecución: pivotes jerárquicos, segmentos visuales y articulaciones.
- Animaciones base reproducibles desde el estudio: reposo, caminar, correr, saltar, hablar y saludar.
- Vista previa real del rig dentro de un SubViewport y controles para probar cada ciclo.
- Selector de vistas de referencia: frente, perfil, espalda y tres cuartos.
- Generación de prompt para un proveedor de IA externo.

## Estado honesto de IA
El módulo actual ya construye un rig 2D procedural editable con jerarquía de pivotes, segmentos visuales y seis ciclos de animación que se pueden reproducir en el estudio. Todavía no segmenta automáticamente una ilustración importada, no calcula pesos de deformación de sprites ni genera imágenes o modelos 3D mediante un modelo de IA. Esas capacidades requieren incorporar modelos de segmentación/generación y un adaptador de inferencia; el proyecto no incluye claves API ni envía imágenes a servicios externos por defecto. El rig actual es una base funcional para validar la estructura y el flujo de animación, no un sistema completo de producción.

## Abrir y ejecutar
1. Instala Godot 4.x desde https://godotengine.org/download/.
2. Descarga o clona este repositorio.
3. Importa la carpeta que contiene project.godot.
4. Abre el proyecto y ejecuta con F6/F5.

## Exportar para Windows
1. Instala las plantillas de exportación en Godot.
2. Abre Proyecto > Exportar.
3. Añade Windows Desktop (x86_64).
4. Exporta el ejecutable.

La compilación del ejecutable todavía no se ha ejecutado ni verificado en CI.

## Documentación
- Diseño funcional: docs/PRODUCT_BLUEPRINT.md
- Núcleo de personajes e IA: docs/CHARACTER_AI_DESIGN.md
