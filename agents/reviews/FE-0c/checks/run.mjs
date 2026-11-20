// QA stand-in runner: node run.mjs <frontend dir>. Runs theme.test.js in Node (fake documentElement, Node webstorage)
// and ThemeToggle.test.jsx in headless Chrome (real react-dom 19.2.8, Radix/lucide/Button stubbed).
import { createRequire } from 'node:module';
import fs from 'node:fs'; import path from 'node:path'; import { execFileSync } from 'node:child_process';
const require = createRequire('/opt/npm-tools/node_modules/');
const esbuild = require('esbuild'); const { chromium } = require('playwright');
const H = path.dirname(new URL(import.meta.url).pathname);
const FE = path.resolve(process.argv[2]);
const shims = {
  name: 'qa-shims',
  setup(b) {
    b.onResolve({ filter: /^vitest$/ }, () => ({ path: `${H}/vitest-shim.js` }));
    b.onResolve({ filter: /^@testing-library\/react$/ }, () => ({ path: `${H}/tl-shim.js` }));
    b.onResolve({ filter: /^(lucide-react|\.\/ui\/button|\.\/ui\/dropdown-menu)$/ }, () => ({ path: `${H}/stubs.jsx` }));
    b.onResolve({ filter: /^react(-dom)?(\/.*)?$/ }, (a) => ({ path: require.resolve(a.path) }));
  },
};
// theme.test.js in Node; the bundle sits next to the test so import.meta.url resolves ../../index.html the same way.
const nodeEntry = `${FE}/src/lib/__qa_entry.mjs`, nodeOut = `${FE}/src/lib/__qa_bundle.mjs`;
fs.writeFileSync(nodeEntry, `import '${H}/node-dom.js';\nimport './theme.test.js';\nimport { __run } from 'vitest';\nconsole.log(await __run('src/lib/theme.test.js'));\n`);
await esbuild.build({ entryPoints: [nodeEntry], bundle: true, platform: 'node', format: 'esm', outfile: nodeOut, plugins: [shims], logLevel: 'error' });
const lsFile = `${FE}/../__qa_ls_${process.pid}.db`;
let nodeOutTxt;
try { nodeOutTxt = execFileSync('node', ['--no-warnings', '--experimental-webstorage', `--localstorage-file=${lsFile}`, nodeOut], { encoding: 'utf8' }); }
catch (e) { nodeOutTxt = (e.stdout || '') + (e.stderr || ''); }
console.log(nodeOutTxt.trim());
// ThemeToggle.test.jsx in Chrome.
const brEntry = `${FE}/src/components/__qa_entry.jsx`;
fs.writeFileSync(brEntry, `import { afterEach } from 'vitest';\nimport { cleanup } from '@testing-library/react';\nafterEach(() => cleanup());\nimport('./ThemeToggle.test.jsx').then(async () => { const { __run } = await import('vitest'); window.__done(await __run('src/components/ThemeToggle.test.jsx')); });\n`);
const br = await esbuild.build({ entryPoints: [brEntry], bundle: true, format: 'iife', write: false, jsx: 'automatic', loader: { '.js': 'jsx' }, define: { 'process.env.NODE_ENV': '"development"' }, plugins: [shims], logLevel: 'error' });
const browser = await chromium.launch({ executablePath: '/usr/bin/google-chrome' });
const page = await browser.newPage();
const errors = []; page.on('pageerror', (e) => errors.push(e.message));
await page.route('http://qa.local/**', (r) => r.request().url().endsWith('.js')
  ? r.fulfill({ contentType: 'text/javascript', body: br.outputFiles[0].text })
  : r.fulfill({ contentType: 'text/html', body: '<!doctype html><html><head></head><body><script src="/b.js"></script></body></html>' }));
const done = new Promise((res) => page.exposeFunction('__done', res));
await page.goto('http://qa.local/');
const result = await Promise.race([done, new Promise((r) => setTimeout(() => r('TIMEOUT ' + errors.join('; ')), 20000))]);
console.log(result);
await browser.close();
for (const f of [nodeEntry, nodeOut, brEntry, lsFile]) fs.rmSync(f, { force: true });
