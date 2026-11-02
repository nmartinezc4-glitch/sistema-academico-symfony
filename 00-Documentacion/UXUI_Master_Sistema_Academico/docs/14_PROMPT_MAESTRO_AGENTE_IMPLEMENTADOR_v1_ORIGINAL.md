# 14 — Prompt Maestro para Agente Implementador Frontend V1

## MISIÓN

Implementa la Fase Frontend V1 del Sistema Académico en Symfony 8.1 + Twig, replicando con alta fidelidad el UX/UI Master “Aula Editorial UI” y los 19 mockups en `mockups/`.

No integrar PostgreSQL/Doctrine. Entrega prototipo navegable y preparado para binding.

## LECTURA OBLIGATORIA
Lee todos los `docs/01..13`, `reference_database/data_dictionary.md` y `traceability_matrix.md`.

## RESTRICCIONES
1. no modificar database;
2. no migraciones;
3. no Doctrine;
4. no inventar columnas;
5. no hardcodear 61;
6. no calcular status académico en Twig/JS;
7. no AdminLTE/theme Bootstrap;
8. no React/Vue;
9. no screenshot como fondo;
10. no SAxxx crudo;
11. no password en SIS_ACA;
12. no azul/navy como identidad;
13. accesibilidad;
14. fixture centralizado.

## ARQUITECTURA
DemoDataProvider + ViewModels + controllers delgados + layouts app/auth/print + components + CSS tokenizado + Stimulus mínimo.

## ORDEN
1 Foundation.
2 Shell.
3 Core.
4 Reports.
5 Auth/exports.
6 QA.

No avanzar si gate anterior falla.

## FOUNDATION GATE
Construye component gallery: typography, palette, buttons, forms, badges, alerts, metrics, progress, table, tabs.

## CORE GATE
Dashboard, students, profile, new, pensum, grade entry, transcript.

## REPORTS GATE
Centro + siete reportes.

## EXPORT GATE
Login + xlsx/pdf/print preview.

## QA
Responsive, a11y, visual screenshots, dead links, gaps.

## ENTREGA
Código + route list + screen/template/fixture matrix + screenshots + deviations + debt + V2 plan.
