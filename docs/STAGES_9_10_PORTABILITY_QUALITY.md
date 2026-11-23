# Etapas 9 y 10 — Portabilidad, calidad y distribución

## Etapa 9: paquete portable de proyecto
`scripts/project_bundle_io.gd` crea un ZIP con manifiesto versionado, documento completo y archivos de recursos referenciados por la biblioteca. La importación valida formato, número de entradas, rutas internas y tamaño agregado, restaura recursos y actualiza sus rutas en el documento. Los formatos .amsproj/.json existentes se conservan. Prueba: `tests/test_project_bundle.gd`.

## Etapa 10: auditoría de calidad y rendimiento
`scripts/performance_auditor.gd` analiza cantidad de escenas, objetos, recursos, tamaño total, rutas faltantes y presupuestos configurables; genera un informe JSON y calcula estimación de memoria de texturas. Incluye una política sugerida de escala dinámica con reducción conservadora y recuperación gradual. Prueba: `tests/test_performance_auditor.gd`.

## Límites pendientes
El auditor no mide FPS/GPU en vivo ni sustituye un perfilador del dispositivo. La escala sugerida aún no está conectada al viewport/renderizador. La creación de un ejecutable Windows y un instalador firmado requiere export templates, certificado y pruebas limpias en Windows; no se declara distribución final certificada. La aceptación visual/dispositivo de etapas anteriores sigue pendiente.
