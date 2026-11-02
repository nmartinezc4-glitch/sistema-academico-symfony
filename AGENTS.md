# AGENTS.md — Sistema Académico

Este repositorio corresponde al proyecto universitario **Sistema Académico**.
Antes de modificar código, inspecciona el repositorio y respeta estas decisiones
arquitectónicas. No sustituyas estas reglas por defaults genéricos de Symfony.

## Stack cerrado

- Symfony 8.1
- PHP 8.5 en la VM de desarrollo
- Twig server-rendered
- AssetMapper + Stimulus
- PostgreSQL 16
- Doctrine DBAL
- **Sin Doctrine ORM**
- **Sin migrations de Doctrine**
- **Sin Docker como runtime del proyecto**

La base de datos PostgreSQL ya fue diseñada, validada y certificada. Es la
fuente de verdad del dominio académico.

## Database-first: prohibiciones

No ejecutar ni proponer:

- `doctrine:schema:update`
- `doctrine:schema:create`
- `doctrine:database:create`
- `make:migration`
- `CREATE TABLE`, `ALTER TABLE` o `DROP TABLE` desde Symfony
- instalar Doctrine ORM para "facilitar" el trabajo
- cambiar triggers, constraints, funciones o vistas para acomodar una pantalla

Symfony usa el rol runtime `sa_app`, sin privilegios DDL. Las reglas críticas
(SA204–SA208, SA401 y equivalentes) permanecen en PostgreSQL.

## Arquitectura de aplicación

Preferir:

Request
→ Controller delgado
→ Repository/Service
→ Doctrine DBAL
→ PostgreSQL
→ ViewModel/array de presentación
→ Twig

Twig presenta datos; no ejecuta SQL ni replica reglas académicas. Ordenamiento,
paginación, filtros y agregaciones de datos pertenecen al backend.

## Contratos UX/UI

La fuente de diseño está en:

- `00-Documentacion/UXUI_Master_Sistema_Academico/docs/`
- `00-Documentacion/UXUI_Master_Sistema_Academico/mockups/`
- `00-Documentacion/UXUI_Master_Sistema_Academico/machine/`

Identidad visual: **Aula Editorial / Editorial Académica Contemporánea**.
Mantener Fraunces para títulos y Inter para UI/datos, paleta cálida y componentes
existentes. No convertir la app en un dashboard SaaS azul/oscuro.

Antes de crear un componente nuevo, revisar `templates/components/`. Antes de
crear CSS nuevo, revisar tokens, layout y componentes. Reglas repetidas en tres
pantallas deben promoverse a componente.

## Datos

Nunca inventar campos para satisfacer un mockup. Campos sin respaldo de DB deben
omitirse, mostrarse como no disponibles cuando corresponda o documentarse como
`uiOnly`.

No hardcodear la nota mínima de aprobación. Consumir estados y reglas calculadas
por PostgreSQL.

## Seguridad

- Nunca versionar `.env.local`.
- `.env` y `.env.dev` solo contienen defaults genéricos.
- No registrar DATABASE_URL ni passwords.
- No cambiar Symfony para usar `sa_owner`.

## Flujo Git

- `main`: baseline estable.
- `frontend/rework`: integración y refinamiento visual.
- Hacer cambios pequeños y auditables.
- No reformattear archivos ajenos al cambio.

## Validación mínima

Después de cambios PHP/Twig/config:

```bash
php -l <archivo.php>
php bin/console lint:twig templates/
php bin/console lint:yaml config/
php bin/console lint:container
php bin/console cache:clear
```

Para cambios visuales, ejecutar los scripts Playwright existentes cuando el
entorno disponga de sus dependencias y comparar con los mockups aprobados.

Una pantalla no se considera terminada solo por responder HTTP 200: debe cumplir
datos correctos, contrato funcional, responsive, accesibilidad y fidelidad visual.
