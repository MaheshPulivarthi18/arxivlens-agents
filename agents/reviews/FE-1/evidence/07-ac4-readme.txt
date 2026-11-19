$ bash -c grep -n "npm" frontend/README.md; echo; ls frontend/AGENTS.md 2>&1
11:| `npm ci` | Install the exact dependencies from `package-lock.json` |
12:| `npm run dev` | Dev server on :5173; proxies `/v1` to the query API on :8080 |
13:| `npm run lint` | oxlint |
14:| `npm test` | Vitest component tests (jsdom, no network); test files are `src/**/*.test.jsx` |
15:| `npm run build` | Production build |
17:CI runs `npm ci`, `npm run lint`, `npm test` and `npm run build` on every PR.

ls: cannot access 'frontend/AGENTS.md': No such file or directory

[exit code 2]
