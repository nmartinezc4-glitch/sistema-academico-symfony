# Cierre de auditoría de aplicación

Fecha de cierre técnico: 2026-10-10

## Alcance

Este bloque corrige la lógica de aplicación sin modificar ni regenerar los datos históricos cargados por los scripts seed. PostgreSQL continúa siendo la fuente de verdad y mantiene sus restricciones, vistas y triggers de integridad.

## Hallazgos cerrados

- Códigos institucionales:
  - estudiante: `STU-AAAA-NNNN`;
  - política: `POL-AAAA-NN`;
  - curso: `SIGLA-###`, iniciando en 101 cuando la sigla es nueva;
  - sección: secuencia alfabética `A, B, C ... Z, AA...`;
  - carrera: sigla semántica, sugerida automáticamente y ajustable por coordinación;
  - pensum: `SIGLA-CARRERA-AAAA`, con sufijo de versión solo cuando existe colisión en el mismo año.
- Se implementaron las operaciones faltantes de escritura de notas y eliminación segura de estudiantes sin historial.
- La asignación de pensum valida vigencia contra la fecha de ingreso.
- Un pensum no puede activarse si existe un ciclo activo sin al menos un curso obligatorio.
- El cierre de período se bloquea cuando quedan cursos sin oferta, sin registro o pendientes de nota.
- Se habilitó reapertura explícita de períodos cerrados para correcciones excepcionales.
- El año lectivo se cierra automáticamente cuando sus dos períodos están cerrados y vuelve a ABIERTO si un período se reabre.
- Todas las operaciones POST de la interfaz incluyen protección CSRF de sesión.
- El acceso dejó de ser un login visual: ahora requiere usuario configurado, contraseña verificada mediante hash y sesión autenticada.
- Los controladores abandonaron el namespace `Demo` y se retiró `DemoDataProvider`.
- Reportes: los filtros se aplican en servidor y la exportación académica utiliza un único XLSX simple, sin hojas de metadatos técnicos.
- Se retiraron exportadores legacy PDF/XLSX que producían flujos duplicados y configuraciones técnicas.
- Se agregó `app:audit:preflight` como verificación automatizada previa a pruebas funcionales.

## Seguridad final

La autenticación temporal mediante `APP_LOGIN_USER` y
`APP_LOGIN_PASSWORD_HASH` fue sustituida por Symfony Security y usuarios
persistentes en `SIS_SEG_USUARIO`.

No existe contraseña institucional versionada ni usuario de negocio en
`.env.local`. Antes de crear el primer usuario, el entorno debe instalar las dependencias de seguridad y aplicar el esquema aditivo:

```bash
composer update symfony/security-bundle symfony/security-csrf --with-all-dependencies
psql -h 127.0.0.1 -U sa_owner -d sistema_academico_dev -f 00-Documentacion/database/16_security_schema.sql
psql -h 127.0.0.1 -U sa_owner -d sistema_academico_dev -f 00-Documentacion/database/17_security_seed_roles.sql
psql -h 127.0.0.1 -U sa_owner -d sistema_academico_dev -f 00-Documentacion/database/15_runtime_permissions.sql
php bin/console app:security:create-user
```

No ejecutar `run_all.sql` sobre la base validada para esta actualización, porque su primer paso es destructivo en desarrollo.

La autorización se resuelve mediante roles persistentes, `access_control` y
voters contextuales.

## Verificación previa

Ejecutar después de actualizar la rama:

```bash
php bin/console cache:clear
php bin/console lint:container
php bin/console lint:twig templates
find src -name '*.php' -print0 | xargs -0 -n1 php -l
php bin/console debug:router
php bin/console debug:config security
php bin/console app:audit:preflight
```

La fase siguiente es la prueba funcional controlada de altas, códigos, pensums, inscripciones, notas, cierres, reportes y exportaciones.
