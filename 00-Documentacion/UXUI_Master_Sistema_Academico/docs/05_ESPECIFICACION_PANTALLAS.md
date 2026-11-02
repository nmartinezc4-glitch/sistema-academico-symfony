# 05 — Especificación detallada de las 19 pantallas
## Convención de lectura

Cada pantalla define propósito, tarea primaria, datos, componentes, acciones, estados, responsive y criterios de aceptación. Los datos citados indican el contrato futuro; en Frontend V1 se simulan desde fixtures con la misma forma.

> Los mockups son referencia visual; los criterios aquí son referencia funcional de UI.

---

## S01 — Dashboard

**Mockup:** `01_dashboard.png`  
**Ruta:** `/`

### Propósito
Dar una lectura ejecutiva del estado académico actual sin obligar al usuario a abrir reportes.

### Tarea primaria
Ver contexto del período, avance de calificación y alertas; navegar a tareas críticas.

### Contrato de datos
Período actual; estudiantes activos; porcentaje calificado; tasa de aprobación sobre intentos calificados; notas pendientes; alertas; distribución/avance por carrera; períodos.

### Componentes y regiones
PageHeader editorial, MetricCard x4, ProgressPanel, AcademicAttentionCard, CareerDistribution, CareerProgress, PeriodCards, QuickActions.

### Acciones esperadas
Registrar estudiante; ingreso de notas; ver reportes; gestionar pensum.

### Estados que deben diseñarse
Sin período abierto; sin resultados; alertas = 0; calificación 0%; calificación 100%.

### Responsive
A 1024, métricas 2x2 y paneles apilados. En móvil, una métrica por fila y hero sin fotografía lateral.

### Criterios específicos de aceptación
La tasa de aprobación indica su denominador. Los KPIs no están hardcodeados en Twig. Acciones navegan a rutas reales.

### Reglas comunes de implementación
- Todo valor de negocio viene del ViewModel/fixture; Twig solo presenta.
- Los elementos interactivos deben tener foco visible.
- Las cards/tablas deben tener estado vacío coherente.
- Los botones sin implementación real deben estar `disabled` o claramente marcados como demo, no aparentar éxito silencioso.
- La pantalla debe reutilizar los componentes base del Design System.

---

## S02 — Listado de alumnos

**Mockup:** `02_alumnos_listado.png`  
**Ruta:** `/alumnos`

### Propósito
Localizar estudiantes con rapidez y abrir su contexto académico.

### Tarea primaria
Buscar por nombre/código, filtrar y acceder a perfil/expediente.

### Contrato de datos
Código, nombre, foto, carrera, pensum, estado, avance y opcionalmente fecha de nacimiento/ingreso.

### Componentes y regiones
PageHeader, Metrics, ViewToggle, SearchInput, FilterPanel, StudentTable/List, StatusBadge, Progress, Pagination.

### Acciones esperadas
Registrar; ver perfil; ver expediente; editar futuro; exportar futuro.

### Estados que deben diseñarse
Resultados; sin resultados; filtros activos; estudiante sin foto; estudiante sin período; retirado/inactivo.

### Responsive
Ocultar columnas secundarias, mantener código/nombre/estado/avance. Filtros pasan a drawer.

### Criterios específicos de aceptación
Filtros se reflejan en query o estado visible; no hay acciones con href '#'; avance usa ViewModel.

### Reglas comunes de implementación
- Todo valor de negocio viene del ViewModel/fixture; Twig solo presenta.
- Los elementos interactivos deben tener foco visible.
- Las cards/tablas deben tener estado vacío coherente.
- Los botones sin implementación real deben estar `disabled` o claramente marcados como demo, no aparentar éxito silencioso.
- La pantalla debe reutilizar los componentes base del Design System.

---

## S03 — Perfil de estudiante

**Mockup:** `03_perfil_estudiante.png`  
**Ruta:** `/alumnos/{id}`

### Propósito
Concentrar identidad, programa vigente, período actual, avance, trayectoria y alertas.

### Tarea primaria
Comprender situación actual y saltar a expediente/notas/avance.

### Contrato de datos
EST_* + EPR/PEN/CAR + EPE/PER/CIC/SEC + VW_AVANCE_PENSUM + últimas notas.

### Componentes y regiones
StudentHero, CurrentPeriodCard, Tabs, ProgressSummary, AcademicTrajectory, LatestGrades, Notice, QuickActions.

### Acciones esperadas
Gestionar inscripción (placeholder V1); ingreso de notas; expediente; avance; edición visual.

### Estados que deben diseñarse
Programa activo/finalizado/retirado; sin período; sin notas; sin foto; avance 0/100.

### Responsive
Hero en columnas pasa a vertical. CurrentPeriod baja debajo. Tabs scroll horizontal.

### Criterios específicos de aceptación
Campos gap (email/teléfono/documentos) se marcan ui-only o se omiten. Carrera se deriva del pensum.

### Reglas comunes de implementación
- Todo valor de negocio viene del ViewModel/fixture; Twig solo presenta.
- Los elementos interactivos deben tener foco visible.
- Las cards/tablas deben tener estado vacío coherente.
- Los botones sin implementación real deben estar `disabled` o claramente marcados como demo, no aparentar éxito silencioso.
- La pantalla debe reutilizar los componentes base del Design System.

---

## S04 — Nuevo estudiante

**Mockup:** `04_nuevo_estudiante.png`  
**Ruta:** `/alumnos/nuevo`

### Propósito
Mostrar el flujo de alta con separación entre persona y programa académico.

### Tarea primaria
Completar datos mínimos, seleccionar pensum y confirmar.

### Contrato de datos
EST_CODIGO, EST_NOMBRES, EST_APELLIDOS, EST_FECHA_NACIMIENTO, EST_FOTO_RUTA futuro, EST_ACTIVO, EPR_PEN_ID, EPR_FECHA_INICIO, EPR_ESTADO.

### Componentes y regiones
Stepper, PhotoUploader, FormSections, DependentSelects, SummaryPanel, ConfirmationPanel, FormActions.

### Acciones esperadas
Anterior/siguiente; cancelar; confirmación demo.

### Estados que deben diseñarse
Validación de requeridos; fecha inválida; foto inválida; sin pensums; formulario dirty; confirmación.

### Responsive
Panel resumen baja al final; campos 2 columnas pasan a 1.

### Criterios específicos de aceptación
Carrera solo filtra pensums. No se persisten género/email/teléfono/nacionalidad/CUI.

### Reglas comunes de implementación
- Todo valor de negocio viene del ViewModel/fixture; Twig solo presenta.
- Los elementos interactivos deben tener foco visible.
- Las cards/tablas deben tener estado vacío coherente.
- Los botones sin implementación real deben estar `disabled` o claramente marcados como demo, no aparentar éxito silencioso.
- La pantalla debe reutilizar los componentes base del Design System.

---

## S05 — Pensum / Constructor curricular

**Mockup:** `05_pensum_builder.png`  
**Ruta:** `/pensums/{id}`

### Propósito
Representar una tabla puente compleja como un plan de estudios legible por ciclos.

### Tarea primaria
Comprender composición del pensum y ubicación de cursos.

### Contrato de datos
PEN_*, CAR_*, CIC_*, PCU_*, CUR_*.

### Componentes y regiones
CurriculumHeader, Tabs, CycleColumns, CourseCards, RequiredBadge, DetailsSidebar, DistributionCard, QuickActions.

### Acciones esperadas
Agregar curso visual; cambiar ciclo; cambiar obligatorio; reordenar demo; vista previa; export futura.

### Estados que deben diseñarse
Pensum vigente/vencido/inactivo; ciclo sin cursos; curso optativo; pensum grande.

### Responsive
Desktop columnas por años; tablet 2 columnas; móvil accordion por ciclo.

### Criterios específicos de aceptación
No mostrar créditos como reales; orden se basa PCU_ORDEN; obligatorio se basa PCU_OBLIGATORIO.

### Reglas comunes de implementación
- Todo valor de negocio viene del ViewModel/fixture; Twig solo presenta.
- Los elementos interactivos deben tener foco visible.
- Las cards/tablas deben tener estado vacío coherente.
- Los botones sin implementación real deben estar `disabled` o claramente marcados como demo, no aparentar éxito silencioso.
- La pantalla debe reutilizar los componentes base del Design System.

---

## S06 — Ingreso de notas

**Mockup:** `06_ingreso_notas.png`  
**Ruta:** `/evaluacion/notas`

### Propósito
Ser la pantalla operativa principal para calificar sin exponer IDs ni reglas internas.

### Tarea primaria
Buscar estudiante, elegir su inscripción/período y registrar notas editables.

### Contrato de datos
En V2 proviene de SIS_ACA_VW_INGRESO_NOTAS filtrada por EPE_ID.

### Componentes y regiones
StudentSearch, StudentContext, TermContext, Tabs, GradeTableCurrent, GradeTablePrevious, RulesNotice, SaveBar.

### Acciones esperadas
Buscar; editar input; limpiar; guardar demo.

### Estados que deben diseñarse
PENDIENTE/APROBADO/REPROBADO/SIN_OFERTA/YA_APROBADO; bloqueos PERIODO_NO_ABIERTO/ESTUDIANTE_NO_INSCRITO/OFERTA_INACTIVA.

### Responsive
Mantener tabla con scroll horizontal; contexto se apila. SaveBar sticky opcional.

### Criterios específicos de aceptación
No calcular estado con 61 en UI; input disabled si editable=false y muestra motivo humano.

### Reglas comunes de implementación
- Todo valor de negocio viene del ViewModel/fixture; Twig solo presenta.
- Los elementos interactivos deben tener foco visible.
- Las cards/tablas deben tener estado vacío coherente.
- Los botones sin implementación real deben estar `disabled` o claramente marcados como demo, no aparentar éxito silencioso.
- La pantalla debe reutilizar los componentes base del Design System.

---

## S07 — Expediente académico

**Mockup:** `07_expediente_academico.png`  
**Ruta:** `/expedientes/{id}`

### Propósito
Presentar un documento vivo del historial completo del estudiante.

### Tarea primaria
Consultar resultados por período, intentos, avance y contexto de pensum.

### Contrato de datos
Student + program + VW_RESULTADO_ESTUDIANTE + VW_AVANCE_* + VW_INTENTO_CURSO.

### Componentes y regiones
StudentHeader, TranscriptTabs, PeriodAccordion, ResultTable, ProgressSidebar, CurriculumCard, QuickActions.

### Acciones esperadas
Ingreso notas; avance; generar constancia futura; exportar expediente futura.

### Estados que deben diseñarse
Período en curso/completo; nota pendiente; sin oferta; múltiples intentos; sin historial.

### Responsive
Sidebar contextual baja; tabs scroll; tables scroll.

### Criterios específicos de aceptación
Observaciones/sanciones/documentos no se inventan. Intento se muestra según backend futuro.

### Reglas comunes de implementación
- Todo valor de negocio viene del ViewModel/fixture; Twig solo presenta.
- Los elementos interactivos deben tener foco visible.
- Las cards/tablas deben tener estado vacío coherente.
- Los botones sin implementación real deben estar `disabled` o claramente marcados como demo, no aparentar éxito silencioso.
- La pantalla debe reutilizar los componentes base del Design System.

---

## S08 — Centro de reportes

**Mockup:** `08_centro_reportes.png`  
**Ruta:** `/reportes`

### Propósito
Servir de catálogo analítico y puerta de entrada a los reportes.

### Tarea primaria
Aplicar contexto global y elegir reporte.

### Contrato de datos
KPIs globales + catálogo estático de reportes.

### Componentes y regiones
Metrics, QuickFilters, ReportTabs, ReportCards, MiniCharts, ScheduleButton demo.

### Acciones esperadas
Ver reporte; export preview; filtros.

### Estados que deben diseñarse
Sin datos; filtro aplicado; report favorites/programmed como demo/disabled.

### Responsive
Cards 4→2→1 columnas.

### Criterios específicos de aceptación
Todos los report cards navegan. No implementar favoritos/programación persistente.

### Reglas comunes de implementación
- Todo valor de negocio viene del ViewModel/fixture; Twig solo presenta.
- Los elementos interactivos deben tener foco visible.
- Las cards/tablas deben tener estado vacío coherente.
- Los botones sin implementación real deben estar `disabled` o claramente marcados como demo, no aparentar éxito silencioso.
- La pantalla debe reutilizar los componentes base del Design System.

---

## S09 — Reporte Alumnos por carrera

**Mockup:** `09_reporte_alumnos_carrera.png`  
**Ruta:** `/reportes/alumnos-carrera`

### Propósito
Cumplir reporte académico exigido de alumnos agrupados por carrera.

### Tarea primaria
Filtrar y revisar alumnos por carrera con su programa/avance.

### Contrato de datos
Q01 + programa/pensum + progreso.

### Componentes y regiones
ReportHeader, FilterBar, Metrics, CareerGroups, DistributionDonut, PeriodSummary.

### Acciones esperadas
Expandir grupo; abrir alumno; export preview.

### Estados que deben diseñarse
Carrera sin alumnos; alumnos sin período; retirados.

### Responsive
Panel derecha baja; grupos permanecen tabla/lista.

### Criterios específicos de aceptación
Conteos coinciden con filas fixture; no inventar carrera redundante en StudentProgram.

### Reglas comunes de implementación
- Todo valor de negocio viene del ViewModel/fixture; Twig solo presenta.
- Los elementos interactivos deben tener foco visible.
- Las cards/tablas deben tener estado vacío coherente.
- Los botones sin implementación real deben estar `disabled` o claramente marcados como demo, no aparentar éxito silencioso.
- La pantalla debe reutilizar los componentes base del Design System.

---

## S10 — Reporte Notas por carrera

**Mockup:** `10_reporte_notas_carrera.png`  
**Ruta:** `/reportes/notas-carrera`

### Propósito
Comparar desempeño por carrera y período.

### Tarea primaria
Entender promedio, aprobación por intento, calificación pendiente y detalle.

### Contrato de datos
VW_REPORTE_NOTAS / Q05,Q09,Q11,Q23 futuros.

### Componentes y regiones
FilterBar, KPI x4, ComparativeChart, SummaryTable, DetailTable.

### Acciones esperadas
Generar/apply filters; export preview; paginar.

### Estados que deben diseñarse
Período parcial; sin notas; 0 calificados.

### Responsive
Chart y tabla resumen se apilan.

### Criterios específicos de aceptación
Mostrar %calificados separado; rotular tasa por intento.

### Reglas comunes de implementación
- Todo valor de negocio viene del ViewModel/fixture; Twig solo presenta.
- Los elementos interactivos deben tener foco visible.
- Las cards/tablas deben tener estado vacío coherente.
- Los botones sin implementación real deben estar `disabled` o claramente marcados como demo, no aparentar éxito silencioso.
- La pantalla debe reutilizar los componentes base del Design System.

---

## S11 — Reporte Notas por curso

**Mockup:** `11_reporte_notas_curso.png`  
**Ruta:** `/reportes/notas-curso`

### Propósito
Analizar un curso transversalmente por secciones.

### Tarea primaria
Distribución de nota, promedio, aprobación y detalle.

### Contrato de datos
VW_REPORTE_NOTAS / Q06,Q10,Q12.

### Componentes y regiones
CourseFilters, KPI, GradeDistribution, SectionComparison, DetailTable.

### Acciones esperadas
Cambiar curso; generar; export.

### Estados que deben diseñarse
Curso sin resultados; una sola sección; pendientes.

### Responsive
Gráficos apilados; tabla scroll.

### Criterios específicos de aceptación
No tratar 60–69 completo como aprobado; estados vienen de datos.

### Reglas comunes de implementación
- Todo valor de negocio viene del ViewModel/fixture; Twig solo presenta.
- Los elementos interactivos deben tener foco visible.
- Las cards/tablas deben tener estado vacío coherente.
- Los botones sin implementación real deben estar `disabled` o claramente marcados como demo, no aparentar éxito silencioso.
- La pantalla debe reutilizar los componentes base del Design System.

---

## S12 — Reporte Notas por sección

**Mockup:** `12_reporte_notas_seccion.png`  
**Ruta:** `/reportes/notas-seccion`

### Propósito
Comparar secciones de un mismo contexto.

### Tarea primaria
Detectar diferencias de promedio y aprobación.

### Contrato de datos
Q07,Q13 y VW_REPORTE_NOTAS.

### Componentes y regiones
Filters, KPI, StackedStatusChart, ApprovalBars, SectionTable.

### Acciones esperadas
Generar; exportar.

### Estados que deben diseñarse
Sección sin estudiantes; una sección.

### Responsive
Charts full width; table scroll.

### Criterios específicos de aceptación
Gráfico tiene tabla equivalente y labels.

### Reglas comunes de implementación
- Todo valor de negocio viene del ViewModel/fixture; Twig solo presenta.
- Los elementos interactivos deben tener foco visible.
- Las cards/tablas deben tener estado vacío coherente.
- Los botones sin implementación real deben estar `disabled` o claramente marcados como demo, no aparentar éxito silencioso.
- La pantalla debe reutilizar los componentes base del Design System.

---

## S13 — Avance curricular por estudiante

**Mockup:** `13_reporte_avance_estudiante.png`  
**Ruta:** `/reportes/avance-estudiante`

### Propósito
Dar una lectura de cumplimiento de pensum por estudiante.

### Tarea primaria
Buscar estudiante y detectar aprobados, pendientes, repitencias y ciclos.

### Contrato de datos
VW_AVANCE_PENSUM, VW_AVANCE_CICLO, VW_INTENTO_CURSO.

### Componentes y regiones
StudentSearch, StudentHeroCompact, KPI, CycleProgress, CourseTypeSummary, PendingTable.

### Acciones esperadas
Ver curso/expediente; export.

### Estados que deben diseñarse
0%,100%,sin notas,repitencias.

### Responsive
KPI 5→2→1; cycle cards horizontal scroll o wrap.

### Criterios específicos de aceptación
Créditos del mockup se omiten en V2 mientras no existan.

### Reglas comunes de implementación
- Todo valor de negocio viene del ViewModel/fixture; Twig solo presenta.
- Los elementos interactivos deben tener foco visible.
- Las cards/tablas deben tener estado vacío coherente.
- Los botones sin implementación real deben estar `disabled` o claramente marcados como demo, no aparentar éxito silencioso.
- La pantalla debe reutilizar los componentes base del Design System.

---

## S14 — Avance curricular por ciclo

**Mockup:** `14_reporte_avance_ciclo.png`  
**Ruta:** `/reportes/avance-ciclo`

### Propósito
Comparar cumplimiento de ciclos para un pensum.

### Tarea primaria
Identificar ciclos completos/incompletos y volumen pendiente.

### Contrato de datos
VW_AVANCE_CICLO agregado.

### Componentes y regiones
Filters, KPI, CycleProgressCards, DetailTable.

### Acciones esperadas
Generar; drill-down visual; export.

### Estados que deben diseñarse
Ciclo sin cursos; ciclo 0%; 100%.

### Responsive
Cards 4→2→1.

### Criterios específicos de aceptación
Estado de ciclo llega de backend/ViewModel; no inferir con CSS/JS.

### Reglas comunes de implementación
- Todo valor de negocio viene del ViewModel/fixture; Twig solo presenta.
- Los elementos interactivos deben tener foco visible.
- Las cards/tablas deben tener estado vacío coherente.
- Los botones sin implementación real deben estar `disabled` o claramente marcados como demo, no aparentar éxito silencioso.
- La pantalla debe reutilizar los componentes base del Design System.

---

## S15 — Pendientes y repitencias

**Mockup:** `15_reporte_pendientes_repitencias.png`  
**Ruta:** `/reportes/pendientes-repitencias`

### Propósito
Convertir alertas académicas en lista accionable.

### Tarea primaria
Filtrar estudiantes con pendientes o intentos repetidos.

### Contrato de datos
VW_INTENTO_CURSO + contexto estudiante/programa.

### Componentes y regiones
Filters, KPI, AlertTabs, AlertTable, AlertDistribution, CriticalCases.

### Acciones esperadas
Abrir expediente/nota; export; acciones recomendadas demo.

### Estados que deben diseñarse
sin alertas; repitencia; pendiente; sin oferta.

### Responsive
Side panel baja; prioridad/actions pueden ocultarse.

### Criterios específicos de aceptación
Prioridad/recomendación se marca UI-only hasta regla de servicio.

### Reglas comunes de implementación
- Todo valor de negocio viene del ViewModel/fixture; Twig solo presenta.
- Los elementos interactivos deben tener foco visible.
- Las cards/tablas deben tener estado vacío coherente.
- Los botones sin implementación real deben estar `disabled` o claramente marcados como demo, no aparentar éxito silencioso.
- La pantalla debe reutilizar los componentes base del Design System.

---

## S16 — Login

**Mockup:** `16_login.png`  
**Ruta:** `/login`

### Propósito
Establecer la identidad visual antes de autenticación real.

### Tarea primaria
Capturar credencial visual y mostrar acceso institucional.

### Contrato de datos
Config institucional + form demo.

### Componentes y regiones
AuthEditorialPanel, LoginCard, FormControls, SecurityNotice, FooterSupport.

### Acciones esperadas
Iniciar sesión demo; recuperar futura.

### Estados que deben diseñarse
idle, loading demo, invalid visual.

### Responsive
En móvil ocultar/reducir panel editorial; login full width.

### Criterios específicos de aceptación
No crear User en SIS_ACA ni prometer controles no implementados.

### Reglas comunes de implementación
- Todo valor de negocio viene del ViewModel/fixture; Twig solo presenta.
- Los elementos interactivos deben tener foco visible.
- Las cards/tablas deben tener estado vacío coherente.
- Los botones sin implementación real deben estar `disabled` o claramente marcados como demo, no aparentar éxito silencioso.
- La pantalla debe reutilizar los componentes base del Design System.

---

## S17 — Exportación XLSX

**Mockup:** `17_exportacion_xlsx.png`  
**Ruta:** `/exportaciones/xlsx`

### Propósito
Definir UX de exportación antes de implementar archivo real.

### Tarea primaria
Configurar nombre/opciones y previsualizar workbook.

### Contrato de datos
Report metadata + preview rows fixture.

### Componentes y regiones
ExportHeader, ContextChips, ExportOptions, SpreadsheetPreview, ExportSummary.

### Acciones esperadas
Generar demo; descargar disabled/demo.

### Estados que deben diseñarse
sin filas; muchas filas; formato condicional off.

### Responsive
Preview conserva scroll horizontal; side summary baja.

### Criterios específicos de aceptación
No generar screenshot como xlsx.

### Reglas comunes de implementación
- Todo valor de negocio viene del ViewModel/fixture; Twig solo presenta.
- Los elementos interactivos deben tener foco visible.
- Las cards/tablas deben tener estado vacío coherente.
- Los botones sin implementación real deben estar `disabled` o claramente marcados como demo, no aparentar éxito silencioso.
- La pantalla debe reutilizar los componentes base del Design System.

---

## S18 — Vista previa PDF

**Mockup:** `18_vista_previa_pdf.png`  
**Ruta:** `/exportaciones/pdf`

### Propósito
Configurar formato documental.

### Tarea primaria
Elegir orientación/tamaño/opciones y revisar página.

### Contrato de datos
Report metadata + rendered preview fixture.

### Componentes y regiones
PdfToolbar, PagePreview, PrintSettings, Pagination.

### Acciones esperadas
Generar/descargar/imprimir demo.

### Estados que deben diseñarse
portrait/landscape, multiple pages.

### Responsive
Desktop priority; móvil puede mostrar preview reducida.

### Criterios específicos de aceptación
Template documental separado del dashboard.

### Reglas comunes de implementación
- Todo valor de negocio viene del ViewModel/fixture; Twig solo presenta.
- Los elementos interactivos deben tener foco visible.
- Las cards/tablas deben tener estado vacío coherente.
- Los botones sin implementación real deben estar `disabled` o claramente marcados como demo, no aparentar éxito silencioso.
- La pantalla debe reutilizar los componentes base del Design System.

---

## S19 — Vista de impresión

**Mockup:** `19_vista_impresion.png`  
**Ruta:** `/impresion/reporte`

### Propósito
Validar cómo se ve el reporte físico.

### Tarea primaria
Mostrar A4 landscape con tablas y páginas.

### Contrato de datos
Report fixture.

### Componentes y regiones
PrintToolbar, PageCanvas, PageThumbnails, PrintReport.

### Acciones esperadas
Imprimir/export PDF demo.

### Estados que deben diseñarse
1..N páginas.

### Responsive
Desktop only acceptable para preview; CSS print real independiente.

### Criterios específicos de aceptación
Sidebar/topbar no aparecen en impresión real; thead repite.

### Reglas comunes de implementación
- Todo valor de negocio viene del ViewModel/fixture; Twig solo presenta.
- Los elementos interactivos deben tener foco visible.
- Las cards/tablas deben tener estado vacío coherente.
- Los botones sin implementación real deben estar `disabled` o claramente marcados como demo, no aparentar éxito silencioso.
- La pantalla debe reutilizar los componentes base del Design System.
