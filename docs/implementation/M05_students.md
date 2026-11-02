# M05 — Alumnos (GET /alumnos)

## Objetivo
Convertir S02 en un listado PostgreSQL real, consistente con el mockup aprobado,
sin duplicar estudiantes cuando existe historial de programas y sin paginación
simulada.

## Implementación actual

### Datos
`StudentReadRepository` construye un dataset de lectura con:
- un único programa por estudiante: ACTIVO primero; si no existe, el más reciente;
- carrera y pensum del programa seleccionado;
- año de ingreso derivado del primer programa;
- avance desde `sis_aca_vw_avance_pensum`;
- conteos académicos desde las vistas certificadas.

### Filtros
Todos son GET y parametrizados:
- búsqueda por código/nombres/apellidos;
- carrera;
- pensum;
- estado;
- año de ingreso;
- rango de avance 0–100;
- ordenamiento permitido por whitelist.

### Paginación
Paginación real de servidor:
- `COUNT(*)` filtrado;
- `LIMIT/OFFSET`;
- page/per_page;
- tamaños 10/25/50 mediante `App\Ui\Paginator`;
- `templates/components/_pagination.html.twig`.

Twig ya no ordena ni pagina arrays.

## KPIs
- total de estudiantes;
- estudiantes activos/inactivos sobre el programa seleccionado de forma determinista;
- carreras y pensums vigentes;
- resultados registrados;
- promedio de avance solo para estudiantes con estado ACTIVO.

## PostgreSQL utilizado
- `sis_aca_estudiante`
- `sis_aca_estudiante_programa`
- `sis_aca_carrera`
- `sis_aca_pensum`
- `sis_aca_vw_avance_pensum`
- `sis_aca_vw_resultado_estudiante`
- `sis_aca_resultado_curso`

No se modifica esquema, vistas, triggers ni constraints.

## UI
La pantalla conserva el lenguaje editorial aprobado:
- hero académico;
- 4 KPI;
- tabla densa;
- panel lateral de filtros;
- rango de avance de doble control;
- exportación;
- paginación real;
- responsive.

Las fotos continúan usando `photoPath` si existe; si no, iniciales. No se
inventan imágenes de estudiantes.

## Validación requerida en UBU26SYMFONY
```bash
php -l src/Repository/StudentReadRepository.php
php -l src/Controller/Demo/StudentController.php
php bin/console lint:twig templates/
php bin/console lint:container
php bin/console cache:clear
curl -I http://127.0.0.1:8000/alumnos
```

Comprobar además filtros combinados y páginas 1..N desde navegador.
