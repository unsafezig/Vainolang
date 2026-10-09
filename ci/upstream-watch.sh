#!/bin/sh
# Upstream watch — list new zig-upstream 0.17 commits for triage.
# No auto-merge: triage entries are added manually to docs/VAINOLANG_SYNC.md
# per Väinölang ROADMAP V1 (take / defer / reject + reason).
#
# Usage: sh ci/upstream-watch.sh [since]   (default: 7 days ago)
set -eu

SINCE="${1:-7 days ago}"
BASELINE_TAG="vainolang-0.16.0"
UPSTREAM_REF="zig-upstream/0.17.x"

echo "=== Vainolang upstream watch ==="
if git fetch --quiet zig-upstream 2>/dev/null; then
  echo "(remote state: fresh)"
else
  echo "(fetch failed — using local remote state)"
fi

echo "--- commits on $UPSTREAM_REF since $SINCE ---"
git log --no-merges --pretty='%H %ad %s' --date=short --since="$SINCE" "$UPSTREAM_REF" -- || true

echo "--- total commits $BASELINE_TAG..$UPSTREAM_REF ---"
git rev-list --count "$BASELINE_TAG..$UPSTREAM_REF"

echo "--- SHAs already triaged in docs/VAINOLANG_SYNC.md ---"
grep -o -E '[0-9a-f]{7,40}' docs/VAINOLANG_SYNC.md | sort -u || true

echo "(done — no merges performed)"
