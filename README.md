# Sistema Académico

Sistema de gestión académica universitaria: estudiantes, pensums, calendario,
ofertas académicas, ingreso de notas y reportes (con exportación a PDF y Excel).

Proyecto final del curso Desarrollo Web, Universidad Mariano Gálvez (UMG).
Trabajo en equipo.

> **Aviso:** proyecto educativo. Todos los datos de ejemplo son ficticios.
> No está preparado para ponerse en internet tal cual (modo desarrollo, sin
> límite de intentos de inicio de sesión). No lo uses con datos reales.

## Tecnologías

- Symfony 8.1, PHP 8.4 o superior, Twig, AssetMapper y Stimulus
- Doctrine DBAL (sin ORM) sobre PostgreSQL 16
- Base de datos primero: tablas, vistas, triggers y reglas de negocio en SQL
- PhpSpreadsheet (Excel) y Dompdf (PDF)

## Requisitos

PHP con las extensiones `pdo_pgsql`, `intl`, `mbstring`, `xml`, `zip` y `gd`;
Composer; PostgreSQL 16; Symfony CLI (opcional).

## Instalación

1. Instala las dependencias:
   ```bash
   composer install
   ```
2. Crea los roles y la base de datos en PostgreSQL. La app usa dos roles:
   `sa_owner` (crea y mantiene la estructura) y `sa_app` (el que usa la
   aplicación al correr). Los pasos están en `docs/SEGURIDAD_INSTALACION.md`.
3. Carga los scripts de `00-Documentacion/database/` en el orden que indica su
   `README.md`. Atención: `00_reset.sql` borra y recrea los datos.
4. Configura el entorno:
   ```bash
   cp .env.example .env.local
   # edita .env.local con tu clave y tu APP_SECRET
   ```
5. Crea un usuario (los scripts no crean ninguno; la clave lleva mínimo 10
   caracteres):
   ```bash
   php bin/console app:security:create-user
   ```
6. Inicia el servidor y abre http://localhost:8000
   ```bash
   symfony server:start
   ```

## Documentación

- `00-Documentacion/` — base de datos, modelo y especificación de diseño
- `docs/` — seguridad, instalación y notas de implementación

## Licencia

MIT. Consulta el archivo `LICENSE`.
