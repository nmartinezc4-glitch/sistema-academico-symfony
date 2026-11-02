# Implementation Log — Frontend V1

## Gate 0 — Auditoría
- Handoff leído: docs 00–23, machine/*, reference_database/*, mockups 01–19.
- Stack base: esqueleto Symfony 8.1 sin Twig/AssetMapper/Stimulus.
- Instalado: `symfony/twig-bundle`, `symfony/asset-mapper`, `symfony/stimulus-bundle`.

## Gate 1 — Foundation
- `src/Ui/UiState/StatusCatalog.php`: mapa canónico status→{label,tone} y mensajes de bloqueo.
- `src/Twig/UiExtension.php`: Twig functions `status_label`, `status_tone`, `block_message`.
- CSS: `tokens.css`, `base.css`, `layout.css`, `components.css`, `pages.css`; `print` embebido en layout print.
- Layouts `app`, `auth`, `print`.
- `/ui-kit` (dev) con tipografía, tokens, botones, badges, progress, notice, tabla.

## Gate 2 — Shell
- Sidebar con grupos aprobados y `aria-current`; topbar con búsqueda global demo y usuario fixture; breadcrumb; page header.
- Drawer responsive < 992px con controller `sidebar`.

## Gate 3–6 — Pantallas
- S01 Dashboard, S02 Alumnos, S03 Perfil, S04 Nuevo (dirty-form + dependent-select + photo-preview), S05 Pensum, S06 Ingreso notas, S07 Expediente, S08 Centro reportes, S09–S15 reportes, S16 Login, S17 XLSX preview, S18 PDF preview, S19 Print.
- Shell routes: `/carreras`, `/cursos`, `/periodos` (catálogo), `/secciones`, `/ofertas`, `/politicas-academicas` (placeholder).

## Gate 7 — Hardening (parcial, ver known-debt)
- Lint Twig OK (43 archivos), `debug:router` OK (27 rutas), smoke test HTTP 200 en las 27 rutas.
- CSS auditoría: hex directos solo en `tokens.css` e inline puntuales en login (ajustar).

## Iteración 2 — Fidelidad visual contra mockups
- Sidebar: logo "SISTEMA ACADÉMICO", iconos por ítem, estado activo terracota suave, footer motto.
- Topbar: buscador con lupa, campana, avatar MG, usuario actualizado.
- MetricCard: icono circular + label + valor + caption + progreso.
- Dashboard: hero editorial con cita de Freire, donut SVG, avance por carrera, períodos en cards, acciones rápidas.
- Login: split editorial (visual campus degradado vs mockup fotográfico — desviación D-07).
- Alumnos: panel de filtros lateral, tabla con avatares, tabs listado/tarjetas, paginación demo.
- Fix responsive: grids con minmax(0,…) para evitar overflow de tablas.

## Iteración 3 — Auditoría mockups y fidelidad por pantalla
- S03 Perfil: header con nombre+estado, tabs pill (Resumen/Historial/Avance/Cursos/Notas/Documentos), tarjeta de identidad con foto placeholder, donut de avance con totales, trayectoria por períodos, últimas calificaciones, sidebar Período actual + Estado académico + Acciones rápidas, alerta de curso pendiente.
- Dead-link `href="#"` eliminados en perfil (botones disabled/documentos reales).
- Pensum (S05) rediseñado en iteración 2; auditado contra mockup 05.
- Href con `#` ya solo aparece en tabs visuales documentados (UI-only).

## Iteración 4 — Fidelidad fina S06 (Ingreso de notas)
- Reescrito según mockup 06: bloque Buscar estudiante + tarjeta de contexto del estudiante + tarjeta Período (sección, ciclo, estado inscripción), tabs (Ingreso de notas / Historial del período / Detalle de inscripción).
- Tabla "Cursos del ciclo actual": #, Código, Curso, Tipo (badge), Oferta, Nota (input number 0-100 si editable), Estado (badge), Editable (✓/—), Motivo (blockMessage).
- Tabla "Pendientes de ciclos anteriores": ciclo original, último resultado (pill), oferta, nota, estado, editable, motivo.
- Sección "Ya aprobados" (historial, no editable).
- Caja "Reglas de ingreso de notas" con las reglas SA.
- SaveBar: Limpiar cambios (reset) + Guardar notas (submit demo).

## Iteración 5 — Auditoría de cierre + persistencia de notas (FASE D escritura)
- Auditoría exhaustiva documentada en `docs/frontend/auditoria.md` (datos dinámicos, responsive 390/768/1536, diseño por pantalla, deuda conocida).
- Copias demo corregidas en `/alumnos/nuevo` y KPI de `/alumnos`; `ReportController` es el único consumidor de `DemoDataProvider` (catálogo de navegación).
- **Persistencia real de notas** (`M14_grade_persistence.md`): `StudentWriteRepository::saveGrades()` transaccional sobre `sis_aca_resultado_curso`, validación servidor (editable/rango), PRG con flash, re-render conservando valores en error, mensajes SA2xx legibles, rollback atómico del lote.
- Búsqueda de estudiante por código en `/evaluacion/notas` (`idFromCode`); flashes `danger` en el layout.
- Verificación: update/insert/clear + errores de rango y fila no editable; trigger SA204 y atomicidad probados; dataset certificado restaurado (`E2_dataset_check.sql` 34/34 PASS, huella intacta); lint twig/container OK.

## Iteración 6 — FASE J completa (CRUD de estudiantes)
- `edit()` GET/POST `/alumnos/{id}/editar`: actualiza ficha personal + programa vigente (pensum, inicio, estado) con prefill y `dependent-select`; pre-chequeo T4/SA401 si hay notas; unicidad de código excluyendo el propio registro; ACTIVO/RETIRADO/FINALIZADO con `ck_epr_estado_fecha_fin` resuelto (fecha fin solo fuera de ACTIVO).
- `delete()` POST `/alumnos/{id}/eliminar`: con historial → rechazo con mensaje que sugiere "Retirado" (FK RESTRICT como respaldo); sin historial → borrado en transacción.
- Fix pdo_pgsql: `false` se liga como `''` → booleanos se envían como `'true'/'false'`.
- Plantilla `student/edit.html.twig` + acción "Editar ficha" en el perfil (`M15_student_crud.md`).
- Verificado por HTTP: alta/baja de registro temporal (45 estudiantes al inicio y al final), retiro/reactivación, errores de código duplicado y pensum congelado; `E2_dataset_check.sql` 34/34 PASS; lint twig (44) y container OK.

## Iteración 7 — Exportación real (M16)
- Dependencias: `phpoffice/phpspreadsheet ^5.10` (sin ext-gd) y `dompdf/dompdf ^3.1`.
- `ReportAggregator` como fuente única de KPIs/por estudiante/por carrera para XLSX, PDF e impresión (mismo lote de `ReportReadRepository`).
- `ReportXlsxWriter`: 3 hojas (Datos / Filtros y metadatos / Resumen por carrera) con banda burdeos, encabezado tinta, cebra, pills de estado, `freezePane`, autofiltro y opciones filtros/agrupar/congelar/formato condicional.
- `ReportPdfBuilder` + `export/pdf_document.html.twig`: documento corporativo (encabezado institucional, filtros, 5 KPIs, tabla con pills, totales, nota de fuente, firmas) con pie «Página N de M»; descarga `BinaryFileResponse`.
- Rutas nuevas: `/exportaciones/{xlsx,pdf}/descargar` e `/impresion/documento`; previews con opciones reales (tamaño en KB del archivo ya generado) e «Imprimir / Exportar PDF» en `/impresion/reporte`.
- Polish de cierre: pie del documento `static` en pantalla (fijo solo al imprimir), tarjeta «Resumen de exportación» apilada con cifras destacadas, muestra XLSX sin columna carrera y preview PDF reorganizado (opciones | resumen + documento a ancho completo) — ninguna de las tablas de muestra desborda.
- Verificación: XLSX leído con PhpSpreadsheet (3 hojas, estilos y totales correctos), PDF 4 páginas `PDF-1.7`, aserciones Playwright de las 4 pantallas, smoke 31 rutas, `E2_dataset_check.sql` 34/34 PASS, lint twig/container/yaml OK, capturas regeneradas.
- Docs: `M16_export_real.md`; `auditoria.md` §3.2/§6 y `known-debt.md` actualizados (deuda «export simulado» resuelta).

## Iteración 8 — Réplica de diseño frontend (fidelidad mockup)
- Comparación mockup↔actual de las 19 vistas por subagentes (scores 24–72; chrome global 66) → `docs/frontend/mockup-fidelity-report.md`.
- Assets fotográficos extraídos de los propios mockups (`extract_assets.mjs` → `public/images/`): `hero-campus.jpg`, `login-panel.jpg`, `sidebar-art.png`, `avatar-user.jpg` (recortes verificados sin texto/UI encima).
- Repiso global del design system: sidebar crema con marca centrada, grupos etiquetados, píldora activa con barra terracota y watermark; topbar crema con campana SVG, avatar fotográfico y bloque usuario; `.page_header` con modo `hero` full-bleed + cita; `.metric_card` con valor sobre label (38px); `.tabs` segmented con iconos; `.btn--primary` terracotta; breadcrumb terracotta; `.grid-3/.grid-4/.chip/.icon-input`; login con foto de panel.
- Librería de iconos `templates/components/_icons.html.twig` (56 iconos + despachador `ic.glyph()`) — resuelve glifos tofu.
- Réplica por vistas en 4 lotes paralelos (CSS propio `views-a..d.css`, clases prefijadas, sin tocar PHP/compartidos): 19 vistas + catálogos; sin hex fuera de tokens (excepto `--vd-canvas` del visor de impresión, documentado); sin librerías de charts (donuts `conic-gradient`, barras CSS/SVG).
- Limpieza de "notas de desarrollo" visibles en UI (se movieron a este informe); captions `Demo ·` → neutros.
- Fix overflow `/evaluacion/notas` (+220px tablet/+665px mobile): `.vb-sr` absoluta escapaba del clip → `left:-9999px` + `.table-wrap { position: relative }`.
- Verificación: lint twig 46 OK, smoke 26 rutas ×(desktop/tablet/mobile) sin overflow horizontal, E2 34/34 PASS, capturas regeneradas (56 archivos).
