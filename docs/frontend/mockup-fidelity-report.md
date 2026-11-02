# Informe de fidelidad mockup ↔ implementación

Fecha: 2026-10-09 · Comparación visual directa (mockups `00-Documentacion/UXUI_Master_Sistema_Academico/mockups/*.png` vs. capturas viewport 1536×1024 de la app).

## 1. Scores por vista (0–100)

| # | Vista | Ruta | Score | Brechas principales |
|---|-------|------|-------|---------------------|
| 01 | Dashboard | `/` | 64 | hero: ok tras repiso global; KPI con icono/tendencia, watermarks |
| 02 | Alumnos listado | `/alumnos` | 58 | filtros (carrera/año/estado/orden), chips de contexto, chips de fila |
| 03 | Perfil estudiante | `/alumnos/1` | 62 | foto de estudiante, pestañas con iconos, módulos del resumen |
| 04 | Nuevo estudiante | `/alumnos/nuevo` | 30 | stepper “01 Datos 02 Académico”, revisión lateral, éxito |
| 05 | Constructor de pensum | `/pensums/1` | 57 | tabs con iconos, chips de filtro, grid estructura/prerrequisitos |
| 06 | Ingreso de notas | `/evaluacion/notas` | 68 | filtros buscador, layout de columna de notas, barra de acción |
| 07 | Expediente académico | `/expedentes/1` | 30 | hero con foto+eyebrow, mosaico de reportes, panel derecho |
| 08 | Centro de reportes | `/reportes` | 38 | hero, grid-4 de tarjetas con icono+n°, filtros |
| 09 | Alumnos por carrera | `/reportes/alumnos-carrera` | 25 | rail de filtros, KPIs, tabla (4 extra: carrera/asignaturas/puntaje/estado) |
| 10 | Notas por carrera | `/reportes/notas-carrera` | 40 | filtros, KPIs, botón “Ver alumnos”, chips de estado |
| 11 | Notas por curso | `/reportes/notas-curso` | 30 | filtros, donut distribución, resumen promedio/aprobados, botones |
| 12 | Notas por sección | `/reportes/notas-seccion` | 32 | filtros, KPIs, distribución, chips A/B/C/D |
| 13 | Avance por estudiante | `/reportes/avance-estudiante` | 24 | filtros, fila icono+tendencia, prompt vacío con ilustración |
| 14 | Avance por ciclo | `/reportes/avance-ciclo` | 29 | filtros, KPIs, barras por ciclo, panel comparativo + donut |
| 15 | Pendientes/repitentes | `/reportes/pendientes-repitencias` | 24 | chips de filtro, estados urgentes/riesgo, comparativo |
| 16 | Login | `/login` | 72 | foto de panel (resuelta: `public/images/login-panel.jpg`), tipografía CTA |
| 17 | Vista previa XLSX | `/exportaciones/xlsx` | 42 | chips de estado, hoja estilo Excel (filas/col/celdas), previews 2×2 |
| 18 | Vista previa PDF | `/exportaciones/pdf` | 30 | layout de dos paneles + pestañas de documento |
| 19 | Impresión | `/impresion/reporte` | 55 | **visor con canvas oscuro** `#646464`, pager `‹ 1/3 ›`, zoom, miniaturas |
| — | Chrome global | sidebar/topbar | 66 | **resuelto en gran parte** (ver §3) |

## 2. Limitantes para replicar el frontend

### Bloqueantes (no resueltos)
1. **No hay librería de gráficos instalada** (donuts/barras/comparativos de los reportes 11/12/14/15). Se decidió en su momento no agregar dependencias de charts. Opciones: CSS `conic-gradient`/barras hechas a mano (como el donut actual del dashboard) — viable sin dependencias.
2. **Sin datos de “créditos/faltantes/carga semanal”** (reporte 14) ni campos de puntaje/estado por fila (09): requieren cambios de backend (fase de funcionalidad), no solo UI.

### Sortejables (resueltos o con workaround)
3. **Fotos inexistentes**: el repo no tenía assets de imagen (solo `marca.svg`). Extraídas de los propios mockups → `public/images/hero-campus.jpg`, `login-panel.jpg`, `sidebar-art.png`, `avatar-user.jpg` (recortes limpios verificados; script `extract_assets.mjs`).
4. **Glifos tofu** en botones (falta fuente/glyph): resuelto con `templates/components/_icons.html.twig` (56 iconos SVG + despachador `ic.glyph(nombre, tamaño)`).
5. **Fuentes vía CDN** (Google Fonts): si no hay red, cae a Georgia/system-ui. Auto-hospedaje = deuda menor.
6. **Foto de estudiante**: la DB tiene `photo_path` pero sin datos; fallback = iniciales (avatar) — no se hardcodea foto de personas en listados.
7. **Reporte 14 ilegible en mockup**: usar `docs/05_ESPECIFICACION_PANTALLAS.md` como especificación.

### Pendientes de fase de funcionalidad
8. Rail de filtros persistente (09), métricas extra (09/14), estados de fila (15): dependen de queries nuevas.

## 3. Resuelto en el repiso global de esta sesión
- Sidebar: marca centrada, grupos con label, píldora activa con barra terracota al borde, fondo crema, arte de watermark.
- Topbar: crema, campana SVG con punto, avatar fotográfico, bloque usuario tipografiado, Salir en pill.
- `_page_header`: modo `hero` (banda full-bleed con foto + cita `quote`/`quoteAuthor`), H1 hasta 46px.
- `_metric_card`: valor arriba del label (38px), igual que mockup.
- `_tabs`: contenedor tipo segmented con iconos (`item.icon`).
- `.btn--primary` → terracotta (CTAs de mockup), breadcrumb terracotta.
- Hero del dashboard full-bleed con foto; login con foto de panel; `.grid-4`/`.grid-3`, `.chip`, `.icon-input`.

## 4. Comandos de verificación
```bash
php bin/console lint:twig templates/        # 46 OK
psql -f 00-Documentacion/database/E2_dataset_check.sql   # 34/34
node shots.mjs && node shots_mobile.mjs     # capturas docs/frontend/screenshots/
```

## 5. Resultado de la réplica (iteración 8)
- 4 lotes paralelos ejecutados (A: dashboard/alumnos/login · B: pensum/notas/expediente/catálogos · C: reportes 08–12 · D: reportes 13–15 + export/impresión); lint 46 OK y todas las rutas 200.
- Verificación objetiva: sin overflow horizontal en 26 rutas × {1536, 768, 375}px.
- Pendientes de backend listados por lote (§2.1/§2.2 y reportes de lote) entran en la fase de auditoría funcional.
