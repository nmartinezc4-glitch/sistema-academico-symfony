-- =====================================================================
--  07_seed_curricula.sql — E2 · Pensums y asignación de cursos
--
--  PENSUMS DEMOSTRATIVOS / ACADÉMICAMENTE PLAUSIBLES. No corresponden a
--  pensums oficiales del MINEDUC.
--
--  · 3 carreras × pensum 2025 (versión 1), 4 ciclos × 5 cursos obligatorios.
--  · Optativo ART-101 (Expresión Artística) en Año 1 / Semestre II de
--    Computación y Ciencias y Letras: no cuenta para el avance.
--  · Computación tiene además el pensum 2027 (versión 2, sin estudiantes):
--    demuestra que un pensum nuevo NO migra a los estudiantes del anterior.
-- =====================================================================

INSERT INTO SIS_ACA_PENSUM (PEN_CAR_ID, PEN_CODIGO, PEN_NOMBRE, PEN_VERSION, PEN_VIGENTE_DESDE, PEN_VIGENTE_HASTA)
SELECT c.CAR_ID, x.codigo, x.nombre, x.version, x.desde, x.hasta
FROM (VALUES
  ('BCL-COMP', 'BCL-COMP-2025', 'Computación · Pensum 2025',         1, DATE '2025-01-01', DATE '2026-12-31'),
  ('BCL-COMP', 'BCL-COMP-2027', 'Computación · Pensum 2027',         2, DATE '2027-01-01', NULL::date),
  ('BCL',      'BCL-2025',      'Ciencias y Letras · Pensum 2025',   1, DATE '2025-01-01', NULL::date),
  ('BCO',      'BCO-2025',      'Comercial · Pensum 2025',           1, DATE '2025-01-01', NULL::date)
) x(carrera, codigo, nombre, version, desde, hasta)
JOIN SIS_ACA_CARRERA c ON c.CAR_CODIGO = x.carrera;

-- (pensum, curso, año curricular, semestre, orden, obligatorio)
INSERT INTO SIS_ACA_PENSUM_CURSO (PCU_PEN_ID, PCU_CUR_ID, PCU_CIC_ID, PCU_ORDEN, PCU_OBLIGATORIO)
SELECT p.PEN_ID, c.CUR_ID, k.CIC_ID, x.orden, x.oblig
FROM (VALUES
  -- Computación 2025
  ('BCL-COMP-2025','MAT-101',1,1,1,true), ('BCL-COMP-2025','PRG-101',1,1,2,true), ('BCL-COMP-2025','ING-101',1,1,3,true),
  ('BCL-COMP-2025','COM-101',1,1,4,true), ('BCL-COMP-2025','FIS-101',1,1,5,true),
  ('BCL-COMP-2025','MAT-102',1,2,1,true), ('BCL-COMP-2025','PRG-102',1,2,2,true), ('BCL-COMP-2025','ING-102',1,2,3,true),
  ('BCL-COMP-2025','FIS-102',1,2,4,true), ('BCL-COMP-2025','WEB-101',1,2,5,true), ('BCL-COMP-2025','ART-101',1,2,6,false),
  ('BCL-COMP-2025','MAT-201',2,1,1,true), ('BCL-COMP-2025','PRG-201',2,1,2,true), ('BCL-COMP-2025','BDD-201',2,1,3,true),
  ('BCL-COMP-2025','ING-201',2,1,4,true), ('BCL-COMP-2025','EST-201',2,1,5,true),
  ('BCL-COMP-2025','RED-202',2,2,1,true), ('BCL-COMP-2025','SOF-202',2,2,2,true), ('BCL-COMP-2025','ING-202',2,2,3,true),
  ('BCL-COMP-2025','ETI-202',2,2,4,true), ('BCL-COMP-2025','SEM-202',2,2,5,true),
  -- Computación 2027 (versión 2: IAR-202 sustituye a SEM-202; sin optativo)
  ('BCL-COMP-2027','MAT-101',1,1,1,true), ('BCL-COMP-2027','PRG-101',1,1,2,true), ('BCL-COMP-2027','ING-101',1,1,3,true),
  ('BCL-COMP-2027','COM-101',1,1,4,true), ('BCL-COMP-2027','FIS-101',1,1,5,true),
  ('BCL-COMP-2027','MAT-102',1,2,1,true), ('BCL-COMP-2027','PRG-102',1,2,2,true), ('BCL-COMP-2027','ING-102',1,2,3,true),
  ('BCL-COMP-2027','FIS-102',1,2,4,true), ('BCL-COMP-2027','WEB-101',1,2,5,true),
  ('BCL-COMP-2027','MAT-201',2,1,1,true), ('BCL-COMP-2027','PRG-201',2,1,2,true), ('BCL-COMP-2027','BDD-201',2,1,3,true),
  ('BCL-COMP-2027','ING-201',2,1,4,true), ('BCL-COMP-2027','EST-201',2,1,5,true),
  ('BCL-COMP-2027','RED-202',2,2,1,true), ('BCL-COMP-2027','SOF-202',2,2,2,true), ('BCL-COMP-2027','ING-202',2,2,3,true),
  ('BCL-COMP-2027','ETI-202',2,2,4,true), ('BCL-COMP-2027','IAR-202',2,2,5,true),
  -- Ciencias y Letras 2025
  ('BCL-2025','MAT-101',1,1,1,true), ('BCL-2025','COM-101',1,1,2,true), ('BCL-2025','ING-101',1,1,3,true),
  ('BCL-2025','BIO-101',1,1,4,true), ('BCL-2025','SOC-101',1,1,5,true),
  ('BCL-2025','MAT-102',1,2,1,true), ('BCL-2025','COM-102',1,2,2,true), ('BCL-2025','ING-102',1,2,3,true),
  ('BCL-2025','QUI-101',1,2,4,true), ('BCL-2025','SOC-102',1,2,5,true), ('BCL-2025','ART-101',1,2,6,false),
  ('BCL-2025','MAT-201',2,1,1,true), ('BCL-2025','LIT-201',2,1,2,true), ('BCL-2025','FIS-101',2,1,3,true),
  ('BCL-2025','FIL-201',2,1,4,true), ('BCL-2025','PSI-201',2,1,5,true),
  ('BCL-2025','EST-201',2,2,1,true), ('BCL-2025','ING-201',2,2,2,true), ('BCL-2025','FIS-102',2,2,3,true),
  ('BCL-2025','ETI-202',2,2,4,true), ('BCL-2025','SEM-202',2,2,5,true),
  -- Comercial 2025
  ('BCO-2025','MAT-101',1,1,1,true), ('BCO-2025','COM-101',1,1,2,true), ('BCO-2025','CON-101',1,1,3,true),
  ('BCO-2025','ING-101',1,1,4,true), ('BCO-2025','MEC-101',1,1,5,true),
  ('BCO-2025','MAT-102',1,2,1,true), ('BCO-2025','CON-102',1,2,2,true), ('BCO-2025','ECO-101',1,2,3,true),
  ('BCO-2025','ING-102',1,2,4,true), ('BCO-2025','DER-101',1,2,5,true),
  ('BCO-2025','CON-201',2,1,1,true), ('BCO-2025','EST-201',2,1,2,true), ('BCO-2025','ADM-201',2,1,3,true),
  ('BCO-2025','ING-201',2,1,4,true), ('BCO-2025','FIN-201',2,1,5,true),
  ('BCO-2025','CON-202',2,2,1,true), ('BCO-2025','AUD-202',2,2,2,true), ('BCO-2025','ETI-202',2,2,3,true),
  ('BCO-2025','SEM-202',2,2,4,true), ('BCO-2025','LEG-202',2,2,5,true)
) x(pensum, curso, anio, semestre, orden, oblig)
JOIN SIS_ACA_PENSUM p           ON p.PEN_CODIGO = x.pensum
JOIN SIS_ACA_CURSO c            ON c.CUR_CODIGO = x.curso
JOIN SIS_ACA_CICLO_CURRICULAR k ON k.CIC_ANIO = x.anio AND k.CIC_SEMESTRE = x.semestre;
