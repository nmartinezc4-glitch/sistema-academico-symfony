# M09 — Expediente académico

## Objetivo
Presentar el historial académico completo de un estudiante como documento vivo,
sin datos ficticios, controles demo ni acciones que apunten a reportes genéricos.

## Datos utilizados
- StudentReadRepository::findProfile()
- StudentReadRepository::periods()
- StudentReadRepository::results()
- vista `sis_aca_vw_avance_pensum`
- vista `sis_aca_vw_resultado_estudiante`

El Controller agrupa resultados por período y prepara únicamente métricas de
presentación: cantidad calificada, promedio del período y conteos por estado.

## Eliminaciones
Se removieron del expediente:
- ubicación ficticia;
- correo ficticio;
- teléfono ficticio;
- etiquetas `UI-only`;
- filtro de materia deshabilitado/demo;
- columna Observaciones sin respaldo;
- tab Observaciones;
- links `href="#"`;
- imprimir/descargar "expediente" que en realidad apuntaban al reporte global de
  notas por carrera;
- report cards generales que no respetaban el contexto del estudiante.

## Identidad real
El encabezado usa:
- carné;
- nombres/apellidos;
- fecha de nacimiento;
- dirección cuando existe;
- fotografía persistida cuando existe;
- carrera/pensum/programa;
- inscripción académica real.

Programa ACTIVO no se confunde con inscripción: un estudiante recién creado
puede tener programa activo y `SIN_REGISTRO` como estado de inscripción.

## Historial
Cada período muestra:
- año/período;
- ciclo;
- sección;
- estado del período;
- estado de inscripción;
- cantidad de resultados calificados;
- promedio del período;
- resultados con código, curso, tipo, sección, nota, estado e intento.

## Resumen lateral
- avance curricular real;
- aprobados;
- pendientes;
- reprobaciones históricas;
- cursos obligatorios;
- situación programa/inscripción;
- acciones que sí existen.

## Estados vacíos
- estudiante sin períodos;
- período sin resultados;
- inscripción inexistente;
- nota pendiente.

## Validación requerida
```bash
php -l src/Controller/Demo/TranscriptController.php
php bin/console lint:twig templates/transcript/show.html.twig
php bin/console lint:container
php bin/console cache:clear
```

Pruebas visuales mínimas:
- estudiante con 4 períodos completos;
- estudiante con período ABIERTO;
- estudiante recién creado sin inscripción;
- resultado PENDIENTE;
- resultado REPROBADO / intento > 1.


## Directorio de expedientes
El menú lateral ya no apunta a un estudiante fijo. `/expedientes` es ahora un
directorio real con búsqueda y filtros.

Filtros:
- nombre/carné;
- carrera;
- pensum;
- estado del programa;
- año de ingreso;
- con/sin historial;
- ordenamiento;
- tamaño de página.

Cada fila muestra el último período, cantidad de períodos/resultados, avance y
acceso al expediente o al perfil. El filtro "Sin historial" permite localizar
estudiantes recién creados que todavía no poseen inscripción académica.
