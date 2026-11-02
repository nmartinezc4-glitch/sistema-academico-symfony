# M08 — Ingreso de notas (GET|POST /evaluacion/notas)

## Objetivo
Conectar la pantalla de ingreso de notas con `sis_aca_vw_ingreso_notas`
real, manteniendo las tres secciones del contrato visual: ciclo actual,
ciclos anteriores y aprobados.

## Archivos modificados
- `src/Repository/StudentReadRepository.php` (`gradeEntryRows()`,
  `currentPeriodStatus` en el perfil)
- `src/Controller/Demo/GradeController.php` (`entry()` usa el repositorio)
- `templates/grade/entry.html.twig` (categorías por `ing_origen` real:
  `CICLO_ACTUAL` / `CICLO_ANTERIOR` / estado `APROBADO`)
- `src/Ui/UiState/StatusCatalog.php` (+ `SIN_REGISTRO`)

## PostgreSQL utilizado
- `sis_aca_vw_ingreso_notas` (única fuente; no se reescribe la lógica de
  elegibilidad — PostgreSQL es la fuente de verdad)
- `sis_aca_vw_avance_pensum`, `sis_aca_estudiante` (perfil)

## Contrato preservado
- Cada fila trae `editable`, `status`, `blockReason`/`blockMessage`
  producidos por PostgreSQL; Twig no deriva aprobación.
- Inputs `type=number` 0–100 solo cuando `editable`.
- POST sigue siendo simulación visual sin persistencia (persistencia real
  queda para la fase de escritura).

## Pruebas
- `php -l` OK, `lint:twig` OK.
- `/evaluacion/notas` → 200; filas reales renderizadas (badges APROBADO /
  SIN_OFERTA / PENDIENTE según `ing_estado`).
- `/evaluacion/notas?student=3` → 200.
- Regresión: `/` 200.
- Captura: `docs/frontend/screenshots/06_ingreso_notas_pg_desktop.png`.

## Discrepancias
- `attemptCount` (`res_numero_intento`) no está en la vista de ingreso; la
  columna "Intento" de ciclos anteriores usa `lastGrade` cuando existe.
- Sin oferta: el contador usa filas con `ing_estado`/`ofe_id` ausente; la
  vista no distingue explícitamente `SIN_OFERTA` como estado.

## Pendientes
- FASE E: Carreras / cursos / pensums.
