# M11 — Políticas académicas y reportes (FASE G, FASE H)

## FASE G — Políticas académicas
- `/politicas-academicas` ahora muestra `sis_aca_vw_politica_vigente`:
  código, nombre, nota de aprobación, vigencia desde/hasta.
- SQL: `SELECT pol_codigo AS code, pol_nombre AS name, pol_nota_aprobacion,
  pol_vigente_desde, pol_vigente_hasta FROM sis_aca_vw_politica_vigente`.

## FASE H — Reportes
Todos los filtros de reportes ahora usan vistas reales:

| Reporte | Fuente |
|---|---|
| Alumnos/carrera | `sis_aca_estudiante_programa` + carrera/pensum |
| Notas/carrera, /curso, /sección | `sis_aca_vw_reporte_notas` |
| Avance por estudiante | `sis_aca_vw_avance_pensum` |
| Avance por ciclo | `sis_aca_vw_avance_ciclo` |
| Pendientes/repitencias | `sis_aca_vw_reporte_notas` filtrado REPROBADO/PENDIENTE |

KPIs: `porcentaje calificado` y `tasa de aprobación` calculados desde la
misma fila de la vista (sin duplicar cálculos).

## Archivos modificados
- `src/Repository/ReportReadRepository.php` (nuevo)
- `src/Controller/Demo/ReportController.php`
- `src/Controller/Demo/CurriculumController.php` (`/politicas-academicas`)
- `templates/report/students_career.html.twig` (columnas del avance real)

## Pruebas
- `php -l` OK; `cache:clear` OK; `lint:twig` OK
- Los 9 reportes y `/politicas-academicas` → 200
- `/reportes/notas-carrera` mostró 748 coincidencias de carreras/nombres
- Regresión: todas las demás rutas → 200

## Discrepancias / pendientes
- El centro de reportes (`/reportes`) sigue mostrando el catálogo fixture
  (`DemoDataProvider::reportCatalog`) — decisión: el catálogo es estático y
  las rutas de cada reporte ya apuntan a datos reales. Se puede reemplazar
  por un catálogo derivado (EG: Q01–Q25) si se requiere.
- POST de creación de estudiante (FASE J) sigue sin persistir.
