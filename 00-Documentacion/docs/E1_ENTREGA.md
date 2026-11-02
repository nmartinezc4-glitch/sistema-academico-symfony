# E1: Estructura de la base de datos (Fases 2, 3 y 4) — Revisión 3 (final)

**Sistema Académico Symfony · capa PostgreSQL**

| | |
|---|---|
| **STATUS** | **APPROVED.** El parche final pasa el smoke test (criterio de cierre fijado en el gate) |
| Revisión | R3: atiende "GATE E1 — FINAL PATCH REQUIRED" (D6, D7, identidad de RESULTADO_CURSO) |
| Motor probado | PostgreSQL 16.15 (sintaxis estándar, sin extensiones) |
| Verificación | `E1_smoke_test.sql`: **109/109 PASS** (R1: 50 · R2: 86). `run_all.sql` se puede re-ejecutar. La guarda de `00_reset.sql` devuelve **SA001** fuera de `sistema_academico_dev`. |
| NEXT | E2 (dataset realista + 25 consultas) en curso. |

---

## 0a. Cambios de R3 respecto a R2

| Punto del dictamen | Cambio | Verificación (sección del smoke test) |
|---|---|---|
| **D6** | T2 rechaza con **SA207** un INSERT cuando el mismo `EPR_ID + PCU_ID` ya tiene un resultado aprobado (con la política histórica de su período) en un período **anterior**. Los intentos reprobados previos no se tocan. | §10d: 60.99 → 61.00 válido; 55 → 61 válido; 61.00 → nuevo intento = SA207 (dos casos) |
| **D7** | SA204 pasa a significar `PERIODO_NO_ABIERTO`: PLANIFICADO y CERRADO bloquean INSERT/UPDATE/DELETE; solo ABIERTO admite cambios. La vista usa `PERIODO_NO_ABIERTO` cuando `PER_ESTADO <> 'ABIERTO'`. | §10 (CERRADO), §10b (PLANIFICADO I/U/D y vuelta a ABIERTO) |
| **Identidad de RESULTADO_CURSO** | T4 (misma función) hace inmutables `RES_EPE_ID` y `RES_OFE_ID` siempre. `RES_NOTA` y `RES_CALIFICADO_EN` siguen editables mientras T2 lo permita. La corrección de contexto se hace con DELETE + INSERT. Se mantiene SA401. | §10c: cambio de `RES_EPE_ID` y de `RES_OFE_ID` = SA401; reescritura con el mismo valor permitida; edición de nota permitida; corrección DELETE + INSERT |
| Orden de triggers en RESULTADO_CURSO | Se renombraron para fijar el orden: `TRG_RES_01_T4_IDENTIDAD` → `TRG_RES_02_T2_CONTEXTO` → `TRG_RES_T1_ACTUALIZACION`. Así un cambio de identidad responde siempre SA401, aunque el destino también viole T2. | §10c usa destinos válidos para T2, de modo que el SA401 demuestra que T4 corre primero |

Conteo final: 4 funciones de trigger · **24 triggers** · 109 verificaciones.

**Nota sobre D6 (alcance):** la regla se evalúa al **crear** un intento. Si se edita la nota de un intento antiguo hasta aprobarlo cuando ya existe un intento posterior, la base lo permite: no es un nuevo intento. El avance no se ve afectado (el curso cuenta una vez). Se agregará una consulta de diagnóstico "intento posterior a una aprobación" en 10_validation (E3).

## 0. Cambios de R2 respecto a R1

| Punto del dictamen | Cambio | Archivo | Verificación (sección del smoke test) |
|---|---|---|---|
| E1-H1 aprobado | Se mantiene `SIS_ACA_PENSUM_CURSO` bajo T4 | 04 | §11 |
| E1-H4 aprobado | Se mantiene el prefijo `ANL` | — | — |
| E1-H6 aprobado | Se mantiene la autoasignación de política; una política explícita incorrecta sigue rechazándose (SA302) | 04 | §3, §13 |
| D1 | T2: solo `EPE_ESTADO = 'INSCRITO'` permite INSERT/UPDATE/DELETE de resultados → **SA205** | 04 | §8 (RETIRADO y FINALIZADO) |
| D2 | T2: `OFE_ACTIVO` debe ser TRUE para INSERT/UPDATE/DELETE → **SA206** | 04 | §9 |
| T4 extendido (misma función) | Congela `PEN_CAR_ID`; `PER_ANL_ID`, `PER_NUMERO`, `PER_FECHA_INICIO`, `PER_FECHA_FIN`; `ANL_ANIO`; `CIC_ANIO`, `CIC_SEMESTRE` | 04 | §11, §12 |
| Vista de ingreso de notas | Descubre cursos de ciclos anteriores no aprobados con oferta activa **antes** de crear el intento; agrega `EPE_ESTADO`, `OFE_ACTIVO`, `ING_EDITABLE`, `ING_MOTIVO_BLOQUEO` | 05 | §6, §10 |
| Reset | `SA000` → `SA001` | 00 | Prueba manual en otra base |
| Smoke test | De 50 a 86 verificaciones, con contador final | E1_smoke_test | — |

Conteo de objetos tras R2: 14 tablas · 20 UNIQUE + 1 único parcial · 35 CHECK · 17 FK (todas RESTRICT) · 7 índices · 1 función auxiliar + **4 funciones de trigger** · 23 triggers (R1: 19; R3: 24) · 8 vistas.

---

## 1. Archivos entregados

| Archivo | Contenido |
|---|---|
| `database/00_reset.sql` | **SOLO DESARROLLO / DESTRUCTIVO.** Aborta con SA001 si la base no es `sistema_academico_dev`. |
| `database/01_schema.sql` | 14 tablas: columnas, tipos, NOT NULL, DEFAULT, PK, COMMENT. |
| `database/02_constraints.sql` | UNIQUE, CHECK y FK con nombre. |
| `database/03_indexes.sql` | 7 índices de soporte justificados. |
| `database/04_functions_triggers.sql` | `SIS_ACA_FN_POLITICA_VIGENTE` + T1–T4. |
| `database/05_views.sql` | 8 vistas. |
| `database/run_all.sql` | Orquestador psql. |
| `database/E1_smoke_test.sql` | 109 verificaciones; mini-dataset descartado con ROLLBACK. |
| `docs/data_dictionary.md` | Diccionario generado desde el catálogo, convención de nombres y mapeo Doctrine. |
| `docs/er_model.md` | ER conceptual y lógico (Mermaid). |

```bash
createdb sistema_academico_dev
cd database
psql -d sistema_academico_dev -v solo_estructura=1 -f run_all.sql   # estructura sin datos (desde E2)
psql -d sistema_academico_dev -f E1_smoke_test.sql     # termina con "TOTAL: 109 verificaciones PASS"
```

---

## 2. Decisiones aprobadas y su implementación

| Decisión | Implementación |
|---|---|
| **H1** sin carrera en el programa | La carrera se obtiene por `EPR_PEN_ID → PEN_CAR_ID`. R2: además, `PEN_CAR_ID` queda congelado si hay estudiantes con ese pensum. Sin esto, mover el pensum de carrera cambiaría la carrera de todos sus estudiantes. |
| **H2** vigencia derivada | `POL_VIGENTE_DESDE` es UNIQUE. `SIS_ACA_VW_POLITICA_LINEA_TIEMPO` calcula `POL_VIGENTE_HASTA`. |
| **H2 condición** | T3: el período usa la política vigente en `PER_FECHA_INICIO` (SA301/SA302). Una política usada no cambia ni su nota ni su vigencia (SA303). No se admiten reformas retroactivas (SA304). |
| **H3** congelar solo contexto | T4 con `BEFORE UPDATE OF <columnas>` en 8 tablas (§4). |
| **E1-H6** autoasignación | Si `PER_POL_ID` llega NULL, T3 asigna la vigente. Si llega explícita y no es la vigente, T3 la rechaza (SA302). |
| **S1** sección estricta | T2 (SA203). |
| **S2** NUMERIC(5,2) sin redondeo | 60.99 → REPROBADO; 61.00 → APROBADO. |
| **S3 + D7** solo ABIERTO admite I/U/D | T2 (SA204 `PERIODO_NO_ABIERTO`). |
| **D1** solo INSCRITO | T2 (SA205) sobre la fila original y la nueva. |
| **D2** oferta activa | T2 (SA206) sobre la fila original y la nueva. |
| **D6** sin nuevo intento tras aprobar | T2 (SA207), solo en INSERT. |
| Identidad del resultado | T4 (SA401): `RES_EPE_ID`, `RES_OFE_ID` inmutables. |
| Reglas 1–3 | Sin regex; fecha de nacimiento solo NOT NULL; estrategia de Doctrine en §6. |

---

## 3. T2: orden de evaluación

En **UPDATE**, T2 evalúa primero la fila **original** y después la **nueva**. En **DELETE** evalúa solo la original; en **INSERT**, solo la nueva. Así no se puede "sacar" un resultado de un contexto bloqueado moviéndolo a otro abierto, ni al revés.

| Orden | Regla | Aplica a | SQLSTATE |
|---|---|---|---|
| 0 | (T4, trigger previo) identidad `RES_EPE_ID`/`RES_OFE_ID` sin cambios | UPDATE | SA401 |
| 1 | Período ABIERTO (`PERIODO_NO_ABIERTO`) | original y nueva | SA204 |
| 2 | `EPE_ESTADO = 'INSCRITO'` | original y nueva | SA205 |
| 3 | `OFE_ACTIVO = TRUE` | original y nueva | SA206 |
| 4 | Mismo período (EPE vs OFE) | nueva | SA201 |
| 5 | Mismo pensum (EPR vs PCU) | nueva | SA202 |
| 6 | Misma sección (S1) | nueva | SA203 |
| 7 | Sin aprobación previa del curso en un período anterior | nueva, solo INSERT | SA207 |
| 8 | (E3 · DF1) No aprobar retroactivamente un intento con intentos posteriores | nueva, solo UPDATE | SA208 |

**Consecuencia operativa (seeds de E2 y Symfony):** los períodos nacen PLANIFICADO (DEFAULT). Hay que abrirlos antes de registrar notas, con el estudiante INSCRITO y la oferta activa. Al terminar, se marca el estudiante como FINALIZADO y el período como CERRADO. Para corregir después hay que revertir esos estados de forma explícita.

---

## 4. T4: columnas congeladas (una sola función, 9 tablas)

| Tabla | Columnas congeladas | Se congela cuando… |
|---|---|---|
| ESTUDIANTE_PROGRAMA | EPR_PEN_ID | el programa tiene resultados |
| ESTUDIANTE_PERIODO | EPE_EPR_ID, EPE_PER_ID, EPE_CIC_ID, EPE_SEC_ID | el estudiante-período tiene resultados |
| OFERTA_CURSO | OFE_PER_ID, OFE_PCU_ID, OFE_SEC_ID | la oferta tiene resultados |
| PENSUM_CURSO | PCU_PEN_ID, PCU_CUR_ID, PCU_CIC_ID | alguna de sus ofertas tiene resultados (E1-H1) |
| PENSUM | PEN_CAR_ID | existe un ESTUDIANTE_PROGRAMA con ese pensum |
| PERIODO_ACADEMICO | PER_ANL_ID, PER_NUMERO, PER_FECHA_INICIO, PER_FECHA_FIN | el período tiene resultados (`PER_POL_ID` sigue en T3) |
| ANIO_LECTIVO | ANL_ANIO | alguno de sus períodos tiene resultados |
| CICLO_CURRICULAR | CIC_ANIO, CIC_SEMESTRE | lo referencia PENSUM_CURSO o ESTUDIANTE_PERIODO |
| RESULTADO_CURSO (R3) | RES_EPE_ID, RES_OFE_ID | **siempre** (identidad del intento); la nota sigue editable según T2 |

Columnas que siguen editables y están verificadas en el smoke test: nombres (`PEN_NOMBRE`, `PER_NOMBRE`, `CIC_NOMBRE`, `POL_NOMBRE`), estados (`EPE_ESTADO`, `PER_ESTADO`) y `OFE_ACTIVO`.

**Interacción T3/T4 en PERIODO_ACADEMICO:** PostgreSQL ejecuta los BEFORE triggers en orden alfabético: `TRG_PER_T1…` → `TRG_PER_T3_POLITICA` → `TRG_PER_T4_CONTEXTO`. Si se cambia `PER_FECHA_INICIO` sin cambiar de política, T3 lo acepta y T4 lo bloquea si hay resultados (verificado). Si el cambio también implica otra política, T3 responde primero con SA302 o SA305.

---

## 5. `SIS_ACA_VW_INGRESO_NOTAS` rediseñada

**Problema en R1:** un curso reprobado de un ciclo anterior solo aparecía si ya existía un resultado en el período actual. Symfony no podía ofrecer crear el nuevo intento.

**R2:** tres orígenes mutuamente excluyentes. La clave (EPE_ID, PCU_ID) sigue siendo única (verificado).

| Origen (`ING_ORIGEN`) | Qué incluye |
|---|---|
| `CICLO_ACTUAL` | Todos los cursos del pensum del ciclo del estudiante, exista o no oferta o resultado |
| `CICLO_ANTERIOR` (registrado) | Intentos ya registrados en el período para cursos de un ciclo anterior |
| `CICLO_ANTERIOR` (descubierto) | Cursos de ciclos anteriores del **mismo pensum**, **no aprobados** antes del período, con **oferta activa** en el período y sección del estudiante, y sin intento todavía |
| `OTRO_CICLO` | Intentos registrados de un ciclo posterior (adelanto), si existieran |

Columnas nuevas: `EPE_ESTADO`, `OFE_ACTIVO`, `PCU_CIC_NOMBRE`, `ING_EDITABLE`, `ING_MOTIVO_BLOQUEO`.

| `ING_MOTIVO_BLOQUEO` (por prioridad) | Equivale a |
|---|---|
| `PERIODO_NO_ABIERTO` | SA204 (PLANIFICADO o CERRADO) |
| `ESTUDIANTE_NO_INSCRITO` | SA205 |
| `SIN_OFERTA` | no hay oferta en período/sección |
| `OFERTA_INACTIVA` | SA206 |
| `YA_APROBADO` | SA207: curso aprobado en un período previo y sin intento en este |
| NULL | `ING_EDITABLE = TRUE` |

Escenarios verificados: Carla reprobó PRG1 en 2025-I. En 2025-II la vista le muestra PRG1 como `CICLO_ANTERIOR:SIN_REGISTRO` editable. Con ese `OFE_ID` registra el intento y la fila pasa a `PENDIENTE` sin duplicarse. Si la oferta se desactiva, PRG1 deja de sugerirse y el intento ya registrado de Ana muestra `OFERTA_INACTIVA`.

---

## 6. Reproducibilidad con Doctrine Migrations (regla 3)

Sin cambios respecto a R1:

- **Migración base:** el SQL de `database/` es canónico. Una migración base ejecuta 01→05, un archivo por `addSql`. Pendiente verificar con pdo_pgsql al montar Symfony.
- **Configuración:** `schema_filter: '~^(?!sis_aca_vw_)~'`. Nunca `doctrine:schema:update --force`. Para validar el mapeo, `doctrine:schema:validate --skip-sync`.
- **Cambios futuros:** migraciones con SQL explícito, reflejado también en `database/`.
- **Vistas en Doctrine:** `SIS_ACA_VW_INGRESO_NOTAS` se mapea como entidad readOnly con clave compuesta (EPE_ID, PCU_ID). `ING_EDITABLE` se usa para habilitar o deshabilitar cada campo del formulario.

---

## 7. Catálogo de SQLSTATE

| SQLSTATE | Origen | Regla |
|---|---|---|
| SA001 | 00_reset | ejecutado fuera de `sistema_academico_dev` |
| SA101 | T1 | columna de auditoría mal configurada |
| SA201 / SA202 / SA203 | T2 | período / pensum / sección distintos |
| SA204 | T2 | `PERIODO_NO_ABIERTO`: período PLANIFICADO o CERRADO |
| SA205 | T2 | estudiante no INSCRITO en el período |
| SA206 | T2 | oferta inactiva |
| SA207 | T2 | nuevo intento de un curso ya aprobado en un período anterior |
| SA208 | T2 | (E3 · DF1) corrección que convierte en aprobado un intento con intentos posteriores |
| SA301 / SA302 | T3 | sin política vigente / política distinta a la vigente |
| SA303 | T3 | política usada: nota o vigencia protegidas |
| SA304 | T3 | vigencia retroactiva |
| SA305 | T3 | cambio de política en período con resultados |
| SA401 | T4 | contexto congelado o identidad de RESULTADO_CURSO modificada |

---

## 8. Índices

Sin cambios (7 índices; ver R1 y el encabezado de `03_indexes.sql`). Las consultas nuevas de T4 se apoyan en índices existentes:

| Verificación de T4 | Índice que la atiende |
|---|---|
| `PEN_CAR_ID` → ¿EPR con el pensum? | `IX_EPR_PEN` |
| PER / ANL → ¿resultados del período? | `IX_EPE_PER_SEC` + `UQ_RES_EPE_OFE` |
| CIC → ¿PCU o EPE lo usan? | Recorrido secuencial. Es aceptable: cambiar año/semestre de un ciclo es una operación administrativa rara. |

---

## 9. Decisiones abiertas (no bloquean E1)

| # | Tema | Situación | Propuesta |
|---|---|---|---|
| D3 | Fechas del período dentro del año; períodos solapados | Sin control en BD | Diagnóstico en 10_validation (E3) |
| D4 | `EPE_CIC_ID` que el pensum del estudiante no usa | Sin control en BD | Diagnóstico en E3 |
| D5 | Versión de PostgreSQL en Ubuntu 26.04 | Probado en 16.15 | Confirmar con `psql --version` |
| D6 | Nuevo intento sobre curso aprobado | **Resuelto en R3** (SA207) | — |
| D7 | Período PLANIFICADO | **Resuelto en R3** (SA204 `PERIODO_NO_ABIERTO`) | — |

---

## 10. Autoauditoría (estructura)

| Pregunta | Resultado |
|---|---|
| ¿Redundancia o datos derivados almacenados? | PASS |
| ¿Una reforma académica rompe el pasado? | PASS — FK explícita + T3 (§47) |
| ¿Se puede reescribir el historial editando catálogos o contexto? | PASS — T4 sobre 8 tablas (R2) |
| ¿Se puede modificar una nota de un estudiante no inscrito o de una oferta inactiva? | PASS — SA205/SA206 (R2) |
| ¿Una repetición rompe el progreso? / ¿un curso repetido cuenta dos veces? | PASS |
| ¿La pantalla de ingreso ofrece las repitencias pendientes? | PASS — descubrimiento previo al intento (R2) |
| ¿Un NULL puede producir un falso aprobado? | PASS |
| ¿El porcentaje puede superar 100 %? | PASS |
| ¿Se puede asignar un pensum a la carrera equivocada? | PASS — imposible por construcción (H1) + `PEN_CAR_ID` congelado (R2) |
| ¿Un pensum puede tener dos veces el mismo curso? | PASS |
| ¿Puede una FK quedar semánticamente inconsistente? | WARNING — D3 y D4 quedan como diagnóstico en E3 |
| ¿Se puede mover un resultado a otro estudiante u oferta? | PASS — identidad inmutable (R3) |
| ¿Un JOIN puede duplicar estudiantes? | WARNING — grano por programa (EPR); se documentará en Q01 (E2) |
| ¿Consultas indexables? | NEEDS REVIEW — EXPLAIN sobre el dataset de E2/E3 |
| ¿Doctrine lo mapea sin hacks? | PASS |
