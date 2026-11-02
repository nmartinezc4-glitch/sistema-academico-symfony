# M16 — Exportación real: XLSX, PDF e impresión corporativa

## Objetivo
Sustituir la «vista simulada» de exportación por archivos binarios reales,
con el tema corporativo **Aula Editorial** (paleta y tipografías de
`assets/styles/tokens.css`), sobre el mismo lote certificado de
`ReportReadRepository` que alimenta los reportes en pantalla.

## Dependencias
- `phpoffice/phpspreadsheet ^5.10` (`composer require`, `--ignore-platform-req=ext-gd`:
  sin ext-d no se embeben imágenes en celdas; el logo va en el PDF, no en el XLSX).
- `dompdf/dompdf ^3.1` para el PDF.

## Archivos
- `src/Service/Export/ReportAggregator.php` — fuente única de KPIs/resúmenes
  para las tres salidas: `kpis()` (totales, promedio, aprobados/reprobados/
  pendientes con estado `REPROBADO > PENDIENTE > APROBADO`), `students()`
  (una fila por estudiante con promedio y estado) y `byCareer()`.
- `src/Service/Export/ReportXlsxWriter.php` — libro de 3 hojas:
  **Datos** (banda burdeos `793B46`, encabezado tinta `342D29`, cebra
  `FBF8F2`, bordes `DED5C9`, pills de estado, numfmt `0.0`, `freezePane`,
  autofiltro), **Filtros y metadatos** (fuente, criterios, generado por) y
  **Resumen por carrera**. Opciones: `includeFilters`, `groupByCareer`,
  `freeze`, `conditional` (tiñe también la celda de nota).
- `src/Service/Export/ReportPdfBuilder.php` — `build()` → `{path, pages}`,
  `download()` → `BinaryFileResponse`; documento HTML corporativo
  (`templates/export/pdf_document.html.twig`) con encabezado institucional,
  tabla de filtros, 5 tarjetas KPI, tabla de resultados con pills, totales,
  nota de fuente y firmas; pie con `Página {PAGE_NUM} de {PAGE_COUNT}`
  (`page_text`), chroot en `projectDir`, logo como data-URI SVG
  (`public/images/marca.svg`).
- `src/Controller/Demo/ExportController.php` — previews con opciones reales
  (el tamaño mostrado es el del archivo ya generado) y descargas:
  | Ruta | Nombre |
  |---|---|
  | `GET /exportaciones/xlsx` | `app_export_xlsx_preview` |
  | `GET /exportaciones/xlsx/descargar` | `app_export_xlsx_download` |
  | `GET /exportaciones/pdf` | `app_export_pdf_preview` |
  | `GET /exportaciones/pdf/descargar` | `app_export_pdf_download` |
  | `GET /impresion/reporte` | `app_print_preview` (toolbar + iframe) |
  | `GET /impresion/documento` | `app_print_document` (HTML del documento) |
- Plantillas: `export/xlsx_preview.html.twig`, `export/pdf_preview.html.twig`
  (config + resumen + muestra de tabla), `print/preview.html.twig`
  (Imprimir vía `window.frames['sheet'].print()` y «Exportar PDF»).

## Quirks resueltos
- **PhpSpreadsheet 5.x:** no existe `addSheet(string)` → `createSheet()` +
  `setTitle()`; no existe `setCellValueByColumnAndRow()` → helper `at()`
  con `Coordinate::stringFromColumnIndex`; `setStartColor` exige objeto
  `Color`; `setPrintTitleRows` y `getFreezeState` no existen (se omiten).
- **Dompdf:** el pie `position: fixed` se repite por página al imprimir;
  en pantalla (`@media screen`) el pie pasa a `static` para no tapar la
  tabla de la vista de impresión.
- **Sin ext-gd:** logo del PDF como data-URI (no imagen de celda XLSX).

## Verificación
- XLSX: descarga 200, MIME `…spreadsheetml.sheet`, 3 hojas, 38–39 KB, leído
  con PhpSpreadsheet (brand block, totales 708/627/75.2/589/38/81, estilos
  `A1 fill=FF793B46`, `A6 fill=FF342D29`, condicional `E3EDDE`, numfmt `0.0`).
- PDF: descarga 200, `PDF-1.7`, 4 páginas, ~126 KB, fuentes embebidas.
- UI: Playwright afirma pie `static` sin solape, muestra XLSX/PDF sin
  overflow horizontal y toolbar de impresión con las 3 acciones.
- Smoke: 31 rutas 200 (404/405 solo en plantilla de error y POST-only).
- `E2_dataset_check.sql` **34/34 PASS**; lint:twig (45), lint:container y
  lint:yaml OK; capturas regeneradas (`shots.mjs`, `shots_mobile.mjs`).
