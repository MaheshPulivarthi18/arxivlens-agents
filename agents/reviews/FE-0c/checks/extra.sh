#!/usr/bin/env bash
# QA's own extra mutants + the FE-3 AC8 control (both files flipped together must still pass).
M=$(dirname "$0")/mutate.sh
$M ctl "CONTROL (FE-3 AC8): DEFAULT_THEME flipped to system in BOTH files -> expect SURVIVED" index.html "s/var DEFAULT_THEME = 'dark'/var DEFAULT_THEME = 'system'/" src/lib/theme.js 's/DEFAULT_THEME = "dark"/DEFAULT_THEME = "system"/'
$M f "pre-paint never removes .dark (add-only)" index.html "s/document\.documentElement\.classList\.toggle\('dark', dark\);/if (dark) document.documentElement.classList.add('dark');/"
$M g "storage key changed in index.html only" index.html "s/getItem\('arxivlens-theme'\)/getItem('arxivlens-theme-v2')/"
$M h "storage handler ignores the event key" src/components/ThemeToggle.jsx 's/if \(event\.key === THEME_STORAGE_KEY\) //'
$M i "Safari fallback cleanup is a no-op" src/lib/theme.js 's/return \(\) => query\.removeListener\?\.\(listener\);/return () => {};/'
$M j "setStoredTheme writes invalid values" src/lib/theme.js 's/if \(!isTheme\(pref\)\) return;//'
$M k "pre-paint drops the try/catch around getItem" index.html "s/try \{ (pref = localStorage[^}]*) \} catch \(e\) \{\}/\$1/"
$M l "pre-paint ignores the OS in system mode" index.html "s/\(pref === 'system' && !!window\.matchMedia &&\s*window\.matchMedia\('\(prefers-color-scheme: dark\)'\)\.matches\)/false/"
