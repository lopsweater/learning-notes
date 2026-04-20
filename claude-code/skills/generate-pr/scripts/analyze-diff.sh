#!/usr/bin/env bash
# analyze-diff.sh - Analyze git changes and output structured PR context
# Usage: analyze-diff.sh [base_branch]
# Example: analyze-diff.sh main

set -euo pipefail

BASE="${1:-main}"
CURRENT=$(git branch --show-current 2>/dev/null || echo "detached")

echo "=== Branch Info ==="
echo "Current: ${CURRENT}"
echo "Base:    ${BASE}"
echo ""

echo "=== Commits ==="
git log "${BASE}...HEAD" --oneline 2>/dev/null || echo "(no commits ahead of ${BASE})"
echo ""

echo "=== File Stats ==="
git diff "${BASE}...HEAD" --stat 2>/dev/null || echo "(no diff)"
echo ""

echo "=== Changed Files by Type ==="
# Categorize files
ADDED=$(git diff "${BASE}...HEAD" --diff-filter=A --name-only 2>/dev/null || true)
MODIFIED=$(git diff "${BASE}...HEAD" --diff-filter=M --name-only 2>/dev/null || true)
DELETED=$(git diff "${BASE}...HEAD" --diff-filter=D --name-only 2>/dev/null || true)
RENAMED=$(git diff "${BASE}...HEAD" --diff-filter=R --name-only 2>/dev/null || true)

[ -n "${ADDED}" ]    && echo "Added:"    && echo "${ADDED}"    | sed 's/^/  /'
[ -n "${MODIFIED}" ] && echo "Modified:" && echo "${MODIFIED}" | sed 's/^/  /'
[ -n "${DELETED}" ]  && echo "Deleted:"  && echo "${DELETED}"  | sed 's/^/  /'
[ -n "${RENAMED}" ]  && echo "Renamed:"  && echo "${RENAMED}"  | sed 's/^/  /'
echo ""

echo "=== Issue References ==="
git log "${BASE}...HEAD" --grep="#[0-9]" --oneline 2>/dev/null || echo "(no issue references)"
echo ""

echo "=== Scope Detection ==="
# Extract top-level module from changed files
SCOPE=$(git diff "${BASE}...HEAD" --name-only 2>/dev/null \
  | sed 's|^src/||;s|/.*||' \
  | sort -u \
  | head -5 \
  | tr '\n' ',' \
  | sed 's/,$//')
echo "Detected scopes: ${SCOPE:-none}"
echo ""

echo "=== Type Detection ==="
# Guess PR type from changed files
FILES=$(git diff "${BASE}...HEAD" --name-only 2>/dev/null || true)

if echo "${FILES}" | grep -qE "(test|spec|__tests__)" 2>/dev/null; then
  echo "Likely type: test"
elif echo "${FILES}" | grep -qE "\.md$|docs/" 2>/dev/null && [ -z "$(echo "${FILES}" | grep -vE '\.md$|docs/')" ]; then
  echo "Likely type: docs"
elif git log "${BASE}...HEAD" --oneline 2>/dev/null | grep -qiE "^.\{0,10\}fix|bug|issue|patch"; then
  echo "Likely type: fix"
elif [ -n "${ADDED}" ]; then
  echo "Likely type: feat"
elif [ -n "$(echo "${FILES}" | grep -iE 'perf|optim|cache|pool')" ]; then
  echo "Likely type: perf"
else
  echo "Likely type: refactor (verify manually)"
fi
echo ""

echo "=== Diff Summary ==="
# Output a truncated diff for context
DIFF_LINES=$(git diff "${BASE}...HEAD" 2>/dev/null | wc -l || echo "0")
if [ "${DIFF_LINES}" -gt 500 ]; then
  echo "Diff is ${DIFF_LINES} lines, showing first 500:"
  git diff "${BASE}...HEAD" 2>/dev/null | head -500
  echo ""
  echo "... (${DIFF_LINES} total lines, truncated)"
else
  git diff "${BASE}...HEAD" 2>/dev/null || echo "(no diff)"
fi
