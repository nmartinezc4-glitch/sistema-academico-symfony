-- =====================================================================
-- 18_security_user_photo.sql
-- Agrega fotografía institucional a usuarios de Symfony Security.
-- Seguro para una base ya inicializada: no recrea ni elimina datos.
-- =====================================================================

\set ON_ERROR_STOP on

ALTER TABLE SIS_SEG_USUARIO
    ADD COLUMN IF NOT EXISTS USU_FOTO_RUTA VARCHAR(255);

\echo '18_security_user_photo.sql: fotografía de usuario disponible'
