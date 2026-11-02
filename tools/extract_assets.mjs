import { chromium } from 'playwright';
import fs from 'fs';

const M = '00-Documentacion/UXUI_Master_Sistema_Academico/mockups';
const OUT = 'public/images';

const crops = [
  ['01_dashboard.png',           1240,  60, 296, 140, 'hero-campus.jpg',  'image/jpeg'],
  ['16_login.png',                520, 520, 316, 421, 'login-panel.jpg',   'image/jpeg'],
  ['01_dashboard.png',              0, 858, 250, 166, 'sidebar-art.png',    'image/png'],
  ['01_dashboard.png',           1252,  14,  46,  46, 'avatar-user.jpg',   'image/jpeg'],
];

const browser = await chromium.launch();
const page = await browser.newPage();
for (const [file, x, y, w, h, out, mime] of crops) {
  const src = `data:image/png;base64,${fs.readFileSync(`${M}/${file}`).toString('base64')}`;
  const dataUrl = await page.evaluate(async ({ src, x, y, w, h, mime }) => {
    const img = new Image();
    await new Promise((res, rej) => { img.onload = res; img.onerror = rej; img.src = src; });
    const c = document.createElement('canvas');
    c.width = w; c.height = h;
    c.getContext('2d').drawImage(img, x, y, w, h, 0, 0, w, h);
    return c.toDataURL(mime, 0.88);
  }, { src, x, y, w, h, mime });
  fs.writeFileSync(`${OUT}/${out}`, Buffer.from(dataUrl.split(',')[1], 'base64'));
}

const html = `<!DOCTYPE html><html><head><meta charset="utf-8"><style>
 body{background:#1c1917;color:#fff;font:14px system-ui;padding:14px;margin:0}
 .g{display:grid;grid-template-columns:repeat(4,1fr);gap:10px}
 figure{margin:0} figcaption{font-size:11px;color:#c8c1b8;margin-bottom:4px}
 img{width:100%;display:block;border:1px solid #44403c}
</style></head><body><div class="g">
${crops.map(([, , , , , out]) => `<figure><figcaption>${out}</figcaption><img src="data:image/jpeg;base64,${fs.readFileSync(`${OUT}/${out}`).toString('base64')}"></figure>`).join('')}
</div></body></html>`;
await page.setViewportSize({ width: 1400, height: 560 });
await page.setContent(html);
await page.waitForTimeout(300);
await page.screenshot({ path: '/tmp/opencode/assets_sheet5.png', fullPage: true });
await browser.close();
console.log('ok');
