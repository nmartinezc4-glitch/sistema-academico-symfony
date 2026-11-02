# Instalación y certificación de la fase de seguridad Symfony

Esta fase es **aditiva**. No reconstruye la base académica ni modifica los seeds históricos.

## 1. Sincronizar la rama

```bash
cd ~/projects/sistema-academico
git switch frontend/rework
git pull --ff-only origin frontend/rework
git log -1 --oneline
```

## 2. Resolver dependencias Symfony

El proyecto requiere `symfony/security-bundle` y `symfony/security-csrf` 8.1.*. PhpSpreadsheet 5.10 también requiere GD.

```bash
sudo apt update
sudo apt install -y php8.5-gd
php -m | grep -i '^gd$'

composer update symfony/security-bundle symfony/security-csrf --with-all-dependencies
composer check-platform-reqs
composer show symfony/security-bundle
composer show symfony/security-csrf
```

No usar `--ignore-platform-req=ext-gd`: Excel forma parte del proyecto y la extensión debe existir realmente.

> Nota: `composer.lock` se actualizará en la VM al resolver estas dependencias. Después de validar la fase, debe versionarse para que futuras instalaciones sean reproducibles.

## 3. Base existente ya migrada a seguridad

Si `16_security_schema.sql` ya fue ejecutado una vez, **no volver a ejecutarlo**. El error `relation "sis_seg_usuario" already exists` solo indica que la fase base ya está instalada.

Para una base existente como `sistema_academico_dev`, ejecutar únicamente el parche aditivo de fotografía y reaplicar permisos:

```bash
psql -h 127.0.0.1 -U sa_owner -d sistema_academico_dev \
  -f 00-Documentacion/database/18_security_user_photo.sql

psql -h 127.0.0.1 -U sa_owner -d sistema_academico_dev \
  -f 00-Documentacion/database/15_runtime_permissions.sql
```

Los roles pueden resembrarse de forma segura si fuera necesario:

```bash
psql -h 127.0.0.1 -U sa_owner -d sistema_academico_dev \
  -f 00-Documentacion/database/17_security_seed_roles.sql
```

No ejecutar `run_all.sql` sobre la base validada.

## 4. Validación Symfony

```bash
php bin/console cache:clear
php bin/console lint:container
php bin/console lint:twig templates
php bin/console debug:config security
php bin/console app:audit:preflight
php bin/console app:security:audit
```

El voter de notas está adaptado a la firma de Symfony 8.1, incluida la instancia opcional `Vote`.

## 5. Crear el primer usuario institucional

```bash
php bin/console app:security:create-user
```

La contraseña se solicita de forma oculta y Symfony la almacena únicamente como hash.

Para el usuario inicial se recomienda combinar:

- `ROLE_COORDINACION`
- `ROLE_GESTION_USUARIOS`

No existe un rol `SUPER_ADMIN`.

Después, volver a ejecutar:

```bash
php bin/console app:security:audit
```

El resultado esperado es:

```text
[OK] Seguridad certificada para iniciar pruebas funcionales por rol.
```

## 6. Reiniciar el servidor Symfony

```bash
symfony server:stop
symfony server:start -d --allow-all-ip
symfony server:status
```

A partir de aquí, las rutas académicas exigen sesión real y la autorización depende de los roles persistidos en PostgreSQL y de las reglas de Symfony Security.
