# M12 — Calendario académico y políticas

## Objetivo
Completar la configuración temporal del sistema para que ofertas,
inscripciones y notas puedan crearse sin depender exclusivamente de los seeds.

## Año lectivo
Ruta: `/anios/nuevo`.

Campos:
- año;
- nombre;
- fecha inicio;
- fecha fin.

Se crea con estado `PLANIFICADO`.

## Período académico
Ruta: `/periodos/nuevo`.

Campos:
- año lectivo;
- semestre I/II;
- fecha inicio;
- fecha fin.

La aplicación no selecciona manualmente `PER_POL_ID`.
El INSERT omite la columna y T3 asigna la política vigente en
`PER_FECHA_INICIO`.

Si no existe política aplicable, PostgreSQL responde SA301 y la UI lo explica.

## Estados
Transiciones expuestas:
- PLANIFICADO → ABIERTO;
- ABIERTO → CERRADO.

No se expone reapertura ordinaria de un período cerrado. La reapertura queda
reservada para correcciones excepcionales.

Abrir un período también cambia el año de PLANIFICADO a ABIERTO.

## Políticas académicas
Ruta: `/politicas-academicas/nueva`.

Campos:
- código;
- nombre;
- nota mínima;
- vigente desde.

T3 conserva SA301–SA305 y evita reformas retroactivas.

## Integración
`Año → Período → Oferta + Inscripción → Resultado`.

El dashboard deja de apuntar a un pensum fijo y abre el directorio
`/pensums`.

## Validación
```bash
php -l src/Controller/Demo/AcademicCalendarController.php
php -l src/Repository/AcademicCalendarReadRepository.php
php -l src/Repository/AcademicCalendarWriteRepository.php
php bin/console lint:twig templates/calendar/index.html.twig
php bin/console lint:twig templates/calendar/year_new.html.twig
php bin/console lint:twig templates/calendar/period_new.html.twig
php bin/console lint:twig templates/policy/new.html.twig
php bin/console lint:container
php bin/console cache:clear
```
