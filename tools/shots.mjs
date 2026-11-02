import { chromium } from 'playwright';
const base = 'http://127.0.0.1:8000';
const routes = [
  ['01_dashboard', '/'], ['16_login', '/login'], ['02_alumnos', '/alumnos'],
  ['04_nuevo_estudiante', '/alumnos/nuevo'], ['03_perfil', '/alumnos/1'],
  ['07_expediente', '/expedientes/1'], ['05_pensum', '/pensums/1'],
  ['06_ingreso_notas', '/evaluacion/notas'], ['08_centro_reportes', '/reportes'],
  ['09_alumnos_carrera', '/reportes/alumnos-carrera'], ['10_notas_carrera', '/reportes/notas-carrera'],
  ['11_notas_curso', '/reportes/notas-curso'], ['12_notas_seccion', '/reportes/notas-seccion'],
  ['13_avance_estudiante', '/reportes/avance-estudiante'], ['14_avance_ciclo', '/reportes/avance-ciclo'],
  ['15_pendientes', '/reportes/pendientes-repitencias'], ['17_xlsx', '/exportaciones/xlsx'],
  ['18_pdf', '/exportaciones/pdf'], ['19_print', '/impresion/reporte'], ['ui_kit', '/ui-kit'],
];
const browser = await chromium.launch();
const viewports = [['desktop', 1536, 1024], ['tablet', 768, 1024]];
for (const [name, path] of routes) {
  for (const [label, w, h] of viewports) {
    const page = await browser.newPage({ viewport: { width: w, height: h } });
    await page.goto(base + path, { waitUntil: 'networkidle' });
    await page.screenshot({ path: `docs/frontend/screenshots/${name}_${label}.png`, fullPage: true });
    await page.close();
  }
}
await browser.close();
console.log('done');
