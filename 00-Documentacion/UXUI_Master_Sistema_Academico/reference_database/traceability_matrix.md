# Matriz de trazabilidad — Sistema Académico (SIS_ACA)

Cada fila liga un requerimiento a las piezas que lo implementan y a la prueba que lo demuestra.

- **Fuente:** `PDF` = enunciado UMG · `§n` = sección del contrato `Arquitectura SQL.md` · `Dn`/`Sn`/`Hn` = decisiones aprobadas en los gates.
- **Prefijos de prueba:** `SMK` = `E1_smoke_test.sql` · `DSC` = `E2_dataset_check.sql` · `Dxx`/`Ixx` = `10_validation_queries.sql` · `Nxx` = `11_negative_tests.sql` · `Pxx` y `A–P` = `13_positive_tests.sql` · `Qxx` = `12_business_queries.sql` · `Ex` = `14_explain.sql`.

## 1. Enunciado del proyecto (PDF)

| ID | Requerimiento | Tabla | Campo(s) | Constraint / Trigger | Vista / Consulta | Prueba |
|---|---|---|---|---|---|---|
| R01 | Nombres y apellidos en campos diferentes | SIS_ACA_ESTUDIANTE | EST_NOMBRES, EST_APELLIDOS | NOT NULL, CK_EST_NOMBRES_NO_VACIO, CK_EST_APELLIDOS_NO_VACIO | Q02, Q03 | N51, P04 |
| R02 | Fecha de nacimiento | SIS_ACA_ESTUDIANTE | EST_FECHA_NACIMIENTO | NOT NULL (rango de edad en Symfony) | Q03 | SMK §1 (NULL → 23502) |
| R03 | Fotografía (imagen) | SIS_ACA_ESTUDIANTE | EST_FOTO_RUTA | UQ_EST_FOTO_RUTA, CK_EST_FOTO_NO_VACIA; sin BYTEA | Q03 | P04 (alta con ruta), Q03 |
| R04 | Carrera (catálogo) | SIS_ACA_CARRERA, SIS_ACA_ESTUDIANTE_PROGRAMA, SIS_ACA_PENSUM | CAR_*, EPR_PEN_ID → PEN_CAR_ID | UQ_CAR_CODIGO, UQ_CAR_NOMBRE, FK_EPR_PEN, FK_PEN_CAR | Q01, Q03 | N06, P01, P05, A |
| R05 | Catálogo de semestres | SIS_ACA_PERIODO_ACADEMICO, SIS_ACA_CICLO_CURRICULAR | PER_*, CIC_* | UQ_PER_ANL_NUMERO, UQ_CIC_ANIO_SEMESTRE | Q23 | N08, P07 |
| R06 | Catálogo de secciones | SIS_ACA_SECCION | SEC_* | UQ_SEC_CODIGO | Q07, Q13 | DSC |
| R07 | Catálogo de cursos | SIS_ACA_CURSO | CUR_* | UQ_CUR_CODIGO | Q06, Q10 | N07, P03 |
| R08 | Ingreso de notas al finalizar el semestre (semestre, sección, curso, nota) | SIS_ACA_RESULTADO_CURSO + EPE + OFE | RES_NOTA, RES_EPE_ID, RES_OFE_ID | T2 (SA201–SA207), CK_RES_NOTA_RANGO | VW_INGRESO_NOTAS, Q25 | P10–P15, N16–N24, N |
| R09 | Buscar al alumno para luego ingresar notas | SIS_ACA_ESTUDIANTE | EST_CODIGO, EST_APELLIDOS | UQ_EST_CODIGO, IX_EST_BUSQUEDA_APELLIDOS | Q02, Q25 | E1 / Q02 |
| R10 | Reporte general de alumnos por carrera | EST, EPR, PEN, CAR | — | IX_EPR_PEN | Q01 | L, E2 |
| R11 | Reporte de notas por carrera, curso y sección | RES y contexto | — | IX_OFE_PCU, IX_RES_OFE | VW_REPORTE_NOTAS, Q08 | M, E3 |
| R12 | Consulta en pantalla: información del alumno e historial de notas | EST, RES | — | — | Q03, Q04, VW_RESULTADO_ESTUDIANTE | DSC casos A–J, E1 |
| R13 | Datos precargados para la demostración | 06–09 | — | — | — | DSC (34 verificaciones) |

## 2. Contrato de arquitectura

| ID | Requerimiento | Tabla | Campo(s) | Constraint / Trigger | Vista / Consulta | Prueba |
|---|---|---|---|---|---|---|
| R20 | Nota válida 0–100, distinta de la aprobación (§2) | SIS_ACA_RESULTADO_CURSO | RES_NOTA NUMERIC(5,2) | CK_RES_NOTA_RANGO | — | N01, N02, N04 |
| R21 | Nota mínima 61 configurable, no hardcodeada (§2, §3) | SIS_ACA_POLITICA_ACADEMICA, SIS_ACA_PERIODO_ACADEMICO | POL_NOTA_APROBACION, PER_POL_ID | FK_PER_POL, T3 | VW_RESULTADO_ESTUDIANTE (RES_ESTADO) | P11 (61), P12 (60), SMK §3 |
| R22 | Frontera 60.99 / 61.00, sin redondeo (S2) | SIS_ACA_RESULTADO_CURSO | RES_NOTA | comparación literal `>=` | VW_RESULTADO_ESTUDIANTE | SMK §3, §10d; DSC frontera |
| R23 | Políticas versionadas sin modificar el pasado (§3, H2) | SIS_ACA_POLITICA_ACADEMICA | POL_VIGENTE_DESDE | UQ_POL_VIGENTE_DESDE, T3 SA303, SA304 | VW_POLITICA_LINEA_TIEMPO, Q24 | N14, N27, N28, D01 |
| R24 | El período usa la política vigente en su inicio (H2) | SIS_ACA_PERIODO_ACADEMICO | PER_POL_ID, PER_FECHA_INICIO | T3 SA301, SA302, SA305; autoasignación (E1-H6) | — | N25, N26, N29, P07, D02 |
| R25 | Validación histórica: 65 en 2026 sigue APROBADO tras POL-2028 = 70 (§47) | POL, PER, RES | — | FK explícita PER_POL_ID + T3 | Q24 | P20–P23, SMK §13 |
| R26 | Política vigente hoy, ignorando futuras (§22.1) | SIS_ACA_POLITICA_ACADEMICA | — | — | VW_POLITICA_VIGENTE | SMK §13 |
| R27 | Currículo ≠ calendario (§4) | CIC vs PER | CIC_*, PER_* | tablas separadas | VW_RESULTADO_ESTUDIANTE (CIC_* y EPE_CIC_ID) | Q04 (repitencia de ciclo 1 en 2026) |
| R28 | Pensum versionado; el estudiante no migra (§5) | SIS_ACA_PENSUM, SIS_ACA_ESTUDIANTE_PROGRAMA | PEN_VERSION, EPR_PEN_ID | UQ_PEN_CAR_VERSION, T4 (EPR_PEN_ID) | — | N31, B, DSC (pensum 2027 sin estudiantes), I06 |
| R29 | Catálogo maestro sin duplicar cursos por carrera (§6) | SIS_ACA_CURSO, SIS_ACA_PENSUM_CURSO | PCU_CUR_ID | UQ_CUR_CODIGO, UQ_PCU_PEN_CUR | — | DSC (MAT-101 en 4 pensums), N12, D06 |
| R30 | Obligatorio vs optativo; contrato para Symfony (§7) | SIS_ACA_PENSUM_CURSO | PCU_OBLIGATORIO | COMMENT (contrato) | VW_AVANCE_*, VW_INGRESO_NOTAS | C, SMK §5 (optativo no cuenta) |
| R31 | Carrera ↔ pensum coherentes (§12, §17.1) | SIS_ACA_ESTUDIANTE_PROGRAMA | (sin EPR_CAR_ID: H1) | por construcción + T4 PEN_CAR_ID | — | N15, N35, P05 |
| R32 | Un solo programa activo por estudiante (§12) | SIS_ACA_ESTUDIANTE_PROGRAMA | EPR_EST_ID, EPR_ESTADO | UX_EPR_EST_ACTIVO, CK_EPR_ESTADO_FECHA_FIN | — | N13, N47 |
| R33 | Ciclo y sección del estudiante por período (§13) | SIS_ACA_ESTUDIANTE_PERIODO | EPE_CIC_ID, EPE_SEC_ID | UQ_EPE_EPR_PER | Q03 | N09, P08, D08 |
| R34 | Oferta única por período, curso del pensum y sección (§14) | SIS_ACA_OFERTA_CURSO | OFE_* | UQ_OFE_PER_PCU_SEC | — | N10, P09 |
| R35 | Un resultado por estudiante y oferta; estado derivado (§15) | SIS_ACA_RESULTADO_CURSO | RES_EPE_ID, RES_OFE_ID | UQ_RES_EPE_OFE | VW_RESULTADO_ESTUDIANTE | N11, P11–P13, D13 |
| R36 | Repetición sin destruir intentos; intentos, primera/última/mejor nota (§16) | RES | — | T4 identidad (SA401), sin attempt_number almacenado | VW_INTENTO_CURSO, Q16, Q17 | P16, P17, G, H, DSC casos D/E |
| R37 | Sin nuevo intento tras aprobar (D6) | RES | — | T2 SA207 | VW_INGRESO_NOTAS (YA_APROBADO) | N24, N55, D14 |
| R38 | Resultado en período compatible (§17.3) | RES, EPE, OFE | — | T2 SA201 | — | N16, D09 |
| R39 | Oferta del mismo pensum (§17.2, §17.5) | RES, OFE, PCU | — | T2 SA202 | — | N17, D10 |
| R40 | Sección coherente (§17.4, S1) | RES, EPE, OFE | — | T2 SA203 | — | N18, D11 |
| R41 | Solo un período ABIERTO admite cambios de resultados (S3, D7) | PER | PER_ESTADO | T2 SA204 | VW_INGRESO_NOTAS (PERIODO_NO_ABIERTO) | N19–N21, SMK §10, §10b |
| R42 | Solo un estudiante INSCRITO y una oferta activa (D1, D2) | EPE, OFE | EPE_ESTADO, OFE_ACTIVO | T2 SA205, SA206 | VW_INGRESO_NOTAS | N22, N23, SMK §8, §9 |
| R43 | Sin reescritura histórica del contexto (H3) | EPR, EPE, OFE, PCU, PEN, PER, ANL, CIC, RES | columnas de contexto | T4 SA401 | — | N31–N40, SMK §11, §12, §10c |
| R44 | Fechas coherentes (§17.8, §17.9) | ANL, PER, PEN, EPR | *_FECHA_*, *_VIGENTE_* | CK_ANL_FECHAS, CK_PER_FECHAS, CK_PEN_VIGENCIA, CK_EPR_FECHAS | — | N43–N46, D03, D04, D07 |
| R45 | Sin IDs huérfanos (§17.10) | todas | FK | 17 FK RESTRICT | — | N49, N50 |
| R46 | `updated_at` automático con una sola función (§19) | 12 tablas | *_ACTUALIZADO_EN | T1 | — | SMK §2, P19 |
| R47 | Sin CASCADE; borrados restringidos (§20) | todas | — | ON DELETE RESTRICT | — | N30, N41, N42, SMK §1 |
| R48 | Estados VARCHAR + CHECK, no ENUM (§8) | ANL, PER, EPR, EPE | *_ESTADO | CK_*_ESTADO | — | N48 |
| R49 | Índices justificados por consultas (§21) | — | — | 7 IX_* | — | E1–E5 |
| R50 | Progreso por estudiante sin doble conteo (§22.3) | — | — | — | VW_AVANCE_PENSUM, Q18 | P18, I, D15, D16, SMK §5 |
| R51 | Progreso y estado por ciclo (§22.4) | — | — | — | VW_AVANCE_CICLO, Q19, Q20 | J, DSC casos F/G |
| R52 | Base para reportes (§22.5) | — | — | — | VW_REPORTE_NOTAS, Q05–Q13 | M, E3 |
| R53 | Pantalla de ingreso con cursos esperados aunque no exista resultado (§22.6) | — | — | — | VW_INGRESO_NOTAS, Q25 | N, P15, SMK §6, DSC (Q25) |
| R54 | Repitencias pendientes descubiertas antes de crear el intento (E1-R2) | — | — | — | VW_INGRESO_NOTAS (CICLO_ANTERIOR) | SMK §6, P15, DSC |
| R55 | Q01–Q25 (§23) | — | — | — | 12_business_queries.sql | resultados esperados en E2_ENTREGA §5 |
| R56 | Tasa de aprobación por intento + % calificados (E3) | — | — | — | Q11, Q12, Q13, Q23 | E2_ENTREGA §5 |
| R57 | Dataset ficticio, realista y reproducible (§24–§31, §50) | 06–09 | — | sin random(); huella md5 | — | DSC (reproducibilidad) |
| R58 | Casos A–J identificables (§30) | — | — | — | — | DSC casos A–J |
| R59 | Pruebas negativas con EXPECTED FAILURE (§33) | — | — | — | — | 11_negative_tests.sql (54 PASS) |
| R60 | Diagnósticos semánticos (§34) + intento posterior a aprobación (E3) | — | — | — | 10_validation_queries.sql | D01–D18, I01–I06, N53 |
| R61 | EXPLAIN de 5 consultas (§35) | — | — | — | 14_explain.sql | E1–E5 |
| R62 | Criterios de aceptación §46 A–P | — | — | — | — | 13_positive_tests.sql P3 |
| R63 | Reset solo en desarrollo (§36) | — | — | 00_reset.sql guarda SA001 | — | prueba manual en otra base |
| R64 | Compatible con Doctrine (§41) | todas | nombres sin comillas | sin FK compuestas ni ManyToMany | vistas readOnly con clave estable | data_dictionary §4, README §17 |
