// QA stand-in for @testing-library/react: render/act/screen.getByRole(button,{name}) with real react-dom 19.
import { act as reactAct } from 'react';
import { createRoot } from 'react-dom/client';
globalThis.IS_REACT_ACT_ENVIRONMENT = true;
const mounted = [];
export const act = (fn) => reactAct(fn);
export function render(ui) {
  const container = document.body.appendChild(document.createElement('div'));
  const root = createRoot(container);
  reactAct(() => root.render(ui));
  const entry = { root, container };
  mounted.push(entry);
  return { container, unmount: () => { reactAct(() => root.unmount()); container.remove(); mounted.splice(mounted.indexOf(entry), 1); } };
}
export function cleanup() { while (mounted.length) { const { root, container } = mounted.pop(); reactAct(() => root.unmount()); container.remove(); } }
export const screen = {
  getByRole(role, { name }) {
    const els = [...document.querySelectorAll(role === 'button' ? 'button,[role=button]' : `[role=${role}]`)]
      .filter((el) => (el.getAttribute('aria-label') ?? el.textContent.trim()) === name);
    if (els.length !== 1) {
      const names = [...document.querySelectorAll('button')].map((b) => b.getAttribute('aria-label'));
      throw new Error(`getByRole(${role}, ${name}): found ${els.length}; buttons present: ${JSON.stringify(names)}`);
    }
    return els[0];
  },
};
