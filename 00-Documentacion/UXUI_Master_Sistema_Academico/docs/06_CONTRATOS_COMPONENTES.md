# 06 — Contratos de Componentes

Estructura sugerida `templates/components/`:
`_sidebar`, `_topbar`, `_page_header`, `_breadcrumb`, `_metric_card`, `_status_badge`, `_progress`, `_tabs`, `_filter_bar`, `_student_header`, `_data_table`, `_empty_state`, `_notice`, `_report_card`, `_period_card`, `_course_row`, `_print_header`, `_print_footer`.

## PageHeader
Props: eyebrow, title, subtitle, quote?, heroImage?, primaryAction?.

## MetricCard
label, value, caption, icon, tone, trend?, progress?.

## StatusBadge
status, label?, size. Mapa semántico centralizado.

## Progress
value 0..100, label, semantic, showValue; `role=progressbar`.

## Tabs
Items `{label, route, icon, active}`. Preferir links.

## FilterBar
Controles + limpiar + aplicar; conservar query.

## StudentHeader
photo/fullName/code/birthDate/status/career/curriculum/admissionDate. Omitir campos ausentes.

## DataTable
Patrón reusable, no componente “Dios”. thead, responsive wrapper, empty, acciones accesibles.

## Notice
info/success/warning/danger.

## ReportCard
title, description, visualization slot, report route, export.

## CourseRow
Pensum e ingreso de notas pueden compartir primitivos, no el mismo mega componente.

## Buttons
primary, secondary, ghost, danger, icon; hover/focus/disabled/loading.

No crear componentes con docenas de flags.
