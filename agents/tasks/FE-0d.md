# FE-0d: Commit render tests for the six FE-0b ui primitives

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P2 (harness/quality: today nothing in CI executes the six files; Vite tree-shakes them until FE-3/FE-4 import them) |
| **PRD ref** | Product PRD §7 (accessible, readable UI; principles 1 "Evidence first" and 3 "One click to the source" via FE-3/FE-4); FE-0b QA "Missing tests" (`agents/reviews/FE-0b/report.md`, rounds 1–3) |
| **Depends on** | FE-0b (#70) **merged**. FE-1 (#68, merged `2410d2e`: Vitest + jsdom + Testing Library). No dependency change needed |
| **Jira** | KAN-90 (epic KAN-5 "Research UI & citations"; labels `task-FE-0d`, `agent-frontend`, `arxivlens`) |
| **Design required** | no: tests only, no component, contract or dependency change |
| **Status** | Done: ArxivLens [#95](https://github.com/MaheshPulivarthi18/ArxivLens/pull/95) merged by Mahesh 2026-11-21 as `ae8de39` (QA r1 PASS, PM APPROVE) |

## Goal
FE-0b's six primitives were proven only by QA's throwaway smoke harness (real Radix/sonner in headless Chromium). CI lints them but never
renders them, so a typo in a namespace member or a broken `toastOptions` merge would first show up in FE-3/FE-4. Commit jsdom render tests that
pin the behaviour QA verified, so later edits to `ui/*.jsx` can't silently regress it.

## Scope
- New `frontend/src/components/ui/primitives.test.jsx` only. Nothing else (no change to the six `ui/*.jsx`, `package.json`, the lockfile, `vite.config.js` or `src/test/setup.js`).
- Starting point: QA's harness description and facts in `agents/reviews/FE-0b/evidence/25-r3-ac6-smoke-facts.txt`, `26-r3-f3-toast-description.txt`, `29-r3-harness-sources.txt` (read them here, don't copy files into `app/`).
- Out of scope: computed colours and contrast (jsdom doesn't compute Tailwind CSS: assert class names and inline styles instead), mounting `<Toaster/>` in the app, any new dependency.
- Size: ~150 test lines.

## Acceptance criteria
- [x] AC1 — **Tooltip / Popover:** rendered open (`open` prop or `defaultOpen`), the content is in `document.body` but **outside** the render container (portal), has `font-sans`, `bg-popover` and `text-popover-foreground` in its class list, and the forwarded `ref` points at that element. A caller `className` is merged (present alongside the defaults).
- [x] AC2 — **Collapsible:** with `defaultOpen` the content text is in the document and `data-state="open"`; closed, the content text is not in the document; clicking the trigger (`user-event`) opens it.
- [x] AC3 — **ScrollArea / ScrollBar:** the viewport (`[data-radix-scroll-area-viewport]`) has `focus-visible:ring-inset` and `focus-visible:ring-ring` and no `ring-offset` class (pins the FE-0b inset-ring deviation); the Root's ref forwards; children render inside the viewport.
- [x] AC4 — **Separator:** default renders `role="none"` with `h-px w-full`; `decorative={false}` renders `role="separator"`; `orientation="vertical"` gives `h-full w-px` (and `aria-orientation="vertical"` when not decorative).
- [x] AC5 — **Toaster:** once a toast is shown, sonner's list `<ol data-sonner-toaster>` inside the `ref` target `<section>` carries the inline variables (sonner 2.0.8 forwards `ref` to the `<section>` but puts `style` on the list; amended 2026-11-21 from QA `[spec]` 1) `--normal-bg: hsl(var(--popover))`, `--normal-text`, `--normal-border`, `--border-radius`; a caller `style={{ "--normal-bg": "red" }}` overrides that one variable and keeps the other three. After `toast("t", { description: "d" })`, the description element (`[data-description]`) has `!text-muted-foreground`; with `toastOptions={{ classNames: { title: "x-title", description: "x-desc" } }}` the title has `x-title` and the description has both `!text-muted-foreground` and `x-desc` (pins the FE-0b F3 fix). No `data-sonner-theme="dark"` is needed for this.
- [x] AC6 — **Mutation check:** the developer reports (in Notes, with output), or, when the developer sandbox can't install npm packages, QA shows with its harness (evidence file) that the AC5 description assertion fails when `sonner.jsx`'s `classNames.description` line is removed, and the AC3 assertion fails when `ring-inset` is replaced by `ring-offset-2`. Changes reverted before commit.
- [x] AC7 — `npm run lint` (0 warnings) and `npm test` pass in CI on the draft PR; test file count goes up by one versus main.
- [x] Docs: none.

## Verification
```bash
# CI (source of truth): Frontend job on the draft PR
cd frontend && npm ci && npm run lint && npm test && npm run build

# Scope (sandbox)
git diff origin/main --name-only     # exactly frontend/src/components/ui/primitives.test.jsx
git diff origin/main --shortstat
```

## Notes
- 2026-11-20 (pm-lead): created from FE-0b QA "Missing tests" (raised r1, carried r2/r3) at the FE-0b final review. Kept separate from FE-3/FE-4
  so those stay under 400 lines and so the primitives have tests before their first callers. Independent of FE-0c (different files). Jira story
  is KAN-90.
- jsdom notes: Radix Tooltip/Popover may need `ResizeObserver` and `DOMRect` stubs in the test file (not in `setup.js`, which is out of scope); sonner renders toasts asynchronously, so use `findBy*`/`waitFor`.
- 2026-11-20 20:00Z (pm-lead): re-checked scope against open PRs #91 (`App.test.jsx`), #92 (`ui/button.jsx`, `ui/button.test.jsx`), #93, #94: disjoint. The six primitive files are unchanged on `230f617`. Do **not** import or test `ui/button.jsx` here (#92 owns it), and keep stubs in the test file, not `src/test/setup.js` (FE-3b adds `ResizeObserver` there).
- 2026-11-21 (pm-lead, final review): **APPROVE**; PR #95 raised (ready for review, `ready-to-merge`). QA r1 PASS at `76b851c`, evidence pinned `e012695`.
  `[spec]` 1: AC5 reworded to the sonner 2.0.8 DOM (variables on `<ol data-sonner-toaster>` inside the ref'd `<section>`), which the test already does.
  `[spec]` 2: AC6 now accepts a QA-run mutation result when npm is blocked. The developer couldn't run Vitest; QA ran M1 (2 tests fail) and M2 (1 fails) on copies, and the worktree stayed clean (evidence 05, 07).
  Nit 3: the developer left no Notes entry; this entry records the AC5 deviation and the AC6 hand-off. Nit 4: keep unique toast text per test if toast tests are added.
  Follow-up: FE-0g (Backlog), covering surviving mutants M35–M39 (ScrollBar className/horizontal, Toaster position, Separator className, Tooltip `delayDuration`).
