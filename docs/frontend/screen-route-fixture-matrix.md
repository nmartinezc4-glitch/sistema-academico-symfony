# Screen → Route → Fixture → ViewModel

| Pantalla | Ruta | Route name | Controller | Template | Fuente |
|---|---|---|---|---|---|
| Login | `/login` | `app_login` | AuthDemoController | `auth/login.html.twig` | — |
| Dashboard | `/` | `app_dashboard` | DashboardController | `dashboard/index.html.twig` | `DemoDataProvider::dashboard()` |
| Alumnos | `/alumnos` | `app_student_index` | StudentController | `student/index.html.twig` | `students()` |
| Nuevo | `/alumnos/nuevo` | `app_student_new` | StudentController | `student/new.html.twig` | `careers()`, `curricula()` |
| Perfil | `/alumnos/{id}` | `app_student_show` | StudentController | `student/show.html.twig` | `student()`, `studentResults()`, `studentPeriods()` |
| Pensum | `/pensums/{id}` | `app_curriculum_show` | CurriculumController | `curriculum/show.html.twig` | `curriculum()` |
| Notas | `/evaluacion/notas` | `app_grade_entry` | GradeController | `grade/entry.html.twig` | `gradeEntryRows()` |
| Expediente | `/expedientes/{id}` | `app_transcript_show` | TranscriptController | `transcript/show.html.twig` | `student()`, `studentPeriods()`, `studentResults()` |
| Centro | `/reportes` | `app_report_index` | ReportController | `report/index.html.twig` | `reportCatalog()` |
| R09–R15 | `/reportes/*` | `app_report_*` | ReportController | `report/*.html.twig` | `gradesReportRows()`, `progressReportRows()`, `pendingRows()` |
| XLSX | `/exportaciones/xlsx` | `app_export_xlsx_preview` | ExportController | `export/xlsx_preview.html.twig` | `gradesReportRows()` |
| PDF | `/exportaciones/pdf` | `app_export_pdf_preview` | ExportController | `export/pdf_preview.html.twig` | `student(1)`, `studentResults(1)` |
| Print | `/impresion/reporte` | `app_print_preview` | ExportController | `print/preview.html.twig` (layout print) | `gradesReportRows()` |
| UI Kit | `/ui-kit` | `app_dev_ui_kit` | DevController | `dev/ui_kit.html.twig` | — |
