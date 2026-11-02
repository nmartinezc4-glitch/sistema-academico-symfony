# Fase de Seguridad e Identidad — Symfony Security

## Objetivo

La autenticación y autorización pertenecen a **Symfony Security**. PostgreSQL
persiste identidades, roles, auditoría y asignaciones; no decide por sí solo qué
pantalla o acción HTTP puede ejecutar un usuario.

No existe un rol genérico de superusuario.

## Modelo persistente

Tablas de seguridad:

- `SIS_SEG_USUARIO`
- `SIS_SEG_ROL`
- `SIS_SEG_USUARIO_ROL`
- `SIS_SEG_AUDITORIA`

Relación académica contextual:

- `SIS_ACA_DOCENTE_OFERTA`

Las contraseñas nunca se guardan en texto plano. Solo se persiste
`USU_PASSWORD_HASH`, generado mediante el password hasher de Symfony.

## Roles

| Rol | Responsabilidad |
| --- | --- |
| `ROLE_DOCENTE` | Ingreso de notas sobre ofertas asignadas |
| `ROLE_COORDINACION` | Gestión académica operativa |
| `ROLE_DIRECCION` | Consulta institucional y análisis |
| `ROLE_GESTION_USUARIOS` | Administración de cuentas y roles |

`ROLE_COORDINACION` hereda las capacidades funcionales de
`ROLE_DOCENTE` para permitir correcciones académicas, pero
`ROLE_GESTION_USUARIOS` permanece separado.

## Autenticación Symfony

La aplicación utiliza:

- `SecurityBundle`;
- `FormLoginAuthenticator`;
- proveedor DBAL `AcademicUserProvider`;
- `AcademicUser implements UserInterface, PasswordAuthenticatedUserInterface`;
- password hasher `auto`;
- CSRF nativo de Symfony;
- logout gestionado por el firewall;
- `access_control` para fronteras de módulos;
- `GradeEntryVoter` para autorización contextual.

El login temporal basado en variables `APP_LOGIN_USER` /
`APP_LOGIN_PASSWORD_HASH` fue retirado.

## Autorización contextual de notas

Un docente necesita dos condiciones:

1. poseer `ROLE_DOCENTE`;
2. tener una fila activa en `SIS_ACA_DOCENTE_OFERTA` para la oferta que
   intenta calificar.

Coordinación puede intervenir sobre cualquier oferta mediante
`ROLE_COORDINACION`.

Los docentes solo reciben en el selector de ingreso de notas los estudiantes,
inscripciones y ofertas vinculadas a sus asignaciones.

## Bootstrap del primer usuario

No existe usuario seed ni contraseña por defecto.

Después de aplicar la migración de seguridad se crea el primer usuario desde
Symfony:

```bash
php bin/console app:security:create-user
```

Para el primer operador se recomienda asignar:

- `ROLE_COORDINACION`;
- `ROLE_GESTION_USUARIOS`.

Esto no crea un superusuario: ambos permisos siguen siendo independientes.

## Administración

Rutas:

- `/configuracion/usuarios`
- `/configuracion/usuarios/nuevo`
- `/configuracion/usuarios/{id}/editar`
- `/ofertas/docentes`

La aplicación protege la última cuenta activa con
`ROLE_GESTION_USUARIOS` para evitar bloquear la administración.

## Scripts

Aplicación incremental sobre la base certificada:

```bash
psql -d sistema_academico_dev -f 16_security_schema.sql
psql -d sistema_academico_dev -f 17_security_seed_roles.sql
psql -d sistema_academico_dev -f 15_runtime_permissions.sql
psql -d sistema_academico_dev -f 18_security_validation.sql
```

No ejecutar `run_all.sql` sobre la base actual: es destructivo en desarrollo.

## Dependencia Composer

`composer.json` incluye:

```
symfony/security-bundle: 8.1.*
```

El `composer.lock` debe regenerarse en UBU26SYMFONY antes de ejecutar
`cache:clear`.

## Gate de seguridad

Antes de pruebas funcionales:

```bash
php bin/console lint:container
php bin/console lint:twig templates
php bin/console debug:config security
php bin/console debug:router
php bin/console app:audit:preflight
```
