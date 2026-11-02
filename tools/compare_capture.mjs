import { chromium } from 'playwright';
const base = 'http://127.0.0.1:8000';
const routes = [
  ['01_dashboard', '/'],
  ['02_alumnos_listado', '/alumnos'],
  ['03_perfil_estudiante', '/alumnos/1'],
  ['04_nuevo_estudiante', '/alumnos/nuevo'],
  ['05_pensum_builder', '/pensums/1'],
  ['06_ingreso_notas', '/evaluacion/notas'],
  ['07_expediente_academico', '/expedientes/1'],
  ['08_centro_reportes', '/reportes'],
  ['09_reporte_alumnos_carrera', '/reportes/alumnos-carrera'],
  ['10_reporte_notas_carrera', '/reportes/notas-carrera'],
  ['11_reporte_notas_curso', '/reportes/notas-curso'],
  ['12_reporte_notas_seccion', '/reportes/notas-seccion'],
  ['13_reporte_avance_estudiante', '/reportes/avance-estudiante'],
  ['14_reporte_avance_ciclo', '/reportes/avance-ciclo'],
  ['15_reporte_pendientes_repitencias', '/reportes/pendientes-repitencias'],
  ['16_login', '/login'],
  ['17_exportacion_xlsx', '/exportaciones/xlsx'],
  ['18_vista_previa_pdf', '/exportaciones/pdf'],
  ['19_vista_impresion', '/impresion/reporte'],
];
const browser = await chromium.launch();
for (const [name, path] of routes) {
  const page = await browser.newPage({ viewport: { width: 1536, height: 1024 } });
  await page.goto(base + path, { waitUntil: 'networkidle' });
  await page.waitForTimeout(300);
  await page.screenshot({ path: `/tmp/opencode/vp/${name}.png` });
  await page.close();
}
await browser.close();
console.log('viewport shots done');
