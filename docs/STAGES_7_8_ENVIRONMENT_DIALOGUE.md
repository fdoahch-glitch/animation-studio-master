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
