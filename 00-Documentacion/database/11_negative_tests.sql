-- =====================================================================
--  11_negative_tests.sql — E3 · Pruebas negativas (§33)
--
--  Cada prueba INTENTA una operación inválida sobre el dataset demostrativo
--  y verifica que falle con el SQLSTATE y, cuando aplica, la constraint
--  esperada (EXPECTED FAILURE). Cada intento corre en su propia
--  subtransacción y TODO el archivo termina en ROLLBACK: no modifica datos.
--
--  Uso (después de run_all.sql):
--    psql -d sistema_academico_dev -f 11_negative_tests.sql
--
--  Sección N7: REAPERTURA / CORRECCIÓN HISTÓRICA (DF1). Aprobar
--  retroactivamente un intento que tiene intentos posteriores falla con
--  SA208; las correcciones legítimas (sigue reprobado, sin intentos
--  posteriores, aprobado → aprobado, política de 70) se verifican como
--  permitidas. D14 se mantiene como defensa en profundidad.
-- =====================================================================
\set ON_ERROR_STOP on
\set QUIET on
\pset tuples_only on
\pset format unaligned
SET client_min_messages = notice;
BEGIN;

CREATE TEMP TABLE t_conteo (pruebas integer NOT NULL DEFAULT 0);
INSERT INTO t_conteo VALUES (0);

-- EXPECTED FAILURE: p_sql debe fallar con p_sqlstate; si p_constraint no es
-- NULL, también debe coincidir el nombre de la constraint violada.
CREATE FUNCTION pg_temp.debe_fallar(p_id text, p_sql text, p_sqlstate text, p_constraint text, p_msg text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
    v_con text;
BEGIN
    BEGIN
        EXECUTE p_sql;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_con = CONSTRAINT_NAME;
        IF SQLSTATE = p_sqlstate AND (p_constraint IS NULL OR lower(v_con) = lower(p_constraint)) THEN
            UPDATE t_conteo SET pruebas = pruebas + 1;
            RAISE NOTICE 'PASS % [EXPECTED FAILURE % %] %', p_id, p_sqlstate, COALESCE(upper(p_constraint), ''), p_msg;
            RETURN;
        END IF;
        RAISE EXCEPTION 'FAIL % — se esperaba % %, se obtuvo % % (%)', p_id, p_sqlstate, COALESCE(p_constraint, ''), SQLSTATE, COALESCE(v_con, ''), SQLERRM;
    END;
    RAISE EXCEPTION 'FAIL % — se esperaba el error %, pero la sentencia tuvo éxito: %', p_id, p_sqlstate, p_msg;
END $$;

-- Operación válida que DEBE ejecutarse (casos frontera de las reglas).
CREATE FUNCTION pg_temp.debe_pasar(p_id text, p_sql text, p_msg text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_filas bigint;
BEGIN
    EXECUTE p_sql;
    GET DIAGNOSTICS v_filas = ROW_COUNT;
    IF v_filas = 0 THEN
        RAISE EXCEPTION 'FAIL % — la sentencia no afectó ninguna fila (prueba vacía): %', p_id, p_msg USING ERRCODE = 'SAT01';
    END IF;
    UPDATE t_conteo SET pruebas = pruebas + 1;
    RAISE NOTICE 'PASS % [permitido] %', p_id, p_msg;
EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'SAT01' THEN RAISE; END IF;
    RAISE EXCEPTION 'FAIL % — se esperaba éxito, se obtuvo % (%)', p_id, SQLSTATE, SQLERRM;
END $$;

CREATE FUNCTION pg_temp.ok(p_id text, p_cond boolean, p_msg text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    IF p_cond IS DISTINCT FROM true THEN RAISE EXCEPTION 'FAIL % %', p_id, p_msg; END IF;
    UPDATE t_conteo SET pruebas = pruebas + 1;
    RAISE NOTICE 'PASS % %', p_id, p_msg;
END $$;

-- Atajos por clave natural
CREATE TEMP VIEW t_per AS
  SELECT p.PER_ID, a.ANL_ANIO || '-' || p.PER_NUMERO AS clave FROM SIS_ACA_PERIODO_ACADEMICO p JOIN SIS_ACA_ANIO_LECTIVO a ON a.ANL_ID = p.PER_ANL_ID;
CREATE TEMP VIEW t_epe AS
  SELECT e.EPE_ID, s.EST_CODIGO AS est, t.clave AS per
  FROM SIS_ACA_ESTUDIANTE_PERIODO e JOIN SIS_ACA_ESTUDIANTE_PROGRAMA r ON r.EPR_ID = e.EPE_EPR_ID
  JOIN SIS_ACA_ESTUDIANTE s ON s.EST_ID = r.EPR_EST_ID JOIN t_per t ON t.PER_ID = e.EPE_PER_ID;
CREATE TEMP VIEW t_ofe AS
  SELECT o.OFE_ID, t.clave AS per, p.PEN_CODIGO AS pen, u.CUR_CODIGO AS cur, s.SEC_CODIGO AS sec
  FROM SIS_ACA_OFERTA_CURSO o JOIN t_per t ON t.PER_ID = o.OFE_PER_ID
  JOIN SIS_ACA_PENSUM_CURSO c ON c.PCU_ID = o.OFE_PCU_ID JOIN SIS_ACA_PENSUM p ON p.PEN_ID = c.PCU_PEN_ID
  JOIN SIS_ACA_CURSO u ON u.CUR_ID = c.PCU_CUR_ID JOIN SIS_ACA_SECCION s ON s.SEC_ID = o.OFE_SEC_ID;
CREATE TEMP VIEW t_res AS
  SELECT x.RES_ID, e.est, e.per, o.cur FROM SIS_ACA_RESULTADO_CURSO x
  JOIN t_epe e ON e.EPE_ID = x.RES_EPE_ID JOIN t_ofe o ON o.OFE_ID = x.RES_OFE_ID;

-- =====================================================================
\echo '--- N1. Validez de la nota ---'
-- =====================================================================
-- Resultado PENDIENTE de STU-2026-0002 (CASO I) en 2026-II (ABIERTO): solo falla por la nota.
SELECT pg_temp.debe_fallar('N01', $$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = -1, RES_CALIFICADO_EN = now() WHERE RES_ID = (SELECT RES_ID FROM t_res WHERE est = 'STU-2026-0002' AND cur = 'MAT-102')$$,
                           '23514', 'ck_res_nota_rango', 'nota -1');
SELECT pg_temp.debe_fallar('N02', $$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 101, RES_CALIFICADO_EN = now() WHERE RES_ID = (SELECT RES_ID FROM t_res WHERE est = 'STU-2026-0002' AND cur = 'MAT-102')$$,
                           '23514', 'ck_res_nota_rango', 'nota 101');
SELECT pg_temp.debe_fallar('N03', $$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 80 WHERE RES_ID = (SELECT RES_ID FROM t_res WHERE est = 'STU-2026-0002' AND cur = 'MAT-102')$$,
                           '23514', 'ck_res_nota_fecha', 'nota sin fecha de calificación');
SELECT pg_temp.debe_fallar('N04', $$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 1000 WHERE RES_ID = (SELECT RES_ID FROM t_res WHERE est = 'STU-2026-0002' AND cur = 'MAT-102')$$,
                           '22003', NULL, 'nota fuera de NUMERIC(5,2) (overflow numérico)');

-- =====================================================================
\echo '--- N2. Duplicados lógicos ---'
-- =====================================================================
SELECT pg_temp.debe_fallar('N05', $$INSERT INTO SIS_ACA_ESTUDIANTE (EST_CODIGO, EST_NOMBRES, EST_APELLIDOS, EST_FECHA_NACIMIENTO) VALUES ('STU-2025-0001', 'Otra', 'Persona', DATE '2008-01-01')$$,
                           '23505', 'uq_est_codigo', 'estudiante duplicado por código');
SELECT pg_temp.debe_fallar('N06', $$INSERT INTO SIS_ACA_CARRERA (CAR_CODIGO, CAR_NOMBRE) VALUES ('BCL', 'Otra carrera')$$,
                           '23505', 'uq_car_codigo', 'carrera duplicada por código');
SELECT pg_temp.debe_fallar('N07', $$INSERT INTO SIS_ACA_CURSO (CUR_CODIGO, CUR_NOMBRE) VALUES ('MAT-101', 'Matemática I (copia)')$$,
                           '23505', 'uq_cur_codigo', 'curso duplicado por código');
SELECT pg_temp.debe_fallar('N08', $$INSERT INTO SIS_ACA_PERIODO_ACADEMICO (PER_ANL_ID, PER_NUMERO, PER_NOMBRE, PER_FECHA_INICIO, PER_FECHA_FIN)
                                    SELECT ANL_ID, 1, 'Semestre I (copia)', DATE '2026-01-15', DATE '2026-06-15' FROM SIS_ACA_ANIO_LECTIVO WHERE ANL_ANIO = 2026$$,
                           '23505', 'uq_per_anl_numero', 'período académico duplicado (año + número)');
SELECT pg_temp.debe_fallar('N09', $$INSERT INTO SIS_ACA_ESTUDIANTE_PERIODO (EPE_EPR_ID, EPE_PER_ID, EPE_CIC_ID, EPE_SEC_ID)
                                    SELECT EPE_EPR_ID, EPE_PER_ID, EPE_CIC_ID, EPE_SEC_ID FROM SIS_ACA_ESTUDIANTE_PERIODO WHERE EPE_ID = (SELECT EPE_ID FROM t_epe WHERE est = 'STU-2026-0002' AND per = '2026-2')$$,
                           '23505', 'uq_epe_epr_per', 'estudiante-período duplicado');
SELECT pg_temp.debe_fallar('N10', $$INSERT INTO SIS_ACA_OFERTA_CURSO (OFE_PER_ID, OFE_PCU_ID, OFE_SEC_ID)
                                    SELECT OFE_PER_ID, OFE_PCU_ID, OFE_SEC_ID FROM SIS_ACA_OFERTA_CURSO WHERE OFE_ID = (SELECT OFE_ID FROM t_ofe WHERE per = '2026-2' AND pen = 'BCL-COMP-2025' AND cur = 'PRG-102' AND sec = 'A')$$,
                           '23505', 'uq_ofe_per_pcu_sec', 'oferta duplicada (período + curso del pensum + sección)');
SELECT pg_temp.debe_fallar('N11', $$INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID)
                                    SELECT RES_EPE_ID, RES_OFE_ID FROM SIS_ACA_RESULTADO_CURSO WHERE RES_ID = (SELECT RES_ID FROM t_res WHERE est = 'STU-2026-0002' AND cur = 'PRG-102')$$,
                           '23505', 'uq_res_epe_ofe', 'nota duplicada para estudiante + oferta');
SELECT pg_temp.debe_fallar('N12', $$INSERT INTO SIS_ACA_PENSUM_CURSO (PCU_PEN_ID, PCU_CUR_ID, PCU_CIC_ID, PCU_ORDEN)
                                    SELECT p.PEN_ID, c.CUR_ID, k.CIC_ID, 9 FROM SIS_ACA_PENSUM p, SIS_ACA_CURSO c, SIS_ACA_CICLO_CURRICULAR k
                                    WHERE p.PEN_CODIGO = 'BCL-2025' AND c.CUR_CODIGO = 'MAT-101' AND k.CIC_ANIO = 2 AND k.CIC_SEMESTRE = 2$$,
                           '23505', 'uq_pcu_pen_cur', 'curso repetido dentro de un pensum');
SELECT pg_temp.debe_fallar('N13', $$INSERT INTO SIS_ACA_ESTUDIANTE_PROGRAMA (EPR_EST_ID, EPR_PEN_ID, EPR_FECHA_INICIO)
                                    SELECT e.EST_ID, p.PEN_ID, DATE '2026-02-01' FROM SIS_ACA_ESTUDIANTE e, SIS_ACA_PENSUM p WHERE e.EST_CODIGO = 'STU-2026-0002' AND p.PEN_CODIGO = 'BCL-2025'$$,
                           '23505', 'ux_epr_est_activo', 'segundo programa ACTIVO del mismo estudiante');
SELECT pg_temp.debe_fallar('N14', $$INSERT INTO SIS_ACA_POLITICA_ACADEMICA (POL_CODIGO, POL_NOMBRE, POL_NOTA_APROBACION, POL_VIGENTE_DESDE) VALUES ('POL-2028-02', 'Copia', 70, DATE '2028-01-01')$$,
                           '23505', 'uq_pol_vigente_desde', 'dos políticas con la misma fecha de inicio (solapamiento)');

-- =====================================================================
\echo '--- N3. Pensum de otra carrera / contexto incompatible ---'
-- =====================================================================
-- §33 "curriculum asignado a carrera incorrecta": IMPOSIBLE por construcción (H1).
-- No existe columna de carrera en el programa, así que no hay forma de expresar la combinación.
SELECT pg_temp.debe_fallar('N15', $$INSERT INTO SIS_ACA_ESTUDIANTE_PROGRAMA (EPR_EST_ID, EPR_CAR_ID, EPR_PEN_ID, EPR_FECHA_INICIO)
                                    SELECT e.EST_ID, (SELECT CAR_ID FROM SIS_ACA_CARRERA WHERE CAR_CODIGO = 'BCO'), p.PEN_ID, DATE '2026-02-01'
                                    FROM SIS_ACA_ESTUDIANTE e, SIS_ACA_PENSUM p WHERE e.EST_CODIGO = 'STU-2026-0019' AND p.PEN_CODIGO = 'BCL-COMP-2025'$$,
                           '42703', NULL, 'carrera ≠ carrera del pensum: no expresable (no existe EPR_CAR_ID)');
SELECT pg_temp.debe_fallar('N16', $$INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID)
                                    SELECT e.EPE_ID, o.OFE_ID FROM t_epe e, t_ofe o
                                    WHERE e.est = 'STU-2026-0002' AND e.per = '2026-2' AND o.per = '2026-1' AND o.pen = 'BCL-COMP-2025' AND o.cur = 'MAT-101' AND o.sec = 'A'$$,
                           'SA201', NULL, 'resultado en período incompatible (estudiante 2026-II, oferta 2026-I)');
SELECT pg_temp.debe_fallar('N17', $$INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID)
                                    SELECT e.EPE_ID, o.OFE_ID FROM t_epe e, t_ofe o
                                    WHERE e.est = 'STU-2026-0002' AND e.per = '2026-2' AND o.per = '2026-2' AND o.pen = 'BCL-2025' AND o.cur = 'COM-102' AND o.sec = 'A'$$,
                           'SA202', NULL, 'pensum incompatible: alumno de Computación en oferta de Ciencias y Letras');
SELECT pg_temp.debe_fallar('N18', $$INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID)
                                    SELECT e.EPE_ID, o.OFE_ID FROM t_epe e, t_ofe o
                                    WHERE e.est = 'STU-2026-0003' AND e.per = '2026-2' AND o.per = '2026-2' AND o.pen = 'BCL-COMP-2025' AND o.cur = 'PRG-102' AND o.sec = 'B'$$,
                           'SA203', NULL, 'sección incoherente: alumno de la sección A en oferta de la B (S1)');

-- =====================================================================
\echo '--- N4. Mutabilidad de resultados (T2) ---'
-- =====================================================================
SELECT pg_temp.debe_fallar('N19', $$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 99, RES_CALIFICADO_EN = now() WHERE RES_ID = (SELECT RES_ID FROM t_res WHERE est = 'STU-2025-0001' AND cur = 'PRG-101')$$,
                           'SA204', NULL, 'modificar nota de un período CERRADO (2025-I)');
SELECT pg_temp.debe_fallar('N20', $$DELETE FROM SIS_ACA_RESULTADO_CURSO WHERE RES_ID = (SELECT RES_ID FROM t_res WHERE est = 'STU-2025-0004' AND per = '2025-1' AND cur = 'PRG-101')$$,
                           'SA204', NULL, 'borrar el intento reprobado histórico de CASO D (período CERRADO)');
SELECT pg_temp.debe_fallar('N21', $$UPDATE SIS_ACA_PERIODO_ACADEMICO SET PER_ESTADO = 'PLANIFICADO' WHERE PER_ID = (SELECT PER_ID FROM t_per WHERE clave = '2026-2');
                                    UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 70, RES_CALIFICADO_EN = now() WHERE RES_ID = (SELECT RES_ID FROM t_res WHERE est = 'STU-2026-0002' AND cur = 'MAT-102')$$,
                           'SA204', NULL, 'registrar nota en período PLANIFICADO');
SELECT pg_temp.debe_fallar('N22', $$UPDATE SIS_ACA_ESTUDIANTE_PERIODO SET EPE_ESTADO = 'RETIRADO' WHERE EPE_ID = (SELECT EPE_ID FROM t_epe WHERE est = 'STU-2026-0002' AND per = '2026-2');
                                    UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 70, RES_CALIFICADO_EN = now() WHERE RES_ID = (SELECT RES_ID FROM t_res WHERE est = 'STU-2026-0002' AND cur = 'MAT-102')$$,
                           'SA205', NULL, 'registrar nota a estudiante RETIRADO del período');
SELECT pg_temp.debe_fallar('N23', $$UPDATE SIS_ACA_OFERTA_CURSO SET OFE_ACTIVO = FALSE WHERE OFE_ID = (SELECT OFE_ID FROM t_ofe WHERE per = '2026-2' AND pen = 'BCL-COMP-2025' AND cur = 'MAT-102' AND sec = 'A');
                                    UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 70, RES_CALIFICADO_EN = now() WHERE RES_ID = (SELECT RES_ID FROM t_res WHERE est = 'STU-2026-0002' AND cur = 'MAT-102')$$,
                           'SA206', NULL, 'registrar nota en oferta inactiva');
SELECT pg_temp.debe_fallar('N24', $$INSERT INTO SIS_ACA_OFERTA_CURSO (OFE_PER_ID, OFE_PCU_ID, OFE_SEC_ID)
                                    SELECT t.PER_ID, c.PCU_ID, s.SEC_ID FROM t_per t, SIS_ACA_PENSUM_CURSO c, SIS_ACA_PENSUM p, SIS_ACA_CURSO u, SIS_ACA_SECCION s
                                    WHERE t.clave = '2026-2' AND p.PEN_CODIGO = 'BCL-COMP-2025' AND c.PCU_PEN_ID = p.PEN_ID AND u.CUR_CODIGO = 'PRG-101' AND c.PCU_CUR_ID = u.CUR_ID AND s.SEC_CODIGO = 'B';
                                    INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID)
                                    SELECT e.EPE_ID, o.OFE_ID FROM t_epe e, t_ofe o WHERE e.est = 'STU-2025-0004' AND e.per = '2026-2' AND o.per = '2026-2' AND o.cur = 'PRG-101' AND o.sec = 'B'$$,
                           'SA207', NULL, 'CASO D: nuevo intento de PRG-101 después de aprobarlo con 74');

-- =====================================================================
\echo '--- N5. Política académica (T3) ---'
-- =====================================================================
SELECT pg_temp.debe_fallar('N25', $$INSERT INTO SIS_ACA_ANIO_LECTIVO (ANL_ANIO, ANL_NOMBRE, ANL_FECHA_INICIO, ANL_FECHA_FIN) VALUES (2024, '2024', DATE '2024-01-10', DATE '2024-11-30');
                                    INSERT INTO SIS_ACA_PERIODO_ACADEMICO (PER_ANL_ID, PER_NUMERO, PER_NOMBRE, PER_FECHA_INICIO, PER_FECHA_FIN)
                                    SELECT ANL_ID, 1, 'Semestre I', DATE '2024-01-15', DATE '2024-06-15' FROM SIS_ACA_ANIO_LECTIVO WHERE ANL_ANIO = 2024$$,
                           'SA301', NULL, 'período sin política vigente (2024)');
SELECT pg_temp.debe_fallar('N26', $$INSERT INTO SIS_ACA_ANIO_LECTIVO (ANL_ANIO, ANL_NOMBRE, ANL_FECHA_INICIO, ANL_FECHA_FIN) VALUES (2027, '2027', DATE '2027-01-11', DATE '2027-11-26');
                                    INSERT INTO SIS_ACA_PERIODO_ACADEMICO (PER_ANL_ID, PER_NUMERO, PER_NOMBRE, PER_FECHA_INICIO, PER_FECHA_FIN, PER_POL_ID)
                                    SELECT a.ANL_ID, 1, 'Semestre I', DATE '2027-01-15', DATE '2027-06-15', x.POL_ID FROM SIS_ACA_ANIO_LECTIVO a, SIS_ACA_POLITICA_ACADEMICA x
                                    WHERE a.ANL_ANIO = 2027 AND x.POL_CODIGO = 'POL-2028-01'$$,
                           'SA302', NULL, 'período 2027 con política explícita incorrecta (POL-2028)');
SELECT pg_temp.debe_fallar('N27', $$UPDATE SIS_ACA_POLITICA_ACADEMICA SET POL_NOTA_APROBACION = 65 WHERE POL_CODIGO = 'POL-2025-01'$$,
                           'SA303', NULL, 'cambiar retroactivamente la nota mínima de 2025');
SELECT pg_temp.debe_fallar('N28', $$INSERT INTO SIS_ACA_POLITICA_ACADEMICA (POL_CODIGO, POL_NOMBRE, POL_NOTA_APROBACION, POL_VIGENTE_DESDE) VALUES ('POL-2026-02', 'Reforma retroactiva', 70, DATE '2026-06-01')$$,
                           'SA304', NULL, 'reforma retroactiva que absorbería 2026-II');
SELECT pg_temp.debe_fallar('N29', $$UPDATE SIS_ACA_PERIODO_ACADEMICO SET PER_FECHA_INICIO = DATE '2028-01-15', PER_FECHA_FIN = DATE '2028-06-15',
                                           PER_POL_ID = (SELECT POL_ID FROM SIS_ACA_POLITICA_ACADEMICA WHERE POL_CODIGO = 'POL-2028-01')
                                    WHERE PER_ID = (SELECT PER_ID FROM t_per WHERE clave = '2026-1')$$,
                           'SA305', NULL, 'cambiar la política de un período con resultados');
SELECT pg_temp.debe_fallar('N30', $$DELETE FROM SIS_ACA_POLITICA_ACADEMICA WHERE POL_CODIGO = 'POL-2025-01'$$,
                           '23503', 'fk_per_pol', 'borrar una política usada');

-- =====================================================================
\echo '--- N6. Reescritura histórica (T4) y borrados ---'
-- =====================================================================
SELECT pg_temp.debe_fallar('N31', $$UPDATE SIS_ACA_ESTUDIANTE_PROGRAMA SET EPR_PEN_ID = (SELECT PEN_ID FROM SIS_ACA_PENSUM WHERE PEN_CODIGO = 'BCL-COMP-2027')
                                    WHERE EPR_EST_ID = (SELECT EST_ID FROM SIS_ACA_ESTUDIANTE WHERE EST_CODIGO = 'STU-2025-0001')$$,
                           'SA401', NULL, 'migrar a Ana al pensum 2027 con historial');
SELECT pg_temp.debe_fallar('N32', $$UPDATE SIS_ACA_ESTUDIANTE_PERIODO SET EPE_SEC_ID = (SELECT SEC_ID FROM SIS_ACA_SECCION WHERE SEC_CODIGO = 'C') WHERE EPE_ID = (SELECT EPE_ID FROM t_epe WHERE est = 'STU-2026-0002' AND per = '2026-2')$$,
                           'SA401', NULL, 'cambiar la sección de un estudiante-período con resultados');
SELECT pg_temp.debe_fallar('N33', $$UPDATE SIS_ACA_OFERTA_CURSO SET OFE_SEC_ID = (SELECT SEC_ID FROM SIS_ACA_SECCION WHERE SEC_CODIGO = 'C') WHERE OFE_ID = (SELECT OFE_ID FROM t_ofe WHERE per = '2026-2' AND pen = 'BCL-COMP-2025' AND cur = 'PRG-102' AND sec = 'A')$$,
                           'SA401', NULL, 'cambiar la sección de una oferta con resultados');
SELECT pg_temp.debe_fallar('N34', $$UPDATE SIS_ACA_PENSUM_CURSO SET PCU_CIC_ID = (SELECT CIC_ID FROM SIS_ACA_CICLO_CURRICULAR WHERE CIC_ANIO = 2 AND CIC_SEMESTRE = 2)
                                    WHERE PCU_PEN_ID = (SELECT PEN_ID FROM SIS_ACA_PENSUM WHERE PEN_CODIGO = 'BCL-COMP-2025') AND PCU_CUR_ID = (SELECT CUR_ID FROM SIS_ACA_CURSO WHERE CUR_CODIGO = 'PRG-101')$$,
                           'SA401', NULL, 'mover PRG-101 de ciclo en un pensum con resultados');
SELECT pg_temp.debe_fallar('N35', $$UPDATE SIS_ACA_PENSUM SET PEN_CAR_ID = (SELECT CAR_ID FROM SIS_ACA_CARRERA WHERE CAR_CODIGO = 'BCO') WHERE PEN_CODIGO = 'BCL-COMP-2025'$$,
                           'SA401', NULL, 'mover un pensum con estudiantes a otra carrera');
SELECT pg_temp.debe_fallar('N36', $$UPDATE SIS_ACA_PERIODO_ACADEMICO SET PER_FECHA_FIN = DATE '2025-07-31' WHERE PER_ID = (SELECT PER_ID FROM t_per WHERE clave = '2025-1')$$,
                           'SA401', NULL, 'cambiar fechas de un período con resultados');
SELECT pg_temp.debe_fallar('N37', $$UPDATE SIS_ACA_ANIO_LECTIVO SET ANL_ANIO = 2030 WHERE ANL_ANIO = 2025$$,
                           'SA401', NULL, 'cambiar el año de un año lectivo con resultados');
SELECT pg_temp.debe_fallar('N38', $$UPDATE SIS_ACA_CICLO_CURRICULAR SET CIC_SEMESTRE = 3 WHERE CIC_ANIO = 1 AND CIC_SEMESTRE = 2$$,
                           'SA401', NULL, 'renumerar un ciclo referenciado');
SELECT pg_temp.debe_fallar('N39', $$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_EPE_ID = (SELECT EPE_ID FROM t_epe WHERE est = 'STU-2026-0001' AND per = '2026-2')
                                    WHERE RES_ID = (SELECT RES_ID FROM t_res WHERE est = 'STU-2026-0002' AND cur = 'MAT-102')$$,
                           'SA401', NULL, 'mover un intento a otro estudiante (RES_EPE_ID)');
SELECT pg_temp.debe_fallar('N40', $$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_OFE_ID = (SELECT OFE_ID FROM t_ofe WHERE per = '2026-2' AND pen = 'BCL-COMP-2025' AND cur = 'FIS-102' AND sec = 'A')
                                    WHERE RES_ID = (SELECT RES_ID FROM t_res WHERE est = 'STU-2026-0002' AND cur = 'MAT-102')$$,
                           'SA401', NULL, 'mover un intento a otra oferta (RES_OFE_ID)');
SELECT pg_temp.debe_fallar('N41', $$DELETE FROM SIS_ACA_CARRERA WHERE CAR_CODIGO = 'BCL-COMP'$$,
                           '23503', 'fk_pen_car', 'borrar una carrera con historial (RESTRICT, sin cascada)');
SELECT pg_temp.debe_fallar('N42', $$DELETE FROM SIS_ACA_ESTUDIANTE WHERE EST_CODIGO = 'STU-2025-0004'$$,
                           '23503', 'fk_epr_est', 'borrar un estudiante con historial');

-- =====================================================================
\echo '--- N6b. Fechas invertidas, estados inválidos y FK inexistentes ---'
-- =====================================================================
SELECT pg_temp.debe_fallar('N43', $$INSERT INTO SIS_ACA_ANIO_LECTIVO (ANL_ANIO, ANL_NOMBRE, ANL_FECHA_INICIO, ANL_FECHA_FIN) VALUES (2031, '2031', DATE '2031-11-30', DATE '2031-01-10')$$,
                           '23514', 'ck_anl_fechas', 'año lectivo con fechas invertidas');
SELECT pg_temp.debe_fallar('N44', $$INSERT INTO SIS_ACA_ANIO_LECTIVO (ANL_ANIO, ANL_NOMBRE, ANL_FECHA_INICIO, ANL_FECHA_FIN) VALUES (2027, '2027', DATE '2027-01-11', DATE '2027-11-26');
                                    INSERT INTO SIS_ACA_PERIODO_ACADEMICO (PER_ANL_ID, PER_NUMERO, PER_NOMBRE, PER_FECHA_INICIO, PER_FECHA_FIN)
                                    SELECT ANL_ID, 1, 'Semestre I', DATE '2027-06-15', DATE '2027-01-15' FROM SIS_ACA_ANIO_LECTIVO WHERE ANL_ANIO = 2027$$,
                           '23514', 'ck_per_fechas', 'período con fin anterior al inicio');
SELECT pg_temp.debe_fallar('N45', $$UPDATE SIS_ACA_PENSUM SET PEN_VIGENTE_HASTA = DATE '2026-12-31' WHERE PEN_CODIGO = 'BCL-COMP-2027'$$,
                           '23514', 'ck_pen_vigencia', 'pensum con vigencia invertida');
SELECT pg_temp.debe_fallar('N46', $$UPDATE SIS_ACA_ESTUDIANTE_PROGRAMA SET EPR_FECHA_FIN = DATE '2020-01-01', EPR_ESTADO = 'RETIRADO'
                                    WHERE EPR_EST_ID = (SELECT EST_ID FROM SIS_ACA_ESTUDIANTE WHERE EST_CODIGO = 'STU-2026-0019')$$,
                           '23514', 'ck_epr_fechas', 'programa con fin anterior al inicio');
SELECT pg_temp.debe_fallar('N47', $$UPDATE SIS_ACA_ESTUDIANTE_PROGRAMA SET EPR_FECHA_FIN = DATE '2026-12-31'
                                    WHERE EPR_EST_ID = (SELECT EST_ID FROM SIS_ACA_ESTUDIANTE WHERE EST_CODIGO = 'STU-2026-0019')$$,
                           '23514', 'ck_epr_estado_fecha_fin', 'programa ACTIVO con fecha de fin');
SELECT pg_temp.debe_fallar('N48', $$UPDATE SIS_ACA_PERIODO_ACADEMICO SET PER_ESTADO = 'EN_CURSO' WHERE PER_ID = (SELECT PER_ID FROM t_per WHERE clave = '2026-2')$$,
                           '23514', 'ck_per_estado', 'estado de período inexistente');
SELECT pg_temp.debe_fallar('N49', $$INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID) VALUES (999999, (SELECT min(OFE_ID) FROM SIS_ACA_OFERTA_CURSO))$$,
                           '23503', 'fk_res_epe', 'resultado con estudiante-período inexistente');
SELECT pg_temp.debe_fallar('N50', $$INSERT INTO SIS_ACA_ESTUDIANTE_PROGRAMA (EPR_EST_ID, EPR_PEN_ID, EPR_FECHA_INICIO, EPR_FECHA_FIN, EPR_ESTADO)
                                    VALUES ((SELECT EST_ID FROM SIS_ACA_ESTUDIANTE WHERE EST_CODIGO = 'STU-2025-0026'), 999999, DATE '2026-01-15', DATE '2026-06-30', 'RETIRADO')$$,
                           '23503', 'fk_epr_pen', 'programa con pensum inexistente');
SELECT pg_temp.debe_fallar('N51', $$INSERT INTO SIS_ACA_ESTUDIANTE (EST_CODIGO, EST_NOMBRES, EST_APELLIDOS, EST_FECHA_NACIMIENTO) VALUES ('STU-2026-0099', '   ', 'Prueba', DATE '2010-01-01')$$,
                           '23514', 'ck_est_nombres_no_vacio', 'nombres en blanco');

-- =====================================================================
\echo '--- N7. Reapertura / corrección histórica (DF1 · SA208) ---'
-- =====================================================================
-- Escenario: STU-2025-0005 (CASO E) tiene MAT-101 = 48 (2025-I) y 57 (2026-I), ambos REPROBADO.
-- Una autoridad reabre 2025-I y devuelve al estudiante a INSCRITO para corregir el 48.
--   · 48 → 65 (lo convertiría en APROBADO con un intento posterior) → SA208.
--   · 48 → 60 (sigue REPROBADO) → permitido.
-- Es la última sección: el ROLLBACK final del archivo descarta todas las correcciones.
UPDATE SIS_ACA_PERIODO_ACADEMICO  SET PER_ESTADO = 'ABIERTO'  WHERE PER_ID = (SELECT PER_ID FROM t_per WHERE clave = '2025-1');
UPDATE SIS_ACA_ESTUDIANTE_PERIODO SET EPE_ESTADO = 'INSCRITO' WHERE EPE_ID = (SELECT EPE_ID FROM t_epe WHERE est = 'STU-2025-0005' AND per = '2025-1');

SELECT pg_temp.debe_fallar('N52', $$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 65, RES_CALIFICADO_EN = now()
                                    WHERE RES_ID = (SELECT RES_ID FROM t_res WHERE est = 'STU-2025-0005' AND per = '2025-1' AND cur = 'MAT-101')$$,
                           'SA208', NULL, 'corrección histórica 48 → 65 con un intento posterior (2026-I, 57)');
SELECT pg_temp.debe_pasar('N53', $$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 60, RES_CALIFICADO_EN = now()
                                    WHERE RES_ID = (SELECT RES_ID FROM t_res WHERE est = 'STU-2025-0005' AND per = '2025-1' AND cur = 'MAT-101')$$,
                          'corrección 48 → 60 con intento posterior: sigue REPROBADO, se permite');
SELECT pg_temp.ok('N54', (SELECT RES_ESTADO FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE WHERE EST_CODIGO = 'STU-2025-0005' AND CUR_CODIGO = 'MAT-101' AND ANL_ANIO = 2025) = 'REPROBADO'
                     AND (SELECT RES_TOTAL_INTENTOS FROM SIS_ACA_VW_INTENTO_CURSO WHERE EST_CODIGO = 'STU-2025-0005' AND CUR_CODIGO = 'MAT-101') = 2,
                  'tras la corrección permitida: 60 REPROBADO, se conservan los 2 intentos');

-- 58 → 61 SIN intento posterior: STU-2025-0007 (CASO G), ING-102 en 2025-II.
UPDATE SIS_ACA_PERIODO_ACADEMICO  SET PER_ESTADO = 'ABIERTO'  WHERE PER_ID = (SELECT PER_ID FROM t_per WHERE clave = '2025-2');
UPDATE SIS_ACA_ESTUDIANTE_PERIODO SET EPE_ESTADO = 'INSCRITO' WHERE EPE_ID = (SELECT EPE_ID FROM t_epe WHERE est = 'STU-2025-0007' AND per = '2025-2');
SELECT pg_temp.debe_pasar('N55', $$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 61, RES_CALIFICADO_EN = now()
                                    WHERE RES_ID = (SELECT RES_ID FROM t_res WHERE est = 'STU-2025-0007' AND per = '2025-2' AND cur = 'ING-102')$$,
                          'corrección 58 → 61 SIN intento posterior: se permite (pasa a APROBADO)');
SELECT pg_temp.ok('N56', (SELECT AVA_ESTADO_CICLO FROM SIS_ACA_VW_AVANCE_CICLO WHERE EST_CODIGO = 'STU-2025-0007' AND CIC_ANIO = 1 AND CIC_SEMESTRE = 2) = 'COMPLETO',
                  'la corrección permitida completa el ciclo de CASO G');

-- Aprobado → otra nota aprobatoria: CASO D, PRG-101 = 74 en 2026-I (su intento aprobado).
UPDATE SIS_ACA_PERIODO_ACADEMICO  SET PER_ESTADO = 'ABIERTO'  WHERE PER_ID = (SELECT PER_ID FROM t_per WHERE clave = '2026-1');
UPDATE SIS_ACA_ESTUDIANTE_PERIODO SET EPE_ESTADO = 'INSCRITO' WHERE EPE_ID = (SELECT EPE_ID FROM t_epe WHERE est = 'STU-2025-0004' AND per = '2026-1');
SELECT pg_temp.debe_pasar('N57', $$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 80, RES_CALIFICADO_EN = now()
                                    WHERE RES_ID = (SELECT RES_ID FROM t_res WHERE est = 'STU-2025-0004' AND per = '2026-1' AND cur = 'PRG-101')$$,
                          'aprobado → otra nota aprobatoria (74 → 80): se permite');

-- Política histórica distinta de 61: en 2028 rige POL-2028 (70).
-- STU-2026-0019 (registrado sin períodos) cursa PRG-101 en 2028-I con 65 (REPROBADO con 70)
-- y lo repite en 2028-II (intento posterior, pendiente).
INSERT INTO SIS_ACA_ANIO_LECTIVO (ANL_ANIO, ANL_NOMBRE, ANL_FECHA_INICIO, ANL_FECHA_FIN, ANL_ESTADO) VALUES (2028, 'Año lectivo 2028', DATE '2028-01-10', DATE '2028-11-30', 'ABIERTO');
INSERT INTO SIS_ACA_PERIODO_ACADEMICO (PER_ANL_ID, PER_NUMERO, PER_NOMBRE, PER_FECHA_INICIO, PER_FECHA_FIN, PER_ESTADO)
SELECT ANL_ID, x.n, x.nombre, x.ini, x.fin, 'ABIERTO' FROM SIS_ACA_ANIO_LECTIVO,
       (VALUES (1, 'Semestre I', DATE '2028-01-15', DATE '2028-06-15'), (2, 'Semestre II', DATE '2028-07-15', DATE '2028-11-15')) x(n, nombre, ini, fin)
WHERE ANL_ANIO = 2028;
INSERT INTO SIS_ACA_ESTUDIANTE_PERIODO (EPE_EPR_ID, EPE_PER_ID, EPE_CIC_ID, EPE_SEC_ID)
SELECT r.EPR_ID, t.PER_ID, k.CIC_ID, s.SEC_ID
FROM SIS_ACA_ESTUDIANTE_PROGRAMA r JOIN SIS_ACA_ESTUDIANTE e ON e.EST_ID = r.EPR_EST_ID AND e.EST_CODIGO = 'STU-2026-0019'
JOIN (VALUES ('2028-1', 1), ('2028-2', 2)) x(per, sem) ON true
JOIN t_per t ON t.clave = x.per JOIN SIS_ACA_CICLO_CURRICULAR k ON k.CIC_ANIO = 1 AND k.CIC_SEMESTRE = x.sem
JOIN SIS_ACA_SECCION s ON s.SEC_CODIGO = 'A';
INSERT INTO SIS_ACA_OFERTA_CURSO (OFE_PER_ID, OFE_PCU_ID, OFE_SEC_ID)
SELECT t.PER_ID, c.PCU_ID, s.SEC_ID
FROM t_per t, SIS_ACA_PENSUM_CURSO c JOIN SIS_ACA_PENSUM p ON p.PEN_ID = c.PCU_PEN_ID JOIN SIS_ACA_CURSO u ON u.CUR_ID = c.PCU_CUR_ID, SIS_ACA_SECCION s
WHERE t.clave IN ('2028-1', '2028-2') AND p.PEN_CODIGO = 'BCL-COMP-2025' AND u.CUR_CODIGO IN ('PRG-101', 'MAT-101') AND s.SEC_CODIGO = 'A';
INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID, RES_NOTA, RES_CALIFICADO_EN)
SELECT e.EPE_ID, o.OFE_ID, x.nota, CASE WHEN x.nota IS NULL THEN NULL ELSE now() END
FROM (VALUES ('2028-1', 'PRG-101', 65::numeric), ('2028-2', 'PRG-101', NULL),
             ('2028-1', 'MAT-101', 55),            ('2028-2', 'MAT-101', NULL)) x(per, cur, nota)
JOIN t_epe e ON e.est = 'STU-2026-0019' AND e.per = x.per
JOIN t_ofe o ON o.per = x.per AND o.pen = 'BCL-COMP-2025' AND o.cur = x.cur AND o.sec = 'A';
SELECT pg_temp.ok('N58', (SELECT RES_ESTADO || '/' || POL_CODIGO FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE WHERE EST_CODIGO = 'STU-2026-0019' AND CUR_CODIGO = 'PRG-101' AND ANL_ANIO = 2028 AND PER_NUMERO = 1)
                         = 'REPROBADO/POL-2028-01',
                  'en 2028 rige POL-2028: 65 es REPROBADO y el reintento en 2028-II fue admitido');
SELECT pg_temp.debe_fallar('N59', $$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 70, RES_CALIFICADO_EN = now()
                                    WHERE RES_ID = (SELECT RES_ID FROM t_res WHERE est = 'STU-2026-0019' AND per = '2028-1' AND cur = 'PRG-101')$$,
                           'SA208', NULL, 'política 70: 65 → 70 aprueba un intento con intento posterior (con 61 no se activaría: 65 ya aprobaba)');
SELECT pg_temp.debe_pasar('N60', $$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 65, RES_CALIFICADO_EN = now()
                                    WHERE RES_ID = (SELECT RES_ID FROM t_res WHERE est = 'STU-2026-0019' AND per = '2028-1' AND cur = 'MAT-101')$$,
                          'política 70: 55 → 65 sigue REPROBADO y se permite (con 61 habría sido SA208)');

-- Defensa en profundidad: tras todas las correcciones, D14 sigue en 0.
SELECT pg_temp.ok('N61', (SELECT count(*) FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE a JOIN SIS_ACA_VW_RESULTADO_ESTUDIANTE b
                          ON b.EPR_ID = a.EPR_ID AND b.PCU_ID = a.PCU_ID AND b.PER_FECHA_INICIO > a.PER_FECHA_INICIO
                          WHERE a.RES_ESTADO = 'APROBADO') = 0,
                  'D14 (intento posterior a una aprobación) = 0 después de todos los escenarios');

SELECT 'TOTAL: ' || pruebas || ' pruebas PASS' FROM t_conteo;
\echo '=== 11_negative_tests: todas las pruebas PASS ==='
ROLLBACK;
