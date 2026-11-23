# Bibliotecas de recursos y timeline de dirección

## Biblioteca local

- Categorías: personajes, fondos, elementos y decoraciones.
- Importación múltiple de PNG, JPG, JPEG y WebP; personajes, elementos y decoraciones también admiten GLB/glTF.
- Los archivos se copian a `user://animation_studio_assets/<categoría>/`; el proyecto conserva ID, nombre, archivo original, extensión, tamaño, etiquetas, modo visual, compatibilidad y ruta administrada.
- Búsqueda local por nombre, archivo y etiquetas.
- La biblioteca valida extensión/categoría, compatibilidad con el modo del proyecto y protege la eliminación para que solo afecte rutas dentro de su carpeta administrada.
- La ficha de biblioteca muestra una vista previa de las imágenes importadas, junto con nombre, archivo, tamaño, etiquetas y modos compatibles.
- Los modelos GLB/glTF se cargan en una vista previa 3D temporal; cuando incluyen AnimationPlayer, la ficha permite seleccionar, reproducir y detener sus clips. También informa el número de huesos y la cobertura anatómica estimada humanoide/cuadrúpeda de cada Skeleton3D detectado. También se pueden añadir a escenas como instancias vinculadas por ID.
- Desde la ficha de biblioteca se puede añadir el recurso seleccionado a la escena como instancia vinculada por ID.

La importación de glTF con dependencias externas no las empaqueta automáticamente; conserva las dependencias junto al modelo original o usa GLB autocontenido.

## Timeline de dirección

- Pistas dirigidas a una instancia de escena y una propiedad: posición XY combinada, X, Y, escala X/Y, rotación o profundidad.
- La pista de posición XY interpola ambos ejes en un único conjunto de keyframes para construir trayectorias.
- El timeline incluye un lienzo de previsualización no editable; el muestreo aplica las pistas sobre una copia temporal de la escena y nunca sobrescribe las transformaciones base del proyecto.
- Keyframes ordenados por tiempo; al guardar en el mismo instante se reemplaza la clave anterior.
- Curvas: lineal, ease-in, ease-out, ease-in-out y step.
- Muestreo interpolado para previsualizar el valor en el playhead.
- Al seleccionar un fotograma se actualiza el valor interpolado en el inspector de keyframes; se puede añadir/actualizar o eliminar la clave del fotograma actual.
- Los tracks se almacenan en `scene_animation_tracks`, separados por ID de escena.
- El timeline de dirección complementa el timeline de poses 2D/3D ya existente; no lo reemplaza.

## Límites actuales

La biblioteca muestra imágenes importadas en una vista previa 2D y carga modelos GLB/glTF mediante GLTFDocument en una vista 3D con iluminación, encuadre automático, giro horizontal, zoom y reproducción de clips AnimationPlayer importados. La extracción y persistencia de miniaturas 3D aún requiere implementación y validación visual. El timeline nuevo anima propiedades numéricas de instancias; rutas de movimiento, cámara multicapa y mezcla de pistas quedan para ampliación posterior.
