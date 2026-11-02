# M05 — Pensums / Estructura curricular

## Objetivo
Convertir el acceso de Pensums en un módulo navegable y respaldado por datos
reales. El menú lateral ya no abre un pensum fijo.

## Rutas
- `/pensums`: directorio de versiones de pensum.
- `/pensums/{id}`: estructura curricular de una versión específica.

## Directorio
Permite buscar y filtrar por:
- código/nombre/carrera;
- carrera;
- estado activo/inactivo;
- ordenamiento;
- tamaño de página.

Cada tarjeta muestra datos persistidos:
- código y nombre;
- carrera;
- versión;
- vigencia;
- cantidad de cursos/ciclos;
- estudiantes con programa ACTIVO.

## Detalle
La estructura se obtiene de:
- `SIS_ACA_PENSUM`;
- `SIS_ACA_CARRERA`;
- `SIS_ACA_CICLO_CURRICULAR`;
- `SIS_ACA_PENSUM_CURSO`;
- `SIS_ACA_CURSO`;
- `SIS_ACA_ESTUDIANTE_PROGRAMA`.

Se muestran únicamente:
- años/ciclos;
- orden de cursos;
- código/nombre;
- obligatorio/optativo;
- vigencia;
- estudiantes activos.

## Eliminaciones del mockup/demo
Se eliminaron:
- créditos decorativos;
- etiquetas UI-only;
- acciones de agregar/reordenar/editar que no tienen write contract;
- tabs deshabilitadas presentadas como funcionales;
- bloque de prerrequisitos sin tabla respaldada;
- botones demo de PDF/edición.

La pantalla es deliberadamente de consulta hasta que exista un contrato de
escritura explícito para modificar un pensum sin comprometer historial.

## Validación
```bash
php -l src/Controller/Demo/CurriculumController.php
php -l src/Repository/CurriculumReadRepository.php
php bin/console lint:twig templates/curriculum/index.html.twig
php bin/console lint:twig templates/curriculum/show.html.twig
php bin/console lint:container
php bin/console cache:clear
```

Pruebas:
- menú Pensums → `/pensums`;
- búsqueda por código;
- filtro por carrera;
- activo/inactivo;
- abrir un pensum;
- enlace Estudiantes conserva filtro `curriculum`;
- pensum sin cursos conserva estado vacío.


## Alta y configuración de pensums
El módulo incorpora escritura real sin modificar el esquema:

### Nuevo pensum
Ruta `/pensums/nuevo`.

Campos persistidos:
- carrera;
- código;
- nombre;
- vigencia desde/hasta.

La versión se calcula automáticamente como el siguiente correlativo dentro de
la carrera mediante advisory lock. El nuevo pensum se crea con
`PEN_ACTIVO = FALSE`, funcionando como borrador.

### Agregar cursos
En `/pensums/{id}` aparece el constructor cuando la estructura es editable.

Cada alta en `SIS_ACA_PENSUM_CURSO` selecciona:
- curso existente;
- ciclo curricular;
- obligatorio/optativo.

`PCU_ORDEN` se asigna automáticamente como el siguiente orden del ciclo.

### Protección de historia
La UI impide modificar la estructura si existe al menos un
`SIS_ACA_ESTUDIANTE_PROGRAMA` asociado al pensum. La reforma debe realizarse
como una nueva versión. Esto es intencionalmente más estricto que el trigger T4:
agregar un nuevo curso obligatorio a un pensum ya asignado alteraría el avance
de estudiantes existentes aunque el INSERT no cambiara una fila histórica.

### Activación
Un borrador solo puede activarse si posee al menos un curso. Activar no
desactiva otras versiones: el modelo permite convivencia temporal durante una
transición curricular.
