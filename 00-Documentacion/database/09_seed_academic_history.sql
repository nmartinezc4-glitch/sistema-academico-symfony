-- =====================================================================
--  09_seed_academic_history.sql — E2 · Historial académico 2025–2026
--
--  DEMONSTRATION DATA · FICTIONAL · ACADEMICALLY PLAUSIBLE
--
--  Reproducibilidad: no usa random(). Cada nota es
--      COALESCE(nota fija del caso, base del perfil + dificultad del curso + ruido)
--  donde el ruido (−6…+6) sale de md5(estudiante|curso|período): mismo
--  dato de entrada → misma nota, en cualquier instalación.
--
--    Perfil   base   rango posible        efecto
--    ALTO      90    77–100               nunca reprueba
--    MEDIO     76    63–86                nunca reprueba por fórmula
--    BAJO      65    52–75                reprobaciones naturales
--
--    Dificultad: MAT −7 · FIS −6 · FIN −4 · CON −3 · PRG −2 ·
--                ING +4 · ETI/SEM +3 · ART +6 · resto 0
--
--  Ciclo de vida por período (respeta T2/T3/T4):
--    PLANIFICADO → ABIERTO → inscripción (EPE) → ofertas → resultados
--    → EPE FINALIZADO → período CERRADO.
--  2026-II queda ABIERTO (hoy es octubre de 2026): la cohorte 2025
--  (graduandos) ya tiene notas; la cohorte 2026 está en curso, con notas
--  parciales o pendientes (CASO I).
--
--  Tablas y funciones auxiliares: TEMPORALES (pg_temp), se eliminan al final
--  del script (y en todo caso al cerrar la sesión).
-- =====================================================================

-- ---------------------------------------------------------------------
-- Perfil de rendimiento (solo para generar el dataset; no se guarda)
-- ---------------------------------------------------------------------
CREATE TEMP TABLE seed_perfil (est text PRIMARY KEY, perfil text NOT NULL);
INSERT INTO seed_perfil
SELECT e.EST_CODIGO,
       CASE
         WHEN e.EST_CODIGO IN ('STU-2025-0001','STU-2025-0009','STU-2025-0011','STU-2025-0016','STU-2025-0021',
                               'STU-2026-0001','STU-2026-0007','STU-2026-0011','STU-2026-0017') THEN 'ALTO'
         WHEN e.EST_CODIGO IN ('STU-2025-0005','STU-2025-0010','STU-2025-0014','STU-2025-0018','STU-2025-0020','STU-2025-0024',
                               'STU-2026-0004','STU-2026-0008','STU-2026-0012','STU-2026-0015') THEN 'BAJO'
         ELSE 'MEDIO'
       END
FROM SIS_ACA_ESTUDIANTE e;

-- ---------------------------------------------------------------------
-- Ubicación: (estudiante, período, ciclo curricular, sección)
-- ---------------------------------------------------------------------
CREATE TEMP TABLE seed_ubicacion (est text, per text, cic_anio int, cic_sem int, sec text, PRIMARY KEY (est, per));
WITH seccion(desde, hasta, sec) AS (VALUES
  ('STU-2025-0001','STU-2025-0001','A'), ('STU-2025-0002','STU-2025-0003','A'), ('STU-2025-0006','STU-2025-0006','A'),
  ('STU-2025-0008','STU-2025-0008','A'), ('STU-2025-0004','STU-2025-0005','B'), ('STU-2025-0007','STU-2025-0007','B'),
  ('STU-2025-0009','STU-2025-0010','B'),
  ('STU-2025-0011','STU-2025-0014','A'), ('STU-2025-0015','STU-2025-0018','B'),
  ('STU-2025-0019','STU-2025-0022','A'), ('STU-2025-0023','STU-2025-0026','C'),
  ('STU-2026-0001','STU-2026-0004','A'), ('STU-2026-0005','STU-2026-0008','B'),
  ('STU-2026-0009','STU-2026-0013','A'), ('STU-2026-0014','STU-2026-0018','B')
),
trayecto(cohorte, per, cic_anio, cic_sem) AS (VALUES
  ('2025','2025-1',1,1), ('2025','2025-2',1,2), ('2025','2026-1',2,1), ('2025','2026-2',2,2),
  ('2026','2026-1',1,1), ('2026','2026-2',1,2)
)
INSERT INTO seed_ubicacion
SELECT e.EST_CODIGO, t.per, t.cic_anio, t.cic_sem, s.sec
FROM SIS_ACA_ESTUDIANTE e
JOIN seccion  s ON e.EST_CODIGO BETWEEN s.desde AND s.hasta
JOIN trayecto t ON t.cohorte = substr(e.EST_CODIGO, 5, 4)
WHERE NOT (e.EST_CODIGO = 'STU-2025-0026' AND t.per LIKE '2026%');   -- retirado al cierre de 2025

-- ---------------------------------------------------------------------
-- Notas fijas: casos nombrados y valores de frontera (58–63)
-- ---------------------------------------------------------------------
CREATE TEMP TABLE seed_nota_fija (est text, per text, cur text, nota numeric(5,2), PRIMARY KEY (est, per, cur));
INSERT INTO seed_nota_fija VALUES
  ('STU-2025-0001','2025-1','PRG-101', 98.00),   -- CASO A: excelencia
  ('STU-2025-0001','2026-2','SOF-202', 97.00),
  ('STU-2025-0001','2025-2','WEB-101', 96.00),
  ('STU-2025-0002','2025-1','FIS-101', 61.00),   -- CASO B: límite de aprobación
  ('STU-2025-0003','2025-2','MAT-102', 60.00),   -- CASO C: límite de reprobación
  ('STU-2025-0004','2025-1','PRG-101', 52.00),   -- CASO D: 1.er intento reprobado
  ('STU-2025-0004','2026-1','PRG-101', 74.00),   -- CASO D: 2.º intento aprobado
  ('STU-2025-0005','2025-1','MAT-101', 48.00),   -- CASO E: 1.er intento reprobado
  ('STU-2025-0005','2026-1','MAT-101', 57.00),   -- CASO E: 2.º intento reprobado
  ('STU-2025-0007','2025-2','ING-102', 58.00),   -- CASO G: ciclo incompleto
  ('STU-2025-0008','2025-2','FIS-102', 62.00),   -- frontera
  ('STU-2025-0006','2026-1','EST-201', 63.00),   -- frontera
  ('STU-2025-0010','2026-1','MAT-201', 59.00),   -- frontera (reprueba)
  ('STU-2025-0012','2025-1','MAT-101', 61.00),   -- frontera
  ('STU-2026-0003','2026-1','MAT-101', 60.00),   -- frontera (reprueba)
  ('STU-2026-0009','2026-1','ING-101', 65.00);   -- usado en la validación histórica §47 (E3)

-- Intentos de repitencia (curso de un ciclo anterior cursado en otro período)
CREATE TEMP TABLE seed_repitencia (est text, per text, cur text, PRIMARY KEY (est, per, cur));
INSERT INTO seed_repitencia VALUES
  ('STU-2025-0004','2026-1','PRG-101'),          -- CASO D
  ('STU-2025-0005','2026-1','MAT-101');          -- CASO E

-- ---------------------------------------------------------------------
-- Nota generada (determinista)
-- ---------------------------------------------------------------------
CREATE FUNCTION pg_temp.nota_generada(p_est text, p_cur text, p_per text) RETURNS numeric
LANGUAGE sql STABLE AS $$
    SELECT least(100, greatest(0,
             CASE (SELECT perfil FROM seed_perfil WHERE est = p_est) WHEN 'ALTO' THEN 90 WHEN 'BAJO' THEN 65 ELSE 76 END
           + CASE left(p_cur, 3) WHEN 'MAT' THEN -7 WHEN 'FIS' THEN -6 WHEN 'FIN' THEN -4 WHEN 'CON' THEN -3
                                 WHEN 'PRG' THEN -2 WHEN 'ING' THEN 4  WHEN 'ETI' THEN 3  WHEN 'SEM' THEN 3
                                 WHEN 'ART' THEN 6  ELSE 0 END
           + (('x' || substr(md5(p_est || '|' || p_cur || '|' || p_per), 1, 7))::bit(28)::int % 13) - 6
           ))::numeric(5,2)
$$;

-- ¿La nota de este resultado ya está registrada? (solo 2026-II tiene pendientes)
CREATE FUNCTION pg_temp.nota_registrada(p_est text, p_cur text, p_per text) RETURNS boolean
LANGUAGE sql STABLE AS $$
    SELECT p_per <> '2026-2'
        OR substr(p_est, 5, 4) = '2025'                                   -- graduandos: notas ya ingresadas
        OR (p_est BETWEEN 'STU-2026-0001' AND 'STU-2026-0008'
            AND p_cur IN ('PRG-102', 'ING-102'))                          -- Computación 2026: dos cursos ya calificados
$$;

-- ---------------------------------------------------------------------
-- Carga de un período completo
-- ---------------------------------------------------------------------
CREATE FUNCTION pg_temp.cargar_periodo(p_per text, p_cerrar boolean) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
    v_per_id     integer;
    v_calificado timestamptz;
BEGIN
    SELECT p.PER_ID,
           CASE WHEN p_cerrar THEN (p.PER_FECHA_FIN + time '16:00') AT TIME ZONE 'America/Guatemala'
                ELSE TIMESTAMPTZ '2026-10-02 16:00:00-06' END
      INTO v_per_id, v_calificado
    FROM SIS_ACA_PERIODO_ACADEMICO p JOIN SIS_ACA_ANIO_LECTIVO a ON a.ANL_ID = p.PER_ANL_ID
    WHERE a.ANL_ANIO || '-' || p.PER_NUMERO = p_per;

    -- 1) Abrir el período (D7: solo ABIERTO admite resultados)
    UPDATE SIS_ACA_PERIODO_ACADEMICO SET PER_ESTADO = 'ABIERTO' WHERE PER_ID = v_per_id;

    -- 2) Inscripción del estudiante en el período (ciclo + sección)
    INSERT INTO SIS_ACA_ESTUDIANTE_PERIODO (EPE_EPR_ID, EPE_PER_ID, EPE_CIC_ID, EPE_SEC_ID)
    SELECT r.EPR_ID, v_per_id, k.CIC_ID, s.SEC_ID
    FROM seed_ubicacion u
    JOIN SIS_ACA_ESTUDIANTE e          ON e.EST_CODIGO = u.est
    JOIN SIS_ACA_ESTUDIANTE_PROGRAMA r ON r.EPR_EST_ID = e.EST_ID
    JOIN SIS_ACA_CICLO_CURRICULAR k    ON k.CIC_ANIO = u.cic_anio AND k.CIC_SEMESTRE = u.cic_sem
    JOIN SIS_ACA_SECCION s             ON s.SEC_CODIGO = u.sec
    WHERE u.per = p_per
    ORDER BY u.est;

    -- 3) Ofertas: cursos del ciclo por cada (pensum, ciclo, sección) presente
    INSERT INTO SIS_ACA_OFERTA_CURSO (OFE_PER_ID, OFE_PCU_ID, OFE_SEC_ID)
    SELECT DISTINCT v_per_id, c.PCU_ID, e.EPE_SEC_ID
    FROM SIS_ACA_ESTUDIANTE_PERIODO  e
    JOIN SIS_ACA_ESTUDIANTE_PROGRAMA r ON r.EPR_ID = e.EPE_EPR_ID
    JOIN SIS_ACA_PENSUM_CURSO        c ON c.PCU_PEN_ID = r.EPR_PEN_ID AND c.PCU_CIC_ID = e.EPE_CIC_ID
    WHERE e.EPE_PER_ID = v_per_id
    ORDER BY 2, 3;

    --    + ofertas para repitentes que no coincidan con una ya creada
    INSERT INTO SIS_ACA_OFERTA_CURSO (OFE_PER_ID, OFE_PCU_ID, OFE_SEC_ID)
    SELECT DISTINCT v_per_id, c.PCU_ID, s.SEC_ID
    FROM seed_repitencia x
    JOIN seed_ubicacion u              ON u.est = x.est AND u.per = x.per
    JOIN SIS_ACA_ESTUDIANTE e          ON e.EST_CODIGO = x.est
    JOIN SIS_ACA_ESTUDIANTE_PROGRAMA r ON r.EPR_EST_ID = e.EST_ID
    JOIN SIS_ACA_CURSO cu              ON cu.CUR_CODIGO = x.cur
    JOIN SIS_ACA_PENSUM_CURSO c        ON c.PCU_PEN_ID = r.EPR_PEN_ID AND c.PCU_CUR_ID = cu.CUR_ID
    JOIN SIS_ACA_SECCION s             ON s.SEC_CODIGO = u.sec
    WHERE x.per = p_per
    ON CONFLICT ON CONSTRAINT UQ_OFE_PER_PCU_SEC DO NOTHING;

    -- 4a) Resultados de los cursos del ciclo. El optativo (ART-101) solo lo
    --     llevan los estudiantes con código impar.
    INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID, RES_NOTA, RES_CALIFICADO_EN)
    SELECT q.EPE_ID, q.OFE_ID, q.nota, CASE WHEN q.nota IS NULL THEN NULL ELSE v_calificado END
    FROM (
        SELECT e.EPE_ID, o.OFE_ID,
               CASE WHEN pg_temp.nota_registrada(est.EST_CODIGO, cu.CUR_CODIGO, p_per)
                    THEN COALESCE(f.nota, pg_temp.nota_generada(est.EST_CODIGO, cu.CUR_CODIGO, p_per))
               END AS nota,
               est.EST_CODIGO, c.PCU_ORDEN
        FROM SIS_ACA_ESTUDIANTE_PERIODO  e
        JOIN SIS_ACA_ESTUDIANTE_PROGRAMA r   ON r.EPR_ID = e.EPE_EPR_ID
        JOIN SIS_ACA_ESTUDIANTE          est ON est.EST_ID = r.EPR_EST_ID
        JOIN SIS_ACA_PENSUM_CURSO        c   ON c.PCU_PEN_ID = r.EPR_PEN_ID AND c.PCU_CIC_ID = e.EPE_CIC_ID
        JOIN SIS_ACA_CURSO               cu  ON cu.CUR_ID = c.PCU_CUR_ID
        JOIN SIS_ACA_OFERTA_CURSO        o   ON o.OFE_PER_ID = e.EPE_PER_ID AND o.OFE_PCU_ID = c.PCU_ID AND o.OFE_SEC_ID = e.EPE_SEC_ID
        LEFT JOIN seed_nota_fija         f   ON f.est = est.EST_CODIGO AND f.per = p_per AND f.cur = cu.CUR_CODIGO
        WHERE e.EPE_PER_ID = v_per_id
          AND (c.PCU_OBLIGATORIO OR right(est.EST_CODIGO, 1)::int % 2 = 1)
    ) q
    ORDER BY q.EST_CODIGO, q.PCU_ORDEN;

    -- 4b) Resultados de repitencia
    INSERT INTO SIS_ACA_RESULTADO_CURSO (RES_EPE_ID, RES_OFE_ID, RES_NOTA, RES_CALIFICADO_EN)
    SELECT e.EPE_ID, o.OFE_ID, f.nota, CASE WHEN f.nota IS NULL THEN NULL ELSE v_calificado END
    FROM seed_repitencia x
    JOIN SIS_ACA_ESTUDIANTE          est ON est.EST_CODIGO = x.est
    JOIN SIS_ACA_ESTUDIANTE_PROGRAMA r   ON r.EPR_EST_ID = est.EST_ID
    JOIN SIS_ACA_ESTUDIANTE_PERIODO  e   ON e.EPE_EPR_ID = r.EPR_ID AND e.EPE_PER_ID = v_per_id
    JOIN SIS_ACA_CURSO               cu  ON cu.CUR_CODIGO = x.cur
    JOIN SIS_ACA_PENSUM_CURSO        c   ON c.PCU_PEN_ID = r.EPR_PEN_ID AND c.PCU_CUR_ID = cu.CUR_ID
    JOIN SIS_ACA_OFERTA_CURSO        o   ON o.OFE_PER_ID = v_per_id AND o.OFE_PCU_ID = c.PCU_ID AND o.OFE_SEC_ID = e.EPE_SEC_ID
    LEFT JOIN seed_nota_fija         f   ON f.est = x.est AND f.per = x.per AND f.cur = x.cur
    WHERE x.per = p_per
    ORDER BY x.est;

    -- 5) Cierre del período
    IF p_cerrar THEN
        UPDATE SIS_ACA_ESTUDIANTE_PERIODO SET EPE_ESTADO = 'FINALIZADO' WHERE EPE_PER_ID = v_per_id;
        UPDATE SIS_ACA_PERIODO_ACADEMICO  SET PER_ESTADO = 'CERRADO'    WHERE PER_ID = v_per_id;
    END IF;
END
$$;

-- ---------------------------------------------------------------------
-- Ejecución cronológica
-- ---------------------------------------------------------------------
DO $$
BEGIN
    PERFORM pg_temp.cargar_periodo('2025-1', true);
    PERFORM pg_temp.cargar_periodo('2025-2', true);
    UPDATE SIS_ACA_ANIO_LECTIVO SET ANL_ESTADO = 'CERRADO' WHERE ANL_ANIO = 2025;
    PERFORM pg_temp.cargar_periodo('2026-1', true);
    PERFORM pg_temp.cargar_periodo('2026-2', false);   -- período en curso: queda ABIERTO
END
$$;

DROP FUNCTION pg_temp.cargar_periodo(text, boolean);
DROP FUNCTION pg_temp.nota_registrada(text, text, text);
DROP FUNCTION pg_temp.nota_generada(text, text, text);
DROP TABLE seed_repitencia, seed_nota_fija, seed_ubicacion, seed_perfil;
