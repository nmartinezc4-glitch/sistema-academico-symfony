-- =====================================================================
--  E1_smoke_test.sql — Evidencia del gate E1 (revisión 3: parche final)
--
--  Verifica que la ESTRUCTURA (constraints, triggers T1–T4 y vistas)
--  se comporta según lo aprobado. Usa un mini-dataset propio que vive
--  dentro de una transacción y se descarta con ROLLBACK: no deja datos.
--
--  NO sustituye a 11_negative_tests.sql / 13_positive_tests.sql (E3),
--  que correrán sobre el dataset realista de E2.
--
--  Uso (estructura sin datos):
--    psql -d sistema_academico_dev -v solo_estructura=1 -f run_all.sql
--    psql -d sistema_academico_dev -f E1_smoke_test.sql
--  Cada verificación imprime "PASS ..." o aborta con "FAIL ...".
--  Al final imprime el total de verificaciones ejecutadas.
-- =====================================================================
\set ON_ERROR_STOP on
\set QUIET on
\pset tuples_only on
\pset format unaligned
SET client_min_messages = notice;
BEGIN;

-- Guarda: el mini-dataset choca con el dataset demostrativo (años 2025/2026).
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM SIS_ACA_ESTUDIANTE) THEN
        RAISE EXCEPTION 'E1_smoke_test.sql requiere la estructura SIN datos. Ejecute: psql -d sistema_academico_dev -v solo_estructura=1 -f run_all.sql';
    END IF;
END $$;

CREATE TEMP TABLE t_conteo (n integer NOT NULL DEFAULT 0);
INSERT INTO t_conteo VALUES (0);

-- Aserción booleana
CREATE FUNCTION pg_temp.ok(p_cond boolean, p_msg text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    IF p_cond IS DISTINCT FROM true THEN
        RAISE EXCEPTION 'FAIL %', p_msg;
    END IF;
    UPDATE t_conteo SET n = n + 1;
    RAISE NOTICE 'PASS %', p_msg;
END $$;

-- Ejecuta SQL que DEBE fallar con un SQLSTATE concreto
CREATE FUNCTION pg_temp.debe_fallar(p_sql text, p_sqlstate text, p_msg text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        EXECUTE p_sql;
    EXCEPTION WHEN OTHERS THEN
        IF SQLSTATE = p_sqlstate THEN
            UPDATE t_conteo SET n = n + 1;
            RAISE NOTICE 'PASS [esperado %] %', p_sqlstate, p_msg;
            RETURN;
        END IF;
        RAISE EXCEPTION 'FAIL % — se esperaba %, se obtuvo % (%)', p_msg, p_sqlstate, SQLSTATE, SQLERRM;
    END;
    RAISE EXCEPTION 'FAIL % — se esperaba error %, pero la sentencia tuvo éxito', p_msg, p_sqlstate;
END $$;

-- Ejecuta SQL que DEBE tener éxito
CREATE FUNCTION pg_temp.debe_pasar(p_sql text, p_msg text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE p_sql;
    UPDATE t_conteo SET n = n + 1;
    RAISE NOTICE 'PASS [permitido] %', p_msg;
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'FAIL % — se esperaba éxito, se obtuvo % (%)', p_msg, SQLSTATE, SQLERRM;
END $$;

-- =====================================================================
-- Mini-dataset
-- =====================================================================
INSERT INTO SIS_ACA_POLITICA_ACADEMICA (POL_CODIGO, POL_NOMBRE, POL_NOTA_APROBACION, POL_VIGENTE_DESDE)
VALUES ('POL-T-2025', 'Política de prueba 2025', 61, DATE '2025-01-01');

INSERT INTO SIS_ACA_ANIO_LECTIVO (ANL_ANIO, ANL_NOMBRE, ANL_FECHA_INICIO, ANL_FECHA_FIN, ANL_ESTADO) VALUES
 (2025, 'Año lectivo 2025', DATE '2025-01-10', DATE '2025-11-30', 'ABIERTO'),
 (2026, 'Año lectivo 2026', DATE '2026-01-10', DATE '2026-11-30', 'ABIERTO');

-- PER_POL_ID omitido: T3 debe asignar la política vigente (E1-H6)
INSERT INTO SIS_ACA_PERIODO_ACADEMICO (PER_ANL_ID, PER_NUMERO, PER_NOMBRE, PER_FECHA_INICIO, PER_FECHA_FIN, PER_ESTADO)
SELECT a.ANL_ID, n, CASE n WHEN 1 THEN 'Semestre I' ELSE 'Semestre II' END,
       make_date(a.ANL_ANIO, CASE n WHEN 1 THEN 1 ELSE 7 END, 15),
       make_date(a.ANL_ANIO, CASE n WHEN 1 THEN 6 ELSE 11 END, 15), 'ABIERTO'
FROM SIS_ACA_ANIO_LECTIVO a CROSS JOIN generate_series(1, 2) n;

INSERT INTO SIS_ACA_CARRERA (CAR_CODIGO, CAR_NOMBRE) VALUES
 ('T-COMP', 'Carrera de prueba A'), ('T-COMR', 'Carrera de prueba B'), ('T-IND', 'Carrera de prueba C');
INSERT INTO SIS_ACA_PENSUM (PEN_CAR_ID, PEN_CODIGO, PEN_NOMBRE, PEN_VERSION, PEN_VIGENTE_DESDE)
SELECT CAR_ID, CAR_CODIGO || '-P1', 'Pensum ' || CAR_NOMBRE, 1, DATE '2025-01-01'
FROM SIS_ACA_CARRERA WHERE CAR_CODIGO IN ('T-COMP', 'T-COMR');

INSERT INTO SIS_ACA_CICLO_CURRICULAR (CIC_ANIO, CIC_SEMESTRE, CIC_NOMBRE) VALUES
 (1, 1, 'Año 1 / Semestre I'), (1, 2, 'Año 1 / Semestre II');
INSERT INTO SIS_ACA_SECCION (SEC_CODIGO, SEC_NOMBRE) VALUES ('A', 'Sección A'), ('B', 'Sección B');

INSERT INTO SIS_ACA_CURSO (CUR_CODIGO, CUR_NOMBRE) VALUES
 ('T-PRG1', 'Programación I'), ('T-MAT1', 'Matemática I'), ('T-ELE1', 'Optativo I'),
 ('T-PRG2', 'Programación II'), ('T-FIS2', 'Física II'), ('T-CON1', 'Contabilidad I');

-- Pensum A: ciclo 1 = PRG1, MAT1, ELE1 (optativo); ciclo 2 = PRG2, FIS2
INSERT INTO SIS_ACA_PENSUM_CURSO (PCU_PEN_ID, PCU_CUR_ID, PCU_CIC_ID, PCU_OBLIGATORIO, PCU_ORDEN)
SELECT p.PEN_ID, c.CUR_ID, k.CIC_ID, x.oblig, x.orden
FROM (VALUES ('T-PRG1', 1, true, 1), ('T-MAT1', 1, true, 2), ('T-ELE1', 1, false, 3),
             ('T-PRG2', 2, true, 1), ('T-FIS2', 2, true, 2)) x(cod, sem, oblig, orden)
JOIN SIS_ACA_CURSO c ON c.CUR_CODIGO = x.cod
JOIN SIS_ACA_CICLO_CURRICULAR k ON k.CIC_ANIO = 1 AND k.CIC_SEMESTRE = x.sem
JOIN SIS_ACA_PENSUM p ON p.PEN_CODIGO = 'T-COMP-P1';
-- Pensum B: ciclo 1 = CON1
INSERT INTO SIS_ACA_PENSUM_CURSO (PCU_PEN_ID, PCU_CUR_ID, PCU_CIC_ID, PCU_ORDEN)
SELECT p.PEN_ID, c.CUR_ID, k.CIC_ID, 1
FROM SIS_ACA_PENSUM p, SIS_ACA_CURSO c, SIS_ACA_CICLO_CURRICULAR k
WHERE p.PEN_CODIGO = 'T-COMR-P1' AND c.CUR_CODIGO = 'T-CON1' AND k.CIC_ANIO = 1 AND k.CIC_SEMESTRE = 1;

INSERT INTO SIS_ACA_ESTUDIANTE (EST_CODIGO, EST_NOMBRES, EST_APELLIDOS, EST_FECHA_NACIMIENTO) VALUES
 ('T-0001', 'Ana Lucía', 'López Ajú',     DATE '2009-03-14'),
 ('T-0002', 'Bryan',     'Tzul Morales',  DATE '2009-08-02'),
 ('T-0003', 'Carla',     'Xicará Pérez',  DATE '2009-11-20'),
 ('T-0004', 'Dora',      'Batz Coyoy',    DATE '2009-05-09');
INSERT INTO SIS_ACA_ESTUDIANTE_PROGRAMA (EPR_EST_ID, EPR_PEN_ID, EPR_FECHA_INICIO)
SELECT e.EST_ID, p.PEN_ID, DATE '2025-01-15'
FROM SIS_ACA_ESTUDIANTE e JOIN SIS_ACA_PENSUM p ON p.PEN_CODIGO = 'T-COMP-P1';

-- Vistas auxiliares del script (temporales)
CREATE TEMP VIEW t_per AS
  SELECT p.PER_ID, a.ANL_ANIO || '-' || p.PER_NUMERO AS clave
  FROM SIS_ACA_PERIODO_ACADEMICO p JOIN SIS_ACA_ANIO_LECTIVO a ON a.ANL_ID = p.PER_ANL_ID;
CREATE TEMP VIEW t_pcu AS
  SELECT c.PCU_ID, u.CUR_CODIGO FROM SIS_ACA_PENSUM_CURSO c JOIN SIS_ACA_CURSO u ON u.CUR_ID = c.PCU_CUR_ID;

-- Ubicación por período: (estudiante, período, ciclo semestre, sección)
INSERT INTO SIS_ACA_ESTUDIANTE_PERIODO (EPE_EPR_ID, EPE_PER_ID, EPE_CIC_ID, EPE_SEC_ID)
SELECT r.EPR_ID, t.PER_ID, k.CIC_ID, s.SEC_ID
FROM (VALUES ('T-0001', '2025-1', 1), ('T-0001', '2025-2', 2),
             ('T-0003', '2025-1', 1), ('T-0003', '2025-2', 2),
             ('T-0002', '2025-1', 1),
             ('T-0004', '2025-1', 1), ('T-0004', '2025-2', 2), ('T-0004', '2026-1', 1)) x(est, per, sem)
JOIN SIS_ACA_ESTUDIANTE e ON e.EST_CODIGO = x.est
JOIN SIS_ACA_ESTUDIANTE_PROGRAMA r ON r.EPR_EST_ID = e.EST_ID
JOIN t_per t ON t.clave = x.per
JOIN SIS_ACA_CICLO_CURRICULAR k ON k.CIC_ANIO = 1 AND k.CIC_SEMESTRE = x.sem
JOIN SIS_ACA_SECCION s ON s.SEC_CODIGO = 'A';

-- Ofertas: 2025-1 → PRG1/MAT1/ELE1 en A, PRG1 en B, CON1 en A (pensum B)
--          2025-2 → PRG2 en A, PRG1 en A (para repitentes). FIS2 sin oferta.
INSERT INTO SIS_ACA_OFERTA_CURSO (OFE_PER_ID, OFE_PCU_ID, OFE_SEC_ID)
SELECT t.PER_ID, c.PCU_ID, s.SEC_ID
FROM (VALUES ('2025-1', 'T-PRG1', 'A'), ('2025-1', 'T-MAT1', 'A'), ('2025-1', 'T-ELE1', 'A'),
             ('2025-1', 'T-PRG1', 'B'), ('2025-1', 'T-CON1', 'A'),
             ('2025-2', 'T-PRG2', 'A'), ('2025-2', 'T-PRG1', 'A')) x(per, cur, sec)
JOIN t_per t ON t.clave = x.per
JOIN t_pcu c ON c.CUR_CODIGO = x.cur
JOIN SIS_ACA_SECCION s ON s.SEC_CODIGO = x.sec;

CREATE TEMP VIEW t_ofe AS
  SELECT o.OFE_ID, t.clave AS per, c.CUR_CODIGO AS cur, s.SEC_CODIGO AS sec
  FROM SIS_ACA_OFERTA_CURSO o JOIN t_per t ON t.PER_ID = o.OFE_PER_ID
  JOIN t_pcu c ON c.PCU_ID = o.OFE_PCU_ID JOIN SIS_ACA_SECCION s ON s.SEC_ID = o.OFE_SEC_ID;
CREATE TEMP VIEW t_epe AS
  SELECT e.EPE_ID, s.EST_CODIGO AS est, t.clave AS per
  FROM SIS_ACA_ESTUDIANTE_PERIODO e
  JOIN SIS_ACA_ESTUDIANTE_PROGRAMA r ON r.EPR_ID = e.EPE_EPR_ID
  JOIN SIS_ACA_ESTUDIANTE s ON s.EST_ID = r.EPR_EST_ID
  JOIN t_per t ON t.PER_ID = e.EPE_PER_ID;
-- Resumen compacto de la pantalla de ingreso: CURSO:ORIGEN:ESTADO
CREATE TEMP VIEW t_ing AS
  SELECT e.est, e.per, string_agg(i.CUR_CODIGO || ':' || i.ING_ORIGEN || ':' || i.ING_ESTADO, ' ' ORDER BY i.CUR_CODIGO) AS filas
  FROM SIS_ACA_VW_INGRESO_NOTAS i JOIN t_epe e ON e.EPE_ID = i.EPE_ID
  GROUP BY e.est, e.per;

-- Resultados: Ana (aprueba PRG1 al 2.º intento) y Carla (reprueba PRG1)
INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID, RES_NOTA, RES_CALIFICADO_EN)
SELECT e.EPE_ID, o.OFE_ID, x.nota, CASE WHEN x.nota IS NULL THEN NULL ELSE now() END
FROM (VALUES ('T-0001', '2025-1', 'T-PRG1', 60.99::numeric), ('T-0001', '2025-1', 'T-MAT1', 61.00),
             ('T-0001', '2025-1', 'T-ELE1', NULL),           ('T-0001', '2025-2', 'T-PRG2', 65.00),
             ('T-0001', '2025-2', 'T-PRG1', 75.00),
             ('T-0003', '2025-1', 'T-PRG1', 55.00),           ('T-0003', '2025-1', 'T-MAT1', 70.00)) x(est, per, cur, nota)
JOIN t_epe e ON e.est = x.est AND e.per = x.per
JOIN t_ofe o ON o.per = x.per AND o.cur = x.cur AND o.sec = 'A';

-- =====================================================================
\echo '--- 1. Estructura y constraints ---'
-- =====================================================================
SELECT pg_temp.ok((SELECT count(*) FROM pg_tables WHERE tablename LIKE 'sis\_aca\_%') = 15, '15 tablas SIS_ACA_ creadas (14 núcleo + DOCENTE_OFERTA)');
SELECT pg_temp.ok((SELECT count(*) FROM pg_tables WHERE tablename LIKE 'sis\_seg\_%') = 4, '4 tablas SIS_SEG_ creadas');
SELECT pg_temp.ok((SELECT count(*) FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sis_seg_usuario' AND column_name = 'usu_foto_ruta') = 1, 'usuario de seguridad admite fotografía institucional');
SELECT pg_temp.ok((SELECT count(*) FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid
                   WHERE t.relname LIKE 'sis\_aca\_%' AND c.contype = 'f' AND c.confdeltype = 'c') = 0,
                  'ninguna FK con ON DELETE CASCADE');
SELECT pg_temp.ok((SELECT count(DISTINCT tgfoid) FROM pg_trigger t JOIN pg_class c ON c.oid = t.tgrelid
                   WHERE c.relname LIKE 'sis\_aca\_%' AND NOT t.tgisinternal) = 4,
                  'exactamente 4 funciones de trigger (T1–T4)');
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 101 WHERE RES_NOTA = 75$$, '23514', 'nota 101 → CK_RES_NOTA_RANGO');
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = -1  WHERE RES_NOTA = 75$$, '23514', 'nota -1 → CK_RES_NOTA_RANGO');
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_CALIFICADO_EN = NULL WHERE RES_NOTA = 75$$, '23514', 'nota sin fecha de calificación → CK_RES_NOTA_FECHA');
SELECT pg_temp.debe_fallar($$INSERT INTO SIS_ACA_ESTUDIANTE (EST_CODIGO, EST_NOMBRES, EST_APELLIDOS, EST_FECHA_NACIMIENTO) VALUES ('T-0001','X','Y','2009-01-01')$$, '23505', 'código de estudiante duplicado → UQ_EST_CODIGO');
SELECT pg_temp.debe_fallar($$INSERT INTO SIS_ACA_ESTUDIANTE (EST_CODIGO, EST_NOMBRES, EST_APELLIDOS, EST_FECHA_NACIMIENTO) VALUES ('T-0009','X','Y',NULL)$$, '23502', 'fecha de nacimiento obligatoria');
SELECT pg_temp.debe_fallar($$INSERT INTO SIS_ACA_ESTUDIANTE_PROGRAMA (EPR_EST_ID, EPR_PEN_ID, EPR_FECHA_INICIO) SELECT EPR_EST_ID, EPR_PEN_ID, DATE '2026-01-01' FROM SIS_ACA_ESTUDIANTE_PROGRAMA LIMIT 1$$, '23505', 'segundo programa ACTIVO del mismo estudiante → UX_EPR_EST_ACTIVO');
SELECT pg_temp.debe_fallar($$INSERT INTO SIS_ACA_PERIODO_ACADEMICO (PER_ANL_ID, PER_NUMERO, PER_NOMBRE, PER_FECHA_INICIO, PER_FECHA_FIN) SELECT PER_ANL_ID, 1, 'Dup', DATE '2025-01-15', DATE '2025-06-15' FROM SIS_ACA_PERIODO_ACADEMICO LIMIT 1$$, '23505', 'período duplicado año+número → UQ_PER_ANL_NUMERO');
SELECT pg_temp.debe_fallar($$INSERT INTO SIS_ACA_ANIO_LECTIVO (ANL_ANIO, ANL_NOMBRE, ANL_FECHA_INICIO, ANL_FECHA_FIN) VALUES (2030, 'X', DATE '2030-12-01', DATE '2030-01-01')$$, '23514', 'fechas invertidas → CK_ANL_FECHAS');
SELECT pg_temp.debe_fallar($$INSERT INTO SIS_ACA_PENSUM_CURSO (PCU_PEN_ID, PCU_CUR_ID, PCU_CIC_ID, PCU_ORDEN) SELECT PCU_PEN_ID, PCU_CUR_ID, PCU_CIC_ID, 99 FROM SIS_ACA_PENSUM_CURSO LIMIT 1$$, '23505', 'curso duplicado en el mismo pensum → UQ_PCU_PEN_CUR');
SELECT pg_temp.debe_fallar($$INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID) VALUES (999999, 999999)$$, '23503', 'FK inexistente → FK_RES_EPE / FK_RES_OFE');
SELECT pg_temp.debe_fallar($$INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID) SELECT RES_EPE_ID, RES_OFE_ID FROM SIS_ACA_RESULTADO_CURSO LIMIT 1$$, '23505', 'resultado duplicado estudiante+oferta → UQ_RES_EPE_OFE');
SELECT pg_temp.debe_fallar($$DELETE FROM SIS_ACA_CARRERA WHERE CAR_CODIGO = 'T-COMP'$$, '23503', 'no se borra una carrera con historial (RESTRICT)');

-- =====================================================================
\echo '--- 2. T1 updated_at ---'
-- =====================================================================
UPDATE SIS_ACA_ESTUDIANTE SET EST_ACTUALIZADO_EN = TIMESTAMPTZ '2000-01-01', EST_NOMBRES = 'Ana Lucía' WHERE EST_CODIGO = 'T-0001';
SELECT pg_temp.ok((SELECT EST_ACTUALIZADO_EN = now() FROM SIS_ACA_ESTUDIANTE WHERE EST_CODIGO = 'T-0001'), 'T1 sella EST_ACTUALIZADO_EN con now() (ignora valor manual)');

-- =====================================================================
\echo '--- 3. Estados derivados y política ---'
-- =====================================================================
SELECT pg_temp.ok((SELECT RES_ESTADO FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE WHERE RES_NOTA = 60.99) = 'REPROBADO', '60.99 → REPROBADO (sin redondeo)');
SELECT pg_temp.ok((SELECT RES_ESTADO FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE WHERE RES_NOTA = 61.00) = 'APROBADO',  '61.00 → APROBADO');
SELECT pg_temp.ok((SELECT RES_ESTADO FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE WHERE CUR_CODIGO = 'T-ELE1') = 'PENDIENTE', 'NULL → PENDIENTE');
SELECT pg_temp.ok((SELECT count(DISTINCT PER_POL_ID) = 1 AND bool_and(PER_POL_ID IS NOT NULL) FROM SIS_ACA_PERIODO_ACADEMICO), 'T3 asignó la política vigente a períodos creados sin PER_POL_ID (E1-H6)');

-- =====================================================================
\echo '--- 4. Repitencia e intentos ---'
-- =====================================================================
SELECT pg_temp.ok((SELECT RES_TOTAL_INTENTOS = 2 AND RES_PRIMERA_NOTA = 60.99 AND RES_ULTIMA_NOTA = 75 AND RES_MEJOR_NOTA = 75
                          AND RES_APROBADO AND PER_NOMBRE_APROBACION = '2025 / Semestre II'
                   FROM SIS_ACA_VW_INTENTO_CURSO WHERE CUR_CODIGO = 'T-PRG1' AND EST_CODIGO = 'T-0001'),
                  'Ana PRG1: 2 intentos, primera 60.99, última 75, aprobado en 2025 / Semestre II');
SELECT pg_temp.ok((SELECT array_agg(RES_NUMERO_INTENTO ORDER BY PER_FECHA_INICIO) = ARRAY[1,2]
                   FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE WHERE CUR_CODIGO = 'T-PRG1' AND EST_CODIGO = 'T-0001'),
                  'número de intento derivado 1, 2 (el primer intento no se destruye)');

-- =====================================================================
\echo '--- 5. Avance ---'
-- =====================================================================
SELECT pg_temp.ok((SELECT AVA_CURSOS_OBLIGATORIOS = 4 AND AVA_CURSOS_APROBADOS = 3 AND AVA_PORCENTAJE = 75.00 AND NOT AVA_PENSUM_COMPLETO
                   FROM SIS_ACA_VW_AVANCE_PENSUM WHERE EST_CODIGO = 'T-0001'),
                  'Ana avance 3/4 = 75 % (repetido cuenta una vez, optativo no cuenta)');
SELECT pg_temp.ok((SELECT string_agg(AVA_ESTADO_CICLO, ',' ORDER BY CIC_SEMESTRE) FROM SIS_ACA_VW_AVANCE_CICLO WHERE EST_CODIGO = 'T-0001') = 'COMPLETO,INCOMPLETO',
                  'Ana: ciclo 1 COMPLETO, ciclo 2 INCOMPLETO (FIS2 pendiente)');
SELECT pg_temp.ok((SELECT max(AVA_PORCENTAJE) <= 100 FROM SIS_ACA_VW_AVANCE_CICLO), 'ningún porcentaje > 100');

-- =====================================================================
\echo '--- 6. Ingreso de notas: descubrimiento de repitencias ---'
-- =====================================================================
SELECT pg_temp.ok((SELECT filas FROM t_ing WHERE est = 'T-0001' AND per = '2025-2')
                  = 'T-FIS2:CICLO_ACTUAL:SIN_OFERTA T-PRG1:CICLO_ANTERIOR:APROBADO T-PRG2:CICLO_ACTUAL:APROBADO',
                  'Ana 2025-II: ciclo actual (incluye SIN_OFERTA) + repitencia registrada');
SELECT pg_temp.ok((SELECT filas FROM t_ing WHERE est = 'T-0003' AND per = '2025-2')
                  = 'T-FIS2:CICLO_ACTUAL:SIN_OFERTA T-PRG1:CICLO_ANTERIOR:SIN_REGISTRO T-PRG2:CICLO_ACTUAL:SIN_REGISTRO',
                  'Carla 2025-II: PRG1 reprobado se DESCUBRE antes de crear el intento; MAT1 aprobado y ELE1 sin oferta no aparecen');
SELECT pg_temp.ok((SELECT ING_EDITABLE AND ING_MOTIVO_BLOQUEO IS NULL AND OFE_ACTIVO AND EPE_ESTADO = 'INSCRITO'
                   FROM SIS_ACA_VW_INGRESO_NOTAS i JOIN t_epe e ON e.EPE_ID = i.EPE_ID
                   WHERE e.est = 'T-0003' AND e.per = '2025-2' AND i.CUR_CODIGO = 'T-PRG1'),
                  'Carla PRG1 descubierto: editable, sin motivo de bloqueo, expone OFE_ACTIVO y EPE_ESTADO');
SELECT pg_temp.ok((SELECT NOT ING_EDITABLE AND ING_MOTIVO_BLOQUEO = 'SIN_OFERTA'
                   FROM SIS_ACA_VW_INGRESO_NOTAS i JOIN t_epe e ON e.EPE_ID = i.EPE_ID
                   WHERE e.est = 'T-0003' AND e.per = '2025-2' AND i.CUR_CODIGO = 'T-FIS2'),
                  'FIS2 sin oferta: ING_EDITABLE = false, motivo SIN_OFERTA');

-- Oferta inactiva: el curso descubierto desaparece; el registrado se bloquea
UPDATE SIS_ACA_OFERTA_CURSO SET OFE_ACTIVO = FALSE WHERE OFE_ID = (SELECT OFE_ID FROM t_ofe WHERE per = '2025-2' AND cur = 'T-PRG1');
SELECT pg_temp.ok((SELECT filas FROM t_ing WHERE est = 'T-0003' AND per = '2025-2') NOT LIKE '%T-PRG1%',
                  'oferta inactiva: PRG1 ya no se sugiere a Carla (requiere oferta activa)');
SELECT pg_temp.ok((SELECT NOT ING_EDITABLE AND ING_MOTIVO_BLOQUEO = 'OFERTA_INACTIVA' AND NOT OFE_ACTIVO
                   FROM SIS_ACA_VW_INGRESO_NOTAS i JOIN t_epe e ON e.EPE_ID = i.EPE_ID
                   WHERE e.est = 'T-0001' AND e.per = '2025-2' AND i.CUR_CODIGO = 'T-PRG1'),
                  'oferta inactiva: el intento ya registrado de Ana muestra OFERTA_INACTIVA');
UPDATE SIS_ACA_OFERTA_CURSO SET OFE_ACTIVO = TRUE WHERE OFE_ID = (SELECT OFE_ID FROM t_ofe WHERE per = '2025-2' AND cur = 'T-PRG1');

-- Estudiante no inscrito
UPDATE SIS_ACA_ESTUDIANTE_PERIODO SET EPE_ESTADO = 'RETIRADO' WHERE EPE_ID = (SELECT EPE_ID FROM t_epe WHERE est = 'T-0003' AND per = '2025-2');
SELECT pg_temp.ok((SELECT bool_and(NOT ING_EDITABLE) AND bool_and(ING_MOTIVO_BLOQUEO IN ('ESTUDIANTE_NO_INSCRITO', 'SIN_OFERTA'))
                          AND bool_or(ING_MOTIVO_BLOQUEO = 'ESTUDIANTE_NO_INSCRITO')
                   FROM SIS_ACA_VW_INGRESO_NOTAS i JOIN t_epe e ON e.EPE_ID = i.EPE_ID
                   WHERE e.est = 'T-0003' AND e.per = '2025-2'),
                  'estudiante RETIRADO: todas las filas bloqueadas con ESTUDIANTE_NO_INSCRITO');
UPDATE SIS_ACA_ESTUDIANTE_PERIODO SET EPE_ESTADO = 'INSCRITO' WHERE EPE_ID = (SELECT EPE_ID FROM t_epe WHERE est = 'T-0003' AND per = '2025-2');

-- Carla crea el nuevo intento desde la fila descubierta (usa OFE_ID de la vista)
SELECT pg_temp.debe_pasar($$INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID)
                             SELECT i.EPE_ID, i.OFE_ID FROM SIS_ACA_VW_INGRESO_NOTAS i JOIN t_epe e ON e.EPE_ID = i.EPE_ID
                             WHERE e.est = 'T-0003' AND e.per = '2025-2' AND i.CUR_CODIGO = 'T-PRG1'$$,
                          'Carla registra el 2.º intento de PRG1 usando el OFE_ID que expone la vista');
SELECT pg_temp.ok((SELECT filas FROM t_ing WHERE est = 'T-0003' AND per = '2025-2')
                  = 'T-FIS2:CICLO_ACTUAL:SIN_OFERTA T-PRG1:CICLO_ANTERIOR:PENDIENTE T-PRG2:CICLO_ACTUAL:SIN_REGISTRO',
                  'tras crear el intento, PRG1 pasa a PENDIENTE sin duplicar la fila');

-- Repetición de ciclo: curso ya aprobado antes → YA_APROBADO
INSERT INTO SIS_ACA_ESTUDIANTE_PERIODO (EPE_EPR_ID, EPE_PER_ID, EPE_CIC_ID, EPE_SEC_ID)
SELECT r.EPR_ID, t.PER_ID, k.CIC_ID, s.SEC_ID
FROM SIS_ACA_ESTUDIANTE_PROGRAMA r JOIN SIS_ACA_ESTUDIANTE e ON e.EST_ID = r.EPR_EST_ID AND e.EST_CODIGO = 'T-0001'
JOIN t_per t ON t.clave = '2026-1' JOIN SIS_ACA_CICLO_CURRICULAR k ON k.CIC_ANIO = 1 AND k.CIC_SEMESTRE = 1
JOIN SIS_ACA_SECCION s ON s.SEC_CODIGO = 'A';
INSERT INTO SIS_ACA_OFERTA_CURSO (OFE_PER_ID, OFE_PCU_ID, OFE_SEC_ID)
SELECT t.PER_ID, c.PCU_ID, s.SEC_ID FROM t_per t, t_pcu c, SIS_ACA_SECCION s
WHERE t.clave = '2026-1' AND c.CUR_CODIGO = 'T-MAT1' AND s.SEC_CODIGO = 'A';
SELECT pg_temp.ok((SELECT NOT ING_EDITABLE AND ING_MOTIVO_BLOQUEO = 'YA_APROBADO' AND ING_APROBADO_PREVIAMENTE
                   FROM SIS_ACA_VW_INGRESO_NOTAS i JOIN t_epe e ON e.EPE_ID = i.EPE_ID
                   WHERE e.est = 'T-0001' AND e.per = '2026-1' AND i.CUR_CODIGO = 'T-MAT1'),
                  'Ana repite ciclo en 2026-I: MAT1 (aprobado en 2025) bloqueado como YA_APROBADO');
SELECT pg_temp.ok((SELECT count(*) = count(DISTINCT (EPE_ID, PCU_ID)) FROM SIS_ACA_VW_INGRESO_NOTAS), 'clave (EPE_ID, PCU_ID) única en VW_INGRESO_NOTAS');

-- =====================================================================
\echo '--- 7. T2 coherencia del resultado ---'
-- =====================================================================
CREATE TEMP VIEW t_bryan AS SELECT EPE_ID FROM t_epe WHERE est = 'T-0002' AND per = '2025-1';
SELECT pg_temp.debe_fallar($$INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID) SELECT b.EPE_ID, o.OFE_ID FROM t_bryan b, t_ofe o WHERE o.per = '2025-2' AND o.cur = 'T-PRG2'$$, 'SA201', 'oferta de otro período');
SELECT pg_temp.debe_fallar($$INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID) SELECT b.EPE_ID, o.OFE_ID FROM t_bryan b, t_ofe o WHERE o.per = '2025-1' AND o.cur = 'T-CON1'$$, 'SA202', 'oferta de otro pensum');
SELECT pg_temp.debe_fallar($$INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID) SELECT b.EPE_ID, o.OFE_ID FROM t_bryan b, t_ofe o WHERE o.per = '2025-1' AND o.cur = 'T-PRG1' AND o.sec = 'B'$$, 'SA203', 'oferta de otra sección (S1)');
SELECT pg_temp.debe_pasar($$INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID) SELECT b.EPE_ID, o.OFE_ID FROM t_bryan b, t_ofe o WHERE o.per = '2025-1' AND o.cur = 'T-PRG1' AND o.sec = 'A'$$, 'resultado en contexto correcto se registra');

-- =====================================================================
\echo '--- 8. T2 estudiante no INSCRITO (SA205) ---'
-- =====================================================================
UPDATE SIS_ACA_ESTUDIANTE_PERIODO SET EPE_ESTADO = 'RETIRADO' WHERE EPE_ID IN (SELECT EPE_ID FROM t_bryan);
SELECT pg_temp.debe_fallar($$INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID) SELECT b.EPE_ID, o.OFE_ID FROM t_bryan b, t_ofe o WHERE o.per = '2025-1' AND o.cur = 'T-MAT1'$$, 'SA205', 'INSERT con estudiante RETIRADO');
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 80, RES_CALIFICADO_EN = now() WHERE RES_EPE_ID IN (SELECT EPE_ID FROM t_bryan)$$, 'SA205', 'UPDATE con estudiante RETIRADO');
SELECT pg_temp.debe_fallar($$DELETE FROM SIS_ACA_RESULTADO_CURSO WHERE RES_EPE_ID IN (SELECT EPE_ID FROM t_bryan)$$, 'SA205', 'DELETE con estudiante RETIRADO');
UPDATE SIS_ACA_ESTUDIANTE_PERIODO SET EPE_ESTADO = 'FINALIZADO' WHERE EPE_ID IN (SELECT EPE_ID FROM t_bryan);
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 80, RES_CALIFICADO_EN = now() WHERE RES_EPE_ID IN (SELECT EPE_ID FROM t_bryan)$$, 'SA205', 'UPDATE con estudiante FINALIZADO');
UPDATE SIS_ACA_ESTUDIANTE_PERIODO SET EPE_ESTADO = 'INSCRITO' WHERE EPE_ID IN (SELECT EPE_ID FROM t_bryan);
SELECT pg_temp.debe_pasar($$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 80, RES_CALIFICADO_EN = now() WHERE RES_EPE_ID IN (SELECT EPE_ID FROM t_bryan)$$, 'de nuevo INSCRITO: la nota se registra');

-- =====================================================================
\echo '--- 9. T2 oferta inactiva (SA206) ---'
-- =====================================================================
UPDATE SIS_ACA_OFERTA_CURSO SET OFE_ACTIVO = FALSE WHERE OFE_ID = (SELECT OFE_ID FROM t_ofe WHERE per = '2025-1' AND cur = 'T-MAT1');
SELECT pg_temp.debe_fallar($$INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID) SELECT b.EPE_ID, o.OFE_ID FROM t_bryan b, t_ofe o WHERE o.per = '2025-1' AND o.cur = 'T-MAT1'$$, 'SA206', 'INSERT en oferta inactiva');
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 62, RES_CALIFICADO_EN = now() WHERE RES_NOTA = 61.00$$, 'SA206', 'UPDATE en oferta inactiva');
SELECT pg_temp.debe_fallar($$DELETE FROM SIS_ACA_RESULTADO_CURSO WHERE RES_NOTA = 61.00$$, 'SA206', 'DELETE en oferta inactiva');
UPDATE SIS_ACA_OFERTA_CURSO SET OFE_ACTIVO = TRUE WHERE OFE_ID = (SELECT OFE_ID FROM t_ofe WHERE per = '2025-1' AND cur = 'T-MAT1');
SELECT pg_temp.debe_pasar($$INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID) SELECT b.EPE_ID, o.OFE_ID FROM t_bryan b, t_ofe o WHERE o.per = '2025-1' AND o.cur = 'T-MAT1'$$, 'oferta reactivada: el registro se permite');

-- =====================================================================
\echo '--- 10. T2 período CERRADO (SA204) ---'
-- =====================================================================
UPDATE SIS_ACA_PERIODO_ACADEMICO SET PER_ESTADO = 'CERRADO' WHERE PER_ID = (SELECT PER_ID FROM t_per WHERE clave = '2025-1');
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 62, RES_CALIFICADO_EN = now() WHERE RES_NOTA = 60.99$$, 'SA204', 'UPDATE en período cerrado');
SELECT pg_temp.debe_fallar($$DELETE FROM SIS_ACA_RESULTADO_CURSO WHERE RES_NOTA = 60.99$$, 'SA204', 'DELETE en período cerrado');
SELECT pg_temp.debe_fallar($$INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID) SELECT b.EPE_ID, o.OFE_ID FROM t_bryan b, t_ofe o WHERE o.per = '2025-1' AND o.cur = 'T-ELE1'$$, 'SA204', 'INSERT en período cerrado');
SELECT pg_temp.ok((SELECT bool_and(NOT ING_EDITABLE AND ING_MOTIVO_BLOQUEO = 'PERIODO_NO_ABIERTO')
                   FROM SIS_ACA_VW_INGRESO_NOTAS i JOIN t_epe e ON e.EPE_ID = i.EPE_ID WHERE e.per = '2025-1'),
                  'ingreso de notas: todo 2025-I (CERRADO) bloqueado con PERIODO_NO_ABIERTO');
UPDATE SIS_ACA_PERIODO_ACADEMICO SET PER_ESTADO = 'ABIERTO' WHERE PER_ID = (SELECT PER_ID FROM t_per WHERE clave = '2025-1');
SELECT pg_temp.debe_pasar($$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 60.99, RES_CALIFICADO_EN = now() WHERE RES_NOTA = 60.99$$, 'tras reapertura explícita, la corrección se permite');

-- =====================================================================
\echo '--- 10b. T2 período PLANIFICADO (SA204 PERIODO_NO_ABIERTO) ---'
-- =====================================================================
UPDATE SIS_ACA_PERIODO_ACADEMICO SET PER_ESTADO = 'PLANIFICADO' WHERE PER_ID = (SELECT PER_ID FROM t_per WHERE clave = '2025-2');
SELECT pg_temp.debe_fallar($$INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID) SELECT e.EPE_ID, o.OFE_ID FROM t_epe e, t_ofe o WHERE e.est = 'T-0003' AND e.per = '2025-2' AND o.per = '2025-2' AND o.cur = 'T-PRG2'$$, 'SA204', 'INSERT en período PLANIFICADO');
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 66, RES_CALIFICADO_EN = now() WHERE RES_NOTA = 65$$, 'SA204', 'UPDATE en período PLANIFICADO');
SELECT pg_temp.debe_fallar($$DELETE FROM SIS_ACA_RESULTADO_CURSO WHERE RES_NOTA = 65$$, 'SA204', 'DELETE en período PLANIFICADO');
SELECT pg_temp.ok((SELECT bool_and(NOT ING_EDITABLE AND ING_MOTIVO_BLOQUEO = 'PERIODO_NO_ABIERTO')
                   FROM SIS_ACA_VW_INGRESO_NOTAS i JOIN t_epe e ON e.EPE_ID = i.EPE_ID WHERE e.per = '2025-2'),
                  'ingreso de notas: todo 2025-II (PLANIFICADO) bloqueado con PERIODO_NO_ABIERTO');
UPDATE SIS_ACA_PERIODO_ACADEMICO SET PER_ESTADO = 'ABIERTO' WHERE PER_ID = (SELECT PER_ID FROM t_per WHERE clave = '2025-2');
SELECT pg_temp.debe_pasar($$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 65, RES_CALIFICADO_EN = now() WHERE RES_NOTA = 65$$, 'período ABIERTO: UPDATE de nota permitido');
SELECT pg_temp.ok((SELECT count(*) FILTER (WHERE ING_MOTIVO_BLOQUEO = 'PERIODO_NO_ABIERTO') = 0
                   FROM SIS_ACA_VW_INGRESO_NOTAS i JOIN t_epe e ON e.EPE_ID = i.EPE_ID WHERE e.per = '2025-2'),
                  'período ABIERTO: la vista ya no muestra PERIODO_NO_ABIERTO');

-- =====================================================================
\echo '--- 10c. T4 identidad del resultado (SA401) ---'
-- =====================================================================
-- Destinos VÁLIDOS para T2 (mismo período, pensum y sección; INSCRITO; oferta activa):
-- el rechazo debe venir de T4, que corre antes que T2 en RESULTADO_CURSO.
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_EPE_ID = (SELECT EPE_ID FROM t_epe WHERE est = 'T-0003' AND per = '2025-2')
                              WHERE RES_EPE_ID = (SELECT EPE_ID FROM t_epe WHERE est = 'T-0001' AND per = '2025-2')
                                AND RES_OFE_ID = (SELECT OFE_ID FROM t_ofe WHERE per = '2025-2' AND cur = 'T-PRG2')$$,
                           'SA401', 'UPDATE de RES_EPE_ID (mover el intento a otro estudiante)');
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_OFE_ID = (SELECT OFE_ID FROM t_ofe WHERE per = '2025-1' AND cur = 'T-ELE1')
                              WHERE RES_NOTA = 60.99$$,
                           'SA401', 'UPDATE de RES_OFE_ID (mover el intento a otra oferta)');
SELECT pg_temp.debe_pasar($$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_EPE_ID = RES_EPE_ID, RES_OFE_ID = RES_OFE_ID WHERE RES_NOTA = 65$$,
                          'UPDATE que reescribe la identidad con el mismo valor se permite');
SELECT pg_temp.debe_pasar($$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 72, RES_CALIFICADO_EN = now()
                              WHERE RES_OFE_ID = (SELECT OFE_ID FROM t_ofe WHERE per = '2025-1' AND cur = 'T-ELE1')
                                AND RES_EPE_ID = (SELECT EPE_ID FROM t_epe WHERE est = 'T-0001' AND per = '2025-1')$$,
                          'edición legítima de nota (PENDIENTE → 72) con período ABIERTO');
SELECT pg_temp.ok((SELECT RES_ESTADO FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE WHERE EST_CODIGO = 'T-0001' AND CUR_CODIGO = 'T-ELE1') = 'APROBADO',
                  'la nota editada se refleja en el estado derivado');
-- Corrección por DELETE + INSERT
SELECT pg_temp.debe_pasar($$INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID) SELECT e.EPE_ID, o.OFE_ID FROM t_epe e, t_ofe o WHERE e.est = 'T-0003' AND e.per = '2025-2' AND o.per = '2025-2' AND o.cur = 'T-PRG2'$$,
                          'Carla: intento de PRG2 registrado');
SELECT pg_temp.debe_pasar($$DELETE FROM SIS_ACA_RESULTADO_CURSO WHERE RES_EPE_ID = (SELECT EPE_ID FROM t_epe WHERE est = 'T-0003' AND per = '2025-2') AND RES_OFE_ID = (SELECT OFE_ID FROM t_ofe WHERE per = '2025-2' AND cur = 'T-PRG2')$$,
                          'corrección: DELETE del intento con período/estudiante/oferta mutables');
SELECT pg_temp.debe_pasar($$INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID) SELECT e.EPE_ID, o.OFE_ID FROM t_epe e, t_ofe o WHERE e.est = 'T-0003' AND e.per = '2025-2' AND o.per = '2025-2' AND o.cur = 'T-PRG2'$$,
                          'corrección: INSERT del intento en el contexto correcto');

-- =====================================================================
\echo '--- 10d. D6: nuevo intento de curso ya aprobado (SA207) + frontera 60.99 / 61.00 ---'
-- =====================================================================
INSERT INTO SIS_ACA_OFERTA_CURSO (OFE_PER_ID, OFE_PCU_ID, OFE_SEC_ID)
SELECT t.PER_ID, c.PCU_ID, s.SEC_ID FROM t_per t, t_pcu c, SIS_ACA_SECCION s
WHERE t.clave = '2026-1' AND c.CUR_CODIGO = 'T-PRG1' AND s.SEC_CODIGO = 'A';
-- Dora: 60.99 (REPROBADO) → reintento → 61.00 (APROBADO) → nuevo intento prohibido
SELECT pg_temp.debe_pasar($$INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID, RES_NOTA, RES_CALIFICADO_EN) SELECT e.EPE_ID, o.OFE_ID, 60.99, now() FROM t_epe e, t_ofe o WHERE e.est = 'T-0004' AND e.per = '2025-1' AND o.per = '2025-1' AND o.cur = 'T-PRG1' AND o.sec = 'A'$$,
                          'Dora 2025-I PRG1 = 60.99');
SELECT pg_temp.debe_pasar($$INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID) SELECT e.EPE_ID, o.OFE_ID FROM t_epe e, t_ofe o WHERE e.est = 'T-0004' AND e.per = '2025-2' AND o.per = '2025-2' AND o.cur = 'T-PRG1'$$,
                          'frontera: 60.99 previo NO impide un nuevo intento');
SELECT pg_temp.debe_pasar($$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 61.00, RES_CALIFICADO_EN = now() WHERE RES_EPE_ID = (SELECT EPE_ID FROM t_epe WHERE est = 'T-0004' AND per = '2025-2')$$,
                          'Dora 2025-II PRG1 = 61.00 (edición legítima del intento pendiente)');
SELECT pg_temp.ok((SELECT string_agg(RES_NOTA || '=' || RES_ESTADO, ' → ' ORDER BY PER_FECHA_INICIO) FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE WHERE EST_CODIGO = 'T-0004' AND CUR_CODIGO = 'T-PRG1')
                  = '60.99=REPROBADO → 61.00=APROBADO',
                  'frontera: 60.99 REPROBADO y 61.00 APROBADO; el intento reprobado se conserva');
SELECT pg_temp.debe_fallar($$INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID) SELECT e.EPE_ID, o.OFE_ID FROM t_epe e, t_ofe o WHERE e.est = 'T-0004' AND e.per = '2026-1' AND o.per = '2026-1' AND o.cur = 'T-PRG1'$$,
                           'SA207', 'frontera: 61.00 aprobado → nuevo intento posterior prohibido');
SELECT pg_temp.ok((SELECT NOT ING_EDITABLE AND ING_MOTIVO_BLOQUEO = 'YA_APROBADO'
                   FROM SIS_ACA_VW_INGRESO_NOTAS i JOIN t_epe e ON e.EPE_ID = i.EPE_ID
                   WHERE e.est = 'T-0004' AND e.per = '2026-1' AND i.CUR_CODIGO = 'T-PRG1'),
                  'la vista anticipa SA207 con YA_APROBADO');
-- Carla: 55 → 61 es válido
SELECT pg_temp.debe_pasar($$UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 61, RES_CALIFICADO_EN = now()
                              WHERE RES_EPE_ID = (SELECT EPE_ID FROM t_epe WHERE est = 'T-0003' AND per = '2025-2')
                                AND RES_OFE_ID = (SELECT OFE_ID FROM t_ofe WHERE per = '2025-2' AND cur = 'T-PRG1')$$,
                          'Carla 55 → 61: válido');
SELECT pg_temp.ok((SELECT RES_TOTAL_INTENTOS = 2 AND RES_PRIMERA_NOTA = 55 AND RES_APROBADO FROM SIS_ACA_VW_INTENTO_CURSO WHERE EST_CODIGO = 'T-0003' AND CUR_CODIGO = 'T-PRG1'),
                  'Carla PRG1: 2 intentos, el 55 se conserva y el curso queda aprobado');
-- Ana: MAT1 aprobado con 61.00 en 2025-I → nuevo intento en 2026-I prohibido
SELECT pg_temp.debe_fallar($$INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID) SELECT e.EPE_ID, o.OFE_ID FROM t_epe e, t_ofe o WHERE e.est = 'T-0001' AND e.per = '2026-1' AND o.per = '2026-1' AND o.cur = 'T-MAT1'$$,
                           'SA207', 'Ana MAT1 61.00 en 2025 → nuevo intento en 2026 prohibido');

-- =====================================================================
\echo '--- 11. T4 contexto congelado: resultados, ofertas y pensum ---'
-- =====================================================================
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_ESTUDIANTE_PERIODO SET EPE_SEC_ID = (SELECT SEC_ID FROM SIS_ACA_SECCION WHERE SEC_CODIGO = 'B') WHERE EPE_ID IN (SELECT EPE_ID FROM t_bryan)$$, 'SA401', 'EPE_SEC_ID congelado con resultados');
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_ESTUDIANTE_PERIODO SET EPE_CIC_ID = (SELECT CIC_ID FROM SIS_ACA_CICLO_CURRICULAR WHERE CIC_SEMESTRE = 2) WHERE EPE_ID IN (SELECT EPE_ID FROM t_bryan)$$, 'SA401', 'EPE_CIC_ID congelado con resultados');
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_ESTUDIANTE_PROGRAMA SET EPR_PEN_ID = (SELECT PEN_ID FROM SIS_ACA_PENSUM WHERE PEN_CODIGO = 'T-COMR-P1') WHERE EPR_EST_ID = (SELECT EST_ID FROM SIS_ACA_ESTUDIANTE WHERE EST_CODIGO = 'T-0001')$$, 'SA401', 'EPR_PEN_ID congelado con resultados');
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_OFERTA_CURSO SET OFE_SEC_ID = (SELECT SEC_ID FROM SIS_ACA_SECCION WHERE SEC_CODIGO = 'B') WHERE OFE_ID = (SELECT OFE_ID FROM t_ofe WHERE per = '2025-2' AND cur = 'T-PRG2')$$, 'SA401', 'OFE_SEC_ID congelado con resultados');
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_PENSUM_CURSO SET PCU_CUR_ID = (SELECT CUR_ID FROM SIS_ACA_CURSO WHERE CUR_CODIGO = 'T-CON1') WHERE PCU_ID = (SELECT PCU_ID FROM t_pcu WHERE CUR_CODIGO = 'T-PRG1')$$, 'SA401', 'PCU_CUR_ID congelado con resultados (E1-H1)');
SELECT pg_temp.debe_pasar($$UPDATE SIS_ACA_ESTUDIANTE_PERIODO SET EPE_ESTADO = 'FINALIZADO' WHERE EPE_ID IN (SELECT EPE_ID FROM t_bryan)$$, 'columnas no contextuales (EPE_ESTADO) siguen editables');
SELECT pg_temp.debe_pasar($$UPDATE SIS_ACA_OFERTA_CURSO SET OFE_SEC_ID = (SELECT SEC_ID FROM SIS_ACA_SECCION WHERE SEC_CODIGO = 'B') WHERE OFE_ID = (SELECT OFE_ID FROM t_ofe WHERE per = '2025-1' AND cur = 'T-CON1')$$, 'oferta SIN resultados puede cambiar de sección');
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_PENSUM SET PEN_CAR_ID = (SELECT CAR_ID FROM SIS_ACA_CARRERA WHERE CAR_CODIGO = 'T-IND') WHERE PEN_CODIGO = 'T-COMP-P1'$$, 'SA401', 'PEN_CAR_ID congelado: hay estudiantes con el pensum');
SELECT pg_temp.debe_pasar($$UPDATE SIS_ACA_PENSUM SET PEN_CAR_ID = (SELECT CAR_ID FROM SIS_ACA_CARRERA WHERE CAR_CODIGO = 'T-IND') WHERE PEN_CODIGO = 'T-COMR-P1'$$, 'pensum SIN estudiantes puede cambiar de carrera');
SELECT pg_temp.debe_pasar($$UPDATE SIS_ACA_PENSUM SET PEN_NOMBRE = 'Pensum renombrado' WHERE PEN_CODIGO = 'T-COMP-P1'$$, 'nombre de pensum con estudiantes sigue editable');

-- =====================================================================
\echo '--- 12. T4 contexto congelado: período, año lectivo y ciclo ---'
-- =====================================================================
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_PERIODO_ACADEMICO SET PER_FECHA_FIN = DATE '2025-06-30' WHERE PER_ID = (SELECT PER_ID FROM t_per WHERE clave = '2025-1')$$, 'SA401', 'PER_FECHA_FIN congelada con resultados');
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_PERIODO_ACADEMICO SET PER_FECHA_INICIO = DATE '2025-01-20' WHERE PER_ID = (SELECT PER_ID FROM t_per WHERE clave = '2025-1')$$, 'SA401', 'PER_FECHA_INICIO congelada (misma política: T3 la acepta, T4 la bloquea)');
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_PERIODO_ACADEMICO SET PER_NUMERO = 3 WHERE PER_ID = (SELECT PER_ID FROM t_per WHERE clave = '2025-1')$$, 'SA401', 'PER_NUMERO congelado con resultados');
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_PERIODO_ACADEMICO SET PER_ANL_ID = (SELECT ANL_ID FROM SIS_ACA_ANIO_LECTIVO WHERE ANL_ANIO = 2026), PER_NUMERO = 3 WHERE PER_ID = (SELECT PER_ID FROM t_per WHERE clave = '2025-1')$$, 'SA401', 'PER_ANL_ID congelado con resultados');
SELECT pg_temp.debe_pasar($$UPDATE SIS_ACA_PERIODO_ACADEMICO SET PER_NOMBRE = 'Primer semestre' WHERE PER_ID = (SELECT PER_ID FROM t_per WHERE clave = '2025-1')$$, 'PER_NOMBRE de período con resultados sigue editable');
SELECT pg_temp.debe_pasar($$UPDATE SIS_ACA_PERIODO_ACADEMICO SET PER_FECHA_INICIO = DATE '2026-07-20', PER_FECHA_FIN = DATE '2026-11-20' WHERE PER_ID = (SELECT PER_ID FROM t_per WHERE clave = '2026-2')$$, 'período SIN resultados puede cambiar fechas');
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_ANIO_LECTIVO SET ANL_ANIO = 2024 WHERE ANL_ANIO = 2025$$, 'SA401', 'ANL_ANIO congelado: sus períodos tienen resultados');
SELECT pg_temp.debe_pasar($$UPDATE SIS_ACA_ANIO_LECTIVO SET ANL_ANIO = 2027 WHERE ANL_ANIO = 2026$$, 'año SIN resultados puede cambiar ANL_ANIO');
UPDATE SIS_ACA_ANIO_LECTIVO SET ANL_ANIO = 2026 WHERE ANL_ANIO = 2027;
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_CICLO_CURRICULAR SET CIC_SEMESTRE = 3 WHERE CIC_ANIO = 1 AND CIC_SEMESTRE = 2$$, 'SA401', 'CIC_SEMESTRE congelado: ciclo referenciado');
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_CICLO_CURRICULAR SET CIC_ANIO = 5 WHERE CIC_ANIO = 1 AND CIC_SEMESTRE = 1$$, 'SA401', 'CIC_ANIO congelado: ciclo referenciado');
INSERT INTO SIS_ACA_CICLO_CURRICULAR (CIC_ANIO, CIC_SEMESTRE, CIC_NOMBRE) VALUES (2, 1, 'Año 2 / Semestre I');
SELECT pg_temp.debe_pasar($$UPDATE SIS_ACA_CICLO_CURRICULAR SET CIC_SEMESTRE = 2, CIC_NOMBRE = 'Año 2 / Semestre II' WHERE CIC_ANIO = 2 AND CIC_SEMESTRE = 1$$, 'ciclo SIN referencias puede cambiar año/semestre');
SELECT pg_temp.debe_pasar($$UPDATE SIS_ACA_CICLO_CURRICULAR SET CIC_NOMBRE = 'Primer año, primer semestre' WHERE CIC_ANIO = 1 AND CIC_SEMESTRE = 1$$, 'CIC_NOMBRE de ciclo referenciado sigue editable');

-- =====================================================================
\echo '--- 13. T3 política ---'
-- =====================================================================
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_POLITICA_ACADEMICA SET POL_NOTA_APROBACION = 70 WHERE POL_CODIGO = 'POL-T-2025'$$, 'SA303', 'nota de política usada protegida');
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_POLITICA_ACADEMICA SET POL_VIGENTE_DESDE = DATE '2024-06-01' WHERE POL_CODIGO = 'POL-T-2025'$$, 'SA303', 'vigencia de política usada protegida');
SELECT pg_temp.debe_pasar($$UPDATE SIS_ACA_POLITICA_ACADEMICA SET POL_NOMBRE = 'Política de prueba 2025 (renombrada)' WHERE POL_CODIGO = 'POL-T-2025'$$, 'nombre de política usada sigue editable');
SELECT pg_temp.debe_fallar($$INSERT INTO SIS_ACA_POLITICA_ACADEMICA (POL_CODIGO, POL_NOMBRE, POL_NOTA_APROBACION, POL_VIGENTE_DESDE) VALUES ('POL-RETRO', 'Retroactiva', 65, DATE '2025-06-01')$$, 'SA304', 'política retroactiva que absorbería 2025-II');
SELECT pg_temp.debe_fallar($$INSERT INTO SIS_ACA_ANIO_LECTIVO (ANL_ANIO, ANL_NOMBRE, ANL_FECHA_INICIO, ANL_FECHA_FIN) VALUES (2024, '2024', DATE '2024-01-10', DATE '2024-11-30');
                              INSERT INTO SIS_ACA_PERIODO_ACADEMICO (PER_ANL_ID, PER_NUMERO, PER_NOMBRE, PER_FECHA_INICIO, PER_FECHA_FIN) SELECT ANL_ID, 1, 'Semestre I', DATE '2024-01-15', DATE '2024-06-15' FROM SIS_ACA_ANIO_LECTIVO WHERE ANL_ANIO = 2024$$,
                           'SA301', 'período sin política vigente en su fecha de inicio');

-- §47 Validación histórica: crear POL-2028 = 70 no cambia los resultados 2025
INSERT INTO SIS_ACA_POLITICA_ACADEMICA (POL_CODIGO, POL_NOMBRE, POL_NOTA_APROBACION, POL_VIGENTE_DESDE)
VALUES ('POL-T-2028', 'Política de prueba 2028', 70, DATE '2028-01-01');
SELECT pg_temp.ok((SELECT RES_ESTADO FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE WHERE RES_NOTA = 65 AND CUR_CODIGO = 'T-PRG2') = 'APROBADO',
                  '§47: nota 65 de 2025 sigue APROBADA tras crear política 2028 (70)');
SELECT pg_temp.ok((SELECT POL_VIGENTE_HASTA FROM SIS_ACA_VW_POLITICA_LINEA_TIEMPO WHERE POL_CODIGO = 'POL-T-2025') = DATE '2027-12-31',
                  'vigencia derivada: POL-T-2025 hasta 2027-12-31');
SELECT pg_temp.ok((SELECT POL_CODIGO FROM SIS_ACA_VW_POLITICA_VIGENTE) = 'POL-T-2025', 'política vigente hoy ignora la futura (2028)');
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_PERIODO_ACADEMICO SET PER_POL_ID = (SELECT POL_ID FROM SIS_ACA_POLITICA_ACADEMICA WHERE POL_CODIGO = 'POL-T-2028') WHERE PER_ID = (SELECT PER_ID FROM t_per WHERE clave = '2026-1')$$,
                           'SA302', 'política explícita incorrecta rechazada (2026-I no puede usar 2028)');
SELECT pg_temp.debe_fallar($$UPDATE SIS_ACA_PERIODO_ACADEMICO SET PER_FECHA_INICIO = DATE '2028-01-15', PER_FECHA_FIN = DATE '2028-06-15',
                                     PER_POL_ID = (SELECT POL_ID FROM SIS_ACA_POLITICA_ACADEMICA WHERE POL_CODIGO = 'POL-T-2028')
                              WHERE PER_ID = (SELECT PER_ID FROM t_per WHERE clave = '2025-2')$$,
                           'SA305', 'no se cambia la política de un período con resultados');

SELECT 'TOTAL: ' || n || ' verificaciones PASS' FROM t_conteo;
\echo '=== E1 smoke test: todas las verificaciones PASS ==='
ROLLBACK;
