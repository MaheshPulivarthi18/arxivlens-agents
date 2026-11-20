// QA stand-in for the subset of the vitest API used by the FE-0c tests (real vitest unavailable: npm registry blocked).
const tests = []; const stack = []; const before = []; const after = [];
const mocks = [];
export function describe(name, fn) { stack.push(name); fn(); stack.pop(); }
export function it(name, fn) { tests.push({ name: [...stack, name].join(' > '), fn }); }
const fmt = (t, args) => { let i = 0; return t.replace(/%[sjd]/g, (m) => { const a = args[i++]; return m === '%j' ? JSON.stringify(a) : String(a); }); };
it.each = (rows) => (name, fn) => rows.forEach((r) => it(fmt(name, r), () => fn(...r)));
export function beforeEach(fn) { before.push(fn); }
export function afterEach(fn) { after.push(fn); }
function makeFn(impl) {
  const f = function (...a) { f.mock.calls.push(a); return f._impl ? f._impl.apply(this, a) : undefined; };
  f.mock = { calls: [] }; f._impl = impl; f._isMock = true;
  f.mockImplementation = (i) => { f._impl = i; return f; };
  return f;
}
export const vi = {
  fn: (impl) => makeFn(impl),
  spyOn(obj, key) {
    const orig = obj[key]; const f = makeFn(function (...a) { return orig.apply(this, a); });
    const passthrough = f._impl; f.mockImplementation = (i) => { f._impl = i; return f; };
    obj[key] = f; mocks.push(() => { obj[key] = orig; }); void passthrough; return f;
  },
  restoreAllMocks() { while (mocks.length) mocks.pop()(); },
};
const eq = (a, b) => JSON.stringify(a) === JSON.stringify(b);
function fail(msg) { throw new Error(msg); }
export function expect(actual) {
  const m = (neg) => {
    const chk = (ok, msg) => { if (neg ? ok : !ok) fail((neg ? 'NOT ' : '') + msg); };
    return {
      toBe: (e) => chk(Object.is(actual, e), `expected ${JSON.stringify(actual)} toBe ${JSON.stringify(e)}`),
      toEqual: (e) => chk(eq(actual, e), `expected ${JSON.stringify(actual)} toEqual ${JSON.stringify(e)}`),
      toBeDefined: () => chk(actual !== undefined, 'expected defined'),
      toBeNull: () => chk(actual === null, `expected ${JSON.stringify(actual)} toBeNull`),
      toBeGreaterThan: (n) => chk(actual > n, `expected ${actual} > ${n}`),
      toHaveLength: (n) => chk(actual.length === n, `expected length ${actual.length} to be ${n}`),
      toHaveBeenCalled: () => chk(actual.mock.calls.length > 0, 'expected call'),
      toHaveBeenCalledTimes: (n) => chk(actual.mock.calls.length === n, `expected ${n} calls, got ${actual.mock.calls.length}`),
      toHaveBeenCalledWith: (...a) => chk(actual.mock.calls.some((c) => eq(c, a)), `expected call with ${JSON.stringify(a)}`),
      toHaveBeenLastCalledWith: (...a) => chk(eq(actual.mock.calls.at(-1), a), `expected last call ${JSON.stringify(a)}, got ${JSON.stringify(actual.mock.calls.at(-1))}`),
      toThrow: () => { let t = false; try { actual(); } catch { t = true; } chk(t, 'expected throw'); },
      toBeInTheDocument: () => chk(actual && actual.ownerDocument && actual.ownerDocument.contains(actual), 'expected in document'),
    };
  };
  const r = m(false); r.not = m(true); return r;
}
export async function __run(label) {
  let pass = 0, failN = 0; const out = [];
  for (const t of tests) {
    try { for (const b of before) await b(); await t.fn(); pass++; out.push(`  PASS ${t.name}`); }
    catch (e) { failN++; out.push(`  FAIL ${t.name}\n       -> ${String(e.message).split('\n')[0]}`); }
    finally { for (const a of after) { try { await a(); } catch (e) { out.push('  afterEach error ' + e.message); } } }
  }
  out.push(`${label}: ${pass} passed, ${failN} failed (${tests.length})`);
  return out.join('\n');
}
