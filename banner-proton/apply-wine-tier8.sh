#!/bin/bash
# Apply WoW Forever / ARM64EC tier-8 patches onto the pinned wine submodule (tier 7 tip).
# Patches live in patches/wow-tier8/*.patch and are applied in sorted order during CI,
# after banner-proton/prep.sh (which requires a clean wine tree).
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
dir="$root/patches/wow-tier8"
shopt -s nullglob
patches=( "$dir"/*.patch )
if [ "${#patches[@]}" -eq 0 ]; then
  echo "wow-tier8: no patches in $dir"
  exit 0
fi
cd "$root/wine"
for p in "${patches[@]}"; do
  echo "wow-tier8: applying $(basename "$p")"
  patch -Np1 --forward < "$p"
done
echo "wow-tier8: applied ${#patches[@]} patch(es)"
