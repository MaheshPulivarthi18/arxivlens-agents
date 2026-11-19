// QA (independent): parse :root and .dark HSL tokens from frontend/src/index.css, check every Scope token
// is defined in both, and compute WCAG 2.1 contrast for every AC4 pair (HSL -> sRGB -> relative luminance).
import fs from 'node:fs';
const css = fs.readFileSync('frontend/src/index.css', 'utf8');
const block = (sel) => { const i = css.indexOf(sel + ' {'); const j = css.indexOf('}', i); return css.slice(i, j); };
const parse = (b) => Object.fromEntries([...b.replace(/\/\*[\s\S]*?\*\//g, '').matchAll(/--([\w-]+):\s*([^;]+);/g)].map(m => [m[1], m[2].trim()]));
const themes = { light: parse(block(':root')), dark: parse(block('.dark')) };
const required = ['background','foreground','card','card-foreground','popover','popover-foreground','primary','primary-foreground',
  'secondary','secondary-foreground','muted','muted-foreground','accent','accent-foreground','destructive','destructive-foreground',
  'border','input','ring','supported','supported-foreground','unsupported','unsupported-foreground','unchecked','unchecked-foreground'];
let fail = 0;
for (const [t, v] of Object.entries(themes)) {
  const missing = required.filter(k => !(k in v)); if (missing.length) fail++;
  console.log(`${t}: ${required.length - missing.length}/${required.length} required colour tokens defined${missing.length ? ' MISSING: ' + missing : ''}`);
}
const hsl2rgb = (s) => { const [h, S, L] = s.split(/\s+/).map(parseFloat); const sat = S / 100, l = L / 100;
  const k = (n) => (n + h / 30) % 12, a = sat * Math.min(l, 1 - l);
  const f = (n) => l - a * Math.max(-1, Math.min(k(n) - 3, Math.min(9 - k(n), 1)));
  return [f(0), f(8), f(4)].map(c => Math.round(c * 255)); };
const lum = (rgb) => { const [r, g, b] = rgb.map(c => { c /= 255; return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4; }); return 0.2126 * r + 0.7152 * g + 0.0722 * b; };
const ratio = (a, b) => { const [x, y] = [lum(hsl2rgb(a)), lum(hsl2rgb(b))].sort((p, q) => q - p); return (x + 0.05) / (y + 0.05); };
const hex = (s) => '#' + hsl2rgb(s).map(c => c.toString(16).padStart(2, '0')).join('');
const pairs = [
  ['foreground','background',4.5],['card-foreground','card',4.5],['popover-foreground','popover',4.5],
  ['muted-foreground','background',4.5],['muted-foreground','card',4.5],['muted-foreground','muted',4.5],
  ['primary-foreground','primary',4.5],['secondary-foreground','secondary',4.5],['accent-foreground','accent',4.5],
  ['destructive-foreground','destructive',4.5],['primary','background',4.5,'link text'],['primary','card',4.5,'link text'],
  ['supported-foreground','supported',4.5],['unsupported-foreground','unsupported',4.5],['unchecked-foreground','unchecked',4.5],
  ['ring','background',3],['ring','card',3],['input','background',3,'control outline'],['input','card',3,'control outline'],
  // extra pairs used by this PR's own UI: Navbar active tab text on bg-secondary, menu label on popover, highlighted item
  ['foreground','secondary',4.5,'active tab (this PR)'],['muted-foreground','popover',4.5,'menu label (this PR)'],
  ['accent-foreground','accent',4.5,'highlighted menu item (this PR)'],['muted-foreground','secondary',4.5,'inactive tab hover n/a; info'],
];
console.log('\npair (text/UI on surface)                          min   light   dark   result');
for (const [fg, bg, min, note] of pairs) {
  const l = ratio(themes.light[fg], themes.light[bg]), d = ratio(themes.dark[fg], themes.dark[bg]);
  const ok = l >= min && d >= min; if (!ok) fail++;
  console.log(`${(fg + ' on ' + bg + (note ? ' [' + note + ']' : '')).padEnd(50)} ${String(min).padEnd(5)} ${l.toFixed(2).padStart(6)} ${d.toFixed(2).padStart(6)}   ${ok ? 'PASS' : 'FAIL'}`);
}
const bl = ratio(themes.light.border, themes.light.background), bd = ratio(themes.dark.border, themes.dark.background);
console.log(`${'border on background [decorative, no minimum]'.padEnd(50)} n/a   ${bl.toFixed(2).padStart(6)} ${bd.toFixed(2).padStart(6)}   info`);
// design table cross-check: hex values match docs/design/FE-0.md §1
console.log('\ntoken hex (light / dark): ' + ['background','primary','input','unsupported-foreground','unchecked-foreground'].map(k => `${k} ${hex(themes.light[k])}/${hex(themes.dark[k])}`).join(', '));
console.log(`radius: ${themes.light.radius}`);
console.log(fail ? `RESULT: ${fail} FAIL` : 'RESULT: ALL PASS');
process.exit(fail ? 1 : 0);
