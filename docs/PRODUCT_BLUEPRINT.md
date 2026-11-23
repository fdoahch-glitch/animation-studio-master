# Diseño funcional — Animation Studio Manager

## Visión del producto

Animation Studio Manager será un estudio visual de animación por escenas. El flujo principal será **crear proyecto → elegir formato → construir escenario → colocar y dirigir personajes → grabar voces → montar y exportar el capítulo**. La experiencia debe ser de arrastrar, soltar y configurar mediante paneles claros, sin obligar al usuario a programar.

Este documento define el comportamiento objetivo. No significa que todas estas funciones estén implementadas todavía.

## 1. Crear proyecto: configuración antes del lienzo

Al pulsar «Nuevo proyecto» se abre un asistente. El lienzo no aparece hasta confirmar:

- Nombre del proyecto y carpeta.
- Resolución: presets 720p, 1080p, 1440p, 4K y tamaño personalizado.
- Orientación: horizontal, vertical o cuadrada.
- Fotogramas por segundo: 24, 25, 30, 50 o 60 FPS; permitir 60 FPS.
- Espacio de trabajo: 2D, 2.5D, 3D o Híbrido.
- Fondo inicial: vacío, biblioteca, imagen importada o generar/ayudar con IA.
- Duración inicial o creación por escenas.

Ejemplo de preset solicitado: **1920 × 1080, 60 FPS, Híbrido o 2D según elección**.

El proyecto guarda esta configuración como propiedades maestras. Los recursos y escenas se adaptan al modo elegido; no se deben mezclar objetos 3D en un proyecto 2D puro.

## 2. Espacio principal: secciones de producción

La interfaz se organiza en secciones accesibles desde una barra superior o lateral:

1. **Escenas** — capítulos, escenas, orden, duración, transiciones y notas.
2. **Personajes** — biblioteca de personajes, poses, rigs, acciones y diálogos.
3. **Fondos** — fondos generados, importados o creados; planos y profundidad.
4. **Elementos** — objetos que interactúan con personajes y entorno (muebles, vehículos, herramientas, etc.).
5. **Decoraciones** — vegetación, partículas, detalles ambientales y objetos de ambientación.
6. **Tiempo y clima** — hora, momento del día, iluminación, lluvia, nieve, viento, niebla y otros estados.
7. **Animación** — línea de tiempo, pistas, keyframes, curvas, cámara y eventos.
8. **Audio y doblaje** — voces, música, efectos, subtítulos, tomas y sincronización.
9. **Exportar** — render, resolución, FPS, formato, audio y subtítulos.

El centro de trabajo mantiene el escenario visible. Cada sección abre su biblioteca y herramientas sin perder la escena actual.

## 3. Modo visual y reglas de compatibilidad

- **2D:** sprites, dibujos, esqueletos 2D, capas y cámara ortográfica. No introducir geometría 3D visible.
- **2.5D:** composición por planos con profundidad, paralaje, cámara con desplazamiento y elementos 2D en espacio 3D.
- **3D:** modelos, materiales, esqueletos 3D, iluminación y cámara tridimensional.
- **Híbrido:** combinar recursos 2D y 3D con controles explícitos de profundidad, orden, cámara y render.

La elección inicial define las herramientas y filtros de las bibliotecas. Se podrá cambiar más tarde mediante conversión asistida, avisando de los elementos que requieren ajuste.

Los personajes deben poder rotar sobre su eje cuando el tipo de recurso lo permita. Para 2D se usarán vistas/poses, sprites o rigs 2D; para 2.5D se podrán usar planos orientados a cámara; para 3D, modelos con rig 3D. No prometer rotación volumétrica real de una imagen plana sin reconstrucción o modelo 3D.

## 4. Fondos inteligentes y ambiente

El usuario podrá:
- Elegir un fondo de la biblioteca del programa.
- Importar una imagen propia.
- Usar una imagen generada externamente y añadirla al proyecto.
- Solicitar asistencia de IA para analizar el fondo y proponer capas, profundidad, zonas de movimiento y puntos de anclaje.

Herramientas de preparación del fondo:
- Separación asistida de primer plano, plano medio y fondo, con máscara editable.
- Creación de capas/parallax para 2.5D.
- Esqueleto o deformadores para elementos orgánicos cuando el análisis lo permita.
- Viento configurable para árboles, hojas, cabello, ropa y elementos flexibles.
- Movimiento ambiental: agua, nubes, humo, polvo, partículas y luces.
- Controles manuales para corregir segmentación, pivotes, máscaras y rig.

La IA debe ser una asistencia verificable: mostrar lo que detectó, permitir corregirlo y nunca destruir la imagen original. Si no existe un proveedor/modelo configurado o conexión disponible, el programa debe informar y mantener herramientas manuales utilizables.

## 5. Personajes listos para animar

La aplicación incluirá una biblioteca inicial de personajes originales de alta calidad visual, con dirección de arte coherente entre ellos. Cada ficha debe mostrar vista previa, estilo, dimensiones, tipo de rig, modos compatibles y acciones disponibles.

Cada personaje podrá contener:
- Arte fuente y variantes de vista/pose.
- Rig 2D (huesos, pesos y deformación) o rig 3D (esqueleto y skinning).
- Pivotes, puntos de apoyo y zonas de contacto.
- Acciones reutilizables: idle, caminar, correr, saltar, girar, gesticular, sentarse, etc.
- Estados faciales y formas de boca para diálogo.
- Parámetros editables y posibilidad de reemplazar/importar arte.

Los personajes de biblioteca deben ser recursos originales, no copias de personajes protegidos. La calidad final dependerá de los recursos artísticos y modelos incluidos en el repositorio.

## 6. Arrastrar, soltar y panel de acciones

Al arrastrar un personaje, fondo, elemento o decoración al escenario, se crea una instancia editable. Al seleccionar una instancia se abre automáticamente su inspector contextual.

Ejemplo de inspector de personaje:
- **Movimiento:** quedarse quieto, caminar entre puntos, seguir ruta, entrar/salir, saltar, girar.
- **Actuación:** gesto, emoción, mirada, pose y reacción.
- **Diálogo:** texto, idioma, voz/toma, inicio, fin y subtítulos.
- **Apariencia:** escala, orientación, color, profundidad y visibilidad.
- **Física/interacción:** suelo, colisiones, puntos de contacto y objetos vinculados.
- **Tiempo:** fotograma/segundo de inicio, duración, espera y repetición.

Las acciones se colocan como pistas en la línea de tiempo. Los desplazamientos deben poder definirse visualmente arrastrando puntos de inicio y destino en el escenario.

## 7. Tiempo, hora y clima

La sección «Tiempo y clima» tendrá controles para:
- Momento: amanecer, mañana, mediodía, tarde, atardecer, noche y madrugada.
- Hora editable (reloj de 24 horas).
- Intensidad y dirección de luz.
- Lluvia, nieve, tormenta, viento, niebla y nubes.
- Intensidad, velocidad, dirección y duración de cada efecto.
- Cambios animados entre estados a lo largo de la escena.

Estos parámetros pueden afectar luces, cielo, partículas, sonido ambiental y animaciones de elementos. En 2D puro se aplicarán efectos 2D; en 2.5D/3D/híbrido se utilizarán además luces y sistemas espaciales adecuados.

## 8. Estudio de doblaje y grabación guiada

El estudio de doblaje se abre cuando las escenas y diálogos están preparados.

Flujo por toma:
1. Elegir escena, personaje y diálogo.
2. Mostrar el encuadre de vídeo y el texto que debe leer la persona.
3. Preparar micrófono y nivel de entrada.
4. Iniciar cuenta regresiva visible **3, 2, 1**.
5. Reproducir la escena con subtítulos guía sincronizados y resaltado de la frase actual.
6. Grabar la voz mientras se reproduce la animación.
7. Detener, escuchar, repetir o aceptar la toma.
8. Guardar la toma vinculada a personaje, escena y fragmento de diálogo.

La boca del personaje podrá usar visemas/poses de boca y sincronización por fonemas o amplitud como primera aproximación; el usuario podrá ajustar manualmente. La sincronización labial avanzada requiere análisis de audio/idioma y debe poder corregirse.

## 9. Montaje de voces y sincronización global

Todas las tomas aceptadas se incorporan a una línea de tiempo maestra:
- Una pista por personaje/voz, más música y efectos.
- Cada clip conserva su escena, diálogo, duración y posición de tiempo.
- Se pueden mover, recortar, ajustar volumen, fundir y reemplazar tomas.
- Los subtítulos mantienen vínculo con el diálogo y el tiempo.
- Cambiar la duración de una toma debe permitir elegir si se desplazan eventos vinculados.
- Vista de todas las escenas para detectar silencios, solapamientos y desfases.

La exportación debe consolidar vídeo, voces, música, efectos y subtítulos usando una misma referencia temporal y el FPS del proyecto.

## 10. Formato de proyecto y arquitectura

Formato de proyecto recomendado: carpeta portable con manifiesto `project.amsproj` (JSON versionado) y subcarpetas:
- `scenes/`
- `characters/`
- `backgrounds/`
- `elements/`
- `decorations/`
- `audio/recordings/`
- `audio/music/`
- `fonts/`
- `renders/`
- `thumbnails/`

Cada recurso tendrá ID estable, tipo, ruta, metadatos y compatibilidad 2D/2.5D/3D/híbrida. Guardado incremental y recuperación ante fallos son requisitos.

## 11. Orden de construcción recomendado

**Fase 1 — Fundamentos del estudio**
- Asistente de nuevo proyecto con resolución, orientación, FPS y modo visual.
- Navegación por secciones.
- Escenario, selección, arrastrar/soltar y panel inspector.
- Guardado/carga del proyecto y estructura de recursos.

**Fase 2 — Escena y animación**
- Fondos, elementos, decoraciones y personajes.
- Línea de tiempo por pistas y keyframes.
- Movimiento por rutas y acciones reutilizables.
- Cámara y previsualización en tiempo real.

**Fase 3 — Personajes y ambiente**
- Biblioteca de personajes originales.
- Rigs 2D y 3D según modo.
- Herramientas de separación de fondo, máscaras y viento.
- Tiempo, iluminación y clima.

**Fase 4 — Doblaje**
- Guion y subtítulos temporizados.
- Cuenta regresiva y captura de micrófono.
- Tomas, retomas, pistas y sincronización.
- Visemas y ajustes de boca.

**Fase 5 — IA y exportación**
- Integración opcional con modelos/proveedores de IA para análisis, segmentación y asistencia.
- Procesos locales cuando sea viable y proveedores externos configurables.
- Render por lotes, exportación de vídeo/audio/subtítulos y validación final.

## 12. Requisitos de calidad

- Interfaz en español, clara y consistente.
- Operaciones principales mediante arrastrar y soltar.
- Deshacer/rehacer y guardado frecuente.
- No perder originales al procesar recursos.
- Avisar de funciones que requieren IA externa, modelos adicionales o conexión.
- Rendimiento configurable para proyectos 1080p/60 FPS y superiores.
- Evitar prometer que una imagen fija se convierte automáticamente en un personaje 3D riggeado perfecto: el proceso debe ser asistido, editable y dependiente del material de entrada.
