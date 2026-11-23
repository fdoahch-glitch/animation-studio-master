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
- Ensamblado de rig 2D desde piezas recortadas y puntos articulares entregados por un proveedor IA.
- Adaptador HTTP configurable para segmentación con máscaras, puntos articulares, generación de vistas y propuestas de poses.
- Constructor de esqueleto 3D con Skeleton3D y piezas geométricas de referencia; utilidad de planos 2.5D.
- Animaciones base reproducibles desde el estudio: reposo, caminar, correr, saltar, hablar y saludar.
- Vista previa real del rig dentro de un SubViewport y controles para probar cada ciclo.
- Selector de vistas de referencia: frente, perfil, espalda y tres cuartos.
- Seis ciclos de animación 2D base y controles de ajuste manual de articulaciones.

## Estado honesto de IA
El programa incorpora preparación local de imágenes, rigs 2D por piezas, animaciones base, pivotes editables, un constructor Skeleton3D segmentado y un adaptador HTTP para conectar un servicio de IA. El adaptador puede solicitar segmentación, máscaras, puntos articulares, vistas de giro y poses. **No se incluye un modelo IA ni un servidor de inferencia**: para obtener segmentación semántica y generación real se debe configurar un endpoint compatible según `docs/AI_PROVIDER_CONTRACT.md`. Sin ese servicio, el procesamiento local solo elimina fondos planos conectados a los bordes y propone recortes proporcionales aproximados. El rig 3D actual usa piezas geométricas ancladas a huesos; todavía no hace skinning de una malla artística ni contiene ciclos de animación 3D. El rig 2D usa sprites recortados y pivotes; puede requerir revisión manual de máscaras, pivotes y solapamientos.

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
- Rig en tiempo real: docs/RIG_RUNTIME.md
- Contrato del proveedor IA: docs/AI_PROVIDER_CONTRACT.md
