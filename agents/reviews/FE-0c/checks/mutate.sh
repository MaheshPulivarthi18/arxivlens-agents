#!/usr/bin/env bash
# QA mutation run: mutate.sh <id> <description> <file> <perl-substitution> [<file2> <subst2>]
# Copies frontend/ from the PR-head worktree into a fresh temp dir, applies the mutation, shows the diff, runs both test files.
set -u
H=$(dirname "$0"); SRC=$HOME/wt/qa-FE-0c/frontend
id=$1; desc=$2; shift 2
d=$(mktemp -d); cp -r "$SRC" "$d/frontend"
echo "== mutant $id: $desc  (fresh copy of PR head $(git -C "$SRC" rev-parse --short HEAD), never pushed)"
while [ $# -ge 2 ]; do
  perl -0pi -e "$2" "$d/frontend/$1"
  diff -u "$SRC/$1" "$d/frontend/$1" | sed -n '3,$p' | grep '^[-+]' | sed "s|^|   $1: |"
  shift 2
done
out=$(node "$H/run.mjs" "$d/frontend" 2>&1)
echo "$out" | grep -E '^ +FAIL|^ +-> |passed, |TIMEOUT'
n=$(echo "$out" | grep -c '^ *FAIL')
[ "$n" -gt 0 ] && echo "RESULT: KILLED ($n failing tests)" || echo "RESULT: SURVIVED"
rm -rf "$d"
