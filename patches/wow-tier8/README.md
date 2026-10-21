# Wine tier 8 — WoW Forever (ARM64EC)

Patches applied on top of the pinned `wine` submodule (`bp-11.9-tier7`) at build time.
See `banner-proton/apply-wine-tier8.sh` and `banner-proton/PINS`.

**Target client:** `WowB-ARM64.exe` (WoW Forever) is an **ARM64EC** application, not a plain
ARM64 image. Nt syscall thunks are emitted from **`include/wine/asm.h`** (via winebuild from
`ntdll.spec`), not `tools/make_requests` (wineserver protocol only). Patch **0002** matches the
deck-verified PE stub rewrite: plain **ARM64** stubs use unconditional TEB `syscall_table` at
**+0x370** and `KeServiceDescriptorTable[0].CounterTable` at **+8** (same as `patch-ntdll-teb-table-stub.py`),
keeping the original `.quad` tail for relocs. **ARM64EC** stubs try TEB first, then fall back to the
stock `__wine_syscall_dispatcher` PE extern. **0003** / **0005** / **0006** publish and refresh the
dispatch target and fill **unpatched** stub `.data` slots in mapped `ntdll.dll` views (WoW’s on-disk copy).

Apply in numeric order:

| Patch | Issue |
|-------|--------|
| `0001-…` | Zero ARM64 `CONTEXT` before `save_context` in `setup_exception` and `trap_handler` |
| `0002-…` | ARM64 TEB → KSDT dispatch (deck parity); ARM64EC TEB with PE extern fallback (`include/wine/asm.h`) |
| `0003-…` | Publish `__wine_syscall_dispatcher` in `KeServiceDescriptorTable[0].CounterTable` on aarch64 |
| `0004-…` | NLS map-fail fallback via `read_nls_file` + `NtAllocateVirtualMemory` (`env.c`; plain ARM64 + ARM64EC) |
| `0005-…` | `ntdll_arm64ec_sync_syscall_dispatch()` refreshes KSDT `CounterTable` and per-thread `syscall_table` on EC thread start and after `ChpeV2` setup (`syscall.c`, `thread.c`) |
| `0006-…` | Map-time init of `__wine_syscall_dispatcher` for ntdll SEC_IMAGE maps (export-gated, ARM64/AMD64 header); patches legacy stub `.data` cells (`virtual.c`) |

Do not commit these changes inside the `wine` submodule; only the `.patch` files here.
