# 02 — UX/UI Master Specification

## 1. Visión

El Sistema Académico no debe percibirse como un CRUD genérico. La experiencia representa un **expediente académico convertido en producto digital contemporáneo**.

Metáfora visual: papel, tinta, archivo, campus, conocimiento, trayectoria.  
Metáfora funcional: personas, pensums, períodos y resultados; nunca tablas SQL.

## 2. Perfiles V1

- Coordinación académica: actor principal.
- Operador académico: altas, asignaciones, notas.
- Consulta: expedientes/reportes.

Permisos reales son backend futuro.

## 3. Tareas primarias

Localizar alumno, registrar alumno, consultar perfil/expediente, revisar avance, construir pensum, ingresar notas, detectar pendientes/repitencias, analizar resultados y exportar/imprimir.

## 4. Jerarquía

1. contexto actual;
2. identidad;
3. métricas;
4. tarea principal;
5. detalle;
6. acciones secundarias.

## 5. Navegación

Inicio; Estudiantes (Alumnos, Expedientes); Estructura académica (Carreras, Cursos, Pensums); Gestión académica (Años y períodos, Secciones, Ofertas); Evaluación (Ingreso de notas); Análisis (Reportes, Avance curricular); Configuración (Políticas).

## 6. Búsqueda global

Desktop topbar. V1 puede buscar fixtures por estudiante, curso o período. No simular resultados inexistentes.

## 7. Interacción

- links Symfony convencionales;
- tabs como rutas/query cuando representan subvista;
- filtros con query string cuando convenga;
- acciones bloqueadas explican motivo;
- destructivas requieren confirmación en backend futuro.

## 8. Microcopy

Directa, académica, humana y sobria. Nunca mostrar códigos SAxxx como único mensaje.

## 9. Datos

Números de mockup son ilustrativos y viven en fixtures.

## 10. Decoración

Retratos/campus/botánica son demo/decoración. Ninguna información crítica depende de imágenes.

## 11. Semántica

Resultado: APROBADO, REPROBADO, PENDIENTE, SIN_OFERTA, YA_APROBADO.  
Período: PLANIFICADO, ABIERTO, CERRADO.  
Programa: ACTIVO, FINALIZADO, RETIRADO.  
Inscripción: INSCRITO, FINALIZADO, RETIRADO.

## 12. Progressive disclosure

Dashboard resume; reportes detallan; expediente individualiza; ingreso de notas acciona.

## 13. Densidad

Desktop: 4–5 metrics/row, 6–9 columnas visibles, filtros agrupados, máximo 2 visualizaciones grandes por bloque.

## 14. Datos visuales

Orden preferido: KPI → tabla → progress → barras → donut → línea temporal.

## 15. Documento oficial

Expediente/PDF/print usan header, metadata, contenido, paginación y firmas opcionales.
