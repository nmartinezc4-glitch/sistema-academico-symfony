# M10 — Secciones / Ofertas (FASE F)

## Objetivo
Completar FASE F con catálogos reales de secciones y ofertas; los períodos
ya se migraron en FASE E.

## Archivos modificados
- `src/Repository/CurriculumReadRepository.php` (`sections()`, `offerings()`)
- `src/Controller/Demo/CurriculumController.php` (`sections()`, `offerings()`)

## PostgreSQL utilizado
- `sis_aca_seccion`
- `sis_aca_oferta_curso` + `sis_aca_periodo_academico`,
  `sis_aca_anio_lectivo`, `sis_aca_pensum_curso`, `sis_aca_curso`,
  `sis_aca_ciclo_curricular`, `sis_aca_pensum`, `sis_aca_carrera`

## Comportamiento
- `/secciones`: catálogo real de secciones activas (código + nombre).
- `/ofertas`: tabla real oferta (período`año-semestre romano`, curso,
  carrera, sección, ciclo, estado ACTIVO/INACTIVA con badge).

## Pruebas
- `php -l` OK · cache:clear OK · `/secciones` → 200 · `/ofertas` → 200
  (filas reales 2025-I…2026-II).
- Regresión: `/periodos`, `/carreras`, `/cursos`, `/pensums/1` → 200.

## Discrepancias
- `/politicas-academicas` sigue como shell hasta contar con contrato de
  políticas; `sis_aca_politica_academica` existe pero no está expuesta en la
  UI aprobada con columnas compatibles (se documenta como FASE G opcional).
