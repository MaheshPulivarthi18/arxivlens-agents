// Minimal document.documentElement for theme.test.js in Node (classList + style + className).
const cls = new Set();
const documentElement = {
  classList: { toggle(c, f) { const on = f === undefined ? !cls.has(c) : !!f; on ? cls.add(c) : cls.delete(c); return on; }, contains: (c) => cls.has(c), add: (c) => cls.add(c), remove: (c) => cls.delete(c) },
  style: { colorScheme: '' },
  set className(v) { cls.clear(); String(v).split(/\s+/).filter(Boolean).forEach((c) => cls.add(c)); },
  get className() { return [...cls].join(' '); },
};
globalThis.document = { documentElement };
globalThis.window = globalThis;
