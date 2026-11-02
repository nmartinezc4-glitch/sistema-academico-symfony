# M06 — Perfil de estudiante (GET /alumnos/{id})

## Objetivo
Convertir S03 en una ficha de consulta operativa: identidad, programa vigente,
situación actual, avance, trayectoria, alertas y accesos rápidos, sin campos
ficticios ni lógica académica duplicada en Twig.

## Patrón visual adoptado
S03 utiliza un patrón distinto al listado S02:
- hero compacto con identidad y acciones;
- resumen académico horizontal;
- contexto de período integrado;
- tabs de navegación;
- avance curricular + situación actual;
- trayectoria + acciones rápidas/alertas;
- últimas cinco calificaciones.

La pantalla prioriza comprensión de la situación del estudiante y navegación a
expediente/notas/avance, no una imitación rígida de dashboard.

## Datos
Se mantienen las fuentes PostgreSQL certificadas ya integradas:
- `sis_aca_estudiante`
- `sis_aca_estudiante_programa`
- `sis_aca_pensum`
- `sis_aca_carrera`
- `sis_aca_estudiante_periodo`
- `sis_aca_periodo_academico`
- `sis_aca_anio_lectivo`
- `sis_aca_ciclo_curricular`
- `sis_aca_seccion`
- `sis_aca_vw_avance_pensum`
- `sis_aca_vw_resultado_estudiante`

## Correcciones de semántica
- El total de cursos usa `vm.required` de la vista de avance cuando está
  disponible; no suma reprobaciones al total del pensum.
- El donut representa directamente `vm.progress`, calculado por PostgreSQL.
- `vm.repeats` se muestra como **Reprobaciones históricas**, porque el valor
  actual cuenta resultados REPROBADO y no debe venderse como cursos únicos en
  repitencia.
- Si el período más reciente no está abierto, la UI lo denomina
  **Último período registrado** en vez de llamarlo período actual.
- Se eliminan del resumen principal correo, teléfono y ubicación `uiOnly`.

## Acciones
- Editar ficha
- Ingresar notas
- Ver expediente
- Ver avance curricular
- Documentos
- Gestionar inscripción permanece deshabilitado por alcance V1

## Validación requerida en UBU26SYMFONY
```bash
php -l src/Repository/StudentReadRepository.php
php bin/console lint:twig templates/student/show.html.twig
php bin/console lint:container
php bin/console cache:clear
curl -I http://127.0.0.1:8000/alumnos/1
curl -I http://127.0.0.1:8000/alumnos/99999
```

Esperado:
- ID válido → 200
- ID inexistente → 404
- sin regresiones en `/alumnos`
