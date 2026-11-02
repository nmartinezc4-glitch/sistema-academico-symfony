# 22 — Protocolo de Regresión Visual

## 1. Objetivo

Evitar que una mejora de una pantalla rompa el lenguaje visual de otras.

## 2. Resolución canónica

Captura principal en:
- 1536×1024 o ancho equivalente;
- zoom navegador 100%;
- sin DevTools abierto.

Comparar con mockup de referencia, no buscando pixel-perfect absoluto sino:
- proporciones;
- jerarquía;
- densidad;
- color;
- alineación;
- componentes.

## 3. Capturas obligatorias

Por pantalla:
- desktop canonical;
- 1024 wide;
- mobile si la pantalla tiene comportamiento móvil relevante.

## 4. Checklist visual

### Shell
- sidebar ancho consistente;
- topbar 64;
- logo no cambia tamaño;
- content start alineado.

### Typography
- H1 serif;
- labels sans;
- no fallback inesperado.

### Cards
- radius;
- border;
- shadow;
- spacing.

### State colors
- approved same green;
- pending same mustard;
- rejected same red.

### Tables
- headers;
- row height;
- numeric alignment.

## 5. Tolerancias

Aceptable:
- ajuste de texto por fuente/fallback;
- cambio menor de altura;
- icono equivalente.

No aceptable:
- grid distinto;
- azul tech;
- sidebar oscura;
- cards con sombras fuertes;
- fuentes totalmente diferentes;
- tabla genérica bootstrap.

## 6. Captura automatizada futura

Se puede usar Playwright en V1/V2 si está disponible, pero no es requisito inicial.

## 7. Registro

Mantener `/docs/screenshots/` en repo si el equipo lo decide, con:
`S01-dashboard-desktop.png`, etc.

## 8. Gate

Un merge que toca tokens/componentes base requiere revisar al menos Dashboard, Alumnos, Ingreso Notas y un Reporte.
