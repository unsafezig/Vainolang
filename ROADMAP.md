# Väinölang Roadmap

> Väinölang is a Zig-compatible language fork for the Väinö project.
> Upstream Zig (`zig-upstream` remote) is the source of truth; Väinölang
> takes the best parts ("rusinat pullasta") via selective cherry-picks
> and adds only small, opt-in Väinö extensions.

**Base:** Zig 0.16 (start from Zig 0.16).

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
- [x] `docs/VAINOLANG_SYNC.md`: cherry-pick ledger —
  upstream SHA → decision (take / defer / reject) + reason.
- [x] CI: nightly `git fetch zig-upstream`, list new 0.17 commits, no auto-merge
  (`.github/workflows/upstream-watch.yml` + `ci/upstream-watch.sh`).
- [x] Local compiler-build capacity (2026-10-10): LLVM 21.1.3 + zlib + zstd
  built from source with `zig cc` in `~/deps`; self-built stage3 validated
  green (behavior slice/math + std math). Unblocks compiler-side takes.
  Recipe + pitfalls in `docs/VAINOLANG_SYNC.md`.

---

## V1 — Zig 0.17 triage

**Triage status 2026-10-11:** `@divCeil` is **taken** — full upstream
series cherry-picked, adapted to the 0.16 base, validated on a self-built
stage3, merged to `main` (PR #1). All other evaluated series are
**deferred with reasons** in `docs/VAINOLANG_SYNC.md` (next candidate:
slice deref/coercion). No breaking (V1.2) change has been taken.

### V1.1 Take as-is (the "rusinat")

| Feature | Why it matters for Väinö/Zinux |
|---------|--------------------------------|
| `@divCeil` | Kernel alignment and size math without hand-rolled helpers; take as a complete upstream dependency series. ✅ TAKEN 2026-10-11 (merged to `main`, PR #1; validated stage3, see sync ledger) |
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
|--------|----------------|
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
- PowerPC/glibc target drops — no effect on x86_64-freestanding.

### V1.4 Known 0.17.0 regressions (track, do not ignore)

- soft-float x86 — hits the Zinux freestanding target (soft_float,
  no SSE/MMX/AVX) directly. Own QEMU smoke test is the gate; a confirmed
  upstream fix or a documented, tested workaround is required before the
  toolchain can become Zinux's default.
- `std.debug.simple_panic`, weak libc symbol overrides, response-file run
  steps (watch `linux_hello_gen`), SPIR-V.
- ZLS broken by the maker/configurer split — editor support stays on 0.16
  until fixed upstream.

---

## V2 — Small Väinö extensions (opt-in only)

1. A versioned `vaino` module/package with capability helpers (Rights
   literals, grant/deny constants) to reduce `@bitCast` repetition. Do not
   place project-specific APIs in upstream std until the module boundary
   and compatibility policy are proven.
   ✅ Done 2026-10-09: `libs/vaino.zig` v1 in Zinux (`exp/vainolang`);
   recorded as `V-1` in `LANGUAGE.md`.
2. MMIO packed struct + volatile read/write patterns for kernel code.
   ✅ Done 2026-10-09: `mmioRead`/`mmioWrite` in `vaino` v1.
3. `vaino`-version stamp + build `-Dvaino` flag for experiments.
   ✅ Done 2026-10-09: version stamp + `-Dvaino` + kernel comptime check.
4. Later: TDL / driver-plan schema in the `vaino` module — no syntax
   changes in this phase. *(not started)*
5. Each extension ships with: langref example + host test + freestanding
   QEMU test. *(partial 2026-10-10: host test ✅, freestanding compile ✅,
   QEMU boot test ⏳, langref example ⏳)*

---

## V3 — Low-Level and Assembly Replacement

Väinölang's long-term low-level goal is to replace as much hand-written
assembly as the compiler and target ABI can safely support. This does not
mean removing assembly unconditionally. Boot entries, interrupt return
sequences, context switches, and other architecture-specific instruction
windows may remain assembly when the compiler cannot provide equivalent
guarantees.

### V3.1 Language and compiler foundation

- [ ] Document inline assembly constraints, clobbers, volatile, and
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

### V3.5 — Native Väinölang machine model (long-term)

The long-term direction is to give Väinölang its own architecture-independent
low-level operation model, rather than merely translating Finnish spellings
of existing x86 instructions. The compiler defines the semantics; each target
backend lowers those operations to its own machine code.

This is a staged research and implementation track, not a change to the current
Zig 0.16 compatibility baseline. Existing Zig compatibility and the assembly
replacement work in V3 continue until this track has a proven implementation
and an explicit migration decision.

#### V3.5.1 Language-owned semantics

- [ ] Specify a minimal low-level operation set: constants and value movement,
  integer arithmetic, bitwise operations, comparisons, branches, calls,
  returns, memory reads/writes, and unreachable/trap behavior.
- [ ] Specify integer widths, signedness, overflow behavior, shifts, alignment,
  pointer/address representation, and invalid-memory behavior explicitly.
- [ ] Define control-flow and calling semantics independently of any one CPU's
  registers, flags, instruction names, or calling convention.
- [ ] Define how volatile access, MMIO, memory ordering, atomics, CPU features,
  privileged operations, and address spaces are represented. Keep operations
  target-specific when portable semantics cannot express their guarantees.
- [ ] Keep the semantic specification separate from surface syntax and from
  each backend's machine instructions.

#### V3.5.2 Compiler representation and first backend

- [ ] Introduce a versioned, documented Väinölang low-level IR / operation set.
- [ ] Add validation for well-formed control flow, operand types, memory
  operations, and target-specific constraints.
- [ ] Implement an x86-64 backend that lowers the IR to machine code without
  requiring handwritten assembly for ordinary supported operations.
- [ ] Preserve an explicit escape hatch for narrowly scoped target-specific
  instructions and ABI boundaries; do not promise that every CPU operation
  is portable.
- [ ] Add a second-target feasibility spike before claiming that the operation
  model is architecture-independent in practice.

#### V3.5.3 Finnish surface vocabulary and source format

- [ ] Evaluate Finnish command names as the human-facing syntax for the
  low-level operation set (for example: *sano*, *ota*, *pane*, *lisää*,
  *koettele*, *käy*, *palaa*, *seis*). Names are provisional; semantics
  and tests take precedence over metaphor or historical style.
- [ ] Evaluate `.dio` as a Väinölang source-file extension. Treat it as a
  naming proposal until compiler, tooling, formatting, and build integration
  support it.
- [ ] Document the vocabulary and syntax in the language reference. Do not
  make biblical or literary phrasing part of the language's semantics.
- [ ] Keep generated machine code and disassembly available for debugging and
  review, even when source programs no longer contain assembly.

#### V3.5.4 Verification and migration gates

- [ ] Build a conformance suite for every defined operation, including boundary
  values, overflow, alignment, branch behavior, and memory semantics.
- [ ] Compare execution against a reference interpreter or other trusted
  semantic oracle where practical.
- [ ] Test generated code in host tests and QEMU; inspect disassembly and ABI
  behavior for low-level paths.
- [ ] Keep existing assembly implementations as fallbacks until the new path
  passes equivalent tests and review.
- [ ] Only consider using the new operation model for Zinux kernel paths after
  compiler correctness, ABI checks, boot tests, interrupt tests, syscall
  tests, and user-mode transitions have passed.
- [ ] Make any move away from the Zig-compatible language baseline a separate,
  explicit roadmap decision. Do not silently conflate the native operation
  model with the existing Zig fork or its opt-in extensions.

---

## V4 — Maintenance

- Stay on 0.16 base + cherry-pick ledger; full 0.17 rebase only when the
  Zinux `exp/vainolang` branch is green (host tests + smoke + full boot).
- First consumer: Zinux `exp/vainolang` branch; main stays on Zig 0.16
  until the exit gate passes (see Zinux `docs/ROADMAP.md`, Phase 0).
  Status 2026-10-11: branch carries `vaino` v1, copy-fix, `@bitCast`
  audit, dual-config CI and `-Dqemu-args`; QEMU/host exit-gate evidence GREEN
  2026-10-13 (host 321/321 + smoke + full boot on both toolchains x both
  configs, pinned prefix `~/deps/vainolang-pinned/`, see Zinux
  `docs/PHASE0_EVIDENCE.md`); `.zigversion` flip deferred until the prefix
  is CI-published and hardware smoke is re-run.

---

## V5 — Memory safety: ownership, borrowing, scoped unsafe

> Decided 2026-10-13 (design only — not implemented). Fills `LANGUAGE.md`
> §4.2 (*Memory model*), which now specifies the decided model (M0 spec, 2026-10-13).

### V5.0 Rationale and evidence

Zinux survey 2026-10-13 (consumer tree, `**/*.zig`):

- ~115 `@ptrFromInt`, ~75 `@ptrCast`, ~300 unchecked slices/indexings,
  ~258 `volatile` uses, ~176 memory-touching `asm volatile` sites.
- Ownership is by convention only: PMM owns frames, VMM owns mappings,
  virtio-blk owns DMA rings, snapshot owns copies, heap owns regions —
  but nothing prevents two owners of one frame.
- The only machine-checked boundary is capabilities (`Rights`, grant
  gates). Memory needs the same treatment: the kernel decides, and the
  language makes the decision visible.

Goals (from `LANGUAGE.md` §4.2): explicit allocation and ownership for
kernel memory management, physically contiguous and DMA-safe memory,
page-granular control, no hidden runtime, no implicit allocation.

### V5.1 Decided design

**Keywords are Finnish** (decided 2026-10-13, cf. V3.5.3): the dangerous
block is `vaara`, borrowing is `lainaa` / `lainaa mut`. Finnish first;
no English alias in v1 (aliases multiply the grammar for no safety gain).

**Ownership.** Every memory region (frame, DMA buffer, heap block, page
table) has exactly one owner. Ownership transfers only by an explicit
move (the PMM→VMM→driver chain becomes recorded transfers, not aliases).
Double ownership is a compile error (M2) / lint error (M1).

**Borrowing — pragmatic subset, no lifetime inference in v1** (decided
2026-10-13). `lainaa` borrows read-only (shareable); `lainaa mut`
borrows mutably (exclusive). A borrow must not outlive the owner's
lexical scope; checking is scope-based inside a function, not
Rust-style lifetime inference. Lifetimes spanning functions need an
explicit transfer instead of a borrow.

**Scoped dangerous block.** Raw pointers, direct physical memory,
`volatile`, `asm`, and check bypasses are allowed ONLY inside an
explicit block:

```zig
vaara "syy: HHDM-ikkuna, omistaja: vmm" {
    const tab: [*]PageTableEntry = @ptrFromInt(vmm.physToVirt(pml4));
}
```

Rules:

- Outside a `vaara` block these operations are a compile error (M2) /
  lint error (M1). Greppability is a requirement, not a style wish.
- Every block carries a reason string + owning module.
- All blocks are machine-listed into `VAARA_LEDGER.md` (`BITCAST_AUDIT`
  pattern from the Zinux side).
- The kernel needs ~10 such sites (`physToVirt`, PTE read-modify-write,
  DMA rings, `stac`/`clac` copies, supervisor-table clone). They are not
  banned — they are made visible. Visibility, not prohibition.
- `vaara` never weakens capability checks: a block explains *how* memory
  is touched, capabilities still decide *whether* it may be touched.

**Non-goals for v1:** lifetime inference, banning `unsafe` in the kernel,
per-capability runtime revoke, waiting for std ownership types (the
language carries; libraries follow).

**Capability connection (M4):** a DMA/physical region's owner is its
capability holder; granting a capability is lending (`lainaa`) it.
Revocation ends the loan. This unifies the Zinux capability model with
the language memory model instead of running two authorities.

### V5.2 Implementation phases

- **M0 — Spec.** Write `LANGUAGE.md` §4.2: owner/borrow/`vaara`
  semantics, allowed-operation list, audit rule. Decisions only, no code. DONE 2026-10-13: LANGUAGE.md 4.2 specifies owner/borrow/vaara + capability link + non-goals.
- **M1 — Lint + ledger first** (decided 2026-10-13; 0.16-compatible,
  Zinux side): `vaara` convention on the ~10 current kernel sites,
  `VAARA_LEDGER.md`, lint script listing unmarked dangerous ops → CI gate
  on `exp-vainolang`. Evidence: ledger + host test (block counter) +
  QEMU green on both configs. No compiler change.
- **M2 — Compiler enforcement** (Väinölang repo, V-1 opt-in pattern):
  `vaara {}` syntax, Sema rejects raw ops outside blocks, move +
  lexical borrow checking inside functions. Negative tests: double
  ownership, escaping/mutably-shared borrow, out-of-block raw pointer →
  all compile errors. Record as V-2 in `LANGUAGE.md` + update `AGENTS.md`.
- **M3 — Kernel migration**, one module at a time, QEMU green at every
  step: PMM → paging/VMM → heap → virtio-blk → snapshot/ELF loader.
  Assembly fallbacks stay (V3 principle).
- **M4 — DMA/physical ownership** tied to capabilities (grant = lend).

### V5.3 Acceptance evidence

- [x] `LANGUAGE.md` §4.2 specifies the model (M0, 2026-10-13).
- [ ] `AGENTS.md` updated (due at M2: no enforcement yet, agent assumptions unchanged).
- [ ] `VAARA_LEDGER.md` lists every kernel `vaara` block with reason.
- [ ] Lint gate green in CI; host tests count blocks.
- [ ] Negative compile tests for each forbidden pattern.
- [ ] QEMU full boot green (x86_64 + ARM64) after each kernel migration step.
- [ ] No `**`-style silent semantic drift: the model is 0.16-compatible
  until an explicit migration decision (V4 rule).

---

## References

- Upstream release notes: <https://ziglang.org/download/0.17.0/release-notes.html>
- Consumer roadmap: `../Zinux/docs/ROADMAP.md` (Phase 0)
- Sync ledger: `docs/VAINOLANG_SYNC.md` (done in V0)