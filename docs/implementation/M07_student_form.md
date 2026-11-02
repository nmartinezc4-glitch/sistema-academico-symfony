# M07 — Alta y edición de estudiante

## Objetivo
Convertir S04 en un punto de evidencia real del sistema: la interfaz únicamente
muestra campos respaldados por PostgreSQL y todas las acciones visibles tienen
comportamiento implementado.

## Decisiones de alcance
Se eliminaron completamente de alta/edición:
- género;
- correo electrónico;
- teléfono;
- nacionalidad;
- documento de identificación;
- etiquetas y avisos `UI-only`.

Estos campos no forman parte del modelo aprobado y no deben aparecer en una
pantalla operativa como si fueran persistentes.

## Campos persistidos
### Estudiante
- carné generado automáticamente por año de ingreso + correlativo;
- nombres;
- apellidos;
- fecha de nacimiento;
- dirección de residencia;
- fotografía opcional;
- estado activo derivado del programa.

### Programa académico
- pensum;
- carrera derivada del pensum (el selector de carrera filtra);
- fecha de ingreso;
- estado del programa.

## Fotografía
La carga deja de ser demostrativa:
- JPG/PNG/WEBP;
- máximo 2 MB;
- almacenamiento en `public/uploads/students/`;
- ruta persistida en `est_foto_ruta`;
- reemplazo seguro en edición;
- no se eliminan rutas seed que no pertenecen al directorio de uploads.

## Integridad
- creación de estudiante + programa permanece transaccional en DBAL;
- el usuario ya no escribe el carné: se genera dentro de la transacción como `STU-AAAA-NNNN`, usando lock transaccional por año para evitar duplicados;
- fechas se validan estrictamente;
- pensum debe existir y estar activo;
- código único;
- si existen calificaciones, el pensum se muestra bloqueado en la UI y también
  continúa protegido por PostgreSQL;
- estados permitidos: ACTIVO / FINALIZADO / RETIRADO.

## UX
Se elimina el stepper ficticio. La pantalla usa dos secciones reales:
1. Identidad del estudiante.
2. Programa académico.

El rail derecho es una vista previa viva de los valores que sí se guardarán.

## Validación requerida
```bash
php -l src/Controller/Demo/StudentController.php
php -l src/Repository/StudentWriteRepository.php
php -l src/Service/StudentPhotoStorage.php
php bin/console lint:twig templates/student/new.html.twig
php bin/console lint:twig templates/student/edit.html.twig
php bin/console lint:container
php bin/console cache:clear
```

Pruebas funcionales:
- alta sin fotografía;
- alta con JPG/PNG/WEBP menor a 2 MB;
- rechazo de archivo >2 MB;
- rechazo de código inválido;
- código duplicado;
- edición de nombres/fecha;
- reemplazo de fotografía;
- estudiante con historial: pensum bloqueado;
- estudiante sin historial: eliminación disponible;
- alta exitosa redirige a la ficha recién creada.


## Extensión de datos personales
La dirección deja de ser un elemento UI-only. La integración aprobó
`EST_DIRECCION VARCHAR(255)` en `SIS_ACA_ESTUDIANTE`.

Para bases ya instaladas se aplica una vez:

```bash
psql -h 127.0.0.1 -U sa_owner -d sistema_academico_dev \
  -f 00-Documentacion/database/16_student_personal_extension.sql
```

La columna es nullable para no invalidar los 45 estudiantes del dataset previo.
La fecha de nacimiento ya pertenecía al modelo original y continúa siendo
obligatoria.
