# M07 — Expediente (GET /expedientes/{id})

## Objetivo
Migrar el expediente académico a PostgreSQL reutilizando los métodos reales
introducidos en M06.

## Archivos modificados
- `src/Controller/Demo/TranscriptController.php` (`show()` usa
  `StudentReadRepository`)

## PostgreSQL utilizado
- Mismas fuentes que M06: `sis_aca_vw_avance_pensum`, `estudiante_programa`,
  `estudiante_periodo`, `periodo_academico`, `anio_lectivo`,
  `ciclo_curricular`, `seccion`, `sis_aca_vw_resultado_estudiante`.

## Comportamiento
- Cada período (`period-card`) se agrupa con sus resultados
  (`r.period == p.periodLabel`): código, nombre, tipo (badge), sección,
  nota, estado (badge), intento.
- Resumen lateral: `vm.progress`, `approved`, `pending`, `repeats`.

## Pruebas
- `php -l` OK.
- `/expedientes/1` → 200, resultados reales agrupados por período.
- `/expedientes/99999` → 404.
- Regresión: `/` 200.
- Captura: `docs/frontend/screenshots/07_expediente_pg_desktop.png`.

## Pendientes
- FASE D: `/evaluacion/notas` con vista de ingreso de notas (`sis_aca_vw_ingreso_notas`).
