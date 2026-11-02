# 16 — Catálogo de Estados, Mensajes y Microcopy

## 1. Objetivo

Evitar que cada agente invente etiquetas distintas para la misma regla. Los textos siguientes son la redacción canónica inicial.

## 2. Resultados académicos

### APROBADO
Label: `Aprobado`  
Tone: success  
Texto de apoyo: `El curso cumple la nota mínima aplicable al período.`

### REPROBADO
Label: `Reprobado`  
Tone: danger  
Texto: `La nota registrada no alcanza la nota mínima aplicable.`

### PENDIENTE
Label: `Pendiente`  
Tone: warning  
Texto: `Aún no se ha registrado una calificación.`

### SIN_OFERTA
Label: `Sin oferta`  
Tone: neutral  
Texto: `No existe una oferta activa para este curso, período y sección.`

### YA_APROBADO
Label: `Ya aprobado`  
Tone: success/neutral  
Texto: `El estudiante ya aprobó este curso en un período anterior.`

## 3. Período

PLANIFICADO → `Planificado`  
ABIERTO → `Abierto`  
CERRADO → `Cerrado`

Mensaje bloqueado:
`Este período no está abierto. Las calificaciones no pueden modificarse.`

## 4. Programa académico

ACTIVO → `Activo`  
FINALIZADO → `Finalizado`  
RETIRADO → `Retirado`

## 5. Inscripción por período

INSCRITO → `Inscrito`  
FINALIZADO → `Finalizado`  
RETIRADO → `Retirado`

## 6. Motivos de bloqueo de notas

`PERIODO_NO_ABIERTO`
> El período no está abierto. No es posible registrar o modificar calificaciones.

`ESTUDIANTE_NO_INSCRITO`
> El estudiante no se encuentra inscrito en este período.

`SIN_OFERTA`
> No existe una oferta del curso disponible para este período y sección.

`OFERTA_INACTIVA`
> La oferta académica está inactiva.

`YA_APROBADO`
> El curso ya fue aprobado y no requiere un nuevo intento.

## 7. Traducción de errores backend

SA204 → período no abierto.  
SA205 → estudiante no inscrito.  
SA206 → oferta inactiva.  
SA207 → curso ya aprobado.  
SA208 → corrección histórica incompatible con intentos posteriores.  
SA401 → contexto académico protegido.

El código se puede registrar en logs, no mostrar como mensaje principal.

## 8. Empty states

### Sin estudiantes
Título: `No encontramos estudiantes`  
Texto: `Ajusta los filtros o registra un nuevo estudiante.`

### Sin resultados de reporte
`No hay información para los filtros seleccionados.`

### Sin notas
`Este estudiante todavía no tiene resultados académicos.`

### Sin pendientes
`No se encontraron cursos pendientes para este estudiante.`

### Sin ofertas
`No existen ofertas académicas disponibles en el contexto seleccionado.`

## 9. Confirmaciones

Guardar notas:
`¿Guardar los cambios de calificación?`

Descartar:
`Hay cambios sin guardar. ¿Deseas salir?`

Cierre de período (fase backend):
`Cerrar un período bloquea la edición de resultados. Esta acción requiere confirmación.`

## 10. Éxito

`Estudiante registrado correctamente.`  
`Cambios guardados.`  
`Notas actualizadas correctamente.`  
`Reporte preparado.`

En V1 estos mensajes pueden ser simulados sin persistencia.
