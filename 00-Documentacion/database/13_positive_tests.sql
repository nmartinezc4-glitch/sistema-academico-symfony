-- =====================================================================
--  13_positive_tests.sql — E3 · Pruebas positivas (§32), validación
--  histórica (§47) y criterios de aceptación del modelo (§46 A–P)
--
--  P1 · Flujo completo de alta: carrera → pensum → cursos → estudiante →
--       año/período → inscripción → oferta → notas → repitencia.
--  P2 · §47: una reforma futura (70) no altera notas históricas (61).
--  P3 · §46: las 16 preguntas de aceptación respondidas sobre el dataset.
--
--  Todo corre en una transacción que termina en ROLLBACK: no deja datos.
--  Uso (después de run_all.sql):
--    psql -d sistema_academico_dev -f 13_positive_tests.sql
-- =====================================================================
\set ON_ERROR_STOP on
\set QUIET on
\pset tuples_only on
\pset format unaligned
SET client_min_messages = notice;
BEGIN;

CREATE TEMP TABLE t_conteo (n integer NOT NULL DEFAULT 0);
INSERT INTO t_conteo VALUES (0);
CREATE FUNCTION pg_temp.ok(p_id text, p_cond boolean, p_msg text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    IF p_cond IS DISTINCT FROM true THEN RAISE EXCEPTION 'FAIL % %', p_id, p_msg; END IF;
    UPDATE t_conteo SET n = n + 1;
    RAISE NOTICE 'PASS % %', p_id, p_msg;
END $$;

-- =====================================================================
\echo '--- P1. Flujo completo de alta (§32) ---'
-- =====================================================================
INSERT INTO SIS_ACA_CARRERA (CAR_CODIGO, CAR_NOMBRE, CAR_DESCRIPCION)
VALUES ('BIN', 'Bachillerato Industrial', 'Carrera DEMOSTRATIVA creada por la prueba positiva.');
SELECT pg_temp.ok('P01', EXISTS (SELECT 1 FROM SIS_ACA_CARRERA WHERE CAR_CODIGO = 'BIN'), 'se puede crear una carrera');

INSERT INTO SIS_ACA_PENSUM (PEN_CAR_ID, PEN_CODIGO, PEN_NOMBRE, PEN_VERSION, PEN_VIGENTE_DESDE)
SELECT CAR_ID, 'BIN-2027', 'Industrial · Pensum 2027', 1, DATE '2027-01-01' FROM SIS_ACA_CARRERA WHERE CAR_CODIGO = 'BIN';
SELECT pg_temp.ok('P02', EXISTS (SELECT 1 FROM SIS_ACA_PENSUM WHERE PEN_CODIGO = 'BIN-2027'), 'se puede crear un pensum');

INSERT INTO SIS_ACA_CURSO (CUR_CODIGO, CUR_NOMBRE) VALUES ('TAL-101', 'Taller Industrial I'), ('DIB-101', 'Dibujo Técnico'), ('TAL-102', 'Taller Industrial II');
INSERT INTO SIS_ACA_PENSUM_CURSO (PCU_PEN_ID, PCU_CUR_ID, PCU_CIC_ID, PCU_ORDEN)
SELECT p.PEN_ID, c.CUR_ID, k.CIC_ID, x.orden
FROM (VALUES ('TAL-101', 1, 1), ('MAT-101', 1, 2), ('DIB-101', 1, 3), ('TAL-102', 2, 1)) x(cur, sem, orden)
JOIN SIS_ACA_CURSO c ON c.CUR_CODIGO = x.cur
JOIN SIS_ACA_CICLO_CURRICULAR k ON k.CIC_ANIO = 1 AND k.CIC_SEMESTRE = x.sem
JOIN SIS_ACA_PENSUM p ON p.PEN_CODIGO = 'BIN-2027';
SELECT pg_temp.ok('P03', (SELECT count(*) FROM SIS_ACA_PENSUM_CURSO c JOIN SIS_ACA_PENSUM p ON p.PEN_ID = c.PCU_PEN_ID WHERE p.PEN_CODIGO = 'BIN-2027') = 4,
                  'se pueden asignar cursos a ciclos (reutiliza MAT-101 del catálogo, sin duplicarlo)');

INSERT INTO SIS_ACA_ESTUDIANTE (EST_CODIGO, EST_NOMBRES, EST_APELLIDOS, EST_FECHA_NACIMIENTO, EST_FOTO_RUTA)
VALUES ('STU-2027-0001', 'Wendy Carolina', 'Pérez Tuyuc', DATE '2010-04-04', 'students/2027/STU-2027-0001.jpg');
SELECT pg_temp.ok('P04', EXISTS (SELECT 1 FROM SIS_ACA_ESTUDIANTE WHERE EST_CODIGO = 'STU-2027-0001'), 'se puede crear un estudiante');

INSERT INTO SIS_ACA_ESTUDIANTE_PROGRAMA (EPR_EST_ID, EPR_PEN_ID, EPR_FECHA_INICIO)
SELECT e.EST_ID, p.PEN_ID, DATE '2027-01-15' FROM SIS_ACA_ESTUDIANTE e, SIS_ACA_PENSUM p WHERE e.EST_CODIGO = 'STU-2027-0001' AND p.PEN_CODIGO = 'BIN-2027';
SELECT pg_temp.ok('P05', (SELECT c.CAR_CODIGO FROM SIS_ACA_ESTUDIANTE_PROGRAMA r JOIN SIS_ACA_PENSUM p ON p.PEN_ID = r.EPR_PEN_ID JOIN SIS_ACA_CARRERA c ON c.CAR_ID = p.PEN_CAR_ID
                           JOIN SIS_ACA_ESTUDIANTE e ON e.EST_ID = r.EPR_EST_ID WHERE e.EST_CODIGO = 'STU-2027-0001') = 'BIN',
                  'se puede asignar el estudiante a un pensum; la carrera se deriva del pensum');

INSERT INTO SIS_ACA_ANIO_LECTIVO (ANL_ANIO, ANL_NOMBRE, ANL_FECHA_INICIO, ANL_FECHA_FIN) VALUES (2027, 'Año lectivo 2027', DATE '2027-01-11', DATE '2027-11-26');
UPDATE SIS_ACA_ANIO_LECTIVO SET ANL_ESTADO = 'ABIERTO' WHERE ANL_ANIO = 2027;
SELECT pg_temp.ok('P06', (SELECT ANL_ESTADO FROM SIS_ACA_ANIO_LECTIVO WHERE ANL_ANIO = 2027) = 'ABIERTO', 'se puede abrir un año académico');

INSERT INTO SIS_ACA_PERIODO_ACADEMICO (PER_ANL_ID, PER_NUMERO, PER_NOMBRE, PER_FECHA_INICIO, PER_FECHA_FIN)
SELECT ANL_ID, x.n, x.nombre, x.ini, x.fin FROM SIS_ACA_ANIO_LECTIVO,
       (VALUES (1, 'Semestre I', DATE '2027-01-15', DATE '2027-06-15'), (2, 'Semestre II', DATE '2027-07-15', DATE '2027-11-15')) x(n, nombre, ini, fin)
WHERE ANL_ANIO = 2027;
UPDATE SIS_ACA_PERIODO_ACADEMICO SET PER_ESTADO = 'ABIERTO'
WHERE PER_ANL_ID = (SELECT ANL_ID FROM SIS_ACA_ANIO_LECTIVO WHERE ANL_ANIO = 2027) AND PER_NUMERO = 1;
CREATE TEMP VIEW t_per AS
  SELECT p.PER_ID, a.ANL_ANIO || '-' || p.PER_NUMERO AS clave, x.POL_CODIGO
  FROM SIS_ACA_PERIODO_ACADEMICO p JOIN SIS_ACA_ANIO_LECTIVO a ON a.ANL_ID = p.PER_ANL_ID JOIN SIS_ACA_POLITICA_ACADEMICA x ON x.POL_ID = p.PER_POL_ID;
SELECT pg_temp.ok('P07', (SELECT POL_CODIGO FROM t_per WHERE clave = '2027-1') = 'POL-2026-01',
                  'se puede crear un período; T3 le asigna POL-2026 (vigente hasta 2027-12-31)');

INSERT INTO SIS_ACA_ESTUDIANTE_PERIODO (EPE_EPR_ID, EPE_PER_ID, EPE_CIC_ID, EPE_SEC_ID)
SELECT r.EPR_ID, t.PER_ID, k.CIC_ID, s.SEC_ID
FROM SIS_ACA_ESTUDIANTE_PROGRAMA r JOIN SIS_ACA_ESTUDIANTE e ON e.EST_ID = r.EPR_EST_ID AND e.EST_CODIGO = 'STU-2027-0001'
JOIN t_per t ON t.clave = '2027-1' JOIN SIS_ACA_CICLO_CURRICULAR k ON k.CIC_ANIO = 1 AND k.CIC_SEMESTRE = 1
JOIN SIS_ACA_SECCION s ON s.SEC_CODIGO = 'A';
CREATE TEMP VIEW t_epe AS
  SELECT e.EPE_ID, t.clave AS per FROM SIS_ACA_ESTUDIANTE_PERIODO e JOIN t_per t ON t.PER_ID = e.EPE_PER_ID
  JOIN SIS_ACA_ESTUDIANTE_PROGRAMA r ON r.EPR_ID = e.EPE_EPR_ID JOIN SIS_ACA_ESTUDIANTE s ON s.EST_ID = r.EPR_EST_ID
  WHERE s.EST_CODIGO = 'STU-2027-0001';
SELECT pg_temp.ok('P08', (SELECT count(*) FROM t_epe) = 1, 'se puede asignar el estudiante a período + ciclo + sección');

INSERT INTO SIS_ACA_OFERTA_CURSO (OFE_PER_ID, OFE_PCU_ID, OFE_SEC_ID)
SELECT t.PER_ID, c.PCU_ID, s.SEC_ID
FROM t_per t, SIS_ACA_PENSUM_CURSO c JOIN SIS_ACA_PENSUM p ON p.PEN_ID = c.PCU_PEN_ID JOIN SIS_ACA_CICLO_CURRICULAR k ON k.CIC_ID = c.PCU_CIC_ID, SIS_ACA_SECCION s
WHERE t.clave = '2027-1' AND p.PEN_CODIGO = 'BIN-2027' AND k.CIC_SEMESTRE = 1 AND s.SEC_CODIGO = 'A';
CREATE TEMP VIEW t_ofe AS
  SELECT o.OFE_ID, t.clave AS per, u.CUR_CODIGO AS cur FROM SIS_ACA_OFERTA_CURSO o JOIN t_per t ON t.PER_ID = o.OFE_PER_ID
  JOIN SIS_ACA_PENSUM_CURSO c ON c.PCU_ID = o.OFE_PCU_ID JOIN SIS_ACA_PENSUM p ON p.PEN_ID = c.PCU_PEN_ID AND p.PEN_CODIGO = 'BIN-2027'
  JOIN SIS_ACA_CURSO u ON u.CUR_ID = c.PCU_CUR_ID;
SELECT pg_temp.ok('P09', (SELECT count(*) FROM t_ofe WHERE per = '2027-1') = 3, 'se puede crear la oferta académica');

INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID, RES_NOTA, RES_CALIFICADO_EN)
SELECT e.EPE_ID, o.OFE_ID, x.nota, CASE WHEN x.nota IS NULL THEN NULL ELSE now() END
FROM (VALUES ('TAL-101', 61.00::numeric), ('MAT-101', 60.00), ('DIB-101', NULL)) x(cur, nota)
JOIN t_ofe o ON o.cur = x.cur AND o.per = '2027-1'
JOIN t_epe e ON e.per = '2027-1';
CREATE TEMP VIEW t_res AS SELECT * FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE WHERE EST_CODIGO = 'STU-2027-0001';
SELECT pg_temp.ok('P10', (SELECT count(*) FROM t_res) = 3, 'se pueden registrar notas');
SELECT pg_temp.ok('P11', (SELECT RES_ESTADO FROM t_res WHERE CUR_CODIGO = 'TAL-101') = 'APROBADO',  '61 → APROBADO');
SELECT pg_temp.ok('P12', (SELECT RES_ESTADO FROM t_res WHERE CUR_CODIGO = 'MAT-101') = 'REPROBADO', '60 → REPROBADO');
SELECT pg_temp.ok('P13', (SELECT RES_ESTADO FROM t_res WHERE CUR_CODIGO = 'DIB-101') = 'PENDIENTE', 'NULL → PENDIENTE');

UPDATE SIS_ACA_RESULTADO_CURSO SET RES_NOTA = 88, RES_CALIFICADO_EN = now()
WHERE RES_ID = (SELECT RES_ID FROM t_res WHERE CUR_CODIGO = 'DIB-101');
SELECT pg_temp.ok('P14', (SELECT RES_ESTADO FROM t_res WHERE CUR_CODIGO = 'DIB-101') = 'APROBADO', 'una nota pendiente se registra después (PENDIENTE → 88 APROBADO)');

-- Cierre de 2027-I y repitencia de MAT-101 en 2027-II
UPDATE SIS_ACA_ESTUDIANTE_PERIODO SET EPE_ESTADO = 'FINALIZADO' WHERE EPE_ID = (SELECT EPE_ID FROM t_epe WHERE per = '2027-1');
UPDATE SIS_ACA_PERIODO_ACADEMICO SET PER_ESTADO = 'CERRADO' WHERE PER_ID = (SELECT PER_ID FROM t_per WHERE clave = '2027-1');
UPDATE SIS_ACA_PERIODO_ACADEMICO SET PER_ESTADO = 'ABIERTO' WHERE PER_ID = (SELECT PER_ID FROM t_per WHERE clave = '2027-2');
INSERT INTO SIS_ACA_ESTUDIANTE_PERIODO (EPE_EPR_ID, EPE_PER_ID, EPE_CIC_ID, EPE_SEC_ID)
SELECT r.EPR_ID, t.PER_ID, k.CIC_ID, s.SEC_ID
FROM SIS_ACA_ESTUDIANTE_PROGRAMA r JOIN SIS_ACA_ESTUDIANTE e ON e.EST_ID = r.EPR_EST_ID AND e.EST_CODIGO = 'STU-2027-0001'
JOIN t_per t ON t.clave = '2027-2' JOIN SIS_ACA_CICLO_CURRICULAR k ON k.CIC_ANIO = 1 AND k.CIC_SEMESTRE = 2
JOIN SIS_ACA_SECCION s ON s.SEC_CODIGO = 'A';
INSERT INTO SIS_ACA_OFERTA_CURSO (OFE_PER_ID, OFE_PCU_ID, OFE_SEC_ID)
SELECT t.PER_ID, c.PCU_ID, s.SEC_ID
FROM t_per t, SIS_ACA_PENSUM_CURSO c JOIN SIS_ACA_PENSUM p ON p.PEN_ID = c.PCU_PEN_ID JOIN SIS_ACA_CURSO u ON u.CUR_ID = c.PCU_CUR_ID, SIS_ACA_SECCION s
WHERE t.clave = '2027-2' AND p.PEN_CODIGO = 'BIN-2027' AND u.CUR_CODIGO IN ('TAL-102', 'MAT-101') AND s.SEC_CODIGO = 'A';
SELECT pg_temp.ok('P15', (SELECT ING_ORIGEN = 'CICLO_ANTERIOR' AND ING_EDITABLE FROM SIS_ACA_VW_INGRESO_NOTAS i JOIN t_epe e ON e.EPE_ID = i.EPE_ID
                           WHERE e.per = '2027-2' AND i.CUR_CODIGO = 'MAT-101'),
                  'la pantalla de ingreso ofrece repetir MAT-101 antes de crear el intento');
INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID, RES_NOTA, RES_CALIFICADO_EN)
SELECT e.EPE_ID, o.OFE_ID, 75, now() FROM t_epe e, t_ofe o WHERE e.per = '2027-2' AND o.per = '2027-2' AND o.cur = 'MAT-101';
SELECT pg_temp.ok('P16', (SELECT RES_TOTAL_INTENTOS = 2 AND RES_PRIMERA_NOTA = 60 AND RES_ULTIMA_NOTA = 75 AND RES_APROBADO
                          FROM SIS_ACA_VW_INTENTO_CURSO WHERE EST_CODIGO = 'STU-2027-0001' AND CUR_CODIGO = 'MAT-101'),
                  'se puede repetir un curso (60 → 75)');
SELECT pg_temp.ok('P17', (SELECT string_agg(RES_NOTA || ':' || RES_ESTADO || ':' || RES_NUMERO_INTENTO, ' ' ORDER BY RES_NUMERO_INTENTO) FROM t_res WHERE CUR_CODIGO = 'MAT-101')
                         = '60.00:REPROBADO:1 75.00:APROBADO:2',
                  'el segundo intento no elimina el primero');
SELECT pg_temp.ok('P18', (SELECT AVA_CURSOS_OBLIGATORIOS = 4 AND AVA_CURSOS_APROBADOS = 3 AND AVA_PORCENTAJE = 75.00
                          FROM SIS_ACA_VW_AVANCE_PENSUM WHERE EST_CODIGO = 'STU-2027-0001'),
                  'el progreso no duplica aprobaciones: MAT-101 cuenta una vez (3/4 = 75 %)');
UPDATE SIS_ACA_ESTUDIANTE SET EST_NOMBRES = 'Wendy Carolina', EST_ACTUALIZADO_EN = TIMESTAMPTZ '2000-01-01' WHERE EST_CODIGO = 'STU-2027-0001';
SELECT pg_temp.ok('P19', (SELECT EST_ACTUALIZADO_EN = now() FROM SIS_ACA_ESTUDIANTE WHERE EST_CODIGO = 'STU-2027-0001'), 'T1 actualiza EST_ACTUALIZADO_EN');

-- =====================================================================
\echo '--- P2. Validación histórica (§47) ---'
-- =====================================================================
-- STU-2026-0009 obtuvo 65 en ING-101 en 2026-I, con POL-2026 (61).
SELECT pg_temp.ok('P20', (SELECT RES_NOTA = 65 AND POL_CODIGO = 'POL-2026-01' AND POL_NOTA_APROBACION = 61 AND RES_ESTADO = 'APROBADO'
                          FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE WHERE EST_CODIGO = 'STU-2026-0009' AND CUR_CODIGO = 'ING-101'),
                  '§47: 65 en 2026 con POL-2026 (61) → APROBADO');
SELECT pg_temp.ok('P21', (SELECT POL_NOTA_APROBACION = 70 FROM SIS_ACA_POLITICA_ACADEMICA WHERE POL_CODIGO = 'POL-2028-01'),
                  '§47: existe POL-2028 con nota mínima 70');
INSERT INTO SIS_ACA_POLITICA_ACADEMICA (POL_CODIGO, POL_NOMBRE, POL_NOTA_APROBACION, POL_VIGENTE_DESDE)
VALUES ('POL-2030-01', 'Reglamento 2030 (prueba)', 75, DATE '2030-01-01');
SELECT pg_temp.ok('P22', (SELECT RES_ESTADO FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE WHERE EST_CODIGO = 'STU-2026-0009' AND CUR_CODIGO = 'ING-101') = 'APROBADO',
                  '§47: tras crear también POL-2030 (75), la nota 65 de 2026 CONTINÚA APROBADA');
SELECT pg_temp.ok('P23', (SELECT count(*) FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE
                          WHERE RES_NOTA IS NOT NULL AND (RES_ESTADO = 'APROBADO') <> (RES_NOTA >= POL_NOTA_APROBACION)) = 0
                     AND (SELECT count(*) FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE WHERE RES_NOTA >= 61 AND RES_NOTA < 70 AND RES_ESTADO = 'APROBADO' AND ANL_ANIO <= 2026) > 0,
                  '§47: todas las notas 61–69.99 de 2025/2026 siguen APROBADAS con su política histórica');

-- =====================================================================
\echo '--- P3. Criterios de aceptación del modelo (§46 A–P) ---'
-- =====================================================================
SELECT pg_temp.ok('A', (SELECT c.CAR_NOMBRE FROM SIS_ACA_ESTUDIANTE e JOIN SIS_ACA_ESTUDIANTE_PROGRAMA r ON r.EPR_EST_ID = e.EST_ID
                        JOIN SIS_ACA_PENSUM p ON p.PEN_ID = r.EPR_PEN_ID JOIN SIS_ACA_CARRERA c ON c.CAR_ID = p.PEN_CAR_ID WHERE e.EST_CODIGO = 'STU-2025-0001')
                       = 'Bachillerato en Ciencias y Letras con Orientación en Computación', '¿Qué carrera estudia Ana? → Computación');
SELECT pg_temp.ok('B', (SELECT p.PEN_CODIGO FROM SIS_ACA_ESTUDIANTE e JOIN SIS_ACA_ESTUDIANTE_PROGRAMA r ON r.EPR_EST_ID = e.EST_ID
                        JOIN SIS_ACA_PENSUM p ON p.PEN_ID = r.EPR_PEN_ID WHERE e.EST_CODIGO = 'STU-2025-0001') = 'BCL-COMP-2025',
                  '¿Con qué pensum ingresó? → BCL-COMP-2025 (no migró al 2027)');
SELECT pg_temp.ok('C', (SELECT AVA_CURSOS_OBLIGATORIOS FROM SIS_ACA_VW_AVANCE_PENSUM WHERE EST_CODIGO = 'STU-2025-0001') = 20,
                  '¿Qué cursos debería aprobar? → 20 obligatorios (ART-101 es optativo)');
SELECT pg_temp.ok('D', (SELECT count(*) FROM SIS_ACA_VW_INGRESO_NOTAS WHERE EST_CODIGO = 'STU-2025-0001' AND PER_ESTADO = 'ABIERTO' AND ING_ORIGEN = 'CICLO_ACTUAL') = 5,
                  '¿Qué cursos pertenecen al ciclo actual? → 5 de Año 2 / Semestre II');
SELECT pg_temp.ok('E', (SELECT AVA_CURSOS_APROBADOS FROM SIS_ACA_VW_AVANCE_PENSUM WHERE EST_CODIGO = 'STU-2025-0001') = 20,
                  '¿Qué cursos ya aprobó? → 20');
SELECT pg_temp.ok('F', (SELECT string_agg(CUR_CODIGO, ',') FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE WHERE EST_CODIGO = 'STU-2025-0004' AND RES_ESTADO = 'REPROBADO') = 'PRG-101'
                   AND NOT EXISTS (SELECT 1 FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE WHERE EST_CODIGO = 'STU-2025-0001' AND RES_ESTADO = 'REPROBADO'),
                  '¿Qué cursos reprobó? → Ana ninguno; Diego PRG-101');
SELECT pg_temp.ok('G', (SELECT string_agg(CUR_CODIGO, ',') FROM SIS_ACA_VW_INTENTO_CURSO WHERE EST_CODIGO = 'STU-2025-0004' AND RES_TOTAL_INTENTOS > 1) = 'PRG-101',
                  '¿Cuáles repitió? → Diego PRG-101');
SELECT pg_temp.ok('H', (SELECT RES_TOTAL_INTENTOS FROM SIS_ACA_VW_INTENTO_CURSO WHERE EST_CODIGO = 'STU-2025-0004' AND CUR_CODIGO = 'PRG-101') = 2,
                  '¿Cuántos intentos necesitó? → 2');
SELECT pg_temp.ok('I', (SELECT AVA_PORCENTAJE FROM SIS_ACA_VW_AVANCE_PENSUM WHERE EST_CODIGO = 'STU-2025-0005') = 80.00,
                  '¿Porcentaje real de avance? → Elena 80 % (16/20; MAT-101 repetido no suma dos veces)');
SELECT pg_temp.ok('J', (SELECT AVA_ESTADO_CICLO FROM SIS_ACA_VW_AVANCE_CICLO WHERE EST_CODIGO = 'STU-2025-0006' AND CIC_ANIO = 1 AND CIC_SEMESTRE = 1) = 'COMPLETO'
                   AND (SELECT AVA_ESTADO_CICLO FROM SIS_ACA_VW_AVANCE_CICLO WHERE EST_CODIGO = 'STU-2025-0007' AND CIC_ANIO = 1 AND CIC_SEMESTRE = 2) = 'INCOMPLETO',
                  '¿Completó el ciclo? → CASO F sí, CASO G no');
SELECT pg_temp.ok('K', (SELECT POL_NOTA_APROBACION || ' (' || POL_CODIGO || ')' FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE WHERE EST_CODIGO = 'STU-2025-0001' AND CUR_CODIGO = 'PRG-101')
                       = '61.00 (POL-2025-01)', '¿Qué nota mínima aplicaba cuando cursó PRG-101? → 61 (POL-2025-01)');
SELECT pg_temp.ok('L', (SELECT count(*) FROM SIS_ACA_ESTUDIANTE_PROGRAMA r JOIN SIS_ACA_PENSUM p ON p.PEN_ID = r.EPR_PEN_ID
                        JOIN SIS_ACA_CARRERA c ON c.CAR_ID = p.PEN_CAR_ID WHERE c.CAR_CODIGO = 'BCL-COMP' AND r.EPR_ESTADO = 'ACTIVO') = 19,
                  '¿Qué estudiantes están en Computación? → 19');
SELECT pg_temp.ok('M', (SELECT count(*) FROM SIS_ACA_VW_REPORTE_NOTAS WHERE CAR_CODIGO = 'BCL-COMP' AND CUR_CODIGO = 'MAT-101' AND SEC_CODIGO = 'B') = 10,
                  '¿Notas de Computación + MAT-101 + sección B? → 10');
SELECT pg_temp.ok('N', (SELECT count(*) = 6 AND count(*) FILTER (WHERE CUR_CODIGO = 'MAT-102' AND ING_ORIGEN = 'CICLO_ANTERIOR' AND ING_EDITABLE) = 1
                        FROM SIS_ACA_VW_INGRESO_NOTAS WHERE EST_CODIGO = 'STU-2025-0003' AND PER_ESTADO = 'ABIERTO'),
                  '¿Qué materias muestra Symfony al ingresar notas de Carla? → 6, incluida MAT-102 por repetir');
SELECT pg_temp.ok('O', (SELECT count(DISTINCT r.EPR_ID)
                        FROM SIS_ACA_ESTUDIANTE_PROGRAMA r
                        JOIN LATERAL (SELECT k.CIC_ANIO, k.CIC_SEMESTRE FROM SIS_ACA_ESTUDIANTE_PERIODO x
                                      JOIN SIS_ACA_PERIODO_ACADEMICO p ON p.PER_ID = x.EPE_PER_ID JOIN SIS_ACA_CICLO_CURRICULAR k ON k.CIC_ID = x.EPE_CIC_ID
                                      WHERE x.EPE_EPR_ID = r.EPR_ID ORDER BY p.PER_FECHA_INICIO DESC LIMIT 1) ca ON true
                        JOIN SIS_ACA_PENSUM_CURSO c ON c.PCU_PEN_ID = r.EPR_PEN_ID AND c.PCU_OBLIGATORIO
                        JOIN SIS_ACA_CICLO_CURRICULAR k ON k.CIC_ID = c.PCU_CIC_ID AND (k.CIC_ANIO, k.CIC_SEMESTRE) < (ca.CIC_ANIO, ca.CIC_SEMESTRE)
                        LEFT JOIN SIS_ACA_VW_INTENTO_CURSO i ON i.EPR_ID = r.EPR_ID AND i.PCU_ID = c.PCU_ID
                        WHERE r.EPR_ESTADO = 'ACTIVO' AND NOT COALESCE(i.RES_APROBADO, false)
                          AND r.EPR_EST_ID <> (SELECT EST_ID FROM SIS_ACA_ESTUDIANTE WHERE EST_CODIGO = 'STU-2027-0001')) = 12,
                  '¿Quiénes tienen cursos pendientes de ciclos anteriores? → 12 (Q21)');
SELECT pg_temp.ok('P', (SELECT count(*) FROM SIS_ACA_VW_AVANCE_PENSUM WHERE AVA_PENSUM_COMPLETO) = 17,
                  '¿Quiénes terminaron todo su pensum? → 17');

SELECT 'TOTAL: ' || n || ' pruebas positivas PASS' FROM t_conteo;
\echo '=== 13_positive_tests: todas las pruebas PASS ==='
ROLLBACK;
