# Ambiente, clima y doblaje

## Escenarios — etapa 7

El Estudio de escenarios mantiene una previsualización SceneCanvas dedicada y conectada al catálogo de recursos del proyecto. Los cambios de ambiente se reflejan tanto en esa previsualización como en el lienzo principal.

Controles disponibles:
- presets de amanecer, mañana, mediodía, tarde, atardecer y noche;
- interpolación continua por hora de energía solar, luz ambiental y colores de cielo/luz;
- selección de color de cielo y sol;
- clima despejado, lluvia, nieve, viento, niebla y polvo;
- intensidad de clima, fuerza del viento, densidad de niebla y activación de partículas;
- capas de fondo vinculadas a recursos, ordenadas por profundidad y con parallax, opacidad y visibilidad editables;
- keyframes ambientales con interpolación de valores numéricos y colores, reemplazo y eliminación.

Las partículas desactivadas no mantienen un ciclo de redibujado. La previsualización respeta la intensidad, densidad y viento configurados.

## Diálogo y doblaje — etapa 8

Cada línea puede tener múltiples tomas de audio. El usuario puede seleccionar una toma, ajustar ganancia en dB, offset, silencio y reproducir/detener el archivo WAV, OGG o MP3.

La captura directa usa AudioEffectRecord, cuenta regresiva y guardado WAV. También se pueden importar tomas externas.

Para WAV PCM de 8 y 16 bits se genera una pista de visemas temporizada mediante energía por ventana. La estimación clasifica silencio y aperturas aproximadas A/O/E; no es reconocimiento fonético ni reemplaza un modelo de fonemas. La pista queda vinculada a la línea y puede previsualizarse en los blend shapes del rig 3D.

El animador espacial reproduce pistas de visemas, interpola su intensidad y permite detener la sincronización.

## Pruebas

- tests/test_environment_director.gd: presets, interpolación horaria, luces, colores, clima, viento, niebla, capas y keyframes.
- tests/test_scene_canvas.gd: ciclo de render del clima y desactivación de partículas.
- tests/test_dialogue_studio.gd: tomas, mezcla, WAV PCM, visemas, blend shapes y reproducción temporizada.
