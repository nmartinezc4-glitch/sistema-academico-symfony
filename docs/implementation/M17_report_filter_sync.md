# M17 · Sincronía de filtros, vista previa y Excel

## Hallazgo

Los siete reportes tenían dos rutas de obtención de datos: la página web resolvía
sus filas directamente en el controlador/repositorio, mientras Vista previa y
Excel reconstruían el reporte mediante `ReportExportBuilder`. Además, los
botones de exportación eran enlaces construidos con la query ya existente en la
URL; si el usuario cambiaba un filtro y exportaba antes de volver a enviar el
formulario, la selección visible no viajaba al reporte generado.

## Corrección

- `ReportController` usa ahora `ReportExportBuilder`, la misma fuente que
  Vista previa y Excel.
- `ReportFilterSet` es la única traducción de parámetros HTTP a filtros
  canónicos.
- Los botones Vista previa PDF y Excel son `submit` del mismo formulario GET
  y usan `formaction`; por tanto envían los valores que el usuario tiene
  seleccionados en ese instante.
- `app:audit:report-filters` verifica automáticamente filtros representativos
  de los siete reportes.

## Regla funcional

> Lo que el usuario filtra es exactamente lo que ve, previsualiza y exporta.

No se deben volver a implementar filtros independientes en controladores de
exportación ni construir enlaces de descarga leyendo manualmente la query.
