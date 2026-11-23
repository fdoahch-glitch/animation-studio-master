# Núcleo de personajes e IA — Animation Studio Manager

## Objetivo
Crear personajes consistentes entre vistas y preparar una estructura de rig editable. Se separan diseño visual, consistencia multivista y rig/animación.

## Implementado en el prototipo
- Constructor de ficha de personaje.
- Plantilla procedural de esqueleto humanoide con jerarquía de huesos.
- Restricciones angulares iniciales para codos y rodillas.
- Catálogo declarativo de vistas: frente, perfil, espalda y tres cuartos.
- Catálogo de acciones sugeridas: idle, caminar, correr, saltar, hablar, girar, saludar y sentarse.
- Prompt de producción multivista.
- Vista esquemática que cambia según la vista seleccionada.

La plantilla no calcula pesos de piel, no segmenta una ilustración y no crea todavía un rig deformable listo para producción.

## Pipeline de IA objetivo
1. Entrada: prompt, imágenes de referencia, estilo, proporciones, vestuario, paleta y modo 2D/2.5D/3D/híbrido.
2. Generación: hoja de personaje consistente, vistas individuales, expresiones, visemas y pose A/T.
3. Segmentación: cabeza, torso, brazos, antebrazos, manos, muslos, piernas y pies; máscaras editables.
4. Rig 2D: Skeleton2D/Bone2D, asociación de partes, pesos iniciales y corrección manual.
5. Rig 2.5D: planos separados, profundidad, pivotes y paralaje.
6. Rig 3D: malla, UV, materiales, esqueleto y skinning. Una hoja 2D no equivale a un modelo 3D.
7. Validación: pruebas de articulaciones, deformación, identidad visual y rangos de movimiento.

## Integración de proveedor
El adaptador futuro debe definir endpoint, autenticación segura, formato de solicitud/respuesta, trabajos asíncronos, progreso, errores, descarga y validación de recursos. No guardar claves en GitHub. No asumir que todos los proveedores usan la misma API. Solicitar consentimiento antes de enviar referencias o descripciones a servicios externos.

El prototipo no conecta proveedor alguno. El botón prepara y copia un prompt, sin transmitirlo.

## Próximas tareas técnicas
- Convertir el blueprint a nodos reales Skeleton2D/Bone2D.
- Editor visual de huesos, pivotes y pesos.
- Importación de hoja multivista y recorte por partes.
- Adaptador concreto para el proveedor de IA elegido.
- Generación y pruebas de poses y exportación.
- Pipeline de modelo 3D para proyectos 3D.
