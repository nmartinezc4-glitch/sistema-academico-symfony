-- =====================================================================
--  10_validation_queries.sql — E3 · Diagnósticos semánticos (§34)
--
--  Consultas de SOLO LECTURA que buscan datos que los constraints y
--  triggers no pueden impedir por sí solos (o que conviene vigilar aunque
--  estén impedidos). Cada diagnóstico devuelve las filas problemáticas.
--
--    D-xx  INTEGRIDAD  → esperado 0 filas. Si aparece alguna: FAIL.
--    I-xx  INFORMATIVO → valor esperado conocido del dataset demostrativo.
--
--  Uso:  psql -d sistema_academico_dev -f 10_validation_queries.sql
--  Imprime un resumen (diagnóstico, encontrados, esperado, resultado) y el
--  detalle de los diagnósticos informativos. Termina con ROLLBACK.
--
--  Symfony puede reutilizar cualquier D-xx como chequeo de salud
--  (p. ej. un comando de consola "app:diagnostico").
-- =====================================================================
\set ON_ERROR_STOP on
\set QUIET on
\pset null '·'
\pset tuples_only off
\pset format aligned
BEGIN;

CREATE TEMP VIEW r AS SELECT * FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE;

-- ---------------------------------------------------------------------
-- Política y calendario
-- ---------------------------------------------------------------------
-- D01 · Políticas solapadas (dos políticas con la misma fecha de inicio).
--       La vigencia es derivada (LEAD), así que solo puede solaparse si
--       coinciden en POL_VIGENTE_DESDE. UQ_POL_VIGENTE_DESDE lo impide.
CREATE TEMP VIEW d01 AS
SELECT POL_VIGENTE_DESDE, string_agg(POL_CODIGO, ', ') AS politicas
FROM SIS_ACA_POLITICA_ACADEMICA GROUP BY POL_VIGENTE_DESDE HAVING count(*) > 1;

-- D02 · Períodos cuya política no es la vigente en su fecha de inicio (T3).
CREATE TEMP VIEW d02 AS
SELECT p.PER_ID, p.PER_NOMBRE, p.PER_FECHA_INICIO, p.PER_POL_ID, SIS_ACA_FN_POLITICA_VIGENTE(p.PER_FECHA_INICIO) AS vigente
FROM SIS_ACA_PERIODO_ACADEMICO p
WHERE p.PER_POL_ID IS DISTINCT FROM SIS_ACA_FN_POLITICA_VIGENTE(p.PER_FECHA_INICIO);

-- D03 · Períodos fuera de las fechas de su año lectivo (D3).
--       DF3: se mantiene como diagnóstico; VALIDACIÓN OBLIGATORIA en Symfony
--       (formulario de período: inicio y fin dentro del año lectivo).
CREATE TEMP VIEW d03 AS
SELECT a.ANL_ANIO, p.PER_NOMBRE, p.PER_FECHA_INICIO, p.PER_FECHA_FIN, a.ANL_FECHA_INICIO, a.ANL_FECHA_FIN
FROM SIS_ACA_PERIODO_ACADEMICO p JOIN SIS_ACA_ANIO_LECTIVO a ON a.ANL_ID = p.PER_ANL_ID
WHERE p.PER_FECHA_INICIO < a.ANL_FECHA_INICIO OR p.PER_FECHA_FIN > a.ANL_FECHA_FIN;

-- D04 · Períodos solapados dentro del mismo año lectivo (D3).
--       DF3: diagnóstico; VALIDACIÓN OBLIGATORIA en Symfony (sin solapes en el año).
CREATE TEMP VIEW d04 AS
SELECT p1.PER_ANL_ID, p1.PER_NOMBRE AS periodo_1, p2.PER_NOMBRE AS periodo_2
FROM SIS_ACA_PERIODO_ACADEMICO p1
JOIN SIS_ACA_PERIODO_ACADEMICO p2 ON p2.PER_ANL_ID = p1.PER_ANL_ID AND p2.PER_ID > p1.PER_ID
WHERE p1.PER_FECHA_INICIO <= p2.PER_FECHA_FIN AND p2.PER_FECHA_INICIO <= p1.PER_FECHA_FIN;

-- ---------------------------------------------------------------------
-- Pensum y asignación del estudiante
-- ---------------------------------------------------------------------
-- D05 · Pensums sin cursos asignados (pensum incoherente).
CREATE TEMP VIEW d05 AS
SELECT p.PEN_CODIGO FROM SIS_ACA_PENSUM p
WHERE NOT EXISTS (SELECT 1 FROM SIS_ACA_PENSUM_CURSO c WHERE c.PCU_PEN_ID = p.PEN_ID);

-- D06 · Cursos duplicados dentro de un pensum (UQ_PCU_PEN_CUR lo impide).
CREATE TEMP VIEW d06 AS
SELECT PCU_PEN_ID, PCU_CUR_ID, count(*) AS veces
FROM SIS_ACA_PENSUM_CURSO GROUP BY PCU_PEN_ID, PCU_CUR_ID HAVING count(*) > 1;

-- D07 · Programas iniciados fuera de la ventana de admisión del pensum
--       (estudiante asignado a un pensum que no correspondía en esa fecha).
CREATE TEMP VIEW d07 AS
SELECT e.EST_CODIGO, p.PEN_CODIGO, r.EPR_FECHA_INICIO, p.PEN_VIGENTE_DESDE, p.PEN_VIGENTE_HASTA
FROM SIS_ACA_ESTUDIANTE_PROGRAMA r
JOIN SIS_ACA_PENSUM p     ON p.PEN_ID = r.EPR_PEN_ID
JOIN SIS_ACA_ESTUDIANTE e ON e.EST_ID = r.EPR_EST_ID
WHERE r.EPR_FECHA_INICIO < p.PEN_VIGENTE_DESDE
   OR (p.PEN_VIGENTE_HASTA IS NOT NULL AND r.EPR_FECHA_INICIO > p.PEN_VIGENTE_HASTA);

-- D08 · Estudiante ubicado en un ciclo que su pensum no usa (D4).
--       DF3: diagnóstico; VALIDACIÓN OBLIGATORIA en Symfony (el selector de
--       ciclo solo ofrece ciclos con cursos en el pensum del estudiante).
CREATE TEMP VIEW d08 AS
SELECT e.EPE_ID, s.EST_CODIGO, e.EPE_CIC_ID
FROM SIS_ACA_ESTUDIANTE_PERIODO e
JOIN SIS_ACA_ESTUDIANTE_PROGRAMA r ON r.EPR_ID = e.EPE_EPR_ID
JOIN SIS_ACA_ESTUDIANTE s          ON s.EST_ID = r.EPR_EST_ID
WHERE NOT EXISTS (SELECT 1 FROM SIS_ACA_PENSUM_CURSO c WHERE c.PCU_PEN_ID = r.EPR_PEN_ID AND c.PCU_CIC_ID = e.EPE_CIC_ID);

-- ---------------------------------------------------------------------
-- Resultados
-- ---------------------------------------------------------------------
-- D09 · Resultado cuyo estudiante-período y oferta están en períodos distintos (T2 SA201).
CREATE TEMP VIEW d09 AS
SELECT x.RES_ID FROM SIS_ACA_RESULTADO_CURSO x
JOIN SIS_ACA_ESTUDIANTE_PERIODO e ON e.EPE_ID = x.RES_EPE_ID
JOIN SIS_ACA_OFERTA_CURSO o       ON o.OFE_ID = x.RES_OFE_ID
WHERE e.EPE_PER_ID <> o.OFE_PER_ID;

-- D10 · Resultado de una oferta de otro pensum (T2 SA202).
CREATE TEMP VIEW d10 AS
SELECT x.RES_ID FROM SIS_ACA_RESULTADO_CURSO x
JOIN SIS_ACA_ESTUDIANTE_PERIODO e  ON e.EPE_ID = x.RES_EPE_ID
JOIN SIS_ACA_ESTUDIANTE_PROGRAMA r ON r.EPR_ID = e.EPE_EPR_ID
JOIN SIS_ACA_OFERTA_CURSO o        ON o.OFE_ID = x.RES_OFE_ID
JOIN SIS_ACA_PENSUM_CURSO c        ON c.PCU_ID = o.OFE_PCU_ID
WHERE r.EPR_PEN_ID <> c.PCU_PEN_ID;

-- D11 · Resultado en una oferta de otra sección (T2 SA203, regla S1).
CREATE TEMP VIEW d11 AS
SELECT x.RES_ID FROM SIS_ACA_RESULTADO_CURSO x
JOIN SIS_ACA_ESTUDIANTE_PERIODO e ON e.EPE_ID = x.RES_EPE_ID
JOIN SIS_ACA_OFERTA_CURSO o       ON o.OFE_ID = x.RES_OFE_ID
WHERE e.EPE_SEC_ID <> o.OFE_SEC_ID;

-- D12 · Notas sin contexto válido: nota en un período PLANIFICADO
--       (nunca abierto) o nota sin fecha de calificación.
CREATE TEMP VIEW d12 AS
SELECT x.RES_ID, p.PER_ESTADO, x.RES_NOTA, x.RES_CALIFICADO_EN
FROM SIS_ACA_RESULTADO_CURSO x
JOIN SIS_ACA_ESTUDIANTE_PERIODO e ON e.EPE_ID = x.RES_EPE_ID
JOIN SIS_ACA_PERIODO_ACADEMICO p  ON p.PER_ID = e.EPE_PER_ID
WHERE p.PER_ESTADO = 'PLANIFICADO'
   OR (x.RES_NOTA IS NULL) <> (x.RES_CALIFICADO_EN IS NULL);

-- D13 · Más de un intento del mismo curso en el mismo período.
CREATE TEMP VIEW d13 AS
SELECT EPR_ID, PCU_ID, PER_ID, count(*) AS intentos
FROM r GROUP BY EPR_ID, PCU_ID, PER_ID HAVING count(*) > 1;

-- D14 · Intento POSTERIOR a una aprobación del mismo curso.
--       Prevenido por T2 en sus dos vías: SA207 (nuevo intento tras una
--       aprobación) y SA208 (corrección que aprueba un intento histórico
--       con intentos posteriores, DF1). Se mantiene como DEFENSA EN
--       PROFUNDIDAD: detectaría datos cargados con triggers deshabilitados
--       o por una vía futura no prevista. Ver 11_negative_tests.sql §N7.
CREATE TEMP VIEW d14 AS
SELECT a.EST_CODIGO, a.CUR_CODIGO,
       a.ANL_ANIO || ' / ' || a.PER_NOMBRE AS aprobado_en, a.RES_NOTA AS nota_aprobada,
       b.ANL_ANIO || ' / ' || b.PER_NOMBRE AS intento_posterior_en, b.RES_NOTA AS nota_posterior, b.RES_ID AS res_id_posterior
FROM r a
JOIN r b ON b.EPR_ID = a.EPR_ID AND b.PCU_ID = a.PCU_ID AND b.PER_FECHA_INICIO > a.PER_FECHA_INICIO
WHERE a.RES_ESTADO = 'APROBADO';

-- ---------------------------------------------------------------------
-- Avance
-- ---------------------------------------------------------------------
-- D15 · Progreso superior a 100 %.
CREATE TEMP VIEW d15 AS
SELECT EST_CODIGO, AVA_PORCENTAJE FROM SIS_ACA_VW_AVANCE_PENSUM WHERE AVA_PORCENTAJE > 100
UNION ALL
SELECT EST_CODIGO, AVA_PORCENTAJE FROM SIS_ACA_VW_AVANCE_CICLO  WHERE AVA_PORCENTAJE > 100;

-- D16 · Cursos aprobados contados más de una vez: el avance de la vista
--       debe coincidir con el número de cursos obligatorios DISTINTOS
--       que tienen al menos un intento aprobado (recalculado aquí sin vistas de avance).
CREATE TEMP VIEW d16 AS
SELECT a.EST_CODIGO, a.AVA_CURSOS_APROBADOS, COALESCE(x.distintos, 0) AS recalculado
FROM SIS_ACA_VW_AVANCE_PENSUM a
LEFT JOIN (SELECT EPR_ID, count(DISTINCT PCU_ID) AS distintos
           FROM r WHERE RES_ESTADO = 'APROBADO' AND PCU_OBLIGATORIO GROUP BY EPR_ID) x ON x.EPR_ID = a.EPR_ID
WHERE a.AVA_CURSOS_APROBADOS <> COALESCE(x.distintos, 0);

-- D17 · Períodos CERRADOS con estudiantes aún INSCRITO.
CREATE TEMP VIEW d17 AS
SELECT p.PER_NOMBRE, count(*) AS inscritos
FROM SIS_ACA_ESTUDIANTE_PERIODO e JOIN SIS_ACA_PERIODO_ACADEMICO p ON p.PER_ID = e.EPE_PER_ID
WHERE p.PER_ESTADO = 'CERRADO' AND e.EPE_ESTADO = 'INSCRITO'
GROUP BY p.PER_NOMBRE;

-- D18 · Programas FINALIZADO sin el pensum completo.
CREATE TEMP VIEW d18 AS
SELECT EST_CODIGO, AVA_PORCENTAJE FROM SIS_ACA_VW_AVANCE_PENSUM
WHERE EPR_ESTADO = 'FINALIZADO' AND NOT AVA_PENSUM_COMPLETO;

-- ---------------------------------------------------------------------
-- Informativos (valor esperado conocido del dataset demostrativo)
-- ---------------------------------------------------------------------
-- I01 · Ciclos del catálogo que ningún pensum usa.
CREATE TEMP VIEW i01 AS
SELECT k.CIC_NOMBRE FROM SIS_ACA_CICLO_CURRICULAR k
WHERE NOT EXISTS (SELECT 1 FROM SIS_ACA_PENSUM_CURSO c WHERE c.PCU_CIC_ID = k.CIC_ID);

-- I02 · Ofertas sin alumnos (sin ningún resultado registrado).
CREATE TEMP VIEW i02 AS
SELECT o.OFE_ID FROM SIS_ACA_OFERTA_CURSO o
WHERE NOT EXISTS (SELECT 1 FROM SIS_ACA_RESULTADO_CURSO x WHERE x.RES_OFE_ID = o.OFE_ID);

-- I03 · Programas ACTIVOS registrados sin períodos ni resultados.
CREATE TEMP VIEW i03 AS
SELECT s.EST_CODIGO, r.EPR_FECHA_INICIO
FROM SIS_ACA_ESTUDIANTE_PROGRAMA r JOIN SIS_ACA_ESTUDIANTE s ON s.EST_ID = r.EPR_EST_ID
WHERE r.EPR_ESTADO = 'ACTIVO'
  AND NOT EXISTS (SELECT 1 FROM SIS_ACA_ESTUDIANTE_PERIODO e WHERE e.EPE_EPR_ID = r.EPR_ID);

-- I04 · Pensum completo con programa aún ACTIVO (pendiente de cierre administrativo, E2-H2).
CREATE TEMP VIEW i04 AS
SELECT EST_CODIGO FROM SIS_ACA_VW_AVANCE_PENSUM WHERE AVA_PENSUM_COMPLETO AND EPR_ESTADO = 'ACTIVO';

-- I05 · Resultados pendientes (NULL) en períodos ABIERTOS.
CREATE TEMP VIEW i05 AS
SELECT RES_ID FROM r WHERE RES_ESTADO = 'PENDIENTE' AND PER_ESTADO = 'ABIERTO';

-- I06 · Pensums sin estudiantes.
CREATE TEMP VIEW i06 AS
SELECT p.PEN_CODIGO FROM SIS_ACA_PENSUM p
WHERE NOT EXISTS (SELECT 1 FROM SIS_ACA_ESTUDIANTE_PROGRAMA x WHERE x.EPR_PEN_ID = p.PEN_ID);

-- =====================================================================
\echo '== Resumen de diagnósticos =='
-- =====================================================================
CREATE TEMP VIEW resumen AS
SELECT codigo, tipo, descripcion, encontrados, esperado,
       CASE WHEN encontrados = esperado THEN (CASE tipo WHEN 'INTEGRIDAD' THEN 'PASS' ELSE 'OK' END) ELSE 'FAIL' END AS resultado
FROM (VALUES
  ('D01','INTEGRIDAD','Políticas solapadas',                                (SELECT count(*) FROM d01), 0),
  ('D02','INTEGRIDAD','Período con política distinta a la vigente',         (SELECT count(*) FROM d02), 0),
  ('D03','INTEGRIDAD','Período fuera de su año lectivo',                    (SELECT count(*) FROM d03), 0),
  ('D04','INTEGRIDAD','Períodos solapados en el mismo año',                 (SELECT count(*) FROM d04), 0),
  ('D05','INTEGRIDAD','Pensum sin cursos',                                  (SELECT count(*) FROM d05), 0),
  ('D06','INTEGRIDAD','Curso duplicado en un pensum',                       (SELECT count(*) FROM d06), 0),
  ('D07','INTEGRIDAD','Programa fuera de la ventana de admisión del pensum',(SELECT count(*) FROM d07), 0),
  ('D08','INTEGRIDAD','Estudiante en ciclo que su pensum no usa',           (SELECT count(*) FROM d08), 0),
  ('D09','INTEGRIDAD','Resultado con período incompatible',                 (SELECT count(*) FROM d09), 0),
  ('D10','INTEGRIDAD','Resultado de otro pensum',                           (SELECT count(*) FROM d10), 0),
  ('D11','INTEGRIDAD','Resultado de otra sección',                          (SELECT count(*) FROM d11), 0),
  ('D12','INTEGRIDAD','Nota sin contexto válido',                           (SELECT count(*) FROM d12), 0),
  ('D13','INTEGRIDAD','Dos intentos del mismo curso en un período',         (SELECT count(*) FROM d13), 0),
  ('D14','INTEGRIDAD','Intento posterior a una aprobación',                 (SELECT count(*) FROM d14), 0),
  ('D15','INTEGRIDAD','Progreso > 100 %',                                   (SELECT count(*) FROM d15), 0),
  ('D16','INTEGRIDAD','Curso aprobado contado más de una vez',              (SELECT count(*) FROM d16), 0),
  ('D17','INTEGRIDAD','Período CERRADO con estudiantes INSCRITO',           (SELECT count(*) FROM d17), 0),
  ('D18','INTEGRIDAD','Programa FINALIZADO sin pensum completo',            (SELECT count(*) FROM d18), 0),
  ('I01','INFORMATIVO','Ciclos sin cursos en ningún pensum',                (SELECT count(*) FROM i01), 0),
  ('I02','INFORMATIVO','Ofertas sin alumnos',                               (SELECT count(*) FROM i02), 0),
  ('I03','INFORMATIVO','Programas activos sin períodos ni resultados',      (SELECT count(*) FROM i03), 1),
  ('I04','INFORMATIVO','Pensum completo con programa ACTIVO',               (SELECT count(*) FROM i04), 17),
  ('I05','INFORMATIVO','Resultados pendientes en período ABIERTO',          (SELECT count(*) FROM i05), 81),
  ('I06','INFORMATIVO','Pensums sin estudiantes',                           (SELECT count(*) FROM i06), 1)
) x(codigo, tipo, descripcion, encontrados, esperado);

SELECT * FROM resumen ORDER BY codigo;

\echo '== Detalle I03 · Programas activos sin períodos ni resultados (esperado: STU-2026-0019) =='
SELECT * FROM i03;
\echo '== Detalle I06 · Pensums sin estudiantes (esperado: BCL-COMP-2027) =='
SELECT * FROM i06;
\echo '== Detalle D14 · Intento posterior a una aprobación (esperado: 0 filas) =='
SELECT * FROM d14;

-- Falla el script (útil en run_tests.sql) si algún diagnóstico no coincide.
DO $$
DECLARE v text;
BEGIN
    SELECT string_agg(codigo, ', ' ORDER BY codigo) INTO v FROM resumen WHERE resultado = 'FAIL';
    IF v IS NOT NULL THEN
        RAISE EXCEPTION 'FAIL diagnósticos: %', v;
    END IF;
    RAISE NOTICE 'PASS 10_validation_queries: 18 diagnósticos de integridad en 0 y 6 informativos con el valor esperado';
END $$;

ROLLBACK;
