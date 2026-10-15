# LANGUAGE.md

This document describes the Väinölang programming language: its current state, its direction, and the rules that govern divergence from Zig.

**Language source of truth order:**

1. Current Väinölang compiler implementation
2. This file (`LANGUAGE.md`)
3. Tests
4. `AGENTS.md`
5. `README.md`
6. Zig 0.16 documentation / knowledge

If this document and the implementation disagree, the implementation describes the current behavior, but it does not automatically define the intended language semantics.

If the implementation is believed to be wrong, fix the implementation and update this document rather than documenting the bug as language behavior.

---

## 1. What Väinölang Is

Väinölang is primarily a systems programming language, with Zinux and Väinö OS as its primary environments.

It is currently derived from Zig 0.16.x. It is becoming an independent language.

Väinölang is designed around the needs of low-level systems software: capabilities, isolation, precise hardware control, and as little assembly as practical.

> **Zig is the starting point. Väinölang is the destination.**

---

## 2. Current Baseline

The current implementation is based on:

```text
Zig 0.16.x
```

At this stage, most language behavior comes directly from Zig. This is temporary.

- Code written today is largely Zig 0.16-shaped.
- Differences from Zig 0.16 are not automatically bugs.
- Compatibility with Zig is useful during the transition, but it is not the goal.

### Transitional rule

Unless explicitly documented otherwise, existing Zig 0.16 behavior remains the current behavior of Väinölang.

However, new code must not assume that this behavior is permanent.

### Selective Zig 0.17+ incorporation

Newer Zig releases may contain improvements that serve Väinölang's goals. These are incorporated **selectively**, feature by feature — not by following upstream releases wholesale.

A newer Zig feature is a candidate for adoption when it:

- removes low-level ceremony
- strengthens explicitness or safety without hiding the machine
- simplifies compiler or toolchain work that Väinölang would otherwise need to recreate
- provides useful low-level capabilities

A Zig feature is not adopted merely because upstream adopted it.

Every incorporated feature is recorded in [Divergences and Adoptions](#7-divergences-and-adoptions).

---

## 3. Direction of the Language

Väinölang evolves along two axes simultaneously.

### Axis A — Independence from Zig

Gradually replace dependence on:

- Zig syntax
- Zig semantics
- Zig compiler architecture
- Zig build system
- Zig linker model
- Zig runtime
- Zig standard library
- Zig-specific terminology

When a Väinölang-native design is practical, prefer it over inherited Zig behavior.

### Axis B — Toward the machine

Väinölang aims to make low-level hardware operations **first-class language capabilities** instead of escapes into assembly.

The intended direction:

```text
Less assembly
    ↓
More low-level operations expressed in Väinölang
    ↓
Better compiler and hardware abstractions
    ↓
More of the operating system written in one language
```

The aim is not to hide the machine.

The aim is to expose the machine directly through the language.

---

## 4. Planned Language Areas

The following areas are **design targets, not current language features**.

A feature must not be treated as implemented merely because it is listed here.

Each divergence must be implemented explicitly, tested, and documented in this file.

### 4.1 Low-level hardware capabilities

First-class language and compiler support for:

- CPU intrinsics — explicit and architecture-aware
- Atomic operations — language primitives with explicit memory-order semantics
- Memory barriers — expressible directly in Väinölang
- Control registers and MSRs — exposed as language operations where appropriate
- Interrupt primitives — enabling/disabling and state save/restore
- Architecture-specific instructions — exposed through the toolchain when required
- CPU feature detection — compile-time and runtime
- ABI operations — calling conventions, frame layout, and link-time behavior
- Linker and ELF support — Väinölang-owned abstractions where practical
- Freestanding execution without unnecessary runtime assumptions

Rule of thumb:

> **If the compiler can provide a safe, explicit and efficient abstraction, the operating system should not implement it in assembly.**

### 4.2 Memory model

> **Status: decided (M0 spec, ROADMAP V5); M1 complete on the consumer
> side (2026-10-13); M2a complete in the compiler (2026-10-15, V-2).**
> M1 brought lint + ledger on the consumer side
> (0.16-compatible, no compiler change — Zinux `exp/vainolang`:
> `docs/VAARA_LEDGER.md` valid with V-01..V-10 + justified `vaara-ok`
> scopes, `tools/vaara_lint.sh` CI gate, `tests/host/vaara_ledger_test.zig`
> block counter, smoke green on both configs with zero `.bin` drift);
> M2a brings compiler errors for the `vaara`-block subset below:
> contextual `vaara "reason" {}` syntax (no new keyword), Sema rejection
> of `@ptrFromInt` / `@ptrCast` (all three Zir forms) / function-scope
> `asm` outside a block when the module opts in (`-fvaara-strict`,
> per-module, never inherited by dependencies — `std` stays non-strict).
> Move/borrow checking is M2b. Until M2b, this section is
> the normative design that M1 conventions and M2a enforcement follow.

Zig's memory model is superseded by the following rules.

#### Ownership

Every memory region (frame, DMA buffer, heap block, page table) has
exactly one owner at any time. Ownership transfers only by an explicit
move: the PMM-to-VMM-to-driver chain is a sequence of recorded transfers,
not aliases. Two owners of one region is a compile error (M2) / lint
error (M1).

#### Borrowing

A pragmatic subset, with no lifetime inference in v1:

- `lainaa` borrows read-only (shareable).
- `lainaa mut` borrows mutably (exclusive: no other borrow, read or
  mutable, of the same region is live at the same time).
- A borrow must not outlive the owner's lexical scope. Checking is
  scope-based inside a function, not Rust-style lifetime inference.
- A borrow that must span functions is not a borrow: use an explicit
  ownership transfer instead.

Keywords are Finnish, with no English alias in v1: aliases multiply the
grammar for no safety gain.

#### Scoped dangerous blocks

Raw pointers, direct physical memory access, `volatile`, `asm`, and
explicit check bypasses are allowed ONLY inside a `vaara` block:

```zig
vaara "syy: HHDM-ikkuna, omistaja: vmm" {
    const tab: [*]PageTableEntry = @ptrFromInt(vmm.physToVirt(pml4));
}
```

Rules:

- Outside a `vaara` block, these operations are a compile error (M2) /
  lint error (M1). Greppability is a requirement, not a style wish.
- Every block carries a reason string and names the owning module.
- All blocks are machine-listed into `VAARA_LEDGER.md` (one row per block:
  location, reason, owner, review date).
- The kernel needs on the order of ten such sites (`physToVirt`, PTE
  read-modify-write, DMA rings, copy with privilege bracketing,
  supervisor-table clone). They are not banned; they are made visible.
  Visibility, not prohibition.
- `vaara` never weakens capability checks: a block explains *how* memory
  is touched, capabilities still decide *whether* it may be touched.

#### Capability connection (M4 direction)

A DMA/physical region's owner is its capability holder; granting a
capability lends (`lainaa`) the region, and revocation ends the loan.
This unifies the Zinux capability model with the language memory model
instead of running two authorities. The exact grant-as-lend mechanics
are specified at M4; M0-M3 must not contradict them.

#### Non-goals for v1

Lifetime inference, banning `unsafe` in the kernel, per-capability
runtime revoke, and waiting for standard-library ownership types (the
language carries the model; libraries follow).

#### Rationale

Consumer survey 2026-10-13 (Zinux tree): ~115 `@ptrFromInt`, ~75
`@ptrCast`, ~300 unchecked slices/indexings, ~258 `volatile` uses, ~176
memory-touching `asm volatile` sites, with ownership by convention only
(PMM owns frames, VMM owns mappings, virtio-blk owns DMA rings, snapshot
owns copies, heap owns regions). The only machine-checked boundary is
capabilities; memory needs the same treatment: the kernel decides, and
the language makes the decision visible.

### 4.3 Error handling

Error handling must remain explicit and suitable for freestanding systems software.

Changes are allowed when they:

- reduce silent failure modes
- make kernel error paths clearer
- remain usable without a hidden runtime
- avoid unnecessary allocation

No final divergence from Zig's error model is defined here yet.

### 4.4 Modules and compile-time execution

Potential directions include:

- a module system designed around kernel, driver, and userland layering
- compile-time execution retained as a core strength
- compile-time semantics eventually owned by Väinölang rather than inherited accidentally from Zig

No final module or compile-time model is defined here yet.

### 4.5 Standard library

No traditional standard library is assumed.

OS-facing libraries such as:

- HAL
- capability interfaces
- driver runtime
- kernel services

are Zinux / Väinö OS components rather than automatically language components.

A minimal freestanding core may eventually be defined and owned by Väinölang.

### 4.6 Build system

The current build system is transitional Zig infrastructure.

The long-term goal is a Väinölang-owned build and link model.

This may eventually include:

- Väinölang-native build descriptions
- Väinölang-native linking
- Väinölang-owned linker abstractions
- reduced dependence on Zig's build system

---

## 5. Assembly Policy

Assembly is an implementation detail, not the desired programming model.

For every piece of assembly:

```text
Assembly
   │
   ├── genuinely required?  →  keep
   │
   └── compiler limitation?  →  improve Väinölang
```

Rules:

- Do not add assembly merely because Zig currently uses it.
- Prefer a Väinölang abstraction when it provides the required control.
- Keep assembly when the hardware or target architecture genuinely requires it.
- Do not pursue zero assembly as an ideological goal.

The project aims to discover how little assembly an operating system actually needs when the language and compiler are designed for the machine.

---

## 6. Documentation Rule for Language Changes

A language change normally requires:

```text
implementation
      ↓
tests
      ↓
LANGUAGE.md
      ↓
AGENTS.md
(if agent assumptions changed)
```

Never silently introduce new language semantics.

When a language behavior intentionally diverges from Zig:

1. implement it explicitly
2. add or update tests
3. document the behavior here
4. explain why the divergence exists
5. update `AGENTS.md` if it changes how agents should work

---

## 7. Divergences and Adoptions

This section is the registry of intentional differences from Zig 0.16 and selectively adopted features from newer Zig releases.

Every entry should explain:

- what changed
- Väinölang's behavior
- why the change exists
- which tests cover it

### Divergences from Zig 0.16

| # | Area | Status | Väinölang behavior | Reason | Tests |
|---|------|--------|--------------------|--------|-------|
| V-1 | Opt-in `vaino` module | **current** (v1) | Versioned `vaino` module (`libs/vaino.zig` in Zinux): capability `Rights` mask constants + `toMask`/`fromMask`/`narrow` helpers, MMIO `packed struct` + `volatile` read/write patterns, `vaino-version` stamp + `build -Dvaino` flag. Only active via explicit `@import("vaino")`; default build has no language change. | Centralize `@bitCast` conversions in one audited place ahead of the 0.17 `@bitCast` semantic change; reduce repetition without implicit semantics. | Zinux `tests/host/vaino_test.zig` (host) + kernel freestanding compile via `@import("vaino")` in `kernel/main.zig`; QEMU boot unchanged (default `-Dvaino=false`). |
| V-2 | Scoped `vaara` block (M2a) | **current** (`exp/vaara`) | Contextual `vaara "reason" {}` (identifier + string + block; no new reserved keyword): `vaara_block` AST node → ZIR `vaara_block` → Sema `in_vaara` scope. With `-fvaara-strict` (per-module opt-in, never inherited by dependencies), `@ptrFromInt`, `@ptrCast` (all forms incl. extended), and function-scope `asm` outside a block are compile errors. `vaara` also valid as a statement (no semicolon, like blocks); ZON rejects it; `zig fmt` renders it. | Make the ~10 kernel dangerous sites visible and machine-checked (M1 lint becomes M2 errors); `std`/deps stay non-strict so gradual module-at-a-time migration (M3) is possible. | `test/cases/vaara_block_ok.zig` + 3 `compile_errors/vaara_*_outside.zig` negative tests (all green on LLVM stage3); full `test-cases` suite green (no regressions). |

### Adopted from Zig 0.17+

| # | Feature | Source | Status | Reason | Tests |
|---|---------|--------|--------|--------|-------|
| A-1 | `@divCeil` builtin | Zig 0.17 (`f810faa828` + 3 follow-ups, adapted) | **current** (main, PR #1) | Kernel alignment/size math without hand-rolled helpers; purely additive, no migration | New stage3 on self-built LLVM 21: behavior slice/math + std math 5124/5142 pass, div compile-error cases 25/25 (native, Debug+ReleaseSafe); `@divCeil` end-to-end demo |

This registry is part of the language history.

Do not silently change a language feature without recording the intentional divergence.

---

## 8. Status

Väinölang is experimental.

The compiler and language are expected to change substantially as Zinux and Väinö OS develop.

This document describes both current behavior and future design intent.

Where this document says:

- **current** — the behavior is intended to describe the language as it exists now
- **transitional** — the behavior exists primarily because of the Zig 0.16 foundation
- **planned** — the feature is a design target, not an implemented language feature
- **candidate** — the feature is being considered but has no committed design

The current implementation remains authoritative for what the compiler actually does.

The purpose of this document is to ensure that current behavior, intended semantics, and future direction do not become confused.

---

## 9. Core Principles

Keep these principles in mind when evolving Väinölang:

> **Zig is the starting point.**
>
> **Väinölang is the destination.**
>
> Compatibility is transitional; independence is the goal.
>
> Do not hide the machine. Expose it through the language.
>
> Prefer language capabilities over unnecessary assembly.
>
> Do not introduce differences merely for the sake of being different.
>
> Every intentional divergence must be explicit, tested, and documented.
