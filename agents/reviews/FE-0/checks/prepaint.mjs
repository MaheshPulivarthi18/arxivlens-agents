// QA (independent): run the inline pre-paint <script> from frontend/index.html in a vm sandbox
// with stubbed localStorage / matchMedia / document, for every {stored} x {OS} combination.
import fs from 'node:fs'; import vm from 'node:vm';
const html = fs.readFileSync('frontend/index.html', 'utf8');
const scripts = [...html.matchAll(/<script(?![^>]*\bsrc=)([^>]*)>([\s\S]*?)<\/script>/g)];
const inline = scripts.filter(m => !/type=["']module/.test(m[1]));
console.log(`inline classic scripts in index.html: ${inline.length}`);
const src = inline[0][2];
const headEnd = html.indexOf('</head>'), scriptPos = html.indexOf(inline[0][0]), modPos = html.indexOf('type="module"');
console.log(`pre-paint script in <head> (before </head>): ${scriptPos < headEnd}; before module script: ${scriptPos < modPos}`);
const stores = { none: null, light: 'light', dark: 'dark', system: 'system', invalid: 'purple', empty: '', throws: 'THROW' };
let fail = 0;
const expect = (stored, osDark) => (stored === 'light') ? 'light' : (stored === 'system') ? (osDark ? 'dark' : 'light') : 'dark';
console.log('stored     | OS     | class .dark | colorScheme | expected | result');
for (const [name, v] of Object.entries(stores)) for (const osDark of [true, false]) {
  const cls = new Set(['preexisting']); const style = {}; const keysRead = [];
  const ctx = {
    localStorage: { getItem(k) { keysRead.push(k); if (v === 'THROW') throw new Error('SecurityError'); return v; } },
    document: { documentElement: { classList: { toggle(c, on) { on ? cls.add(c) : cls.delete(c); } }, style } },
  };
  ctx.window = { matchMedia: (q) => ({ matches: q === '(prefers-color-scheme: dark)' ? osDark : false }) };
  vm.runInNewContext(src, ctx);
  const got = cls.has('dark') ? 'dark' : 'light'; const exp = expect(name === 'none' ? null : v, osDark);
  const ok = got === exp && style.colorScheme === got && keysRead.every(k => k === 'arxivlens-theme');
  if (!ok) fail++;
  console.log(`${name.padEnd(10)} | ${(osDark ? 'dark' : 'light').padEnd(6)} | ${String(cls.has('dark')).padEnd(11)} | ${String(style.colorScheme).padEnd(11)} | ${exp.padEnd(8)} | ${ok ? 'PASS' : 'FAIL'}`);
}
// matchMedia missing entirely (old browser): system must not throw
{ const cls = new Set(); const style = {};
  const ctx = { localStorage: { getItem: () => 'system' }, window: {}, document: { documentElement: { classList: { toggle(c, on) { on ? cls.add(c) : cls.delete(c); } }, style } } };
  let err = null; try { vm.runInNewContext(src, ctx); } catch (e) { err = e; }
  const ok = !err && !cls.has('dark') && style.colorScheme === 'light'; if (!ok) fail++;
  console.log(`system, no matchMedia -> ${err ? 'THREW ' + err.message : (cls.has('dark') ? 'dark' : 'light')} (expected light, no throw): ${ok ? 'PASS' : 'FAIL'}`); }
// stored dark then light: class must be removed (toggle, not add-only)
{ const cls = new Set(['dark']); const style = {};
  const ctx = { localStorage: { getItem: () => 'light' }, window: { matchMedia: () => ({ matches: true }) }, document: { documentElement: { classList: { toggle(c, on) { on ? cls.add(c) : cls.delete(c); } }, style } } };
  vm.runInNewContext(src, ctx); const ok = !cls.has('dark'); if (!ok) fail++;
  console.log(`pre-existing .dark + stored light -> .dark removed: ${ok ? 'PASS' : 'FAIL'}`); }
const m = src.match(/var DEFAULT_THEME = '(\w+)'/); const key = src.match(/getItem\('([^']+)'\)/);
console.log(`pre-paint DEFAULT_THEME = ${m && m[1]}, key = ${key && key[1]}, comment points at src/lib/theme.js: ${/src\/lib\/theme\.js/.test(src)}`);
console.log(fail ? `RESULT: ${fail} FAIL` : 'RESULT: ALL PASS');
process.exit(fail ? 1 : 0);
