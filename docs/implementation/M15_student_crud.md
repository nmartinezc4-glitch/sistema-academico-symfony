# M15 — FASE J completa: editar y eliminar estudiantes

## Objetivo
Cerrar la FASE J del contrato (CRUD necesario) con UPDATE y DELETE reales,
bajo las reglas certificadas de la base (T4/SA401, checks de programa,
FK RESTRICT), sin alterar esquemas.

## Archivos modificados
- `src/Repository/StudentWriteRepository.php`:
  - `update()` transaccional (ficha personal + programa vigente);
  - `delete()` transaccional con pre-chequeo de historial;
  - `codeExists()` acepta `?int $exceptStudentId` (unicidad excluyendo el propio registro);
  - fix pdo_pgsql: `est_activo` se liga como `'true'/'false'` (el `false` de PHP se envía como `''` y PostgreSQL lo rechaza).
- `src/Repository/StudentReadRepository.php`: `program()` (programa vigente),
  `academicHistory()` (inscripciones y resultados).
- `src/Controller/Demo/StudentController.php`: `edit()` GET/POST y `delete()` POST.
- `templates/student/edit.html.twig` (nuevo): formulario estilo S04 prellenado
  (carrera/pensum con `dependent-select`, estado de programa, zona de peligro).
- `templates/student/show.html.twig`: acción "Editar ficha" en Acciones rápidas.

## Reglas aplicadas
- **T4/SA401:** si hay resultados, el pensum está congelado; se bloquea en el
  servidor con mensaje claro antes de llegar al trigger (el trigger queda como
  respaldo y su mensaje SA401 se traduce con `domainMessage()`).
- **`ck_epr_estado_fecha_fin`:** ACTIVO ⇒ `epr_fecha_fin = NULL`; cualquier otro
  estado ⇒ fecha fin (la existente o la de hoy). `est_activo = false` solo para RETIRADO.
- **`ux_epr_est_activo`:** se edita el programa ACTIVO (o el más reciente).
- **DELETE:** con inscripciones/resultados se rechaza con mensaje que sugiere
  "Retirado"; sin historial borra programa + estudiante en transacción
  (FK RESTRICT como respaldo).

## Verificación (HTTP real)
- GET `/alumnos/1/editar` → 200, prefill correcto (carrera, pensum, estado);
  id inexistente → 404.
- POST estado RETIRADO → `epr_fecha_fin = hoy`, `est_activo = f`; volver a
  ACTIVO → fecha fin NULL, `est_activo = t`.
- Código duplicado → error de validación; cambio de pensum con notas → error
  T4/SA401.
- DELETE con historial → flash danger ("…no puede eliminarse. Usa 'Retirado'"),
  estudiante intacto.
- DELETE sin historial: alta temporal STU-TEST-DELETE (id 49) → eliminado,
  45 estudiantes como al inicio.
- Dataset certificado: `E2_dataset_check.sql` **34/34 PASS** (huella intacta);
  `lint:twig` 44/44 · `lint:container` OK.

## Rutas nuevas
- `app_student_edit` GET|POST `/alumnos/{id}/editar`
- `app_student_delete` POST `/alumnos/{id}/eliminar`
