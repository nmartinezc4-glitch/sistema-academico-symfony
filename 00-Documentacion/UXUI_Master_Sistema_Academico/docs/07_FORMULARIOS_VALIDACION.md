# 07 — Formularios y Validación UX

La BD es autoridad de integridad; Symfony previene y traduce.

## Frontend V1
No persiste: HTML validation + visual feedback + demo state.

## Nuevo estudiante
Reales:
- studentCode → EST_CODIGO
- firstNames → EST_NOMBRES
- lastNames → EST_APELLIDOS
- birthDate → EST_FECHA_NACIMIENTO
- photo → futura EST_FOTO_RUTA
- studentActive → EST_ACTIVO
- curriculumId → EPR_PEN_ID
- programStartDate → EPR_FECHA_INICIO
- programStatus → EPR_ESTADO

Carrera es selector auxiliar para filtrar pensum; no duplicar FK.

## Nota
decimal 0..100, step .01, blank = pendiente. No decidir status en UI. `editable` y `blockReason` llegan del ViewModel.

Motivos: PERIODO_NO_ABIERTO, ESTUDIANTE_NO_INSCRITO, SIN_OFERTA, OFERTA_INACTIVA, YA_APROBADO.

## Traducción SA
SA204 período no abierto; SA205 no inscrito; SA206 oferta inactiva; SA207 curso aprobado; SA208 corrección histórica conflictiva; SA401 contexto congelado.

Nunca mostrar solo SQLSTATE.

## Foto
V1 preview local. V2 filesystem + ruta, nunca BLOB.

Estados: pristine, dirty, valid, invalid, submitting, success, server-error, blocked.
