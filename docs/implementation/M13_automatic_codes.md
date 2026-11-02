# M13 — Códigos institucionales automáticos

## Decisión
Los códigos visibles dejan de ser capturados manualmente en las altas.

La base de datos mantiene sus restricciones UNIQUE y la aplicación genera
correlativos legibles dentro de la misma transacción del INSERT.

## Formatos para nuevas altas
- Estudiante: `STU-AAAA-NNNN`
- Carrera: `CAR-NNNN`
- Curso: `CUR-NNNN`
- Sección: `SEC-NNNN`
- Pensum: `PEN-AAAA-NNN`
- Política académica: `POL-AAAA-NN`

Los códigos históricos existentes no se reescriben.

## Concurrencia
`InstitutionalCodeGenerator` utiliza `pg_advisory_xact_lock` antes de
calcular el siguiente correlativo. Así dos solicitudes concurrentes no reservan
el mismo código.

La restricción UNIQUE de PostgreSQL continúa siendo la última barrera de
integridad.

## Entidades sin código manual
Año lectivo, período académico, oferta, inscripción, resultado y asignación
pensum-curso utilizan sus claves internas o claves naturales existentes; no se
agrega un código artificial a la interfaz.

## Validación
```bash
php -l src/Service/InstitutionalCodeGenerator.php
php -l src/Repository/StudentWriteRepository.php
php -l src/Repository/AcademicCatalogWriteRepository.php
php -l src/Repository/CurriculumWriteRepository.php
php -l src/Repository/AcademicCalendarWriteRepository.php
php -l src/Controller/Demo/CurriculumController.php
php -l src/Controller/Demo/AcademicCalendarController.php
php bin/console lint:twig templates/catalog/new.html.twig
php bin/console lint:twig templates/curriculum/new.html.twig
php bin/console lint:twig templates/policy/new.html.twig
php bin/console lint:container
php bin/console cache:clear
```
