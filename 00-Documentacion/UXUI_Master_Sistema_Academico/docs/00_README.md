# UX/UI Master — Sistema Académico

**Versión:** 1.0  
**Estado:** Baseline visual aprobado para implementación Frontend V1  
**Stack objetivo:** Symfony 8.1 + Twig + AssetMapper/Importmap + CSS propio + Stimulus opcional  
**Prioridad actual:** replicación visual, navegación y comportamiento de interfaz con datos de demostración.  
**Siguiente fase:** integración con Doctrine/PostgreSQL y reemplazo de fixtures visuales por datos reales.

## Objetivo del paquete

Este paquete es el contrato de handoff para agentes de desarrollo. Su función es reducir al mínimo las decisiones implícitas durante la construcción del frontend. Los mockups incluidos constituyen la referencia visual principal; los documentos definen cómo traducirlos a código sin convertir la interfaz en una copia rígida de una imagen ni introducir reglas de negocio o campos que no existen en el modelo PostgreSQL.

El agente debe leer los documentos en este orden:

1. `01_CONTRATO_MAESTRO_AGENTE_FRONTEND.md`
2. `02_UX_UI_MASTER.md`
3. `03_DESIGN_SYSTEM.md`
4. `04_ARQUITECTURA_INFORMACION_RUTAS.md`
5. `05_ESPECIFICACION_PANTALLAS.md`
6. `06_CONTRATOS_COMPONENTES.md`
7. `07_FORMULARIOS_VALIDACION.md`
8. `08_REPORTES_EXPORTACIONES_IMPRESION.md`
9. `09_RESPONSIVE_ACCESIBILIDAD.md`
10. `10_SYMFONY_TWIG_IMPLEMENTACION.md`
11. `11_QA_CRITERIOS_ACEPTACION.md`
12. `12_CONTRATO_DATOS_UI.md`
13. `13_GAPS_MOCKUP_MODELO_DATOS.md`
14. `14_PROMPT_MAESTRO_AGENTE_IMPLEMENTADOR.md`
15. `15_PLAN_IMPLEMENTACION_FRONTEND_V1.md`

## Fuentes de verdad y prioridad

Cuando dos fuentes parezcan contradecirse, usar esta prioridad:

1. **Modelo de datos / restricciones aprobadas** en `reference_database/`.
2. **Contrato funcional y de interacción** de este paquete.
3. **Mockup de la pantalla concreta**.
4. **Patrones generales del Design System**.
5. Preferencias del implementador.

Los mockups son referencias visuales, no contratos de base de datos. Los nombres, cifras, fotografías, textos institucionales, universidades y datos personales visibles en ellos son ficticios/ilustrativos y no deben quedar hardcodeados como datos de producción.

## Regla de oro de la Fase Frontend V1

En esta fase el agente **NO debe modificar PostgreSQL ni inventar nuevas entidades**. El objetivo es conseguir un prototipo navegable de alta fidelidad que replique el lenguaje visual aprobado. Los datos se alimentan con fixtures/arrays/ViewModels de demostración. Toda integración persistente se realiza en una fase posterior.

## Entregables esperados de un agente

- Layout base completo.
- Sistema de tokens y componentes reutilizables.
- Todas las rutas visuales del catálogo.
- Fixtures deterministas.
- Navegación completa.
- Estados vacíos, carga, error y bloqueo.
- Responsive razonable con prioridad desktop.
- Estilos de impresión.
- Sin errores Twig/HTML/CSS.
- Sin lógica SQL ni acceso directo a PostgreSQL en Frontend V1.
- Matriz de cumplimiento por pantalla.

## Estructura del paquete

- `docs/`: contratos legibles por humanos/agentes.
- `machine/`: tokens, rutas y pantallas en formato estructurado.
- `mockups/`: 19 referencias visuales aprobadas.
- `reference_database/`: snapshot del modelo PostgreSQL aprobado.
- `UXUI_Master_Sistema_Academico_v1.0.docx`: manual maestro condensado.
