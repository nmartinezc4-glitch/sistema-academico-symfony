# Auditoría Frontend V1 — Sin datos hardcodeados · Responsive · Diseño

**Fecha:** 2026-10-08 · **Alcance:** las 19 pantallas + rutas shell (27 rutas) sobre PostgreSQL real · **Contrato:** `00-Documentacion/docs/CONSTRUCTOR_BD.MD` (FASE A–J) · **Mockups:** `00-Documentacion/UXUI_Master_Sistema_Academico/mockups/`

---

## 1. Dictamen

| Eje | Resultado |
|---|---|
| Datos dinámicos (sin fixtures en vistas) | **PASS** — 45 estudiantes, perfiles, notas, pensums, reportes y dashboard provienen de vistas/tablas certificadas |
| Rutas funcionales | **PASS** — 19 vistas verificadas HTTP 200 + `lint:twig` 43/43 + `lint:container` OK |
| Responsive (390 / 768 / 1536) | **PASS** — drawer, grids colapsables, tablas con scroll horizontal |
| Diseño / identidad aprobada | **PASS** — sistema Aula Editorial intacto; sin rediseños (§8 del contrato) |
| Deuda restante | **CONOCIDA** — §6 de este documento + `known-debt.md` |

---

## 2. Estado por fase (CONSTRUCTOR_BD.MD §7)

| Fase | Pantalla(s) | Repositorio | Estado |
|---|---|---|---|
| A | `/alumnos` listado + métricas | `StudentReadRepository` | ✅ real |
| B | `/alumnos/{id}` ficha | `StudentReadRepository::findProfile/periods/results` | ✅ real |
| C | `/expedientes/{id}` historial | `StudentReadRepository` (reutiliza perfil) | ✅ real |
| D | `/evaluacion/notas` ingreso | `StudentReadRepository::gradeEntryRows()` + `StudentWriteRepository::saveGrades()` | ✅ real (lectura y escritura, ver `M14_grade_persistence.md`) |
| E | `/carreras`, `/cursos`, `/pensums/{id}` | `CurriculumReadRepository` | ✅ real |
| F | `/secciones`, `/ofertas`, `/periodos` | `CurriculumReadRepository` | ✅ real |
| G | `/politicas-academicas` | `ReportReadRepository` sobre `vw_politica_vigente` | ✅ real |
| H | `/reportes/*` + `/exportaciones/*` | `ReportReadRepository` | ✅ real (lectura y export binario, ver `M16_export_real.md`) |
| I | `/` dashboard | `DashboardReadRepository::dashboard()` | ✅ real |
| J | `/alumnos/nuevo`, `/alumnos/{id}/editar`, `/alumnos/{id}/eliminar` (CRUD) | `StudentWriteRepository` (create/update/delete transaccionales) | ✅ real |

---

## 3. Hardcodeo de datos — hallazgos y correcciones

### 3.1 Eliminado en esta auditoría
- `DemoDataProvider::students()` ya no consume ninguna vista migrada; el proveedor solo conserva `reportCatalog()` (taxonomía de navegación de reportes, sin números).
- Copias obsoletas corregidas:
  - `/alumnos/nuevo`: *"Alta sin persistencia…"* → *"Alta real validada contra PostgreSQL."*; botón *"Guardar (demo)"* → *"Registrar estudiante"*.
  - `/alumnos`: caption del KPI *"2025 - 2026"* (hardcodeado) → *"En base certificada"*.
  - Perfil: donut con hex inline → `var(--terracotta)`.
- `ExportController` (xlsx/pdf/printPreview) migrado a `ReportReadRepository`/`StudentReadRepository` — antes usaba el proveedor demo.

### 3.2 Hardcodeo restante (intencional / documentado)
| Ubicación | Qué es | Por qué se queda |
|---|---|---|
| `DemoDataProvider::reportCatalog()` | Catálogo de secciones/íconos de `/reportes` | metadatos de navegación, no datos |
| `report/index` marcadores "Favoritos/Programados = 0" | UI-only V1 | funcionalidad de guardado en V2 |
| Fecha/año del sidebar y footer | estáticos | decorativos |

*(La fila «Etiquetas "(demo)" en xlsx/pdf/print» se retiró: los export ya no son simulación — ver §6.2 y `M16_export_real.md`.)*

### 3.3 Verificación
- Búsqueda de `DemoDataProvider` en `templates/`: **0 ocurrencias** (solo inyectado en `ReportController::index` como catálogo).
- Ningún controller de las 27 rutas lee de arrays de fixtures; todo pasa por repositorios DBAL.

---

## 4. Responsive — verificación con capturas

Evidencia: `docs/frontend/screenshots/` (desktop 1536, tablet 768, mobile 390).

| Elemento | Comportamiento verificado |
|---|---|
| Sidebar | sticky ≥ 992px; **drawer** con sombra + botón ☰ < 992px (Stimulus `sidebar`) |
| Topbar | buscador y usuario ocultos < 768px; menú ☰ accesible |
| KPIs (dashboard/alumnos) | 4 col → 2×2 (768) → 1 col (390) |
| Tablas | `.table-wrap { overflow-x:auto }` + `white-space:nowrap`; scroll horizontal en móvil |
| `grid-2` / `.split-table` | colapsan a 1 columna < 1200 / < 991px |
| Contenedores de grid | `minmax(0,…)` + `min-width:0` en hijos → sin overflow lateral |
| Donut dashboard | `flex-wrap` — leyenda no se corta a 390px |
| Ingreso de notas | 3 tarjetas header apiladas; tablas con scroll; savebar fija |

Sin horizontal-scroll del `body` en ninguna vista (verificado `document.documentElement.scrollWidth <= innerWidth` en 390/768).

---

## 5. Diseño — revisión por área

- **Paleta:** `--paper`, `--ink`, `--terracotta`, `--burgundy`, `--success`, `--warning` coherentes en todas las vistas. Hex literales solo en `tokens.css`, `print.css` y muestras del UI-Kit.
- **Tipografía:** Fraunces (títulos/editorial), Inter (datos/tablas), monoespaciada para códigos. Sin fuentes nuevas.
- **Componentes:** MetricCard, badge por estado (`StatusCatalog` vía `status_label`/`status_tone`), progress, notice, tabs pill, savebar — todos reutilizados, sin duplicación.
- **Estados vacíos/bloqueo:** `block_message` cubre períodos cerrados, resultados no editable, etc.
- **Accesibilidad:** `aria-current` en sidebar, labels en inputs, tabs con roles, contraste AA verificado en tokens.
- **Anti-patrones:** sin `href="#"` sin documentar; sin `!important` salvo `prefers-reduced-motion` y `.split-table`.
- **No-rediseño (§8):** ningún mockup alterado; iteraciones limitadas a fidelidad.

---

## 6. Deuda conocida (ver también `known-debt.md` / `deviations.md`)

1. **Escrituras no expuestas:** secciones, ofertas y políticas se leen pero no se editan desde la UI (solo lectura por diseño en V1); el CRUD de estudiantes (crear/editar/eliminar/retirar) está completo — `M15_student_crud.md`.
2. ~~**Export simulado.**~~ **Resuelto:** `/exportaciones/xlsx` y `/exportaciones/pdf` descargan archivos reales (PhpSpreadsheet 3 hojas y Dompdf respectivamente) y `/impresion/reporte` imprime el documento corporativo — `M16_export_real.md`.
3. **Filtros de reportes:** GET simple sin estado completo en URL (D-06, GATE 7).
4. **Sin PHPUnit:** `symfony/test-pack` sin instalar; smoke HTTP manual.
5. **Login visual:** SecurityBundle en V2 (D-01).
6. **Fotos:** `photo_path` en contrato; upload sin implementar (D-02/uiOnly).
7. **Gráficos:** donuts SVG/progress en vez de librería de charts (D-03).

---

## 7. Comandos de re-verificación

```bash
bin/console lint:twig templates && bin/console lint:container && bin/console lint:yaml config
node shots.mjs && node shots_mobile.mjs   # capturas de regresión
# smoke de rutas:
for r in / /alumnos /alumnos/nuevo /alumnos/1 /alumnos/1/editar /expedientes/1 /evaluacion/notas \
  /carreras /cursos /periodos /pensums/1 /secciones /ofertas /politicas-academicas \
  /reportes /reportes/notas-carrera /exportaciones/xlsx /exportaciones/pdf \
  /exportaciones/xlsx/descargar /exportaciones/pdf/descargar /impresion/reporte /impresion/documento /ui-kit; do
  curl -s -o /dev/null -w "%{http_code} $r\n" "http://127.0.0.1:8000$r"
done
# integridad del dataset certificado (esperar 34/34 PASS):
psql -h 127.0.0.1 -U sa_app -d sistema_academico_dev -f 00-Documentacion/database/E2_dataset_check.sql
```
