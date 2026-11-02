# M14 — Ingreso de notas: persistencia real (FASE D escritura)

## Objetivo
Convertir el POST de `/evaluacion/notas` en una operación real sobre
`sis_aca_resultado_curso`, sin tocar el esquema y dejando que los triggers
certificados (T2/SA2xx) apliquen las reglas de dominio.

## Archivos modificados
- `src/Repository/StudentWriteRepository.php`: `saveGrades()` transaccional
  + `domainMessage()` (traduce SQLSTATE SA2xx a mensaje legible).
- `src/Repository/StudentReadRepository.php`: `gradeEntryRows()` expone
  `enrollmentId` (epe_id) y `offeringId`/`grade` casteados; nuevo
  `idFromCode()` para la caja de búsqueda.
- `src/Controller/Demo/GradeController.php`: POST real (validación → lote →
  PRG) o re-render conservando valores en error; `resolveStudentId()` acepta
  id numérico o `CÓDIGO · Nombre`.
- `templates/grade/entry.html.twig`: inputs con `name="grades[<ofe_id>]"`,
  valor preservado entre intentos, bloque `notice--danger` de errores.
- `templates/layout/app.html.twig`: render de flashes `danger`.

## Flujo POST
1. Filas editables = `sis_aca_vw_ingreso_notas` (autoridad: período ABIERTO,
   estudiante INSCRITO, oferta activa, sin aprobación previa).
2. Validación servidor: fila no editable / no numérica / fuera de rango
   (0–100) → `formErrors[]` y re-render 200 con los valores escritos.
3. Solo cambios efectivos (delta vs valor actual) entran al lote.
4. `saveGrades()` en una transacción DBAL:
   - con nota → UPDATE `res_nota` + `res_calificado_en`, o INSERT si no
     existe resultado;
   - nota vacía → UPDATE a NULL/NULL (respeta `ck_res_nota_fecha`);
   - cualquier violación de trigger → rollback total y mensaje
     `[SA2xx] …` en el notice rojo.
5. Éxito → flash `success` + redirect PRG.

## Reglas que siguen siendo de la BD (no de PHP)
SA204 período no abierto · SA205 estudiante no inscrito · SA206 oferta
inactiva · SA207 intento posterior a aprobación · SA208 corrección que
aprueba con intentos posteriores · SA201–SA203 coherencia de contexto.

## Verificación
- Update: POST `grades[168]=91.5` → fila persistida con timestamp; flash
  "1 nota guardada correctamente."
- Insert: fila `SIN_REGISTRO` editable → INSERT con `res_calificado_en`.
- Clear: valor vacío → `res_nota` y `res_calificado_en` en NULL.
- Rango 150 y fila no editable → notice rojo, sin escritura.
- Lote atómico: [cambio válido, fila en período cerrado] → rollback total
  (el cambio válido no se aplicó) y mensaje `[SA204] T2 PERIODO_NO_ABIERTO…`.
- Dataset certificado restaurado (res_id 487 → 89.00 / 2026-10-02 16:00
  Guatemala; res_id de prueba eliminado) y `E2_dataset_check.sql` **34/34
  PASS** con huella `4ad9de4736c9003431a4853a234229e7`.
- `lint:twig` 43/43 · `lint:container` OK.
