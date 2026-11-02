-- =====================================================================
--  00_reset.sql
--  ███  SOLO DESARROLLO / DESTRUCTIVO  ███
--
--  Elimina TODAS las vistas, tablas y funciones del Sistema Académico
--  (prefijo SIS_ACA_) del esquema actual.
--
--  Protección: el bloque completo aborta si la base de datos no se llama
--  exactamente 'sistema_academico_dev'. Los DROP viven DENTRO del mismo
--  bloque DO, de modo que aunque psql se ejecute sin ON_ERROR_STOP,
--  nada se elimina cuando la guarda falla.
--
--  NUNCA ejecutar en producción. No usa DROP SCHEMA para no tocar objetos
--  ajenos (p. ej. la tabla de versiones de Doctrine Migrations).
-- =====================================================================

DO $$
DECLARE
    v_obj record;
BEGIN
    IF current_database() <> 'sistema_academico_dev' THEN
        RAISE EXCEPTION
            '00_reset.sql abortado: la base actual es "%". Solo se permite en "sistema_academico_dev".',
            current_database()
            USING ERRCODE = 'SA001';
    END IF;

    -- 1) Vistas
    FOR v_obj IN
        SELECT c.relname
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = current_schema()
          AND c.relkind = 'v'
          AND (c.relname LIKE 'sis\_aca\_%' OR c.relname LIKE 'sis\_seg\_%')
    LOOP
        EXECUTE format('DROP VIEW IF EXISTS %I CASCADE', v_obj.relname);
    END LOOP;

    -- 2) Tablas (CASCADE solo aquí: entorno de desarrollo, elimina FKs entre ellas)
    FOR v_obj IN
        SELECT c.relname
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = current_schema()
          AND c.relkind = 'r'
          AND c.relname LIKE 'sis\_aca\_%'
    LOOP
        EXECUTE format('DROP TABLE IF EXISTS %I CASCADE', v_obj.relname);
    END LOOP;

    -- 3) Funciones (incluye funciones de trigger)
    FOR v_obj IN
        SELECT p.oid::regprocedure AS firma
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = current_schema()
          AND p.proname LIKE 'sis\_aca\_fn\_%'
    LOOP
        EXECUTE format('DROP FUNCTION IF EXISTS %s CASCADE', v_obj.firma);
    END LOOP;

    RAISE NOTICE '00_reset.sql: objetos SIS_ACA_/SIS_SEG_ eliminados de "%".', current_database();
END
$$;
