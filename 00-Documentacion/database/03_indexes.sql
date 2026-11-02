-- =====================================================================
--  03_indexes.sql
--  Índices de soporte. Cada índice responde a una consulta concreta.
--
--  PostgreSQL crea índices automáticamente SOLO para PRIMARY KEY y
--  UNIQUE, NO para FOREIGN KEY. Antes de crear uno se verificó si una
--  UNIQUE compuesta ya lo cubre por su columna líder:
--
--  FK ya cubiertas (no requieren índice adicional):
--    PER_ANL_ID  → UQ_PER_ANL_NUMERO      (PER_ANL_ID, PER_NUMERO)
--    PEN_CAR_ID  → UQ_PEN_CAR_VERSION     (PEN_CAR_ID, PEN_VERSION)
--    PCU_PEN_ID  → UQ_PCU_PEN_CUR / UQ_PCU_PEN_CIC_ORDEN
--    EPR_EST_ID  → UQ_EPR_EST_PEN_INICIO  (EPR_EST_ID, ...)
--    EPE_EPR_ID  → UQ_EPE_EPR_PER         (EPE_EPR_ID, EPE_PER_ID)
--    OFE_PER_ID  → UQ_OFE_PER_PCU_SEC     (OFE_PER_ID, OFE_PCU_ID, OFE_SEC_ID)
--    RES_EPE_ID  → UQ_RES_EPE_OFE         (RES_EPE_ID, RES_OFE_ID)
--
--  FK sin índice a propósito:
--    PCU_CIC_ID, EPE_CIC_ID → catálogo de ~4 filas; ninguna consulta parte
--      del ciclo hacia los hijos sin filtrar antes por pensum/estudiante.
--    OFE_SEC_ID, EPE_SEC_ID (solo) → 3 secciones = selectividad ~33 %;
--      un índice no supera a un recorrido secuencial. El reporte por
--      sección se resuelve filtrando primero por período/curso.
--    Borrados en catálogos pequeños (CIC, SEC) → poco frecuentes; el
--      recorrido secuencial de verificación de la FK es aceptable.
-- =====================================================================

-- Consulta: T3 "¿la política ya fue usada por algún período?" y
--           resultados históricos por política (Q24).
CREATE INDEX IX_PER_POL ON SIS_ACA_PERIODO_ACADEMICO (PER_POL_ID);

-- Consulta: resultados por curso (Q06, Q10, Q12) parten de CUR → PCU.
CREATE INDEX IX_PCU_CUR ON SIS_ACA_PENSUM_CURSO (PCU_CUR_ID);

-- Consulta: alumnos por carrera (Q01) y avance de pensum: CAR → PEN → EPR.
CREATE INDEX IX_EPR_PEN ON SIS_ACA_ESTUDIANTE_PROGRAMA (EPR_PEN_ID);

-- Consulta: alumnos de un período (y sección) — listados de clase,
--           comparación entre períodos (Q23), T3 "¿el período tiene resultados?".
CREATE INDEX IX_EPE_PER_SEC ON SIS_ACA_ESTUDIANTE_PERIODO (EPE_PER_ID, EPE_SEC_ID);

-- Consulta: intentos de un curso del pensum (Q16, Q17, VW_INTENTO_CURSO)
--           y T4 "¿el curso del pensum tiene resultados?" (PCU → OFE).
CREATE INDEX IX_OFE_PCU ON SIS_ACA_OFERTA_CURSO (OFE_PCU_ID);

-- Consulta: resultados por oferta (notas por curso + sección + período,
--           Q06–Q08) y T4 "¿la oferta tiene resultados?".
CREATE INDEX IX_RES_OFE ON SIS_ACA_RESULTADO_CURSO (RES_OFE_ID);

-- Consulta: búsqueda de alumno por apellido para ingresar notas (PDF:
--           "buscar el alumno para luego ingresar las notas").
--           lower() + varchar_pattern_ops permite LIKE 'garc%' sin
--           depender de la collation de la base.
CREATE INDEX IX_EST_BUSQUEDA_APELLIDOS
    ON SIS_ACA_ESTUDIANTE (lower(EST_APELLIDOS) varchar_pattern_ops, lower(EST_NOMBRES) varchar_pattern_ops);

-- Búsqueda por código (Q02): cubierta por UQ_EST_CODIGO.
-- Política vigente por fecha: cubierta por UQ_POL_VIGENTE_DESDE.
