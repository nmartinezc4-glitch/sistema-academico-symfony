# 19 — Handoff a Fase V2: Integración Doctrine/PostgreSQL

Este documento define qué NO debe romperse al conectar datos reales.

## 1. Objetivo

Sustituir fixtures por Application Services/Repositories sin rediseñar Twig.

## 2. Secuencia

1. Configurar `DATABASE_URL`.
2. Verificar DBAL.
3. Mapear entidades base.
4. Mapear vistas como read-only o consultar DBAL.
5. Crear repositories.
6. Crear servicios de aplicación.
7. Alimentar los ViewModels ya existentes.
8. Reemplazar DemoDataProvider pantalla por pantalla.
9. Activar Symfony Forms.
10. Activar Symfony Security.
11. Implementar exportaciones.

## 3. Orden recomendado de binding

1. Catálogos: Carrera, Curso, Sección.
2. Pensum/Ciclo/PensumCurso.
3. Student + StudentProgram.
4. StudentPeriod.
5. Profile/Transcript.
6. Grade entry usando `VW_INGRESO_NOTAS`.
7. Result commands.
8. Reports usando `VW_REPORTE_NOTAS`.
9. Progress views.
10. Exports.

## 4. Regla de capa

Controller → Application Service → Repository/DBAL → PostgreSQL.  
Controller nunca SQL directo.

## 5. Vistas PostgreSQL

Preferir DBAL/read-only projection para vistas analíticas complejas. No forzar ORM si empeora claridad.

## 6. Errores

Capturar SQLSTATE de dominio y traducir en Service/Form error.

## 7. Transacciones

Ingreso batch de notas debe ser transaccional en V2 si varias notas se guardan juntas.

## 8. Campos gap

No implementar G01–G18 sin decisión formal.

## 9. Pruebas

- repository integration;
- service;
- controller;
- browser smoke;
- regression visual.

## 10. Gate final

La integración se considera correcta cuando los datos reales sustituyen fixtures sin cambiar estructura visual ni semántica de estados.
