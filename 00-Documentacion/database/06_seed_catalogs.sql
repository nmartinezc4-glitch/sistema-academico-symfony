-- =====================================================================
--  06_seed_catalogs.sql — E2 · Catálogos base
--
--  DEMONSTRATION DATA · FICTIONAL · ACADEMICALLY PLAUSIBLE
--  Ninguna carrera, curso, política o persona corresponde a una
--  institución real ni a registros oficiales del MINEDUC.
--
--  Reproducible: sin random(), sin IDs fijos. Requiere base limpia
--  (00_reset → 01..05). Orden obligatorio por T3: políticas → años → períodos.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Políticas académicas (cronológicas). POL-2028 es FUTURA: demuestra
-- que una reforma posterior no altera 2025/2026 (§47).
-- ---------------------------------------------------------------------
INSERT INTO SIS_ACA_POLITICA_ACADEMICA (POL_CODIGO, POL_NOMBRE, POL_NOTA_APROBACION, POL_VIGENTE_DESDE) VALUES
 ('POL-2025-01', 'Reglamento Académico 2025 (demostrativo)', 61.00, DATE '2025-01-01'),
 ('POL-2026-01', 'Reglamento Académico 2026 (demostrativo)', 61.00, DATE '2026-01-01'),
 ('POL-2028-01', 'Reglamento Académico 2028 (demostrativo, futuro)', 70.00, DATE '2028-01-01');

-- ---------------------------------------------------------------------
-- Años lectivos y períodos. Los períodos nacen PLANIFICADO y SIN
-- PER_POL_ID: T3 asigna la política vigente en su fecha de inicio.
-- 09_seed_academic_history los abre y cierra en orden.
-- ---------------------------------------------------------------------
INSERT INTO SIS_ACA_ANIO_LECTIVO (ANL_ANIO, ANL_NOMBRE, ANL_FECHA_INICIO, ANL_FECHA_FIN, ANL_ESTADO) VALUES
 (2025, 'Año lectivo 2025', DATE '2025-01-13', DATE '2025-11-28', 'ABIERTO'),
 (2026, 'Año lectivo 2026', DATE '2026-01-12', DATE '2026-11-27', 'ABIERTO');

INSERT INTO SIS_ACA_PERIODO_ACADEMICO (PER_ANL_ID, PER_NUMERO, PER_NOMBRE, PER_FECHA_INICIO, PER_FECHA_FIN)
SELECT a.ANL_ID, x.numero, x.nombre, make_date(a.ANL_ANIO, x.mes_ini, 15), make_date(a.ANL_ANIO, x.mes_fin, 15)
FROM SIS_ACA_ANIO_LECTIVO a
CROSS JOIN (VALUES (1, 'Semestre I',  1, 6),
                   (2, 'Semestre II', 7, 11)) x(numero, nombre, mes_ini, mes_fin)
ORDER BY a.ANL_ANIO, x.numero;

-- ---------------------------------------------------------------------
-- Secciones
-- ---------------------------------------------------------------------
INSERT INTO SIS_ACA_SECCION (SEC_CODIGO, SEC_NOMBRE) VALUES
 ('A', 'Sección A'), ('B', 'Sección B'), ('C', 'Sección C');

-- ---------------------------------------------------------------------
-- Ciclos curriculares (bachillerato de 2 años, 4 semestres)
-- ---------------------------------------------------------------------
INSERT INTO SIS_ACA_CICLO_CURRICULAR (CIC_ANIO, CIC_SEMESTRE, CIC_NOMBRE) VALUES
 (1, 1, 'Año 1 / Semestre I'),
 (1, 2, 'Año 1 / Semestre II'),
 (2, 1, 'Año 2 / Semestre I'),
 (2, 2, 'Año 2 / Semestre II');

-- ---------------------------------------------------------------------
-- Carreras (demostrativas)
-- ---------------------------------------------------------------------
INSERT INTO SIS_ACA_CARRERA (CAR_CODIGO, CAR_NOMBRE, CAR_DESCRIPCION) VALUES
 ('BCL-COMP', 'Bachillerato en Ciencias y Letras con Orientación en Computación',
  'Carrera DEMOSTRATIVA. Énfasis en programación, desarrollo web y bases de datos.'),
 ('BCL',      'Bachillerato en Ciencias y Letras',
  'Carrera DEMOSTRATIVA. Formación general en ciencias, humanidades y lenguaje.'),
 ('BCO',      'Bachillerato con Orientación Comercial',
  'Carrera DEMOSTRATIVA. Énfasis en contabilidad, administración y legislación.');

-- ---------------------------------------------------------------------
-- Catálogo maestro de cursos (un solo registro por curso; varios se
-- comparten entre carreras: MAT-101, ING-101, COM-101, EST-201, ETI-202…)
-- ---------------------------------------------------------------------
INSERT INTO SIS_ACA_CURSO (CUR_CODIGO, CUR_NOMBRE) VALUES
 -- Comunes
 ('MAT-101', 'Matemática I'),            ('MAT-102', 'Matemática II'),          ('MAT-201', 'Matemática III'),
 ('COM-101', 'Comunicación y Lenguaje I'), ('COM-102', 'Comunicación y Lenguaje II'),
 ('ING-101', 'Inglés I'),                ('ING-102', 'Inglés II'),               ('ING-201', 'Inglés III'),  ('ING-202', 'Inglés IV'),
 ('FIS-101', 'Física I'),                ('FIS-102', 'Física II'),
 ('EST-201', 'Estadística Descriptiva'), ('ETI-202', 'Ética y Ciudadanía'),     ('SEM-202', 'Seminario de Investigación'),
 ('ART-101', 'Expresión Artística'),
 -- Computación
 ('PRG-101', 'Programación I'),          ('PRG-102', 'Programación II'),        ('PRG-201', 'Programación III'),
 ('WEB-101', 'Desarrollo Web'),          ('BDD-201', 'Bases de Datos'),          ('RED-202', 'Redes de Computadoras'),
 ('SOF-202', 'Fundamentos de Ingeniería de Software'),
 ('IAR-202', 'Introducción a la Inteligencia Artificial'),
 -- Ciencias y Letras
 ('BIO-101', 'Biología'),                ('QUI-101', 'Química'),
 ('SOC-101', 'Estudios Sociales I'),     ('SOC-102', 'Estudios Sociales II'),
 ('LIT-201', 'Literatura'),              ('FIL-201', 'Filosofía'),               ('PSI-201', 'Psicología'),
 -- Comercial
 ('CON-101', 'Contabilidad I'),          ('CON-102', 'Contabilidad II'),         ('CON-201', 'Contabilidad III'),
 ('CON-202', 'Contabilidad de Costos'),  ('MEC-101', 'Mecanografía y Computación'),
 ('ECO-101', 'Economía'),                ('DER-101', 'Derecho Mercantil'),       ('ADM-201', 'Administración'),
 ('FIN-201', 'Matemática Financiera'),   ('AUD-202', 'Auditoría Básica'),        ('LEG-202', 'Legislación Laboral');
