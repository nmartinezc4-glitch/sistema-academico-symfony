# Diccionario de datos — Sistema Académico (SIS_ACA)

> Generado desde el catálogo de PostgreSQL 16 después de ejecutar `run_all.sql` (E1). Las columnas TIPO, NULL, DEFAULT, PK/FK, UNIQUE y CHECK salen de la base real, no se escribieron a mano.

## 1. Convención de nombres

| Elemento | Regla | Ejemplo |
|---|---|---|
| Tabla | `SIS_ACA_<ENTIDAD>` en español, escrita en mayúsculas **sin comillas** (PostgreSQL la guarda en minúsculas) | `SIS_ACA_ESTUDIANTE` → `sis_aca_estudiante` |
| Columna | `<PREFIJO>_<CAMPO>` | `EST_NOMBRES` |
| Clave primaria | `<PREFIJO>_ID` | `EST_ID` |
| Clave foránea | `<PREFIJO_LOCAL>_<PREFIJO_REFERENCIADO>_ID` | `EPR_EST_ID` |
| Constraints | `PK_`, `FK_<LOCAL>_<REF>`, `UQ_`, `UX_` (único parcial), `CK_` | `FK_EPR_EST`, `CK_RES_NOTA_RANGO` |
| Índices | `IX_<PREFIJO>_<COLUMNAS>` | `IX_RES_OFE` |
| Vistas | `SIS_ACA_VW_<NOMBRE>` | `SIS_ACA_VW_AVANCE_PENSUM` |
| Funciones | `SIS_ACA_FN_<NOMBRE>`; triggers `TRG_<PREFIJO>_<Tn>_<REGLA>` | `TRG_RES_T2_CONTEXTO` |

**Prefijos de entidad (únicos).** Las entidades simples usan sus 3 primeras letras. Las compuestas usan iniciales para no chocar con otra entidad.

| Prefijo | Tabla | Concepto del contrato | Regla del prefijo |
|---|---|---|---|
| POL | SIS_ACA_POLITICA_ACADEMICA | academic_policy | 3 primeras letras |
| ANL | SIS_ACA_ANIO_LECTIVO | academic_year | iniciales (AÑO → ANI chocaría con ANIO_*) |
| PER | SIS_ACA_PERIODO_ACADEMICO | academic_term | 3 primeras letras |
| CAR | SIS_ACA_CARRERA | career | 3 primeras letras |
| PEN | SIS_ACA_PENSUM | curriculum | 3 primeras letras |
| CIC | SIS_ACA_CICLO_CURRICULAR | study_cycle | 3 primeras letras |
| CUR | SIS_ACA_CURSO | course | 3 primeras letras |
| PCU | SIS_ACA_PENSUM_CURSO | curriculum_course | iniciales (PEN ya en uso) |
| SEC | SIS_ACA_SECCION | section | 3 primeras letras |
| EST | SIS_ACA_ESTUDIANTE | student | 3 primeras letras |
| EPR | SIS_ACA_ESTUDIANTE_PROGRAMA | student_program | iniciales (EST ya en uso) |
| EPE | SIS_ACA_ESTUDIANTE_PERIODO | student_term | iniciales (EST ya en uso) |
| OFE | SIS_ACA_OFERTA_CURSO | course_offering | 3 primeras letras |
| RES | SIS_ACA_RESULTADO_CURSO | student_course_result | 3 primeras letras |

**Valores de estado (VARCHAR + CHECK):**

| Columna | Valores | Equivalente en el contrato |
|---|---|---|
| ANL_ESTADO, PER_ESTADO | PLANIFICADO · ABIERTO · CERRADO | PLANNED · OPEN · CLOSED |
| EPR_ESTADO | ACTIVO · FINALIZADO · RETIRADO | active · finished · withdrawn |
| EPE_ESTADO | INSCRITO · FINALIZADO · RETIRADO | — |
| RES_ESTADO *(derivado, solo en vistas)* | PENDIENTE · APROBADO · REPROBADO | PENDING · APPROVED · FAILED |

## 2. Tablas

### SIS_ACA_POLITICA_ACADEMICA

Reglas académicas versionadas. La vigencia termina el día anterior al inicio de la siguiente política (derivado en SIS_ACA_VW_POLITICA_LINEA_TIEMPO). Una política usada por un período queda protegida (T3).

| COLUMNA | TIPO | NULL | DEFAULT | PK/FK | UNIQUE | CHECK | DESCRIPCIÓN |
|---|---|---|---|---|---|---|---|
| POL_ID | INTEGER | NO | IDENTITY | PK | — | — | Identificador interno (PK, IDENTITY). |
| POL_CODIGO | VARCHAR(30) | NO | — | — | UQ_POL_CODIGO | CK_POL_CODIGO_NO_VACIO | Código único de la política. Ej.: POL-2026-01. |
| POL_NOMBRE | VARCHAR(150) | NO | — | — | — | CK_POL_NOMBRE_NO_VACIO | Nombre descriptivo. |
| POL_NOTA_APROBACION | NUMERIC(5,2) | NO | — | — | — | CK_POL_NOTA_APROBACION | Nota mínima de aprobación (inclusive). Comparación literal, sin redondeo: 60.99 reprueba con 61.00. |
| POL_VIGENTE_DESDE | DATE | NO | — | — | UQ_POL_VIGENTE_DESDE | — | Inicio de vigencia. Única: no puede haber dos políticas que inicien el mismo día. |
| POL_CREADO_EN | TIMESTAMPTZ | NO | now() | — | — | — | Fecha y hora de creación del registro (auditoría). |
| POL_ACTUALIZADO_EN | TIMESTAMPTZ | NO | now() | — | — | — | Fecha y hora de la última modificación; la sella T1. |

### SIS_ACA_ANIO_LECTIVO

Año lectivo (calendario real). Ej.: 2026.

| COLUMNA | TIPO | NULL | DEFAULT | PK/FK | UNIQUE | CHECK | DESCRIPCIÓN |
|---|---|---|---|---|---|---|---|
| ANL_ID | INTEGER | NO | IDENTITY | PK | — | — | Identificador interno (PK, IDENTITY). |
| ANL_ANIO | SMALLINT | NO | — | — | UQ_ANL_ANIO | CK_ANL_ANIO_POSITIVO | Año calendario del ciclo lectivo. Único. |
| ANL_NOMBRE | VARCHAR(100) | NO | — | — | — | CK_ANL_NOMBRE_NO_VACIO | Nombre descriptivo. |
| ANL_FECHA_INICIO | DATE | NO | — | — | — | CK_ANL_FECHAS | Fecha de inicio. |
| ANL_FECHA_FIN | DATE | NO | — | — | — | CK_ANL_FECHAS | Fecha de finalización. |
| ANL_ESTADO | VARCHAR(20) | NO | 'PLANIFICADO' | — | — | CK_ANL_ESTADO | PLANIFICADO \| ABIERTO \| CERRADO. |
| ANL_CREADO_EN | TIMESTAMPTZ | NO | now() | — | — | — | Fecha y hora de creación del registro (auditoría). |
| ANL_ACTUALIZADO_EN | TIMESTAMPTZ | NO | now() | — | — | — | Fecha y hora de la última modificación; la sella T1. |

### SIS_ACA_PERIODO_ACADEMICO

Período real dentro de un año lectivo (Semestre I / II). Responde: ¿cuándo se cursó?

| COLUMNA | TIPO | NULL | DEFAULT | PK/FK | UNIQUE | CHECK | DESCRIPCIÓN |
|---|---|---|---|---|---|---|---|
| PER_ID | INTEGER | NO | IDENTITY | PK | — | — | Identificador interno (PK, IDENTITY). |
| PER_ANL_ID | INTEGER | NO | — | FK → SIS_ACA_ANIO_LECTIVO.ANL_ID | UQ_PER_ANL_NUMERO (compuesta) | — | Referencia a SIS_ACA_ANIO_LECTIVO. |
| PER_NUMERO | SMALLINT | NO | — | — | UQ_PER_ANL_NUMERO (compuesta) | CK_PER_NUMERO_POSITIVO | Número del período dentro del año (1 = Semestre I, 2 = Semestre II). |
| PER_NOMBRE | VARCHAR(100) | NO | — | — | — | CK_PER_NOMBRE_NO_VACIO | Nombre descriptivo. |
| PER_FECHA_INICIO | DATE | NO | — | — | — | CK_PER_FECHAS | Fecha de inicio. |
| PER_FECHA_FIN | DATE | NO | — | — | — | CK_PER_FECHAS | Fecha de finalización. |
| PER_POL_ID | INTEGER | NO | — | FK → SIS_ACA_POLITICA_ACADEMICA.POL_ID | — | — | Política que evalúa los resultados del período. Debe ser la vigente en PER_FECHA_INICIO (T3). Si se omite, T3 la asigna. |
| PER_ESTADO | VARCHAR(20) | NO | 'PLANIFICADO' | — | — | CK_PER_ESTADO | PLANIFICADO \| ABIERTO \| CERRADO. Solo ABIERTO admite INSERT/UPDATE/DELETE de resultados (T2, SA204 PERIODO_NO_ABIERTO). |
| PER_CREADO_EN | TIMESTAMPTZ | NO | now() | — | — | — | Fecha y hora de creación del registro (auditoría). |
| PER_ACTUALIZADO_EN | TIMESTAMPTZ | NO | now() | — | — | — | Fecha y hora de la última modificación; la sella T1. |

### SIS_ACA_CARRERA

Catálogo de carreras de bachillerato.

| COLUMNA | TIPO | NULL | DEFAULT | PK/FK | UNIQUE | CHECK | DESCRIPCIÓN |
|---|---|---|---|---|---|---|---|
| CAR_ID | INTEGER | NO | IDENTITY | PK | — | — | Identificador interno (PK, IDENTITY). |
| CAR_CODIGO | VARCHAR(30) | NO | — | — | UQ_CAR_CODIGO | CK_CAR_CODIGO_NO_VACIO | Código único legible. |
| CAR_NOMBRE | VARCHAR(150) | NO | — | — | UQ_CAR_NOMBRE | CK_CAR_NOMBRE_NO_VACIO | Nombre descriptivo. |
| CAR_DESCRIPCION | TEXT | SÍ | — | — | — | — | Descripción libre. |
| CAR_ACTIVO | BOOLEAN | NO | true | — | — | — | Desactivación lógica: una carrera con historial no se elimina, se desactiva. |
| CAR_CREADO_EN | TIMESTAMPTZ | NO | now() | — | — | — | Fecha y hora de creación del registro (auditoría). |
| CAR_ACTUALIZADO_EN | TIMESTAMPTZ | NO | now() | — | — | — | Fecha y hora de la última modificación; la sella T1. |

### SIS_ACA_PENSUM

Pensum versionado de una carrera. El estudiante conserva el pensum con que inició.

| COLUMNA | TIPO | NULL | DEFAULT | PK/FK | UNIQUE | CHECK | DESCRIPCIÓN |
|---|---|---|---|---|---|---|---|
| PEN_ID | INTEGER | NO | IDENTITY | PK | — | — | Identificador interno (PK, IDENTITY). |
| PEN_CAR_ID | INTEGER | NO | — | FK → SIS_ACA_CARRERA.CAR_ID | UQ_PEN_CAR_VERSION (compuesta) | — | Referencia a SIS_ACA_CARRERA. |
| PEN_CODIGO | VARCHAR(30) | NO | — | — | UQ_PEN_CODIGO | CK_PEN_CODIGO_NO_VACIO | Código único legible. |
| PEN_NOMBRE | VARCHAR(150) | NO | — | — | — | CK_PEN_NOMBRE_NO_VACIO | Nombre descriptivo. |
| PEN_VERSION | SMALLINT | NO | — | — | UQ_PEN_CAR_VERSION (compuesta) | CK_PEN_VERSION_POSITIVA | Versión correlativa dentro de la carrera (1, 2, ...). |
| PEN_VIGENTE_DESDE | DATE | NO | — | — | — | CK_PEN_VIGENCIA | Inicio de vigencia. |
| PEN_VIGENTE_HASTA | DATE | SÍ | — | — | — | CK_PEN_VIGENCIA | Último día en que se admiten nuevos estudiantes con este pensum. NULL = abierto. Pueden coexistir pensums de la misma carrera en transición. |
| PEN_ACTIVO | BOOLEAN | NO | true | — | — | — | Desactivación lógica (FALSE = no se ofrece en formularios; conserva historial). |
| PEN_CREADO_EN | TIMESTAMPTZ | NO | now() | — | — | — | Fecha y hora de creación del registro (auditoría). |
| PEN_ACTUALIZADO_EN | TIMESTAMPTZ | NO | now() | — | — | — | Fecha y hora de la última modificación; la sella T1. |

### SIS_ACA_CICLO_CURRICULAR

Posición curricular global (Año 1 / Semestre I ...). Responde: ¿dónde pertenece la materia en el pensum? El orden se obtiene con (CIC_ANIO, CIC_SEMESTRE).

| COLUMNA | TIPO | NULL | DEFAULT | PK/FK | UNIQUE | CHECK | DESCRIPCIÓN |
|---|---|---|---|---|---|---|---|
| CIC_ID | INTEGER | NO | IDENTITY | PK | — | — | Identificador interno (PK, IDENTITY). |
| CIC_ANIO | SMALLINT | NO | — | — | UQ_CIC_ANIO_SEMESTRE (compuesta) | CK_CIC_ANIO_POSITIVO | Año curricular (1, 2, ...). No es un año calendario. |
| CIC_SEMESTRE | SMALLINT | NO | — | — | UQ_CIC_ANIO_SEMESTRE (compuesta) | CK_CIC_SEMESTRE_POSITIVO | Semestre dentro del año curricular (1, 2). |
| CIC_NOMBRE | VARCHAR(100) | NO | — | — | UQ_CIC_NOMBRE | CK_CIC_NOMBRE_NO_VACIO | Nombre descriptivo. |
| CIC_ACTIVO | BOOLEAN | NO | true | — | — | — | Desactivación lógica (FALSE = no se ofrece en formularios; conserva historial). |

### SIS_ACA_CURSO

Catálogo maestro de cursos. Se vincula a pensums mediante SIS_ACA_PENSUM_CURSO.

| COLUMNA | TIPO | NULL | DEFAULT | PK/FK | UNIQUE | CHECK | DESCRIPCIÓN |
|---|---|---|---|---|---|---|---|
| CUR_ID | INTEGER | NO | IDENTITY | PK | — | — | Identificador interno (PK, IDENTITY). |
| CUR_CODIGO | VARCHAR(30) | NO | — | — | UQ_CUR_CODIGO | CK_CUR_CODIGO_NO_VACIO | Código único legible. |
| CUR_NOMBRE | VARCHAR(150) | NO | — | — | — | CK_CUR_NOMBRE_NO_VACIO | Nombre descriptivo. |
| CUR_DESCRIPCION | TEXT | SÍ | — | — | — | — | Descripción libre. |
| CUR_ACTIVO | BOOLEAN | NO | true | — | — | — | Desactivación lógica (FALSE = no se ofrece en formularios; conserva historial). |
| CUR_CREADO_EN | TIMESTAMPTZ | NO | now() | — | — | — | Fecha y hora de creación del registro (auditoría). |
| CUR_ACTUALIZADO_EN | TIMESTAMPTZ | NO | now() | — | — | — | Fecha y hora de la última modificación; la sella T1. |

### SIS_ACA_PENSUM_CURSO

Asignación PENSUM + CURSO + CICLO. Un curso aparece una sola vez por pensum.

| COLUMNA | TIPO | NULL | DEFAULT | PK/FK | UNIQUE | CHECK | DESCRIPCIÓN |
|---|---|---|---|---|---|---|---|
| PCU_ID | INTEGER | NO | IDENTITY | PK | — | — | Identificador interno (PK, IDENTITY). |
| PCU_PEN_ID | INTEGER | NO | — | FK → SIS_ACA_PENSUM.PEN_ID | UQ_PCU_PEN_CUR (compuesta)<br>UQ_PCU_PEN_CIC_ORDEN (compuesta) | — | Referencia a SIS_ACA_PENSUM. |
| PCU_CUR_ID | INTEGER | NO | — | FK → SIS_ACA_CURSO.CUR_ID | UQ_PCU_PEN_CUR (compuesta) | — | Referencia a SIS_ACA_CURSO. |
| PCU_CIC_ID | INTEGER | NO | — | FK → SIS_ACA_CICLO_CURRICULAR.CIC_ID | UQ_PCU_PEN_CIC_ORDEN (compuesta) | — | Referencia a SIS_ACA_CICLO_CURRICULAR. |
| PCU_OBLIGATORIO | BOOLEAN | NO | true | — | — | — | CONTRATO PARA SYMFONY. TRUE = obligatorio: cuenta para el avance (AVA_*), el estado del ciclo y el pensum completo. FALSE = optativo: se ofrece, se califica y aparece en historial y reportes, pero no suma ni resta al porcentaje. La interfaz debe distinguirlos con esta columna (no con el nombre del curso). |
| PCU_ORDEN | SMALLINT | NO | — | — | UQ_PCU_PEN_CIC_ORDEN (compuesta) | CK_PCU_ORDEN_POSITIVO | Orden de presentación dentro del ciclo. |
| PCU_CREADO_EN | TIMESTAMPTZ | NO | now() | — | — | — | Fecha y hora de creación del registro (auditoría). |
| PCU_ACTUALIZADO_EN | TIMESTAMPTZ | NO | now() | — | — | — | Fecha y hora de la última modificación; la sella T1. |

### SIS_ACA_SECCION

Catálogo de secciones (A, B, C). El contexto lo dan SIS_ACA_ESTUDIANTE_PERIODO y SIS_ACA_OFERTA_CURSO.

| COLUMNA | TIPO | NULL | DEFAULT | PK/FK | UNIQUE | CHECK | DESCRIPCIÓN |
|---|---|---|---|---|---|---|---|
| SEC_ID | INTEGER | NO | IDENTITY | PK | — | — | Identificador interno (PK, IDENTITY). |
| SEC_CODIGO | VARCHAR(10) | NO | — | — | UQ_SEC_CODIGO | CK_SEC_CODIGO_NO_VACIO | Código único legible. |
| SEC_NOMBRE | VARCHAR(50) | NO | — | — | — | CK_SEC_NOMBRE_NO_VACIO | Nombre descriptivo. |
| SEC_ACTIVO | BOOLEAN | NO | true | — | — | — | Desactivación lógica (FALSE = no se ofrece en formularios; conserva historial). |

### SIS_ACA_ESTUDIANTE

Datos personales mínimos del estudiante. Sin contraseñas, datos médicos ni documentos sensibles.

| COLUMNA | TIPO | NULL | DEFAULT | PK/FK | UNIQUE | CHECK | DESCRIPCIÓN |
|---|---|---|---|---|---|---|---|
| EST_ID | INTEGER | NO | IDENTITY | PK | — | — | Identificador interno (PK, IDENTITY). |
| EST_CODIGO | VARCHAR(20) | NO | — | — | UQ_EST_CODIGO | CK_EST_CODIGO_NO_VACIO | Código único del estudiante (formato sugerido STU-AAAA-NNNN; no se impone con regex). |
| EST_NOMBRES | VARCHAR(100) | NO | — | — | — | CK_EST_NOMBRES_NO_VACIO | Nombres del estudiante (campo separado de apellidos, según enunciado). |
| EST_APELLIDOS | VARCHAR(100) | NO | — | — | — | CK_EST_APELLIDOS_NO_VACIO | Apellidos del estudiante. |
| EST_FECHA_NACIMIENTO | DATE | NO | — | — | — | — | Obligatoria. La validación de rango de edad se realiza en Symfony. |
| EST_FOTO_RUTA | VARCHAR(255) | SÍ | — | — | UQ_EST_FOTO_RUTA | CK_EST_FOTO_NO_VACIA | Ruta relativa de la fotografía (ej. students/2026/STU-2026-0001.jpg). La imagen vive en el filesystem, nunca en la BD. |
| EST_ACTIVO | BOOLEAN | NO | true | — | — | — | Desactivación lógica (FALSE = no se ofrece en formularios; conserva historial). |
| EST_CREADO_EN | TIMESTAMPTZ | NO | now() | — | — | — | Fecha y hora de creación del registro (auditoría). |
| EST_ACTUALIZADO_EN | TIMESTAMPTZ | NO | now() | — | — | — | Fecha y hora de la última modificación; la sella T1. |

### SIS_ACA_ESTUDIANTE_PROGRAMA

Inscripción del estudiante en un pensum. La carrera se deriva de PEN_CAR_ID (decisión H1: sin columna de carrera redundante).

| COLUMNA | TIPO | NULL | DEFAULT | PK/FK | UNIQUE | CHECK | DESCRIPCIÓN |
|---|---|---|---|---|---|---|---|
| EPR_ID | INTEGER | NO | IDENTITY | PK | — | — | Identificador interno (PK, IDENTITY). |
| EPR_EST_ID | INTEGER | NO | — | FK → SIS_ACA_ESTUDIANTE.EST_ID | UQ_EPR_EST_PEN_INICIO (compuesta)<br>UX_EPR_EST_ACTIVO (parcial: EPR_ESTADO = 'ACTIVO') | — | Referencia a SIS_ACA_ESTUDIANTE. |
| EPR_PEN_ID | INTEGER | NO | — | FK → SIS_ACA_PENSUM.PEN_ID | UQ_EPR_EST_PEN_INICIO (compuesta) | — | Pensum con el que el estudiante inició. No migra automáticamente. Congelado si existen resultados (T4). |
| EPR_FECHA_INICIO | DATE | NO | — | — | UQ_EPR_EST_PEN_INICIO (compuesta) | CK_EPR_FECHAS | Fecha de inicio. |
| EPR_FECHA_FIN | DATE | SÍ | — | — | — | CK_EPR_FECHAS<br>CK_EPR_ESTADO_FECHA_FIN | Fecha de finalización. |
| EPR_ESTADO | VARCHAR(20) | NO | 'ACTIVO' | — | — | CK_EPR_ESTADO<br>CK_EPR_ESTADO_FECHA_FIN | ACTIVO \| FINALIZADO \| RETIRADO. Solo un programa ACTIVO por estudiante. |
| EPR_CREADO_EN | TIMESTAMPTZ | NO | now() | — | — | — | Fecha y hora de creación del registro (auditoría). |
| EPR_ACTUALIZADO_EN | TIMESTAMPTZ | NO | now() | — | — | — | Fecha y hora de la última modificación; la sella T1. |

### SIS_ACA_ESTUDIANTE_PERIODO

Ubicación del estudiante en un período: ciclo curricular y sección. Un registro por programa y período.

| COLUMNA | TIPO | NULL | DEFAULT | PK/FK | UNIQUE | CHECK | DESCRIPCIÓN |
|---|---|---|---|---|---|---|---|
| EPE_ID | INTEGER | NO | IDENTITY | PK | — | — | Identificador interno (PK, IDENTITY). |
| EPE_EPR_ID | INTEGER | NO | — | FK → SIS_ACA_ESTUDIANTE_PROGRAMA.EPR_ID | UQ_EPE_EPR_PER (compuesta) | — | Referencia a SIS_ACA_ESTUDIANTE_PROGRAMA. |
| EPE_PER_ID | INTEGER | NO | — | FK → SIS_ACA_PERIODO_ACADEMICO.PER_ID | UQ_EPE_EPR_PER (compuesta) | — | Referencia a SIS_ACA_PERIODO_ACADEMICO. |
| EPE_CIC_ID | INTEGER | NO | — | FK → SIS_ACA_CICLO_CURRICULAR.CIC_ID | — | — | Ciclo curricular que cursa el estudiante en el período (puede diferir del ciclo de un curso repetido). |
| EPE_SEC_ID | INTEGER | NO | — | FK → SIS_ACA_SECCION.SEC_ID | — | — | Sección del estudiante. Regla S1: debe coincidir con la sección de la oferta en que se registra la nota (T2). |
| EPE_ESTADO | VARCHAR(20) | NO | 'INSCRITO' | — | — | CK_EPE_ESTADO | INSCRITO \| FINALIZADO \| RETIRADO. Solo INSCRITO permite INSERT/UPDATE/DELETE de resultados (T2, SA205). |
| EPE_CREADO_EN | TIMESTAMPTZ | NO | now() | — | — | — | Fecha y hora de creación del registro (auditoría). |
| EPE_ACTUALIZADO_EN | TIMESTAMPTZ | NO | now() | — | — | — | Fecha y hora de la última modificación; la sella T1. |

### SIS_ACA_OFERTA_CURSO

Curso de un pensum impartido en un período y sección concretos.

| COLUMNA | TIPO | NULL | DEFAULT | PK/FK | UNIQUE | CHECK | DESCRIPCIÓN |
|---|---|---|---|---|---|---|---|
| OFE_ID | INTEGER | NO | IDENTITY | PK | — | — | Identificador interno (PK, IDENTITY). |
| OFE_PER_ID | INTEGER | NO | — | FK → SIS_ACA_PERIODO_ACADEMICO.PER_ID | UQ_OFE_PER_PCU_SEC (compuesta) | — | Referencia a SIS_ACA_PERIODO_ACADEMICO. |
| OFE_PCU_ID | INTEGER | NO | — | FK → SIS_ACA_PENSUM_CURSO.PCU_ID | UQ_OFE_PER_PCU_SEC (compuesta) | — | Referencia a SIS_ACA_PENSUM_CURSO. |
| OFE_SEC_ID | INTEGER | NO | — | FK → SIS_ACA_SECCION.SEC_ID | UQ_OFE_PER_PCU_SEC (compuesta) | — | Referencia a SIS_ACA_SECCION. |
| OFE_ACTIVO | BOOLEAN | NO | true | — | — | — | FALSE = oferta inactiva: no admite INSERT/UPDATE/DELETE de resultados (T2, SA206) ni se sugiere en ingreso de notas. |
| OFE_CREADO_EN | TIMESTAMPTZ | NO | now() | — | — | — | Fecha y hora de creación del registro (auditoría). |
| OFE_ACTUALIZADO_EN | TIMESTAMPTZ | NO | now() | — | — | — | Fecha y hora de la última modificación; la sella T1. |

### SIS_ACA_RESULTADO_CURSO

Una fila = un intento del estudiante en una oferta. El estado (PENDIENTE/APROBADO/REPROBADO) NO se almacena: se deriva con la política del período. RES_EPE_ID y RES_OFE_ID son inmutables (T4); no se admite un nuevo intento de un curso ya aprobado (T2, SA207).

| COLUMNA | TIPO | NULL | DEFAULT | PK/FK | UNIQUE | CHECK | DESCRIPCIÓN |
|---|---|---|---|---|---|---|---|
| RES_ID | INTEGER | NO | IDENTITY | PK | — | — | Identificador interno (PK, IDENTITY). |
| RES_EPE_ID | INTEGER | NO | — | FK → SIS_ACA_ESTUDIANTE_PERIODO.EPE_ID | UQ_RES_EPE_OFE (compuesta) | — | Referencia a SIS_ACA_ESTUDIANTE_PERIODO. |
| RES_OFE_ID | INTEGER | NO | — | FK → SIS_ACA_OFERTA_CURSO.OFE_ID | UQ_RES_EPE_OFE (compuesta) | — | Referencia a SIS_ACA_OFERTA_CURSO. |
| RES_NOTA | NUMERIC(5,2) | SÍ | — | — | — | CK_RES_NOTA_RANGO<br>CK_RES_NOTA_FECHA | NULL = pendiente. Si existe: 0 <= nota <= 100, NUMERIC(5,2) sin redondeo. |
| RES_CALIFICADO_EN | TIMESTAMPTZ | SÍ | — | — | — | CK_RES_NOTA_FECHA | Momento de la calificación. Obligatorio si y solo si hay nota. |
| RES_CREADO_EN | TIMESTAMPTZ | NO | now() | — | — | — | Fecha y hora de creación del registro (auditoría). |
| RES_ACTUALIZADO_EN | TIMESTAMPTZ | NO | now() | — | — | — | Fecha y hora de la última modificación; la sella T1. |
## 3. Vistas

| Vista | Grano (clave) | Propósito | Sección del contrato |
|---|---|---|---|
| SIS_ACA_VW_POLITICA_LINEA_TIEMPO | POL_ID | Políticas con `POL_VIGENTE_HASTA` derivado (LEAD − 1 día) | 22.1 / H2 |
| SIS_ACA_VW_POLITICA_VIGENTE | 0–1 fila | Política vigente a `CURRENT_DATE` | 22.1 |
| SIS_ACA_VW_RESULTADO_ESTUDIANTE | RES_ID | Un intento por fila con estado derivado y número de intento | 22.2 |
| SIS_ACA_VW_INTENTO_CURSO | (EPR_ID, PCU_ID) | Intentos, primera/última/mejor nota y período de aprobación | 16 |
| SIS_ACA_VW_AVANCE_CICLO | (EPR_ID, CIC_ID) | Obligatorios, aprobados, pendientes, % y estado del ciclo | 22.4 |
| SIS_ACA_VW_AVANCE_PENSUM | EPR_ID | Avance global del pensum | 22.3 |
| SIS_ACA_VW_REPORTE_NOTAS | RES_ID | Base de reportes por carrera, curso, sección o período | 22.5 |
| SIS_ACA_VW_INGRESO_NOTAS | (EPE_ID, PCU_ID) | Cursos para capturar notas: ciclo actual, repitencias registradas y cursos de ciclos anteriores pendientes con oferta activa. Expone `EPE_ESTADO`, `OFE_ACTIVO`, `ING_EDITABLE` e `ING_MOTIVO_BLOQUEO` (PERIODO_NO_ABIERTO, ESTUDIANTE_NO_INSCRITO, SIN_OFERTA, OFERTA_INACTIVA, YA_APROBADO) | 22.6 |

## 4. Relaciones y mapeo futuro a Doctrine

| Entidad (lado N) | Asociación | Entidad (lado 1) | Columna FK | Lado inverso sugerido (opcional) |
|---|---|---|---|---|
| PeriodoAcademico | ManyToOne | AnioLectivo | PER_ANL_ID | AnioLectivo OneToMany periodos |
| PeriodoAcademico | ManyToOne | PoliticaAcademica | PER_POL_ID | — |
| Pensum | ManyToOne | Carrera | PEN_CAR_ID | Carrera OneToMany pensums |
| PensumCurso | ManyToOne | Pensum | PCU_PEN_ID | Pensum OneToMany cursos |
| PensumCurso | ManyToOne | Curso | PCU_CUR_ID | — |
| PensumCurso | ManyToOne | CicloCurricular | PCU_CIC_ID | — |
| EstudiantePrograma | ManyToOne | Estudiante | EPR_EST_ID | Estudiante OneToMany programas |
| EstudiantePrograma | ManyToOne | Pensum | EPR_PEN_ID | — |
| EstudiantePeriodo | ManyToOne | EstudiantePrograma | EPE_EPR_ID | EstudiantePrograma OneToMany periodos |
| EstudiantePeriodo | ManyToOne | PeriodoAcademico | EPE_PER_ID | — |
| EstudiantePeriodo | ManyToOne | CicloCurricular | EPE_CIC_ID | — |
| EstudiantePeriodo | ManyToOne | Seccion | EPE_SEC_ID | — |
| OfertaCurso | ManyToOne | PeriodoAcademico | OFE_PER_ID | — |
| OfertaCurso | ManyToOne | PensumCurso | OFE_PCU_ID | — |
| OfertaCurso | ManyToOne | Seccion | OFE_SEC_ID | — |
| ResultadoCurso | ManyToOne | EstudiantePeriodo | RES_EPE_ID | EstudiantePeriodo OneToMany resultados |
| ResultadoCurso | ManyToOne | OfertaCurso | RES_OFE_ID | — |

- No hay **ManyToMany** puras: toda relación N:M tiene atributos propios (`PCU_OBLIGATORIO`, `EPR_ESTADO`, `RES_NOTA`), así que se modela como entidad intermedia.
- No hay **OneToOne**.
- La carrera del estudiante se navega como `EstudiantePrograma → Pensum → Carrera` (decisión H1).
- Mapeo de columnas: `#[ORM\Column(name: 'est_nombres')]`. Como los nombres van sin comillas, Doctrine no necesita escapar nada.
- `*_ACTUALIZADO_EN` lo escribe T1. En Doctrine se mapea con `insertable: false, updatable: false` (o se deja que Doctrine lo envíe: T1 lo sobrescribe igual).
- Las vistas se pueden mapear como entidades `#[ORM\Entity(readOnly: true)]` usando la clave del grano indicado en §3, o consultarse por DBAL.
