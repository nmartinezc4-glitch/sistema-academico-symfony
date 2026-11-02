# 18 — Contrato de Login y Seguridad Visual

## 1. Alcance V1

Solo UI. No crear tabla de usuarios dentro del esquema SIS_ACA. No reutilizar Student como User.

## 2. Pantalla

Layout split:
- izquierda: identidad visual/campus;
- derecha: login card.

Campos:
- username/email institucional;
- password;
- remember me.

Acciones:
- iniciar sesión;
- recuperación futura;
- acceso administrativo solo si el producto realmente lo requiere; en V1 puede ser visual disabled.

## 3. Backend futuro

Symfony Security:
- entidad `User`/provider independiente;
- password hasher;
- roles;
- CSRF;
- login throttling;
- session;
- logout.

Posibles roles:
- ROLE_ADMIN;
- ROLE_ACADEMIC_COORDINATOR;
- ROLE_OPERATOR;
- ROLE_VIEWER.

No implementar permisos finales hasta definir matriz de autorización.

## 4. Errores

Credenciales inválidas:
`No pudimos iniciar sesión con las credenciales proporcionadas.`

No revelar si el correo existe.

## 5. Accesibilidad

- autocomplete username/current-password;
- botón show password con aria-label;
- focus;
- error summary;
- keyboard.

## 6. Seguridad visual

No prometer seguridad específica (“cifrado institucional”) si aún no está implementada. El texto del mockup debe tratarse como ilustrativo.
