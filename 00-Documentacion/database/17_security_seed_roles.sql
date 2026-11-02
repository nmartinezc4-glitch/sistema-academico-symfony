-- =====================================================================
-- 17_security_seed_roles.sql
-- Roles funcionales iniciales.
--
-- No crea usuarios ni contraseñas. El primer usuario se crea mediante
-- Symfony: php bin/console app:security:create-user
-- =====================================================================

\set ON_ERROR_STOP on

BEGIN;

INSERT INTO SIS_SEG_ROL (ROL_CODIGO, ROL_NOMBRE, ROL_DESCRIPCION)
VALUES
    ('ROLE_DOCENTE', 'Docente', 'Ingreso de notas únicamente sobre ofertas asignadas.'),
    ('ROLE_COORDINACION', 'Coordinación académica', 'Gestión operativa académica: estudiantes, pensums, períodos y ofertas.'),
    ('ROLE_DIRECCION', 'Dirección académica', 'Consulta institucional y análisis; sin privilegios de escritura académica por defecto.'),
    ('ROLE_GESTION_USUARIOS', 'Gestión de usuarios', 'Alta, actualización, activación y roles de usuarios. No implica privilegios académicos.')
ON CONFLICT (ROL_CODIGO) DO UPDATE SET
    ROL_NOMBRE = EXCLUDED.ROL_NOMBRE,
    ROL_DESCRIPCION = EXCLUDED.ROL_DESCRIPCION,
    ROL_ACTIVO = TRUE,
    ROL_ACTUALIZADO_EN = now();

COMMIT;

\echo '17_security_seed_roles.sql: roles funcionales cargados'
