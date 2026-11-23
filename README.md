# Animation Studio Manager

Estudio visual de animación por escenas, desarrollado con Godot 4.x y orientado a Windows 10/11 x64.

## Novedades del prototipo
- Asistente inicial antes de abrir el espacio de trabajo.
- Presets de resolución hasta 4K, orientación y 24/25/30/50/60 FPS.
- Modos 2D, 2.5D, 3D e Híbrido.
- Secciones de Escenas, Personajes, Fondos, Elementos, Decoraciones, Tiempo y clima, Animación, Audio y doblaje y Exportar.
- Estudio de personajes con ficha, estilo y tipo de rig.
- Plantilla procedural de esqueleto humanoide con jerarquía de huesos y límites angulares iniciales.
- Selector de vistas de referencia: frente, perfil, espalda y tres cuartos.
- Generación de prompt para un proveedor de IA externo.

## Estado honesto de IA
El núcleo actual no genera ilustraciones mediante un modelo de IA ni realiza rigging automático de imágenes o mallas. Prepara fichas, prompts, una vista esquemática y un esqueleto procedural base. Para generación real de imágenes, reconstrucción multivista y rigging asistido se debe configurar un proveedor/modelo de IA y desarrollar el adaptador correspondiente. No hay claves API incrustadas ni se envían datos por defecto.

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
