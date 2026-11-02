# E3: Verificación, rendimiento y autoauditoría (Fases 7, 8 y 9) — cierre

**Sistema Académico Symfony · capa PostgreSQL · último gate antes de Doctrine/Symfony**

| | |
|---|---|
| **STATUS** | **POSTGRESQL SCHEMA V1 — FROZEN / APPROVED** (§8) |
| Prerrequisitos | E1 APPROVED (R3) · E2 APPROVED |
| Motor | PostgreSQL 16.15 |
| Dictamen final | DF1 APROBADA (SA208) · DF2 DIFERIDA · DF3 SE MANTIENE COMO DIAGNÓSTICO |
| NEXT | Integración Doctrine/Symfony. Sin cambios estructurales salvo defecto descubierto en la integración. |

## 0. Resultado de todas las suites (corrida final desde base limpia: `dropdb` + `createdb`)

| Suite | Base requerida | Resultado |
|---|---|---|
| `E1_smoke_test.sql` | estructura sin datos | **109/109 PASS** |
| `E2_dataset_check.sql` | dataset | **34/34 PASS** (huella `4ad9de4736c9003431a4853a234229e7` sin cambios) |
| `10_validation_queries.sql` | dataset | **18/18 diagnósticos de integridad en 0 · 6/6 informativos con el valor esperado** |
| `11_negative_tests.sql` | dataset | **61/61 PASS**: reglas que deben fallar (SQLSTATE y constraint verificados) + correcciones frontera de DF1 que deben permitirse |
| `13_positive_tests.sql` | dataset | **39/39 PASS** (19 de flujo §32 + 4 de §47 + 16 de aceptación §46 A–P) |
| `12_business_queries.sql` | dataset | Q01–Q25 sin errores |
| `14_explain.sql` | dataset | 7 planes (E1–E5, E5b, E6) sin errores; los 7 `IX_*` aparecen en planes |
| D14 (intento posterior a una aprobación) | dataset | **0** |

Salida completa de la corrida final: `docs/VERIFICACION_FINAL.log`.

```bash
psql -d sistema_academico_dev -v solo_estructura=1 -f run_all.sql && psql -d sistema_academico_dev -f E1_smoke_test.sql
psql -d sistema_academico_dev -f run_all.sql && psql -d sistema_academico_dev -f run_tests.sql
```

---

## 1. Archivos de E3

| Archivo | Contenido |
|---|---|
| `database/10_validation_queries.sql` | D01–D18 (integridad, esperado 0) e I01–I06 (informativos). Incluye **D14: intento posterior a una aprobación** (punto 1 del gate). Falla si algún diagnóstico no coincide. |
| `database/11_negative_tests.sql` | N01–N51: lista §33 completa más cada regla de T2, T3 y T4, con SQLSTATE y nombre de constraint verificados. N52–N61: reapertura y corrección histórica (DF1 · SA208). Las pruebas "permitido" exigen afectar al menos una fila (sin pruebas vacías). |
| `database/13_positive_tests.sql` | P01–P19 flujo de alta §32 · P20–P23 validación histórica §47 · A–P aceptación §46 |
| `database/14_explain.sql` | Planes reales y con `enable_seqscan = off` para 5 consultas críticas + E5b (ingreso por clave) + E6 (búsqueda por apellido) |
| `database/run_tests.sql` | Orquesta E2_dataset_check, 10, 11 y 13 |
| `database/README.md` | Las 17 secciones de §37 |
| `docs/traceability_matrix.md` | 66 requerimientos trazados hasta su prueba (R65 SA208, R66 validaciones Symfony) |
| `docs/VERIFICACION_FINAL.log` | Evidencia de la corrida final desde base limpia |

### Ajustes de documentación solicitados en el gate (sin cambios de estructura ni de datos)

| Punto | Cambio | Archivo |
|---|---|---|
| 2 | Q23 agrega `pct_calificados` (2026-II: 63.51 %) junto a la tasa de aprobación | 12 |
| 3 | Q11, Q12 y Q13 dicen explícitamente **"POR INTENTO"** y explican su definición | 12, README §13, E2_ENTREGA §5 |
| 4 | STU-2026-0019 pasa a llamarse "registrado sin períodos/resultados" | 08 (comentarios), 12, E2_ENTREGA |
| 5 | `PCU_OBLIGATORIO` documentado como **contrato para Symfony** (COMMENT de columna, diccionario, README §10) | 01 (solo COMMENT), data_dictionary, README |

El COMMENT de `PCU_OBLIGATORIO` es el único cambio en un archivo de E1. Es metadato: no altera tipos, constraints ni datos. La huella del dataset no cambió y las cuatro suites pasan sobre la base reconstruida.

---

## 2. Pruebas negativas: cobertura de §33

| §33 | Prueba | Detenida por |
|---|---|---|
| nota −1 / 101 | N01, N02 | CK_RES_NOTA_RANGO |
| estudiante duplicado | N05 | UQ_EST_CODIGO |
| carrera duplicada | N06 | UQ_CAR_CODIGO |
| curso duplicado | N07 | UQ_CUR_CODIGO |
| academic_term duplicado | N08 | UQ_PER_ANL_NUMERO |
| student_term duplicado | N09 | UQ_EPE_EPR_PER |
| course_offering duplicada | N10 | UQ_OFE_PER_PCU_SEC |
| nota duplicada estudiante/oferta | N11 | UQ_RES_EPE_OFE |
| curriculum de carrera incorrecta | N15 | **imposible por construcción** (no existe EPR_CAR_ID → 42703); N35: SA401 si se intenta mover el pensum |
| resultado en período incompatible | N16 | T2 SA201 |
| fechas invertidas | N43–N46 | CK_ANL_FECHAS, CK_PER_FECHAS, CK_PEN_VIGENCIA, CK_EPR_FECHAS |
| FK inexistente | N49, N50 | FK_RES_EPE, FK_EPR_PEN |

Reglas adicionales cubiertas:

- **T2:** SA202–SA207 (N17–N24) y SA208 (N52, N59).
- **T3:** SA301–SA305 y borrado de política usada (N25–N30).
- **T4:** las 9 tablas (N31–N40).
- **Borrados RESTRICT:** N41, N42.
- **Overflow numérico:** N04.
- **Estados inválidos:** N47, N48.
- **Blancos:** N51.

---

## 3. Reapertura / corrección histórica → DF1 aprobada (SA208)

**Regla en T2 (solo UPDATE, sin función ni trigger nuevos).** Se activa si el UPDATE convierte un intento **no aprobado** (NULL o bajo la nota mínima) en **aprobado**. La nota mínima es la de la **política histórica del período del intento**; la identidad es inmutable (T4), así que es siempre el mismo período. En ese caso se busca **cualquier** intento del mismo `EPR_ID + PCU_ID` en un período cronológicamente posterior, sin importar su nota. Si existe, la corrección se rechaza con **SA208**. El mensaje lista los intentos posteriores y el HINT indica resolverlos administrativamente primero.

| Prueba | Escenario | Política | Resultado |
|---|---|---|---|
| N52 | CASO E: MAT-101 48 → 65 en 2025-I, con intento en 2026-I (57) | 61 | **SA208** |
| N53–N54 | El mismo intento, 48 → 60 | 61 | Permitido: sigue REPROBADO y se conservan los 2 intentos |
| N55–N56 | CASO G: ING-102 58 → 61, **sin** intento posterior | 61 | Permitido: pasa a APROBADO y completa su ciclo |
| N57 | CASO D: PRG-101 74 → 80 (aprobado → aprobado) | 61 | Permitido |
| N58 | 2028-I: PRG-101 = 65 con POL-2028, y reintento en 2028-II | **70** | 65 es REPROBADO; el reintento fue admitido (SA207 no aplica) |
| N59 | 65 → 70 con intento posterior | **70** | **SA208**. Con 61 no se activaría, porque 65 ya aprobaba: prueba que usa la política histórica. |
| N60 | 55 → 65 con intento posterior | **70** | Permitido, porque sigue REPROBADO. Con 61 habría sido SA208. |
| N61 | Tras todos los escenarios | — | D14 = 0 (defensa en profundidad) |

D14 se conserva en `10_validation_queries.sql`: detectaría datos cargados con triggers deshabilitados o por una vía futura no prevista.

---

## 4. Planes de ejecución (§35)

El dataset tiene 45 estudiantes y 708 resultados; casi todas las tablas caben en 1–3 páginas. Por eso cada consulta se ejecuta dos veces:

- **(a) plan real:** el optimizador elige recorridos secuenciales porque leer la tabla completa es más barato que recorrer un índice, y eso es correcto;
- **(b) con `enable_seqscan = off`:** muestra qué índices usaría con volumen real.

| # | Consulta | Plan real (a) | Índices disponibles (b) | Lectura |
|---|---|---|---|---|
| E1 | Historial de un alumno (Q04) | Estudiante por recorrido secuencial (1 fila), luego `uq_epe_epr_per` y `uq_res_epe_ofe` por índice. El número de intento recorre `resultado_curso` completo 21 veces (708 filas c/u). | `uq_est_codigo` → `uq_epr_est_pen_inicio` → `uq_epe_epr_per` → `uq_res_epe_ofe` → PKs. Número de intento: `ix_ofe_pcu` + `ix_res_ofe`. | **PASS.** Con más datos, la subconsulta del intento pasa a índice. |
| E2 | Alumnos por carrera (Q01) | Hash joins con recorridos secuenciales (tablas de 1 página) | `uq_car_codigo` → `uq_pen_car_version` → **`ix_epr_pen`** → `pk_estudiante` | **PASS.** `IX_EPR_PEN` es exactamente el índice previsto. |
| E3 | Reporte carrera + curso + sección (Q08) | `ix_ofe_pcu` ya en el plan real; resto por hash | `uq_cur_codigo` → `ix_pcu_cur` → **`ix_ofe_pcu`** → **`ix_res_ofe`** | **PASS.** |
| E4 | Avance de un alumno (Q18) | Agrega los **708** resultados (HashAggregate) y después filtra por estudiante | Igual, por índices: la agregación sigue cubriendo todos los programas | **WARNING → DF2** (E3-H2) |
| E5 | Ingreso de notas filtrando por `EST_CODIGO` | El filtro entra después del UNION ALL: 737 filas intermedias para devolver 6 | Índices por rama, pero las 3 ramas recorren todos los estudiante-período | **WARNING** si se consulta por código |
| E5b | Ingreso de notas filtrando por la **clave** `EPE_ID` | El filtro entra en cada rama: **6 filas** intermedias para devolver 6 | — | **PASS.** Forma recomendada para Symfony: buscar al alumno y su EPE, y consultar la vista por `EPE_ID` |
| E6 | Búsqueda por apellido (`lower(...) LIKE 'chá%'`) | — (45 filas: el recorrido secuencial es lo esperable) | **`ix_est_busqueda_apellidos`** con rango `~>=~ / ~<~` | **PASS.** El índice de expresión con `varchar_pattern_ops` sirve para la búsqueda por prefijo. |

**Los 7 índices `IX_*` aparecen en al menos un plan:**

- `ix_res_ofe`, `ix_ofe_pcu`, `ix_epr_pen` e `ix_per_pol` ya se usan en planes reales y en los triggers.
- `ix_pcu_cur` (E3), `ix_epe_per_sec` (E5) e `ix_est_busqueda_apellidos` (E6) se usan cuando el optimizador no puede preferir el recorrido secuencial.

El conteo acumulado está al final de `14_explain.sql`.

---

## 5. Hallazgos de E3 (§45)

### E3-H1: corrección histórica que deja un intento posterior a una aprobación — **RESUELTO (DF1)**
- Bloqueado en T2 con SA208 (§3). Probado con política de 61 y de 70. Migración aplicada solo en `04_functions_triggers.sql`; datos sin cambios (huella idéntica).

### E3-H2: el avance por alumno agrega todos los resultados antes de filtrar — **DIFERIDO (DF2)**
- **Problema:** `VW_AVANCE_CICLO` hace LEFT JOIN a `VW_INTENTO_CURSO`, que agrupa **todos** los intentos. PostgreSQL no empuja el filtro del estudiante dentro de una agregación unida por JOIN.
- **Impacto:** a esta escala, ≈3 ms. El costo crece con el total de resultados de la escuela, no con los del alumno.
- **Decisión:** las vistas no se modifican. Optimización candidata documentada, con las mismas columnas y el mismo contrato para Doctrine:

```sql
-- En SIS_ACA_VW_AVANCE_CICLO, sustituir
--   LEFT JOIN SIS_ACA_VW_INTENTO_CURSO i ON i.EPR_ID = epr.EPR_ID AND i.PCU_ID = pcu.PCU_ID
-- por:
LEFT JOIN LATERAL (
    SELECT bool_or(v.RES_ESTADO = 'APROBADO') AS RES_APROBADO
    FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE v
    WHERE v.EPR_ID = epr.EPR_ID AND v.PCU_ID = pcu.PCU_ID
) i ON true
```

Se aplicaría solo si la integración con volumen real lo justifica, verificándola con D15, D16 y P18.

### E3-H3: la vista de ingreso debe consultarse por su clave
- **Problema:** filtrar `VW_INGRESO_NOTAS` por `EST_CODIGO` aplica el filtro después del UNION ALL (E5).
- **Recomendación:** Symfony busca primero al alumno (Q02, por índice) y su `EPE_ID` del período abierto, y consulta la vista por `EPE_ID` (E5b). No requiere cambios en la base.

---

## 6. SELF-AUDIT (§49)

| # | Pregunta | Resultado | Evidencia |
|---|---|---|---|
| 1 | ¿Hay redundancia? | **PASS** | Sin carrera en el programa (H1); sin `effective_to` ni `active` en política (H2); catálogo de cursos único (DSC: MAT-101 en 4 pensums) |
| 2 | ¿Datos derivados almacenados innecesariamente? | **PASS** | Estado, número de intento, avance y vigencia de la política se derivan en vistas |
| 3 | ¿Puede una FK quedar inconsistente semánticamente? | **PASS** | T2 (período, pensum, sección) + T4 (9 tablas) + D09–D11 = 0 |
| 4 | ¿Una reforma académica rompe el pasado? | **PASS** | FK explícita + T3; P20–P23 (§47 con POL-2028 y POL-2030); N27, N28 |
| 5 | ¿Una repetición de curso rompe el progreso? | **PASS** | P16–P18, I (Elena 80 %), D16 = 0 |
| 6 | ¿Un NULL puede producir un falso aprobado? | **PASS** | CASE evalúa NULL primero; P13; tasas excluyen pendientes; Q23 informa % calificados |
| 7 | ¿Un JOIN puede duplicar estudiantes? | **WARNING** | Grano por programa (EPR), documentado en Q01/Q18. Hoy no hay duplicados (1 programa por estudiante). Con cambios de pensum, filtrar `EPR_ESTADO = 'ACTIVO'`. |
| 8 | ¿El porcentaje puede superar 100 %? | **PASS** | Numerador ⊆ denominador; D15 = 0 |
| 9 | ¿Un curso repetido cuenta dos veces? | **PASS** | Agregación por (EPR_ID, PCU_ID); D16 = 0; P18 |
| 10 | ¿Puede un estudiante quedar sin pensum? | **PASS** | `EPR_PEN_ID NOT NULL` + FK; un estudiante sin programa no aparece en reportes de carrera (correcto). I03 detecta programas sin períodos (CASO H). |
| 11 | ¿Puede un pensum contener dos veces el mismo curso? | **PASS** | UQ_PCU_PEN_CUR; N12; D06 = 0 |
| 12 | ¿Se puede asignar un pensum a una carrera incorrecta? | **PASS** | Imposible por construcción (N15) y PEN_CAR_ID congelado (N35) |
| 13 | ¿Las consultas son razonablemente indexables? | **WARNING (aceptado)** | E1–E3, E5b y E6: PASS. E4 agrega todo antes de filtrar (DF2 diferida, optimización documentada). E5: regla de uso por clave (E3-H3). |
| 14 | ¿Doctrine podrá mapearlo sin hacks innecesarios? | **PASS** | Nombres sin comillas, PK IDENTITY, solo ManyToOne, vistas con clave estable, SQLSTATE propios; estrategia database-first (README §17) |
| 15 | ¿Una corrección histórica puede romper la regla D6? | **PASS** | SA208 (DF1): N52 y N59 bloqueados; N53, N55, N57 y N60 permitidos; D14 = 0 |
| 16 | ¿Las reglas transversales tienen prueba positiva y negativa? | **PASS** | Cada SQLSTATE SA1xx–SA4xx (incluido SA208) tiene caso negativo (11) y caso permitido (smoke, 11 N7, 13) |
| 18 | ¿Hay reglas que dependan de la aplicación? | **PASS (documentado)** | DF3: D03, D04 y D08 son validaciones obligatorias de Symfony y diagnósticos en la base (README §16) |
| 17 | ¿El dataset es reproducible y ficticio? | **PASS** | Huella md5 estable; sin `random()`; etiquetado DEMONSTRATION DATA |

**Balance final: 16 PASS · 2 WARNING aceptados (grano por programa; DF2 diferida) · 0 FAIL.**

### Decisiones finales

| ID | Decisión | Dictamen | Aplicación |
|---|---|---|---|
| **DF1** | Corrección histórica con intentos posteriores | **APROBADA** | T2 + SA208; N52/N59 EXPECTED FAILURE; D14 como defensa en profundidad |
| **DF2** | Escalabilidad de `VW_AVANCE_*` | **DIFERIDA** | Vistas sin cambios; reescritura LATERAL documentada (E3-H2, README §15) |
| **DF3** | D3/D4 y solapes de períodos | **SE MANTIENEN COMO DIAGNÓSTICO** | Sin quinta función. D03, D04 y D08 quedan como validaciones obligatorias de Symfony (README §16, matriz R66) |

---|---|---|---|
| **DF1** | Corrección histórica que deja un intento posterior a una aprobación | **(a)** Bloquear en T2 con SA208 (cambio de ≈20 líneas, misma función) · **(b)** Aceptar como riesgo y vigilar con D14 (comando de salud en Symfony) | **(a).** Convierte el único FAIL en PASS antes de que Doctrine dependa del modelo, sin trigger nuevo. |
| **DF2** | Escalabilidad de `VW_AVANCE_*` | **(a)** Reescribir con LATERAL ahora · **(b)** Diferir hasta tener volumen real | **(b).** Es correcto y suficiente para la escala del proyecto (§42). La reescritura no cambia el contrato de la vista. |
| **DF3** | D3/D4 (fechas del período dentro del año, solapes; ciclo no usado por el pensum) | **(a)** Pasarlas a regla bloqueante (trigger nuevo) · **(b)** Mantener como diagnóstico (D03, D04, D08) | **(b).** Son errores de configuración administrativa, poco frecuentes y visibles en el diagnóstico. No justifican una quinta función de trigger. |

---

## 7. Paquete final consolidado (Fase 9)

```
database/
├── 00_reset.sql                 SOLO DESARROLLO / DESTRUCTIVO (SA001)
├── 01_schema.sql                14 tablas
├── 02_constraints.sql           20 UQ + 1 UX parcial · 35 CK · 17 FK RESTRICT
├── 03_indexes.sql               7 índices justificados
├── 04_functions_triggers.sql    1 auxiliar + 4 funciones de trigger · 24 triggers
├── 05_views.sql                 8 vistas
├── 06…09_seed_*.sql             dataset demostrativo reproducible
├── 10_validation_queries.sql    24 diagnósticos
├── 11_negative_tests.sql        61 pruebas (incluye DF1 · SA208)
├── 12_business_queries.sql      Q01–Q25
├── 13_positive_tests.sql        39 pruebas (§32, §46, §47)
├── 14_explain.sql               7 planes
├── E1_smoke_test.sql            109 verificaciones de estructura
├── E2_dataset_check.sql         34 verificaciones del dataset
├── run_all.sql · run_tests.sql  orquestadores
└── README.md                    §37 completo
docs/
├── FASE_1_AUDITORIA.md · E1_ENTREGA.md · E2_ENTREGA.md · E3_ENTREGA.md
├── data_dictionary.md · er_model.md · traceability_matrix.md
├── VERIFICACION_FINAL.log
```

## 8. Declaración

Corrida final desde base limpia (`docs/VERIFICACION_FINAL.log`):

| # | Paso | Resultado |
|---|---|---|
| 1 | E1 smoke test | 109/109 PASS |
| 2 | E2 dataset check | 34/34 PASS · huella `4ad9de4736c9003431a4853a234229e7` |
| 3 | Validation queries | 18/18 integridad = 0 · 6/6 informativos OK |
| 4 | Negative tests | 61/61 PASS |
| 5 | Positive tests | 39/39 PASS |
| 6 | Q01–Q25 | 25 consultas, 0 errores |
| 7 | EXPLAIN | 7 planes, 0 errores, 7/7 índices en planes |
| — | D14 | **0** |

# POSTGRESQL SCHEMA V1 — FROZEN / APPROVED

Estructura congelada: 14 tablas · 20 UQ + 1 UX · 35 CK · 17 FK RESTRICT · 7 índices · 1 función auxiliar + 4 funciones de trigger (24 triggers) · 8 vistas · SQLSTATE SA001, SA101, SA201–SA208, SA301–SA305, SA401.

**Regla de cambio:** no habrá más cambios estructurales, salvo un **defecto descubierto durante la integración con Doctrine**. Si aparece uno, se documenta con el protocolo de hallazgos (§45) y se vuelve a ejecutar esta misma secuencia antes de aceptarlo.
