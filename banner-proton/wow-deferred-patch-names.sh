#!/bin/bash
# Map WOW_DEFERRED_PATCH_SET to version / display suffixes (test builds).
set -euo pipefail
patch_set="${1:-${WOW_DEFERRED_PATCH_SET:-full}}"

if [[ "$patch_set" == "full" ]]; then
  echo "VERSION_SUFFIX="
  echo "DISPLAY_TEST="
  exit 0
fi

slug=$(echo "$patch_set" | tr '_' '-')
echo "VERSION_SUFFIX=-test-${slug}"
echo "DISPLAY_TEST=test ${slug}"
