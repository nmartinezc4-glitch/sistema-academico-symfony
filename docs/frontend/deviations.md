# Desviaciones

| ID | Pantalla | Mockup | Diferencia | Razón | Impacto | Decisión futura |
|---|---|---|---|---|---|---|
| D-01 | S16 Login | campo recuperación con link | reemplazado por texto demo "Recuperar acceso (V2)" | evitar `href="#"` no documentado | medio | activar en V2 |
| D-02 | S04 Nuevo | campos contacto visibles | se mantienen como aviso `uiOnly`, no persistidos | regla anti-deuda V2 | bajo | evaluar retiro visual |
| D-03 | Gráficos | donuts/barras del mockup | reemplazados por progress + tabla (sin lib de charts) | anti-sobreingeniería; accesibilidad de tabla | bajo | charting ligero en V2 opcional |
| D-04 | Créditos/horas | presentes en mockup | eliminados de la UI | no es contrato de datos | bajo | no aplica |
| D-05 | Screenshots/QA visual | requeridos | resuelto: 40 capturas desktop/tablet + 10 mobile en `docs/frontend/screenshots/` | — | — | — |
| D-06 | Filtros `careerId` params en GET | selects de filtros | POST/GET simple sin URL-state completo en todos los reportes | cobertura mínima | bajo | completar en GATE 7 final |
| D-07 | Hero del dashboard / login | fotografía de campus | reemplazada por degradado cálido + cita (sin asset de foto aprobado) | assets | medio | usar asset limpio en V2 |
