-- =====================================================================
--  run_all.sql — Orquestador (psql)
--
--  Uso (desde la carpeta database/):
--    psql -d sistema_academico_dev -f run_all.sql
--  Solo estructura (sin datos demo; requerido por E1_smoke_test.sql):
--    psql -d sistema_academico_dev -v solo_estructura=1 -f run_all.sql
--
--  Estado: E3 (estructura + dataset + suite de verificación).
--  12_business_queries.sql es de consulta: ejecútelo aparte
--    psql -d sistema_academico_dev -f 12_business_queries.sql
-- =====================================================================
\set ON_ERROR_STOP on
\echo '== 00 reset (solo desarrollo) =='
\i 00_reset.sql
BEGIN;
\echo '== 01 schema =='
\i 01_schema.sql
\echo '== 02 constraints =='
\i 02_constraints.sql
\echo '== 03 indexes =='
\i 03_indexes.sql
\echo '== 04 functions / triggers =='
\i 04_functions_triggers.sql
\echo '== 05 views =='
\i 05_views.sql
\echo '== 16 security schema =='
\i 16_security_schema.sql
\echo '== 18 security user photo =='
\i 18_security_user_photo.sql
COMMIT;
\echo '== Estructura E1 creada =='
\if :{?solo_estructura}
\echo '== solo_estructura: se omite el dataset demostrativo =='
\quit
\endif
BEGIN;
\echo '== 06 seed catalogs =='
\i 06_seed_catalogs.sql
\echo '== 07 seed curricula =='
\i 07_seed_curricula.sql
\echo '== 08 seed students =='
\i 08_seed_students.sql
\echo '== 09 seed academic history =='
\i 09_seed_academic_history.sql
\echo '== 17 seed security roles =='
\i 17_security_seed_roles.sql
COMMIT;
\echo '== Dataset demostrativo E2 cargado =='
-- Verificación (E3): psql -d sistema_academico_dev -f run_tests.sql
-- Planes de ejecución: psql -d sistema_academico_dev -f 14_explain.sql
