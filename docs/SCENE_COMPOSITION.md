# Editor de escenas y composición

El gestor de escenas abre un espacio de trabajo con tres zonas:

- **Escenas:** crear, duplicar, eliminar y cambiar el orden de escenas; editar nombre, duración y notas.
- **Lienzo:** vista de la composición según la resolución del proyecto. La paleta permite añadir personajes, fondos, elementos y decoraciones; sus botones también admiten arrastre al lienzo.
- **Inspector:** seleccionar instancias desde el lienzo o la lista de capas y ajustar posición X/Y, escala X/Y, rotación, profundidad y visibilidad. También permite subir/bajar capas, eliminar instancias y guardar una transición de salida.

## Controles del lienzo

- Arrastrar con botón izquierdo o con el dedo: mover el objeto seleccionado.
- Rueda del mouse: acercar/alejar.
- Botón derecho o central: desplazar la cámara del editor.
- **Ajustar vista:** restablece zoom y desplazamiento.

El lienzo convierte coordenadas de pantalla a coordenadas de proyecto, de modo que el posicionamiento no depende del tamaño del panel. Los fondos se dibujan detrás de los demás objetos y la profundidad determina el orden visual. El hit-test considera profundidad y rotación.

## Guardado

Las instancias y transformaciones se guardan dentro de `scenes[].objects` en el documento del proyecto. El movimiento se persiste al soltar el objeto; los cambios hechos desde el inspector se guardan al modificarlos. Las transiciones se almacenan en `scenes[].transitions`.

## Alcance de esta etapa

Los botones de la paleta generan marcadores vectoriales de previsualización con identidad de tipo y referencia interna `builtin:`. La conexión con archivos reales, miniaturas importadas y biblioteca de recursos corresponde a la etapa 3. No se presenta un marcador como si fuera un modelo o imagen importados.


## Edición de propiedades y navegación del lienzo

- El inspector permite renombrar la instancia seleccionada desde el campo **Nombre**; el cambio se refleja en la lista de capas y se guarda en el proyecto al confirmar con Enter.
- El zoom con rueda queda anclado al punto situado bajo el cursor, evitando que el contenido salte hacia el centro del lienzo.
- El desplazamiento de cámara se realiza con el botón derecho o central; **Ajustar vista** restablece zoom y desplazamiento.
- La prueba headless del lienzo verifica el zoom anclado y el desplazamiento de cámara además de selección, coordenadas, movimiento y colocación por arrastrar/soltar.

La biblioteca real de recursos y la previsualización GLB pertenecen a la etapa 3; los botones de composición de esta etapa permiten crear marcadores de escena que después se pueden vincular a recursos importados.


## Edición directa de keyframes

En el timeline de dirección, los diamantes de keyframe se pueden arrastrar horizontalmente para cambiar su fotograma. El editor conserva el valor y la curva de interpolación originales, ajusta el tiempo al FPS del proyecto y guarda el cambio. La interacción se cubre con una prueba automatizada de arrastre y señal.


## Cámara animable

Cada escena nueva incluye cámara 2D con posición, zoom y rotación. El director de animación permite crear pistas específicas de cámara y muestrearlas junto a las pistas de objetos. El lienzo transforma las coordenadas de dibujo y selección según la cámara, manteniendo separada la cámara de salida del zoom/paneo de edición. Pruebas: `tests/test_timeline_tracks.gd` y `tests/test_scene_canvas.gd`.


## Biblioteca de recursos — etapa 3

La biblioteca local administra cuatro categorías (personajes, fondos, elementos y decoraciones). Admite PNG/JPG/JPEG/WebP para imágenes y GLB/glTF para personajes, elementos y decoraciones. Cada importación conserva ID, nombre, archivo de origen, extensión, tamaño total, etiquetas, modo visual, compatibilidad, ruta administrada y, para imágenes, miniatura PNG. Los GLTF con buffers o imágenes externos copian y reescriben sus dependencias dentro de la biblioteca; el conjunto completo queda limitado a 256 MB. La vista previa 3D carga la escena, centra la cámara, permite girar con mouse o toque, zoom, inspección de esqueletos y reproducción de clips AnimationPlayer. El viewport solo se actualiza cuando está visible para evitar trabajo de GPU innecesario. La eliminación valida rutas administradas y la interfaz impide eliminar recursos vinculados a instancias de escenas.
