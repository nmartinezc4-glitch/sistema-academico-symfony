-- =====================================================================
--  12_business_queries.sql — E2 · Consultas de negocio Q01–Q25
--
--  Solo lectura. Cada consulta indica propósito, parámetros y resultado
--  esperado con el dataset demostrativo (06–09). El detalle completo de
--  los resultados esperados está en docs/E2_ENTREGA.md §5.
--
--  Uso:
--    psql -d sistema_academico_dev -f 12_business_queries.sql
--  Parámetros (psql) con valores por defecto; se pueden cambiar con -v:
--    psql -d sistema_academico_dev -v p_estudiante=STU-2025-0005 -f 12_business_queries.sql
--
--  En Symfony, cada consulta se traduce a un método de repositorio con
--  parámetros enlazados (:carrera, :curso…), nunca con concatenación.
-- =====================================================================
\set ON_ERROR_STOP on
\pset null '·'

\if :{?p_carrera}     \else \set p_carrera     'BCL-COMP'      \endif
\if :{?p_estudiante}  \else \set p_estudiante  'STU-2025-0004' \endif
\if :{?p_curso}       \else \set p_curso       'MAT-101'       \endif
\if :{?p_seccion}     \else \set p_seccion     'B'             \endif
\if :{?p_anio}        \else \set p_anio        2026            \endif
\if :{?p_periodo}     \else \set p_periodo     1               \endif
\if :{?p_ciclo_anio}  \else \set p_ciclo_anio  1               \endif
\if :{?p_ciclo_sem}   \else \set p_ciclo_sem   2               \endif
\if :{?p_ingreso_est} \else \set p_ingreso_est 'STU-2025-0003' \endif

-- ---------------------------------------------------------------------
\echo '== Q01 · Alumnos de una carrera =='
-- Propósito: listado general de alumnos por carrera (reporte 3a del PDF).
-- Parámetros: p_carrera (CAR_CODIGO).
-- Grano: un registro por PROGRAMA (EPR). Un estudiante con dos programas
-- históricos aparecería dos veces; por eso se muestra EPR_ESTADO y se
-- ordena primero por estado. Para "alumnos actuales" filtrar EPR_ESTADO = 'ACTIVO'.
-- Esperado (BCL-COMP): 19 filas, todas ACTIVO (10 cohorte 2025, 8 cohorte 2026, 1 registrado sin períodos ni resultados).
-- ---------------------------------------------------------------------
SELECT e.EST_CODIGO, e.EST_APELLIDOS || ', ' || e.EST_NOMBRES AS estudiante,
       p.PEN_CODIGO, r.EPR_FECHA_INICIO, r.EPR_ESTADO
FROM SIS_ACA_CARRERA c
JOIN SIS_ACA_PENSUM p              ON p.PEN_CAR_ID = c.CAR_ID
JOIN SIS_ACA_ESTUDIANTE_PROGRAMA r ON r.EPR_PEN_ID = p.PEN_ID
JOIN SIS_ACA_ESTUDIANTE e          ON e.EST_ID = r.EPR_EST_ID
WHERE c.CAR_CODIGO = :'p_carrera'
ORDER BY r.EPR_ESTADO, e.EST_APELLIDOS, e.EST_NOMBRES;

-- ---------------------------------------------------------------------
\echo '== Q02 · Buscar alumno por código =='
-- Propósito: búsqueda exacta (usa UQ_EST_CODIGO).
-- Parámetros: p_estudiante.
-- Esperado (STU-2025-0004): 1 fila, Diego Alejandro Batz Coyoy, Computación, ACTIVO.
-- (Búsqueda por apellido: WHERE lower(EST_APELLIDOS) LIKE lower(:texto) || '%', usa IX_EST_BUSQUEDA_APELLIDOS.)
-- ---------------------------------------------------------------------
SELECT e.EST_ID, e.EST_CODIGO, e.EST_NOMBRES, e.EST_APELLIDOS, c.CAR_NOMBRE, r.EPR_ESTADO
FROM SIS_ACA_ESTUDIANTE e
LEFT JOIN SIS_ACA_ESTUDIANTE_PROGRAMA r ON r.EPR_EST_ID = e.EST_ID AND r.EPR_ESTADO = 'ACTIVO'
LEFT JOIN SIS_ACA_PENSUM p              ON p.PEN_ID = r.EPR_PEN_ID
LEFT JOIN SIS_ACA_CARRERA c             ON c.CAR_ID = p.PEN_CAR_ID
WHERE e.EST_CODIGO = :'p_estudiante';

-- ---------------------------------------------------------------------
\echo '== Q03 · Ficha completa del alumno =='
-- Propósito: consulta en pantalla (reporte 3c del PDF): datos personales,
-- carrera, pensum, ubicación en el último período y avance.
-- Parámetros: p_estudiante.
-- Esperado (STU-2025-0004): Computación · Pensum 2025 · último período
-- 2026 / Semestre II · Año 2 / Semestre II · sección B · avance 100 %.
-- ---------------------------------------------------------------------
SELECT e.EST_CODIGO, e.EST_NOMBRES, e.EST_APELLIDOS, e.EST_FECHA_NACIMIENTO, e.EST_FOTO_RUTA,
       c.CAR_NOMBRE, p.PEN_NOMBRE, r.EPR_FECHA_INICIO, r.EPR_ESTADO,
       ult.periodo AS ultimo_periodo, ult.CIC_NOMBRE AS ciclo_actual, ult.SEC_CODIGO AS seccion_actual,
       a.AVA_CURSOS_APROBADOS, a.AVA_CURSOS_OBLIGATORIOS, a.AVA_PORCENTAJE
FROM SIS_ACA_ESTUDIANTE e
JOIN SIS_ACA_ESTUDIANTE_PROGRAMA r ON r.EPR_EST_ID = e.EST_ID
JOIN SIS_ACA_PENSUM p              ON p.PEN_ID = r.EPR_PEN_ID
JOIN SIS_ACA_CARRERA c             ON c.CAR_ID = p.PEN_CAR_ID
JOIN SIS_ACA_VW_AVANCE_PENSUM a    ON a.EPR_ID = r.EPR_ID
LEFT JOIN LATERAL (
    SELECT n.ANL_ANIO || ' / ' || pe.PER_NOMBRE AS periodo, k.CIC_NOMBRE, s.SEC_CODIGO
    FROM SIS_ACA_ESTUDIANTE_PERIODO x
    JOIN SIS_ACA_PERIODO_ACADEMICO pe ON pe.PER_ID = x.EPE_PER_ID
    JOIN SIS_ACA_ANIO_LECTIVO n       ON n.ANL_ID = pe.PER_ANL_ID
    JOIN SIS_ACA_CICLO_CURRICULAR k   ON k.CIC_ID = x.EPE_CIC_ID
    JOIN SIS_ACA_SECCION s            ON s.SEC_ID = x.EPE_SEC_ID
    WHERE x.EPE_EPR_ID = r.EPR_ID
    ORDER BY pe.PER_FECHA_INICIO DESC
    LIMIT 1
) ult ON true
WHERE e.EST_CODIGO = :'p_estudiante';

-- ---------------------------------------------------------------------
\echo '== Q04 · Historial completo de notas =='
-- Propósito: historial cronológico con intento, estado y política aplicada.
-- Parámetros: p_estudiante.
-- Esperado (STU-2025-0004): 21 filas = 20 cursos + 1 repitencia.
-- PRG-101 aparece dos veces: 2025/Semestre I nota 52 REPROBADO (intento 1)
-- y 2026/Semestre I nota 74 APROBADO (intento 2).
-- ---------------------------------------------------------------------
SELECT ANL_ANIO, PER_NOMBRE, CIC_NOMBRE, CUR_CODIGO, CUR_NOMBRE, SEC_CODIGO,
       RES_NOTA, POL_NOTA_APROBACION, RES_ESTADO, RES_NUMERO_INTENTO
FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE
WHERE EST_CODIGO = :'p_estudiante'
ORDER BY PER_FECHA_INICIO, CIC_ANIO, CIC_SEMESTRE, CUR_CODIGO;

-- ---------------------------------------------------------------------
\echo '== Q05 · Notas de una carrera =='
-- Propósito: base del reporte por carrera (resumen por período).
-- Parámetros: p_carrera.
-- Esperado (BCL-COMP): 4 períodos; ver tabla en E2_ENTREGA §5.
-- ---------------------------------------------------------------------
SELECT ANL_ANIO, PER_NOMBRE, count(*) AS resultados, count(RES_NOTA) AS calificados,
       round(avg(RES_NOTA), 2) AS promedio
FROM SIS_ACA_VW_REPORTE_NOTAS
WHERE CAR_CODIGO = :'p_carrera'
GROUP BY ANL_ANIO, PER_NOMBRE, PER_FECHA_INICIO
ORDER BY PER_FECHA_INICIO;

-- ---------------------------------------------------------------------
\echo '== Q06 · Notas de un curso =='
-- Propósito: todas las notas de un curso (todas las carreras y períodos).
-- Parámetros: p_curso.
-- Esperado (MAT-101): curso compartido por las 3 carreras; incluye los dos
-- intentos de STU-2025-0005 (48 y 57) y la frontera 60 de STU-2026-0003.
-- ---------------------------------------------------------------------
SELECT CAR_CODIGO, ANL_ANIO, PER_NOMBRE, SEC_CODIGO, EST_CODIGO, EST_NOMBRE_COMPLETO, RES_NOTA, RES_ESTADO, RES_NUMERO_INTENTO
FROM SIS_ACA_VW_REPORTE_NOTAS
WHERE CUR_CODIGO = :'p_curso'
ORDER BY PER_FECHA_INICIO, CAR_CODIGO, SEC_CODIGO, EST_CODIGO;

-- ---------------------------------------------------------------------
\echo '== Q07 · Notas de una sección (en un período) =='
-- Parámetros: p_seccion, p_anio, p_periodo.
-- Esperado (B, 2026-I): alumnos de la sección B de todas las carreras en 2026/Semestre I.
-- ---------------------------------------------------------------------
SELECT CAR_CODIGO, CUR_CODIGO, EST_CODIGO, EST_NOMBRE_COMPLETO, RES_NOTA, RES_ESTADO
FROM SIS_ACA_VW_REPORTE_NOTAS v
JOIN SIS_ACA_PERIODO_ACADEMICO p ON p.PER_ID = v.PER_ID
WHERE v.SEC_CODIGO = :'p_seccion' AND v.ANL_ANIO = :p_anio AND p.PER_NUMERO = :p_periodo
ORDER BY CAR_CODIGO, CUR_CODIGO, EST_CODIGO;

-- ---------------------------------------------------------------------
\echo '== Q08 · Notas por carrera + curso + sección (reporte 3b del PDF) =='
-- Parámetros: p_carrera, p_curso, p_seccion.
-- Esperado (BCL-COMP, MAT-101, B): 10 filas. 2025-I: 5 alumnos de la cohorte 2025 (STU-2025-0005 = 48,
-- STU-2025-0010 = 53 reprueban). 2026-I: 4 de la cohorte 2026 + la repitencia de STU-2025-0005 (57, intento 2).
-- ---------------------------------------------------------------------
SELECT ANL_ANIO, PER_NOMBRE, EST_CODIGO, EST_NOMBRE_COMPLETO, RES_NOTA, RES_ESTADO, RES_NUMERO_INTENTO
FROM SIS_ACA_VW_REPORTE_NOTAS
WHERE CAR_CODIGO = :'p_carrera' AND CUR_CODIGO = :'p_curso' AND SEC_CODIGO = :'p_seccion'
ORDER BY PER_FECHA_INICIO, EST_CODIGO;

-- ---------------------------------------------------------------------
\echo '== Q09 · Promedio de notas por carrera =='
-- Solo notas registradas (AVG ignora NULL: los pendientes no bajan el promedio).
-- ---------------------------------------------------------------------
SELECT CAR_NOMBRE, count(RES_NOTA) AS notas, round(avg(RES_NOTA), 2) AS promedio,
       min(RES_NOTA) AS minima, max(RES_NOTA) AS maxima
FROM SIS_ACA_VW_REPORTE_NOTAS
GROUP BY CAR_NOMBRE
ORDER BY promedio DESC;

-- ---------------------------------------------------------------------
\echo '== Q10 · Promedio por curso =='
-- Esperado: los cursos de Matemática y Física (dificultad alta) al final.
-- ---------------------------------------------------------------------
SELECT CUR_CODIGO, CUR_NOMBRE, count(RES_NOTA) AS notas, round(avg(RES_NOTA), 2) AS promedio
FROM SIS_ACA_VW_REPORTE_NOTAS
GROUP BY CUR_CODIGO, CUR_NOMBRE
HAVING count(RES_NOTA) > 0
ORDER BY promedio DESC, CUR_CODIGO;

-- ---------------------------------------------------------------------
\echo '== Q11 · Tasa de aprobación POR INTENTO, por carrera =='
-- MÉTRICA POR INTENTO (no por estudiante ni por curso único): cada fila de
-- RESULTADO_CURSO calificada cuenta una vez. Ej.: CASO D (52 → 74) aporta
-- 1 reprobado + 1 aprobado. Para "cursos aprobados por estudiante" use
-- SIS_ACA_VW_INTENTO_CURSO / VW_AVANCE_* (un curso cuenta una sola vez).
-- Denominador = intentos CALIFICADOS (los PENDIENTES no cuentan como reprobados).
-- Se mide por intento: un curso reprobado y luego aprobado aporta 1 reprobado + 1 aprobado.
-- ---------------------------------------------------------------------
SELECT CAR_NOMBRE,
       count(*) FILTER (WHERE RES_ESTADO = 'APROBADO')  AS aprobados,
       count(*) FILTER (WHERE RES_ESTADO = 'REPROBADO') AS reprobados,
       count(*) FILTER (WHERE RES_ESTADO = 'PENDIENTE') AS pendientes,
       round(100.0 * count(*) FILTER (WHERE RES_ESTADO = 'APROBADO')
             / NULLIF(count(*) FILTER (WHERE RES_ESTADO <> 'PENDIENTE'), 0), 2) AS tasa_aprobacion
FROM SIS_ACA_VW_REPORTE_NOTAS
GROUP BY CAR_NOMBRE
ORDER BY tasa_aprobacion DESC;

-- ---------------------------------------------------------------------
\echo '== Q12 · Tasa de aprobación POR INTENTO, por curso =='
-- MÉTRICA POR INTENTO (misma definición que Q11): denominador = intentos
-- calificados del curso; los PENDIENTES no cuentan.
-- ---------------------------------------------------------------------
SELECT CUR_CODIGO, CUR_NOMBRE,
       count(*) FILTER (WHERE RES_ESTADO <> 'PENDIENTE') AS calificados,
       count(*) FILTER (WHERE RES_ESTADO = 'REPROBADO')  AS reprobados,
       round(100.0 * count(*) FILTER (WHERE RES_ESTADO = 'APROBADO')
             / NULLIF(count(*) FILTER (WHERE RES_ESTADO <> 'PENDIENTE'), 0), 2) AS tasa_aprobacion
FROM SIS_ACA_VW_REPORTE_NOTAS
GROUP BY CUR_CODIGO, CUR_NOMBRE
HAVING count(*) FILTER (WHERE RES_ESTADO <> 'PENDIENTE') > 0
ORDER BY tasa_aprobacion, CUR_CODIGO;

-- ---------------------------------------------------------------------
\echo '== Q13 · Tasa de aprobación POR INTENTO, por sección (y período) =='
-- ---------------------------------------------------------------------
SELECT ANL_ANIO, PER_NOMBRE, SEC_CODIGO,
       count(DISTINCT EST_ID) AS estudiantes,
       count(*) FILTER (WHERE RES_ESTADO <> 'PENDIENTE') AS calificados,
       round(100.0 * count(*) FILTER (WHERE RES_ESTADO = 'APROBADO')
             / NULLIF(count(*) FILTER (WHERE RES_ESTADO <> 'PENDIENTE'), 0), 2) AS tasa_aprobacion
FROM SIS_ACA_VW_REPORTE_NOTAS
GROUP BY ANL_ANIO, PER_NOMBRE, PER_FECHA_INICIO, SEC_CODIGO
ORDER BY PER_FECHA_INICIO, SEC_CODIGO;

-- ---------------------------------------------------------------------
\echo '== Q14 · Cursos reprobados por estudiante =='
-- Muestra cada intento reprobado y si el curso se aprobó después.
-- Parámetros: ninguno (todos los estudiantes con al menos un reprobado).
-- Esperado: STU-2025-0004 (PRG-101, luego aprobado), STU-2025-0005 (MAT-101 ×2, sin aprobar), etc.
-- ---------------------------------------------------------------------
SELECT v.EST_CODIGO, v.EST_NOMBRE_COMPLETO, v.CUR_CODIGO, v.ANL_ANIO, v.PER_NOMBRE, v.RES_NOTA,
       v.RES_NUMERO_INTENTO, i.RES_SITUACION AS situacion_actual_del_curso
FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE v
JOIN SIS_ACA_VW_INTENTO_CURSO i ON i.EPR_ID = v.EPR_ID AND i.PCU_ID = v.PCU_ID
WHERE v.RES_ESTADO = 'REPROBADO'
ORDER BY v.EST_CODIGO, v.PER_FECHA_INICIO, v.CUR_CODIGO;

-- ---------------------------------------------------------------------
\echo '== Q15 · Cursos pendientes de un estudiante =='
-- Obligatorios del pensum sin intento aprobado: NO_CURSADO, EN_CURSO o REPROBADO.
-- Parámetros: p_estudiante.
-- Esperado (STU-2025-0005, si se pasa -v p_estudiante=STU-2025-0005): 4 cursos, entre ellos MAT-101 (REPROBADO, 2 intentos).
-- Esperado (STU-2025-0004, por defecto): 0 filas (pensum completo).
-- ---------------------------------------------------------------------
SELECT k.CIC_NOMBRE, cu.CUR_CODIGO, cu.CUR_NOMBRE,
       COALESCE(i.RES_SITUACION, 'NO_CURSADO') AS situacion,
       COALESCE(i.RES_TOTAL_INTENTOS, 0)       AS intentos,
       i.RES_MEJOR_NOTA
FROM SIS_ACA_ESTUDIANTE e
JOIN SIS_ACA_ESTUDIANTE_PROGRAMA r ON r.EPR_EST_ID = e.EST_ID
JOIN SIS_ACA_PENSUM_CURSO c        ON c.PCU_PEN_ID = r.EPR_PEN_ID AND c.PCU_OBLIGATORIO
JOIN SIS_ACA_CURSO cu              ON cu.CUR_ID = c.PCU_CUR_ID
JOIN SIS_ACA_CICLO_CURRICULAR k    ON k.CIC_ID = c.PCU_CIC_ID
LEFT JOIN SIS_ACA_VW_INTENTO_CURSO i ON i.EPR_ID = r.EPR_ID AND i.PCU_ID = c.PCU_ID
WHERE e.EST_CODIGO = :'p_estudiante'
  AND NOT COALESCE(i.RES_APROBADO, false)
ORDER BY k.CIC_ANIO, k.CIC_SEMESTRE, c.PCU_ORDEN;

-- ---------------------------------------------------------------------
\echo '== Q16 · Cursos repetidos =='
-- Esperado: 2 filas — STU-2025-0004 PRG-101 (APROBADO) y STU-2025-0005 MAT-101 (REPROBADO).
-- ---------------------------------------------------------------------
SELECT EST_CODIGO, EST_NOMBRE_COMPLETO, CUR_CODIGO, CUR_NOMBRE, RES_TOTAL_INTENTOS,
       RES_PRIMERA_NOTA, RES_ULTIMA_NOTA, RES_MEJOR_NOTA, RES_SITUACION, PER_NOMBRE_APROBACION
FROM SIS_ACA_VW_INTENTO_CURSO
WHERE RES_TOTAL_INTENTOS > 1
ORDER BY EST_CODIGO, CUR_CODIGO;

-- ---------------------------------------------------------------------
\echo '== Q17 · Cantidad de intentos por curso de un estudiante =='
-- Parámetros: p_estudiante.
-- Esperado (STU-2025-0004): 20 cursos; PRG-101 con 2 intentos (52 → 74), el resto con 1.
-- ---------------------------------------------------------------------
SELECT CUR_CODIGO, CUR_NOMBRE, RES_TOTAL_INTENTOS, RES_PRIMERA_NOTA, RES_ULTIMA_NOTA,
       RES_MEJOR_NOTA, RES_SITUACION, PER_NOMBRE_APROBACION
FROM SIS_ACA_VW_INTENTO_CURSO
WHERE EST_CODIGO = :'p_estudiante'
ORDER BY RES_TOTAL_INTENTOS DESC, CUR_CODIGO;

-- ---------------------------------------------------------------------
\echo '== Q18 · Avance global del pensum (todos los programas) =='
-- Esperado: 17 programas al 100 % (graduandos 2025); STU-2026-0019 al 0 %.
-- ---------------------------------------------------------------------
SELECT EST_CODIGO, EST_NOMBRE_COMPLETO, CAR_NOMBRE, EPR_ESTADO, AVA_CURSOS_OBLIGATORIOS,
       AVA_CURSOS_APROBADOS, AVA_CURSOS_PENDIENTES, AVA_PORCENTAJE
FROM SIS_ACA_VW_AVANCE_PENSUM
ORDER BY AVA_PORCENTAJE DESC, EST_CODIGO;

-- ---------------------------------------------------------------------
\echo '== Q19 · Avance por ciclo de un estudiante =='
-- Parámetros: p_estudiante.
-- Esperado (STU-2025-0004): 4 ciclos COMPLETO (Año 1/Sem I se completó al aprobar PRG-101 en 2026).
-- ---------------------------------------------------------------------
SELECT CIC_NOMBRE, AVA_CURSOS_OBLIGATORIOS, AVA_CURSOS_APROBADOS, AVA_CURSOS_PENDIENTES,
       AVA_PORCENTAJE, AVA_ESTADO_CICLO
FROM SIS_ACA_VW_AVANCE_CICLO
WHERE EST_CODIGO = :'p_estudiante'
ORDER BY CIC_ANIO, CIC_SEMESTRE;

-- ---------------------------------------------------------------------
\echo '== Q20 · ¿Está completo un ciclo curricular? (todos los estudiantes) =='
-- Parámetros: p_ciclo_anio, p_ciclo_sem.
-- Esperado (Año 1 / Semestre II): 45 filas. Cohorte 2025 INCOMPLETO: STU-2025-0003 (MAT-102 = 60),
-- STU-2025-0007 (ING-102 = 58), 0010, 0014, 0018, 0020, 0024 (reprobaciones del perfil bajo).
-- Cohorte 2026: INCOMPLETO por estar en curso (notas pendientes en 2026-II), salvo STU-2026-0019 (sin cursar).
-- ---------------------------------------------------------------------
SELECT EST_CODIGO, EST_NOMBRE_COMPLETO, CAR_NOMBRE, AVA_CURSOS_APROBADOS || '/' || AVA_CURSOS_OBLIGATORIOS AS aprobados,
       AVA_ESTADO_CICLO
FROM SIS_ACA_VW_AVANCE_CICLO
WHERE CIC_ANIO = :p_ciclo_anio AND CIC_SEMESTRE = :p_ciclo_sem
ORDER BY AVA_ESTADO_CICLO DESC, EST_CODIGO;

-- ---------------------------------------------------------------------
\echo '== Q21 · Estudiantes con cursos pendientes de ciclos ANTERIORES =='
-- "Anterior" = ciclo previo al ciclo del último período cursado por el programa.
-- Solo programas ACTIVOS.
-- Esperado: 12 filas. Encabeza STU-2025-0018 y STU-2025-0024 (5 cursos cada uno); incluye
-- STU-2025-0005 (MAT-101, PRG-101, FIS-101, MAT-201), STU-2025-0003 (MAT-102) y STU-2025-0007 (ING-102).
-- ---------------------------------------------------------------------
WITH ciclo_actual AS (
    SELECT DISTINCT ON (x.EPE_EPR_ID) x.EPE_EPR_ID AS EPR_ID, k.CIC_ANIO, k.CIC_SEMESTRE, k.CIC_NOMBRE
    FROM SIS_ACA_ESTUDIANTE_PERIODO x
    JOIN SIS_ACA_PERIODO_ACADEMICO p ON p.PER_ID = x.EPE_PER_ID
    JOIN SIS_ACA_CICLO_CURRICULAR k  ON k.CIC_ID = x.EPE_CIC_ID
    ORDER BY x.EPE_EPR_ID, p.PER_FECHA_INICIO DESC
)
SELECT e.EST_CODIGO, e.EST_APELLIDOS || ', ' || e.EST_NOMBRES AS estudiante, ca.CIC_NOMBRE AS ciclo_actual,
       count(*) AS cursos_pendientes_anteriores,
       string_agg(cu.CUR_CODIGO, ', ' ORDER BY k.CIC_ANIO, k.CIC_SEMESTRE, c.PCU_ORDEN) AS cursos
FROM ciclo_actual ca
JOIN SIS_ACA_ESTUDIANTE_PROGRAMA r ON r.EPR_ID = ca.EPR_ID AND r.EPR_ESTADO = 'ACTIVO'
JOIN SIS_ACA_ESTUDIANTE e          ON e.EST_ID = r.EPR_EST_ID
JOIN SIS_ACA_PENSUM_CURSO c        ON c.PCU_PEN_ID = r.EPR_PEN_ID AND c.PCU_OBLIGATORIO
JOIN SIS_ACA_CICLO_CURRICULAR k    ON k.CIC_ID = c.PCU_CIC_ID
                                  AND (k.CIC_ANIO, k.CIC_SEMESTRE) < (ca.CIC_ANIO, ca.CIC_SEMESTRE)
JOIN SIS_ACA_CURSO cu              ON cu.CUR_ID = c.PCU_CUR_ID
LEFT JOIN SIS_ACA_VW_INTENTO_CURSO i ON i.EPR_ID = r.EPR_ID AND i.PCU_ID = c.PCU_ID
WHERE NOT COALESCE(i.RES_APROBADO, false)
GROUP BY e.EST_CODIGO, e.EST_APELLIDOS, e.EST_NOMBRES, ca.CIC_NOMBRE
ORDER BY cursos_pendientes_anteriores DESC, e.EST_CODIGO;

-- ---------------------------------------------------------------------
\echo '== Q22 · Estudiantes que completaron todo su pensum =='
-- Esperado: 17 estudiantes de la cohorte 2025 (todos los obligatorios aprobados).
-- Nota: EPR_ESTADO sigue ACTIVO porque 2026-II no ha cerrado; marcarlo
-- FINALIZADO es un acto administrativo posterior al cierre.
-- ---------------------------------------------------------------------
SELECT EST_CODIGO, EST_NOMBRE_COMPLETO, CAR_NOMBRE, AVA_CURSOS_APROBADOS, EPR_ESTADO
FROM SIS_ACA_VW_AVANCE_PENSUM
WHERE AVA_PENSUM_COMPLETO
ORDER BY CAR_NOMBRE, EST_CODIGO;

-- ---------------------------------------------------------------------
\echo '== Q23 · Comparación entre períodos académicos =='
-- pct_calificados = intentos con nota / intentos totales: indica qué tan
-- completo está el registro del período. Leer tasa_aprobacion junto a él:
-- 2026-II muestra 98.58 % de aprobación, pero solo sobre el 63.51 % de
-- intentos ya calificados (los pendientes aún no cuentan).
-- tasa_aprobacion es POR INTENTO (ver Q11).
-- Esperado: 2025-I y 2025-II y 2026-I al 100 % calificados; 2026-II al 63.51 %.
-- ---------------------------------------------------------------------
SELECT ANL_ANIO, PER_NOMBRE, POL_CODIGO,
       count(DISTINCT EST_ID) AS estudiantes,
       count(*) AS intentos,
       count(RES_NOTA) AS calificados,
       count(*) FILTER (WHERE RES_ESTADO = 'PENDIENTE') AS pendientes,
       round(100.0 * count(RES_NOTA) / NULLIF(count(*), 0), 2) AS pct_calificados,
       round(avg(RES_NOTA), 2) AS promedio,
       round(100.0 * count(*) FILTER (WHERE RES_ESTADO = 'APROBADO')
             / NULLIF(count(RES_NOTA), 0), 2) AS tasa_aprobacion
FROM SIS_ACA_VW_REPORTE_NOTAS
GROUP BY ANL_ANIO, PER_NOMBRE, PER_FECHA_INICIO, POL_CODIGO
ORDER BY PER_FECHA_INICIO;

-- ---------------------------------------------------------------------
\echo '== Q24 · Resultados con la política histórica =='
-- Cada nota se evalúa con la política DEL PERÍODO en que se cursó.
-- La columna "si_se_evaluara_con_2028" es solo ilustrativa: muestra qué
-- pasaría si (incorrectamente) se aplicara la regla futura de 70.
-- Esperado: notas entre 61 y 69.99 → APROBADO con su política histórica
-- (61) aunque serían REPROBADO con POL-2028 (70). Su estado real NO cambia.
-- ---------------------------------------------------------------------
SELECT v.EST_CODIGO, v.CUR_CODIGO, v.ANL_ANIO, v.PER_NOMBRE, v.RES_NOTA,
       v.POL_CODIGO, v.POL_NOTA_APROBACION, v.RES_ESTADO AS estado_real,
       CASE WHEN v.RES_NOTA >= f.POL_NOTA_APROBACION THEN 'APROBADO' ELSE 'REPROBADO' END AS si_se_evaluara_con_2028
FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE v
CROSS JOIN (SELECT POL_NOTA_APROBACION FROM SIS_ACA_POLITICA_ACADEMICA WHERE POL_CODIGO = 'POL-2028-01') f
WHERE v.RES_NOTA >= 61 AND v.RES_NOTA < 70
ORDER BY v.RES_NOTA, v.EST_CODIGO, v.CUR_CODIGO
LIMIT 15;

SELECT POL_CODIGO, POL_NOTA_APROBACION, POL_VIGENTE_DESDE, POL_VIGENTE_HASTA
FROM SIS_ACA_VW_POLITICA_LINEA_TIEMPO ORDER BY POL_VIGENTE_DESDE;

-- ---------------------------------------------------------------------
\echo '== Q25 · Pantalla de ingreso de notas (estudiante en el período ABIERTO) =='
-- Parámetros: p_ingreso_est (el período es el ABIERTO).
-- Esperado (STU-2025-0003, 2026-II): los 5 cursos de Año 2 / Semestre II
-- (ya calificados, editables) + MAT-102 descubierto como CICLO_ANTERIOR /
-- SIN_REGISTRO, editable: reprobó con 60 en 2025 y existe oferta activa
-- de MAT-102 en su sección A en 2026-II.
-- ---------------------------------------------------------------------
SELECT i.CUR_CODIGO, i.CUR_NOMBRE, i.PCU_CIC_NOMBRE, i.ING_ORIGEN, i.SEC_CODIGO,
       i.RES_NOTA, i.ING_ESTADO, i.ING_EDITABLE, i.ING_MOTIVO_BLOQUEO, i.OFE_ID
FROM SIS_ACA_VW_INGRESO_NOTAS i
WHERE i.EST_CODIGO = :'p_ingreso_est' AND i.PER_ESTADO = 'ABIERTO'
ORDER BY i.ING_ORIGEN DESC, i.PCU_ORDEN;
