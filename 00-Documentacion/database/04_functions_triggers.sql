-- =====================================================================
--  04_functions_triggers.sql
--
--  1 función auxiliar + 4 funciones de trigger (responsabilidades
--  aprobadas en E1). Ninguna regla aquí puede expresarse con
--  PK / FK / UNIQUE / CHECK porque requiere leer OTRAS filas o tablas.
--
--  Códigos de error propios (SQLSTATE clase "SA", capturables en
--  pruebas con  EXCEPTION WHEN SQLSTATE 'SA201' ... ):
--
--    SA101  T1  columna de auditoría inexistente (error de configuración)
--    SA201  T2  la oferta y el estudiante pertenecen a períodos distintos
--    SA202  T2  la oferta pertenece a otro pensum
--    SA203  T2  la oferta es de otra sección (regla S1)
--    SA204  T2  el período no está ABIERTO (PLANIFICADO o CERRADO) — PERIODO_NO_ABIERTO
--    SA205  T2  el estudiante no está INSCRITO en el período
--    SA206  T2  la oferta está inactiva (OFE_ACTIVO = FALSE)
--    SA207  T2  nuevo intento de un curso ya aprobado en un período anterior
--    SA208  T2  corrección que aprueba un intento histórico con intentos posteriores
--    SA301  T3  no existe política vigente en la fecha de inicio del período
--    SA302  T3  la política indicada no es la vigente en esa fecha
--    SA303  T3  la política ya fue usada: nota/vigencia protegidas
--    SA304  T3  la nueva vigencia alteraría la política de períodos existentes
--    SA305  T3  no se puede cambiar la política de un período con resultados
--    SA401  T4  contexto académico congelado por datos dependientes o identidad
--               de RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID) modificada
-- =====================================================================

-- =====================================================================
-- Función auxiliar: política vigente en una fecha
-- ---------------------------------------------------------------------
-- La vigencia es una sucesión continua: rige la política con el
-- POL_VIGENTE_DESDE más reciente que no supere la fecha. Usada por T3 y
-- por las vistas. STABLE: lee tablas, no modifica nada.
-- =====================================================================
CREATE OR REPLACE FUNCTION SIS_ACA_FN_POLITICA_VIGENTE(P_FECHA DATE)
RETURNS INTEGER
LANGUAGE sql
STABLE
AS $$
    SELECT POL_ID
    FROM SIS_ACA_POLITICA_ACADEMICA
    WHERE POL_VIGENTE_DESDE <= P_FECHA
    ORDER BY POL_VIGENTE_DESDE DESC
    LIMIT 1
$$;
COMMENT ON FUNCTION SIS_ACA_FN_POLITICA_VIGENTE(DATE) IS 'Devuelve POL_ID de la política vigente en la fecha indicada, o NULL si ninguna aplica.';


-- =====================================================================
-- T1 · Sellado de <PREFIJO>_ACTUALIZADO_EN
-- ---------------------------------------------------------------------
-- Responsabilidad única: fijar la fecha de última modificación en cada
-- UPDATE, aunque la escritura no venga de Doctrine (seeds, psql, admin).
--
-- Una sola función para todas las tablas. Como cada tabla tiene un
-- nombre de columna distinto (por la convención de prefijos), el nombre
-- se pasa como argumento del trigger y se asigna con jsonb_populate_record
-- (función nativa, sin extensiones). Si el argumento no corresponde a una
-- columna real, se falla en lugar de ignorarlo en silencio.
--
-- Se aplica a las 12 tablas con columnas de auditoría. No se aplica a
-- SIS_ACA_CICLO_CURRICULAR ni SIS_ACA_SECCION (catálogos estáticos sin
-- columnas de auditoría, según el contrato).
-- =====================================================================
CREATE OR REPLACE FUNCTION SIS_ACA_FN_T1_SELLAR_ACTUALIZACION()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_columna text := lower(TG_ARGV[0]);
BEGIN
    IF v_columna IS NULL OR NOT (to_jsonb(NEW) ? v_columna) THEN
        RAISE EXCEPTION 'T1: la columna de auditoría "%" no existe en la tabla %.', v_columna, TG_TABLE_NAME
            USING ERRCODE = 'SA101',
                  HINT    = 'Revise el argumento de CREATE TRIGGER ... EXECUTE FUNCTION SIS_ACA_FN_T1_SELLAR_ACTUALIZACION(''<prefijo>_actualizado_en'').';
    END IF;

    NEW := jsonb_populate_record(NEW, jsonb_build_object(v_columna, now()));
    RETURN NEW;
END
$$;
COMMENT ON FUNCTION SIS_ACA_FN_T1_SELLAR_ACTUALIZACION() IS 'T1: asigna now() a la columna <prefijo>_actualizado_en recibida como argumento.';

CREATE TRIGGER TRG_POL_T1_ACTUALIZACION BEFORE UPDATE ON SIS_ACA_POLITICA_ACADEMICA  FOR EACH ROW EXECUTE FUNCTION SIS_ACA_FN_T1_SELLAR_ACTUALIZACION('pol_actualizado_en');
CREATE TRIGGER TRG_ANL_T1_ACTUALIZACION BEFORE UPDATE ON SIS_ACA_ANIO_LECTIVO        FOR EACH ROW EXECUTE FUNCTION SIS_ACA_FN_T1_SELLAR_ACTUALIZACION('anl_actualizado_en');
CREATE TRIGGER TRG_PER_T1_ACTUALIZACION BEFORE UPDATE ON SIS_ACA_PERIODO_ACADEMICO   FOR EACH ROW EXECUTE FUNCTION SIS_ACA_FN_T1_SELLAR_ACTUALIZACION('per_actualizado_en');
CREATE TRIGGER TRG_CAR_T1_ACTUALIZACION BEFORE UPDATE ON SIS_ACA_CARRERA             FOR EACH ROW EXECUTE FUNCTION SIS_ACA_FN_T1_SELLAR_ACTUALIZACION('car_actualizado_en');
CREATE TRIGGER TRG_PEN_T1_ACTUALIZACION BEFORE UPDATE ON SIS_ACA_PENSUM              FOR EACH ROW EXECUTE FUNCTION SIS_ACA_FN_T1_SELLAR_ACTUALIZACION('pen_actualizado_en');
CREATE TRIGGER TRG_CUR_T1_ACTUALIZACION BEFORE UPDATE ON SIS_ACA_CURSO               FOR EACH ROW EXECUTE FUNCTION SIS_ACA_FN_T1_SELLAR_ACTUALIZACION('cur_actualizado_en');
CREATE TRIGGER TRG_PCU_T1_ACTUALIZACION BEFORE UPDATE ON SIS_ACA_PENSUM_CURSO        FOR EACH ROW EXECUTE FUNCTION SIS_ACA_FN_T1_SELLAR_ACTUALIZACION('pcu_actualizado_en');
CREATE TRIGGER TRG_EST_T1_ACTUALIZACION BEFORE UPDATE ON SIS_ACA_ESTUDIANTE          FOR EACH ROW EXECUTE FUNCTION SIS_ACA_FN_T1_SELLAR_ACTUALIZACION('est_actualizado_en');
CREATE TRIGGER TRG_EPR_T1_ACTUALIZACION BEFORE UPDATE ON SIS_ACA_ESTUDIANTE_PROGRAMA FOR EACH ROW EXECUTE FUNCTION SIS_ACA_FN_T1_SELLAR_ACTUALIZACION('epr_actualizado_en');
CREATE TRIGGER TRG_EPE_T1_ACTUALIZACION BEFORE UPDATE ON SIS_ACA_ESTUDIANTE_PERIODO  FOR EACH ROW EXECUTE FUNCTION SIS_ACA_FN_T1_SELLAR_ACTUALIZACION('epe_actualizado_en');
CREATE TRIGGER TRG_OFE_T1_ACTUALIZACION BEFORE UPDATE ON SIS_ACA_OFERTA_CURSO        FOR EACH ROW EXECUTE FUNCTION SIS_ACA_FN_T1_SELLAR_ACTUALIZACION('ofe_actualizado_en');
CREATE TRIGGER TRG_RES_T1_ACTUALIZACION BEFORE UPDATE ON SIS_ACA_RESULTADO_CURSO     FOR EACH ROW EXECUTE FUNCTION SIS_ACA_FN_T1_SELLAR_ACTUALIZACION('res_actualizado_en');


-- =====================================================================
-- T2 · Contexto válido del resultado + protección de escritura
-- ---------------------------------------------------------------------
-- Responsabilidad única: decidir si un resultado puede escribirse
-- (INSERT, UPDATE o DELETE) en su contexto académico.
--
-- Reglas de MUTABILIDAD (aplican a la fila ORIGINAL en UPDATE/DELETE y a
-- la fila NUEVA en INSERT/UPDATE):
--   (d) El período está ABIERTO (PLANIFICADO y CERRADO bloquean) (SA204)
--   (e) El estudiante-período está en EPE_ESTADO = INSCRITO (SA205)
--   (f) La oferta está activa: OFE_ACTIVO = TRUE            (SA206)
--
-- Reglas de COHERENCIA (fila nueva en INSERT/UPDATE):
--   (a) EPE_PER_ID = OFE_PER_ID                             (SA201)
--   (b) EPR_PEN_ID = PCU_PEN_ID                             (SA202)
--   (c) EPE_SEC_ID = OFE_SEC_ID  (regla S1, sección estricta) (SA203)
--
-- Regla de NUEVO INTENTO (solo INSERT, decisión D6):
--   (g) No existe, para el mismo EPR_ID + PCU_ID, un resultado de un
--       período cronológicamente ANTERIOR con nota aprobatoria según la
--       política histórica de ESE período                     (SA207)
--       55 → 61 es válido; 61 → nuevo intento posterior, no.
--       Los intentos reprobados previos no se tocan.
--
-- Regla de CORRECCIÓN HISTÓRICA (solo UPDATE, decisión DF1):
--   (h) Si el UPDATE convierte un intento NO aprobado (NULL o bajo la nota
--       mínima de la política de SU período) en APROBADO, no debe existir
--       ningún intento del mismo EPR_ID + PCU_ID en un período
--       cronológicamente POSTERIOR                             (SA208)
--       Cierra la vía de N52: reabrir 2025-I y pasar 48 → 65 cuando ya
--       existe el intento de 2026-I. Los intentos posteriores deben
--       resolverse administrativamente primero.
--       48 → 60 (sigue reprobado) o 70 → 85 (ya aprobado) no activan la regla.
--
-- Si una FK apunta a una fila inexistente, el trigger no reporta nada y
-- deja que la FK genere el error estándar 23503.
--
-- Garantía derivada: con (c) + UQ_OFE_PER_PCU_SEC, un estudiante solo
-- puede casar con UNA oferta por curso y período → no hay intentos
-- duplicados del mismo curso en el mismo período.
-- =====================================================================
CREATE OR REPLACE FUNCTION SIS_ACA_FN_T2_VALIDAR_RESULTADO()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_fila         record;      -- OLD o NEW según la etapa
    v_etapa        text;
    v_per_estado   text;
    v_per_nombre   text;
    v_epe_estado   text;
    v_epe_per_id   integer;
    v_epe_sec_id   integer;
    v_epr_pen_id   integer;
    v_epr_id       integer;
    v_per_inicio   date;
    v_pcu_id       integer;
    v_aprobado_en  text;
    v_nota_minima  numeric;
    v_posterior    text;
    v_ofe_activo   boolean;
    v_ofe_per_id   integer;
    v_ofe_sec_id   integer;
    v_pcu_pen_id   integer;
BEGIN
    -- Etapa 1: fila ORIGINAL (UPDATE/DELETE). Etapa 2: fila NUEVA (INSERT/UPDATE).
    FOREACH v_etapa IN ARRAY CASE TG_OP WHEN 'INSERT' THEN ARRAY['NEW']
                                        WHEN 'DELETE' THEN ARRAY['OLD']
                                        ELSE ARRAY['OLD', 'NEW'] END
    LOOP
        IF v_etapa = 'OLD' THEN v_fila := OLD; ELSE v_fila := NEW; END IF;

        -- Contexto del estudiante
        SELECT e.EPE_ESTADO, e.EPE_PER_ID, e.EPE_SEC_ID, r.EPR_PEN_ID, r.EPR_ID,
               p.PER_ESTADO, p.PER_FECHA_INICIO, a.ANL_ANIO || ' / ' || p.PER_NOMBRE, x.POL_NOTA_APROBACION
          INTO v_epe_estado, v_epe_per_id, v_epe_sec_id, v_epr_pen_id, v_epr_id,
               v_per_estado, v_per_inicio, v_per_nombre, v_nota_minima
        FROM SIS_ACA_ESTUDIANTE_PERIODO  e
        JOIN SIS_ACA_ESTUDIANTE_PROGRAMA r ON r.EPR_ID = e.EPE_EPR_ID
        JOIN SIS_ACA_PERIODO_ACADEMICO   p ON p.PER_ID = e.EPE_PER_ID
        JOIN SIS_ACA_ANIO_LECTIVO        a ON a.ANL_ID = p.PER_ANL_ID
        JOIN SIS_ACA_POLITICA_ACADEMICA  x ON x.POL_ID = p.PER_POL_ID
        WHERE e.EPE_ID = v_fila.RES_EPE_ID;
        IF NOT FOUND THEN
            CONTINUE WHEN v_etapa = 'OLD';
            RETURN NEW;   -- FK_RES_EPE reportará el huérfano
        END IF;

        -- Contexto de la oferta
        SELECT o.OFE_ACTIVO, o.OFE_PER_ID, o.OFE_SEC_ID, c.PCU_PEN_ID, c.PCU_ID
          INTO v_ofe_activo, v_ofe_per_id, v_ofe_sec_id, v_pcu_pen_id, v_pcu_id
        FROM SIS_ACA_OFERTA_CURSO o
        JOIN SIS_ACA_PENSUM_CURSO c ON c.PCU_ID = o.OFE_PCU_ID
        WHERE o.OFE_ID = v_fila.RES_OFE_ID;
        IF NOT FOUND THEN
            CONTINUE WHEN v_etapa = 'OLD';
            RETURN NEW;   -- FK_RES_OFE reportará el huérfano
        END IF;

        -- (d) Período no ABIERTO (PLANIFICADO o CERRADO)
        IF v_per_estado <> 'ABIERTO' THEN
            RAISE EXCEPTION 'T2 PERIODO_NO_ABIERTO: el período % está %; solo un período ABIERTO admite % de resultados.', v_per_nombre, v_per_estado, TG_OP
                USING ERRCODE = 'SA204',
                      HINT    = 'Las correcciones excepcionales requieren reabrir explícitamente el período (PER_ESTADO = ''ABIERTO'').';
        END IF;

        -- (e) Estudiante no inscrito en el período
        IF v_epe_estado <> 'INSCRITO' THEN
            RAISE EXCEPTION 'T2: el estudiante (EPE_ID=%) está en estado % en el período %; solo un estudiante INSCRITO admite % de resultados.',
                            v_fila.RES_EPE_ID, v_epe_estado, v_per_nombre, TG_OP
                USING ERRCODE = 'SA205',
                      HINT    = 'Devuelva EPE_ESTADO a ''INSCRITO'' para corregir y vuelva a finalizar.';
        END IF;

        -- (f) Oferta inactiva
        IF NOT v_ofe_activo THEN
            RAISE EXCEPTION 'T2: la oferta OFE_ID=% está inactiva; no se permite % sobre sus resultados.', v_fila.RES_OFE_ID, TG_OP
                USING ERRCODE = 'SA206',
                      HINT    = 'Active la oferta (OFE_ACTIVO = TRUE) antes de registrar o corregir notas.';
        END IF;

        -- Coherencia: solo para la fila nueva
        IF v_etapa = 'NEW' THEN
            -- (a) Mismo período
            IF v_epe_per_id <> v_ofe_per_id THEN
                RAISE EXCEPTION 'T2: el estudiante (EPE_ID=%) está inscrito en el período PER_ID=%, pero la oferta (OFE_ID=%) pertenece al período PER_ID=%.',
                                NEW.RES_EPE_ID, v_epe_per_id, NEW.RES_OFE_ID, v_ofe_per_id
                    USING ERRCODE = 'SA201';
            END IF;

            -- (b) Mismo pensum
            IF v_epr_pen_id <> v_pcu_pen_id THEN
                RAISE EXCEPTION 'T2: la oferta (OFE_ID=%) pertenece al pensum PEN_ID=%, pero el estudiante cursa el pensum PEN_ID=%.',
                                NEW.RES_OFE_ID, v_pcu_pen_id, v_epr_pen_id
                    USING ERRCODE = 'SA202';
            END IF;

            -- (c) Misma sección (S1)
            IF v_epe_sec_id <> v_ofe_sec_id THEN
                RAISE EXCEPTION 'T2: el estudiante está en la sección SEC_ID=% y la oferta (OFE_ID=%) es de la sección SEC_ID=%. Regla S1: la sección debe coincidir.',
                                v_epe_sec_id, NEW.RES_OFE_ID, v_ofe_sec_id
                    USING ERRCODE = 'SA203';
            END IF;

            -- (g) Nuevo intento sobre curso ya aprobado en un período anterior (D6)
            IF TG_OP = 'INSERT' THEN
                SELECT a2.ANL_ANIO || ' / ' || p2.PER_NOMBRE || ' (nota ' || r2.RES_NOTA || ')'
                  INTO v_aprobado_en
                FROM SIS_ACA_RESULTADO_CURSO    r2
                JOIN SIS_ACA_ESTUDIANTE_PERIODO e2 ON e2.EPE_ID = r2.RES_EPE_ID
                JOIN SIS_ACA_OFERTA_CURSO       o2 ON o2.OFE_ID = r2.RES_OFE_ID
                JOIN SIS_ACA_PERIODO_ACADEMICO  p2 ON p2.PER_ID = e2.EPE_PER_ID
                JOIN SIS_ACA_ANIO_LECTIVO       a2 ON a2.ANL_ID = p2.PER_ANL_ID
                JOIN SIS_ACA_POLITICA_ACADEMICA x2 ON x2.POL_ID = p2.PER_POL_ID
                WHERE e2.EPE_EPR_ID = v_epr_id
                  AND o2.OFE_PCU_ID = v_pcu_id
                  AND p2.PER_FECHA_INICIO < v_per_inicio
                  AND r2.RES_NOTA >= x2.POL_NOTA_APROBACION
                ORDER BY p2.PER_FECHA_INICIO
                LIMIT 1;

                IF FOUND THEN
                    RAISE EXCEPTION 'T2: el curso (PCU_ID=%) ya fue aprobado por este estudiante en %; no se permite un nuevo intento posterior.',
                                    v_pcu_id, v_aprobado_en
                        USING ERRCODE = 'SA207',
                              HINT    = 'Un curso aprobado cuenta una sola vez. Los intentos reprobados anteriores se conservan.';
                END IF;
            END IF;

            -- (h) Corrección histórica que aprueba un intento con intentos posteriores (DF1)
            --     La identidad es inmutable (T4), así que OLD y NEW comparten período
            --     y v_nota_minima es la política histórica de ESE período.
            IF TG_OP = 'UPDATE'
               AND NEW.RES_NOTA IS NOT NULL AND NEW.RES_NOTA >= v_nota_minima
               AND (OLD.RES_NOTA IS NULL OR OLD.RES_NOTA < v_nota_minima) THEN
                SELECT string_agg(a2.ANL_ANIO || ' / ' || p2.PER_NOMBRE
                                  || ' (nota ' || COALESCE(r2.RES_NOTA::text, 'pendiente') || ')', ', ' ORDER BY p2.PER_FECHA_INICIO)
                  INTO v_posterior
                FROM SIS_ACA_RESULTADO_CURSO    r2
                JOIN SIS_ACA_ESTUDIANTE_PERIODO e2 ON e2.EPE_ID = r2.RES_EPE_ID
                JOIN SIS_ACA_OFERTA_CURSO       o2 ON o2.OFE_ID = r2.RES_OFE_ID
                JOIN SIS_ACA_PERIODO_ACADEMICO  p2 ON p2.PER_ID = e2.EPE_PER_ID
                JOIN SIS_ACA_ANIO_LECTIVO       a2 ON a2.ANL_ID = p2.PER_ANL_ID
                WHERE e2.EPE_EPR_ID = v_epr_id
                  AND o2.OFE_PCU_ID = v_pcu_id
                  AND p2.PER_FECHA_INICIO > v_per_inicio;

                IF v_posterior IS NOT NULL THEN
                    RAISE EXCEPTION 'T2: la corrección convertiría en APROBADO (nota %, mínima % en %) un intento del curso PCU_ID=%, pero existen intentos posteriores: %.',
                                    NEW.RES_NOTA, v_nota_minima, v_per_nombre, v_pcu_id, v_posterior
                        USING ERRCODE = 'SA208',
                              HINT    = 'Los intentos posteriores deben resolverse administrativamente (anularlos con su período reabierto) antes de convertir el intento histórico en aprobado.';
                END IF;
            END IF;
        END IF;
    END LOOP;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END
$$;
COMMENT ON FUNCTION SIS_ACA_FN_T2_VALIDAR_RESULTADO() IS 'T2: un resultado solo se escribe con período ABIERTO, estudiante INSCRITO, oferta activa, mismo período/pensum/sección sin aprobación previa del curso (nuevo intento) y sin aprobar retroactivamente un intento con intentos posteriores.';

-- En RESULTADO_CURSO el orden importa (los BEFORE triggers corren en orden
-- alfabético): TRG_RES_01_T4_IDENTIDAD → TRG_RES_02_T2_CONTEXTO → TRG_RES_T1_ACTUALIZACION.
-- Así un cambio de identidad siempre responde SA401 (T4) antes que T2.
CREATE TRIGGER TRG_RES_02_T2_CONTEXTO
    BEFORE INSERT OR UPDATE OR DELETE ON SIS_ACA_RESULTADO_CURSO
    FOR EACH ROW EXECUTE FUNCTION SIS_ACA_FN_T2_VALIDAR_RESULTADO();


-- =====================================================================
-- T3 · Integridad de la política académica
-- ---------------------------------------------------------------------
-- Responsabilidad única: que cada período quede evaluado, para siempre,
-- por la política vigente en su fecha de inicio.
--
-- Sobre SIS_ACA_PERIODO_ACADEMICO (INSERT / UPDATE de política o fecha):
--   · Si PER_POL_ID viene NULL, se asigna la vigente (comodidad para la app).
--   · Debe existir política vigente en PER_FECHA_INICIO        (SA301)
--   · PER_POL_ID debe ser exactamente esa política            (SA302)
--   · No se cambia la política de un período con resultados    (SA305)
--
-- Sobre SIS_ACA_POLITICA_ACADEMICA (INSERT / UPDATE):
--   · Si ya la usa algún período, POL_NOTA_APROBACION y
--     POL_VIGENTE_DESDE quedan protegidos                      (SA303)
--     (código y nombre siguen editables: no alteran resultados).
--   · Una nueva vigencia no puede "absorber" períodos ya creados que
--     hoy dependen de una política anterior                     (SA304)
--     → impide reformas retroactivas: POL-2028 no toca 2025/2026.
--
-- El DELETE de una política usada lo impide FK_PER_POL (RESTRICT).
-- =====================================================================
CREATE OR REPLACE FUNCTION SIS_ACA_FN_T3_INTEGRIDAD_POLITICA()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_vigente   integer;
    v_periodo   text;
BEGIN
    IF TG_TABLE_NAME = 'sis_aca_periodo_academico' THEN

        v_vigente := SIS_ACA_FN_POLITICA_VIGENTE(NEW.PER_FECHA_INICIO);

        IF v_vigente IS NULL THEN
            RAISE EXCEPTION 'T3: no existe una política académica vigente al % (inicio del período "%").',
                            NEW.PER_FECHA_INICIO, NEW.PER_NOMBRE
                USING ERRCODE = 'SA301',
                      HINT    = 'Registre primero una política con POL_VIGENTE_DESDE <= fecha de inicio del período.';
        END IF;

        IF NEW.PER_POL_ID IS NULL THEN
            NEW.PER_POL_ID := v_vigente;
        ELSIF NEW.PER_POL_ID <> v_vigente THEN
            RAISE EXCEPTION 'T3: el período "%" inicia el %; la política vigente en esa fecha es POL_ID=%, no POL_ID=%.',
                            NEW.PER_NOMBRE, NEW.PER_FECHA_INICIO, v_vigente, NEW.PER_POL_ID
                USING ERRCODE = 'SA302';
        END IF;

        IF TG_OP = 'UPDATE'
           AND NEW.PER_POL_ID IS DISTINCT FROM OLD.PER_POL_ID
           AND EXISTS (SELECT 1
                       FROM SIS_ACA_ESTUDIANTE_PERIODO e
                       JOIN SIS_ACA_RESULTADO_CURSO    r ON r.RES_EPE_ID = e.EPE_ID
                       WHERE e.EPE_PER_ID = OLD.PER_ID) THEN
            RAISE EXCEPTION 'T3: el período "%" ya tiene resultados; no se puede cambiar su política (POL_ID % → %).',
                            OLD.PER_NOMBRE, OLD.PER_POL_ID, NEW.PER_POL_ID
                USING ERRCODE = 'SA305';
        END IF;

        RETURN NEW;

    ELSIF TG_TABLE_NAME = 'sis_aca_politica_academica' THEN

        IF TG_OP = 'UPDATE'
           AND (NEW.POL_NOTA_APROBACION IS DISTINCT FROM OLD.POL_NOTA_APROBACION
                OR NEW.POL_VIGENTE_DESDE IS DISTINCT FROM OLD.POL_VIGENTE_DESDE)
           AND EXISTS (SELECT 1 FROM SIS_ACA_PERIODO_ACADEMICO WHERE PER_POL_ID = OLD.POL_ID) THEN
            RAISE EXCEPTION 'T3: la política % ya fue utilizada por al menos un período; su nota de aprobación y su fecha de vigencia están protegidas.',
                            OLD.POL_CODIGO
                USING ERRCODE = 'SA303',
                      HINT    = 'Para cambiar la regla, cree una NUEVA política con vigencia futura.';
        END IF;

        IF TG_OP = 'INSERT' OR NEW.POL_VIGENTE_DESDE IS DISTINCT FROM OLD.POL_VIGENTE_DESDE THEN
            SELECT a.ANL_ANIO || ' / ' || p.PER_NOMBRE
              INTO v_periodo
            FROM SIS_ACA_PERIODO_ACADEMICO  p
            JOIN SIS_ACA_POLITICA_ACADEMICA x ON x.POL_ID = p.PER_POL_ID
            JOIN SIS_ACA_ANIO_LECTIVO       a ON a.ANL_ID = p.PER_ANL_ID
            WHERE p.PER_FECHA_INICIO  >= NEW.POL_VIGENTE_DESDE
              AND x.POL_VIGENTE_DESDE <  NEW.POL_VIGENTE_DESDE
              AND x.POL_ID            <> NEW.POL_ID
            ORDER BY p.PER_FECHA_INICIO
            LIMIT 1;

            IF FOUND THEN
                RAISE EXCEPTION 'T3: la política % con vigencia desde % cambiaría retroactivamente la política del período % (ya registrado).',
                                NEW.POL_CODIGO, NEW.POL_VIGENTE_DESDE, v_periodo
                    USING ERRCODE = 'SA304',
                          HINT    = 'Las nuevas políticas deben iniciar después del inicio del último período que depende de la política anterior.';
            END IF;
        END IF;

        RETURN NEW;
    END IF;

    RAISE EXCEPTION 'T3: tabla no soportada: %', TG_TABLE_NAME;
END
$$;
COMMENT ON FUNCTION SIS_ACA_FN_T3_INTEGRIDAD_POLITICA() IS 'T3: el período usa la política vigente en su inicio; una política usada no cambia; no hay reformas retroactivas.';

CREATE TRIGGER TRG_PER_T3_POLITICA
    BEFORE INSERT OR UPDATE OF PER_POL_ID, PER_FECHA_INICIO ON SIS_ACA_PERIODO_ACADEMICO
    FOR EACH ROW EXECUTE FUNCTION SIS_ACA_FN_T3_INTEGRIDAD_POLITICA();

CREATE TRIGGER TRG_POL_T3_POLITICA
    BEFORE INSERT OR UPDATE OF POL_NOTA_APROBACION, POL_VIGENTE_DESDE ON SIS_ACA_POLITICA_ACADEMICA
    FOR EACH ROW EXECUTE FUNCTION SIS_ACA_FN_T3_INTEGRIDAD_POLITICA();


-- =====================================================================
-- T4 · Congelamiento del contexto académico
-- ---------------------------------------------------------------------
-- Responsabilidad única: impedir que se reescriba la historia académica
-- modificando columnas que DEFINEN el contexto de datos ya dependientes.
-- Solo se congelan esas columnas; el resto (estado, activo, nombres,
-- descripciones) sigue editable.
--
--   Tabla                         Columnas congeladas                       Dependencia que congela
--   SIS_ACA_ESTUDIANTE_PROGRAMA   EPR_PEN_ID                                resultados del programa
--   SIS_ACA_ESTUDIANTE_PERIODO    EPE_EPR_ID, EPE_PER_ID, EPE_CIC_ID,       resultados del estudiante-período
--                                 EPE_SEC_ID
--   SIS_ACA_OFERTA_CURSO          OFE_PER_ID, OFE_PCU_ID, OFE_SEC_ID        resultados de la oferta
--   SIS_ACA_PENSUM_CURSO          PCU_PEN_ID, PCU_CUR_ID, PCU_CIC_ID        resultados de sus ofertas (E1-H1)
--   SIS_ACA_PENSUM                PEN_CAR_ID                                existe un ESTUDIANTE_PROGRAMA con el pensum
--   SIS_ACA_PERIODO_ACADEMICO     PER_ANL_ID, PER_NUMERO,                   resultados del período
--                                 PER_FECHA_INICIO, PER_FECHA_FIN           (PER_POL_ID: responsabilidad de T3)
--   SIS_ACA_ANIO_LECTIVO          ANL_ANIO                                  resultados de sus períodos
--   SIS_ACA_CICLO_CURRICULAR      CIC_ANIO, CIC_SEMESTRE                    referenciado por PENSUM_CURSO o ESTUDIANTE_PERIODO
--   SIS_ACA_RESULTADO_CURSO       RES_EPE_ID, RES_OFE_ID                    SIEMPRE (identidad del intento)
--                                 RES_NOTA / RES_CALIFICADO_EN siguen editables mientras T2 lo permita.
--                                 Un resultado en el contexto equivocado se corrige con DELETE + INSERT.
--
-- Para corregir un error de captura: eliminar primero las dependencias
-- (solo posible si T2 lo permite) o registrar un contexto nuevo.
-- =====================================================================
CREATE OR REPLACE FUNCTION SIS_ACA_FN_T4_CONGELAR_CONTEXTO()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_columnas text;
    v_motivo   text := 'resultados académicos dependientes';
    v_existe   boolean := false;
BEGIN
    CASE TG_TABLE_NAME
    WHEN 'sis_aca_estudiante_programa' THEN
        IF NEW.EPR_PEN_ID IS DISTINCT FROM OLD.EPR_PEN_ID THEN
            v_columnas := 'EPR_PEN_ID';
            SELECT EXISTS (SELECT 1
                           FROM SIS_ACA_ESTUDIANTE_PERIODO e
                           JOIN SIS_ACA_RESULTADO_CURSO    r ON r.RES_EPE_ID = e.EPE_ID
                           WHERE e.EPE_EPR_ID = OLD.EPR_ID)
              INTO v_existe;
        END IF;

    WHEN 'sis_aca_estudiante_periodo' THEN
        IF (NEW.EPE_EPR_ID, NEW.EPE_PER_ID, NEW.EPE_CIC_ID, NEW.EPE_SEC_ID)
           IS DISTINCT FROM (OLD.EPE_EPR_ID, OLD.EPE_PER_ID, OLD.EPE_CIC_ID, OLD.EPE_SEC_ID) THEN
            v_columnas := 'EPE_EPR_ID, EPE_PER_ID, EPE_CIC_ID, EPE_SEC_ID';
            SELECT EXISTS (SELECT 1 FROM SIS_ACA_RESULTADO_CURSO WHERE RES_EPE_ID = OLD.EPE_ID)
              INTO v_existe;
        END IF;

    WHEN 'sis_aca_oferta_curso' THEN
        IF (NEW.OFE_PER_ID, NEW.OFE_PCU_ID, NEW.OFE_SEC_ID)
           IS DISTINCT FROM (OLD.OFE_PER_ID, OLD.OFE_PCU_ID, OLD.OFE_SEC_ID) THEN
            v_columnas := 'OFE_PER_ID, OFE_PCU_ID, OFE_SEC_ID';
            SELECT EXISTS (SELECT 1 FROM SIS_ACA_RESULTADO_CURSO WHERE RES_OFE_ID = OLD.OFE_ID)
              INTO v_existe;
        END IF;

    WHEN 'sis_aca_pensum_curso' THEN
        IF (NEW.PCU_PEN_ID, NEW.PCU_CUR_ID, NEW.PCU_CIC_ID)
           IS DISTINCT FROM (OLD.PCU_PEN_ID, OLD.PCU_CUR_ID, OLD.PCU_CIC_ID) THEN
            v_columnas := 'PCU_PEN_ID, PCU_CUR_ID, PCU_CIC_ID';
            SELECT EXISTS (SELECT 1
                           FROM SIS_ACA_OFERTA_CURSO    o
                           JOIN SIS_ACA_RESULTADO_CURSO r ON r.RES_OFE_ID = o.OFE_ID
                           WHERE o.OFE_PCU_ID = OLD.PCU_ID)
              INTO v_existe;
        END IF;

    WHEN 'sis_aca_pensum' THEN
        IF NEW.PEN_CAR_ID IS DISTINCT FROM OLD.PEN_CAR_ID THEN
            v_columnas := 'PEN_CAR_ID';
            v_motivo   := 'estudiantes inscritos con este pensum';
            SELECT EXISTS (SELECT 1 FROM SIS_ACA_ESTUDIANTE_PROGRAMA WHERE EPR_PEN_ID = OLD.PEN_ID)
              INTO v_existe;
        END IF;

    WHEN 'sis_aca_periodo_academico' THEN
        IF (NEW.PER_ANL_ID, NEW.PER_NUMERO, NEW.PER_FECHA_INICIO, NEW.PER_FECHA_FIN)
           IS DISTINCT FROM (OLD.PER_ANL_ID, OLD.PER_NUMERO, OLD.PER_FECHA_INICIO, OLD.PER_FECHA_FIN) THEN
            v_columnas := 'PER_ANL_ID, PER_NUMERO, PER_FECHA_INICIO, PER_FECHA_FIN';
            SELECT EXISTS (SELECT 1
                           FROM SIS_ACA_ESTUDIANTE_PERIODO e
                           JOIN SIS_ACA_RESULTADO_CURSO    r ON r.RES_EPE_ID = e.EPE_ID
                           WHERE e.EPE_PER_ID = OLD.PER_ID)
              INTO v_existe;
        END IF;

    WHEN 'sis_aca_anio_lectivo' THEN
        IF NEW.ANL_ANIO IS DISTINCT FROM OLD.ANL_ANIO THEN
            v_columnas := 'ANL_ANIO';
            SELECT EXISTS (SELECT 1
                           FROM SIS_ACA_PERIODO_ACADEMICO  p
                           JOIN SIS_ACA_ESTUDIANTE_PERIODO e ON e.EPE_PER_ID = p.PER_ID
                           JOIN SIS_ACA_RESULTADO_CURSO    r ON r.RES_EPE_ID = e.EPE_ID
                           WHERE p.PER_ANL_ID = OLD.ANL_ID)
              INTO v_existe;
        END IF;

    WHEN 'sis_aca_ciclo_curricular' THEN
        IF (NEW.CIC_ANIO, NEW.CIC_SEMESTRE) IS DISTINCT FROM (OLD.CIC_ANIO, OLD.CIC_SEMESTRE) THEN
            v_columnas := 'CIC_ANIO, CIC_SEMESTRE';
            v_motivo   := 'referencias desde PENSUM_CURSO o ESTUDIANTE_PERIODO';
            SELECT EXISTS (SELECT 1 FROM SIS_ACA_PENSUM_CURSO       WHERE PCU_CIC_ID = OLD.CIC_ID)
                OR EXISTS (SELECT 1 FROM SIS_ACA_ESTUDIANTE_PERIODO WHERE EPE_CIC_ID = OLD.CIC_ID)
              INTO v_existe;
        END IF;

    WHEN 'sis_aca_resultado_curso' THEN
        IF (NEW.RES_EPE_ID, NEW.RES_OFE_ID) IS DISTINCT FROM (OLD.RES_EPE_ID, OLD.RES_OFE_ID) THEN
            v_columnas := 'RES_EPE_ID, RES_OFE_ID';
            v_motivo   := 'identidad de intento inmutable (corrija con DELETE + INSERT)';
            v_existe   := true;
        END IF;

    ELSE
        RAISE EXCEPTION 'T4: tabla no soportada: %', TG_TABLE_NAME;
    END CASE;

    IF v_existe THEN
        RAISE EXCEPTION 'T4: % tiene %; las columnas de contexto (%) están congeladas.',
                        upper(TG_TABLE_NAME), v_motivo, v_columnas
            USING ERRCODE = 'SA401',
                  HINT    = 'Para corregir, elimine primero las dependencias (si T2 lo permite) o registre un contexto nuevo.';
    END IF;

    RETURN NEW;
END
$$;
COMMENT ON FUNCTION SIS_ACA_FN_T4_CONGELAR_CONTEXTO() IS 'T4: congela las columnas que definen el contexto académico cuando existen datos dependientes (8 tablas) y la identidad de RESULTADO_CURSO.';

CREATE TRIGGER TRG_EPR_T4_CONTEXTO
    BEFORE UPDATE OF EPR_PEN_ID ON SIS_ACA_ESTUDIANTE_PROGRAMA
    FOR EACH ROW EXECUTE FUNCTION SIS_ACA_FN_T4_CONGELAR_CONTEXTO();

CREATE TRIGGER TRG_EPE_T4_CONTEXTO
    BEFORE UPDATE OF EPE_EPR_ID, EPE_PER_ID, EPE_CIC_ID, EPE_SEC_ID ON SIS_ACA_ESTUDIANTE_PERIODO
    FOR EACH ROW EXECUTE FUNCTION SIS_ACA_FN_T4_CONGELAR_CONTEXTO();

CREATE TRIGGER TRG_OFE_T4_CONTEXTO
    BEFORE UPDATE OF OFE_PER_ID, OFE_PCU_ID, OFE_SEC_ID ON SIS_ACA_OFERTA_CURSO
    FOR EACH ROW EXECUTE FUNCTION SIS_ACA_FN_T4_CONGELAR_CONTEXTO();

CREATE TRIGGER TRG_PCU_T4_CONTEXTO
    BEFORE UPDATE OF PCU_PEN_ID, PCU_CUR_ID, PCU_CIC_ID ON SIS_ACA_PENSUM_CURSO
    FOR EACH ROW EXECUTE FUNCTION SIS_ACA_FN_T4_CONGELAR_CONTEXTO();

CREATE TRIGGER TRG_PEN_T4_CONTEXTO
    BEFORE UPDATE OF PEN_CAR_ID ON SIS_ACA_PENSUM
    FOR EACH ROW EXECUTE FUNCTION SIS_ACA_FN_T4_CONGELAR_CONTEXTO();

-- Nota: en SIS_ACA_PERIODO_ACADEMICO los BEFORE triggers se ejecutan en
-- orden alfabético: T1 → T3 (política) → T4 (contexto).
CREATE TRIGGER TRG_PER_T4_CONTEXTO
    BEFORE UPDATE OF PER_ANL_ID, PER_NUMERO, PER_FECHA_INICIO, PER_FECHA_FIN ON SIS_ACA_PERIODO_ACADEMICO
    FOR EACH ROW EXECUTE FUNCTION SIS_ACA_FN_T4_CONGELAR_CONTEXTO();

CREATE TRIGGER TRG_ANL_T4_CONTEXTO
    BEFORE UPDATE OF ANL_ANIO ON SIS_ACA_ANIO_LECTIVO
    FOR EACH ROW EXECUTE FUNCTION SIS_ACA_FN_T4_CONGELAR_CONTEXTO();

CREATE TRIGGER TRG_CIC_T4_CONTEXTO
    BEFORE UPDATE OF CIC_ANIO, CIC_SEMESTRE ON SIS_ACA_CICLO_CURRICULAR
    FOR EACH ROW EXECUTE FUNCTION SIS_ACA_FN_T4_CONGELAR_CONTEXTO();

-- Ver nota de orden junto a TRG_RES_02_T2_CONTEXTO.
CREATE TRIGGER TRG_RES_01_T4_IDENTIDAD
    BEFORE UPDATE OF RES_EPE_ID, RES_OFE_ID ON SIS_ACA_RESULTADO_CURSO
    FOR EACH ROW EXECUTE FUNCTION SIS_ACA_FN_T4_CONGELAR_CONTEXTO();
