-- =====================================================================
-- 18_security_validation.sql
-- Verificación de la capa de identidad y roles.
-- Solo lectura.
-- =====================================================================

\set ON_ERROR_STOP on

DO $$
DECLARE
    v_seg_tables integer;
    v_roles integer;
    v_admin_roles integer;
    v_assignment integer;
BEGIN
    SELECT count(*) INTO v_seg_tables
    FROM pg_tables
    WHERE schemaname = current_schema()
      AND tablename LIKE 'sis\_seg\_%';

    IF v_seg_tables <> 4 THEN
        RAISE EXCEPTION 'FAIL seguridad: se esperaban 4 tablas SIS_SEG_, se encontraron %', v_seg_tables;
    END IF;

    SELECT count(*) INTO v_assignment
    FROM pg_tables
    WHERE schemaname = current_schema()
      AND tablename = 'sis_aca_docente_oferta';

    IF v_assignment <> 1 THEN
        RAISE EXCEPTION 'FAIL seguridad: falta SIS_ACA_DOCENTE_OFERTA';
    END IF;

    SELECT count(*) INTO v_roles
    FROM SIS_SEG_ROL
    WHERE ROL_ACTIVO
      AND ROL_CODIGO IN (
          'ROLE_DOCENTE',
          'ROLE_COORDINACION',
          'ROLE_DIRECCION',
          'ROLE_GESTION_USUARIOS'
      );

    IF v_roles <> 4 THEN
        RAISE EXCEPTION 'FAIL seguridad: roles funcionales esperados = 4, encontrados = %', v_roles;
    END IF;

    SELECT count(*) INTO v_admin_roles
    FROM SIS_SEG_ROL
    WHERE upper(ROL_CODIGO) IN ('ROLE_ADMIN', 'ROLE_SUPER_ADMIN', 'ROLE_SUPERUSER');

    IF v_admin_roles <> 0 THEN
        RAISE EXCEPTION 'FAIL seguridad: no se permiten roles de superusuario genérico';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = current_schema()
          AND table_name = 'sis_seg_usuario'
          AND column_name IN ('usu_password', 'password', 'contrasena')
    ) THEN
        RAISE EXCEPTION 'FAIL seguridad: existe una columna que podría almacenar contraseña en texto plano';
    END IF;

    RAISE NOTICE 'PASS seguridad: 4 tablas SIS_SEG_';
    RAISE NOTICE 'PASS seguridad: SIS_ACA_DOCENTE_OFERTA disponible';
    RAISE NOTICE 'PASS seguridad: 4 roles funcionales sin ROLE_ADMIN';
    RAISE NOTICE 'PASS seguridad: solo USU_PASSWORD_HASH almacena credencial persistente';
END
$$;

SELECT
    ROL_CODIGO,
    ROL_NOMBRE,
    ROL_ACTIVO
FROM SIS_SEG_ROL
ORDER BY ROL_CODIGO;

\echo '=== 18 security validation: PASS ==='
