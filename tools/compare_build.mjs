import { chromium } from 'playwright';
import fs from 'fs';

const mockDir = '00-Documentacion/UXUI_Master_Sistema_Academico/mockups';
const vpDir = '/tmp/opencode/vp';
const outDir = '/tmp/opencode/cmp';
const names = fs.readdirSync(vpDir).filter(f => f.endsWith('.png')).map(f => f.replace('.png', '')).sort();

const browser = await chromium.launch();
for (const name of names) {
  const mock = `data:image/png;base64,${fs.readFileSync(`${mockDir}/${name}.png`).toString("base64")}`;
  const cur = `data:image/png;base64,${fs.readFileSync(`${vpDir}/${name}.png`).toString("base64")}`;
  if (!fs.existsSync(`${mockDir}/${name}.png`)) { console.log('missing mockup for', name); continue; }
  const page = await browser.newPage({ viewport: { width: 1620, height: 700 } });
  await page.setContent(`<!DOCTYPE html><html><head><meta charset="utf-8"><style>
    * { box-sizing: border-box; margin: 0; }
    body { font-family: Georgia, serif; background: #1c1917; color: #fff; padding: 14px 18px; }
    h1 { font-size: 19px; font-weight: 700; margin-bottom: 10px; letter-spacing: .3px; }
    .cols { display: flex; gap: 16px; align-items: flex-start; }
    .col { flex: 1; }
    .tag { display: inline-block; font-size: 12px; letter-spacing: 1.4px; text-transform: uppercase;
           padding: 3px 9px; border-radius: 3px; margin-bottom: 7px; font-family: system-ui, sans-serif; }
    .tag.a { background: #C86F50; color: #fff; }
    .tag.b { background: #667E88; color: #fff; }
    img { width: 100%; display: block; border: 1px solid #44403c; border-radius: 4px; }
  </style></head><body>
    <h1>${name.replace(/_/g, ' ')}</h1>
    <div class="cols">
      <div class="col"><span class="tag a">Mockup (maqueta)</span><img src="${mock}"></div>
      <div class="col"><span class="tag b">Implementación actual</span><img src="${cur}"></div>
    </div>
  </body></html>`);
  await page.waitForTimeout(250);
  await page.screenshot({ path: `${outDir}/${name}.png`, fullPage: true });
  await page.close();
  console.log('cmp', name);
}
await browser.close();
console.log('done');
