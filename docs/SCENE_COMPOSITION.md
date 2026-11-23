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
