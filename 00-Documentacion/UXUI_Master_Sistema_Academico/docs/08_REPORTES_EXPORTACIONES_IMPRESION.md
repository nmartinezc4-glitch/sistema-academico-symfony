# 08 — Reportes, XLSX, PDF e Impresión

Pantalla interactiva != documento.

Reportes oficiales: alumnos/carrera, notas/carrera, notas/curso, notas/sección, avance estudiante, avance ciclo, pendientes/repitencias.

Filtros aplicados deben aparecer en exportación.

## Métricas
- tasa de aprobación: rotular por intento cuando corresponda;
- `% calificado` separado;
- pendientes no entran a promedio si consulta aprobada los excluye.

## XLSX futuro
Workbook:
1. Datos
2. Filtros y metadatos
3. Resumen

Datos: freeze header, autofilter, formatos, anchuras, status. No merged cells en data.
Motor sugerido: PhpSpreadsheet.

## PDF
Template print separado. A4 portrait en expedientes; landscape para tablas anchas.

## Print CSS
`@page`, thead table-header-group, evitar cortes de filas, ocultar navegación, fondo blanco, footer.

## Firmas
UI demo; no hay modelo de autorizadores.

Nunca exportar un screenshot rasterizado del dashboard.
