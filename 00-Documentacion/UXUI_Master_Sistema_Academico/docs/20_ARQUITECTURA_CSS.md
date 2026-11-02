# 20 — Arquitectura CSS y Convenciones

## 1. Objetivo

Mantener fidelidad visual sin convertir el proyecto en una colección de overrides.

## 2. Orden de carga

```text
tokens.css
base.css
layout.css
components.css
pages.css
print.css
```

No permitir que `pages.css` redefina todos los primitivos. Si una regla aparece en tres páginas, debe subir a component.

## 3. Nomenclatura

Se recomienda BEM ligero o nombres semánticos:

```css
.page-header {}
.page-header__title {}
.metric-card {}
.metric-card--warning {}
.student-header {}
.status-badge {}
```

Evitar:
```css
.red-card {}
.left-box {}
.big-text {}
```

## 4. Utilidades

Crear pocas utilidades explícitas para spacing/alignment:
- `.stack`
- `.cluster`
- `.grid`
- `.text-muted`
- `.sr-only`

No recrear Tailwind manualmente.

## 5. Layout primitives

### `.app-shell`
Grid: sidebar + main.

### `.app-main`
Topbar sticky + content.

### `.content-shell`
Padding y background paper.

### `.page-grid`
Grid de contenido principal + aside, usualmente `minmax(0,1fr) 320px`.

### `.metric-grid`
`repeat(4,minmax(0,1fr))`, responsive.

## 6. Container queries

Opcional. No introducir si complica compatibilidad. Media queries suficientes.

## 7. CSS tokens semánticos

Los componentes no deberían usar hex directo:

Mal:
```css
.badge-approved { background:#E3EDDE; }
```

Bien:
```css
.badge--success { background:var(--success-bg); color:var(--success); }
```

## 8. Estados

Use data attributes cuando simplifique:

```html
<span class="status-badge" data-status="APROBADO">Aprobado</span>
```

CSS puede mapear status, pero el texto sigue en HTML.

## 9. Hero editorial

Debe ser un patrón reusable:
- background crema;
- imagen decorativa derecha;
- gradient overlay;
- botanical optional;
- content no sobre imagen con contraste insuficiente.

## 10. Tablas

Variables:
- row height 42–48;
- header background transparent/muted;
- border line;
- numeric alignment right;
- status center/left consistente.

## 11. Print

`print.css` se carga siempre o media print. No mezclar estilos screen/print con hacks.

## 12. Auditoría CSS

Antes de cerrar V1:
- buscar hex directos;
- buscar `!important`;
- buscar estilos inline;
- buscar duplicados;
- eliminar reglas muertas.

`!important` solo permitido en print/utilidad muy documentada.
