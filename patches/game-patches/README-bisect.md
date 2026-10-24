# WoW deferred patch bisection (11-11.1 PR)

Device results (NX809J, 2026-10-23):

| Build | Battle.net | Classic Era (ARM64 client) |
|-------|------------|----------------------------|
| Org **11-11.1** (no patch) | OK | Hang after DX11 (`gx.log` stops) |
| **11-11.1-arm64ec-wow** (full patch) | CEF/UI stall | Not stable |
| **11-9.1-arm64ec-wow** (full patch) | OK | In-world OK |

Two independent problems block “11-11.1 + WoW patch” for upstream PR:

1. **Patch × mixed prefix** — i386 Battle.net + ARM64 WoW in one `4153382437` prefix. Suspect hunks: **`virtual.c`** (map-time ntdll dispatch), **`syscall.c` / `thread.c` / `asm.h`** (KSDT / TEB stubs), possibly global `KeServiceDescriptorTable[0].CounterTable` mutation.
2. **GE 11-11 wine base** — stock 11-11.1 (no patch) still fails Classic after GPU init; needs tier-2 diff vs **11-10.1** / **11-9.1** once patch is Bnet-safe.

## Split patches

| File | Contents |
|------|----------|
| `wow-bisect-01-signal-arm64.patch` | `signal_arm64.c` memset CONTEXT |
| `wow-bisect-02-nls-env.patch` | `env.c` NLS map fallback |
| `wow-bisect-03-syscall-dispatch.patch` | `syscall.c`, `thread.c`, `unix_private.h`, `asm.h` |
| `wow-bisect-04-virtual-map.patch` | `virtual.c` map_image ntdll init |
| `wow-forever-arm64ec-ntdll.patch` | All of the above (ship target) |

## CI / local apply sets

Set `WOW_DEFERRED_PATCH_SET` before `banner-proton/apply-deferred-game-patches.sh` (or export in Actions):

- `full` — default, monolithic patch
- `bisect-no-virtual` — test Bnet with dispatch + NLS + signal, no `virtual.c`
- `bisect-no-dispatch` — test Bnet with virtual + NLS + signal, no KSDT/asm changes
- `bisect-minimal` — signal + NLS only
- `APPLY_WOW_DEFERRED_PATCH=0` — org 11-11.1 wine tree (no game patch)

Suggested device order for **11-11.1** PR: `bisect-no-virtual` → `bisect-no-dispatch` → fix forward → `full` → Classic vs **11-10.1** base if still regressed.

## Original six-file series (`patches/wow-tier8/`)

The monolith came from commit **`bb32ae0a`** (“Rebase WoW ARM64EC fixes onto 11-11.1 as one game patch”). The **last git revision** of the separate series is **`bc57a5b6`** (on `main` history).

Retrieve into the tree (or use the vendored copy):

```bash
SRC=bc57a5b6
mkdir -p patches/game-patches/original-wow-tier8
git ls-tree -r --name-only "$SRC" patches/wow-tier8/ | while read -r f; do
  git show "$SRC:$f" > "patches/game-patches/original-wow-tier8/$(basename "$f")"
done
```

**Verified on wine `219dddec`:** apply **`0001`…`0006` in order** → **`git diff` identical** to `wow-forever-arm64ec-ntdll.patch`. The current monolith is **unchanged since `bb32ae0a`**.

| Original | Files touched | Bisect bundle |
|----------|----------------|---------------|
| `0001` | `signal_arm64.c` | `wow-bisect-01-signal-arm64` |
| `0002` | `include/wine/asm.h` | part of `wow-bisect-03-syscall-dispatch` |
| `0003` | `syscall.c`, `thread.c`, `unix_private.h` | part of `wow-bisect-03-syscall-dispatch` |
| `0004` | `env.c` | `wow-bisect-02-nls-env` |
| `0005` | PE/unix slot symbols (see patch) | folded into `03` / monolith |
| `0006` | `virtual.c` | `wow-bisect-04-virtual-map` |

Apply **cumulatively** through step N: `WOW_DEFERRED_PATCH_SET=tier8-0003` applies `0001`→`0003`; … through `tier8-0006`. All six at once: `tier8-original`.

**Actions:** pick `wow_patch_set` on **Build DroidDeck-Proton (aarch64)**. Non-`full` builds get test ids, e.g. internal `DroidDeck-Proton-11-11.1-arm64ec-wow-test-tier8-0003`, Steam folder **DroidDeck-Proton 11-11.1 ARM64EC WoW test tier8-0003** (never replaces the production `-wow` release tag).

## Patch integrity

On wine `219dddec` (bp-11.11 tier tip), run:

```bash
banner-proton/verify-wow-deferred-patches.sh
```

Expect: strict apply (no fuzz / no “ends in middle of line”), and **`git diff` after full patch == after bisect 01→04**. Each `wow-bisect-*.patch` hunk is **byte-identical** to the matching hunk in `wow-forever-arm64ec-ntdll.patch`.
