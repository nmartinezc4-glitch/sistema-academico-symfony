# M10 — Ingreso de notas

## Objetivo
Convertir S06 en un flujo operativo real:

1. seleccionar estudiante;
2. seleccionar una inscripción/período del estudiante;
3. visualizar exactamente las filas de esa inscripción;
4. editar únicamente filas autorizadas por `SIS_ACA_VW_INGRESO_NOTAS`;
5. guardar mediante las reglas de PostgreSQL.

## Correcciones estructurales
Se eliminó el comportamiento anterior que abría por defecto al estudiante ID 1.

`/evaluacion/notas` sin parámetro muestra ahora un selector real de estudiantes
con inscripción académica. Los accesos desde perfil/expediente siguen pudiendo
usar `?student=<id>`.

## Inscripción seleccionada
La pantalla ya no mezcla cursos de todos los períodos del estudiante.

Se añadió:
- `gradeEntryEnrollments(studentId)`;
- selección explícita por `?enrollment=<EPE_ID>`;
- `gradeEntryRows(studentId, enrollmentId)`.

Cada POST conserva estudiante + inscripción y valida que la inscripción
pertenezca al estudiante.

## UI eliminada
Se retiraron:
- filtros de grupo UI-only;
- "bimestre" ficticio;
- búsqueda de curso que no filtraba backend;
- tabs con `href="#"`;
- sección duplicada "Ya aprobados";
- cómputos de aprobación en Twig.

## Reglas
La interfaz no usa 61 ni calcula estado. Consume:
- `ING_ESTADO`;
- `ING_EDITABLE`;
- `ING_MOTIVO_BLOQUEO`.

La base conserva SA204/SA205/SA206/SA207/SA208.

## Estados
- período ABIERTO;
- período CERRADO (consulta);
- inscripción distinta de INSCRITO;
- sin inscripción;
- sin oferta;
- oferta inactiva;
- ya aprobado;
- nota pendiente;
- repitencia / ciclo anterior.

## Validación
```bash
php -l src/Controller/Demo/GradeController.php
php -l src/Repository/StudentReadRepository.php
php bin/console lint:twig templates/grade/index.html.twig
php bin/console lint:twig templates/grade/entry.html.twig
php bin/console lint:container
php bin/console cache:clear
```

Pruebas recomendadas:
- abrir /evaluacion/notas sin student;
- buscar por carné/nombre;
- seleccionar estudiante con varios períodos;
- cambiar inscripción;
- período cerrado → inputs bloqueados;
- período abierto → solo filas editable=true;
- guardar una nota y verificar expediente;
- limpiar una nota;
- estudiante sin inscripción.
