# E2: Dataset realista y consultas de negocio (Fases 5 y 6)

**Sistema Académico Symfony · capa PostgreSQL**

| | |
|---|---|
| **STATUS** | **PASS. Pendiente de revisión (gate E2)** |
| Prerrequisito | E1 APPROVED (R3, smoke test 109/109) |
| Verificación | `E2_dataset_check.sql`: **34/34 PASS**. `12_business_queries.sql`: Q01–Q25 sin errores. `E1_smoke_test.sql` sigue en 109/109 sobre la estructura sin datos. |
| Reproducibilidad | Dos cargas consecutivas producen la misma huella md5 de resultados: **`4ad9de4736c9003431a4853a234229e7`** |
| NEXT | Revisar E2 → E3 (diagnósticos, pruebas positivas y negativas, EXPLAIN, autoauditoría, README, matriz de trazabilidad) |

> **DEMONSTRATION DATA · FICTIONAL · ACADEMICALLY PLAUSIBLE.** Personas, carreras y pensums son inventados. Los pensums no corresponden a pensums oficiales del MINEDUC ni a ninguna institución real.

---

## 1. Archivos entregados

| Archivo | Contenido |
|---|---|
| `database/06_seed_catalogs.sql` | 3 políticas (2025, 2026, 2028 futura), 2 años, 4 períodos, 3 secciones, 4 ciclos, 3 carreras, 41 cursos |
| `database/07_seed_curricula.sql` | 4 pensums (3 de 2025 + Computación 2027 sin estudiantes) y 82 asignaciones curso-ciclo |
| `database/08_seed_students.sql` | 45 estudiantes y su inscripción en pensum |
| `database/09_seed_academic_history.sql` | Historial 2025-I → 2026-II: 138 inscripciones por período, 167 ofertas, 708 resultados |
| `database/12_business_queries.sql` | Q01–Q25 con propósito, parámetros y resultado esperado |
| `database/E2_dataset_check.sql` | Evidencia del gate: 34 verificaciones del dataset |
| `database/run_all.sql` | Ahora carga estructura + datos. Con `-v solo_estructura=1` se detiene antes de los datos. |

```bash
psql -d sistema_academico_dev -f run_all.sql                 # estructura + dataset
psql -d sistema_academico_dev -f E2_dataset_check.sql        # TOTAL: 34 verificaciones PASS
psql -d sistema_academico_dev -f 12_business_queries.sql     # Q01–Q25
psql -d sistema_academico_dev -v p_estudiante=STU-2025-0005 -f 12_business_queries.sql   # otro estudiante
```

---

## 2. Diseño del dataset

### 2.1 Estructura académica

| Elemento | Datos |
|---|---|
| Políticas | POL-2025-01 (61, desde 2025-01-01) · POL-2026-01 (61, desde 2026-01-01) · **POL-2028-01 (70, futura)** |
| Períodos | 2025-I y 2025-II CERRADOS (POL-2025) · 2026-I CERRADO y **2026-II ABIERTO** (POL-2026) |
| Carreras | Computación (BCL-COMP) · Ciencias y Letras (BCL) · Comercial (BCO) |
| Pensums | 4 ciclos × 5 obligatorios = 20 cursos por pensum. Optativo ART-101 en Computación y Ciencias y Letras. Computación 2027 (versión 2) sin estudiantes. |
| Cursos compartidos | MAT-101, MAT-102, COM-101, ING-101, ING-102, ING-201, EST-201, ETI-202, SEM-202, FIS-101, FIS-102: un solo registro, varios pensums |

Continuidad curricular: Programación I → II → III, Matemática I → II → III, Inglés I → IV, Contabilidad I → II → III → Costos. No hay prerrequisitos formales (fuera de alcance).

### 2.2 Cohortes

| Cohorte | Estudiantes | Trayectoria |
|---|---|---|
| 2025 | STU-2025-0001…0026 | Año 1 en 2025, Año 2 en 2026; termina en 2026-II. **STU-2025-0026 se retira al cierre de 2025.** |
| 2026 | STU-2026-0001…0018 | Año 1 en 2026 (2026-II en curso) |
| Registrado sin períodos/resultados | STU-2026-0019 | Programa ACTIVO (BCL-COMP-2025, desde 2026-09-01), sin períodos ni resultados |

Secciones: Computación 2025 en A y B; Ciencias y Letras 2025 en A y B; Comercial 2025 en A y C; Computación 2026 en A y B; Ciencias y Letras 2026 en A; Comercial 2026 en B.

### 2.3 Cómo se generan las notas (reproducible, sin `random()`)

```
nota = COALESCE(nota fija del caso, base del perfil + dificultad del curso + ruido)
ruido = md5(estudiante | curso | período) → entero entre −6 y +6
```

| Perfil | Base | Rango | Estudiantes |
|---|---|---|---|
| ALTO | 90 | 77–100 | 9 (incluye CASO A) |
| MEDIO | 76 | 63–86, nunca reprueba por fórmula | 26 |
| BAJO | 65 | 52–75, reprobaciones naturales | 10 |

Dificultad: MAT −7 · FIS −6 · FIN −4 · CON −3 · PRG −2 · ING +4 · ETI/SEM +3 · ART +6. El resultado: Matemática I, II y III con tasa de aprobación de 77–78 % y promedio de 69; los cursos de Inglés con promedio de 79–81.

**Período abierto (2026-II, hoy octubre de 2026):** los graduandos (cohorte 2025) ya tienen todas sus notas. En Computación 2026 solo están calificados PRG-102 e ING-102. Ciencias y Letras y Comercial 2026 tienen todo pendiente. Total: **81 resultados pendientes (NULL)**.

### 2.4 Ciclo de vida respetado por la carga

Cada período pasa por PLANIFICADO → ABIERTO → inscripción → ofertas → resultados → EPE FINALIZADO → CERRADO. Así la carga misma demuestra que T2 (D7: solo ABIERTO), T3 (política asignada por fecha) y D6 (sin intento posterior a una aprobación) aceptan datos correctos.

---

## 3. Casos nombrados (A–J)

| Caso | Código | Estudiante | Qué demuestra |
|---|---|---|---|
| **A** Excelencia | STU-2025-0001 | Ana Lucía López Ajú (Computación) | 20/20 aprobados, promedio 90.29, pensum completo |
| **B** Límite de aprobación | STU-2025-0002 | Bryan Estuardo Tzul Morales | FIS-101 (2025-I) = **61.00 → APROBADO** |
| **C** Límite de reprobación | STU-2025-0003 | Carla Sofía Xicará Pérez | MAT-102 (2025-II) = **60.00 → REPROBADO**. En 2026-II la pantalla de ingreso le ofrece repetirlo (Q25). |
| **D** Repitencia exitosa | STU-2025-0004 | Diego Alejandro Batz Coyoy | PRG-101: 52 (2025-I) → 74 (2026-I, sección B junto a la cohorte 2026) |
| **E** Repitencia fallida | STU-2025-0005 | Elena María Chávez Son | MAT-101: 48 (2025-I) → 57 (2026-I). Además reprueba FIS-101, PRG-101 y MAT-201. |
| **F** Ciclo completo | STU-2025-0006 | Fernando José Ixcot Ramírez | Año 1 / Semestre I: 5/5 COMPLETO |
| **G** Ciclo incompleto | STU-2025-0007 | Gabriela Alejandra Monzón Tuy | Año 1 / Semestre II: 4/5 por ING-102 = 58 |
| **H** Sin notas | STU-2026-0019 | Tomás Ezequiel Gómez Xuruc | Registrado sin períodos/resultados: programa ACTIVO desde 2026-09-01, avance 0 % |
| **I** Resultados pendientes | STU-2026-0002 | Brandon Steven Ordóñez Ical | 2026-II: PRG-102 e ING-102 calificados; MAT-102, FIS-102 y WEB-101 en NULL |
| **J** Historial multianual | STU-2025-0004 | Diego Alejandro Batz Coyoy | Resultados en 2025 y 2026 (21 intentos) |

Otros escenarios del contrato (§29):

- **Frontera:** notas 58, 59, 60, 61, 62 y 63, todas presentes. Por ejemplo: STU-2025-0010 MAT-201 = 59; STU-2026-0003 MAT-101 = 60; STU-2025-0012 MAT-101 = 61; STU-2025-0008 FIS-102 = 62; STU-2025-0006 EST-201 = 63.
- **Múltiples reprobaciones:** STU-2025-0005, 0010, 0014, 0018, 0020, 0024 y STU-2026-0012.
- **Retirado:** STU-2025-0026, RETIRADO desde 2025-12-05, sin períodos en 2026.
- **§47 (validación histórica, E3):** STU-2026-0009, ING-101 = 65 en 2026 con POL-2026 (61). Con POL-2028 (70) existente, sigue APROBADO.

---

## 4. Reproducibilidad

- Sin `random()` ni IDs fijos. Todo se resuelve por claves naturales (`EST_CODIGO`, `CUR_CODIGO`, `PEN_CODIGO`, año-período).
- Las ofertas y resultados se insertan con `ORDER BY`, así que también los IDs generados coinciden entre cargas sobre una base limpia.
- Huella de verificación (sin IDs), comprobada en `E2_dataset_check.sql`:

```sql
SELECT md5(string_agg(EST_CODIGO||'|'||CUR_CODIGO||'|'||ANL_ANIO||'-'||PER_NUMERO||'|'||COALESCE(RES_NOTA::text,'NULL'),
                      ',' ORDER BY EST_CODIGO, CUR_CODIGO, PER_FECHA_INICIO))
FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE;
-- 4ad9de4736c9003431a4853a234229e7
```

---

## 5. Consultas Q01–Q25: resultado esperado con este dataset

Los parámetros por defecto son: `p_carrera = BCL-COMP` · `p_estudiante = STU-2025-0004` · `p_curso = MAT-101` · `p_seccion = B` · período 2026-I · ciclo Año 1 / Semestre II · `p_ingreso_est = STU-2025-0003`.

| Q | Consulta | Fuente | Resultado esperado |
|---|---|---|---|
| Q01 | Alumnos de una carrera | tablas | 19 filas (10 + 8 + 1 registrado sin períodos), todas ACTIVO. Grano: programa (EPR). |
| Q02 | Buscar por código | tablas | 1 fila: Diego Alejandro Batz Coyoy, Computación, ACTIVO |
| Q03 | Ficha completa | tablas + AVANCE_PENSUM | Computación · Pensum 2025 · último período 2026 / Semestre II · Año 2 / Semestre II · sección B · 20/20 · 100 % |
| Q04 | Historial | RESULTADO_ESTUDIANTE | 21 filas. PRG-101 dos veces: 52 REPROBADO (intento 1) y 74 APROBADO (intento 2) |
| Q05 | Notas de una carrera | REPORTE_NOTAS | Computación por período: 50 / 55 / 92 / 94 resultados; promedios 73.88 · 74.64 · 74.67 · 78.17 (2026-II con 28 pendientes) |
| Q06 | Notas de un curso | REPORTE_NOTAS | MAT-101: 45 filas de las 3 carreras; incluye 48 y 57 de STU-2025-0005 |
| Q07 | Notas de una sección | REPORTE_NOTAS | Sección B, 2026-I: 92 filas |
| Q08 | Carrera + curso + sección | REPORTE_NOTAS | 10 filas. 2025-I: 5 alumnos (0005 = 48 y 0010 = 53 reprueban). 2026-I: 4 de la cohorte 2026 + repitencia de 0005 (57, intento 2). |
| Q09 | Promedio por carrera | REPORTE_NOTAS | Ciencias y Letras 76.11 · Computación 75.39 · Comercial 74.05 |
| Q10 | Promedio por curso | REPORTE_NOTAS | 40 cursos. Arriba: ART-101 86.00, Inglés III 80.68. Abajo: MAT-201 69.61, MAT-102 68.77, MAT-101 68.71. |
| Q11 | Aprobación **por intento**, por carrera | REPORTE_NOTAS | Computación 94.30 % · Comercial 94.29 % · Ciencias y Letras 93.12 % (pendientes excluidos del denominador) |
| Q12 | Aprobación **por intento**, por curso | REPORTE_NOTAS | Más baja: LIT-201 75.00 %, MAT-102 76.92 %, MAT-101 y MAT-201 77.78 % |
| Q13 | Aprobación por sección | REPORTE_NOTAS | 12 filas (4 períodos × 3 secciones). 2025-I sección B 86.67 % |
| Q14 | Reprobados por estudiante | RESULTADO + INTENTO | 38 intentos reprobados; el de PRG-101 de 0004 figura con situación actual APROBADO |
| Q15 | Pendientes de un estudiante | PCU + INTENTO | 0004: 0 filas. Con `p_estudiante = STU-2025-0005`: 4 (MAT-101, PRG-101, FIS-101, MAT-201) |
| Q16 | Cursos repetidos | INTENTO_CURSO | 2 filas: 0004 PRG-101 (52 → 74, APROBADO 2026 / Semestre I) · 0005 MAT-101 (48 → 57, REPROBADO) |
| Q17 | Intentos por curso | INTENTO_CURSO | 0004: 20 cursos; PRG-101 con 2 intentos |
| Q18 | Avance global | AVANCE_PENSUM | 45 programas: 17 al 100 %; STU-2026-0019 al 0 %; STU-2025-0026 (retirado) al 50 % |
| Q19 | Avance por ciclo | AVANCE_CICLO | 0004: 4 ciclos COMPLETO (Año 1 / Sem I se completa al aprobar PRG-101 en 2026) |
| Q20 | ¿Ciclo completo? | AVANCE_CICLO | Año 1 / Sem II, cohorte 2025 INCOMPLETO: 0003, 0007, 0010, 0014, 0018, 0020, 0024. Cohorte 2026 en curso. |
| Q21 | Pendientes de ciclos anteriores | PCU + INTENTO | 12 estudiantes. 0018 y 0024 con 5; 0005 con 4; 0003 (MAT-102); 0007 (ING-102) |
| Q22 | Pensum completo | AVANCE_PENSUM | 17 estudiantes de la cohorte 2025 (EPR sigue ACTIVO hasta el cierre administrativo) |
| Q23 | Comparación de períodos | REPORTE_NOTAS | Aprobación por intento: 2025-I 91.54 % · 2025-II 94.96 % · 2026-I 91.71 % · 2026-II 98.58 %. % calificados (E3): 100 · 100 · 100 · 63.51 (141 de 222; 81 pendientes) |
| Q24 | Política histórica | RESULTADO + POLÍTICA | Notas de 61 a 69.99 son APROBADO con POL-2025/2026 aunque serían REPROBADO con POL-2028. Línea de tiempo: POL-2025 hasta 2025-12-31, POL-2026 hasta 2027-12-31, POL-2028 sin fin. |
| Q25 | Ingreso de notas | INGRESO_NOTAS | 0003 en 2026-II: 5 cursos de CICLO_ACTUAL (calificados, editables) + **MAT-102 CICLO_ANTERIOR / SIN_REGISTRO / editable** con su OFE_ID |

---

## 6. Hallazgos de E2

### E2-H1 — El smoke test de E1 requiere la estructura sin datos
`E1_smoke_test.sql` crea su propio mini-dataset con los años 2025/2026, que chocan con los del dataset demostrativo. Se agregó una guarda con mensaje claro y la opción `run_all.sql -v solo_estructura=1`. Sin otra modificación, las dos suites conviven.

### E2-H2 — Programas de graduandos siguen ACTIVO
Los 17 estudiantes con el pensum completo tienen `EPR_ESTADO = ACTIVO` porque 2026-II no ha cerrado. Q22 se basa en el avance (`AVA_PENSUM_COMPLETO`), no en el estado administrativo. Pasar a FINALIZADO es un acto posterior al cierre (Symfony o un script de cierre de año).

### E2-H3 — Grano de Q01 y Q18
Ambas consultas trabajan por **programa** (EPR). En este dataset cada estudiante tiene un solo programa, así que no hay duplicados. La regla queda documentada en la consulta para cuando existan cambios de pensum.

### E2-H4 — Cursos pendientes sin repitencia registrada
Los estudiantes de perfil bajo reprueban cursos que no vuelven a cursar en el dataset (solo D y E tienen repitencia). Es intencional: alimenta Q21 y la pantalla de ingreso (Q25 descubre MAT-102 para Carla). No es una inconsistencia.

---

## 7. Pendiente para E3

- `10_validation_queries.sql`: diagnósticos de §34 + D3, D4 + "intento posterior a una aprobación".
- `11_negative_tests.sql` y `13_positive_tests.sql` sobre este dataset, incluida la §47 con STU-2026-0009.
- `14_explain.sql`: historial, alumnos por carrera, reporte de notas, avance e ingreso de notas.
- README, matriz de trazabilidad y autoauditoría final.
