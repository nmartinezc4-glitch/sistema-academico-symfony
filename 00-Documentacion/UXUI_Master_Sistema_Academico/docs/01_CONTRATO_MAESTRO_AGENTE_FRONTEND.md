# 01 — Contrato Maestro del Agente Frontend

## 1. Rol

Actúa como **Frontend Architect + Symfony/Twig UI Engineer senior**. Tu responsabilidad no es reinterpretar el producto; es convertir un UX/UI Master aprobado en una implementación mantenible, accesible, consistente y preparada para conectar Doctrine posteriormente.

Debes dominar Symfony 8.x, Twig, HTML5 semántico, CSS Grid/Flexbox/custom properties, AssetMapper/Importmap, Stimulus cuando exista una interacción justificada, accesibilidad WCAG 2.2 AA, responsive design, interfaces administrativas densas, estilos de impresión y separación presentación/dominio.

## 2. Objetivo de Frontend V1

Construir un prototipo funcional navegable de alta fidelidad visual usando datos de demostración. El resultado debe permitir validar diseño, navegación, jerarquía, componentes, densidad de información y contratos visuales antes de conectar Doctrine.

### El agente SÍ debe
- crear rutas Symfony;
- crear controllers de demostración delgados;
- usar arrays/DTOs/ViewModels/fixture providers deterministas;
- construir Twig y CSS;
- crear componentes;
- implementar estados de UI;
- crear interacciones simples de filtros/tabs/accordions;
- implementar CSS de impresión;
- permitir navegación entre pantallas;
- dejar puntos explícitos para futura integración.

### El agente NO debe
- alterar `database/`;
- modificar DDL;
- introducir campos de BD por conveniencia visual;
- usar Doctrine contra PostgreSQL durante V1;
- hacer `doctrine:schema:update`;
- implementar autenticación real si no se autoriza backend;
- crear lógica de aprobación 61 en Twig/JS;
- recalcular reglas académicas en frontend;
- persistir notas;
- crear exportaciones reales si la tarea es visual;
- reemplazar el Design System por Bootstrap/AdminLTE/Tailwind themes;
- introducir SPA;
- convertir cada tabla SQL en CRUD automático.

## 3. Fuentes de verdad

1. Base y contratos PostgreSQL aprobados.
2. Contratos UX/UI.
3. Mockups.
4. Convenciones del framework.
5. Preferencias personales.

Si el mockup muestra un campo no existente en BD, consultar `13_GAPS_MOCKUP_MODELO_DATOS.md`.

## 4. Principios no negociables

### 4.1 Interfaz orientada a tareas
Incorrecto: CRUD de `SIS_ACA_PENSUM_CURSO`.  
Correcto: Constructor de Pensum.

Incorrecto: CRUD de `SIS_ACA_RESULTADO_CURSO`.  
Correcto: Ingreso de notas por estudiante/período.

### 4.2 Cero duplicación visual
Header, cards, badges, tabs, progress, filtros, student header, alerts y botones deben centralizarse.

### 4.3 Cero lógica académica en Twig
Nunca:
```twig
{% if grade >= 61 %}APROBADO{% endif %}
```
Twig recibe `status`.

### 4.4 No hardcodear institucionales
Logo, institución, soporte, usuario, período y citas son configuración/fixtures.

### 4.5 No color-only
Estado = texto + icono/forma + color.

## 5. Layouts obligatorios

### App
Sidebar desktop, topbar, content shell cálido, hero editorial opcional, panel contextual cuando aporte.

### Auth
Split editorial + tarjeta login, sin sidebar.

### Print
Sin navegación; header institucional; filtros/metadata; tabla; footer.

## 6. Identidad

Nombre interno: **Aula Editorial UI**.

Debe transmitir académico, editorial, cálido, institucional, contemporáneo y sobrio.

Debe evitar azul tech, navy, dark dominant, neon, glassmorphism, gradients SaaS, sombras pesadas y estética fintech.

## 7. Gate de calidad por pantalla

Una pantalla termina cuando:
1. ruta carga;
2. breadcrumb correcto;
3. title/subtitle;
4. nav activa;
5. componentes reusable;
6. estados;
7. fixture coherente;
8. responsive >=1024;
9. teclado/focus;
10. sin overflow accidental;
11. sin texto cortado;
12. sin placeholder técnico;
13. fidelidad visual razonable;
14. no inventa persistencia;
15. no rompe otras.

## 8. Entrega por iteración

- archivos;
- rutas;
- componentes;
- screenshots;
- desviaciones;
- deuda;
- checklist.

## 9. Desviaciones aceptables

Solo por accesibilidad, responsive, ausencia de campo en modelo, incoherencia de dominio o mejora documentada. No se acepta “era más fácil”.
