# 11 — QA y Criterios de Aceptación

Gate global: 19 vistas, rutas, navegación, Twig limpio, fidelidad desktop, responsive básico, a11y, fixtures centralizados, sin SQL/Doctrine.

Visual QA a 1536/1440: sidebar, topbar, hero, grid, cards, jerarquía, paleta, tipografía, tablas, spacing.

Content QA: español, no lorem, no IDs SQL visibles, no institución inconsistente, no datos reales.

Model QA: detectar email/teléfono/documento/género/nacionalidad/créditos/sanciones/documentos/prioridades como gaps.

Print QA: A4, header, page number, repeat header, no sidebar/buttons.

Responsive mínimos: 1536×1024, 1366×768, 1024×768, 768×1024, 390×844.

DoD:
- [ ] route
- [ ] fixture
- [ ] layout
- [ ] responsive
- [ ] states
- [ ] empty
- [ ] accessibility
- [ ] no hardcode domain
- [ ] screenshot
- [ ] review

FAIL automático: admin template genérico, azul tech, hardcode 61, nuevas columnas SQL, SAxxx crudo, mockup usado como fondo.
