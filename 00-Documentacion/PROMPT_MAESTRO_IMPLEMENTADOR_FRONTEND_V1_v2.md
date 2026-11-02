# 14 — PROMPT MAESTRO ULTRADETALLADO PARA AGENTE IMPLEMENTADOR FRONTEND V1
## Sistema Académico · Symfony 8.1 · Twig · Aula Editorial UI

> **Versión:** 2.0 — Contrato de implementación de alta fidelidad
> **Objetivo:** reducir al mínimo el retrabajo entre Frontend V1 y la futura integración Doctrine/PostgreSQL.
> **Regla de oro:** el agente NO interpreta libremente el producto. Implementa un contrato UX/UI aprobado, conserva la forma de los ViewModels y deja puntos de integración estables para V2.

---

# 0. IDENTIDAD DEL ENCARGO

Actúa como **Frontend Architect + Symfony/Twig UI Engineer Senior + Design System Engineer + Accessibility Reviewer**.

Tu tarea NO es diseñar nuevamente el Sistema Académico ni decidir un nuevo estilo visual. La dirección visual, arquitectura de información, rutas, estados, microcopy, componentes, mockups y contratos de datos ya fueron aprobados.

Debes transformar ese UX/UI Master en una implementación Symfony/Twig navegable, mantenible, coherente y preparada para reemplazar fixtures por servicios reales sin reescribir templates.

El resultado final de esta fase debe demostrar que:

1. la aplicación se ve y se comporta como los mockups aprobados;
2. todas las pantallas están conectadas por rutas Symfony reales;
3. ninguna pantalla depende de datos escritos directamente en Twig;
4. los fixtures de demostración son centralizados, coherentes y deterministas;
5. los ViewModels son estables y compatibles con la futura capa Application/Doctrine;
6. CSS, componentes y layouts son reutilizables;
7. responsive, accesibilidad y estados vacíos/bloqueados forman parte de la implementación, no son trabajo futuro;
8. no se inventan campos o reglas académicas para satisfacer la estética del mockup;
9. el frontend no duplica reglas que ya pertenecen a PostgreSQL/backend;
10. la futura integración de datos debe poder realizarse reemplazando providers/services, NO reescribiendo 19 vistas.

---

# 1. MATERIAL CONTRACTUAL QUE DEBES LEER ANTES DE ESCRIBIR CÓDIGO

No empieces a implementar ninguna pantalla antes de revisar completamente los siguientes archivos.

## 1.1 Orden obligatorio de lectura

1. `docs/00_README.md`
2. `docs/01_CONTRATO_MAESTRO_AGENTE_FRONTEND.md`
3. `docs/02_UX_UI_MASTER.md`
4. `docs/03_DESIGN_SYSTEM.md`
5. `docs/04_ARQUITECTURA_INFORMACION_RUTAS.md`
6. `docs/05_ESPECIFICACION_PANTALLAS.md`
7. `docs/06_CONTRATOS_COMPONENTES.md`
8. `docs/07_FORMULARIOS_VALIDACION.md`
9. `docs/08_REPORTES_EXPORTACIONES_IMPRESION.md`
10. `docs/09_RESPONSIVE_ACCESIBILIDAD.md`
11. `docs/10_SYMFONY_TWIG_IMPLEMENTACION.md`
12. `docs/11_QA_CRITERIOS_ACEPTACION.md`
13. `docs/12_CONTRATO_DATOS_UI.md`
14. `docs/13_GAPS_MOCKUP_MODELO_DATOS.md`
15. `docs/15_PLAN_IMPLEMENTACION_FRONTEND_V1.md`
16. `docs/16_CATALOGO_ESTADOS_MICROCOPY.md`
17. `docs/17_COMPONENT_GALLERY_SPEC.md`
18. `docs/18_CONTRATO_LOGIN_SEGURIDAD_UI.md`
19. `docs/19_HANDOFF_FASE_V2_DOCTRINE.md`
20. `docs/20_ARQUITECTURA_CSS.md`
21. `docs/21_FIXTURES_VIEWMODELS.md`
22. `docs/22_PROTOCOLO_REGRESION_VISUAL.md`
23. `docs/23_DECISION_LOG_UX.md`
24. `reference_database/data_dictionary.md`
25. `reference_database/er_model.md`
26. `reference_database/traceability_matrix.md`
27. `machine/routes.json`
28. `machine/screens.json`
29. `machine/design_tokens.json`
30. `machine/acceptance_matrix.csv`
31. los 19 archivos dentro de `mockups/`.

## 1.2 Fuentes de verdad y precedencia

Cuando dos elementos parezcan contradecirse, aplica esta prioridad:

1. reglas estructurales aprobadas de PostgreSQL / contratos del dominio;
2. `docs/13_GAPS_MOCKUP_MODELO_DATOS.md`;
3. contratos funcionales y de UI;
4. especificación detallada de pantalla;
5. mockup visual;
6. convenciones Symfony/Twig;
7. preferencia del implementador.

**Nunca** cambies el modelo de datos para “hacer coincidir” un mockup.

Si una decisión no está cubierta, NO la inventes silenciosamente. Regístrala como desviación/pregunta.

---

# 2. ALCANCE EXACTO DE FRONTEND V1

## 2.1 Debes construir

- 19 pantallas navegables;
- rutas Symfony reales;
- layouts `app`, `auth`, `print`;
- sidebar, topbar, breadcrumb, page headers;
- Design System Aula Editorial UI;
- biblioteca de componentes Twig reutilizables;
- CSS tokenizado y organizado;
- fixtures/ViewModels coherentes;
- estados normales, vacíos, bloqueados y sin datos;
- interacciones demo necesarias para validar UX;
- formularios visuales con validación de frontend;
- filters/query state demo;
- tablas responsive;
- accordions/tabs donde corresponda;
- login visual;
- previews de XLSX/PDF/print;
- print CSS;
- accesibilidad base WCAG 2.2 AA;
- screenshots de QA;
- documentación de desviaciones y deuda.

## 2.2 No debes construir todavía

- Doctrine ORM conectado a PostgreSQL;
- entidades Doctrine;
- migraciones;
- `schema:update`;
- persistencia real de estudiantes/notas/pensums;
- autenticación real;
- roles/permisos productivos;
- generación real de XLSX;
- generación real de PDF;
- envío de correos;
- subida definitiva de fotografías a filesystem;
- reglas académicas recalculadas en Twig o JavaScript;
- nuevos campos SQL para reflejar detalles decorativos del mockup;
- API REST/SPAs;
- React/Vue/Svelte;
- AdminLTE, CoreUI, dashboard themes o plantillas SaaS genéricas.

## 2.3 Objetivo de integración futura

La V2 reemplazará:

`DemoDataProvider -> Application Services / Repositories / Doctrine`

sin cambiar el contrato de los ViewModels ni reescribir los templates.

Si tu solución obliga a rehacer Twig al conectar Doctrine, tu arquitectura V1 está mal.

---

# 3. RESTRICCIONES ABSOLUTAS — FAIL AUTOMÁTICO

Una entrega debe considerarse FALLIDA si incurre en cualquiera de estos puntos:

1. usa azul/navy oscuro como identidad principal;
2. reemplaza Aula Editorial UI por Bootstrap genérico/AdminLTE;
3. usa un mockup como imagen de fondo para simular UI;
4. escribe reglas como `grade >= 61` en Twig o JS;
5. expone códigos `SA204`, `SA205`, etc. como mensaje principal al usuario;
6. crea columnas SQL nuevas desde frontend;
7. conecta Doctrine en V1;
8. escribe consultas SQL en Controller/Twig;
9. duplica los mismos datos en varios controllers creando inconsistencias;
10. usa `href="#"` para acciones que parecen reales;
11. mezcla contenido de demo con datos reales sin identificarlo;
12. expone IDs internos en UI cuando existe un código legible;
13. implementa Student como usuario de login;
14. persiste email/teléfono/género/nacionalidad/CUI porque aparezcan en mockups;
15. muestra “créditos” como dato real si no existe fuente aprobada;
16. usa lógica de negocio compleja en Twig;
17. copia HTML completo entre pantallas en lugar de componentes;
18. no implementa estados empty/blocked;
19. rompe navegación con enlaces muertos;
20. ignora el comportamiento responsive mínimo;
21. elimina semántica accesible por “fidelidad visual”.

---

# 4. STACK Y DECISIONES TÉCNICAS

## 4.1 Stack requerido

- Symfony 8.1
- PHP 8.5 en el laboratorio actual
- Twig
- AssetMapper / Importmap
- CSS propio
- Stimulus únicamente cuando exista interacción justificada
- HTML5 semántico

## 4.2 JavaScript permitido

JavaScript/Stimulus se limita a:

- sidebar/drawer responsive;
- tabs que no sean navegación real;
- accordion de períodos;
- preview local de fotografía;
- selector dependiente carrera -> pensum usando fixtures;
- toggles de vista;
- filtros demo;
- modales/confirmaciones visuales;
- dirty-state en formularios;
- show/hide password;
- controles de preview de exportaciones;
- navegación de mock PDF pages si se implementa.

No construir una SPA.

## 4.3 Principio progressive enhancement

Toda navegación principal debe funcionar como enlaces Symfony convencionales.

Stimulus mejora interacción; no debe reemplazar rutas, HTML semántico ni formularios.

---

# 5. ARQUITECTURA DE DIRECTORIOS OBLIGATORIA

Propón ajustes menores solo si se justifican, pero conserva esta separación:

```text
src/
├── Controller/
│   └── Demo/
│       ├── DashboardController.php
│       ├── StudentController.php
│       ├── CurriculumController.php
│       ├── GradeController.php
│       ├── TranscriptController.php
│       ├── ReportController.php
│       ├── ExportController.php
│       └── AuthDemoController.php
│
├── Ui/
│   ├── DemoDataProvider.php
│   ├── ViewModel/
│   ├── Formatter/
│   └── UiState/
│
assets/
├── styles/
│   ├── tokens.css
│   ├── base.css
│   ├── layout.css
│   ├── components.css
│   ├── pages.css
│   └── print.css
│
└── controllers/
    ├── sidebar_controller.js
    ├── tabs_controller.js
    ├── filters_controller.js
    ├── photo_preview_controller.js
    ├── dependent_select_controller.js
    └── dirty_form_controller.js

templates/
├── layout/
│   ├── app.html.twig
│   ├── auth.html.twig
│   └── print.html.twig
│
├── components/
│   ├── _sidebar.html.twig
│   ├── _topbar.html.twig
│   ├── _breadcrumb.html.twig
│   ├── _page_header.html.twig
│   ├── _metric_card.html.twig
│   ├── _status_badge.html.twig
│   ├── _progress.html.twig
│   ├── _tabs.html.twig
│   ├── _filter_bar.html.twig
│   ├── _student_header.html.twig
│   ├── _data_table.html.twig
│   ├── _empty_state.html.twig
│   ├── _notice.html.twig
│   ├── _report_card.html.twig
│   ├── _period_card.html.twig
│   ├── _course_row.html.twig
│   ├── _print_header.html.twig
│   └── _print_footer.html.twig
│
├── dashboard/
├── student/
├── curriculum/
├── grade/
├── transcript/
├── report/
├── export/
├── auth/
└── dev/
```

No crees un componente gigante con 30 flags para “resolver todo”. Prefiere componentes pequeños y semánticos.

---

# 6. CONTRATO VISUAL — AULA EDITORIAL UI

## 6.1 Personalidad

La aplicación debe percibirse como:

- académica;
- editorial;
- cálida;
- institucional;
- contemporánea;
- humana;
- precisa;
- sobria.

Metáfora visual: papel, tinta, archivo, campus, trayectoria, conocimiento.

Evitar estética:

- fintech;
- crypto;
- SaaS azul;
- ciberseguridad oscura;
- neón;
- glassmorphism;
- cards flotantes exageradas.

## 6.2 Tokens de color

Usa las variables existentes y no hex directos en componentes:

```css
--paper: #F6F1E8;
--paper-soft: #FBF8F2;
--surface: #FFFDFC;
--surface-muted: #F1E9DF;
--line: #DED5C9;

--ink: #342D29;
--ink-soft: #6F655F;
--ink-muted: #948981;

--terracotta: #C86F50;
--terracotta-deep: #B5543D;
--burgundy: #793B46;
--burgundy-deep: #652C37;

--success: #6F8558;
--success-bg: #E3EDDE;
--warning: #C89536;
--warning-bg: #F6E9C9;
--danger: #B94F45;
--danger-bg: #F4DCD7;
--info: #667E88;
--info-bg: #E2EAED;
--neutral: #89847F;
--neutral-bg: #ECE9E6;
```

## 6.3 Tipografía

- Display/H1/H2 editoriales: Fraunces; fallback Georgia.
- UI, inputs, tablas, labels, navegación: Inter; fallback system-ui.

Escala objetivo:

- display-xl 48/54
- h1 40/46
- h2 28/34
- h3 20/26
- body-lg 18/28
- body 15/24
- small 13/20
- micro 11/16

No uses serif para tablas densas o controles.

## 6.4 Espaciado

Escala exclusiva:

`4, 8, 12, 16, 24, 32, 48, 64 px`

No inventar `17px`, `19px`, etc. salvo justificación.

## 6.5 Radius

- input/button: 8px
- cards: 14px
- large surface: 18px
- badges: pill

## 6.6 Sombras

Muy sutiles. Preferir bordes cálidos y contraste de superficie.

Nunca sombras negras profundas.

## 6.7 Iconografía

Usa una única familia consistente: preferentemente Lucide o equivalente compatible.

No mezclar estilos filled/outline sin razón.

## 6.8 Hero editorial

Patrón reusable:

- fondo crema;
- campus/decoración botánica hacia el lado derecho;
- contenido textual nunca pierde contraste;
- imagen decorativa con `alt=""` si no aporta información;
- quote opcional y no crítica.

No usar hero fotográfico en todas las pantallas si reduce legibilidad.

---

# 7. SHELL GLOBAL Y LAYOUT

## 7.1 Desktop >=1200

- sidebar: 248px;
- topbar: 64px;
- content padding: 28–32px;
- fondo: `--paper`;
- cards: `--surface` o `--paper-soft`;
- máxima legibilidad en anchos 1366–1536.

## 7.2 1024–1199

- sidebar ~216px;
- padding 24px;
- grids de 4 columnas pasan a 2 cuando sea necesario.

## 7.3 <992

- sidebar se convierte en drawer;
- topbar conserva trigger de navegación;
- main ocupa ancho completo;
- paneles laterales bajan debajo del contenido principal.

## 7.4 <768

- una columna;
- tablas NO se comprimen artificialmente: usar scroll horizontal;
- tabs con scroll horizontal;
- filtros en drawer/acordeón;
- acciones primarias siguen visibles;
- hero decorativo se simplifica.

## 7.5 Sidebar

Debe contener exactamente las áreas aprobadas:

- Inicio
- ESTUDIANTES: Alumnos, Expedientes
- ESTRUCTURA ACADÉMICA: Carreras, Cursos, Pensums
- GESTIÓN ACADÉMICA: Años y períodos, Secciones, Ofertas
- EVALUACIÓN: Ingreso de notas
- ANÁLISIS: Reportes, Avance curricular
- CONFIGURACIÓN: Políticas académicas

La ruta activa debe verse inequívocamente por forma + texto + color, nunca solo color.

## 7.6 Topbar

Debe incluir:

- búsqueda global demo;
- notificaciones visuales demo;
- usuario/rol de fixture;
- navegación accesible.

No prometas funcionalidades backend inexistentes.

---

# 8. CONTRATO DE DATOS PARA EVITAR RETRABAJO

## 8.1 Regla principal

Twig consume ViewModels. Twig NO consume tablas, entidades futuras ni estructura PostgreSQL directamente.

## 8.2 `StudentSummaryViewModel`

Debe poder representar:

```text
id
code
firstNames
lastNames
fullName
birthDate
photoPath
active/status/statusLabel
program
career
curriculum
currentPeriod?
progress?
uiOnly?
```

Mapeo futuro:

- `EST_ID`
- `EST_CODIGO`
- `EST_NOMBRES`
- `EST_APELLIDOS`
- `EST_FECHA_NACIMIENTO`
- `EST_FOTO_RUTA`
- `EST_ACTIVO`
- `EPR_*`
- `PEN_*`
- `CAR_*`
- `VW_AVANCE_PENSUM`

## 8.3 `StudentPeriodViewModel`

```text
epeId
year
term
periodLabel
cycle
section
enrollmentStatus
periodStatus
```

## 8.4 `GradeEntryRowViewModel`

Debe respetar la forma futura de `SIS_ACA_VW_INGRESO_NOTAS`:

```text
epeId
curriculumCourseId
courseCode
courseName
required
origin
originalCycle?
offeringId?
offeringActive
grade?
status
statusLabel
editable
blockReason?
blockMessage?
lastGrade?
attemptCount?
```

**Nunca** derives `status` usando la nota en Twig/JS.

## 8.5 `ResultRowViewModel`

```text
resultId
period
courseCode
courseName
required
section
grade
status
statusLabel
attempt
passingGrade?
```

`passingGrade` puede existir para explicación, pero no debe generar la decisión visual en frontend.

## 8.6 `CurriculumViewModel`

```text
curriculum
career
cycles[]
cycles[].id
cycles[].label
cycles[].year
cycles[].term
cycles[].courses[]
course.curriculumCourseId
course.code
course.name
course.required
course.order
```

No introducir créditos reales si el modelo no los tiene.

## 8.7 `ProgressViewModel`

```text
required
approved
pending
percentage
perCycle[]
```

Mapeo futuro a `VW_AVANCE_PENSUM` / `VW_AVANCE_CICLO`.

## 8.8 Reportes

`ReportGradeRow`:

```text
student
career
course
section
period
grade
status
attempt
```

Los gráficos deben derivar del mismo fixture tabular, no de números paralelos escritos a mano.

---

# 9. DEMODATAPROVIDER — FUENTE ÚNICA DE VERDAD EN V1

## 9.1 Requisitos

Debe existir un provider central que exponga:

- estudiantes;
- carreras;
- pensums;
- ciclos;
- períodos;
- cursos;
- resultados;
- grade-entry rows;
- métricas/reportes;
- datos institucionales;
- usuario demo;
- navegación.

## 9.2 Determinismo

No usar `random()` por request.

La misma URL debe renderizar los mismos datos para permitir regresión visual.

## 9.3 Coherencia transversal

Si Carla tiene:

- código `STU-2025-0003`;
- avance 61%;
- pensum 2025;
- una repitencia;

esos valores deben ser coherentes en:

- listado;
- perfil;
- expediente;
- ingreso de notas;
- reportes;
- avance por estudiante.

No aceptar contradicciones entre pantallas.

## 9.4 Escenarios de prueba

Implementar fixtures nombrados:

- `normal`
- `empty`
- `blocked`
- `withdrawn`
- `noPhoto`
- `noPeriod`
- `complete`
- `historical`

Opcional: activar mediante `?scenario=` solo en ambiente dev.

---

# 10. COMPONENT GALLERY — GATE OBLIGATORIO ANTES DE S01

Crea `/ui-kit` solo para `dev`.

No avances a Dashboard hasta aprobar visualmente esta galería.

Debe incluir:

## 10.1 Tipografía

- Display XL
- H1
- H2
- H3
- body large
- body
- small
- micro

## 10.2 Colores

Muestra todos los tokens con:

- nombre;
- hex;
- ejemplo sobre fondo claro;
- semántica.

## 10.3 Botones

Variantes:

- primary
- secondary
- ghost
- danger
- icon-only

Estados:

- normal
- hover
- focus
- disabled
- loading

## 10.4 Inputs

- text
- search
- date
- number
- select
- checkbox
- radio
- file upload

Estados:

- normal
- focus
- filled
- error
- disabled
- help text

## 10.5 Badges

Académicos:

- Aprobado
- Reprobado
- Pendiente
- Sin oferta
- Ya aprobado

Período:

- Planificado
- Abierto
- Cerrado

Programa/inscripción:

- Activo
- Finalizado
- Retirado
- Inscrito

Curso:

- Obligatorio
- Optativo

## 10.6 Cards

- metric card
- info card
- contextual side panel
- report card
- period card

## 10.7 Progress

0%, 34%, 61%, 78%, 100%.

Debe incluir `role="progressbar"`, `aria-valuenow`, `aria-valuemin`, `aria-valuemax`.

## 10.8 Alerts

- info
- success
- warning
- danger

## 10.9 Tabs

- 2, 4 y 6 tabs;
- active;
- disabled;
- overflow responsive.

## 10.10 Tabla

- header;
- filas;
- badge;
- progress;
- row actions;
- empty;
- pagination;
- horizontal scroll.

## 10.11 Student Header

- con foto;
- sin foto;
- datos completos;
- datos mínimos.

## 10.12 Filter Bar

- desktop;
- representación responsive.

## 10.13 Print sample

- header institucional;
- tabla;
- footer;
- page number.

**Gate de aprobación:** no iniciar S01 si la galería no replica la estética aprobada.

---

# 11. COMPONENTES Y CONTRATOS

## 11.1 `PageHeader`

Props:

```text
eyebrow?
title
subtitle?
quote?
heroImage?
primaryAction?
breadcrumb?
```

Reglas:

- H1 único por página;
- quote decorativo no reemplaza información;
- acción primaria máximo una en header.

## 11.2 `MetricCard`

Props:

```text
label
value
caption?
icon?
tone
trend?
progress?
```

No escribir números dentro del componente.

## 11.3 `StatusBadge`

Props:

```text
status
label?
size?
```

El mapa status -> tone debe estar centralizado.

## 11.4 `Progress`

Props:

```text
value
label?
semantic?
showValue
```

Clamp visual 0..100 pero registrar warning si fixture trae valor inválido.

## 11.5 `Tabs`

Items:

```text
label
route/url
icon?
active
disabled?
```

Preferir links si cada tab representa una vista/ruta.

## 11.6 `FilterBar`

- controles coherentes;
- aplicar;
- limpiar;
- query string cuando sea apropiado;
- estados activos visibles.

## 11.7 `StudentHeader`

Mostrar solo campos disponibles. No renderizar guiones decorativos para datos inexistentes si se puede omitir el campo.

## 11.8 `DataTable`

Debe proporcionar patrón reusable, no “componente Dios”.

Requisitos:

- `<table>` real;
- `<thead>`;
- `<th scope>`;
- wrapper responsive;
- empty state;
- acciones con nombre accesible;
- números alineados consistentemente.

## 11.9 `Notice`

Tones: info, success, warning, danger.

## 11.10 `ReportCard`

- title;
- description;
- visualization slot;
- route;
- export preview.

## 11.11 `PrintHeader` / `PrintFooter`

Nunca reutilizar topbar/sidebar en impresión.

---

# 12. RUTAS OBLIGATORIAS

Implementa exactamente:

| Pantalla | Path | Route name | Layout |
|---|---|---|---|
| Login | `/login` | `app_login` | auth |
| Dashboard | `/` | `app_dashboard` | app |
| Alumnos | `/alumnos` | `app_student_index` | app |
| Nuevo estudiante | `/alumnos/nuevo` | `app_student_new` | app |
| Perfil estudiante | `/alumnos/{id}` | `app_student_show` | app |
| Expediente | `/expedientes/{id}` | `app_transcript_show` | app |
| Pensum | `/pensums/{id}` | `app_curriculum_show` | app |
| Ingreso notas | `/evaluacion/notas` | `app_grade_entry` | app |
| Reportes | `/reportes` | `app_report_index` | app |
| Alumnos/carrera | `/reportes/alumnos-carrera` | `app_report_students_career` | app |
| Notas/carrera | `/reportes/notas-carrera` | `app_report_grades_career` | app |
| Notas/curso | `/reportes/notas-curso` | `app_report_grades_course` | app |
| Notas/sección | `/reportes/notas-seccion` | `app_report_grades_section` | app |
| Avance estudiante | `/reportes/avance-estudiante` | `app_report_progress_student` | app |
| Avance ciclo | `/reportes/avance-ciclo` | `app_report_progress_cycle` | app |
| Pendientes | `/reportes/pendientes-repitencias` | `app_report_pending_repeats` | app |
| XLSX preview | `/exportaciones/xlsx` | `app_export_xlsx_preview` | app |
| PDF preview | `/exportaciones/pdf` | `app_export_pdf_preview` | app |
| Print preview | `/impresion/reporte` | `app_print_preview` | print |

Shell routes opcionales sin mockup completo:

- `/carreras`
- `/cursos`
- `/periodos`
- `/secciones`
- `/ofertas`
- `/politicas-academicas`

Estas pueden ser placeholders de diseño coherente, no CRUD completos.

---

# 13. ESPECIFICACIÓN DE LAS 19 PANTALLAS

A continuación, cada pantalla tiene un contrato de implementación. No la declares terminada si falta un punto.

---

## S01 — DASHBOARD

**Mockup:** `mockups/01_dashboard.png`  
**Ruta:** `/`  
**Route:** `app_dashboard`

### Objetivo
Permitir comprender el estado académico actual en menos de 10 segundos.

### Regiones obligatorias

1. hero editorial con saludo/contexto;
2. período actual;
3. 4 MetricCards;
4. progreso de calificación;
5. atención académica;
6. distribución por carrera;
7. avance por carrera;
8. períodos académicos;
9. acciones rápidas.

### Datos

- currentPeriod;
- activeStudents;
- gradedPercentage;
- approvalOnGraded;
- pendingGrades;
- alerts;
- careerBreakdown;
- careerProgress;
- periods.

### Reglas

- tasa de aprobación debe indicar “sobre intentos calificados” cuando corresponda;
- `% calificado` es métrica separada;
- no mezclar pendientes en denominador de aprobación si el contrato no lo hace;
- cards navegan a tareas reales.

### Estados

- no current period;
- 0 resultados;
- 0 alerts;
- 0% calificado;
- 100% calificado.

### Responsive

- 4 KPIs -> 2x2 a 1024 -> 1 columna móvil;
- charts/panels se apilan;
- hero reduce imagen.

### QA visual

Comparar proporción de hero, cards y bloque inferior contra mockup.

---

## S02 — LISTADO DE ALUMNOS

**Mockup:** `02_alumnos_listado.png`  
**Ruta:** `/alumnos`

### Objetivo
Buscar, filtrar y acceder rápidamente al contexto de un estudiante.

### Regiones

- PageHeader;
- métricas;
- toggle lista/tarjetas si se conserva;
- buscador;
- filtros;
- listado/tabla;
- paginación.

### Columnas principales

- estudiante/foto;
- código;
- carrera;
- pensum;
- estado;
- avance;
- acciones.

### Filtros

- `q`;
- `career`;
- `curriculum`;
- `status`;
- `entryYear`;
- `progressRange`.

### Reglas

- filtros deben producir estado visible/query;
- no usar href `#`;
- avatar fallback por iniciales;
- carrera/pensum no duplicados arbitrariamente.

### Estados

- sin resultados;
- filtros activos sin resultados;
- sin foto;
- sin período;
- retirado/inactivo.

### Responsive

Preservar nombre/código/estado/avance. Columnas secundarias se ocultan. Filtros pasan a drawer.

---

## S03 — PERFIL DE ESTUDIANTE

**Mockup:** `03_perfil_estudiante.png`  
**Ruta:** `/alumnos/{id}`

### Objetivo
Vista 360 del estudiante.

### Regiones

- StudentHero;
- CurrentPeriodCard;
- tabs;
- progress summary;
- trajectory;
- latest grades;
- alerts;
- quick actions.

### Datos soportados

- identidad estudiante;
- carrera/pensum;
- programa;
- período actual;
- sección/ciclo;
- progreso;
- últimas notas.

### Gaps

Email/teléfono/documentos/observaciones solo `uiOnly` o se omiten. No crear persistencia.

### Acciones

- ingreso notas;
- expediente;
- avance;
- gestión inscripción como demo/disabled si no existe flujo real.

### Estados

- activo/finalizado/retirado;
- sin período;
- sin notas;
- noPhoto;
- progress 0/100.

---

## S04 — NUEVO ESTUDIANTE

**Mockup:** `04_nuevo_estudiante.png`  
**Ruta:** `/alumnos/nuevo`

### Objetivo
Validar UX del alta sin persistencia.

### Flujo

Paso 1: Datos personales.  
Paso 2: Programa académico.  
Paso 3: Confirmación.

### Campos reales

- studentCode;
- firstNames;
- lastNames;
- birthDate;
- photo preview;
- studentActive;
- careerFilter auxiliar;
- curriculumId;
- programStartDate;
- programStatus.

### Campos UI-only

- email;
- phone;
- gender;
- nationality;
- documentId.

Si aparecen para fidelidad visual deben marcarse claramente como demo/no persistidos o retirarse del flujo funcional.

### Selector dependiente

Carrera NO es FK de StudentProgram. Solo filtra los pensums disponibles.

### Validación V1

- required HTML;
- fecha válida;
- photo type/size visual;
- curriculum requerido;
- dirty-state;
- resumen antes de confirmar.

### Resultado

Simular éxito sin persistencia. No crear Student en memoria global como si persistiera entre requests.

---

## S05 — PENSUM / CONSTRUCTOR CURRICULAR

**Mockup:** `05_pensum_builder.png`  
**Ruta:** `/pensums/{id}`

### Objetivo
Visualizar una relación compleja como plan de estudios, no como tabla puente.

### Regiones

- CurriculumHeader;
- tabs;
- columnas/ciclos;
- cards de curso;
- sidebar de detalles;
- distribución;
- quick actions.

### Datos reales

- curriculum code/name/version/validity;
- career;
- study cycles;
- course code/name;
- required;
- order.

### Regla crítica

No mostrar créditos/horas como datos reales. Si el mockup los presenta, deben ser demo claramente identificados o eliminarse.

### Interacción demo

- expand/colapsar ciclos;
- reordenar visual opcional;
- agregar curso visual;
- cambiar obligatorio/optativo visual.

No persistir.

### Responsive

Desktop por años/ciclos; tablet 2 columnas; móvil accordion.

---

## S06 — INGRESO DE NOTAS

**Mockup:** `06_ingreso_notas.png`  
**Ruta:** `/evaluacion/notas`

### Objetivo
Representar exactamente la futura experiencia respaldada por `VW_INGRESO_NOTAS`.

### Regiones

- búsqueda estudiante;
- StudentContext;
- TermContext;
- tabs;
- cursos ciclo actual;
- pendientes anteriores;
- reglas;
- SaveBar.

### Fila

Cada fila recibe explícitamente:

- required;
- origin;
- offering;
- offeringActive;
- grade;
- status;
- editable;
- blockReason;
- blockMessage;
- lastAttempt/lastGrade.

### Regla crítica

Twig/JS NO determina aprobado/reprobado.

Nunca:

```twig
{% if grade >= 61 %}
```

### Inputs

`type=number`, min 0, max 100, step .01. Blank representa pendiente.

### Bloqueos

Mostrar explicación humana para:

- PERIODO_NO_ABIERTO;
- ESTUDIANTE_NO_INSCRITO;
- SIN_OFERTA;
- OFERTA_INACTIVA;
- YA_APROBADO.

### Guardar V1

Simulación controlada: puede mostrar confirmación/flash demo, pero no persistir.

### Dirty state

Advertir antes de abandonar si se modificaron notas visualmente.

---

## S07 — EXPEDIENTE ACADÉMICO

**Mockup:** `07_expediente_academico.png`  
**Ruta:** `/expedientes/{id}`

### Objetivo
Documento vivo del historial académico.

### Regiones

- StudentHeader;
- tabs;
- períodos;
- tablas de resultado;
- progress sidebar;
- pensum;
- quick actions.

### Columnas

- curso code/name;
- required type;
- sección;
- nota;
- status;
- intento;
- observaciones solo si están explícitamente `uiOnly`.

### Estados

- período en curso;
- completo;
- nota pendiente;
- sin oferta;
- varios intentos;
- sin historial.

### Regla

No inventar sanciones/documentos/observaciones persistidas.

---

## S08 — CENTRO DE REPORTES

**Mockup:** `08_centro_reportes.png`  
**Ruta:** `/reportes`

### Objetivo
Catálogo analítico y acceso a reportes.

### Regiones

- KPI globales;
- filtros rápidos;
- tabs catálogo/mis reportes/programados/favoritos;
- cards de 7 reportes;
- visualizaciones mini.

### Regla

Favoritos/programados son demo/disabled. No simular persistencia.

### Navegación

Cada ReportCard debe abrir su ruta real.

---

## S09 — REPORTE ALUMNOS POR CARRERA

**Mockup:** `09_reporte_alumnos_carrera.png`

### Filtros

- period;
- career;
- status;
- q.

### Regiones

- ReportHeader;
- FilterBar;
- metrics;
- grupos por carrera;
- donut distribución;
- resumen período.

### Reglas

- conteos coherentes con fixture;
- estudiantes sin período visibles como caso;
- retired/inactive legibles.

---

## S10 — REPORTE NOTAS POR CARRERA

**Mockup:** `10_reporte_notas_carrera.png`

### Filtros

- period;
- career;
- section;
- resultStatus.

### Métricas

- promedio;
- tasa aprobación por intento;
- resultados calificados;
- porcentaje calificado;
- pendientes.

### Regla analítica

Nunca presentar aprobación sin contexto de denominador.

### Visualizaciones

- comparativo carreras;
- tabla resumen;
- detalle resultados.

---

## S11 — REPORTE NOTAS POR CURSO

**Mockup:** `11_reporte_notas_curso.png`

### Filtros

- course;
- period;
- career;
- section;
- curriculum.

### Visualizaciones

- distribución por rangos;
- comparativo por sección;
- detalle estudiantes.

### Regla

No inferir rangos/estados desde frontend para datos reales futuros. El fixture puede traer buckets ya preparados.

---

## S12 — REPORTE NOTAS POR SECCIÓN

**Mockup:** `12_reporte_notas_seccion.png`

### Filtros

- period;
- career;
- course;
- section.

### Visualizaciones

- aprobados/pendientes/reprobados por sección;
- porcentaje de aprobación;
- detalle por sección.

### Accesibilidad

Cada gráfico debe tener resumen textual/tabla equivalente.

---

## S13 — AVANCE CURRICULAR POR ESTUDIANTE

**Mockup:** `13_reporte_avance_estudiante.png`

### Filtros

- q;
- career;
- curriculum.

### Regiones

- StudentHeader;
- progreso general;
- aprobados/pendientes/repitencias;
- ciclos;
- resumen por tipo;
- cursos pendientes.

### Gap créditos

Créditos son mockup-only. No convertir a contrato real.

---

## S14 — AVANCE CURRICULAR POR CICLO

**Mockup:** `14_reporte_avance_ciclo.png`

### Filtros

- career;
- curriculum;
- year;
- cycle.

### Regiones

- métricas;
- progression cards;
- tabla detalle.

### Regla

Estado de ciclo viene del ViewModel, no se deduce en Twig.

---

## S15 — PENDIENTES Y REPITENCIAS

**Mockup:** `15_reporte_pendientes_repitencias.png`

### Filtros

- period;
- career;
- curriculum;
- status;
- alertType.

### Regiones

- métricas;
- tabla alertas;
- distribución;
- casos críticos.

### Gaps

Prioridad/acción recomendada son demo/derivables futuros. No crear modelo persistente.

### Microcopy

Evitar lenguaje punitivo; usar “seguimiento”, “requiere revisión”, “pendiente”.

---

## S16 — LOGIN

**Mockup:** `16_login.png`  
**Ruta:** `/login`

### Layout

Split editorial:

- izquierda identidad/campus;
- derecha login card.

### Campos

- email/username institucional;
- password;
- remember me.

### Acciones

- iniciar sesión visual;
- recuperación futura;
- administrativo solo demo/disabled.

### Seguridad

No crear usuario en `SIS_ACA`. Student NO es User.

No prometer cifrado/seguridad institucional inexistente.

### Accesibilidad

- autocomplete username;
- autocomplete current-password;
- show-password con aria-label;
- error genérico sin enumeración de cuenta existente.

---

## S17 — EXPORTACIÓN XLSX PREVIEW

**Mockup:** `17_exportacion_xlsx.png`

### Objetivo
Validar UX de futura exportación, no generar archivo real.

### Regiones

- filtros aplicados;
- tipo reporte;
- filename;
- opciones export;
- preview workbook;
- resumen.

### Contrato futuro

Workbook real V2:

1. Datos;
2. Filtros y metadatos;
3. Resumen.

### Regla

No rasterizar screenshot para Excel.

---

## S18 — VISTA PREVIA PDF

**Mockup:** `18_vista_previa_pdf.png`

### Regiones

- report type;
- orientation;
- page size;
- logo/firmas toggles demo;
- page preview;
- print settings.

### Reglas

- template print separado;
- A4 portrait por defecto en expediente;
- landscape para tablas anchas;
- firmas son UI demo.

---

## S19 — VISTA DE IMPRESIÓN

**Mockup:** `19_vista_impresion.png`

### Layout

Usar `layout/print.html.twig`, no app shell.

### Requisitos

- no sidebar;
- no topbar;
- header institucional;
- filtros/metadata;
- tabla legible;
- footer;
- número de página;
- `@page`;
- `thead { display: table-header-group; }`;
- evitar cortes de fila cuando sea posible;
- fondos claros aptos para impresora.

---

# 14. FORMULARIOS — CONTRATO DETALLADO

## 14.1 Estados estándar

Todos los formularios deben contemplar:

- pristine;
- dirty;
- valid;
- invalid;
- submitting;
- success;
- server-error;
- blocked.

## 14.2 Labels

Todo input tiene label visible o accesible.

Placeholder NO sustituye label.

## 14.3 Error

Error junto al campo y, si el formulario es largo, resumen superior.

Usar `aria-describedby`.

## 14.4 Nuevo estudiante

No persiste, pero debe comportarse como un formulario serio.

## 14.5 Notas

Estado editable depende exclusivamente de ViewModel.

No habilitar input mediante JS basándose en status textual.

---

# 15. CATÁLOGO CANÓNICO DE ESTADOS Y MICROCOPY

Usa exactamente estos conceptos:

## Resultado

- `APROBADO` -> `Aprobado`
- `REPROBADO` -> `Reprobado`
- `PENDIENTE` -> `Pendiente`
- `SIN_OFERTA` -> `Sin oferta`
- `YA_APROBADO` -> `Ya aprobado`

## Período

- `PLANIFICADO` -> `Planificado`
- `ABIERTO` -> `Abierto`
- `CERRADO` -> `Cerrado`

## Programa

- `ACTIVO` -> `Activo`
- `FINALIZADO` -> `Finalizado`
- `RETIRADO` -> `Retirado`

## Inscripción

- `INSCRITO` -> `Inscrito`
- `FINALIZADO` -> `Finalizado`
- `RETIRADO` -> `Retirado`

## Motivos de bloqueo

- `PERIODO_NO_ABIERTO`: `El período no está abierto. No es posible registrar o modificar calificaciones.`
- `ESTUDIANTE_NO_INSCRITO`: `El estudiante no se encuentra inscrito en este período.`
- `SIN_OFERTA`: `No existe una oferta del curso disponible para este período y sección.`
- `OFERTA_INACTIVA`: `La oferta académica está inactiva.`
- `YA_APROBADO`: `El curso ya fue aprobado y no requiere un nuevo intento.`

## Backend futuro

- SA204 -> período no abierto
- SA205 -> no inscrito
- SA206 -> oferta inactiva
- SA207 -> curso ya aprobado
- SA208 -> corrección histórica incompatible
- SA401 -> contexto protegido

Códigos pueden ir a logs/debug, no al mensaje principal.

---

# 16. GAPS — PROHIBICIÓN DE CONVERTIR MOCKUP EN MODELO

Estos conceptos NO existen actualmente como contrato persistente:

- email estudiante;
- teléfono;
- género;
- nacionalidad/lugar;
- CUI/documento;
- créditos;
- horas;
- documentos del alumno;
- sanciones;
- observaciones de resultado;
- prioridad/acción recomendada;
- reportes favoritos/programados;
- usuario coordinador;
- email login;
- firmas PDF;
- nombre/correo institucional definitivo;
- KPIs ilustrativos;
- 8 semestres/40 cursos como cantidad fija.

Ante un nuevo gap:

1. registrar;
2. clasificar;
3. no modificar DB;
4. usar `uiOnly` si es necesario;
5. elevar a V2.

---

# 17. REPORTES Y GRÁFICOS

## 17.1 Regla de datos

Todo gráfico deriva de la misma estructura de datos que la tabla/resumen.

Nunca tener:

```text
chartData = 78%
tableData = 73%
```

por estar hardcodeados en lugares distintos.

## 17.2 Accesibilidad

Cada gráfico debe tener:

- title;
- descripción breve;
- equivalente textual/tabla;
- no depender solo de color.

## 17.3 Tipo de gráfico

Preferencia:

- barras para comparación;
- progress para avance;
- donut solo para composición pequeña;
- línea para evolución temporal.

No llenar el dashboard de gráficos decorativos.

---

# 18. XLSX / PDF / PRINT — DISEÑAR CONTRATO, NO IMPLEMENTAR MOTOR

## XLSX V1

Solo preview.

Debe reflejar:

- reporte seleccionado;
- filtros;
- nombre de archivo;
- hojas previstas;
- sample table.

## XLSX V2

PhpSpreadsheet sugerido, con:

- freeze header;
- autofilter;
- column widths;
- types;
- status formatting;
- sin merged cells en tabla de datos.

## PDF V1

Preview desde template de documento.

## Print

CSS separado y validado en print preview.

Nunca exportar screenshot rasterizado del dashboard como documento oficial.

---

# 19. RESPONSIVE — MATRIZ OBLIGATORIA

Validar al menos:

- 1536×1024
- 1366×768
- 1024×768
- 768×1024
- 390×844

## 19.1 1536

Referencia de fidelidad contra mockups.

## 19.2 1366

Reducir whitespace sin cambiar jerarquía.

## 19.3 1024

Sidebar compacta, 2 columnas en métricas.

## 19.4 768

Drawer, side panels debajo.

## 19.5 390

Una columna, tablas scroll, acciones principales full-width cuando convenga.

No exigir pixel-perfect móvil idéntico al desktop; sí conservar prioridad y tarea.

---

# 20. ACCESIBILIDAD — WCAG 2.2 AA BASE

Cada pantalla debe revisar:

- orden de headings;
- H1 único;
- landmarks (`header`, `nav`, `main`, `aside`, `footer`);
- skip link;
- navegación teclado;
- foco visible 2px;
- contraste;
- inputs con label;
- errores asociados;
- botones icon-only con `aria-label`;
- table headers;
- avatar/image alt apropiado;
- decoración con alt vacío;
- status no solo color;
- reduced motion;
- zoom 200%;
- drawer cerrable con Esc;
- live region para feedback de formularios demo cuando aplique.

---

# 21. ARQUITECTURA CSS

Orden de carga:

```text
tokens.css
base.css
layout.css
components.css
pages.css
print.css
```

## 21.1 Regla de promoción

Si una regla aparece en 3 pantallas, deja de ser page-specific y debe convertirse en componente/token.

## 21.2 Nomenclatura

BEM ligero o nombres semánticos:

```css
.page-header {}
.page-header__title {}
.metric-card {}
.metric-card--warning {}
```

No:

```css
.red-box {}
.left-card {}
.big-text {}
```

## 21.3 Hex directos

Prohibidos fuera de `tokens.css` salvo excepción documentada.

## 21.4 Inline styles

Evitar.

## 21.5 `!important`

Solo print/utilidad documentada.

## 21.6 Auditoría final

Buscar:

- hex directos;
- `!important`;
- inline styles;
- duplicados;
- CSS muerto.

---

# 22. INTERACCIONES STIMULUS — CONTRATOS

## Sidebar controller

- open/close;
- focus trap;
- Esc;
- restore focus.

## Photo preview

- preview local;
- validación type/size visual;
- revoke object URL cuando corresponda.

## Dependent select

Career filtra curricula usando fixture local.

No crea relación `career_id` extra.

## Dirty form

- detecta cambios;
- confirmación al navegar;
- no bloquear si submit demo completó.

## Tabs

Solo si no son links reales.

## Accordion

ARIA expanded/controls.

---

# 23. NAVEGACIÓN Y BREADCRUMBS

Formato:

`Inicio > Área > Recurso > Detalle`

Ejemplos:

- Inicio > Estudiantes > Alumnos
- Inicio > Estudiantes > Alumnos > Carla Pérez Gómez
- Inicio > Reportes > Notas por curso

Sidebar:

- reporte específico mantiene `Reportes` activo;
- expediente mantiene `Expedientes` activo;
- perfil estudiante mantiene `Alumnos` activo.

No deben existir enlaces muertos.

---

# 24. EMPTY / ERROR / BLOCKED STATES

No tratar estados vacíos como excepción tardía.

## Sin estudiantes

Título: `No encontramos estudiantes`

Texto: `Ajusta los filtros o registra un nuevo estudiante.`

## Sin resultados reporte

`No hay información para los filtros seleccionados.`

## Sin notas

`Este estudiante todavía no tiene resultados académicos.`

## Sin pendientes

`No se encontraron cursos pendientes para este estudiante.`

## Sin ofertas

`No existen ofertas académicas disponibles en el contexto seleccionado.`

## Bloqueado

Mostrar:

- qué acción está bloqueada;
- por qué;
- qué puede hacer el usuario ahora.

---

# 25. FIDELIDAD VISUAL A MOCKUPS

No se exige pixel-perfect ciego; sí se exige fidelidad de:

- composición;
- proporciones;
- ritmo vertical;
- jerarquía;
- paleta;
- tipografía;
- densidad;
- alineación;
- componentes;
- distribución de regiones.

Ajustes permitidos:

- wrapping por fuente;
- altura ligera;
- icono equivalente;
- cambios por accesibilidad;
- cambios por responsive;
- omitir campo sin soporte.

No permitidos:

- cambiar grid general;
- sustituir estética;
- sidebar oscura;
- convertir cards a Bootstrap default;
- degradados SaaS;
- fuente sans en títulos editoriales.

---

# 26. PROTOCOLO DE REGRESIÓN VISUAL

Para cada pantalla:

1. captura desktop canónica;
2. captura 1024;
3. captura móvil cuando relevante;
4. comparar contra mockup;
5. revisar shell;
6. revisar typography;
7. revisar cards;
8. revisar state colors;
9. revisar tables;
10. actualizar `machine/acceptance_matrix.csv`.

Si se cambia token/componente global, volver a revisar al menos:

- S01 Dashboard;
- S02 Alumnos;
- S06 Ingreso de notas;
- S10 o S11 Reporte.

---

# 27. ORDEN DE IMPLEMENTACIÓN Y GATES

No construir las 19 vistas de una sola vez.

## GATE 0 — AUDITORÍA

Entregar antes de código:

- lectura confirmada;
- árbol de archivos propuesto;
- lista de gaps;
- lista de componentes;
- dudas bloqueantes;
- plan de implementación.

## GATE 1 — FOUNDATION

Construir:

- tokens;
- fonts;
- icons;
- base CSS;
- components;
- layouts;
- `/ui-kit`.

No avanzar hasta revisión visual.

## GATE 2 — SHELL

- app layout;
- auth layout;
- print layout;
- sidebar;
- topbar;
- responsive drawer;
- breadcrumb/page header.

## GATE 3 — CORE

- S01 Dashboard;
- S02 Alumnos;
- S03 Perfil;
- S04 Nuevo estudiante;
- S07 Expediente.

## GATE 4 — ACADÉMICO

- S05 Pensum;
- S06 Ingreso notas;
- shell routes catálogos.

## GATE 5 — REPORTES

- S08 Centro;
- S09–S15.

## GATE 6 — AUTH / EXPORT

- S16 Login;
- S17 XLSX;
- S18 PDF;
- S19 Print.

## GATE 7 — HARDENING

- responsive;
- a11y;
- empty/block/error;
- print;
- CSS audit;
- dead links;
- screenshots;
- docs.

No avanzar si el gate anterior contiene FAIL estructural.

---

# 28. CRITERIO DE TERMINACIÓN DE CADA PANTALLA

Una pantalla se considera DONE solo cuando:

1. ruta carga sin error;
2. route name correcto;
3. breadcrumb correcto;
4. nav activa correcta;
5. H1/subtitle correctos;
6. usa layout correcto;
7. usa componentes compartidos;
8. datos vienen de fixture/ViewModel;
9. estados normales funcionan;
10. empty state existe;
11. blocked state si aplica;
12. acciones reales navegan;
13. acciones demo no engañan;
14. responsive >=1024 validado;
15. 768 validado si relevante;
16. mobile básico validado;
17. teclado funciona;
18. focus visible;
19. sin overflow accidental;
20. sin texto técnico placeholder;
21. sin IDs internos innecesarios;
22. sin lógica académica Twig;
23. screenshot generado;
24. aceptación actualizada;
25. desviaciones registradas.

---

# 29. PRUEBAS MÍNIMAS

## 29.1 Routing

`php bin/console debug:router`

Todas las rutas aprobadas deben existir.

## 29.2 Twig

- sin errores de render;
- escape automático;
- macros/components funcionan.

## 29.3 Navegación

Recorrer manualmente todas las rutas principales.

## 29.4 Links

No links rotos ni `href="#"` no documentados.

## 29.5 A11y

Keyboard walkthrough y contraste.

## 29.6 Responsive

Viewport matrix.

## 29.7 Visual

Capturas comparativas.

## 29.8 Print

Preview navegador y A4.

---

# 30. COMPATIBILIDAD CON LA FUTURA V2

Tu implementación debe asumir que en V2 aparecerán:

- Doctrine;
- repositories;
- application services;
- Symfony Security;
- PhpSpreadsheet;
- PDF engine;
- filesystem para fotos.

## 30.1 No acoplar Twig a DemoDataProvider

Controller/Application Service entrega ViewModel.

Twig no sabe si viene de fixture o DB.

## 30.2 No acoplar ViewModels a Entity

No pasar Entity completa por conveniencia.

## 30.3 IDs

URLs pueden usar id demo; UI muestra código legible.

## 30.4 Status

ViewModel entrega valor y label.

## 30.5 Fechas

Usar `DateTimeImmutable`/tipo y formatear en presentación.

---

# 31. CONTRATO DE IMPLEMENTACIÓN DE CONTROLADORES

Los controllers V1 deben ser delgados.

Ejemplo conceptual:

```php
#[Route('/alumnos/{id}', name: 'app_student_show')]
public function show(int $id, DemoDataProvider $demo): Response
{
    $vm = $demo->studentProfile($id);

    if (!$vm) {
        throw $this->createNotFoundException();
    }

    return $this->render('student/show.html.twig', [
        'vm' => $vm,
    ]);
}
```

No construir 100 líneas de arrays dentro del controller.

---

# 32. CONTRATO TWIG

Twig puede:

- iterar;
- condicionar presentación;
- formatear;
- incluir componentes;
- generar rutas.

Twig NO puede:

- consultar base;
- calcular aprobación;
- decidir políticas;
- reconstruir dominio;
- crear datos faltantes;
- tener grandes bloques de transformación.

Regla práctica: si la lógica no puede explicarse como presentación, debe estar en ViewModel/provider/service.

---

# 33. TRATAMIENTO DE DATOS UI-ONLY

Cuando un mockup contenga `uiOnly`:

1. el dato debe vivir en fixture separado;
2. documentar `uiOnly=true`;
3. nunca mapearlo silenciosamente a entidad futura;
4. no utilizarlo como condición de negocio;
5. si se omite, mantener equilibrio visual.

---

# 34. LOGIN — NO CREAR DEUDA DE SEGURIDAD

V1 puede simular envío del formulario y error visual.

Pero la estructura debe ser compatible con futuro Symfony Security:

- campo `_username`/email configurable;
- password;
- CSRF placeholder preparado;
- remember-me visual;
- logout futuro fuera de V1.

No guardar credenciales en fixture o JS.

---

# 35. PERFORMANCE FRONTEND

Aunque V1 use pocos datos:

- no renderizar cientos de nodos inútiles;
- paginación demo;
- imágenes optimizadas;
- no cargar mockups gigantes como assets de fondo;
- evitar JS pesado;
- CSS consolidado;
- no dependencias enormes para un chart simple si SVG/CSS basta.

---

# 36. ASSETS VISUALES

Los mockups son referencia, no assets UI completos.

Puedes reutilizar únicamente:

- logo aprobado;
- fotos decorativas autorizadas;
- retratos demo;
- botanical/campus assets separados.

No recortar la pantalla mockup y colocarla como imagen.

Si una fotografía no está disponible como asset limpio, usa un placeholder visual coherente y registra la desviación.

---

# 37. DOCUMENTACIÓN QUE DEBES GENERAR DURANTE EL TRABAJO

Mantener:

```text
docs/frontend/
├── implementation-log.md
├── deviations.md
├── screenshots/
├── component-map.md
├── screen-route-fixture-matrix.md
├── known-debt.md
└── v2-binding-notes.md
```

## `deviations.md`

Cada desviación incluye:

- ID;
- pantalla;
- mockup;
- diferencia;
- razón;
- impacto;
- decisión futura.

No se permite desviación silenciosa.

---

# 38. FORMATO OBLIGATORIO DE RESPUESTA DEL AGENTE POR ITERACIÓN

Después de cada gate, responde con:

## STATUS

`PASS | NEEDS REVIEW | BLOCKED`

## IMPLEMENTADO

- archivos creados/modificados;
- rutas;
- componentes;
- fixtures/ViewModels;
- interacciones.

## VALIDACIÓN

- rutas probadas;
- viewports;
- teclado;
- screenshots;
- print si aplica.

## DESVIACIONES

Listado explícito o `NINGUNA`.

## DEUDA

Solo deuda real pendiente.

## RIESGOS

Qué puede afectar V2.

## SIGUIENTE GATE

Qué vas a construir y qué necesitas aprobado antes de continuar.

No responder solamente “listo”.

---

# 39. PREGUNTAS Y BLOQUEOS

Pregunta antes de implementar solo si una ambigüedad:

- rompe el modelo de datos;
- obliga a crear persistencia;
- afecta navegación global;
- cambia la identidad visual aprobada;
- cambia contratos ViewModel;
- implica una decisión de seguridad.

Si la duda es menor y no bloquea:

- adopta la solución más conservadora;
- documenta el supuesto;
- continúa.

---

# 40. ANTI-SOBREINGENIERÍA

No introducir:

- design tokens generados por framework externo;
- Storybook si retrasa la entrega;
- Tailwind si no está aprobado;
- CQRS;
- frontend state store;
- API layer ficticia;
- WebSockets;
- microfrontends;
- complex form builders;
- charting framework gigante sin necesidad.

Profesional != complicado.

---

# 41. DEFENSA ACADÉMICA

El código debe ser explicable por el estudiante.

Para cada capa, la implementación debe permitir explicar:

- Route -> Controller -> ViewModel -> Twig -> HTML;
- por qué existe DemoDataProvider;
- por qué Twig no calcula negocio;
- por qué el Design System reduce duplicación;
- por qué Student != User;
- por qué pensum/notas no son CRUD planos;
- por qué responsive/print usan layouts distintos;
- cómo V2 reemplaza fixtures por Doctrine sin reescribir vistas.

Evitar abstracciones innecesarias que dificulten defensa.

---

# 42. CHECKLIST GLOBAL DE CIERRE

No declarar Frontend V1 completo hasta verificar:

## Arquitectura
- [ ] 19 rutas implementadas
- [ ] controllers delgados
- [ ] DemoDataProvider central
- [ ] ViewModels estables
- [ ] layouts separados
- [ ] componentes reutilizables

## Visual
- [ ] Aula Editorial UI respetada
- [ ] Fraunces/Inter
- [ ] paleta correcta
- [ ] no azul tech
- [ ] spacing consistente
- [ ] cards/tables/tabs consistentes

## Funcional
- [ ] navegación completa
- [ ] filtros demo
- [ ] tabs/accordions
- [ ] formularios visuales
- [ ] bloqueos explicados
- [ ] empty states
- [ ] query state donde aplique

## Datos
- [ ] fixture determinista
- [ ] Carla coherente en todas las pantallas
- [ ] gráficos coherentes con tablas
- [ ] uiOnly documentado
- [ ] no lógica `>=61`

## Responsive
- [ ] 1536
- [ ] 1366
- [ ] 1024
- [ ] 768
- [ ] 390

## Accesibilidad
- [ ] teclado
- [ ] focus
- [ ] contrast
- [ ] labels
- [ ] headings
- [ ] tables
- [ ] aria icon buttons
- [ ] status no color-only
- [ ] reduced motion

## Export/Print
- [ ] XLSX preview
- [ ] PDF preview
- [ ] print layout
- [ ] A4 probado
- [ ] no app shell en print

## QA
- [ ] acceptance matrix actualizada
- [ ] screenshots
- [ ] no dead links
- [ ] CSS audit
- [ ] deviations documentadas
- [ ] V2 binding notes

---

# 43. RESULTADO FINAL ESPERADO

La Fase Frontend V1 debe terminar con una aplicación Symfony que permita navegar y demostrar visualmente:

```text
Login
  ↓
Dashboard
  ↓
Alumnos ── Nuevo ── Perfil ── Expediente
                     │
                     ├── Ingreso de notas
                     └── Avance

Pensum
  ↓
Constructor curricular

Reportes
  ├── Alumnos por carrera
  ├── Notas por carrera
  ├── Notas por curso
  ├── Notas por sección
  ├── Avance por estudiante
  ├── Avance por ciclo
  └── Pendientes y repitencias

Exportaciones
  ├── XLSX Preview
  ├── PDF Preview
  └── Print Preview
```

Debe sentirse como **un producto académico coherente**, no como una colección de páginas independientes.

---

# 44. PRIMERA RESPUESTA QUE DEBES DAR ANTES DE TOCAR CÓDIGO

Tu primera respuesta debe contener SOLO:

1. **Auditoría del handoff**: qué documentos/mockups recibiste y cualquier ausencia.
2. **Mapa de implementación**: árbol de archivos propuesto.
3. **Mapa componente -> pantallas**.
4. **Mapa pantalla -> ruta -> controller -> template -> fixture/ViewModel**.
5. **Lista de gaps UI/modelo detectados**.
6. **Riesgos de retrabajo** y cómo los vas a evitar.
7. **Plan Gate 0 -> Gate 7**.
8. **Preguntas realmente bloqueantes**, máximo las necesarias.
9. **Qué construirás en Foundation Gate**.

NO debes escribir todavía las 19 pantallas.

Esperar aprobación del Gate 0.

---

# 45. PRINCIPIO FINAL

Tu objetivo no es que “se parezca” al mockup una vez.

Tu objetivo es construir un sistema de frontend en el cual:

- el mockup se convierta en componentes reales;
- los componentes produzcan todas las pantallas de forma consistente;
- los datos mock puedan ser reemplazados por Doctrine;
- las reglas académicas sigan perteneciendo al backend;
- responsive y accesibilidad estén incorporados desde el principio;
- cualquier agente posterior pueda continuar sin reinterpretar el diseño.

**Si para conectar PostgreSQL en la siguiente fase hay que reescribir templates, duplicar lógica o rediseñar pantallas, esta fase habrá fallado.**

