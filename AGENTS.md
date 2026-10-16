# AGENTS.md

> **READ THIS FILE BEFORE MODIFYING THE COMPILER OR LANGUAGE.**

This repo is Väinölang itself (the language + compiler fork). The consumer
(Zinux kernel) lives in the sibling repo and validates our changes.

## 1. Project identity

Väinölang is a Zig-compatible language fork becoming an independent
systems language. Base: Zig 0.16 + selective 0.17 cherry-picks (ledger in
`docs/VAINOLANG_SYNC.md`) + small opt-in Väinö extensions.

> Zig is the starting point. Väinölang is the destination.

A difference from Zig is not automatically a bug. Check `LANGUAGE.md` §7
before "fixing" one.

## 2. Source of truth order

1. Current compiler implementation
2. `LANGUAGE.md`
3. Tests (`test/cases/`)
4. This file (`AGENTS.md`)
5. `README.md`
6. Zig 0.16 documentation / knowledge

## 3. Current divergences (agent-visible behavior)

- **V-1** (`vaino` module): consumer-side only (`libs/vaino.zig` in Zinux).
  Nothing to do in this repo.
- **A-1** (`@divCeil` from 0.17): merged to `main`. Purely additive.
- **V-2** (memory model, M2 — ENFORCED, always consider it):
  - `vaara "reason" {}` — scoped dangerous block. Gated by
    `-fvaara-strict`, **per-module, never inherited by dependencies**
    (`std` must keep building under a strict root).
  - `lainaa x` / `lainaa mut x` — borrow. **Always on**, triggered by the
    syntax itself, no flag. Lowers exactly like `&x`.
  - `luovuta x` — explicit move. **Always on**, identity lowering.
  - All three are **contextual, not keywords**: `lainaa(x)` is still a
    call, `lainaa;` still a variable. Any new contextual shape needs a
    collision survey of the exact spelling in BOTH repos first
    (`mut` is a real variable name in the consumer).
  - All three are rejected in ZON and rendered by `zig fmt`.
  - Negative tests live in `test/cases/compile_errors/` with exact
    `file:line:col` expectations.

## 4. Hard constraints (learned the expensive way — do not re-learn)

- **`Zir.Inst.Tag` (`enum(u8)`) is FULL (256). No new ZIR tags, ever.**
  New syntax must lower to existing constructs. Checking lives in
  AstGen/Sema on existing nodes.
- **Rebuild economics:** any `Sema.zig`/`AstGen.zig` edit recompiles the
  world + static-LLVM relink (~15–40 min). Batch fixes per cycle; use
  `ast-check` / `build-obj` probes for fast iteration first.
- **Stage3 recipe:** `-Dstatic-llvm=true` is REQUIRED. Without it the
  prefix builds without LLVM (~58 MB vs ~225 MB) and everything silently
  falls back to the x86_64 backend (`u128`/`f128` misbehave exactly like
  a miscompile). Always sanity-check prefix size and `-fllvm`.
- **Cache hygiene:** the version string comes from `git describe`, so
  uncommitted compiler changes do NOT change cache digests. After any
  compiler-side change, nuke the test caches before trusting results.
  Never share `--global-cache-dir`/`--cache-dir` between compilers.
- **Vacuous-pass probe:** `-Dtest-filter` matching nothing exits 0
  silently. After a green filtered run, prove genuineness (wrong-column
  probe must fail, or compile each test file directly: positives must
  build, negatives must error with the expected message).
- **Test columns:** never predict error columns by reasoning — verify
  empirically. Point errors at identifier tokens for stable columns.
- **PowerShell 5.1 here:** no `&&`; use `; if ($?) { }`. No
  `Select-Object -First` on build output for verification (full output
  is captured to file). `git` is slow on this repo — prefer
  `git --no-optional-locks` and narrow queries.

## 5. Workflow rules

- Cherry-picks: every upstream 0.17 series gets a ledger row in
  `docs/VAINOLANG_SYNC.md` (take / defer / reject + reason + validation)
  BEFORE merge. Taken only after tests pass and consumer impact is
  recorded — never because it "applies cleanly".
- Language changes follow: implementation → tests → `LANGUAGE.md` →
  this file (if agent assumptions changed). Never silently introduce
  new semantics. Every intentional divergence gets a `V-N` row in
  `LANGUAGE.md` §7.
- Consumer validation: compiler takes that touch the frontend pipeline
  get a consumer smoke on Zinux `exp/vainolang` (flag off = regression
  proof) before the next compiler phase builds on top.
- Disk: one active build dir per need, disposable per-compiler caches,
  keep `vainolang-pinned/` + LLVM/zlib/zstd sources, drop ladder
  intermediates after evidence lands in the ledger.

## 6. Core principle

Compatibility is transitional; independence is the goal. Do not hide the
machine. Every divergence must be explicit, tested, and documented.
