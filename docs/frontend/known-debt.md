# Known Debt

- Screenshots QA capturadas en `docs/frontend/screenshots/` (desktop 1536, tablet 768, mobile 390) vía headless shell; Playwright local con libs extraídas (`~/libs`).
- Filtros GET sin estado completo en todos los reportes (pendiente de pulir en GATE 7).
- Gráficos reemplazados por progress/tablas accesibles (decisión documentada).
- Sin tests PHPUnit aún; suite `php bin/phpunit` pendiente de instalar con `symfony/test-pack`.
- Login visual únicamente; SecurityBundle queda para V2.
- ~~Export XLSX/PDF/impresión aún genera la vista, no el archivo binario~~ → **resuelto** (PhpSpreadsheet + Dompdf, `docs/implementation/M16_export_real.md`).
- Escritura de estudiantes completa (create/update/delete/retirar, `M15_student_crud.md`); secciones/ofertas/políticas quedan de solo lectura en V1.
