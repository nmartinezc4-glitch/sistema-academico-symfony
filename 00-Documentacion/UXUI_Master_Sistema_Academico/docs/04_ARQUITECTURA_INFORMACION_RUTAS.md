# 04 — Arquitectura de Información y Rutas

| Vista | Ruta | Route name |
|---|---|---|
| Login | `/login` | `app_login` |
| Dashboard | `/` | `app_dashboard` |
| Alumnos | `/alumnos` | `app_student_index` |
| Nuevo | `/alumnos/nuevo` | `app_student_new` |
| Perfil | `/alumnos/{id}` | `app_student_show` |
| Expediente | `/expedientes/{id}` | `app_transcript_show` |
| Pensum | `/pensums/{id}` | `app_curriculum_show` |
| Notas | `/evaluacion/notas` | `app_grade_entry` |
| Reportes | `/reportes` | `app_report_index` |
| Alumnos/carrera | `/reportes/alumnos-carrera` | `app_report_students_career` |
| Notas/carrera | `/reportes/notas-carrera` | `app_report_grades_career` |
| Notas/curso | `/reportes/notas-curso` | `app_report_grades_course` |
| Notas/sección | `/reportes/notas-seccion` | `app_report_grades_section` |
| Avance estudiante | `/reportes/avance-estudiante` | `app_report_progress_student` |
| Avance ciclo | `/reportes/avance-ciclo` | `app_report_progress_cycle` |
| Pendientes | `/reportes/pendientes-repitencias` | `app_report_pending_repeats` |
| XLSX | `/exportaciones/xlsx` | `app_export_xlsx_preview` |
| PDF | `/exportaciones/pdf` | `app_export_pdf_preview` |
| Print | `/impresion/reporte` | `app_print_preview` |

Shell routes sin mockup: `/carreras`, `/cursos`, `/periodos`, `/secciones`, `/ofertas`, `/politicas-academicas`.

Breadcrumb: Inicio > Área > Recurso > Detalle.

La sidebar marca área actual. Reporte específico mantiene “Reportes” activo.

Filtros pueden persistir con query strings: `period`, `career`, `section`, `status`, `q`.
