# M11 — Gestión académica: ofertas e inscripciones

## Objetivo
Conectar la configuración académica con la operación real del estudiante.

Cadena:
`Carrera → Pensum → PensumCurso → Oferta → EstudiantePeriodo → Resultado`.

## Ofertas
`/ofertas` deja de ser una tabla genérica y pasa a un módulo operativo.

Una oferta es:
- período académico;
- curso de un pensum;
- sección;
- estado activo.

La combinación está protegida por `UQ_OFE_PER_PCU_SEC`.

La creación se rechaza para períodos CERRADOS y solo admite:
- pensums activos;
- cursos activos;
- secciones activas.

## Inscripción del estudiante
Ruta:
`/alumnos/{id}/inscripcion`.

Utiliza el programa ACTIVO del estudiante y registra:
- período;
- ciclo curricular;
- sección;
- estado inicial INSCRITO.

La combinación programa + período está protegida por `UQ_EPE_EPR_PER`.

La UI permite inscripción en períodos PLANIFICADOS o ABIERTOS, pero no
CERRADOS. El ciclo debe pertenecer al pensum del estudiante.

## Relación con notas
Crear la inscripción no crea resultados.

Para ingreso de notas deben existir ofertas activas cuyo:
- período = período de EPE;
- pensum = pensum del EPR;
- sección = sección de EPE.

PostgreSQL conserva SA201–SA206 y evita resultados fuera de contexto.

## Validación
```bash
php -l src/Controller/Demo/AcademicManagementController.php
php -l src/Repository/AcademicOperationsReadRepository.php
php -l src/Repository/AcademicOperationsWriteRepository.php
php -l src/Controller/Demo/StudentController.php
php bin/console lint:twig templates/offering/index.html.twig
php bin/console lint:twig templates/offering/new.html.twig
php bin/console lint:twig templates/student/enrollment.html.twig
php bin/console lint:container
php bin/console cache:clear
```

Pruebas:
1. crear sección;
2. crear oferta en período abierto;
3. duplicar oferta → debe fallar;
4. crear inscripción del estudiante;
5. repetir mismo período → debe fallar;
6. abrir perfil y comprobar período/ciclo/sección;
7. abrir ingreso de notas y confirmar coincidencia de ofertas.
