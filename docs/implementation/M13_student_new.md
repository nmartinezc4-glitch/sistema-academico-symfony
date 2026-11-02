# M13 — Nuevo estudiante (FASE J)

## Objetivo
Convertir el alta de estudiante en operación real validada, respetando la
regla DB-first (la base de datos es el contrato, no se modifica su
estructura).

## Archivos modificados
- `src/Repository/StudentWriteRepository.php` (nuevo):
  `codeExists()`, `curriculumExists()`, `create()` transaccional.
- `src/Repository/CurriculumReadRepository.php`: `curricula()` ahora
  expone `careerId` para el selector dependiente.
- `src/Controller/Demo/StudentController.php`: `create()` GET/POST.
- `templates/student/new.html.twig`: bloque de errores del servidor.

## Flujo POST
1. Validar: código, nombres, apellidos, fecha válida, fecha inicio válida,
   pensum existente, código único.
2. Si falla: re-render con `errors[]` (notice rojo).
3. Si OK: INSERT en `sis_aca_estudiante` + INSERT en
   `sis_aca_estudiante_programa` dentro de una transacción DBAL; flash de
   éxito y redirect PRG a `/alumnos`.

## Contrato DB preservado
- Campos persistidos: código, nombres, apellidos, fecha de nacimiento,
   foto_ruta (NULL), est_activo=true; programa: est_id, pen_id,
   fecha_inicio, epr_estado=ACTIVO.
- `careerFilter` solo filtra pensums; no crea columna `career_id` fuera del
  modelo.
- Campos uiOnly del mockup (correo, teléfono, documento) NO se persisten.
- Rollback en caso de error de dominio (constraint/trigger).

## Pruebas
- `php -l` OK en los tres PHP. `lint:container` OK. `cache:clear` OK.
- POST vacío → notice "Revisa el formulario" (validaciones requeridas).
- POST con código duplicado `STU-2025-0001` → "Ya existe un estudiante con
  ese código."
- GET `/alumnos/nuevo` → 200; catálogos dinámicos desde PostgreSQL.
- No se insertó fila real en la base certificada durante la validación.

## Pendientes
- Verificación visual de éxito real requiere entorno de staging; ejecutar
  manualmente con datos de prueba.
