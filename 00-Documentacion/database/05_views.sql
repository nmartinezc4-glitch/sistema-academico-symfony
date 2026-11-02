-- =====================================================================
--  05_views.sql
--  Vistas de lectura. Ninguna almacena datos (no hay vistas materializadas).
--
--  Convención de columnas en vistas:
--    · Columnas que vienen de una tabla conservan su nombre original
--      (EST_CODIGO, CUR_NOMBRE, RES_NOTA ...).
--    · Columnas derivadas usan el prefijo de la entidad que describen
--      (RES_ESTADO, RES_NUMERO_INTENTO) o un prefijo propio de la vista:
--        AVA_  métricas de avance curricular
--        ING_  pantalla de ingreso de notas
--
--  Estados derivados (nunca almacenados):
--    RES_NOTA IS NULL                          → PENDIENTE
--    RES_NOTA >= POL_NOTA_APROBACION (período) → APROBADO
--    RES_NOTA <  POL_NOTA_APROBACION (período) → REPROBADO
--
--  Orden de dependencia:
--    POLITICA_LINEA_TIEMPO → POLITICA_VIGENTE
--    RESULTADO_ESTUDIANTE  → INTENTO_CURSO → AVANCE_CICLO → AVANCE_PENSUM
--    RESULTADO_ESTUDIANTE  → REPORTE_NOTAS
--    INGRESO_NOTAS (independiente de las demás vistas)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 22.1a  Línea de tiempo de políticas (vigencia derivada — decisión H2)
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW SIS_ACA_VW_POLITICA_LINEA_TIEMPO AS
SELECT
    p.POL_ID,
    p.POL_CODIGO,
    p.POL_NOMBRE,
    p.POL_NOTA_APROBACION,
    p.POL_VIGENTE_DESDE,
    (LEAD(p.POL_VIGENTE_DESDE) OVER (ORDER BY p.POL_VIGENTE_DESDE) - 1)::date AS POL_VIGENTE_HASTA
FROM SIS_ACA_POLITICA_ACADEMICA p;
COMMENT ON VIEW SIS_ACA_VW_POLITICA_LINEA_TIEMPO IS 'Todas las políticas con su vigencia derivada: POL_VIGENTE_HASTA = día anterior al inicio de la siguiente (NULL = sin fin). Usar en pruebas con fechas literales.';

-- ---------------------------------------------------------------------
-- 22.1b  Política vigente HOY
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW SIS_ACA_VW_POLITICA_VIGENTE AS
SELECT
    t.POL_ID,
    t.POL_CODIGO,
    t.POL_NOMBRE,
    t.POL_NOTA_APROBACION,
    t.POL_VIGENTE_DESDE,
    t.POL_VIGENTE_HASTA
FROM SIS_ACA_VW_POLITICA_LINEA_TIEMPO t
WHERE t.POL_VIGENTE_DESDE <= CURRENT_DATE
  AND (t.POL_VIGENTE_HASTA IS NULL OR t.POL_VIGENTE_HASTA >= CURRENT_DATE);
COMMENT ON VIEW SIS_ACA_VW_POLITICA_VIGENTE IS 'Política vigente a la fecha actual (0 o 1 fila). Ignora políticas futuras e históricas. Depende de CURRENT_DATE: no usar en pruebas reproducibles.';

-- ---------------------------------------------------------------------
-- 22.2  Resultado por estudiante (una fila por intento)
-- ---------------------------------------------------------------------
-- Sin funciones de ventana a propósito: así los filtros (por estudiante,
-- curso, sección, período) se aplican ANTES de calcular, usando índices.
-- El número de intento se obtiene con una subconsulta correlacionada que
-- solo se evalúa para las filas que sobreviven al filtro.
CREATE OR REPLACE VIEW SIS_ACA_VW_RESULTADO_ESTUDIANTE AS
SELECT
    r.RES_ID,
    est.EST_ID,
    est.EST_CODIGO,
    (est.EST_APELLIDOS || ', ' || est.EST_NOMBRES)::varchar(202) AS EST_NOMBRE_COMPLETO,
    epr.EPR_ID,
    car.CAR_ID,
    car.CAR_CODIGO,
    car.CAR_NOMBRE,
    pen.PEN_ID,
    pen.PEN_CODIGO,
    pen.PEN_NOMBRE,
    anl.ANL_ID,
    anl.ANL_ANIO,
    per.PER_ID,
    per.PER_NUMERO,
    per.PER_NOMBRE,
    per.PER_FECHA_INICIO,
    per.PER_ESTADO,
    epe.EPE_ID,
    epe.EPE_CIC_ID,
    cic.CIC_ID,
    cic.CIC_ANIO,
    cic.CIC_SEMESTRE,
    cic.CIC_NOMBRE,
    pcu.PCU_ID,
    pcu.PCU_OBLIGATORIO,
    cur.CUR_ID,
    cur.CUR_CODIGO,
    cur.CUR_NOMBRE,
    sec.SEC_ID,
    sec.SEC_CODIGO,
    ofe.OFE_ID,
    r.RES_NOTA,
    r.RES_CALIFICADO_EN,
    pol.POL_ID,
    pol.POL_CODIGO,
    pol.POL_NOTA_APROBACION,
    (CASE
        WHEN r.RES_NOTA IS NULL                    THEN 'PENDIENTE'
        WHEN r.RES_NOTA >= pol.POL_NOTA_APROBACION THEN 'APROBADO'
        ELSE                                            'REPROBADO'
     END)::varchar(20) AS RES_ESTADO,
    (SELECT count(*)
     FROM SIS_ACA_RESULTADO_CURSO    r2
     JOIN SIS_ACA_ESTUDIANTE_PERIODO e2 ON e2.EPE_ID = r2.RES_EPE_ID
     JOIN SIS_ACA_OFERTA_CURSO       o2 ON o2.OFE_ID = r2.RES_OFE_ID
     JOIN SIS_ACA_PERIODO_ACADEMICO  p2 ON p2.PER_ID = e2.EPE_PER_ID
     WHERE e2.EPE_EPR_ID = epe.EPE_EPR_ID
       AND o2.OFE_PCU_ID = ofe.OFE_PCU_ID
       AND (p2.PER_FECHA_INICIO, r2.RES_ID) <= (per.PER_FECHA_INICIO, r.RES_ID)
    )::integer AS RES_NUMERO_INTENTO
FROM SIS_ACA_RESULTADO_CURSO      r
JOIN SIS_ACA_ESTUDIANTE_PERIODO   epe ON epe.EPE_ID = r.RES_EPE_ID
JOIN SIS_ACA_ESTUDIANTE_PROGRAMA  epr ON epr.EPR_ID = epe.EPE_EPR_ID
JOIN SIS_ACA_ESTUDIANTE           est ON est.EST_ID = epr.EPR_EST_ID
JOIN SIS_ACA_PENSUM               pen ON pen.PEN_ID = epr.EPR_PEN_ID
JOIN SIS_ACA_CARRERA              car ON car.CAR_ID = pen.PEN_CAR_ID
JOIN SIS_ACA_PERIODO_ACADEMICO    per ON per.PER_ID = epe.EPE_PER_ID
JOIN SIS_ACA_ANIO_LECTIVO         anl ON anl.ANL_ID = per.PER_ANL_ID
JOIN SIS_ACA_POLITICA_ACADEMICA   pol ON pol.POL_ID = per.PER_POL_ID
JOIN SIS_ACA_OFERTA_CURSO         ofe ON ofe.OFE_ID = r.RES_OFE_ID
JOIN SIS_ACA_PENSUM_CURSO         pcu ON pcu.PCU_ID = ofe.OFE_PCU_ID
JOIN SIS_ACA_CURSO                cur ON cur.CUR_ID = pcu.PCU_CUR_ID
JOIN SIS_ACA_CICLO_CURRICULAR     cic ON cic.CIC_ID = pcu.PCU_CIC_ID
JOIN SIS_ACA_SECCION              sec ON sec.SEC_ID = ofe.OFE_SEC_ID;
COMMENT ON VIEW SIS_ACA_VW_RESULTADO_ESTUDIANTE IS 'Una fila por intento (RES_ID). Estado derivado con la política DEL PERÍODO cursado, nunca con la vigente hoy. CIC_* = ciclo del curso; EPE_CIC_ID = ciclo del estudiante en ese período.';

-- ---------------------------------------------------------------------
-- Auxiliar 16  Resumen de intentos por estudiante-programa y curso
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW SIS_ACA_VW_INTENTO_CURSO AS
SELECT
    v.EPR_ID,
    v.EST_ID,
    v.EST_CODIGO,
    v.EST_NOMBRE_COMPLETO,
    v.PEN_ID,
    v.PCU_ID,
    v.PCU_OBLIGATORIO,
    v.CIC_ID,
    v.CUR_ID,
    v.CUR_CODIGO,
    v.CUR_NOMBRE,
    count(*)::integer                                       AS RES_TOTAL_INTENTOS,
    count(v.RES_NOTA)::integer                              AS RES_INTENTOS_CALIFICADOS,
    (array_agg(v.RES_NOTA ORDER BY v.PER_FECHA_INICIO, v.RES_ID)
        FILTER (WHERE v.RES_NOTA IS NOT NULL))[1]           AS RES_PRIMERA_NOTA,
    (array_agg(v.RES_NOTA ORDER BY v.PER_FECHA_INICIO DESC, v.RES_ID DESC)
        FILTER (WHERE v.RES_NOTA IS NOT NULL))[1]           AS RES_ULTIMA_NOTA,
    max(v.RES_NOTA)                                         AS RES_MEJOR_NOTA,
    COALESCE(bool_or(v.RES_ESTADO = 'APROBADO'), false)     AS RES_APROBADO,
    (array_agg(v.PER_ID ORDER BY v.PER_FECHA_INICIO, v.RES_ID)
        FILTER (WHERE v.RES_ESTADO = 'APROBADO'))[1]        AS PER_ID_APROBACION,
    (array_agg(v.ANL_ANIO || ' / ' || v.PER_NOMBRE ORDER BY v.PER_FECHA_INICIO, v.RES_ID)
        FILTER (WHERE v.RES_ESTADO = 'APROBADO'))[1]::varchar(120) AS PER_NOMBRE_APROBACION,
    (CASE
        WHEN bool_or(v.RES_ESTADO = 'APROBADO')  THEN 'APROBADO'
        WHEN bool_or(v.RES_ESTADO = 'PENDIENTE') THEN 'EN_CURSO'
        ELSE                                          'REPROBADO'
     END)::varchar(20)                                      AS RES_SITUACION
FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE v
GROUP BY v.EPR_ID, v.EST_ID, v.EST_CODIGO, v.EST_NOMBRE_COMPLETO, v.PEN_ID,
         v.PCU_ID, v.PCU_OBLIGATORIO, v.CIC_ID, v.CUR_ID, v.CUR_CODIGO, v.CUR_NOMBRE;
COMMENT ON VIEW SIS_ACA_VW_INTENTO_CURSO IS 'Una fila por (EPR_ID, PCU_ID): número de intentos, primera/última/mejor nota y período de aprobación. Un curso está aprobado si existe al menos un intento APROBADO.';

-- ---------------------------------------------------------------------
-- 22.4  Avance por ciclo curricular
-- ---------------------------------------------------------------------
-- Base = TODOS los cursos del pensum (no solo los cursados), unidos con
-- LEFT JOIN al resumen de intentos. Como VW_INTENTO_CURSO tiene una fila
-- por (EPR_ID, PCU_ID), el JOIN no multiplica filas: un curso repetido
-- cuenta UNA sola vez.
CREATE OR REPLACE VIEW SIS_ACA_VW_AVANCE_CICLO AS
SELECT
    epr.EPR_ID,
    est.EST_ID,
    est.EST_CODIGO,
    (est.EST_APELLIDOS || ', ' || est.EST_NOMBRES)::varchar(202) AS EST_NOMBRE_COMPLETO,
    car.CAR_ID,
    car.CAR_NOMBRE,
    pen.PEN_ID,
    pen.PEN_NOMBRE,
    cic.CIC_ID,
    cic.CIC_ANIO,
    cic.CIC_SEMESTRE,
    cic.CIC_NOMBRE,
    count(*)::integer                                                           AS AVA_CURSOS_TOTALES,
    count(*) FILTER (WHERE pcu.PCU_OBLIGATORIO)::integer                        AS AVA_CURSOS_OBLIGATORIOS,
    count(*) FILTER (WHERE pcu.PCU_OBLIGATORIO AND i.RES_APROBADO)::integer     AS AVA_CURSOS_APROBADOS,
    (count(*) FILTER (WHERE pcu.PCU_OBLIGATORIO)
     - count(*) FILTER (WHERE pcu.PCU_OBLIGATORIO AND i.RES_APROBADO))::integer AS AVA_CURSOS_PENDIENTES,
    COALESCE(round(100.0 * count(*) FILTER (WHERE pcu.PCU_OBLIGATORIO AND i.RES_APROBADO)
                   / NULLIF(count(*) FILTER (WHERE pcu.PCU_OBLIGATORIO), 0), 2), 0)::numeric(5,2) AS AVA_PORCENTAJE,
    (CASE
        WHEN count(*) FILTER (WHERE pcu.PCU_OBLIGATORIO) = 0 THEN 'SIN_OBLIGATORIOS'
        WHEN count(*) FILTER (WHERE pcu.PCU_OBLIGATORIO AND i.RES_APROBADO)
           = count(*) FILTER (WHERE pcu.PCU_OBLIGATORIO)     THEN 'COMPLETO'
        ELSE                                                      'INCOMPLETO'
     END)::varchar(20)                                                          AS AVA_ESTADO_CICLO
FROM SIS_ACA_ESTUDIANTE_PROGRAMA  epr
JOIN SIS_ACA_ESTUDIANTE           est ON est.EST_ID = epr.EPR_EST_ID
JOIN SIS_ACA_PENSUM               pen ON pen.PEN_ID = epr.EPR_PEN_ID
JOIN SIS_ACA_CARRERA              car ON car.CAR_ID = pen.PEN_CAR_ID
JOIN SIS_ACA_PENSUM_CURSO         pcu ON pcu.PCU_PEN_ID = epr.EPR_PEN_ID
JOIN SIS_ACA_CICLO_CURRICULAR     cic ON cic.CIC_ID = pcu.PCU_CIC_ID
LEFT JOIN SIS_ACA_VW_INTENTO_CURSO i  ON i.EPR_ID = epr.EPR_ID AND i.PCU_ID = pcu.PCU_ID
GROUP BY epr.EPR_ID, est.EST_ID, est.EST_CODIGO, est.EST_APELLIDOS, est.EST_NOMBRES,
         car.CAR_ID, car.CAR_NOMBRE, pen.PEN_ID, pen.PEN_NOMBRE,
         cic.CIC_ID, cic.CIC_ANIO, cic.CIC_SEMESTRE, cic.CIC_NOMBRE;
COMMENT ON VIEW SIS_ACA_VW_AVANCE_CICLO IS 'Avance por (EPR_ID, CIC_ID). Solo cursos obligatorios cuentan para el porcentaje. COMPLETO = todos los obligatorios del ciclo aprobados.';

-- ---------------------------------------------------------------------
-- 22.3  Avance global del pensum
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW SIS_ACA_VW_AVANCE_PENSUM AS
SELECT
    a.EPR_ID,
    epr.EPR_ESTADO,
    a.EST_ID,
    a.EST_CODIGO,
    a.EST_NOMBRE_COMPLETO,
    a.CAR_ID,
    a.CAR_NOMBRE,
    a.PEN_ID,
    a.PEN_NOMBRE,
    sum(a.AVA_CURSOS_TOTALES)::integer      AS AVA_CURSOS_TOTALES,
    sum(a.AVA_CURSOS_OBLIGATORIOS)::integer AS AVA_CURSOS_OBLIGATORIOS,
    sum(a.AVA_CURSOS_APROBADOS)::integer    AS AVA_CURSOS_APROBADOS,
    sum(a.AVA_CURSOS_PENDIENTES)::integer   AS AVA_CURSOS_PENDIENTES,
    COALESCE(round(100.0 * sum(a.AVA_CURSOS_APROBADOS)
                   / NULLIF(sum(a.AVA_CURSOS_OBLIGATORIOS), 0), 2), 0)::numeric(5,2) AS AVA_PORCENTAJE,
    (sum(a.AVA_CURSOS_OBLIGATORIOS) > 0
     AND sum(a.AVA_CURSOS_PENDIENTES) = 0)  AS AVA_PENSUM_COMPLETO
FROM SIS_ACA_VW_AVANCE_CICLO      a
JOIN SIS_ACA_ESTUDIANTE_PROGRAMA  epr ON epr.EPR_ID = a.EPR_ID
GROUP BY a.EPR_ID, epr.EPR_ESTADO, a.EST_ID, a.EST_CODIGO, a.EST_NOMBRE_COMPLETO,
         a.CAR_ID, a.CAR_NOMBRE, a.PEN_ID, a.PEN_NOMBRE;
COMMENT ON VIEW SIS_ACA_VW_AVANCE_PENSUM IS 'Avance global por programa (EPR_ID). Grano = programa, no estudiante: un estudiante con varios pensums en su historia tiene una fila por programa.';

-- ---------------------------------------------------------------------
-- 22.5  Base para reportes de notas (carrera / curso / sección / período)
-- ---------------------------------------------------------------------
-- Contrato estable para el repositorio de reportes de Symfony: claves de
-- filtro primero, sin columnas internas.
CREATE OR REPLACE VIEW SIS_ACA_VW_REPORTE_NOTAS AS
SELECT
    v.RES_ID,
    v.CAR_ID,  v.CAR_CODIGO, v.CAR_NOMBRE,
    v.PEN_ID,  v.PEN_CODIGO,
    v.CUR_ID,  v.CUR_CODIGO, v.CUR_NOMBRE,
    v.SEC_ID,  v.SEC_CODIGO,
    v.ANL_ID,  v.ANL_ANIO,
    v.PER_ID,  v.PER_NOMBRE, v.PER_FECHA_INICIO,
    v.CIC_ID,  v.CIC_NOMBRE,
    v.EST_ID,  v.EST_CODIGO, v.EST_NOMBRE_COMPLETO,
    v.RES_NOTA,
    v.POL_CODIGO,
    v.POL_NOTA_APROBACION,
    v.RES_ESTADO,
    v.RES_NUMERO_INTENTO
FROM SIS_ACA_VW_RESULTADO_ESTUDIANTE v;
COMMENT ON VIEW SIS_ACA_VW_REPORTE_NOTAS IS 'Base de reportes de notas filtrable por carrera, curso, sección y período (cualquier combinación). Incluye pendientes (RES_NOTA NULL).';

-- ---------------------------------------------------------------------
-- 22.6  Pantalla de ingreso de notas (por estudiante-período)
-- ---------------------------------------------------------------------
-- Tres orígenes, mutuamente excluyentes, unidos con UNION ALL:
--
--   A) CICLO_ACTUAL   → todos los cursos del pensum del ciclo que cursa el
--                       estudiante en el período, EXISTA O NO oferta o
--                       resultado (LEFT JOIN).
--   B) Registrados    → resultados YA registrados en el período para cursos
--                       de otro ciclo: CICLO_ANTERIOR (repitencia/arrastre)
--                       u OTRO_CICLO (ciclo posterior).
--   C) Descubiertos   → cursos de ciclos ANTERIORES del mismo pensum que
--                       aún no tienen intento en este período, siempre que:
--                         · no estén aprobados en un período previo,
--                         · exista oferta ACTIVA en el período y sección
--                           del estudiante.
--                       Permiten crear el nuevo intento desde la pantalla.
--
-- B y C no se solapan: B exige resultado en el período, C exige que no
-- exista. Por eso la clave (EPE_ID, PCU_ID) es única (entidad readOnly
-- en Doctrine).
--
-- ING_EDITABLE / ING_MOTIVO_BLOQUEO replican las reglas de T2 para que
-- Symfony deshabilite la captura ANTES de que la BD la rechace. Prioridad:
--   PERIODO_NO_ABIERTO → ESTUDIANTE_NO_INSCRITO → SIN_OFERTA →
--   OFERTA_INACTIVA → YA_APROBADO (solo si aún no hay intento en el período).
-- Correspondencia con T2: SA204, SA205, (sin oferta), SA206, SA207.
CREATE OR REPLACE VIEW SIS_ACA_VW_INGRESO_NOTAS AS
SELECT
    u.EPE_ID,
    u.PCU_ID,
    est.EST_ID,
    est.EST_CODIGO,
    (est.EST_APELLIDOS || ', ' || est.EST_NOMBRES)::varchar(202) AS EST_NOMBRE_COMPLETO,
    u.EPR_ID,
    u.EPE_ESTADO,
    per.PER_ID,
    anl.ANL_ANIO,
    per.PER_NOMBRE,
    per.PER_ESTADO,
    u.EPE_CIC_ID,
    sec.SEC_ID,
    sec.SEC_CODIGO,
    cur.CUR_ID,
    cur.CUR_CODIGO,
    cur.CUR_NOMBRE,
    pcu.PCU_CIC_ID,
    cic.CIC_NOMBRE AS PCU_CIC_NOMBRE,
    pcu.PCU_OBLIGATORIO,
    pcu.PCU_ORDEN,
    u.OFE_ID,
    ofe.OFE_ACTIVO,
    r.RES_ID,
    r.RES_NOTA,
    pol.POL_NOTA_APROBACION,
    u.ING_ORIGEN,
    (CASE
        WHEN u.OFE_ID IS NULL                      THEN 'SIN_OFERTA'
        WHEN r.RES_ID IS NULL                      THEN 'SIN_REGISTRO'
        WHEN r.RES_NOTA IS NULL                    THEN 'PENDIENTE'
        WHEN r.RES_NOTA >= pol.POL_NOTA_APROBACION THEN 'APROBADO'
        ELSE                                            'REPROBADO'
     END)::varchar(20) AS ING_ESTADO,
    ap.aprobado_previo AS ING_APROBADO_PREVIAMENTE,
    (CASE
        WHEN per.PER_ESTADO <> 'ABIERTO'          THEN 'PERIODO_NO_ABIERTO'
        WHEN u.EPE_ESTADO <> 'INSCRITO'           THEN 'ESTUDIANTE_NO_INSCRITO'
        WHEN u.OFE_ID IS NULL                     THEN 'SIN_OFERTA'
        WHEN NOT ofe.OFE_ACTIVO                   THEN 'OFERTA_INACTIVA'
        WHEN r.RES_ID IS NULL AND ap.aprobado_previo THEN 'YA_APROBADO'
     END)::varchar(30) AS ING_MOTIVO_BLOQUEO,
    (per.PER_ESTADO = 'ABIERTO'
     AND u.EPE_ESTADO = 'INSCRITO'
     AND u.OFE_ID IS NOT NULL
     AND ofe.OFE_ACTIVO
     AND NOT (r.RES_ID IS NULL AND ap.aprobado_previo)) AS ING_EDITABLE
FROM (
    -- A) CICLO_ACTUAL: lo que el estudiante DEBE cursar en su ciclo
    SELECT e.EPE_ID, e.EPE_EPR_ID AS EPR_ID, e.EPE_PER_ID, e.EPE_CIC_ID, e.EPE_SEC_ID, e.EPE_ESTADO,
           c.PCU_ID, o.OFE_ID, 'CICLO_ACTUAL'::varchar(20) AS ING_ORIGEN
    FROM SIS_ACA_ESTUDIANTE_PERIODO  e
    JOIN SIS_ACA_ESTUDIANTE_PROGRAMA p ON p.EPR_ID = e.EPE_EPR_ID
    JOIN SIS_ACA_PENSUM_CURSO        c ON c.PCU_PEN_ID = p.EPR_PEN_ID
                                      AND c.PCU_CIC_ID = e.EPE_CIC_ID
    LEFT JOIN SIS_ACA_OFERTA_CURSO   o ON o.OFE_PER_ID = e.EPE_PER_ID
                                      AND o.OFE_PCU_ID = c.PCU_ID
                                      AND o.OFE_SEC_ID = e.EPE_SEC_ID
    UNION ALL
    -- B) Registrados en el período para cursos de otro ciclo
    SELECT e.EPE_ID, e.EPE_EPR_ID, e.EPE_PER_ID, e.EPE_CIC_ID, e.EPE_SEC_ID, e.EPE_ESTADO,
           c.PCU_ID, o.OFE_ID,
           (CASE WHEN (cc.CIC_ANIO, cc.CIC_SEMESTRE) < (ce.CIC_ANIO, ce.CIC_SEMESTRE)
                 THEN 'CICLO_ANTERIOR' ELSE 'OTRO_CICLO' END)::varchar(20)
    FROM SIS_ACA_ESTUDIANTE_PERIODO  e
    JOIN SIS_ACA_RESULTADO_CURSO     rr ON rr.RES_EPE_ID = e.EPE_ID
    JOIN SIS_ACA_OFERTA_CURSO        o  ON o.OFE_ID = rr.RES_OFE_ID
    JOIN SIS_ACA_PENSUM_CURSO        c  ON c.PCU_ID = o.OFE_PCU_ID
    JOIN SIS_ACA_CICLO_CURRICULAR    ce ON ce.CIC_ID = e.EPE_CIC_ID
    JOIN SIS_ACA_CICLO_CURRICULAR    cc ON cc.CIC_ID = c.PCU_CIC_ID
    WHERE c.PCU_CIC_ID <> e.EPE_CIC_ID
    UNION ALL
    -- C) Descubiertos: ciclos anteriores, no aprobados, oferta activa, sin intento aún
    SELECT e.EPE_ID, e.EPE_EPR_ID, e.EPE_PER_ID, e.EPE_CIC_ID, e.EPE_SEC_ID, e.EPE_ESTADO,
           c.PCU_ID, o.OFE_ID, 'CICLO_ANTERIOR'::varchar(20)
    FROM SIS_ACA_ESTUDIANTE_PERIODO  e
    JOIN SIS_ACA_ESTUDIANTE_PROGRAMA p  ON p.EPR_ID = e.EPE_EPR_ID
    JOIN SIS_ACA_PERIODO_ACADEMICO   pe ON pe.PER_ID = e.EPE_PER_ID
    JOIN SIS_ACA_CICLO_CURRICULAR    ce ON ce.CIC_ID = e.EPE_CIC_ID
    JOIN SIS_ACA_PENSUM_CURSO        c  ON c.PCU_PEN_ID = p.EPR_PEN_ID
    JOIN SIS_ACA_CICLO_CURRICULAR    cc ON cc.CIC_ID = c.PCU_CIC_ID
                                       AND (cc.CIC_ANIO, cc.CIC_SEMESTRE) < (ce.CIC_ANIO, ce.CIC_SEMESTRE)
    JOIN SIS_ACA_OFERTA_CURSO        o  ON o.OFE_PER_ID = e.EPE_PER_ID
                                       AND o.OFE_PCU_ID = c.PCU_ID
                                       AND o.OFE_SEC_ID = e.EPE_SEC_ID
                                       AND o.OFE_ACTIVO
    WHERE NOT EXISTS (SELECT 1 FROM SIS_ACA_RESULTADO_CURSO r0
                      WHERE r0.RES_EPE_ID = e.EPE_ID AND r0.RES_OFE_ID = o.OFE_ID)
      AND NOT EXISTS (SELECT 1
                      FROM SIS_ACA_RESULTADO_CURSO    r2
                      JOIN SIS_ACA_ESTUDIANTE_PERIODO e2 ON e2.EPE_ID = r2.RES_EPE_ID
                      JOIN SIS_ACA_OFERTA_CURSO       o2 ON o2.OFE_ID = r2.RES_OFE_ID
                      JOIN SIS_ACA_PERIODO_ACADEMICO  p2 ON p2.PER_ID = e2.EPE_PER_ID
                      JOIN SIS_ACA_POLITICA_ACADEMICA x2 ON x2.POL_ID = p2.PER_POL_ID
                      WHERE e2.EPE_EPR_ID = e.EPE_EPR_ID
                        AND o2.OFE_PCU_ID = c.PCU_ID
                        AND p2.PER_FECHA_INICIO < pe.PER_FECHA_INICIO
                        AND r2.RES_NOTA >= x2.POL_NOTA_APROBACION)
) u
JOIN SIS_ACA_ESTUDIANTE_PROGRAMA  epr ON epr.EPR_ID = u.EPR_ID
JOIN SIS_ACA_ESTUDIANTE           est ON est.EST_ID = epr.EPR_EST_ID
JOIN SIS_ACA_PERIODO_ACADEMICO    per ON per.PER_ID = u.EPE_PER_ID
JOIN SIS_ACA_ANIO_LECTIVO         anl ON anl.ANL_ID = per.PER_ANL_ID
JOIN SIS_ACA_POLITICA_ACADEMICA   pol ON pol.POL_ID = per.PER_POL_ID
JOIN SIS_ACA_SECCION              sec ON sec.SEC_ID = u.EPE_SEC_ID
JOIN SIS_ACA_PENSUM_CURSO         pcu ON pcu.PCU_ID = u.PCU_ID
JOIN SIS_ACA_CURSO                cur ON cur.CUR_ID = pcu.PCU_CUR_ID
JOIN SIS_ACA_CICLO_CURRICULAR     cic ON cic.CIC_ID = pcu.PCU_CIC_ID
LEFT JOIN SIS_ACA_OFERTA_CURSO    ofe ON ofe.OFE_ID = u.OFE_ID
LEFT JOIN SIS_ACA_RESULTADO_CURSO r   ON r.RES_EPE_ID = u.EPE_ID AND r.RES_OFE_ID = u.OFE_ID
CROSS JOIN LATERAL (
    SELECT EXISTS (
        SELECT 1
        FROM SIS_ACA_RESULTADO_CURSO    r2
        JOIN SIS_ACA_ESTUDIANTE_PERIODO e2 ON e2.EPE_ID = r2.RES_EPE_ID
        JOIN SIS_ACA_OFERTA_CURSO       o2 ON o2.OFE_ID = r2.RES_OFE_ID
        JOIN SIS_ACA_PERIODO_ACADEMICO  p2 ON p2.PER_ID = e2.EPE_PER_ID
        JOIN SIS_ACA_POLITICA_ACADEMICA x2 ON x2.POL_ID = p2.PER_POL_ID
        WHERE e2.EPE_EPR_ID = u.EPR_ID
          AND o2.OFE_PCU_ID = u.PCU_ID
          AND p2.PER_FECHA_INICIO < per.PER_FECHA_INICIO
          AND r2.RES_NOTA >= x2.POL_NOTA_APROBACION
    ) AS aprobado_previo
) ap;
COMMENT ON VIEW SIS_ACA_VW_INGRESO_NOTAS IS 'Cursos esperados por estudiante-período para el formulario de notas: ciclo actual, repitencias registradas y cursos de ciclos anteriores pendientes con oferta activa. ING_EDITABLE/ING_MOTIVO_BLOQUEO anticipan las reglas de T2. Clave: (EPE_ID, PCU_ID).';
