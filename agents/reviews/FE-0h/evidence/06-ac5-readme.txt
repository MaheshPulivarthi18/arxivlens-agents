$ bash -c git diff -U0 origin/main...HEAD -- frontend/README.md; echo; grep -n "test files are" frontend/README.md; grep -n "include:" frontend/vite.config.js
diff --git a/frontend/README.md b/frontend/README.md
index 03e7fdd..15084c3 100644
--- a/frontend/README.md
+++ b/frontend/README.md
@@ -14 +14 @@ Run from `frontend/`:
-| `npm test` | Vitest component tests (jsdom, no network); test files are `src/**/*.test.jsx` |
+| `npm test` | Vitest component tests (jsdom, no network); test files are `src/**/*.test.{js,jsx}` |

14:| `npm test` | Vitest component tests (jsdom, no network); test files are `src/**/*.test.{js,jsx}` |
20:    include: ['src/**/*.test.{js,jsx}'],

[exit code 0]
