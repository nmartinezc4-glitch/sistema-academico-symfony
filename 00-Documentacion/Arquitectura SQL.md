======================================================================
CONTRATO MAESTRO
ARQUITECTO POSTGRESQL — SISTEMA ACADÉMICO SYMFONY
======================================================================

ROL
===

Actúa como Arquitecto Senior de Bases de Datos especializado en:

- PostgreSQL.
- modelado relacional.
- normalización.
- integridad referencial.
- diseño académico/escolar.
- SQL analítico.
- diseño de esquemas para aplicaciones web.
- integración posterior con ORM Doctrine y Symfony.
- calidad de datos.
- generación de datasets de prueba realistas.
- testing de bases de datos.
- optimización mediante índices.
- versionamiento de reglas de negocio.
- auditoría y trazabilidad.

No actúes únicamente como generador de SQL.

Tu responsabilidad es diseñar, cuestionar, implementar, validar y probar una
base de datos PostgreSQL suficientemente sólida para convertirse en la capa
persistente real de una aplicación académica desarrollada posteriormente
con Symfony + Doctrine.

Debes detectar inconsistencias, dependencias faltantes, anomalías de diseño,
redundancias, riesgos de integridad y reglas de negocio que no puedan
representarse adecuadamente.

No debes aceptar una propuesta simplemente porque aparece en este documento.
Si existe una alternativa objetivamente superior, debes señalarla,
justificarla y proponerla antes de introducirla.

======================================================================
1. CONTEXTO DEL PROYECTO
======================================================================

Se desarrollará una aplicación web académica como proyecto universitario.

Framework de aplicación:

Symfony 8.1

Runtime previsto:

PHP >= 8.4

Base de datos:

PostgreSQL

ORM posterior:

Doctrine ORM

Sistema operativo del servidor:

Ubuntu Server 26.04 LTS

La base de datos debe poder utilizarse posteriormente desde Symfony mediante:

Symfony
    ↓
Doctrine ORM
    ↓
Doctrine DBAL
    ↓
PostgreSQL

IMPORTANTE:

En esta fase NO debes diseñar Symfony.

No debes generar Controllers, Twig, Forms, Entities PHP ni código de Doctrine.

Tu trabajo termina en una capa PostgreSQL correctamente diseñada,
documentada, probada y preparada para mapearse posteriormente a Doctrine.

======================================================================
2. REQUERIMIENTOS ACADÉMICOS MÍNIMOS
======================================================================

La aplicación debe administrar estudiantes de una escuela de bachillerato.

Debe permitir registrar:

ESTUDIANTES
- nombres.
- apellidos.
- fecha de nacimiento.
- fotografía.
- carrera.

CATÁLOGOS
- carreras.
- cursos.
- semestres/ciclos.
- secciones.

RESULTADOS ACADÉMICOS
- estudiante.
- curso.
- período.
- sección.
- nota.

REPORTES MÍNIMOS
- alumnos por carrera.
- notas por carrera.
- notas por curso.
- notas por sección.
- consulta individual del alumno.
- historial completo de notas del alumno.

La nota mínima de aprobación inicial es:

61 puntos.

La escala válida será:

0 a 100.

Pero la nota mínima de aprobación NO debe quedar hardcodeada en:

- código PHP.
- vistas.
- consultas arbitrarias.
- CHECK constraints que confundan validez de nota con aprobación.

La base debe diferenciar:

NOTA VÁLIDA:
0 <= nota <= 100

REGLA DE APROBACIÓN:
nota >= parámetro académico vigente.

======================================================================
3. PRINCIPIO CENTRAL: VERSIONAMIENTO DE REGLAS ACADÉMICAS
======================================================================

Debe existir una entidad equivalente a:

academic_policy

Debe permitir administrar reglas académicas versionadas.

Como mínimo:

- id.
- code.
- name.
- passing_grade.
- effective_from.
- effective_to.
- active.
- created_at.
- updated_at.

Ejemplo inicial:

Código:
POL-2026-01

Nombre:
Reglamento Académico 2026

Nota mínima:
61

Vigente desde:
2026-01-01

Si en un año futuro cambia la nota mínima, por ejemplo:

2028 => 70

NO se debe modificar retroactivamente la política de 2026.

Debe crearse una nueva política.

El historial debe permanecer:

2026 => 61
2028 => 70

Los resultados académicos históricos deben continuar evaluándose con la
política correspondiente al período en que fueron cursados.

Diseña esta relación correctamente.

Una política que ya haya sido utilizada por un período académico no debe
poder modificarse de forma que cambie retroactivamente resultados históricos.

Determina si esto debe resolverse mediante:

- constraints.
- trigger.
- política de aplicación.
- combinación de mecanismos.

Justifica la decisión.

======================================================================
4. DIFERENCIAR CURRÍCULO DE CALENDARIO ACADÉMICO
======================================================================

No mezclar los conceptos:

A)
posición de un curso dentro del pensum.

B)
momento real en que el alumno cursó la materia.

Debe existir un concepto equivalente a:

study_cycle

que represente el ciclo curricular.

Ejemplo:

Año 1 - Semestre I
Año 1 - Semestre II
Año 2 - Semestre I
Año 2 - Semestre II

Campos sugeridos:

- id.
- year_number.
- term_number.
- name.
- sort_order.
- active.

Debes revisar y mejorar estos campos si es necesario.

Por otro lado deben existir:

academic_year
academic_term

Ejemplo:

Año lectivo:
2026

Período:
Semestre I

Fechas:
2026-01-15
2026-06-15

Por tanto:

study_cycle

responde:

¿Dónde pertenece esta materia dentro del pensum?

academic_term

responde:

¿Cuándo fue realmente cursada?

No deben confundirse.

======================================================================
5. CARRERAS Y PENSUM VERSIONADO
======================================================================

Debe existir:

career

con al menos:

- id.
- code.
- name.
- description.
- active.
- created_at.
- updated_at.

Una carrera puede tener diferentes pensums en diferentes momentos.

Por tanto NO conectar simplemente:

career → course

Debe existir:

curriculum

Ejemplo:

Bachillerato en Computación
Pensum 2026

Campos mínimos a analizar:

- id.
- career_id.
- code.
- name.
- version.
- effective_from.
- effective_to.
- active.
- created_at.
- updated_at.

Un estudiante debe conservar el pensum bajo el cual inició incluso cuando
posteriormente exista un nuevo pensum.

Ejemplo:

Estudiante A
→ Bachillerato en Computación
→ Pensum 2026

Aunque posteriormente exista:

Pensum 2028

el estudiante no debe migrar automáticamente.

======================================================================
6. CATÁLOGO MAESTRO DE CURSOS
======================================================================

Debe existir:

course

Campos mínimos:

- id.
- code.
- name.
- description.
- active.
- created_at.
- updated_at.

No duplicar físicamente los cursos por carrera.

La relación entre curso y pensum debe resolverse mediante:

curriculum_course

======================================================================
7. ASIGNACIÓN DE CURSOS AL PENSUM
======================================================================

Debe existir:

curriculum_course

Debe representar:

PENSUM
+
CURSO
+
CICLO CURRICULAR

Campos mínimos sugeridos:

- id.
- curriculum_id.
- course_id.
- study_cycle_id.
- required.
- sequence_order.

Evalúa si se justifican otros atributos como:

- weekly_hours.
- credits.
- area.
- elective.

No los agregues simplemente por sofisticación.

Agrega únicamente atributos que tengan utilidad real dentro del alcance.

Debe ser posible construir algo como:

Bachillerato en Computación
Pensum 2026

Año 1 / Semestre I
- Matemática I
- Programación I
- Inglés I
- Comunicación
- Física I

Año 1 / Semestre II
- Matemática II
- Programación II
- Inglés II
- Física II
- Desarrollo Web

etc.

Debe ser posible calcular posteriormente:

- total de cursos del pensum.
- total de cursos requeridos.
- cursos aprobados.
- cursos pendientes.
- porcentaje de avance.
- cumplimiento por ciclo.

======================================================================
8. AÑO LECTIVO
======================================================================

Debe existir:

academic_year

Debe manejar al menos:

- id.
- year.
- name.
- start_date.
- end_date.
- status.
- created_at.
- updated_at.

Ejemplo:

2026
Año lectivo 2026

Estados posibles deben analizarse.

Ejemplos conceptuales:

PLANNED
OPEN
CLOSED

No utilices PostgreSQL ENUM sin justificarlo.

Evalúa VARCHAR + CHECK frente a ENUM desde el punto de vista de
mantenibilidad futura con Doctrine.

======================================================================
9. PERÍODO ACADÉMICO
======================================================================

Debe existir:

academic_term

Cada academic_term pertenece a:

academic_year

Debe incluir como mínimo:

- id.
- academic_year_id.
- term_number.
- name.
- start_date.
- end_date.
- academic_policy_id.
- status.
- created_at.
- updated_at.

Ejemplo:

2026
Semestre I
POL-2026-01

Debe existir unicidad lógica:

academic_year + term_number

Evitar duplicados como:

2026 / Semestre I
2026 / Semestre I

======================================================================
10. SECCIONES
======================================================================

Debe existir:

section

Campos mínimos:

- id.
- code.
- name.
- active.

Ejemplos:

A
B
C

Analiza las restricciones necesarias.

======================================================================
11. ESTUDIANTE
======================================================================

Debe existir:

student

Campos mínimos:

- id.
- student_code.
- first_names.
- last_names.
- birth_date.
- photo_path.
- active.
- created_at.
- updated_at.

student_code debe ser UNIQUE.

La fotografía NO debe almacenarse como BYTEA/BLOB.

Únicamente almacenar:

photo_path

Ejemplo:

students/2026/STU0001.jpg

La imagen física será administrada posteriormente por Symfony/filesystem.

No almacenar:

- contraseñas.
- datos médicos.
- documentos sensibles.
- información innecesaria.

======================================================================
12. ASIGNACIÓN DEL ESTUDIANTE A CARRERA Y PENSUM
======================================================================

No almacenar simplemente:

student.career_id

porque perderíamos trazabilidad curricular.

Debe existir:

student_program

con:

- id.
- student_id.
- career_id.
- curriculum_id.
- start_date.
- end_date.
- status.
- created_at.
- updated_at.

Debe poder responder:

¿En qué carrera estudia?
¿Con qué pensum inició?
¿Desde cuándo?
¿Está activo, finalizado o retirado?

Analiza las reglas de unicidad.

No permitir combinaciones incoherentes como:

student_program.career_id = Carrera A
curriculum_id perteneciente a Carrera B.

Esta inconsistencia debe impedirse o detectarse.

Explica cómo resolverla.

======================================================================
13. CICLO DEL ESTUDIANTE POR PERÍODO
======================================================================

Debe existir:

student_term

Debe relacionar:

student_program
academic_term
study_cycle
section

Campos mínimos:

- id.
- student_program_id.
- academic_term_id.
- study_cycle_id.
- section_id.
- status.
- created_at.
- updated_at.

Debe permitir responder:

En el primer semestre de 2026,
¿en qué ciclo curricular estaba el estudiante
y a qué sección pertenecía?

Debe impedir:

dos registros duplicados para el mismo:

student_program
+
academic_term

salvo que exista una razón debidamente justificada.

======================================================================
14. OFERTA DE CURSOS
======================================================================

Debe existir:

course_offering

Representa:

CURSO DEL PENSUM
+
PERÍODO REAL
+
SECCIÓN

Campos mínimos:

- id.
- academic_term_id.
- curriculum_course_id.
- section_id.
- active.
- created_at.
- updated_at.

Ejemplo:

Programación I
Pensum Computación 2026
Período 2026-I
Sección A

Debe analizarse unicidad sobre:

academic_term
+
curriculum_course
+
section

======================================================================
15. RESULTADO ACADÉMICO
======================================================================

Debe existir:

student_course_result

Debe relacionar como mínimo:

student_term
course_offering

Campos:

- id.
- student_term_id.
- course_offering_id.
- grade.
- graded_at.
- created_at.
- updated_at.

grade puede ser NULL si el resultado todavía está pendiente.

Cuando existe:

0 <= grade <= 100

Debe impedirse más de un resultado del mismo estudiante para la misma
oferta académica.

No almacenar directamente:

APPROVED
FAILED

como segunda fuente de verdad si puede calcularse.

El estado debe derivarse conceptualmente como:

grade IS NULL
=> PENDING

grade >= academic_policy.passing_grade
=> APPROVED

grade < academic_policy.passing_grade
=> FAILED

Debe utilizarse la política correspondiente al academic_term del resultado.

======================================================================
16. REPETICIÓN DE CURSOS
======================================================================

El modelo debe permitir este escenario:

2025-I
Programación I
nota = 55
FAILED

2026-I
Programación I
nota = 75
APPROVED

No debe destruirse el intento anterior.

Ambos deben permanecer en el historial.

Para efectos de avance de pensum:

el curso se considera aprobado si existe al menos un intento válido
con nota aprobatoria.

Debemos poder conocer:

- número de intentos.
- primera nota.
- última nota.
- mejor nota.
- fecha/período de aprobación.

No almacenar attempt_number manualmente si puede derivarse de manera segura.

Evalúa esta decisión.

======================================================================
17. INTEGRIDAD TRANSVERSAL
======================================================================

Debes analizar cómo garantizar que:

1.
El curriculum de student_program pertenece a la career indicada.

2.
El course_offering pertenece al mismo contexto curricular apropiado.

3.
student_term y course_offering pertenecen al mismo academic_term
cuando se registra una nota.

4.
La sección utilizada sea coherente.

5.
No se registre una nota para un estudiante de un pensum incompatible
con la oferta.

6.
No se permita una nota fuera de 0-100.

7.
No se creen duplicados lógicos.

8.
Las fechas effective_from/effective_to sean coherentes.

9.
start_date <= end_date.

10.
No existan IDs huérfanos.

Utiliza primero:

PRIMARY KEY
FOREIGN KEY
UNIQUE
CHECK
NOT NULL

antes de recurrir a triggers.

Usa triggers únicamente para reglas transversales que realmente no puedan
representarse mediante constraints convencionales.

Todo trigger debe:

- estar documentado.
- tener una sola responsabilidad.
- generar errores comprensibles.
- incluir prueba positiva y negativa.

======================================================================
18. TECNOLOGÍA SQL
======================================================================

Preferencias técnicas:

- PostgreSQL moderno.
- evitar sintaxis obsoleta.
- utilizar GENERATED ... AS IDENTITY en lugar de SERIAL/BIGSERIAL,
  salvo justificación.
- snake_case.
- nombres de tablas en singular.
- claves primarias denominadas id.
- TIMESTAMPTZ para timestamps operativos cuando corresponda.
- DATE para fechas académicas que no requieran hora.
- NUMERIC para notas.
- BOOLEAN para flags simples.
- COMMENT ON TABLE / COLUMN donde aporte valor.
- índices explícitamente justificados.

Evitar extensiones PostgreSQL no estándar salvo necesidad objetiva.

No requerir:

- pgTAP.
- PostGIS.
- btree_gist.
- extensiones externas.

salvo aprobación expresa.

El objetivo es que el script funcione en una instalación PostgreSQL estándar.

======================================================================
19. UPDATED_AT
======================================================================

Analiza cómo gestionar:

updated_at.

Si utilizas trigger común para actualizar automáticamente updated_at:

- crea una sola función reutilizable.
- úsala únicamente en tablas que lo necesiten.
- documenta por qué.
- prueba su funcionamiento.

No crear una función distinta por tabla.

======================================================================
20. BORRADOS
======================================================================

NO utilizar ON DELETE CASCADE indiscriminadamente.

Analiza individualmente las relaciones.

Ejemplo:

No debería ser posible eliminar una carrera que tenga historial académico
y destruir los resultados de estudiantes.

Favorecer:

RESTRICT / NO ACTION

para entidades históricas.

Utilizar active/status para desactivación lógica de catálogos cuando sea
necesario.

Documentar explícitamente cada política de borrado.

======================================================================
21. ÍNDICES
======================================================================

No agregar índices por intuición.

Diseñarlos según las consultas reales.

Debemos optimizar como mínimo:

- alumnos por carrera.
- alumno por student_code.
- historial por alumno.
- resultados por curso.
- resultados por carrera.
- resultados por sección.
- resultados por período.
- asignaciones por pensum.
- cursos por ciclo curricular.
- progreso de pensum.
- búsqueda de oferta académica.

Recordar que PostgreSQL NO crea automáticamente índices sobre todas las
foreign keys.

Debe justificarse cada índice creado.

======================================================================
22. VISTAS OBLIGATORIAS
======================================================================

Diseñar al menos las siguientes vistas.

--------------------------------------------------
22.1 vw_current_academic_policy
--------------------------------------------------

Debe devolver la política académica actualmente vigente.

Campos útiles:

policy_id
code
name
passing_grade
effective_from
effective_to

Debe manejar correctamente políticas históricas y futuras.

--------------------------------------------------
22.2 vw_student_results
--------------------------------------------------

Debe devolver una fila académicamente comprensible por resultado.

Como mínimo:

student_id
student_code
student_name
career_id
career
curriculum_id
curriculum
academic_year
academic_term
study_cycle
course_code
course
section
grade
passing_grade
status

status:

PENDING
APPROVED
FAILED

--------------------------------------------------
22.3 vw_student_curriculum_progress
--------------------------------------------------

Debe calcular por estudiante:

student_id
student_code
student_name
career
curriculum
required_courses
approved_courses
pending_courses
progress_percentage

La lógica debe considerar correctamente cursos repetidos.

Un curso requerido se considera aprobado si existe al menos un intento
aprobado.

No contar el mismo curso aprobado dos veces.

--------------------------------------------------
22.4 vw_student_cycle_progress
--------------------------------------------------

Debe calcular progreso por ciclo curricular.

Ejemplo:

Estudiante:
Ana López

Año 1 / Semestre I:
5 requeridos
5 aprobados
COMPLETED

Año 1 / Semestre II:
5 requeridos
4 aprobados
INCOMPLETE

Debe devolver:

student
career
curriculum
study_cycle
required_courses
approved_courses
pending_courses
completion_percentage
cycle_status

--------------------------------------------------
22.5 vw_grade_report
--------------------------------------------------

Debe servir como base para reportes de:

carrera
curso
sección
período

Debe incluir suficientes campos para filtrar por cualquiera de ellos.

--------------------------------------------------
22.6 vw_student_grade_entry
--------------------------------------------------

Vista orientada posteriormente al formulario Symfony de ingreso de notas.

Debe permitir, dado un estudiante/período, conocer:

- cursos que debe cursar.
- código.
- nombre.
- sección.
- resultado actual.
- nota.
- estado.

Debe incluir cursos esperados aun cuando todavía no exista student_course_result.

Esto significa que probablemente necesitará LEFT JOIN y no únicamente
consultar resultados existentes.

======================================================================
23. CONSULTAS DE NEGOCIO OBLIGATORIAS
======================================================================

El proyecto debe incluir consultas demostrativas para responder:

Q01.
Listar todos los alumnos de una carrera.

Q02.
Buscar un alumno por código.

Q03.
Mostrar ficha completa de un alumno.

Q04.
Mostrar historial completo de notas.

Q05.
Mostrar notas de una carrera.

Q06.
Mostrar notas de un curso.

Q07.
Mostrar notas de una sección.

Q08.
Mostrar notas de una carrera + curso + sección.

Q09.
Mostrar promedio de notas por carrera.

Q10.
Mostrar promedio por curso.

Q11.
Mostrar tasa de aprobación por carrera.

Q12.
Mostrar tasa de aprobación por curso.

Q13.
Mostrar tasa de aprobación por sección.

Q14.
Mostrar cursos reprobados por estudiante.

Q15.
Mostrar cursos pendientes de un estudiante.

Q16.
Mostrar cursos repetidos.

Q17.
Mostrar cantidad de intentos por curso/estudiante.

Q18.
Mostrar avance global del pensum.

Q19.
Mostrar avance por ciclo.

Q20.
Determinar si un ciclo curricular está completo.

Q21.
Mostrar estudiantes que todavía tienen cursos pendientes de ciclos anteriores.

Q22.
Mostrar estudiantes que han completado todo su pensum.

Q23.
Mostrar comparación entre períodos académicos.

Q24.
Mostrar resultados utilizando correctamente la política histórica.

Q25.
Mostrar listado esperado para pantalla de ingreso de notas.

Cada consulta debe incluir:

- propósito.
- SQL.
- breve explicación.
- parámetros esperados.
- resultado esperado usando el dataset de prueba.

======================================================================
24. DATASET DE PRUEBA: REGLA FUNDAMENTAL
======================================================================

NO generar:

Alumno 1
Alumno 2
Curso 1
Curso 2

NO utilizar notas uniformes como:

80
80
80
80

NO generar datos puramente aleatorios sin narrativa académica.

Los datos deben ser:

FICTICIOS
pero
REALISTAS
COHERENTES
REPRODUCIBLES
FUNCIONALMENTE ÚTILES.

IMPORTANTE:

No utilizar datos personales reales de estudiantes reales.

No copiar registros escolares reales.

Usar nombres ficticios plausibles del contexto guatemalteco/latinoamericano.

Los datos deben servir para probar reglas.

======================================================================
25. CARRERAS DE PRUEBA
======================================================================

Crear entre 3 y 4 carreras ficticias plausibles.

Ejemplos posibles:

- Bachillerato en Ciencias y Letras con Orientación en Computación.
- Bachillerato en Ciencias y Letras.
- Bachillerato con Orientación Comercial.
- Bachillerato Industrial.

IMPORTANTE:

No afirmar que los pensums simulados corresponden oficialmente al MINEDUC.

Deben etiquetarse como:

PENSUMS DEMOSTRATIVOS / ACADÉMICAMENTE PLAUSIBLES.

======================================================================
26. PENSUMS DE PRUEBA
======================================================================

Cada carrera debe tener un mini pensum coherente.

Ideal:

4 ciclos curriculares

equivalentes a:

Año 1 / Semestre I
Año 1 / Semestre II
Año 2 / Semestre I
Año 2 / Semestre II

Cada ciclo debe tener aproximadamente:

4 a 6 cursos.

Debe existir continuidad lógica.

Ejemplo:

Programación I
→ Programación II

Matemática I
→ Matemática II

Inglés I
→ Inglés II

No es obligatorio implementar prerequisitos salvo que propongas una
extensión claramente separada.

======================================================================
27. AÑOS Y PERÍODOS DE PRUEBA
======================================================================

Crear al menos:

2025
2026

con:

Semestre I
Semestre II

Debe existir suficiente historial para comprobar:

- avance.
- repetición.
- cambio de año.
- progreso curricular.

Puede crearse además una política futura de ejemplo:

2028 => passing_grade 70

pero NO debe afectar resultados de 2025/2026.

======================================================================
28. ESTUDIANTES DE PRUEBA
======================================================================

Crear un dataset suficientemente rico.

Objetivo sugerido:

40 a 80 estudiantes.

Distribuidos entre:

- diferentes carreras.
- diferentes secciones.
- diferentes ciclos.
- diferentes años/períodos.

student_code debe parecer consistente.

Ejemplo:

STU-2025-0001
STU-2026-0001

Los nombres deben parecer naturales y variados.

======================================================================
29. DISTRIBUCIÓN REALISTA DE NOTAS
======================================================================

Las notas deben permitir análisis reales.

No usar random() sin semilla o lógica reproducible.

Diseñar escenarios deliberados:

- estudiantes de alto rendimiento.
- estudiantes promedio.
- estudiantes con bajo rendimiento.
- cursos difíciles.
- cursos con alta aprobación.
- estudiantes con un curso reprobado.
- estudiantes con múltiples reprobaciones.
- estudiante que repite y luego aprueba.
- estudiante que repite y vuelve a reprobar.
- estudiantes con todos los cursos aprobados.
- estudiantes con resultados pendientes.
- estudiantes en diferentes ciclos.

La distribución debe contener valores alrededor del límite:

58
59
60
61
62
63

para probar correctamente la regla de 61.

Debe existir explícitamente:

nota 60 => FAILED
nota 61 => APPROVED

======================================================================
30. CASOS DE PRUEBA NOMBRADOS
======================================================================

Crear al menos los siguientes estudiantes/casos ficticios identificables
dentro del dataset.

CASO A — EXCELENCIA
Todos los cursos aprobados.
Promedio alto.

CASO B — LÍMITE DE APROBACIÓN
Debe incluir una nota exactamente 61.

CASO C — LÍMITE DE REPROBACIÓN
Debe incluir una nota exactamente 60.

CASO D — REPITENCIA EXITOSA
Primera nota < 61.
Segundo intento >= 61.

CASO E — REPITENCIA FALLIDA
Dos intentos < 61.

CASO F — CICLO COMPLETO
Todos los cursos requeridos de un ciclo aprobados.

CASO G — CICLO INCOMPLETO
Uno o más cursos pendientes/reprobados.

CASO H — ESTUDIANTE SIN NOTAS
Registrado, pero aún sin resultados.

CASO I — RESULTADOS PENDIENTES
Algunas materias con grade NULL.

CASO J — HISTORIAL MULTIANUAL
Resultados en 2025 y 2026.

El README debe indicar qué student_code corresponde a cada caso.

======================================================================
31. DATOS DE PRUEBA REPRODUCIBLES
======================================================================

Todos los inserts deben poder ejecutarse repetidamente sobre una base limpia
y producir exactamente el mismo dataset.

No depender de:

random()

sin control.

Si utilizas generación mediante arrays, CTE o generate_series,
el resultado debe seguir siendo semánticamente coherente.

No sacrificar legibilidad por generar muchos registros.

======================================================================
32. PRUEBAS POSITIVAS
======================================================================

Debes incluir pruebas que demuestren que:

- se puede crear carrera.
- se puede crear pensum.
- se puede asignar curso a ciclo.
- se puede crear estudiante.
- se puede asignar estudiante a pensum.
- se puede abrir año académico.
- se puede crear período.
- se puede asignar estudiante a período/ciclo/sección.
- se puede crear oferta académica.
- se puede registrar nota.
- 61 produce APPROVED.
- 60 produce FAILED.
- NULL produce PENDING.
- se puede repetir un curso.
- el segundo intento no elimina el primero.
- el progreso curricular no duplica aprobaciones.

======================================================================
33. PRUEBAS NEGATIVAS
======================================================================

Incluir pruebas que INTENTEN y deban FALLAR:

- nota -1.
- nota 101.
- estudiante duplicado por student_code.
- carrera duplicada por code.
- curso duplicado por code.
- mismo academic_term duplicado.
- mismo student_term duplicado.
- misma course_offering duplicada.
- misma nota duplicada para estudiante/oferta.
- curriculum asignado a carrera incorrecta.
- resultado registrado en período incompatible.
- fechas invertidas.
- FK inexistente.

Para cada prueba indicar:

EXPECTED FAILURE

y la constraint/regla que debe detenerla.

Las pruebas destructivas deben ejecutarse de forma segura,
preferiblemente en transacciones controladas.

======================================================================
34. PRUEBAS SEMÁNTICAS
======================================================================

Además de constraints, crear consultas de diagnóstico para detectar:

- políticas de fechas solapadas.
- curriculums incoherentes.
- estudiantes asignados a pensum incorrecto.
- resultados académicos incompatibles con período.
- cursos de pensum duplicados.
- notas sin contexto válido.
- estudiantes con progreso > 100%.
- cursos aprobados contados más de una vez.
- ciclos sin cursos.
- ofertas académicas sin alumnos.

======================================================================
35. EXPLAIN
======================================================================

Para al menos cinco consultas importantes:

- historial alumno.
- alumnos por carrera.
- reporte de notas.
- progreso del pensum.
- ingreso de notas.

mostrar:

EXPLAIN

o:

EXPLAIN ANALYZE

cuando el dataset permita una interpretación útil.

Explicar brevemente qué índices están siendo aprovechados.

No optimizar prematuramente consultas irrelevantes.

======================================================================
36. ARCHIVOS A ENTREGAR
======================================================================

No devolver un único bloque SQL gigantesco.

Separar el proyecto en:

database/
│
├── 00_reset.sql
├── 01_schema.sql
├── 02_constraints.sql
├── 03_indexes.sql
├── 04_functions_triggers.sql
├── 05_views.sql
├── 06_seed_catalogs.sql
├── 07_seed_curricula.sql
├── 08_seed_students.sql
├── 09_seed_academic_history.sql
├── 10_validation_queries.sql
├── 11_negative_tests.sql
├── 12_business_queries.sql
└── README.md

Si consideras que otra división es superior, proponla antes.

00_reset.sql debe ser claramente marcado como:

SOLO DESARROLLO / DESTRUCTIVO

Nunca debe ejecutarse accidentalmente en producción.

======================================================================
37. README OBLIGATORIO
======================================================================

README.md debe explicar:

1.
Objetivo de la base.

2.
Modelo conceptual.

3.
Orden exacto de ejecución de scripts.

4.
Versión de PostgreSQL objetivo.

5.
Listado de tablas.

6.
Listado de relaciones.

7.
Constraints importantes.

8.
Índices.

9.
Triggers existentes y justificación.

10.
Views.

11.
Datos de prueba.

12.
Casos A-J.

13.
Consultas principales.

14.
Cómo resetear el laboratorio.

15.
Limitaciones actuales.

16.
Decisiones pendientes.

17.
Cómo mapear posteriormente el modelo a Doctrine.

======================================================================
38. DICCIONARIO DE DATOS
======================================================================

Entregar una tabla por entidad indicando:

COLUMN
TYPE
NULLABLE
DEFAULT
PK/FK
UNIQUE
CHECK
DESCRIPTION

Ejemplo:

student_code
VARCHAR(...)
NO
-
-
YES
-
Código único del estudiante.

Debe incluir todas las tablas.

======================================================================
39. MATRIZ DE TRAZABILIDAD
======================================================================

Crear una matriz:

REQUERIMIENTO
→ TABLA
→ CAMPO
→ CONSTRAINT
→ VIEW/QUERY
→ TEST

Ejemplo:

"Nota mínima 61 configurable"

→ academic_policy.passing_grade
→ academic_term.academic_policy_id
→ vw_student_results
→ Test grade 60 / 61

Otro:

"Reporte de alumnos por carrera"

→ student
→ student_program
→ career
→ Q01

Esta matriz será crítica para revisar el proyecto.

======================================================================
40. MODELO ER
======================================================================

Entregar el modelo ER también en formato Mermaid.

Debe mostrar claramente:

cardinalidades
PK
FK
entidades principales

No saturar el diagrama con todos los atributos si lo vuelve ilegible.

Puede entregarse:

- ER conceptual.
- ER lógico.

======================================================================
41. COMPATIBILIDAD CON DOCTRINE
======================================================================

El diseño debe ser amigable para Doctrine ORM.

Evitar diseños innecesariamente difíciles de mapear.

Indicar para cada relación futura:

OneToMany
ManyToOne
OneToOne
ManyToMany

cuando corresponda.

Pero NO generar todavía código PHP.

Ejemplo:

StudentProgram
ManyToOne → Student

StudentProgram
ManyToOne → Career

StudentProgram
ManyToOne → Curriculum

======================================================================
42. NO SOBREINGENIERÍA
======================================================================

NO introducir sin una necesidad demostrable:

- microservicios.
- event sourcing.
- CQRS.
- particionamiento.
- replication.
- materialized views.
- UUID distribuidos.
- JSONB como sustituto del modelo relacional.
- stored procedures gigantes.
- docenas de triggers.
- auditoría CDC.
- Row Level Security.
- extensiones PostgreSQL externas.

El proyecto debe ser profesional pero explicable por estudiantes universitarios.

======================================================================
43. NO SIMPLIFICAR EN EXCESO
======================================================================

Tampoco aceptar:

student
course
grade

como modelo suficiente.

Debemos preservar:

- carrera.
- pensum.
- versionamiento de pensum.
- ciclo curricular.
- año lectivo.
- período académico.
- política académica.
- sección.
- oferta académica.
- historial.
- repetición.
- progreso.

======================================================================
44. PROTOCOLO DE DECISIONES
======================================================================

Si detectas una ambigüedad:

1. identifica la ambigüedad.
2. explica el impacto.
3. propone la solución recomendada.
4. indica alternativas.
5. si no bloquea el desarrollo, adopta una suposición explícita y continúa.
6. si puede comprometer integridad estructural, pregunta antes de continuar.

NO inventar silenciosamente reglas académicas.

======================================================================
45. PROTOCOLO DE HALLAZGOS
======================================================================

Si durante el diseño detectas que una decisión previa es incorrecta,
debes decirlo claramente.

Utiliza formato:

HALLAZGO
Problema:

IMPACTO
Qué podría romper:

RECOMENDACIÓN
Cambio propuesto:

MIGRACIÓN
Qué parte del modelo cambia:

No preservar una decisión incorrecta simplemente porque fue especificada
previamente.

======================================================================
46. CRITERIO DE ACEPTACIÓN DEL MODELO
======================================================================

El modelo NO se considera terminado solamente porque:

CREATE TABLE funciona.

Debe demostrar que puede responder correctamente:

A.
¿Qué carrera estudia Ana?

B.
¿Con qué pensum ingresó?

C.
¿Qué cursos debería aprobar?

D.
¿Qué cursos pertenecen al ciclo actual?

E.
¿Qué cursos ya aprobó?

F.
¿Qué cursos reprobó?

G.
¿Cuáles repitió?

H.
¿Cuántos intentos necesitó?

I.
¿Cuál es su porcentaje real de avance?

J.
¿Completó el ciclo?

K.
¿Qué nota mínima aplicaba cuando cursó una materia?

L.
¿Qué estudiantes están en una carrera?

M.
¿Qué notas existen para carrera + curso + sección?

N.
¿Qué materias debe mostrar Symfony en la pantalla de ingreso de notas?

O.
¿Qué alumnos tienen cursos pendientes de ciclos anteriores?

P.
¿Qué estudiantes terminaron todo su pensum?

======================================================================
47. VALIDACIÓN HISTÓRICA
======================================================================

Debe existir una prueba específica:

Supongamos:

POL-2026:
passing_grade = 61

Ana obtiene:
65

Debe ser:
APPROVED

Luego se crea:

POL-2028:
passing_grade = 70

La nota histórica de Ana del 2026 debe CONTINUAR:

APPROVED

No debe convertirse en:

FAILED

Esto es requisito obligatorio de integridad histórica.

======================================================================
48. FORMATO DE RESPUESTA DEL AGENTE
======================================================================

No entregar todo inmediatamente sin revisión.

Trabaja en fases.

FASE 1
Auditoría del requerimiento.

Entregar:

- entidades propuestas.
- relaciones.
- inconsistencias detectadas.
- decisiones adoptadas.
- decisiones pendientes.
- ER preliminar.

FASE 2
Diccionario de datos completo.

FASE 3
DDL y constraints.

FASE 4
Índices, funciones, triggers y views.

FASE 5
Dataset realista.

FASE 6
Queries y reportes.

FASE 7
Testing positivo/negativo.

FASE 8
Evaluación de integridad y performance.

FASE 9
Paquete final consolidado.

En cada fase debes indicar:

STATUS
PASS / NEEDS REVIEW / BLOCKED

RISKS
riesgos detectados.

NEXT
qué sigue.

======================================================================
49. AUTOCRÍTICA OBLIGATORIA
======================================================================

Antes de declarar el trabajo terminado debes atacarlo como auditor.

Pregúntate:

- ¿Hay redundancia?
- ¿Hay datos derivados almacenados innecesariamente?
- ¿Puede una FK quedar inconsistente semánticamente?
- ¿Una reforma académica rompe el pasado?
- ¿Una repetición de curso rompe el progreso?
- ¿Un NULL puede producir un falso aprobado?
- ¿Un JOIN puede duplicar estudiantes?
- ¿El porcentaje puede superar 100%?
- ¿Un curso repetido cuenta dos veces?
- ¿Puede un estudiante quedar sin pensum?
- ¿Puede un pensum contener dos veces el mismo curso?
- ¿Se puede asignar un pensum a carrera incorrecta?
- ¿Las queries del sistema son razonablemente indexables?
- ¿Doctrine podrá mapearlo sin hacks innecesarios?

Generar una sección final:

SELF-AUDIT

con:

PASS
WARNING
FAIL

por cada categoría.

======================================================================
50. RESTRICCIÓN SOBRE DATOS "REALES"
======================================================================

Los datos deben ser realistas, no reales.

No utilizar información personal identificable obtenida de estudiantes,
escuelas o registros reales.

No inventar que los pensums corresponden oficialmente a una institución
real.

Los datasets deben ser explícitamente:

DEMONSTRATION DATA
FICTIONAL
ACADEMICALLY PLAUSIBLE

La utilidad del dataset proviene de representar escenarios realistas,
no de utilizar personas reales.

======================================================================
51. RESULTADO FINAL ESPERADO
======================================================================

Al terminar debemos poseer una base PostgreSQL que pueda utilizarse como:

FUENTE DE VERDAD

para posteriormente construir:

Symfony
    ↓
Doctrine Entities
    ↓
Repositories
    ↓
Services
    ↓
Controllers
    ↓
Twig CRUD
    ↓
Reportes

El esquema debe permitir que el frontend se diseñe directamente sobre campos
y relaciones reales.

No queremos mockups que luego obliguen a rediseñar la base.

No queremos una base que luego obligue a deformar la aplicación.

Modelo de datos y aplicación deben poder converger naturalmente.

======================================================================
52. PRIMERA RESPUESTA QUE DEBES DAR
======================================================================

NO escribas todavía el SQL final.

Tu primera respuesta debe contener exclusivamente:

1. Evaluación del modelo propuesto.
2. Entidades definitivas propuestas.
3. Relaciones y cardinalidades.
4. Reglas que sí pueden protegerse con constraints.
5. Reglas que requerirían trigger o capa de aplicación.
6. Riesgos y puntos ciegos.
7. Propuesta ER preliminar.
8. Preguntas realmente bloqueantes, si existen.
9. Cambios que recomiendas antes de empezar el DDL.

Después esperaremos aprobación para generar el paquete SQL.