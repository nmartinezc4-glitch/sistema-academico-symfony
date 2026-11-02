# 10 — Contrato de Implementación Symfony/Twig

Stack: Symfony 8.1, Twig, PHP 8.5 del lab, AssetMapper/Importmap, CSS propio, Stimulus opcional. Doctrine fuera de V1.

Estructura:
```text
src/Controller/Demo/
src/Ui/DemoDataProvider.php
src/Ui/ViewModel/
templates/layout/{app,auth,print}.html.twig
templates/components/
templates/{dashboard,student,curriculum,grade,transcript,report,export}/
assets/styles/{tokens,base,layout,components,pages,print}.css
assets/controllers/
```

## DemoDataProvider
Fuente única. Controllers: obtener ViewModel + render.

## ViewModels
No Doctrine en V1. Contrato estable para V2.

## Twig
Escape automático, sin SQL, sin container, sin lógica académica.

## JS
Solo drawer, tabs, filtros demo, toggle, file preview, accordion, modal. No SPA.

## Navegación
No `href="#"` salvo disabled documentado.

## Assets
No usar screenshot completo como UI. Recrear HTML/CSS.

## V2
Reemplazar DemoDataProvider por services/repositories manteniendo ViewModels.

## Seguridad
Login visual V1; V2 Symfony Security con User separado.

## Exports
PhpSpreadsheet y motor PDF en V2.
