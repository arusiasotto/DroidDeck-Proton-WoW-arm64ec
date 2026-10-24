#!/bin/bash
# CI: check wine source markers for the selected WOW_DEFERRED_PATCH_SET.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root/wine"
set="${WOW_DEFERRED_PATCH_SET:-full}"

has() {
  local n
  n=$(grep -cF -- "$2" "$1" || true)
  if [[ "$n" -ge "${3:-1}" ]]; then
    echo "ok: $1 has \"$2\" ($n)"
    return 0
  fi
  echo "MISSING in $1: \"$2\" (found $n, want ${3:-1})"
  return 1
}

lacks() {
  if grep -qF -- "$2" "$1"; then
    echo "unexpected in $1: \"$2\""
    return 1
  fi
  echo "ok: $1 lacks \"$2\""
  return 0
}

fail=0
check() { has "$@" || fail=1; }
nocheck() { lacks "$@" || fail=1; }

want_signal=0 want_nls=0 want_asm=0 want_ksdt=0 want_sync=0 want_virtual=0

case "$set" in
  full|tier8-original|tier8-0006)
    want_signal=1 want_nls=1 want_asm=1 want_ksdt=1 want_sync=1 want_virtual=1 ;;
  tier8-0001|bisect-01-signal)
    want_signal=1 ;;
  tier8-0002)
    want_signal=1 want_asm=1 ;;
  tier8-0003)
    want_signal=1 want_asm=1 want_ksdt=1 ;;
  tier8-0004)
    want_signal=1 want_asm=1 want_ksdt=1 want_nls=1 ;;
  bisect-02-nls)
    want_nls=1 ;;
  tier8-0005)
    want_signal=1 want_asm=1 want_ksdt=1 want_nls=1 want_sync=1 ;;
  bisect-04-virtual)
    want_virtual=1 ;;
  bisect-03-dispatch)
    want_asm=1 want_ksdt=1 want_sync=1 ;;
  bisect-no-virtual)
    want_signal=1 want_nls=1 want_asm=1 want_ksdt=1 want_sync=1 ;;
  bisect-no-dispatch)
    want_signal=1 want_nls=1 want_virtual=1 ;;
  bisect-minimal)
    want_signal=1 want_nls=1 ;;
  *)
    echo "verify-wow-deferred-markers: unknown WOW_DEFERRED_PATCH_SET=$set" >&2
    exit 1
    ;;
esac

[[ "$want_signal" == 1 ]] && {
  check dlls/ntdll/unix/signal_arm64.c "memset( &context, 0, sizeof(context) );"
  check dlls/ntdll/unix/signal_arm64.c "memset( &ctx, 0, sizeof(ctx) );"
}
[[ "$want_nls" == 1 ]] && check dlls/ntdll/unix/env.c "map_nls_file_as_view"
[[ "$want_asm" == 1 ]] && {
  check include/wine/asm.h "ldr x16, [x18, #0x370]"
  check include/wine/asm.h "ldr x16, [x16, #8]"
  check include/wine/asm.h "__ASM_NAME(\"__wine_syscall_dispatcher\")"
}
[[ "$want_ksdt" == 1 ]] && check dlls/ntdll/unix/syscall.c "(ULONG_PTR *)__wine_syscall_dispatcher"
[[ "$want_sync" == 1 ]] && check dlls/ntdll/unix/syscall.c "ntdll_arm64ec_sync_syscall_dispatch"
[[ "$want_virtual" == 1 ]] && check dlls/ntdll/unix/virtual.c "map_image_init_ntdll_dispatchers"

[[ "$set" == bisect-no-virtual ]] && nocheck dlls/ntdll/unix/virtual.c "map_image_init_ntdll_dispatchers"
[[ "$set" == bisect-no-dispatch ]] && nocheck include/wine/asm.h "ldr x16, [x18, #0x370]"

exit "$fail"
