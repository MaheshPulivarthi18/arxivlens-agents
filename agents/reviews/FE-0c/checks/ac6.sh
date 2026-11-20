#!/usr/bin/env bash
# AC6 mutants (a)-(e) from the ticket, each in a fresh copy of the PR head.
M=$(dirname "$0")/mutate.sh
$M a "DEFAULT_THEME changed in index.html only" index.html "s/var DEFAULT_THEME = 'dark'/var DEFAULT_THEME = 'system'/"
$M b "storage key changed in theme.js only" src/lib/theme.js 's/THEME_STORAGE_KEY = "arxivlens-theme"/THEME_STORAGE_KEY = "arxivlens-theme-v2"/'
$M c "storage listener removed from ThemeToggle.jsx" src/components/ThemeToggle.jsx 's/window\.addEventListener\("storage", onStorage\)/\/\/ (mutant) listener removed/'
$M d "osDark dropped from the applyTheme effect deps" src/components/ThemeToggle.jsx 's/\[pref, osDark\]/[pref]/'
$M e "watchSystemTheme cleanup is a no-op" src/lib/theme.js 's/return \(\) => query\.removeEventListener\("change", listener\)/return () => {}/'
