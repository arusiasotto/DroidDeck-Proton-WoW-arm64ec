# Wine tier 8 — WoW Forever (ARM64EC)

Patches applied on top of the pinned `wine` submodule (`bp-11.9-tier7`) at build time.
See `banner-proton/apply-wine-tier8.sh` and `banner-proton/PINS`.

**Target client:** `WowB-ARM64.exe` (WoW Forever) is an **ARM64EC** application, not a plain
ARM64 image. Nt syscall thunks are emitted from **`include/wine/asm.h`** (via winebuild from
`ntdll.spec`), not `tools/make_requests` (wineserver protocol only). Patch **0002** matches the
verified LD_PRELOAD stub rewrite: unconditional TEB `syscall_table` at **+0x370**, dispatch via
`KeServiceDescriptorTable[0].CounterTable` at **+8**; **`brk #0`** if either pointer is null (no
silent fallthrough to an empty PE `.data` slot). **0003** / **0005** / **0006** publish and refresh
that dispatch target and fill manually mapped `ntdll.dll` views.

Apply in numeric order:

| Patch | Issue |
|-------|--------|
| `0001-…` | Uninitialized ARM64 `CONTEXT` debug registers in `setup_exception` |
| `0002-…` | ARM64/ARM64EC syscall stubs: unconditional TEB → KSDT `CounterTable` dispatch; `brk #0` on null (`include/wine/asm.h`) |
| `0003-…` | Publish `__wine_syscall_dispatcher` in `KeServiceDescriptorTable[0].CounterTable` on aarch64 |
| `0004-…` | NLS map-fail fallback via `read_nls_file` + `NtAllocateVirtualMemory` (`env.c`; plain ARM64 + ARM64EC) |
| `0005-…` | `ntdll_arm64ec_sync_syscall_dispatch()` refreshes KSDT `CounterTable` and per-thread `syscall_table` on EC thread start and after `ChpeV2` setup (`syscall.c`, `thread.c`) |
| `0006-…` | Map-time init of `__wine_syscall_dispatcher` (and unix-call exports) for manually mapped `ntdll.dll` views (`unix/virtual.c` `map_image_into_view`) |

Do not commit these changes inside the `wine` submodule; only the `.patch` files here.
