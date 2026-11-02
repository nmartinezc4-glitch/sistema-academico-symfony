-- =====================================================================
--  08_seed_students.sql — E2 · Estudiantes e inscripción en pensum
--
--  DEMONSTRATION DATA · FICTIONAL. Nombres plausibles del contexto
--  guatemalteco, inventados. No corresponden a personas reales.
--
--  45 estudiantes:
--    Cohorte 2025 (STU-2025-0001…0026): ingreso 2025-01-15, cursa Año 1
--      en 2025 y Año 2 en 2026. STU-2025-0026 se retira al final de 2025.
--    Cohorte 2026 (STU-2026-0001…0018): ingreso 2026-01-15, cursa Año 1
--      en 2026.
--    STU-2026-0019: registrado sin períodos ni resultados (CASO H).
--      Programa ACTIVO en el pensum BCL-COMP-2025 desde 2026-09-01; aún no
--      se le ha asignado ningún período.
--
--  Casos nombrados (A–J): ver docs/E2_ENTREGA.md §3.
--  Fotografía: solo ruta relativa (el archivo lo administra Symfony).
-- =====================================================================

INSERT INTO SIS_ACA_ESTUDIANTE (EST_CODIGO, EST_NOMBRES, EST_APELLIDOS, EST_FECHA_NACIMIENTO, EST_FOTO_RUTA)
SELECT x.codigo, x.nombres, x.apellidos, x.nacimiento,
       'students/' || substr(x.codigo, 5, 4) || '/' || x.codigo || '.jpg'
FROM (VALUES
  -- Cohorte 2025 · Computación
  ('STU-2025-0001','Ana Lucía','López Ajú',             DATE '2008-03-14'),
  ('STU-2025-0002','Bryan Estuardo','Tzul Morales',     DATE '2008-08-02'),
  ('STU-2025-0003','Carla Sofía','Xicará Pérez',        DATE '2008-11-20'),
  ('STU-2025-0004','Diego Alejandro','Batz Coyoy',      DATE '2008-05-09'),
  ('STU-2025-0005','Elena María','Chávez Son',          DATE '2008-01-27'),
  ('STU-2025-0006','Fernando José','Ixcot Ramírez',     DATE '2008-07-18'),
  ('STU-2025-0007','Gabriela Alejandra','Monzón Tuy',   DATE '2008-09-05'),
  ('STU-2025-0008','Héctor Manuel','Sicán Gómez',       DATE '2007-12-11'),
  ('STU-2025-0009','Isabel Cristina','Yax Herrera',     DATE '2008-04-23'),
  ('STU-2025-0010','Jorge Luis','Pac Méndez',           DATE '2008-02-08'),
  -- Cohorte 2025 · Ciencias y Letras
  ('STU-2025-0011','Karla Fernanda','Ajcalón Ruiz',     DATE '2008-06-30'),
  ('STU-2025-0012','Luis Fernando','Cutzal Orozco',     DATE '2008-10-14'),
  ('STU-2025-0013','María José','Quemé Barrios',        DATE '2008-03-03'),
  ('STU-2025-0014','Nelson Rodrigo','Tum Aguilar',    DATE '2007-11-29'),
  ('STU-2025-0015','Olga Patricia','Saquic Morales',    DATE '2008-08-21'),
  ('STU-2025-0016','Pablo Andrés','Xoyón Castillo',     DATE '2008-01-16'),
  ('STU-2025-0017','Rosa Elena','Coc Pérez',            DATE '2008-05-25'),
  ('STU-2025-0018','Samuel Isaí','Choc Lima',           DATE '2008-12-07'),
  -- Cohorte 2025 · Comercial
  ('STU-2025-0019','Tatiana Beatriz','Puac Juárez',     DATE '2008-02-19'),
  ('STU-2025-0020','Ulises Javier','Sontay Ortiz',      DATE '2007-10-02'),
  ('STU-2025-0021','Valeria Andrea','Xicay Morán',      DATE '2008-07-07'),
  ('STU-2025-0022','Walter Rubén','Tojín Estrada',      DATE '2008-04-12'),
  ('STU-2025-0023','Ximena Lucía','Raxón Cifuentes',    DATE '2008-09-28'),
  ('STU-2025-0024','Yeferson Abel','Chocoj Paz',        DATE '2008-06-01'),
  ('STU-2025-0025','Zoila Marisol','Tzoc Aguilar',      DATE '2008-11-08'),
  ('STU-2025-0026','Adrián Eduardo','Cumes Maldonado',  DATE '2008-03-26'),
  -- Cohorte 2026 · Computación
  ('STU-2026-0001','Andrea Paola','Sic Chun',           DATE '2009-02-10'),
  ('STU-2026-0002','Brandon Steven','Ordóñez Ical',     DATE '2009-06-17'),
  ('STU-2026-0003','Camila Renata','Yoc Lux',           DATE '2009-09-03'),
  ('STU-2026-0004','Daniel Esteban','Pirir Mazariegos', DATE '2009-01-22'),
  ('STU-2026-0005','Emily Dayana','Quiej García',       DATE '2009-04-15'),
  ('STU-2026-0006','Franco Ismael','Xiloj Tobar',       DATE '2009-08-29'),
  ('STU-2026-0007','Génesis Abigail','Mux Rodas',       DATE '2009-12-04'),
  ('STU-2026-0008','Hugo Leonel','Tecún Ac',            DATE '2008-10-19'),
  -- Cohorte 2026 · Ciencias y Letras
  ('STU-2026-0009','Iris Daniela','Ajú Pineda',         DATE '2009-05-11'),
  ('STU-2026-0010','Josué David','Tiney León',          DATE '2009-03-27'),
  ('STU-2026-0011','Karina Nayeli','Cholotío Soto',   DATE '2009-07-14'),
  ('STU-2026-0012','Leonel Arturo','Calel Bran',        DATE '2008-12-30'),
  ('STU-2026-0013','Mónica Rocío','Guarcax Lemus',      DATE '2009-10-09'),
  -- Cohorte 2026 · Comercial
  ('STU-2026-0014','Natalia Sofía','Tax Villatoro',     DATE '2009-01-05'),
  ('STU-2026-0015','Óscar Iván','Ixchop Morales',       DATE '2009-06-23'),
  ('STU-2026-0016','Paola Michelle','Raguay Solís',     DATE '2009-02-28'),
  ('STU-2026-0017','Rodrigo Alexander','Chiroy Pérez',  DATE '2009-08-16'),
  ('STU-2026-0018','Sara Lucía','Toj Ramírez',          DATE '2009-11-12'),
  -- Registrado sin períodos ni resultados (CASO H)
  ('STU-2026-0019','Tomás Ezequiel','Gómez Xuruc',      DATE '2010-01-20')
) x(codigo, nombres, apellidos, nacimiento);

-- Inscripción en pensum (programa). La carrera se deriva del pensum (H1).
INSERT INTO SIS_ACA_ESTUDIANTE_PROGRAMA (EPR_EST_ID, EPR_PEN_ID, EPR_FECHA_INICIO, EPR_FECHA_FIN, EPR_ESTADO)
SELECT e.EST_ID, p.PEN_ID, x.inicio, x.fin, x.estado
FROM (VALUES
  ('STU-2025-0001','STU-2025-0010','BCL-COMP-2025', DATE '2025-01-15', NULL::date, 'ACTIVO'),
  ('STU-2025-0011','STU-2025-0018','BCL-2025',      DATE '2025-01-15', NULL::date, 'ACTIVO'),
  ('STU-2025-0019','STU-2025-0025','BCO-2025',      DATE '2025-01-15', NULL::date, 'ACTIVO'),
  ('STU-2025-0026','STU-2025-0026','BCO-2025',      DATE '2025-01-15', DATE '2025-12-05', 'RETIRADO'),
  ('STU-2026-0001','STU-2026-0008','BCL-COMP-2025', DATE '2026-01-15', NULL::date, 'ACTIVO'),
  ('STU-2026-0009','STU-2026-0013','BCL-2025',      DATE '2026-01-15', NULL::date, 'ACTIVO'),
  ('STU-2026-0014','STU-2026-0018','BCO-2025',      DATE '2026-01-15', NULL::date, 'ACTIVO'),
  ('STU-2026-0019','STU-2026-0019','BCL-COMP-2025', DATE '2026-09-01', NULL::date, 'ACTIVO')
) x(desde, hasta, pensum, inicio, fin, estado)
JOIN SIS_ACA_ESTUDIANTE e ON e.EST_CODIGO BETWEEN x.desde AND x.hasta
JOIN SIS_ACA_PENSUM p     ON p.PEN_CODIGO = x.pensum;
