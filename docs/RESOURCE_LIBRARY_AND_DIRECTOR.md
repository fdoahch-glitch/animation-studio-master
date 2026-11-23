# Bibliotecas de recursos y timeline de dirección

## Biblioteca local

- Categorías: personajes, fondos, elementos y decoraciones.
- Importación múltiple de PNG, JPG, JPEG y WebP; personajes, elementos y decoraciones también admiten GLB/glTF.
- Los archivos se copian a `user://animation_studio_assets/<categoría>/`; el proyecto conserva ID, nombre, archivo original, extensión, tamaño, etiquetas, modo visual, compatibilidad y ruta administrada.
- Búsqueda local por nombre, archivo y etiquetas.
- La biblioteca valida extensión/categoría, compatibilidad con el modo del proyecto y protege la eliminación para que solo afecte rutas dentro de su carpeta administrada.
- Desde la ficha de biblioteca se puede añadir el recurso seleccionado a la escena como instancia vinculada por ID.

La importación de glTF con dependencias externas no las empaqueta automáticamente; conserva las dependencias junto al modelo original o usa GLB autocontenido.

## Timeline de dirección

- Pistas dirigidas a una instancia de escena y una propiedad: X, Y, escala X/Y, rotación o profundidad.
- Keyframes ordenados por tiempo; al guardar en el mismo instante se reemplaza la clave anterior.
- Curvas: lineal, ease-in, ease-out, ease-in-out y step.
- Muestreo interpolado para previsualizar el valor en el playhead.
- Los tracks se almacenan en `scene_animation_tracks`, separados por ID de escena.
- El timeline de dirección complementa el timeline de poses 2D/3D ya existente; no lo reemplaza.

## Límites actuales

La biblioteca importa y administra archivos, pero la previsualización de modelos 3D y la extracción automática de miniaturas aún requieren validación visual. El timeline nuevo anima propiedades numéricas de instancias; rutas de movimiento, cámara multicapa y mezcla de pistas quedan para ampliación posterior.
