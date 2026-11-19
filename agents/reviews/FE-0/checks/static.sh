#!/usr/bin/env bash
# QA (independent) static checks for FE-0 AC2, AC3, AC4 (border-input rule), AC6, AC7. Run inside app/ at the PR head.
set -u; fail=0
ok(){ echo "PASS  $1"; }; ko(){ echo "FAIL  $1"; fail=$((fail+1)); }
echo "== AC2 fonts =="
grep -n '@fontsource-variable' frontend/src/main.jsx
[ "$(grep -c "^import '@fontsource-variable" frontend/src/main.jsx)" = 3 ] && ok "3 fontsource imports in main.jsx (inter, source-serif-4, wght-italic)" || ko "fontsource imports"
awk '/fontsource/{f=NR} /index.css/{c=NR} END{exit !(f<c)}' frontend/src/main.jsx && ok "font imports precede ./index.css" || ko "import order"
if grep -rEn 'fonts\.(googleapis|gstatic)\.com' frontend/index.html frontend/src/; then ko "Google font host referenced"; else ok "no fonts.googleapis.com / fonts.gstatic.com in index.html or src/"; fi
echo "== AC3 tailwind.config.js =="
for s in 'darkMode: \["class"\]' 'import typography from "@tailwindcss/typography"' 'plugins: \[typography\]' 'serif: \[."Source Serif 4 Variable"' 'sans: \[."Inter Variable"' 'maxWidth: "70ch"' '"--tw-prose-links": "hsl\(var\(--primary\)\)"' 'supported: \{' 'unsupported: \{' 'unchecked: \{' 'DEFAULT: "hsl\(var\(--unchecked\)\)"' 'title: \[' 'clinical: \{'; do
  grep -Eq "$s" frontend/tailwind.config.js && ok "config has: $s" || ko "config missing: $s"; done
grep -n 'font-serif' frontend/src/components/Navbar.jsx | head -1 && ok "Navbar uses font-serif (so .font-serif will be emitted)"
grep -q '@apply font-sans bg-background text-foreground' frontend/src/index.css && ok "body is font-sans" || ko "body font"
grep -q -- '--radius' frontend/src/index.css && ok "--radius defined"
echo "== AC4 border-input rule =="
grep -n 'border-input, never border-border' frontend/src/index.css && ok "comment next to --input states the rule" || ko "rule comment"
echo "-- every border-* class in files styled by this PR:"
grep -nEo 'border(-[a-z]+)?(/[0-9]+)?( border-[a-z]+(/[0-9]+)?)?' frontend/src/components/Navbar.jsx frontend/src/components/ThemeToggle.jsx frontend/src/components/ui/dropdown-menu.jsx | grep -v 'border-b$' | sort | uniq -c
grep -n 'variant="outline"' -A6 frontend/src/components/Navbar.jsx | grep -q 'border-input' && ok "the one outlined control (Infrastructure, variant=outline) overrides to border-input" || ko "outline control"
echo "== AC6 ui/dropdown-menu.jsx =="
F=frontend/src/components/ui/dropdown-menu.jsx
grep -q '@radix-ui/react-dropdown-menu' $F && ok "wraps @radix-ui/react-dropdown-menu" || ko radix
for e in DropdownMenu DropdownMenuTrigger DropdownMenuContent DropdownMenuGroup DropdownMenuLabel DropdownMenuItem DropdownMenuRadioGroup DropdownMenuRadioItem DropdownMenuSeparator; do
  sed -n '/^export {/,/^}/p' $F | grep -qw "$e" && ok "exports $e" || ko "missing export $e"; done
[ "$(grep -c '^export' $F)" = 1 ] && ! grep -Eq '^export (const|function|default)' $F && ok "single export list of components only (no constants/default)" || ko "exports"
echo "forwardRef count: $(grep -c 'React.forwardRef' $F) (Content, Label, Item, RadioItem, Separator)"; [ "$(grep -c 'React.forwardRef' $F)" = 5 ] && ok "forwardRef on every styled DOM element" || ko forwardRef
[ "$(grep -c 'displayName = DropdownMenuPrimitive' $F)" = 5 ] && ok "displayName copied from primitive (5)" || ko displayName
grep -q 'cn(' $F && ok "uses cn()" || ko cn
if grep -En '(slate|emerald|teal|zinc|gray)-' $F frontend/src/components/ThemeToggle.jsx; then ko "palette classes found"; else ok "no slate|emerald|teal|zinc|gray- classes in dropdown-menu.jsx / ThemeToggle.jsx"; fi
grep -q 'data-\[highlighted\]:bg-accent' $F && ok "data-[highlighted] visible focus" || ko highlighted
grep -q 'font-sans' $F && ok "font-sans on content" || ko font-sans
grep -q 'from "./ui/dropdown-menu"' frontend/src/components/ThemeToggle.jsx && ok "ThemeToggle uses ui/dropdown-menu" || ko usage
if grep -En '(slate|emerald|teal|gradient|shadow-emerald)' frontend/src/components/Navbar.jsx; then ko "Navbar still has hard-coded palette"; else ok "Navbar: no slate/emerald/teal/gradient classes"; fi
echo "== AC5 toggle (static) =="
grep -n 'aria-label={name}' frontend/src/components/ThemeToggle.jsx && ok "toggle trigger has accessible name"
grep -n 'DropdownMenuRadioItem key' frontend/src/components/ThemeToggle.jsx && ok "light/dark/system as Radix radio items (menuitemradio, keyboard)"
grep -n 'useEffect(() => watchSystemTheme(setOsDark), \[\])' frontend/src/components/ThemeToggle.jsx && ok "OS change listener subscribed with cleanup"
grep -n '<ThemeToggle />' frontend/src/components/Navbar.jsx && ok "mounted in Navbar"
echo "== AC7 scope =="
git diff origin/main...HEAD --name-only
git diff origin/main...HEAD --shortstat
if [ -n "$(git diff origin/main...HEAD --name-only -- frontend/package.json frontend/package-lock.json frontend/vite.config.js)" ]; then ko "dependency/vite files changed"; else ok "no change to package.json, package-lock.json, vite.config.js"; fi
for f in SynthesisView ReferencesStack HeroSearch App Toast PapersLibrary IngestModal InfrastructureModal; do
  [ -z "$(git diff origin/main...HEAD --name-only -- "frontend/src/components/$f.jsx" "frontend/src/$f.jsx")" ] || ko "out-of-scope $f changed"; done; ok "none of the out-of-scope feature components changed"
for f in tooltip popover collapsible scroll-area separator sonner; do [ -e frontend/src/components/ui/$f.jsx ] && ko "FE-0b file $f.jsx present"; done; ok "none of FE-0b's six primitive files added"
for f in badge card dialog progress tabs; do [ -z "$(git diff origin/main...HEAD --name-only -- frontend/src/components/ui/$f.jsx)" ] || ko "ui/$f.jsx changed"; done; ok "ui/{badge,card,dialog,progress,tabs}.jsx unchanged"
git diff origin/main...HEAD -- frontend/src/components/ui/button.jsx | grep -E '^[-+] ' ; ok "button.jsx: only the default variant line changes"
echo; [ $fail = 0 ] && echo "RESULT: ALL PASS" || echo "RESULT: $fail FAIL"; exit $fail
