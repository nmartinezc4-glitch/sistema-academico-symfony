# 03 — Design System: Aula Editorial UI

## Color

Superficies:
- `--paper #F6F1E8`
- `--paper-soft #FBF8F2`
- `--surface #FFFDFC`
- `--surface-muted #F1E9DF`
- `--line #DED5C9`

Texto:
- `--ink #342D29`
- `--ink-soft #6F655F`
- `--ink-muted #948981`

Marca:
- `--terracotta #C86F50`
- `--terracotta-deep #B5543D`
- `--burgundy #793B46`
- `--burgundy-deep #652C37`

Semánticos:
- success `#6F8558`, bg `#E3EDDE`
- warning `#C89536`, bg `#F6E9C9`
- danger `#B94F45`, bg `#F4DCD7`
- info `#667E88`, bg `#E2EAED`
- neutral `#89847F`, bg `#ECE9E6`

## Tipografía

Display: `Fraunces`, fallback Georgia.  
UI: `Inter`, fallback system-ui.

Escala: display-xl 48/54, h1 40/46, h2 28/34, h3 20/26, body-lg 18/28, body 15/24, small 13/20, micro 11/16.

## Espaciado
4, 8, 12, 16, 24, 32, 48, 64 px.

## Radius
input/button 8; card 14; large 18; badge pill.

## Shadow
Card muy sutil; evitar sombras negras fuertes.

## Layout
>=1200: sidebar 248, topbar 64, padding 28–32.  
1024–1199: sidebar 216, padding 24.  
<992: sidebar drawer.

## Primitivos

Botones primary/secondary/ghost/danger/icon.  
Inputs 44px.  
Cards paper/surface.  
Badges siempre con texto.  
Progress accesible.  
Tables con header legible.  
Iconos consistentes, preferencia Lucide/Symfony UX.

## Gráficos
Paleta semantic. Título + equivalente textual/tabla. No abusar pie/donut.

## Decoración
Campus + botanical line art + crema; no competir con tarea.

## Focus
Outline visible 2px.

## Motion
120–180ms y `prefers-reduced-motion`.
