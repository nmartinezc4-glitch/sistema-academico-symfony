-- =====================================================================
--  14_explain.sql — E3 · Planes de ejecución (§35)
--
--  Cinco consultas críticas del sistema (E1–E5), cada una en dos pasadas,
--  más E5b (ingreso de notas por su clave) y E6 (búsqueda por apellido):
--
--    (a) Plan REAL con el dataset demostrativo (EXPLAIN ANALYZE).
--        Con ~700 resultados y tablas de 1–3 páginas, PostgreSQL elige
--        con razón recorridos secuenciales en varias tablas: leer una
--        página entera es más barato que recorrer un índice. No es un
--        defecto: el optimizador decide por costo.
--
--    (b) Plan con enable_seqscan = off (solo diagnóstico, dentro de la
--        transacción): obliga al optimizador a mostrar QUÉ índices usaría
--        cuando las tablas crezcan. Así se verifica que las consultas son
--        indexables sin necesitar miles de filas de prueba.
--
--  La interpretación de cada plan está en docs/E3_ENTREGA.md §4.
--  Uso: psql -d sistema_academico_dev -f 14_explain.sql
-- =====================================================================
\set ON_ERROR_STOP on
BEGIN;
ANALYZE;   -- estadísticas frescas tras la carga del dataset

\echo '#####################################################################'
\echo '## E1 · Historial de un alumno (Q04)'
\echo '#####################################################################'
EXPLAIN (ANALYZE, TIMING OFF, SUMMARY OFF)
SELECT ANL_ANIO, PER_NOMBRE, CUR_CODIGO, RES_NOTA, RES_ESTADO, RES_NUMERO_INTENTO
FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE WHERE EST_CODIGO = 'STU-2025-0004';

SET LOCAL enable_seqscan = off;
EXPLAIN (COSTS OFF)
SELECT ANL_ANIO, PER_NOMBRE, CUR_CODIGO, RES_NOTA, RES_ESTADO, RES_NUMERO_INTENTO
FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE WHERE EST_CODIGO = 'STU-2025-0004';
RESET enable_seqscan;

\echo '#####################################################################'
\echo '## E2 · Alumnos por carrera (Q01)'
\echo '#####################################################################'
EXPLAIN (ANALYZE, TIMING OFF, SUMMARY OFF)
SELECT e.EST_CODIGO, e.EST_APELLIDOS, r.EPR_ESTADO
FROM SIS_ACA_CARRERA c
JOIN SIS_ACA_PENSUM p              ON p.PEN_CAR_ID = c.CAR_ID
JOIN SIS_ACA_ESTUDIANTE_PROGRAMA r ON r.EPR_PEN_ID = p.PEN_ID
JOIN SIS_ACA_ESTUDIANTE e          ON e.EST_ID = r.EPR_EST_ID
WHERE c.CAR_CODIGO = 'BCL-COMP';

SET LOCAL enable_seqscan = off;
EXPLAIN (COSTS OFF)
SELECT e.EST_CODIGO, e.EST_APELLIDOS, r.EPR_ESTADO
FROM SIS_ACA_CARRERA c
JOIN SIS_ACA_PENSUM p              ON p.PEN_CAR_ID = c.CAR_ID
JOIN SIS_ACA_ESTUDIANTE_PROGRAMA r ON r.EPR_PEN_ID = p.PEN_ID
JOIN SIS_ACA_ESTUDIANTE e          ON e.EST_ID = r.EPR_EST_ID
WHERE c.CAR_CODIGO = 'BCL-COMP';
RESET enable_seqscan;

\echo '#####################################################################'
\echo '## E3 · Reporte de notas por carrera + curso + sección (Q08)'
\echo '#####################################################################'
EXPLAIN (ANALYZE, TIMING OFF, SUMMARY OFF)
SELECT ANL_ANIO, PER_NOMBRE, EST_CODIGO, RES_NOTA, RES_ESTADO
FROM SIS_ACA_VW_REPORTE_NOTAS
WHERE CAR_CODIGO = 'BCL-COMP' AND CUR_CODIGO = 'MAT-101' AND SEC_CODIGO = 'B';

SET LOCAL enable_seqscan = off;
EXPLAIN (COSTS OFF)
SELECT ANL_ANIO, PER_NOMBRE, EST_CODIGO, RES_NOTA, RES_ESTADO
FROM SIS_ACA_VW_REPORTE_NOTAS
WHERE CAR_CODIGO = 'BCL-COMP' AND CUR_CODIGO = 'MAT-101' AND SEC_CODIGO = 'B';
RESET enable_seqscan;

\echo '#####################################################################'
\echo '## E4 · Avance del pensum de un alumno (Q18 / ficha Q03)'
\echo '#####################################################################'
EXPLAIN (ANALYZE, TIMING OFF, SUMMARY OFF)
SELECT AVA_CURSOS_OBLIGATORIOS, AVA_CURSOS_APROBADOS, AVA_PORCENTAJE
FROM SIS_ACA_VW_AVANCE_PENSUM WHERE EST_CODIGO = 'STU-2025-0005';

SET LOCAL enable_seqscan = off;
EXPLAIN (COSTS OFF)
SELECT AVA_CURSOS_OBLIGATORIOS, AVA_CURSOS_APROBADOS, AVA_PORCENTAJE
FROM SIS_ACA_VW_AVANCE_PENSUM WHERE EST_CODIGO = 'STU-2025-0005';
RESET enable_seqscan;

\echo '#####################################################################'
\echo '## E5 · Pantalla de ingreso de notas (Q25)'
\echo '#####################################################################'
EXPLAIN (ANALYZE, TIMING OFF, SUMMARY OFF)
SELECT CUR_CODIGO, ING_ORIGEN, ING_ESTADO, ING_EDITABLE, ING_MOTIVO_BLOQUEO, OFE_ID
FROM SIS_ACA_VW_INGRESO_NOTAS
WHERE EST_CODIGO = 'STU-2025-0003' AND PER_ESTADO = 'ABIERTO';

SET LOCAL enable_seqscan = off;
EXPLAIN (COSTS OFF)
SELECT CUR_CODIGO, ING_ORIGEN, ING_ESTADO, ING_EDITABLE, ING_MOTIVO_BLOQUEO, OFE_ID
FROM SIS_ACA_VW_INGRESO_NOTAS
WHERE EST_CODIGO = 'STU-2025-0003' AND PER_ESTADO = 'ABIERTO';
RESET enable_seqscan;

\echo '#####################################################################'
\echo '## E5b · Ingreso de notas filtrando por la CLAVE de la vista (EPE_ID)'
\echo '##       Forma recomendada para Symfony: el filtro entra en cada rama del UNION ALL.'
\echo '#####################################################################'
EXPLAIN (ANALYZE, TIMING OFF, SUMMARY OFF)
SELECT CUR_CODIGO, ING_ORIGEN, ING_ESTADO, ING_EDITABLE, ING_MOTIVO_BLOQUEO, OFE_ID
FROM SIS_ACA_VW_INGRESO_NOTAS
WHERE EPE_ID = (SELECT e.EPE_ID FROM SIS_ACA_ESTUDIANTE_PERIODO e
                JOIN SIS_ACA_ESTUDIANTE_PROGRAMA r ON r.EPR_ID = e.EPE_EPR_ID
                JOIN SIS_ACA_ESTUDIANTE s ON s.EST_ID = r.EPR_EST_ID
                JOIN SIS_ACA_PERIODO_ACADEMICO p ON p.PER_ID = e.EPE_PER_ID
                WHERE s.EST_CODIGO = 'STU-2025-0003' AND p.PER_ESTADO = 'ABIERTO');

\echo '#####################################################################'
\echo '## E6 · Búsqueda de alumno por apellido (pantalla "buscar alumno" del PDF)'
\echo '#####################################################################'
SET LOCAL enable_seqscan = off;
EXPLAIN (COSTS OFF)
SELECT EST_CODIGO, EST_APELLIDOS, EST_NOMBRES
FROM SIS_ACA_ESTUDIANTE
WHERE lower(EST_APELLIDOS) LIKE lower('Chá') || '%';
RESET enable_seqscan;

\echo '#####################################################################'
\echo '## Índices con lecturas acumuladas (pg_stat_user_indexes, desde el último reinicio de estadísticas)'
\echo '#####################################################################'
SELECT indexrelname AS indice, idx_scan AS lecturas
FROM pg_stat_user_indexes
WHERE relname LIKE 'sis\_aca\_%' AND idx_scan > 0
ORDER BY idx_scan DESC, indexrelname;

ROLLBACK;
