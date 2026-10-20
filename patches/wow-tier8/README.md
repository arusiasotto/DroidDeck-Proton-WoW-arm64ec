# Wine tier 8 — WoW Forever (ARM64EC)

Patches applied on top of the pinned `wine` submodule (`bp-11.9-tier7`) at build time.
See `banner-proton/apply-wine-tier8.sh` and `banner-proton/PINS`.

**Target client:** `WowB-ARM64.exe` (WoW Forever) is an **ARM64EC** application, not a plain
ARM64 image. On Wine aarch64, EC threads get `TEB->ChpeV2CpuAreaInfo` at **+0x1788**
(`is_arm64ec()` in `dlls/ntdll/unix/thread.c`). Patches **0002** and **0003** rely on that:
EC threads take the TEB → `KeServiceDescriptorTable[0].CounterTable` dispatch path when WoW
maps a clean `ntdll.dll` whose PE `.data` dispatcher slot was never filled. Plain ARM64
processes keep the upstream PC-literal stub sequence.

Apply in numeric order:

| Patch | Issue |
|-------|--------|
| `0001-…` | Uninitialized ARM64 `CONTEXT` debug registers in `setup_exception` |
| `0002-…` | ARM64/ARM64EC syscall stubs: TEB `KeServiceDescriptorTable[0].CounterTable` dispatch when `ChpeV2CpuAreaInfo` is set (`include/wine/asm.h`, not `tools/make_requests`) |
| `0003-…` | Publish `__wine_syscall_dispatcher` in `KeServiceDescriptorTable[0].CounterTable` on aarch64 |
| `0004-…` | ARM64EC-only NLS fallback via `read_nls_file` + `NtAllocateVirtualMemory` (`env.c`) |

Do not commit these changes inside the `wine` submodule; only the `.patch` files here.
