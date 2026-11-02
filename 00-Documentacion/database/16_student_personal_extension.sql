-- =====================================================================
-- 16_student_personal_extension.sql
-- Extensión aprobada durante integración Symfony (2026-10-09)
--
-- Motivo:
--   · persistir dirección de residencia; ya no se permite mostrarla como
--     dato UI-only.
--   · compatible con los 45 registros existentes: la columna es nullable.
--
-- Ejecutar UNA VEZ sobre la base ya instalada como sa_owner:
--   psql -h 127.0.0.1 -U sa_owner -d sistema_academico_dev \
--        -f 16_student_personal_extension.sql
-- =====================================================================
\set ON_ERROR_STOP on

BEGIN;

ALTER TABLE SIS_ACA_ESTUDIANTE
    ADD COLUMN IF NOT EXISTS EST_DIRECCION VARCHAR(255);

COMMENT ON COLUMN SIS_ACA_ESTUDIANTE.EST_DIRECCION
    IS 'Dirección de residencia. Campo opcional para compatibilidad con registros históricos.';

COMMIT;

\echo '16_student_personal_extension.sql: EST_DIRECCION disponible'
