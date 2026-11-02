import { chromium } from 'playwright';
import fs from 'fs';

const files = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage();
for (const f of files) {
  const b64 = fs.readFileSync(f).toString('base64');
  const stats = await page.evaluate(async (src) => {
    const img = new Image();
    await new Promise((res, rej) => { img.onload = res; img.onerror = rej; img.src = src; });
    const w = 160, h = Math.max(1, Math.round(img.height * 160 / img.width));
    const c = document.createElement('canvas'); c.width = w; c.height = h;
    const ctx = c.getContext('2d'); ctx.drawImage(img, 0, 0, w, h);
    const d = ctx.getImageData(0, 0, w, h).data;
    let sum = 0, min = 255, max = 0; const colors = new Set();
    for (let i = 0; i < d.length; i += 4) {
      const v = (d[i] + d[i+1] + d[i+2]) / 3; sum += v; if (v < min) min = v; if (v > max) max = v;
      colors.add((d[i]>>4) + ',' + (d[i+1]>>4) + ',' + (d[i+2]>>4));
    }
    return { mean: Math.round(sum / (d.length / 4)), min: Math.round(min), max: Math.round(max), colors: colors.size, w: img.width, h: img.height };
  }, `data:image/png;base64,${b64}`);
  console.log(f, JSON.stringify(stats));
}
await browser.close();
