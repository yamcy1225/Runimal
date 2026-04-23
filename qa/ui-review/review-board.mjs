import { chromium, webkit, devices } from 'playwright';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { createServer } from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..', '..');
const outputDir = path.join(__dirname, 'output');
const boardPort = Number(process.env.RUNIMAL_UI_REVIEW_PORT || 4173);
const boardUrl = `http://127.0.0.1:${boardPort}/index.html`;

const cases = [
  {
    id: 'desktop-chrome',
    label: 'Desktop Chrome',
    launcher: chromium,
    contextOptions: { viewport: { width: 1440, height: 2200 } },
  },
  {
    id: 'mobile-safari',
    label: 'Mobile Safari Emulation',
    launcher: webkit,
    contextOptions: { ...devices['iPhone 15 Pro'] },
  },
  {
    id: 'narrow-desktop',
    label: 'Narrow Desktop',
    launcher: chromium,
    contextOptions: { viewport: { width: 1024, height: 2200 } },
  },
];

await mkdir(outputDir, { recursive: true });

const server = createServer(async (request, response) => {
  const requestPath = request.url === '/' ? '/index.html' : request.url || '/index.html';
  const filePath = path.join(__dirname, requestPath.replace(/^\/+/, ''));

  try {
    const data = await readFile(filePath);
    const ext = path.extname(filePath);
    const contentType =
      ext === '.html' ? 'text/html; charset=utf-8'
      : ext === '.json' ? 'application/json; charset=utf-8'
      : ext === '.png' ? 'image/png'
      : 'text/plain; charset=utf-8';
    response.writeHead(200, { 'Content-Type': contentType });
    response.end(data);
  } catch {
    response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
    response.end('Not found');
  }
});

await new Promise((resolve) => server.listen(boardPort, '127.0.0.1', resolve));

const reportLines = [
  '# Runimal UI Review Board Report',
  '',
  `- Board: ${boardUrl}`,
  `- Generated at: ${new Date().toISOString()}`,
  '',
];

try {
  for (const reviewCase of cases) {
    const browser = await reviewCase.launcher.launch({ headless: true });
    const context = await browser.newContext(reviewCase.contextOptions);
    const page = await context.newPage();

    await page.goto(boardUrl);
    await page.waitForLoadState('networkidle');

    const captureCards = await page.locator('.capture-card').count();
    const missingCards = await page.locator('.capture-card[data-missing="true"]').count();
    const screenshotPath = path.join(outputDir, `${reviewCase.id}.png`);

    await page.screenshot({ path: screenshotPath, fullPage: true });

    reportLines.push(`## ${reviewCase.label}`);
    reportLines.push('');
    reportLines.push(`- Screenshot: ${path.relative(repoRoot, screenshotPath)}`);
    reportLines.push(`- Cards visible: ${captureCards}`);
    reportLines.push(`- Manifest rows missing one side: ${missingCards}`);
    reportLines.push('');

    await browser.close();
  }
} finally {
  await new Promise((resolve, reject) => {
    server.close((error) => {
      if (error) {
        reject(error);
      } else {
        resolve();
      }
    });
  });
}

await writeFile(path.join(outputDir, 'review-report.md'), reportLines.join('\n'), 'utf8');
console.log(path.join(outputDir, 'review-report.md'));
