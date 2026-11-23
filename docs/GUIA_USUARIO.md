# Guía de usuario — Animation Studio Master

## Descargar e instalar en Windows

En la página de Releases del repositorio se publican tres opciones:
- AnimationStudioMaster-Setup-x64.exe: instalador Windows x64.
- AnimationStudioMaster-Windows-x64.zip: versión portable.
- AnimationStudioMaster.exe: ejecutable directo.

El workflow de Windows instala silenciosamente el instalador en una carpeta limpia de prueba, verifica que se copie el ejecutable, inicia la aplicación en modo headless y desinstala. El instalador no está firmado digitalmente; Windows puede mostrar una advertencia de SmartScreen.

Descargas: https://github.com/fdoahch-glitch/animation-studio-master/releases

## Proyecto y recursos

- Guarda el proyecto editable en formato .amsproj con esquema versionado.
- Usa Biblioteca de recursos para importar imágenes, audio y modelos 3D.
- Los paquetes .asbundle incluyen manifiesto, documento, recursos de biblioteca, tomas de voz y medios usados por clips de vídeo.
- Al importar un .asbundle se validan versión, nombres, límites y rutas; los paths de los recursos se actualizan a la carpeta restaurada.
- Conserva una copia de seguridad antes de importar un paquete sobre una carpeta con trabajo previo.

## Personajes 2D y 3D

- Prepara imágenes, ajusta brillo/contraste/saturación y revisa las regiones anatómicas generadas.
- Corrige pivotes y jerarquías del rig 2D, usa IK y guarda ciclos.
- Importa GLB/glTF con esqueletos humanoides o cuadrúpedos y comprueba la cobertura.
- Crea perfiles de retargeting, calibra offsets de bind pose por hueso y ajusta root motion.
- Los objetivos de contacto IK pueden resolverse durante la reproducción de clips.

## Escenarios

La previsualización ambiental permite ajustar hora, luz solar/ambiental, colores, clima, viento, niebla, partículas y capas de fondo con profundidad y parallax. Guarda keyframes para interpolar cambios durante la escena.

## Diálogo y doblaje

Crea líneas y varias tomas por personaje. Puedes grabar con micrófono o importar WAV/OGG/MP3, ajustar ganancia, offset y silencio, y reproducir las tomas. La generación de visemas desde WAV PCM usa energía por ventana; es una aproximación visual, no reconocimiento fonético.

## Diagnóstico y rendimiento

Usa la auditoría de rendimiento para generar un informe JSON de escenas, objetos, recursos, rutas faltantes y presupuestos. La recomendación de escala dinámica es conservadora y no sustituye una medición de GPU/FPS en cada equipo.

## Limitaciones conocidas

- El instalador Windows no está firmado digitalmente.
- La extracción de visemas es aproximada y requiere ajuste manual cuando se necesita sincronía fonética precisa.
- Los resultados visuales dependen del rig, pesos, materiales y calidad del modelo importado.
