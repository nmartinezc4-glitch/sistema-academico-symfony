# M09 — Carreras / Cursos / Pensums / Años y períodos (FASE E)

## Objetivo
Conectar la sección de Estructura Académica + Gestión Académica con
PostgreSQL, manteniendo el mockup.

## Archivos modificados
- `src/Repository/CurriculumReadRepository.php` (nuevo)
  - `careers()`, `courses()`, `curricula()`, `curriculum(id)`,
    `cycles(pensumId)`, `periods()`
- `src/Controller/Demo/CurriculumController.php`
  - `show()`, `careers()`, `courses()`, `periods()` usan el repositorio.
- Los CRUD placeholders (`/secciones`, `/ofertas`, `/politicas-academicas`)
  se mantienen como shells hasta su fase.

## PostgreSQL utilizado
- `sis_aca_carrera`, `sis_aca_curso`, `sis_aca_pensum`,
  `sis_aca_pensum_curso`, `sis_aca_ciclo_curricular`,
  `sis_aca_periodo_academico`, `sis_aca_anio_lectivo`.

## Comportamiento
- `/carreras`: catálogo real (código + nombre) sin nombres demo.
- `/cursos`: catálogo real de cursos activos.
- `/pensums/{id}`: plan por ciclos calculado desde `pensum_curso` +
  `ciclo_curricular`; donut de Obligatorios/Optativos derivado del mismo
  fixture (conteo real); vigencia calculada desde `pen_vigente_hasta`.
- `/periodos`: períodos reales con estado `per_estado` (badge).

## Pruebas
- `php -l` OK; `cache:clear` OK.
- `/carreras` → 200 (BCL-COMP, BCL, BCO reales); `/cursos` → 200
  (ADM-201…IAR-202); `/periodos` → 200 (2025-I…2026-II con `Abierto`
  success); `/pensums/1` → 200 con ciclos y 20 cursos obligatorios.
- Regresión: rutas previas 200.
- Captura: `docs/frontend/screenshots/05_pensum_pg_desktop.png`.

## Discrepancias
- El mockup muestra créditos/horas por curso como dato real; seguir
  excluidos (regla DB-only, D-04).
- `pendientes`/`optativos` reales: este pensum es 100% obligatorio; el
  donut refleja 20/0.

## Pendientes
- FASE F: `/periodos`, `/secciones`, `/ofertas` (CRUD/shell con datos
  reales, sin inventar).
