-- =====================================================================
--  E2_dataset_check.sql — Evidencia del gate E2
--
--  Verifica que el dataset demostrativo (06–09) contiene los casos A–J,
--  los valores de frontera y los escenarios que exige el contrato, y que
--  es REPRODUCIBLE (huella md5 fija). Solo lectura: termina en ROLLBACK.
--
--  Uso (después de run_all.sql):
--    psql -d sistema_academico_dev -f E2_dataset_check.sql
-- =====================================================================
\set ON_ERROR_STOP on
\set QUIET on
\pset tuples_only on
\pset format unaligned
SET client_min_messages = notice;
BEGIN;

CREATE TEMP TABLE t_conteo (n integer NOT NULL DEFAULT 0);
INSERT INTO t_conteo VALUES (0);
CREATE FUNCTION pg_temp.ok(p_cond boolean, p_msg text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    IF p_cond IS DISTINCT FROM true THEN
        RAISE EXCEPTION 'FAIL %', p_msg;
    END IF;
    UPDATE t_conteo SET n = n + 1;
    RAISE NOTICE 'PASS %', p_msg;
END $$;

CREATE TEMP VIEW r AS SELECT * FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE;

\echo '--- Volumen y catálogos ---'
SELECT pg_temp.ok((SELECT count(*) FROM SIS_ACA_ESTUDIANTE) = 45, '45 estudiantes (rango del contrato 40–80)');
SELECT pg_temp.ok((SELECT count(*) FROM SIS_ACA_CARRERA) = 3, '3 carreras demostrativas');
SELECT pg_temp.ok((SELECT count(*) FROM SIS_ACA_PENSUM) = 4, '4 pensums (3 de 2025 + Computación 2027)');
SELECT pg_temp.ok((SELECT bool_and(n BETWEEN 5 AND 6) FROM (SELECT count(*) n FROM SIS_ACA_PENSUM_CURSO GROUP BY PCU_PEN_ID, PCU_CIC_ID) x), 'cada ciclo de cada pensum tiene 5–6 cursos');
SELECT pg_temp.ok((SELECT count(DISTINCT PCU_PEN_ID) FROM SIS_ACA_PENSUM_CURSO c JOIN SIS_ACA_CURSO u ON u.CUR_ID = c.PCU_CUR_ID WHERE u.CUR_CODIGO = 'MAT-101') = 4,
                  'MAT-101 está en 4 pensums con UN solo registro de curso (sin duplicar por carrera)');
SELECT pg_temp.ok((SELECT count(*) FROM SIS_ACA_ESTUDIANTE_PROGRAMA r JOIN SIS_ACA_PENSUM p ON p.PEN_ID = r.EPR_PEN_ID WHERE p.PEN_CODIGO = 'BCL-COMP-2027') = 0,
                  'pensum 2027 sin estudiantes: nadie migra automáticamente');
SELECT pg_temp.ok((SELECT count(*) >= 700 FROM SIS_ACA_RESULTADO_CURSO), 'al menos 700 resultados');

\echo '--- Calendario y política ---'
SELECT pg_temp.ok((SELECT string_agg(a.ANL_ANIO || '-' || p.PER_NUMERO || ':' || p.PER_ESTADO || ':' || x.POL_CODIGO, ' ' ORDER BY p.PER_FECHA_INICIO)
                   FROM SIS_ACA_PERIODO_ACADEMICO p JOIN SIS_ACA_ANIO_LECTIVO a ON a.ANL_ID = p.PER_ANL_ID JOIN SIS_ACA_POLITICA_ACADEMICA x ON x.POL_ID = p.PER_POL_ID)
                  = '2025-1:CERRADO:POL-2025-01 2025-2:CERRADO:POL-2025-01 2026-1:CERRADO:POL-2026-01 2026-2:ABIERTO:POL-2026-01',
                  'períodos 2025-I/II y 2026-I cerrados, 2026-II abierto, cada uno con su política');
SELECT pg_temp.ok((SELECT count(*) FROM SIS_ACA_PERIODO_ACADEMICO p JOIN SIS_ACA_POLITICA_ACADEMICA x ON x.POL_ID = p.PER_POL_ID WHERE x.POL_CODIGO = 'POL-2028-01') = 0,
                  'POL-2028 (70) existe pero ningún período la usa');
SELECT pg_temp.ok((SELECT bool_and((RES_ESTADO = 'APROBADO') = (RES_NOTA >= 61)) FROM r WHERE RES_NOTA IS NOT NULL),
                  'todos los resultados 2025–2026 se evalúan con 61, no con 70');

\echo '--- Frontera de aprobación ---'
SELECT pg_temp.ok((SELECT count(DISTINCT RES_NOTA) FROM r WHERE RES_NOTA IN (58, 59, 60, 61, 62, 63)) = 6, 'existen notas 58, 59, 60, 61, 62 y 63');
SELECT pg_temp.ok((SELECT bool_and(RES_ESTADO = 'REPROBADO') FROM r WHERE RES_NOTA = 60), 'toda nota 60 → REPROBADO');
SELECT pg_temp.ok((SELECT bool_and(RES_ESTADO = 'APROBADO') FROM r WHERE RES_NOTA = 61), 'toda nota 61 → APROBADO');

\echo '--- Casos nombrados ---'
SELECT pg_temp.ok((SELECT AVA_PORCENTAJE = 100 FROM SIS_ACA_VW_AVANCE_PENSUM WHERE EST_CODIGO = 'STU-2025-0001')
              AND (SELECT count(*) FILTER (WHERE RES_ESTADO <> 'APROBADO') = 0 AND avg(RES_NOTA) >= 90 FROM r WHERE EST_CODIGO = 'STU-2025-0001'),
                  'CASO A STU-2025-0001: todo aprobado, promedio ≥ 90, avance 100 %');
SELECT pg_temp.ok((SELECT RES_ESTADO FROM r WHERE EST_CODIGO = 'STU-2025-0002' AND CUR_CODIGO = 'FIS-101') = 'APROBADO'
              AND (SELECT RES_NOTA FROM r WHERE EST_CODIGO = 'STU-2025-0002' AND CUR_CODIGO = 'FIS-101') = 61.00,
                  'CASO B STU-2025-0002: FIS-101 = 61.00 → APROBADO');
SELECT pg_temp.ok((SELECT RES_NOTA = 60.00 AND RES_ESTADO = 'REPROBADO' FROM r WHERE EST_CODIGO = 'STU-2025-0003' AND CUR_CODIGO = 'MAT-102'),
                  'CASO C STU-2025-0003: MAT-102 = 60.00 → REPROBADO');
SELECT pg_temp.ok((SELECT RES_TOTAL_INTENTOS = 2 AND RES_PRIMERA_NOTA = 52 AND RES_ULTIMA_NOTA = 74 AND RES_SITUACION = 'APROBADO'
                   FROM SIS_ACA_VW_INTENTO_CURSO WHERE EST_CODIGO = 'STU-2025-0004' AND CUR_CODIGO = 'PRG-101'),
                  'CASO D STU-2025-0004: PRG-101 52 → 74, repitencia exitosa');
SELECT pg_temp.ok((SELECT RES_TOTAL_INTENTOS = 2 AND RES_MEJOR_NOTA < 61 AND RES_SITUACION = 'REPROBADO'
                   FROM SIS_ACA_VW_INTENTO_CURSO WHERE EST_CODIGO = 'STU-2025-0005' AND CUR_CODIGO = 'MAT-101'),
                  'CASO E STU-2025-0005: MAT-101 48 → 57, repitencia fallida');
SELECT pg_temp.ok((SELECT AVA_ESTADO_CICLO FROM SIS_ACA_VW_AVANCE_CICLO WHERE EST_CODIGO = 'STU-2025-0006' AND CIC_ANIO = 1 AND CIC_SEMESTRE = 1) = 'COMPLETO',
                  'CASO F STU-2025-0006: Año 1 / Semestre I COMPLETO');
SELECT pg_temp.ok((SELECT AVA_ESTADO_CICLO FROM SIS_ACA_VW_AVANCE_CICLO WHERE EST_CODIGO = 'STU-2025-0007' AND CIC_ANIO = 1 AND CIC_SEMESTRE = 2) = 'INCOMPLETO',
                  'CASO G STU-2025-0007: Año 1 / Semestre II INCOMPLETO (ING-102 = 58)');
SELECT pg_temp.ok((SELECT count(*) FROM r WHERE EST_CODIGO = 'STU-2026-0019') = 0
              AND (SELECT EPR_ESTADO = 'ACTIVO' AND AVA_PORCENTAJE = 0 FROM SIS_ACA_VW_AVANCE_PENSUM WHERE EST_CODIGO = 'STU-2026-0019'),
                  'CASO H STU-2026-0019: registrado y ACTIVO, sin resultados, avance 0 %');
SELECT pg_temp.ok((SELECT count(*) FILTER (WHERE RES_NOTA IS NULL) > 0 AND count(*) FILTER (WHERE RES_NOTA IS NOT NULL) > 0
                   FROM r WHERE EST_CODIGO = 'STU-2026-0002' AND ANL_ANIO = 2026 AND PER_NUMERO = 2),
                  'CASO I STU-2026-0002: en 2026-II tiene notas registradas y pendientes (NULL)');
SELECT pg_temp.ok((SELECT count(DISTINCT ANL_ANIO) = 2 FROM r WHERE EST_CODIGO = 'STU-2025-0004'),
                  'CASO J STU-2025-0004: resultados en 2025 y 2026');

\echo '--- Escenarios de rendimiento ---'
SELECT pg_temp.ok((SELECT count(*) FROM (SELECT EST_CODIGO FROM r WHERE RES_ESTADO = 'REPROBADO' GROUP BY 1 HAVING count(*) >= 3) x) >= 3,
                  'al menos 3 estudiantes con múltiples reprobaciones');
SELECT pg_temp.ok((SELECT min(p) < 70 AND max(p) > 79 FROM (SELECT avg(RES_NOTA) p FROM r GROUP BY CUR_CODIGO HAVING count(RES_NOTA) >= 10) x),
                  'hay cursos difíciles (promedio < 70) y de alta aprobación (promedio > 79)');
SELECT pg_temp.ok((SELECT count(*) FROM SIS_ACA_VW_AVANCE_PENSUM WHERE AVA_PENSUM_COMPLETO) = 17, '17 estudiantes con el pensum completo');
SELECT pg_temp.ok((SELECT count(DISTINCT EPE_CIC_ID) FROM SIS_ACA_ESTUDIANTE_PERIODO e JOIN SIS_ACA_PERIODO_ACADEMICO p ON p.PER_ID = e.EPE_PER_ID WHERE p.PER_ESTADO = 'ABIERTO') = 2,
                  'en el período abierto hay estudiantes en dos ciclos distintos');
SELECT pg_temp.ok((SELECT count(*) FROM SIS_ACA_ESTUDIANTE_PERIODO e JOIN SIS_ACA_ESTUDIANTE_PROGRAMA r ON r.EPR_ID = e.EPE_EPR_ID
                   JOIN SIS_ACA_ESTUDIANTE s ON s.EST_ID = r.EPR_EST_ID JOIN SIS_ACA_PERIODO_ACADEMICO p ON p.PER_ID = e.EPE_PER_ID
                   WHERE s.EST_CODIGO = 'STU-2025-0026' AND p.PER_FECHA_INICIO >= DATE '2026-01-01') = 0
              AND (SELECT EPR_ESTADO FROM SIS_ACA_ESTUDIANTE_PROGRAMA r JOIN SIS_ACA_ESTUDIANTE s ON s.EST_ID = r.EPR_EST_ID WHERE s.EST_CODIGO = 'STU-2025-0026') = 'RETIRADO',
                  'STU-2025-0026 RETIRADO al cierre de 2025, sin períodos en 2026');

\echo '--- Coherencia ---'
SELECT pg_temp.ok((SELECT count(*) FROM SIS_ACA_VW_INTENTO_CURSO i
                   WHERE i.RES_APROBADO AND EXISTS (SELECT 1 FROM r WHERE r.EPR_ID = i.EPR_ID AND r.PCU_ID = i.PCU_ID AND r.PER_ID <> i.PER_ID_APROBACION
                                                    AND r.PER_FECHA_INICIO > (SELECT PER_FECHA_INICIO FROM SIS_ACA_PERIODO_ACADEMICO WHERE PER_ID = i.PER_ID_APROBACION))) = 0,
                  'ningún intento posterior a una aprobación (D6)');
SELECT pg_temp.ok((SELECT bool_and(EPE_ESTADO = CASE WHEN p.PER_ESTADO = 'CERRADO' THEN 'FINALIZADO' ELSE 'INSCRITO' END)
                   FROM SIS_ACA_ESTUDIANTE_PERIODO e JOIN SIS_ACA_PERIODO_ACADEMICO p ON p.PER_ID = e.EPE_PER_ID),
                  'períodos cerrados con estudiantes FINALIZADO; período abierto con INSCRITO');
SELECT pg_temp.ok((SELECT count(*) = count(DISTINCT (EPE_ID, PCU_ID)) FROM SIS_ACA_VW_INGRESO_NOTAS), 'clave (EPE_ID, PCU_ID) única en VW_INGRESO_NOTAS');
SELECT pg_temp.ok((SELECT ING_ORIGEN = 'CICLO_ANTERIOR' AND ING_ESTADO = 'SIN_REGISTRO' AND ING_EDITABLE
                   FROM SIS_ACA_VW_INGRESO_NOTAS WHERE EST_CODIGO = 'STU-2025-0003' AND CUR_CODIGO = 'MAT-102' AND PER_ESTADO = 'ABIERTO'),
                  'Q25: MAT-102 de STU-2025-0003 se ofrece como repitencia editable en 2026-II');
SELECT pg_temp.ok((SELECT max(AVA_PORCENTAJE) <= 100 FROM SIS_ACA_VW_AVANCE_CICLO), 'ningún porcentaje > 100');

\echo '--- Reproducibilidad ---'
-- Huella de TODOS los resultados por claves naturales (sin IDs).
SELECT pg_temp.ok((SELECT md5(string_agg(EST_CODIGO || '|' || CUR_CODIGO || '|' || ANL_ANIO || '-' || PER_NUMERO || '|' || COALESCE(RES_NOTA::text, 'NULL'),
                                         ',' ORDER BY EST_CODIGO, CUR_CODIGO, PER_FECHA_INICIO)) FROM r)
                  = '4ad9de4736c9003431a4853a234229e7',
                  'huella md5 del dataset = valor publicado en E2_ENTREGA.md');

SELECT 'TOTAL: ' || n || ' verificaciones PASS' FROM t_conteo;
\echo '=== E2 dataset check: todas las verificaciones PASS ==='
ROLLBACK;
