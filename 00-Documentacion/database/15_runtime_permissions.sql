-- =====================================================================
-- 15_runtime_permissions.sql
-- Sistema Académico
--
-- Permisos de ejecución para la aplicación Symfony.
--
-- sa_owner:
--   propietario / DDL / mantenimiento
--
-- sa_app:
--   runtime de Symfony
--
-- Este archivo NO crea roles ni contiene contraseñas.
-- =====================================================================

\set ON_ERROR_STOP on

BEGIN;

-- ---------------------------------------------------------------------
-- 1. Acceso a la base y al esquema
-- ---------------------------------------------------------------------

GRANT CONNECT
ON DATABASE sistema_academico_dev
TO sa_app;

GRANT USAGE
ON SCHEMA public
TO sa_app;


-- ---------------------------------------------------------------------
-- 2. Lectura
--
-- ALL TABLES incluye tablas, vistas académicas y tablas SIS_SEG existentes del esquema.
-- ---------------------------------------------------------------------

GRANT SELECT
ON ALL TABLES IN SCHEMA public
TO sa_app;


-- ---------------------------------------------------------------------
-- 3. DML
--
-- Symfony puede modificar datos, pero NO estructura.
-- No se concede:
--   CREATE
--   ALTER
--   DROP
--   TRUNCATE
--   REFERENCES
--   TRIGGER
-- ---------------------------------------------------------------------

GRANT INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA public
TO sa_app;


-- ---------------------------------------------------------------------
-- 4. Secuencias / identity
-- ---------------------------------------------------------------------

GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA public
TO sa_app;


-- ---------------------------------------------------------------------
-- 5. Privilegios por defecto
--
-- Aplicarán solamente a futuros objetos creados por sa_owner.
-- ---------------------------------------------------------------------

ALTER DEFAULT PRIVILEGES
FOR ROLE sa_owner
IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLES
TO sa_app;

ALTER DEFAULT PRIVILEGES
FOR ROLE sa_owner
IN SCHEMA public
GRANT USAGE, SELECT
ON SEQUENCES
TO sa_app;


-- ---------------------------------------------------------------------
-- 6. Hardening explícito
-- ---------------------------------------------------------------------

REVOKE CREATE
ON SCHEMA public
FROM sa_app;

COMMIT;

\echo '15_runtime_permissions.sql: permisos de sa_app aplicados'
