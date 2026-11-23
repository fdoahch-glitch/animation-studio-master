# Validación funcional de bibliotecas y preparación anatómica

Este documento describe las comprobaciones automatizadas añadidas para las etapas 3 y 4. No sustituye la aceptación visual con modelos y dibujos reales.

## Etapa 3: biblioteca y previsualización GLB

`tests/test_resource_model_preview.gd` crea un GLB temporal con una malla y un clip de animación, lo carga mediante el componente real `ResourceModelPreview` y verifica:

- carga efectiva del modelo en el visor;
- detección y listado del clip importado;
- reproducción y detención de la animación;
- giro del modelo mediante el mismo método usado por el arrastre;
- zoom de cámara;
- limpieza del modelo cargado.

La prueba de biblioteca existente continúa verificando categorías, formatos, límites de tamaño, etiquetas, búsqueda, dependencias GLTF y eliminación segura.

## Etapa 4: preparación de imágenes y anatomía

`tests/test_character_image_processor.gd` genera una imagen sintética controlada y comprueba:

- ajuste local de brillo, contraste y saturación;
- conservación del archivo original;
- eliminación del fondo plano conectado al borde;
- creación de siete regiones anatómicas aproximadas;
- escritura de la imagen procesada y de cada región.

La segmentación es geométrica y aproximada; requiere revisión y corrección manual. No se presenta como detección semántica automática.

## Aceptación visual pendiente

- Etapa 3: importar una imagen y un GLB/glTF externo desde la interfaz; comprobar miniatura, metadatos, reproducción, giro con mouse/toque, zoom y añadido a escena.
- Etapa 4: importar una ilustración real, ajustar textura/tolerancia, revisar recortes, construir el rig segmentado, arrastrar manos/pies con IK, corregir pivotes y reproducir/guardar un clip.

La etapa solo puede cerrarse cuando las pruebas CI estén verdes y la revisión visual correspondiente quede confirmada.
