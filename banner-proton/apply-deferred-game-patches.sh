#!/bin/bash
# Apply game-patches not yet baked into the pinned wine submodule (bp-*-tier6 tip).
# Listed in patches/protonprep-valve-staging.sh GAME PATCH SECTION; prep.sh skips that block.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
gp="$root/patches/game-patches"

if [[ "${APPLY_WOW_DEFERRED_PATCH:-1}" == "0" ]]; then
  echo "deferred game patch: skipped (APPLY_WOW_DEFERRED_PATCH=0)"
  exit 0
fi

apply() {
  local p=$1
  echo "deferred game patch: $(basename "$p")"
  patch -Np1 --forward < "$p"
}

cd "$root/wine"

case "${WOW_DEFERRED_PATCH_SET:-full}" in
  full)
    apply "$gp/wow-forever-arm64ec-ntdll.patch"
    ;;
  bisect-01-signal)
    apply "$gp/wow-bisect-01-signal-arm64.patch"
    ;;
  bisect-02-nls)
    apply "$gp/wow-bisect-02-nls-env.patch"
    ;;
  bisect-03-dispatch)
    apply "$gp/wow-bisect-03-syscall-dispatch.patch"
    ;;
  bisect-04-virtual)
    apply "$gp/wow-bisect-04-virtual-map.patch"
    ;;
  bisect-no-virtual)
    apply "$gp/wow-bisect-01-signal-arm64.patch"
    apply "$gp/wow-bisect-02-nls-env.patch"
    apply "$gp/wow-bisect-03-syscall-dispatch.patch"
    ;;
  bisect-no-dispatch)
    apply "$gp/wow-bisect-01-signal-arm64.patch"
    apply "$gp/wow-bisect-02-nls-env.patch"
    apply "$gp/wow-bisect-04-virtual-map.patch"
    ;;
  bisect-minimal)
    apply "$gp/wow-bisect-01-signal-arm64.patch"
    apply "$gp/wow-bisect-02-nls-env.patch"
    ;;
  tier8-original)
    o="$gp/original-wow-tier8"
    for p in "$o"/000{1,2,3,4,5,6}-*.patch; do
      apply "$p"
    done
    ;;
  tier8-0001|tier8-0002|tier8-0003|tier8-0004|tier8-0005|tier8-0006)
    end="${WOW_DEFERRED_PATCH_SET#tier8-}"
    o="$gp/original-wow-tier8"
    for p in "$o"/000*.patch; do
      num=$(basename "$p" | sed -n 's/^0*\([0-9]\+\).*/\1/p')
      (( num <= 10#$end )) || continue
      apply "$p"
    done
    ;;
  *)
    echo "unknown WOW_DEFERRED_PATCH_SET=${WOW_DEFERRED_PATCH_SET}" >&2
    exit 1
    ;;
esac
