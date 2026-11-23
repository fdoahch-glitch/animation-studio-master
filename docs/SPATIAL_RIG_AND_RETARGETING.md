# Etapas 5 y 6: animación 3D y retargeting

## Etapa 5 — Rig 3D humanoide y cuadrúpedo

- Generación de Skeleton3D humanoide y cuadrúpedo con jerarquía anatómica.
- Rig cuadrúpedo con pelvis, columna, pecho, cuello, cabeza, mandíbula, cuatro cadenas de patas y cuatro segmentos de cola.
- Bibliotecas procedurales de poses y ciclos para humanoides y dinosaurios/cuadrúpedos.
- IK de dos huesos para brazos y piernas humanoides y las cuatro extremidades del cuadrúpedo.
- Captura y aplicación de poses; horneado de clips procedurales a AnimationPlayer.
- Conservación y reproducción de animaciones importadas.
- Auditoría estructural: cobertura de huesos requeridos, ausencias y orden jerárquico padre/hijo.

La geometría segmentada del rig de demostración está anclada a huesos. No equivale a skinning automático de una malla artística externa. Para deformar un modelo GLB externo se necesita que ya incluya un esqueleto y pesos de vértices válidos.

## Etapa 6 — Retargeting local

- Normalización de nombres comunes, incluidos prefijos Mixamo y alias humanoides/cuadrúpedos.
- Construcción de un mapa de huesos entre Skeleton3D de origen y destino.
- Informe de cobertura y lista de huesos sin equivalencia.
- Perfiles versionados guardables dentro del proyecto.
- Transferencia de poses con escala y desplazamiento angular configurables por eje.
- UI en el Estudio de personajes para auditar el esqueleto importado y generar/guardar un perfil frente a un rig de referencia humanoide o cuadrúpedo.

El retargeting implementado transfiere poses articulares mediante equivalencias anatómicas. No se afirma todavía retargeting completo de archivos AnimationPlayer con corrección de root motion, offsets de bind pose, IK de contacto o curvas faciales; esos son pasos de ampliación.

## Validación automatizada

`tests/test_spatial_retargeting.gd` comprueba construcción y auditoría de esqueletos humanoide/cuadrúpedo, cantidad de poses y ciclos, reproducción procedural básica, creación/validación de perfiles y transferencia de rotaciones.

La CI ejecuta esta prueba junto con las pruebas de proyecto, escenas, biblioteca y timeline. La validación headless no sustituye una prueba visual con modelos GLB reales de distintas procedencias.


## Retargeting de clips completos

El retargeter convierte bibliotecas de keyframes de animación 3D, traduce nombres de huesos mediante equivalencias canónicas, conserva duración/bucle/tiempos, permite escala y offset de rotación e informa huesos sin equivalencia. El estudio permite guardar los ciclos procedurales convertidos con el último perfil de retargeting. Prueba: `tests/test_spatial_retargeting.gd`.


## Transiciones suaves entre clips 3D

El animador espacial admite fundido cruzado de pose al cambiar entre ciclos y clips, con duración configurable (por defecto 0,18 s). La interpolación combina rotaciones por hueso y evita saltos bruscos entre animaciones. Prueba de interpolación: `tests/test_spatial_retargeting.gd`.
