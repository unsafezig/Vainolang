# Väinölang Roadmap

> Väinölang is a Zig-compatible language fork for the Väinö project.
> Upstream Zig (`zig-upstream` remote) is the source of truth; Väinölang
> takes the best parts ("rusinat pullasta") via selective cherry-picks
> and adds only small, opt-in Väinö extensions.

**Base:** Zig 0.16 (`Start from Zig 0.16`).
**Strategy (decided):** stay on the 0.16 base, cherry-pick selected 0.17
commits. No full 0.17 rebase until the migration is green in the Zinux
experiment branch. Start work on 0.17.0 immediately; track 0.17.1 fixes.

**Compatibility target:** Väinölang remains source-compatible with the
selected Zig 0.16 baseline. A selected upstream 0.17 change may still
require the same migration as Zig 0.17; every such change must be recorded
in this roadmap and in the sync ledger. Väinö additions are opt-in
(`@import("vaino")` / `-Dvaino`), never implicit language changes.

---

## V0 — Fork hygiene

- [x] Fill in `README.md`: what Väinölang is, upstream policy, versioning.
- [x] Version baseline: `vainolang-0.16.0`; use `vaino-0.17-pickN` naming
      for the first selective 0.17 series.
- [ ] `docs/VAINOLANG_SYNC.md`: cherry-pick ledger —
      upstream SHA → decision (take / defer / reject) + reason.
- [ ] CI: nightly `git fetch zig-upstream`, list new 0.17 commits, no auto-merge.

## V1 — Zig 0.17 triage

### V1.1 Take as-is (the "rusinat")

| Feature | Why it matters for Väinö/Zinux |
|---|---|
| `@divCeil` | Kernel alignment and size math without hand-rolled helpers; take as a complete upstream dependency series |
| `@backingInt` / `@fromBackingInt` | Explicit int↔enum conversion for capability `Rights`/audit codes; take as a complete upstream dependency series |
| Deref/coercion of `comptime`-length slices to array pointers | ELF loader parsing (`kernel/loader`) |
| Formally specified + fuzzed grammar | Helps validate AI-generated driver code syntactically |
| `findProgram` / `findProgramLazy` | Find `xorriso`, `qemu-system-x86_64`, `cc` in ISO/run steps |
| Run-step passthru args | QEMU args without rebuilding the build script |
| Reworked cache (directory tracking, binary format) | Correct invalidation of the ~30 embedded `*.bin` ELFs; requires replacing `cp -f` steps with real copy steps |
| LLVM 22.1.8 + musl/glibc/header updates | Candidate only; take after the required upstream dependency chain builds and the target matrix passes |
| `aarch64` target hardening, ARM/SPARC stack traces | Supports ROADMAP Phase B (ARM64 guest) |
| `zig fmt --complexity`, selective `zig objdump` | Code health + linker/boot-marker test tooling |

### V1.2 Take with migration (breaking changes, work required)

| Change | Migration work |
|---|---|
| `@bitCast` = logical bits, not memory layout; `extern struct/union` casts banned; array/vector casts may change **silently** | Manual audit: `kernel/ipc/capability_core.zig`, `kernel/syscall/dispatch.zig`, `kernel/arch/x86_64/paging.zig`, `kernel/arch/aarch64/semihost_file.zig`, `tools/linux_hello.zig`, all MMIO `packed struct` code |
| `@hasDecl` → `true` only for `public` decls | Audit reflection code taking the private-member branch |
| `void{}` removed; array `*` removed (→ `@splat`); `errdefer \|e\|` capture removed; `i0` removed; `internal`/`link_once` removed | Mechanical `grep` + `zig fmt` pass over Zinux tree |
| `std.builtin` → `std.lang`; `OptimizeMode` → `Optimize`; `fmt.allocPrint` → `mem.Allocator`; `ArrayList` rework (+ pointer-stability rules); `StackFallbackAllocator` rename; `SafeAllocator` (evaluate for host tests); `bit_set` rename; `std.zon.parse` rework (**plugin/package manifests**); `Uri`/`HostName` split (VSL/net code); `@import("builtin")` deprecations | Per-module migration in the `exp/vainolang` branch, host tests first |
| Build system: maker/configurer split (`b.args` → `addPassthruArgs`, `LazyPath` basename only in maker, `b.build_root` → `b.root`, `*2` helpers, no custom build runner, global vs local fetching) | Rewrite of the ~1000-line Zinux `build.zig` (copy steps, `linux_hello_gen` run step, QEMU/ISO steps) |
| C translation → external package; Windows resources → external package | Check `VSL/linux_abi` and any `@cImport` use |

### V1.3 Defer / do not take

- SPIR-V multithreading, task/mesh shaders — no consumer.
- WASM backend — watch only (relevant if Phase C ships a WASM runtime).
- LoongArch/Xtensa experiments, COFF extensions (until a Windows host need exists).
- New linker test framework — adopt ideas, not the framework.
- Fuzzer — unchanged in 0.17, nothing to take.
- PowerPC/glibc target drops — no effect on `x86_64`-freestanding.

### V1.4 Known 0.17.0 regressions (track, do not ignore)

- **soft-float x86** — hits the Zinux freestanding target (`soft_float`,
  no SSE/MMX/AVX) directly. Own QEMU smoke test is the gate; a confirmed
  upstream fix or a documented, tested workaround is required before the
  toolchain can become Zinux's default.
- `std.debug.simple_panic`, weak libc symbol overrides, response-file run
  steps (watch `linux_hello_gen`), SPIR-V.
- ZLS broken by the maker/configurer split — editor support stays on 0.16
  until fixed upstream.

## V2 — Small Väinö extensions (opt-in only)

1. A versioned `vaino` module/package with capability helpers (`Rights`
   literals, grant/deny constants) to reduce `@bitCast` repetition. Do not
   place project-specific APIs in upstream `std` until the module boundary
   and compatibility policy are proven.
2. MMIO `packed struct` + `volatile` read/write patterns for kernel code.
3. `vaino-version` stamp + `build -Dvaino` flag for experiments.
4. Later: TDL / driver-plan schema in the `vaino` module — no syntax
   changes in this phase.
5. Each extension ships with: langref example + host test + freestanding
   QEMU test.

## V3 — Low-Level and Assembly Replacement

Väinölang's long-term low-level goal is to replace as much hand-written
assembly as the compiler and target ABI can safely support. This does not
mean removing assembly unconditionally. Boot entries, interrupt return
sequences, context switches, and other architecture-specific instruction
windows may remain assembly when the compiler cannot provide equivalent
guarantees.

### V3.1 Language and compiler foundation

- [ ] Document inline assembly constraints, clobbers, `volatile`, and
      calling-convention guarantees for supported targets.
- [ ] Add compile-time ABI checks for register arguments, stack alignment,
      preserved registers, naked entry points, and interrupt boundaries.
- [ ] Provide low-level helpers for volatile memory access, memory barriers,
      MMIO registers, bitfields, CPU features, and address spaces.
- [ ] Keep target-specific operations explicit; do not hide privileged
      instructions behind portable APIs that cannot state their assumptions.

### V3.2 Replacement order

1. Register and MMIO helpers.
2. UART and timer paths.
3. Keyboard interrupt paths.
4. Syscall wrappers and entry glue.
5. User-mode entry and return.
6. Context switching.
7. Boot entry and the remaining architecture-specific paths.

Every replacement keeps the original assembly implementation until the new
implementation has equivalent evidence.

### V3.3 Acceptance evidence

- [ ] QEMU boot, interrupt, syscall, and user-mode tests pass.
- [ ] Register preservation, stack layout, and calling convention are checked.
- [ ] Generated disassembly is reviewed against the intended ABI contract.
- [ ] Invalid ABI use has a negative compile-time or runtime test.
- [ ] Performance and code-size differences are measured.
- [ ] A tested assembly fallback remains available for unsupported targets.

### V3.4 Initial Zinux targets

The first candidates are `keyboard_irq.S`, timer and UART paths, and syscall
wrappers. `context_switch.S`, `iretq`/`eret` transitions, and first-stage boot
code are explicitly high-risk and remain assembly until Väinölang can express
their register and stack guarantees precisely.

## V4 — Maintenance

- Stay on 0.16 base + cherry-pick ledger; full 0.17 rebase only when the
  Zinux `exp/vainolang` branch is green (host tests + smoke + full boot).
- First consumer: Zinux `exp/vainolang` branch; `main` stays on Zig 0.16
  until the exit gate passes (see Zinux `docs/ROADMAP.md`, Phase 0).

## References

- Upstream release notes: https://ziglang.org/download/0.17.0/release-notes.html
- Consumer roadmap: `../Zinux/docs/ROADMAP.md` (Phase 0)
- Sync ledger: `docs/VAINOLANG_SYNC.md` (to be created in V0)
