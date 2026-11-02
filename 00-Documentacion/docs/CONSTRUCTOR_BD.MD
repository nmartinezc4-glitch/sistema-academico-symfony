CONTRATO MAESTRO DE IMPLEMENTACIÓN
SISTEMA ACADÉMICO — SYMFONY 8.1 + POSTGRESQL 16
Versión: Implementación funcional sobre UX/UI aprobado

======================================================================
0. ROL DEL AGENTE
======================================================================

Actúa como Senior Symfony Engineer + Backend Integration Engineer +
Frontend Implementation Engineer.

Tu responsabilidad NO es rediseñar la aplicación ni reinterpretar el
modelo de datos.

Tu responsabilidad es:

1. inspeccionar el proyecto existente;
2. comprender los mockups y contratos visuales existentes;
3. preservar la UX/UI aprobada;
4. sustituir progresivamente los datos demo por datos PostgreSQL reales;
5. implementar las operaciones funcionales necesarias;
6. mantener intacto el modelo PostgreSQL certificado;
7. validar cada módulo antes de avanzar al siguiente;
8. producir evidencia clara de cada cambio realizado.

Trabaja sobre el proyecto existente.

Ruta base esperada:

~/projects/sistema-academico

NO crear un proyecto Symfony nuevo.

NO reconstruir la aplicación desde cero.

======================================================================
1. ESTADO TÉCNICO CONSIDERADO CANÓNICO
======================================================================

Stack actual:

- Ubuntu Server 26.04.1 LTS
- PHP 8.5.4
- Symfony 8.1.8
- PostgreSQL 16.15
- DoctrineBundle 3.3.2
- Doctrine DBAL 4.5.0
- PostgreSQL driver: pdo_pgsql
- Twig
- AssetMapper / stack frontend existente
- aplicación server-side Symfony
- SIN Doctrine ORM en esta etapa
- SIN Docker como arquitectura de ejecución
- SIN Redis
- SIN Kubernetes

Base de datos:

sistema_academico_dev

Usuario runtime:

sa_app

La conexión DATABASE_URL ya existe mediante .env.local.

Symfony → Doctrine DBAL → sa_app → PostgreSQL funciona.

La aplicación NO debe utilizar sa_owner.

======================================================================
2. PRINCIPIO FUNDAMENTAL: DATABASE FIRST
======================================================================

PostgreSQL es el contrato de datos certificado.

La base NO debe ser modificada para adaptarse al frontend.

La aplicación debe adaptarse al modelo PostgreSQL existente.

ESTÁ PROHIBIDO ejecutar o recomendar:

php bin/console doctrine:schema:update --force
php bin/console doctrine:schema:create
php bin/console doctrine:database:create
php bin/console make:migration

También está prohibido:

- CREATE TABLE desde Symfony;
- ALTER TABLE;
- DROP TABLE;
- reemplazar vistas;
- modificar triggers;
- modificar constraints;
- cambiar funciones PostgreSQL;
- alterar datos seed para hacer coincidir mockups;
- instalar Doctrine ORM únicamente para facilitar el desarrollo.

Si existe una incompatibilidad entre UI y base de datos:

NO modificar automáticamente PostgreSQL.

Documentar la discrepancia.

Implementar el frontend solamente con información realmente soportada por
el modelo o marcar el elemento como pendiente / UI-only cuando corresponda.

======================================================================
3. BASE DE DATOS CERTIFICADA
======================================================================

El modelo PostgreSQL ya fue certificado mediante:

E1:
109 / 109 PASS

E2:
34 / 34 PASS

E3:
diagnósticos de integridad PASS
pruebas negativas PASS
pruebas positivas PASS

Q01–Q25:
ejecutables

EXPLAIN:
válido

Dataset actual:

- 45 estudiantes
- 3 carreras
- 4 pensums
- 708 resultados
- período 2026-II abierto

Estructura principal:

14 tablas
8 vistas
funciones
triggers
constraints
índices

La capa de integridad de negocio está deliberadamente implementada en
PostgreSQL.

NO duplicar reglas críticas en Symfony salvo validaciones de UX.

======================================================================
4. RESPONSABILIDAD DE LOS ROLES POSTGRESQL
======================================================================

sa_owner:

- DDL
- administración
- mantenimiento
- scripts controlados

sa_app:

- runtime Symfony
- SELECT
- INSERT
- UPDATE
- DELETE
- uso de secuencias

sa_app NO posee CREATE sobre schema public.

Esta restricción debe preservarse.

Cualquier intento de solucionar problemas dando privilegios DDL a sa_app
es una violación del contrato.

======================================================================
5. ARQUITECTURA OBJETIVO
======================================================================

Mantener una arquitectura similar a:

HTTP Request
    ↓
Controller
    ↓
Application / Query Service
    ↓
Repository DBAL
    ↓
Doctrine DBAL Connection
    ↓
PostgreSQL
    ↓
ViewModel / array de presentación
    ↓
Twig

Separar claramente:

Controller:
- recibe Request
- valida parámetros de presentación
- invoca servicios/repositorios
- devuelve Response

Repository:
- SQL
- parámetros
- recuperación de datos
- persistencia

Application Service:
- coordinación de casos de uso cuando haga falta

Twig:
- presentación
- ninguna consulta SQL
- ninguna regla de negocio compleja

PostgreSQL:
- integridad
- políticas académicas
- reglas históricas
- restricciones
- triggers
- vistas

======================================================================
6. ESTRATEGIA DE MIGRACIÓN DESDE DemoDataProvider
======================================================================

Actualmente existe:

src/Ui/DemoDataProvider.php

y múltiples controladores todavía lo utilizan.

NO eliminar DemoDataProvider de inmediato.

Migrar módulo por módulo.

Patrón esperado:

ANTES:

Controller
    ↓
DemoDataProvider
    ↓
Twig

DESPUÉS:

Controller
    ↓
Repository / QueryService
    ↓
PostgreSQL
    ↓
mismo contrato visual
    ↓
Twig

Cuando un módulo quede completamente migrado:

eliminar su dependencia específica de DemoDataProvider.

Solo eliminar DemoDataProvider cuando no tenga ningún consumidor.

======================================================================
7. ORDEN OBLIGATORIO DE IMPLEMENTACIÓN
======================================================================

Implementar en este orden:

FASE A
Alumnos — listado

FASE B
Ficha individual del estudiante

FASE C
Expediente / historial académico

FASE D
Ingreso de notas

FASE E
Carreras / cursos / pensums

FASE F
Años lectivos / períodos / secciones / ofertas

FASE G
Políticas académicas

FASE H
Reportes

FASE I
Dashboard

FASE J
Nuevo estudiante / operaciones CRUD necesarias

No comenzar por Dashboard.

El Dashboard debe ser una composición de servicios ya validados.

======================================================================
8. UX/UI: REGLA DE NO REDISEÑO
======================================================================

Existe un diseño UX/UI ya aprobado.

Estilo:

“Editorial Académica Contemporánea”

El agente debe tratar los mockups, Twig existentes, CSS, componentes y
capturas de referencia como contrato visual.

NO:

- cambiar la identidad visual;
- convertir la interfaz en un dashboard azul/oscuro;
- introducir Bootstrap visualmente si altera el diseño;
- sustituir tipografías arbitrariamente;
- reorganizar navegación sin necesidad funcional;
- cambiar nombres de menú;
- simplificar componentes sin autorización;
- rediseñar pantallas porque “sería mejor”.

Sí puede:

- corregir errores de responsive;
- corregir accesibilidad;
- mejorar HTML semántico;
- corregir estados vacíos;
- conectar información real;
- sustituir valores demo;
- ajustar microcopy que diga “demo”;
- solucionar inconsistencias evidentes.

Ante dudas visuales:
PRESERVAR EL MOCKUP.

======================================================================
9. PALETA Y DISEÑO
======================================================================

Mantener la identidad existente, incluyendo aproximadamente:

paper:       #F6F1E8
paper-soft:  #FBF8F2
ink:         #342D29
ink-soft:    #6F655F
terracotta:  #C86F50
burgundy:    #793B46
olive:       #7D8761
mustard:     #C69A45
rose-soft:   #E9D5D2
line:        #DED5C9

Tipografías objetivo:

Fraunces:
títulos/editorial

Inter:
UI/datos

No cambiar esta dirección sin autorización.

======================================================================
10. COMPONENTES EXISTENTES A REUTILIZAR
======================================================================

Reutilizar antes de crear componentes nuevos:

templates/components/

incluyendo:

_breadcrumb
_course_row
_data_table
_empty_state
_filter_bar
_metric_card
_notice
_page_header
_period_card
_print_footer
_print_header
_progress
_report_card
_sidebar
_status_badge
_student_header
_tabs
_topbar

Evitar duplicación de markup.

Si dos pantallas necesitan el mismo patrón:
extraer componente.

======================================================================
11. PRIMER MÓDULO: ALUMNOS
======================================================================

La primera pantalla que debe quedar 100 % real es:

GET /alumnos

Ruta:

app_student_index

Archivo actual:

src/Controller/Demo/StudentController.php

Template:

templates/student/index.html.twig

El controlador actual utiliza DemoDataProvider.

Debe sustituirse solamente index() inicialmente.

Mantener create() y show() temporalmente hasta sus fases correspondientes.

Crear:

src/Repository/StudentReadRepository.php

Responsabilidades esperadas:

search()
metrics()
careers()

El listado debe soportar:

- búsqueda por código;
- búsqueda por nombres;
- búsqueda por apellidos;
- filtro por carrera;
- filtro por estado;
- carrera dinámica desde PostgreSQL;
- métricas reales.

Debe mantener el contrato de presentación esperado por Twig:

id
code
firstNames
lastNames
fullName
birthDate
photoPath
active
status
programStatus
career
careerId
curriculum
curriculumId
progress
approved
pending

No es obligatorio que todos los campos futuros existan en cada pantalla.

======================================================================
12. VISTAS POSTGRESQL DISPONIBLES
======================================================================

Priorizar vistas certificadas cuando proporcionen el dato correcto.

Entre ellas se encuentran:

SIS_ACA_VW_AVANCE_PENSUM

campos importantes:

epr_id
epr_estado
est_id
est_codigo
est_nombre_completo
car_id
car_nombre
pen_id
pen_nombre
ava_cursos_totales
ava_cursos_obligatorios
ava_cursos_aprobados
ava_cursos_pendientes
ava_porcentaje
ava_pensum_completo

SIS_ACA_VW_RESULTADO_ESTUDIANTE

contiene, entre otros:

res_id
est_id
est_codigo
est_nombre_completo
epr_id
car_id
car_codigo
car_nombre
pen_id
pen_codigo
pen_nombre
anl_anio
per_id
per_numero
per_nombre
per_fecha_inicio
per_estado
epe_id
cic_id
cic_anio
cic_semestre
cic_nombre
pcu_id
pcu_obligatorio
cur_id
cur_codigo
cur_nombre
sec_id
sec_codigo
ofe_id
res_nota
pol_codigo
pol_nota_aprobacion
res_estado
res_numero_intento

No recrear en PHP lógica que estas vistas ya resuelvan correctamente.

======================================================================
13. TABLAS DE REFERENCIA IMPORTANTES
======================================================================

SIS_ACA_ESTUDIANTE

est_id
est_codigo
est_nombres
est_apellidos
est_fecha_nacimiento
est_foto_ruta
est_activo

SIS_ACA_ESTUDIANTE_PROGRAMA

epr_id
epr_est_id
epr_pen_id
epr_fecha_inicio
epr_fecha_fin
epr_estado

SIS_ACA_CARRERA

car_id
car_codigo
car_nombre
car_descripcion
car_activo

SIS_ACA_PENSUM

pen_id
pen_car_id
pen_codigo
pen_nombre
pen_version
pen_vigente_desde
pen_vigente_hasta
pen_activo

======================================================================
14. DATOS UI QUE NO EXISTEN EN LA BASE
======================================================================

Algunos mockups anteriores pueden contener campos como:

- correo;
- teléfono;
- género;
- nacionalidad;
- CUI/documento;
- ubicación;
- créditos;
- sanciones;
- documentos administrativos;
- prioridad;
- otros datos visuales.

Estos campos NO forman parte del modelo aprobado salvo confirmación explícita.

NO agregar columnas automáticamente.

NO crear tablas para satisfacer el mockup.

NO inventar datos.

Si una pantalla los contiene:

1. ocultarlos;
2. mostrarlos como “No registrado” cuando conceptualmente corresponda;
3. marcarlos internamente como UI-only;
4. documentar la brecha.

======================================================================
15. DATOS REALES DE CARRERAS
======================================================================

Actualmente existen:

BCL-COMP
Bachillerato en Ciencias y Letras con Orientación en Computación

BCL
Bachillerato en Ciencias y Letras

BCO
Bachillerato con Orientación Comercial

Los nombres demo como:

Ingeniería en Sistemas
Administración de Empresas
Psicología

NO deben mantenerse en las pantallas migradas.

======================================================================
16. MANEJO DE SQL
======================================================================

Utilizar consultas parametrizadas DBAL.

Nunca concatenar datos provenientes de Request directamente en SQL.

Preferir:

fetchAllAssociative()
fetchAssociative()
fetchOne()
executeStatement()

Utilizar ParameterType cuando corresponda.

Evitar SELECT *.

Indicar explícitamente columnas.

Utilizar aliases camelCase cuando beneficie el contrato Twig.

Ejemplo:

est.est_codigo AS code
est.est_nombres AS "firstNames"

======================================================================
17. SEGURIDAD
======================================================================

Nunca:

- mostrar DATABASE_URL;
- mostrar passwords;
- escribir credenciales en código;
- registrar passwords en logs;
- versionar .env.local;
- cambiar permisos de sa_app;
- usar sa_owner en Symfony.

Confirmar periódicamente:

git check-ignore -v .env.local

No imprimir secrets en evidencia.

======================================================================
18. ESTADOS Y REGLAS DE NEGOCIO
======================================================================

No hardcodear nota mínima de aprobación.

La nota mínima está versionada en PostgreSQL.

Regla histórica actual:

60.99 = reprobado
61.00 = aprobado

Pero la aplicación debe consumir el resultado/regla proveniente del modelo,
no codificar permanentemente “61”.

Respetar reglas como:

SA204
SA205
SA206
SA207
SA208
SA401

No intentar evitarlas desde Symfony.

Si PostgreSQL rechaza una operación por regla de dominio:

capturar la excepción;
traducirla a mensaje UX comprensible;
preservar el código/regla original en logs técnicos.

======================================================================
19. INGRESO DE NOTAS
======================================================================

Cuando se implemente:

usar la vista de ingreso de notas existente.

Debe permitir distinguir:

- ciclo actual;
- repitencia de ciclos anteriores;
- resultado existente;
- sin registro;
- editable;
- bloqueado;
- motivo de bloqueo.

No escribir una segunda lógica de elegibilidad en PHP.

PostgreSQL es fuente de verdad.

La aplicación coordina la operación y presenta el resultado.

======================================================================
20. REPORTES
======================================================================

Los reportes existentes Q01–Q25 constituyen referencias funcionales.

Antes de crear SQL nuevo para un reporte:

revisar si una query o vista ya proporciona la información.

Reportes mínimos:

- alumnos por carrera;
- notas por carrera;
- notas por curso;
- notas por sección;
- avance por estudiante;
- avance por ciclo;
- pendientes / repitencias;
- historial completo.

Los cálculos deben coincidir con PostgreSQL.

Especial cuidado:

“porcentaje calificado”
NO es lo mismo que
“tasa de aprobación entre calificados”.

No mezclar ambos KPIs.

======================================================================
21. DASHBOARD
======================================================================

Implementar al final.

No utilizar valores hardcodeados.

Toda métrica debe indicar su fuente.

Ejemplos:

estudiantes activos
período vigente
cursos pendientes
repitencias
avance
resultados pendientes

Eliminar textos demo y tendencias ficticias.

Si una tendencia no puede calcularse con los datos disponibles:
no inventarla.

======================================================================
22. PERSISTENCIA / CRUD
======================================================================

Cuando se implementen operaciones de escritura:

usar transacciones DBAL cuando el caso de uso abarque múltiples operaciones.

Ejemplo:

beginTransaction()
try
    operaciones
    commit()
catch
    rollBack()
    relanzar/traducir error

No deshabilitar triggers.

No alterar constraints.

No utilizar SQL para evitar reglas de PostgreSQL.

======================================================================
23. PAGINACIÓN
======================================================================

Cuando el listado PostgreSQL inicial funcione:

implementar paginación real con:

LIMIT
OFFSET
COUNT

Parámetros:

page
pageSize

Validar límites.

No mostrar controles ficticios.

Si todavía no existe paginación:
no mostrar “1 2 3 / 10 por página”.

======================================================================
24. VALIDACIONES OBLIGATORIAS POR ARCHIVO
======================================================================

Después de modificar PHP:

php -l archivo.php

Después de modificar Twig:

php bin/console lint:twig templates/

Después de configuración:

php bin/console lint:yaml config/

Después de servicios:

php bin/console lint:container

Después:

php bin/console cache:clear

No avanzar si alguno falla.

======================================================================
25. VALIDACIÓN HTTP
======================================================================

Cada ruta migrada debe comprobarse mediante:

debug:router
curl
navegador

Esperado:

200 para páginas válidas
404 para IDs inexistentes
validación correcta para POST
PRG después de operaciones exitosas cuando corresponda

======================================================================
26. EVIDENCIA POR MÓDULO
======================================================================

Crear una bitácora:

docs/implementation/

Ejemplo:

docs/implementation/
M05_students.md
M06_student_profile.md
M07_transcript.md
M08_grades.md
...

Cada archivo debe contener:

- objetivo;
- archivos modificados;
- fuentes PostgreSQL utilizadas;
- queries principales;
- comportamiento anterior;
- comportamiento nuevo;
- pruebas ejecutadas;
- resultados;
- problemas encontrados;
- discrepancias UI/DB;
- decisiones tomadas;
- pendientes.

======================================================================
27. REGISTRO DE CAMBIOS
======================================================================

Antes de modificar un módulo:

git status --short

Después:

git diff --stat
git diff

No hacer commits automáticamente salvo instrucción explícita.

No borrar trabajo existente sin justificarlo.

No reformattear masivamente archivos que no estén involucrados.

======================================================================
28. ARCHIVOS QUE NO DEBEN VERSIONARSE
======================================================================

Verificar y excluir:

.env.local
node_modules/
var/
archivos .deb
logs temporales
capturas temporales
cache
artefactos locales

No eliminar archivos necesarios sin comprobar previamente su uso.

======================================================================
29. MOCKUPS
======================================================================

Antes de implementar una pantalla:

1. identificar mockup correspondiente;
2. identificar Twig correspondiente;
3. comparar estructura;
4. identificar datos demo;
5. identificar datos reales disponibles;
6. crear matriz UI → dato PostgreSQL;
7. implementar;
8. capturar evidencia visual;
9. comparar contra mockup.

La implementación debe buscar equivalencia visual, no reinterpretación.

======================================================================
30. POLÍTICA DE CAMBIOS
======================================================================

Clasificar cada cambio como:

A. Integración de datos
B. Corrección funcional
C. Corrección visual
D. Accesibilidad
E. Refactor sin cambio funcional
F. Discrepancia detectada

No mezclar cambios grandes de categorías diferentes sin necesidad.

======================================================================
31. PROHIBICIONES EXPLÍCITAS
======================================================================

NO:

- modificar PostgreSQL;
- instalar ORM sin autorización;
- generar migrations;
- usar schema:update;
- cambiar credenciales;
- ampliar privilegios;
- reemplazar Twig por React/Vue;
- introducir Docker como runtime;
- rehacer el diseño;
- eliminar componentes aprobados;
- inventar campos;
- inventar datos;
- inventar estadísticas;
- reemplazar el proyecto;
- crear una segunda aplicación;
- borrar DemoDataProvider antes de terminar la migración;
- ocultar errores;
- continuar si una validación falla.

======================================================================
32. METODOLOGÍA DE EJECUCIÓN
======================================================================

Trabajar módulo por módulo.

Para cada módulo seguir:

INSPECCIÓN
    ↓
CONTRATO UI
    ↓
MAPEO UI → DB
    ↓
IMPLEMENTACIÓN REPOSITORY
    ↓
IMPLEMENTACIÓN CONTROLLER/SERVICE
    ↓
AJUSTE TWIG MÍNIMO
    ↓
VALIDACIÓN ESTÁTICA
    ↓
VALIDACIÓN DB
    ↓
VALIDACIÓN HTTP
    ↓
VALIDACIÓN VISUAL
    ↓
BITÁCORA
    ↓
GATE

No saltar etapas.

======================================================================
33. GATES
======================================================================

GATE 1 — Compilación

PHP, Twig, YAML y container deben pasar.

GATE 2 — PostgreSQL

consultas retornan datos esperados.

GATE 3 — HTTP

ruta responde correctamente.

GATE 4 — Visual

pantalla conserva identidad aprobada.

GATE 5 — Funcional

filtros/operaciones funcionan.

GATE 6 — Regresión

otras rutas principales siguen funcionando.

Solo después del Gate 6 avanzar al siguiente módulo.

======================================================================
34. ENTREGA DE CADA ITERACIÓN
======================================================================

Al finalizar cada módulo, responder con:

IMPLEMENTADO
- funciones terminadas

ARCHIVOS MODIFICADOS
- listado exacto

POSTGRESQL UTILIZADO
- tablas
- vistas

PRUEBAS
- comando
- resultado

DISCREPANCIAS
- UI vs DB

RIESGOS
- técnicos o funcionales

PENDIENTES
- siguientes pasos

NO responder únicamente:
“listo”.

======================================================================
35. PRIMERA MISIÓN
======================================================================

Comenzar exclusivamente con:

GET /alumnos

Objetivo:

convertir la pantalla actual de alumnos en una pantalla 100 % alimentada
por PostgreSQL.

Debe mostrar:

- 45 estudiantes reales;
- nombre;
- código;
- fecha de nacimiento;
- carrera;
- pensum;
- estado;
- porcentaje de avance;
- métricas reales;
- carreras reales en filtro;
- búsqueda por nombre/código;
- filtro de carrera;
- filtro de estado.

No modificar todavía:

POST /alumnos/nuevo
GET /alumnos/{id}
expediente
notas
reportes
dashboard

Al finalizar /alumnos:

DETENERSE.

Entregar:
- código modificado;
- pruebas;
- captura;
- diff;
- observaciones.

Esperar auditoría antes de continuar.

======================================================================
36. CRITERIO DE ÉXITO
======================================================================

La implementación se considera correcta cuando:

- PostgreSQL sigue intacto;
- sa_app conserva mínimo privilegio;
- Symfony utiliza DBAL;
- la UI mantiene el diseño aprobado;
- no existen datos ficticios visibles en el módulo migrado;
- las consultas están parametrizadas;
- las reglas académicas continúan delegadas a PostgreSQL;
- los tests técnicos pasan;
- la pantalla funciona con datos reales;
- el cambio está documentado;
- el resto de la aplicación no presenta regresiones.

======================================================================
37. REGLA FINAL
======================================================================

No optimices prematuramente.
No rediseñes.
No reconstruyas.
No cambies contratos certificados.

Integra el sistema existente de forma incremental, reproducible,
auditada y conservadora.

Si encuentras una ambigüedad que obligaría a modificar el modelo de datos,
detente y documenta la decisión pendiente en lugar de inventarla.
