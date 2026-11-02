# M14 — Reportes orientados a docentes y dirección

## Problema observado

La primera versión del módulo de reportes mezclaba necesidades de análisis con
detalles técnicos de implementación y opciones de exportación que no eran
necesarias para un usuario académico. También existían filtros visuales que no
modificaban los resultados y reportes con exportación desigual.

## Principio de UX

El usuario académico debe elegir **qué decisión necesita tomar**, aplicar pocos
filtros comprensibles y poder descargar exactamente lo que está viendo.

No se muestran nombres de tablas, vistas SQL, frameworks, motores de PDF,
"ViewModel", criterios "UI" ni hojas de metadatos técnicos.

## Necesidades cubiertas

### Seguimiento docente
- Notas por curso.
- Notas por sección.
- Avance curricular por estudiante.
- Pendientes y repitencias.

### Dirección y coordinación
- Alumnos por carrera.
- Notas por carrera.
- Avance curricular por ciclo.

No se implementa una vista "Mis cursos" porque el modelo actual no contiene
docentes ni asignaciones docente-curso. Agregarla sin ese contrato de datos
inventaría una capacidad que el sistema no posee.

## Filtros

Los filtros disponibles en cada reporte utilizan valores reales del conjunto de
datos. Se retiraron controles sin fuente de datos y se activaron los filtros de:
- avance por estudiante;
- avance por ciclo;
- pendientes y repitencias.

Los reportes de notas mantienen sus filtros de período, carrera, curso, sección
y estado según corresponda.

## Exportación Excel

Todos los siete reportes del centro pueden descargarse a Excel.

La exportación:
- conserva los filtros activos;
- usa una sola hoja llamada "Reporte";
- presenta un título y únicamente el contexto seleccionado por el usuario;
- utiliza encabezados académicos comprensibles;
- no incluye fuentes SQL, nombres de vistas, frameworks ni metadatos técnicos;
- congela encabezados y habilita filtros nativos de Excel.

## Paginación

Los reportes detallados de notas por carrera y por curso utilizan 25 registros
por página con navegación Anterior/Siguiente. Se eliminó la fila de decenas de
botones numerados que hacía difícil recorrer conjuntos grandes.

## Validación sugerida

```bash
php -l src/Repository/ReportReadRepository.php
php -l src/Controller/Demo/ExportController.php
php -l src/Service/Export/SimpleReportXlsxWriter.php

php bin/console lint:twig templates/report
php bin/console lint:container
php bin/console cache:clear
```

Pruebas funcionales:
1. Aplicar un filtro en cada uno de los siete reportes y confirmar que cambian
   los KPI y el detalle.
2. Descargar Excel con el filtro activo y comparar el contenido con la pantalla.
3. Confirmar que el archivo no contiene nombres de tablas, vistas SQL ni
   terminología de implementación.
4. Probar navegación Anterior/Siguiente en notas por carrera y notas por curso.
