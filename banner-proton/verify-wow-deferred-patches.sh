#!/bin/bash
# Verify wow-forever-arm64ec-ntdll.patch == wow-bisect-01..04 on the pinned wine tree.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
gp="$root/patches/game-patches"
wine="$root/wine"

if ! git -C "$wine" rev-parse HEAD >/dev/null 2>&1; then
  echo "missing or broken wine submodule at $wine" >&2
  exit 1
fi

git -C "$wine" checkout -- .
git -C "$wine" clean -fdq

strict_apply() {
  local p=$1
  local out
  out=$(cd "$wine" && patch -Np1 --forward < "$p" 2>&1)
  if echo "$out" | grep -qE 'FAILED|ignored|fuzz|ends in middle'; then
    echo "$out" >&2
    return 1
  fi
}

strict_apply "$gp/wow-forever-arm64ec-ntdll.patch"
git -C "$wine" diff > /tmp/wow-deferred-full.diff
git -C "$wine" checkout -- .
git -C "$wine" clean -fdq

for p in \
  "$gp/wow-bisect-01-signal-arm64.patch" \
  "$gp/wow-bisect-02-nls-env.patch" \
  "$gp/wow-bisect-03-syscall-dispatch.patch" \
  "$gp/wow-bisect-04-virtual-map.patch"
do
  strict_apply "$p"
done
git -C "$wine" diff > /tmp/wow-deferred-split.diff

if ! diff -q /tmp/wow-deferred-full.diff /tmp/wow-deferred-split.diff >/dev/null; then
  echo "wow deferred: full vs bisect git diff MISMATCH" >&2
  diff -u /tmp/wow-deferred-full.diff /tmp/wow-deferred-split.diff | head -80 >&2
  exit 1
fi

git -C "$wine" checkout -- .
git -C "$wine" clean -fdq
echo "wow deferred patches: full == bisect-01..04 (strict apply, identical diff)"
