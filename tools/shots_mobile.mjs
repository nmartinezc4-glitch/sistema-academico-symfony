import { chromium } from 'playwright';
const base = 'http://127.0.0.1:8000';
const routes = [
  ['01_dashboard', '/'], ['16_login', '/login'], ['02_alumnos', '/alumnos'],
  ['04_nuevo_estudiante', '/alumnos/nuevo'], ['03_perfil', '/alumnos/1'],
  ['07_expediente', '/expedientes/1'], ['05_pensum', '/pensums/1'],
  ['06_ingreso_notas', '/evaluacion/notas'], ['08_centro_reportes', '/reportes'],
  ['19_print', '/impresion/reporte'],
];
const browser = await chromium.launch();
for (const [name, path] of routes) {
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  await page.goto(base + path, { waitUntil: 'networkidle' });
  await page.screenshot({ path: `docs/frontend/screenshots/${name}_mobile.png`, fullPage: true });
  await page.close();
}
await browser.close();
console.log('done');
