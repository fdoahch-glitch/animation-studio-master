# Etapas 7 y 8 — Ambiente y narrativa sonora

## Etapa 7: escenarios, iluminación, tiempo y clima
- `scripts/environment_director.gd` define entornos persistibles, capas de fondo con profundidad/parallax/opacidad, presets de hora, clima e intensidad, perfiles de emisión para lluvia/nieve/polvo/viento/niebla y keyframes ambientales interpolables.
- Las propiedades de iluminación y color se conservan como datos portables; la aplicación de luces/partículas a una escena renderizada y la aceptación visual en dispositivo siguen pendientes.
- Prueba: `tests/test_environment_director.gd`.

## Etapa 8: guion, diálogos, audio y doblaje
- `scripts/dialogue_studio.gd` crea guiones, líneas con subtítulos temporizados, tomas vinculadas a diálogos, selección de toma, controles de mezcla y una pista de visemas estimada desde muestras de audio.
- La pista de visemas es una aproximación de amplitud (silencio/A/O/E), no reconocimiento fonético. No se afirma que sea lipsync fonético preciso.
- La captura del micrófono, reproducción/mezcla en tiempo real, cuenta regresiva de grabación y sincronización visual con rigs todavía requieren integración de interfaz y pruebas en dispositivo.
- Prueba: `tests/test_dialogue_studio.gd`.

## Estado y límites
Ambas etapas permanecen `partial`. La aceptación de etapas 2–6 no está cerrada en el roadmap; la regla secuencial impide declararlas completas. Los módulos 7–8 se añaden como trabajo preparatorio verificable, sin falsear el gate.


## Grabación directa de voz

El estudio de diálogos habilita la entrada de audio de Godot y crea un bus dedicado `MicRecord` con `AudioEffectRecord`. El botón de inicio reproduce una fuente `AudioStreamMicrophone`; detener guarda la toma como WAV en `user://animation_studio_recordings/` y la vincula a la última línea del guion como una toma numerada. La grabación requiere un micrófono disponible y permiso del sistema operativo. La captura física debe verificarse en Windows y en cada dispositivo Android de destino; CI solo valida el guardado y la lectura de WAV.


## Cuenta regresiva de grabación

El botón de grabación inicia una cuenta regresiva de tres segundos antes de activar la captura de micrófono. El contador se puede cancelar antes de iniciar; al cambiar de área de trabajo se detiene una cuenta regresiva pendiente para evitar iniciar una grabación fuera del estudio de diálogo. La captura WAV y su vinculación a la última línea de diálogo se mantienen.


## Selección de línea y cuenta regresiva

La lista de diálogo permite elegir explícitamente la línea a la que se asociará una nueva toma, tanto de micrófono como importada. Si no hay una selección válida, se conserva el comportamiento de asociar a la última línea. La cuenta regresiva es una pequeña máquina de estados reutilizable y cubierta por pruebas.


## Vista ambiental integrada en el lienzo

El lienzo de composición y la vista previa del timeline aplican el color del cielo, energía ambiental, sol, capas de fondo parallax y efectos 2D de lluvia, nieve, niebla, polvo y viento. Las capas se enlazan con recursos de la biblioteca; la animación de clima solo procesa fotogramas cuando existe intensidad activa. Los keyframes ambientales se muestrean junto al cabezal del timeline. Prueba de estado de actualización: `tests/test_scene_canvas.gd`.
