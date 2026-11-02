# M12 — Dashboard (FASE H / I)

## Objetivo
Cerrar FASE I: la vista de Inicio (`app_dashboard`) deja de usar
`DemoDataProvider` y compone métricas reales desde servicios validados.

## Archivos modificados
- `src/Repository/DashboardReadRepository.php` (nuevo)
- `src/Controller/Demo/DashboardController.php`
- `templates/dashboard/index.html.twig` (tendencia del KPI convertida en
  caption fijo; línea hardcoded de totales reemplazada por contadores
  reales; estructura, diseño y componentes conservados)

## PostgreSQL utilizado
- `sis_aca_vw_reporte_notas` (total resultados, calificados, pendientes,
  aprobados)
- `sis_aca_vw_avance_pensum` (avance por carrera)
- `sis_aca_estudiante(_programa)` + `carrera` (distribución por carrera)
- `sis_aca_vw_ingreso_notas` (cursos sin oferta para alertas)
- `sis_aca_periodo_academico` + `sis_aca_anio_lectivo` (período actual y
  catálogo de períodos)

## Comportamiento
- `period`: último período ABIERTO (o último disponible).
- `gradedPercentage`: %calificados/total (misma fórmula que el contrato
  KPI); `approvalOnGraded`: %aprobados sobre calificados.
- Alertas: repitencias activas, resultados pendientes, cursos sin oferta.
- Donut: distribución de estudiantes activos por carrera con paleta Aula
  Editorial.
- Tarjetas de períodos con estado badge.

## Pruebas
- `php -l` OK; `cache:clear` OK; `lint:twig` OK.
- `/` → 200; cifras reales: 708 resultados · 627 calificados · 81
  pendientes; donut `conic-gradient(#C86F50 0% 43.2%, #6F8558 72.7%,
  #C69A45 100%)`.
- Regresión: todas las rutas → 200 (ver listado FASE H).
- Captura: `docs/frontend/screenshots/01_dashboard_pg_desktop.png`.

## Discrepancias
- La tendencia "+4 este período" se reemplazó por un caption neutro porque
  el modelo no expone conteo histórico por período; documentado.

## Pendientes
- FASE J: CRUD mínimo para `/alumnos/nuevo` (persistencia con DBAL + validación de reglas SA desde la base).
