-- =====================================================================
--  02_constraints.sql
--  UNIQUE · CHECK · FOREIGN KEY (todas con nombre explícito)
--
--  Nomenclatura de constraints:
--    UQ_<PREFIJO>_<COLUMNAS>   UNIQUE
--    UX_<PREFIJO>_<REGLA>      índice UNIQUE parcial (no expresable como constraint)
--    CK_<PREFIJO>_<REGLA>      CHECK
--    FK_<PREFIJO>_<PREFIJO_REF> FOREIGN KEY
--
--  Política de borrado: TODAS las FK usan ON DELETE RESTRICT / ON UPDATE
--  RESTRICT. No existe ningún ON DELETE CASCADE: toda la información es
--  histórica. Los catálogos se retiran con <PREFIJO>_ACTIVO = FALSE.
--
--  Reglas sin regex de formato (decisión E1): solo UNIQUE y "no vacío".
-- =====================================================================

-- ---------------------------------------------------------------------
-- POL · Política académica
-- ---------------------------------------------------------------------
ALTER TABLE SIS_ACA_POLITICA_ACADEMICA
    ADD CONSTRAINT UQ_POL_CODIGO          UNIQUE (POL_CODIGO),
    ADD CONSTRAINT UQ_POL_VIGENTE_DESDE   UNIQUE (POL_VIGENTE_DESDE),
    ADD CONSTRAINT CK_POL_CODIGO_NO_VACIO CHECK (btrim(POL_CODIGO) <> ''),
    ADD CONSTRAINT CK_POL_NOMBRE_NO_VACIO CHECK (btrim(POL_NOMBRE) <> ''),
    ADD CONSTRAINT CK_POL_NOTA_APROBACION CHECK (POL_NOTA_APROBACION BETWEEN 0 AND 100);

-- ---------------------------------------------------------------------
-- ANL · Año lectivo
-- ---------------------------------------------------------------------
ALTER TABLE SIS_ACA_ANIO_LECTIVO
    ADD CONSTRAINT UQ_ANL_ANIO            UNIQUE (ANL_ANIO),
    ADD CONSTRAINT CK_ANL_ANIO_POSITIVO   CHECK (ANL_ANIO > 0),
    ADD CONSTRAINT CK_ANL_NOMBRE_NO_VACIO CHECK (btrim(ANL_NOMBRE) <> ''),
    ADD CONSTRAINT CK_ANL_FECHAS          CHECK (ANL_FECHA_INICIO <= ANL_FECHA_FIN),
    ADD CONSTRAINT CK_ANL_ESTADO          CHECK (ANL_ESTADO IN ('PLANIFICADO', 'ABIERTO', 'CERRADO'));

-- ---------------------------------------------------------------------
-- PER · Período académico
-- ---------------------------------------------------------------------
ALTER TABLE SIS_ACA_PERIODO_ACADEMICO
    ADD CONSTRAINT UQ_PER_ANL_NUMERO      UNIQUE (PER_ANL_ID, PER_NUMERO),
    ADD CONSTRAINT CK_PER_NUMERO_POSITIVO CHECK (PER_NUMERO > 0),
    ADD CONSTRAINT CK_PER_NOMBRE_NO_VACIO CHECK (btrim(PER_NOMBRE) <> ''),
    ADD CONSTRAINT CK_PER_FECHAS          CHECK (PER_FECHA_INICIO <= PER_FECHA_FIN),
    ADD CONSTRAINT CK_PER_ESTADO          CHECK (PER_ESTADO IN ('PLANIFICADO', 'ABIERTO', 'CERRADO')),
    ADD CONSTRAINT FK_PER_ANL FOREIGN KEY (PER_ANL_ID)
        REFERENCES SIS_ACA_ANIO_LECTIVO (ANL_ID)        ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT FK_PER_POL FOREIGN KEY (PER_POL_ID)
        REFERENCES SIS_ACA_POLITICA_ACADEMICA (POL_ID)  ON DELETE RESTRICT ON UPDATE RESTRICT;

-- ---------------------------------------------------------------------
-- CAR · Carrera
-- ---------------------------------------------------------------------
ALTER TABLE SIS_ACA_CARRERA
    ADD CONSTRAINT UQ_CAR_CODIGO          UNIQUE (CAR_CODIGO),
    ADD CONSTRAINT UQ_CAR_NOMBRE          UNIQUE (CAR_NOMBRE),
    ADD CONSTRAINT CK_CAR_CODIGO_NO_VACIO CHECK (btrim(CAR_CODIGO) <> ''),
    ADD CONSTRAINT CK_CAR_NOMBRE_NO_VACIO CHECK (btrim(CAR_NOMBRE) <> '');

-- ---------------------------------------------------------------------
-- PEN · Pensum
-- ---------------------------------------------------------------------
ALTER TABLE SIS_ACA_PENSUM
    ADD CONSTRAINT UQ_PEN_CODIGO          UNIQUE (PEN_CODIGO),
    ADD CONSTRAINT UQ_PEN_CAR_VERSION     UNIQUE (PEN_CAR_ID, PEN_VERSION),
    ADD CONSTRAINT CK_PEN_CODIGO_NO_VACIO CHECK (btrim(PEN_CODIGO) <> ''),
    ADD CONSTRAINT CK_PEN_NOMBRE_NO_VACIO CHECK (btrim(PEN_NOMBRE) <> ''),
    ADD CONSTRAINT CK_PEN_VERSION_POSITIVA CHECK (PEN_VERSION > 0),
    ADD CONSTRAINT CK_PEN_VIGENCIA        CHECK (PEN_VIGENTE_HASTA IS NULL OR PEN_VIGENTE_HASTA >= PEN_VIGENTE_DESDE),
    ADD CONSTRAINT FK_PEN_CAR FOREIGN KEY (PEN_CAR_ID)
        REFERENCES SIS_ACA_CARRERA (CAR_ID)             ON DELETE RESTRICT ON UPDATE RESTRICT;

-- ---------------------------------------------------------------------
-- CIC · Ciclo curricular
-- ---------------------------------------------------------------------
ALTER TABLE SIS_ACA_CICLO_CURRICULAR
    ADD CONSTRAINT UQ_CIC_ANIO_SEMESTRE   UNIQUE (CIC_ANIO, CIC_SEMESTRE),
    ADD CONSTRAINT UQ_CIC_NOMBRE          UNIQUE (CIC_NOMBRE),
    ADD CONSTRAINT CK_CIC_ANIO_POSITIVO   CHECK (CIC_ANIO > 0),
    ADD CONSTRAINT CK_CIC_SEMESTRE_POSITIVO CHECK (CIC_SEMESTRE > 0),
    ADD CONSTRAINT CK_CIC_NOMBRE_NO_VACIO CHECK (btrim(CIC_NOMBRE) <> '');

-- ---------------------------------------------------------------------
-- CUR · Curso
-- ---------------------------------------------------------------------
ALTER TABLE SIS_ACA_CURSO
    ADD CONSTRAINT UQ_CUR_CODIGO          UNIQUE (CUR_CODIGO),
    ADD CONSTRAINT CK_CUR_CODIGO_NO_VACIO CHECK (btrim(CUR_CODIGO) <> ''),
    ADD CONSTRAINT CK_CUR_NOMBRE_NO_VACIO CHECK (btrim(CUR_NOMBRE) <> '');

-- ---------------------------------------------------------------------
-- PCU · Pensum ↔ Curso ↔ Ciclo
-- ---------------------------------------------------------------------
ALTER TABLE SIS_ACA_PENSUM_CURSO
    ADD CONSTRAINT UQ_PCU_PEN_CUR         UNIQUE (PCU_PEN_ID, PCU_CUR_ID),
    ADD CONSTRAINT UQ_PCU_PEN_CIC_ORDEN   UNIQUE (PCU_PEN_ID, PCU_CIC_ID, PCU_ORDEN),
    ADD CONSTRAINT CK_PCU_ORDEN_POSITIVO  CHECK (PCU_ORDEN > 0),
    ADD CONSTRAINT FK_PCU_PEN FOREIGN KEY (PCU_PEN_ID)
        REFERENCES SIS_ACA_PENSUM (PEN_ID)              ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT FK_PCU_CUR FOREIGN KEY (PCU_CUR_ID)
        REFERENCES SIS_ACA_CURSO (CUR_ID)               ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT FK_PCU_CIC FOREIGN KEY (PCU_CIC_ID)
        REFERENCES SIS_ACA_CICLO_CURRICULAR (CIC_ID)    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- ---------------------------------------------------------------------
-- SEC · Sección
-- ---------------------------------------------------------------------
ALTER TABLE SIS_ACA_SECCION
    ADD CONSTRAINT UQ_SEC_CODIGO          UNIQUE (SEC_CODIGO),
    ADD CONSTRAINT CK_SEC_CODIGO_NO_VACIO CHECK (btrim(SEC_CODIGO) <> ''),
    ADD CONSTRAINT CK_SEC_NOMBRE_NO_VACIO CHECK (btrim(SEC_NOMBRE) <> '');

-- ---------------------------------------------------------------------
-- EST · Estudiante
-- ---------------------------------------------------------------------
ALTER TABLE SIS_ACA_ESTUDIANTE
    ADD CONSTRAINT UQ_EST_CODIGO            UNIQUE (EST_CODIGO),
    ADD CONSTRAINT UQ_EST_FOTO_RUTA         UNIQUE (EST_FOTO_RUTA),
    ADD CONSTRAINT CK_EST_CODIGO_NO_VACIO   CHECK (btrim(EST_CODIGO) <> ''),
    ADD CONSTRAINT CK_EST_NOMBRES_NO_VACIO  CHECK (btrim(EST_NOMBRES) <> ''),
    ADD CONSTRAINT CK_EST_APELLIDOS_NO_VACIO CHECK (btrim(EST_APELLIDOS) <> ''),
    ADD CONSTRAINT CK_EST_FOTO_NO_VACIA     CHECK (EST_FOTO_RUTA IS NULL OR btrim(EST_FOTO_RUTA) <> '');
-- EST_FECHA_NACIMIENTO: solo NOT NULL. Rango de edad validado en Symfony (decisión E1).

-- ---------------------------------------------------------------------
-- EPR · Estudiante ↔ Pensum
-- ---------------------------------------------------------------------
ALTER TABLE SIS_ACA_ESTUDIANTE_PROGRAMA
    ADD CONSTRAINT UQ_EPR_EST_PEN_INICIO  UNIQUE (EPR_EST_ID, EPR_PEN_ID, EPR_FECHA_INICIO),
    ADD CONSTRAINT CK_EPR_FECHAS          CHECK (EPR_FECHA_FIN IS NULL OR EPR_FECHA_INICIO <= EPR_FECHA_FIN),
    ADD CONSTRAINT CK_EPR_ESTADO          CHECK (EPR_ESTADO IN ('ACTIVO', 'FINALIZADO', 'RETIRADO')),
    -- Un programa ACTIVO no tiene fecha fin; uno FINALIZADO o RETIRADO sí.
    ADD CONSTRAINT CK_EPR_ESTADO_FECHA_FIN CHECK ((EPR_ESTADO = 'ACTIVO') = (EPR_FECHA_FIN IS NULL)),
    ADD CONSTRAINT FK_EPR_EST FOREIGN KEY (EPR_EST_ID)
        REFERENCES SIS_ACA_ESTUDIANTE (EST_ID)          ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT FK_EPR_PEN FOREIGN KEY (EPR_PEN_ID)
        REFERENCES SIS_ACA_PENSUM (PEN_ID)              ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Un solo programa ACTIVO por estudiante (el historial FINALIZADO/RETIRADO puede tener varios).
CREATE UNIQUE INDEX UX_EPR_EST_ACTIVO
    ON SIS_ACA_ESTUDIANTE_PROGRAMA (EPR_EST_ID)
    WHERE EPR_ESTADO = 'ACTIVO';

-- ---------------------------------------------------------------------
-- EPE · Estudiante en período
-- ---------------------------------------------------------------------
ALTER TABLE SIS_ACA_ESTUDIANTE_PERIODO
    ADD CONSTRAINT UQ_EPE_EPR_PER         UNIQUE (EPE_EPR_ID, EPE_PER_ID),
    ADD CONSTRAINT CK_EPE_ESTADO          CHECK (EPE_ESTADO IN ('INSCRITO', 'FINALIZADO', 'RETIRADO')),
    ADD CONSTRAINT FK_EPE_EPR FOREIGN KEY (EPE_EPR_ID)
        REFERENCES SIS_ACA_ESTUDIANTE_PROGRAMA (EPR_ID) ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT FK_EPE_PER FOREIGN KEY (EPE_PER_ID)
        REFERENCES SIS_ACA_PERIODO_ACADEMICO (PER_ID)   ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT FK_EPE_CIC FOREIGN KEY (EPE_CIC_ID)
        REFERENCES SIS_ACA_CICLO_CURRICULAR (CIC_ID)    ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT FK_EPE_SEC FOREIGN KEY (EPE_SEC_ID)
        REFERENCES SIS_ACA_SECCION (SEC_ID)             ON DELETE RESTRICT ON UPDATE RESTRICT;

-- ---------------------------------------------------------------------
-- OFE · Oferta de curso
-- ---------------------------------------------------------------------
ALTER TABLE SIS_ACA_OFERTA_CURSO
    ADD CONSTRAINT UQ_OFE_PER_PCU_SEC     UNIQUE (OFE_PER_ID, OFE_PCU_ID, OFE_SEC_ID),
    ADD CONSTRAINT FK_OFE_PER FOREIGN KEY (OFE_PER_ID)
        REFERENCES SIS_ACA_PERIODO_ACADEMICO (PER_ID)   ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT FK_OFE_PCU FOREIGN KEY (OFE_PCU_ID)
        REFERENCES SIS_ACA_PENSUM_CURSO (PCU_ID)        ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT FK_OFE_SEC FOREIGN KEY (OFE_SEC_ID)
        REFERENCES SIS_ACA_SECCION (SEC_ID)             ON DELETE RESTRICT ON UPDATE RESTRICT;

-- ---------------------------------------------------------------------
-- RES · Resultado de curso
-- ---------------------------------------------------------------------
ALTER TABLE SIS_ACA_RESULTADO_CURSO
    ADD CONSTRAINT UQ_RES_EPE_OFE         UNIQUE (RES_EPE_ID, RES_OFE_ID),
    -- Validez de la nota (NO confundir con aprobación, que depende de la política).
    ADD CONSTRAINT CK_RES_NOTA_RANGO      CHECK (RES_NOTA IS NULL OR RES_NOTA BETWEEN 0 AND 100),
    ADD CONSTRAINT CK_RES_NOTA_FECHA      CHECK ((RES_NOTA IS NULL) = (RES_CALIFICADO_EN IS NULL)),
    ADD CONSTRAINT FK_RES_EPE FOREIGN KEY (RES_EPE_ID)
        REFERENCES SIS_ACA_ESTUDIANTE_PERIODO (EPE_ID)  ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT FK_RES_OFE FOREIGN KEY (RES_OFE_ID)
        REFERENCES SIS_ACA_OFERTA_CURSO (OFE_ID)        ON DELETE RESTRICT ON UPDATE RESTRICT;
