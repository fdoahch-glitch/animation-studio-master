# Etapas 9 y 10 — Portabilidad, calidad y distribución

## Etapa 9: paquete portable de proyecto
`scripts/project_bundle_io.gd` crea un ZIP con manifiesto versionado, documento completo, archivos de recursos de biblioteca, tomas WAV de diálogo y medios locales del montaje audiovisual. La importación valida formato, número de entradas, rutas internas y tamaño agregado, restaura los archivos y actualiza las rutas de recursos, tomas de audio y medios del montaje en el documento. Los formatos .amsproj/.json existentes se conservan. Prueba: `tests/test_project_bundle.gd`.

## Etapa 10: auditoría de calidad y rendimiento
`scripts/performance_auditor.gd` analiza cantidad de escenas, objetos, recursos, tamaño total, rutas faltantes y presupuestos configurables; genera un informe JSON y calcula estimación de memoria de texturas. Incluye una política sugerida de escala dinámica con reducción conservadora y recuperación gradual. Prueba: `tests/test_performance_auditor.gd`.

## Límites pendientes
El auditor no mide FPS/GPU en vivo ni sustituye un perfilador del dispositivo. La escala sugerida aún no está conectada al viewport/renderizador. El workflow de Windows genera EXE, ZIP e instalador Inno Setup x64. Ejecuta una instalación silenciosa, verifica que el ejecutable quede instalado, lo inicia en modo headless y desinstala. El instalador no está firmado digitalmente; la prueba de instalación gráfica en un Windows de usuario sigue pendiente. La aceptación visual/dispositivo de etapas anteriores sigue pendiente.


## Timeline visual multipista

`scripts/video_timeline_view.gd` presenta pistas y clips en una escala temporal desplazable horizontalmente. Permite seleccionar pistas/clips, mover el cabezal al pulsar la regla y arrastrar clips entre tiempos sin perder el desplazamiento del punto de agarre. La vista se sincroniza con el modelo de montaje y el documento del proyecto. Prueba de interacción: `tests/test_video_timeline_view.gd`.
