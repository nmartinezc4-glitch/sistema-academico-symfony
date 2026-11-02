-- =====================================================================
--  run_tests.sql — Suite de verificación sobre el dataset demostrativo
--
--  Requiere: psql -d sistema_academico_dev -f run_all.sql
--  Uso:      psql -d sistema_academico_dev -f run_tests.sql
--
--  Todos los scripts son de solo lectura o terminan en ROLLBACK.
--  E1_smoke_test.sql NO se incluye: necesita la estructura SIN datos
--    psql -d sistema_academico_dev -v solo_estructura=1 -f run_all.sql
--    psql -d sistema_academico_dev -f E1_smoke_test.sql
-- =====================================================================
\set ON_ERROR_STOP on
\echo '######## E2_dataset_check.sql ########'
\i E2_dataset_check.sql
\echo '######## 10_validation_queries.sql ########'
\i 10_validation_queries.sql
\echo '######## 11_negative_tests.sql ########'
\i 11_negative_tests.sql
\echo '######## 13_positive_tests.sql ########'
\i 13_positive_tests.sql
\echo '######## 18_security_validation.sql ########'
\i 18_security_validation.sql
\echo '######## Suite completa: PASS ########'
