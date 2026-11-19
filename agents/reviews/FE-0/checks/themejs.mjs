// QA (independent): import frontend/src/lib/theme.js in bare Node (no node_modules) with stubbed globals.
import path from 'node:path'; import { pathToFileURL } from 'node:url'; import fs from 'node:fs';
let fail = 0, n = 0;
const check = (name, cond) => { n++; if (!cond) fail++; console.log(`${cond ? 'PASS' : 'FAIL'}  ${name}`); };
// --- stubs
let store = new Map(); let storageMode = 'ok';
globalThis.localStorage = {
  getItem(k) { if (storageMode === 'throw') throw new Error('SecurityError'); return store.has(k) ? store.get(k) : null; },
  setItem(k, v) { if (storageMode === 'throw' || storageMode === 'quota') throw new Error('QuotaExceededError'); store.set(k, String(v)); },
};
let osDark = true; const listeners = new Set(); let lastQuery = null;
const mql = () => ({ get matches() { return osDark; },
  addEventListener(t, f) { if (t === 'change') listeners.add(f); }, removeEventListener(t, f) { if (t === 'change') listeners.delete(f); } });
globalThis.window = { matchMedia(q) { lastQuery = q; return mql(); } };
const cls = new Set(); const style = {};
globalThis.document = { documentElement: { classList: { toggle(c, on) { on ? cls.add(c) : cls.delete(c); } }, style } };
const osChange = (dark) => { osDark = dark; for (const f of [...listeners]) f({ matches: dark }); };

const T = await import(pathToFileURL(path.resolve('frontend/src/lib/theme.js')).href);
const html = fs.readFileSync('frontend/index.html', 'utf8');
check('exports: THEME_STORAGE_KEY, THEMES, DEFAULT_THEME, getStoredTheme, setStoredTheme, resolveTheme, systemPrefersDark, applyTheme, watchSystemTheme',
  ['THEME_STORAGE_KEY','THEMES','DEFAULT_THEME','getStoredTheme','setStoredTheme','resolveTheme','systemPrefersDark','applyTheme','watchSystemTheme'].every(k => k in T));
check(`DEFAULT_THEME === "dark" (got ${JSON.stringify(T.DEFAULT_THEME)})`, T.DEFAULT_THEME === 'dark');
check(`THEMES = light,dark,system (got ${T.THEMES})`, JSON.stringify(T.THEMES) === '["light","dark","system"]');
check(`same key as index.html pre-paint ("${T.THEME_STORAGE_KEY}")`, html.includes(`getItem('${T.THEME_STORAGE_KEY}')`));
check(`same default as index.html pre-paint`, html.includes(`var DEFAULT_THEME = '${T.DEFAULT_THEME}'`));
check('theme.js comment points at index.html', /index\.html/.test(fs.readFileSync('frontend/src/lib/theme.js','utf8')));
// getStoredTheme
store.clear(); check('getStoredTheme: nothing stored -> dark', T.getStoredTheme() === 'dark');
for (const v of ['light','dark','system']) { store.set(T.THEME_STORAGE_KEY, v); check(`getStoredTheme: stored ${v} -> ${v}`, T.getStoredTheme() === v); }
for (const v of ['purple','', 'DARK', 'null']) { store.set(T.THEME_STORAGE_KEY, v); check(`getStoredTheme: stored ${JSON.stringify(v)} -> dark`, T.getStoredTheme() === 'dark'); }
storageMode = 'throw'; let r; try { r = T.getStoredTheme(); } catch { r = 'THREW'; } check(`getStoredTheme: storage throws -> dark, no throw (got ${r})`, r === 'dark'); storageMode = 'ok';
// setStoredTheme
store.clear(); T.setStoredTheme('light'); check('setStoredTheme(light) persists under arxivlens-theme', store.get('arxivlens-theme') === 'light');
T.setStoredTheme('system'); check('setStoredTheme(system) persists', store.get('arxivlens-theme') === 'system');
T.setStoredTheme('bogus'); check('setStoredTheme(invalid) ignored (keeps system)', store.get('arxivlens-theme') === 'system');
storageMode = 'quota'; try { T.setStoredTheme('dark'); r = 'ok'; } catch { r = 'THREW'; } check('setStoredTheme swallows storage errors', r === 'ok'); storageMode = 'ok';
// resolveTheme
for (const [p, d, e] of [['light',true,'light'],['light',false,'light'],['dark',true,'dark'],['dark',false,'dark'],['system',true,'dark'],['system',false,'light']])
  check(`resolveTheme(${p}, osDark=${d}) -> ${e}`, T.resolveTheme(p, d) === e);
// systemPrefersDark
osDark = true; check('systemPrefersDark() true when OS dark', T.systemPrefersDark() === true && lastQuery === '(prefers-color-scheme: dark)');
osDark = false; check('systemPrefersDark() false when OS light', T.systemPrefersDark() === false);
// applyTheme
osDark = false; check('applyTheme(dark) on OS light -> .dark + colorScheme dark', T.applyTheme('dark') === 'dark' && cls.has('dark') && style.colorScheme === 'dark');
check('applyTheme(light) -> no .dark + colorScheme light', T.applyTheme('light') === 'light' && !cls.has('dark') && style.colorScheme === 'light');
osDark = true; check('applyTheme(system) on OS dark -> dark', T.applyTheme('system') === 'dark' && cls.has('dark'));
osDark = false; check('applyTheme(system) on OS light -> light', T.applyTheme('system') === 'light' && !cls.has('dark'));
check('applyTheme(invalid) -> default dark', T.applyTheme('xyz') === 'dark' && cls.has('dark'));
// watchSystemTheme: OS change applies live in system mode, unsubscribe works
osDark = false; T.applyTheme('system'); const seen = [];
const unsub = T.watchSystemTheme((d) => { seen.push(d); T.applyTheme('system'); });
check('watchSystemTheme subscribes one change listener', listeners.size === 1);
osChange(true); check('OS -> dark while in system: callback(true) and .dark applied without reload', seen.at(-1) === true && cls.has('dark'));
osChange(false); check('OS -> light while in system: callback(false) and .dark removed', seen.at(-1) === false && !cls.has('dark'));
unsub(); check('unsubscribe removes the listener', listeners.size === 0);
osChange(true); check('no callback after unsubscribe', seen.length === 2);
// legacy addListener (Safari < 14)
const legacy = new Set(); globalThis.window = { matchMedia: () => ({ matches: false, addListener: (f) => legacy.add(f), removeListener: (f) => legacy.delete(f) }) };
const u2 = T.watchSystemTheme(() => {}); check('legacy addListener path subscribes', legacy.size === 1); u2(); check('legacy removeListener path unsubscribes', legacy.size === 0);
// no matchMedia / no window / no document / no localStorage
globalThis.window = {}; check('systemPrefersDark() without matchMedia -> false', T.systemPrefersDark() === false);
let u3; try { u3 = T.watchSystemTheme(() => {}); u3(); r = 'ok'; } catch { r = 'THREW'; } check('watchSystemTheme without matchMedia -> no-op unsubscribe', r === 'ok');
delete globalThis.window; delete globalThis.document; delete globalThis.localStorage;
try { r = [T.getStoredTheme(), T.applyTheme('system')].join(','); T.setStoredTheme('light'); } catch (e) { r = 'THREW ' + e.message; }
check(`no window/document/localStorage (SSR/Node): getStoredTheme,applyTheme(system) = ${r}`, r === 'dark,light');
console.log(fail ? `RESULT: ${fail}/${n} FAIL` : `RESULT: ALL PASS (${n} checks)`);
process.exit(fail ? 1 : 0);
