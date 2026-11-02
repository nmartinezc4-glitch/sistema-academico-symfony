# V2 Binding Notes

- `DemoDataProvider` se reemplaza por Application Services/Repositories. Los templates NO cambian: el mismo array/ViewModel entra a cada vista.
- ViewModels objetivo (ver `docs/12_CONTRATO_DATOS_UI.md`): `StudentSummaryViewModel`, `StudentPeriodViewModel`, `GradeEntryRowViewModel` (forma de `SIS_ACA_VW_INGRESO_NOTAS`), `ResultRowViewModel`, `CurriculumViewModel`, `ProgressViewModel`.
- `StatusCatalog` seguirá siendo el origen de labels/tonos; V2 solo debe poblar los mismos valores de estado.
- No hay SQL en controllers/templates; los joins futuros viven en repositorio.
- Fotos: `photoPath` ya está en el fixture; V2 resolverá upload a filesystem.
- XLSX/PDF: templates `export/*` y `print/*` son el contrato visual; V2 añade PhpSpreadsheet y motor PDF sin tocar el layout.
