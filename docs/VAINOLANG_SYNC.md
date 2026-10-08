# Väinölang Upstream Sync Ledger

This ledger records deliberate divergence from the `zig-upstream` remote.
It prevents a selective cherry-pick strategy from becoming an unexplained
fork. Every 0.17 change that is evaluated gets an entry before it is merged.

## Baseline

| Item | Value |
|---|---|
| Upstream remote | `https://codeberg.org/ziglang/zig.git` |
| Local baseline | upstream tag `0.16.0` |
| Väinölang baseline tag | `vainolang-0.16.0` |
| Selection policy | Take small, useful changes; defer risky or irrelevant changes |
| Consumer | Zinux `exp/vainolang` experiment branch |

## Decisions

| Upstream ref | Area | Decision | Reason / evidence |
|---|---|---|---|
| `0.17.0` release notes | Language, stdlib, build, linker | Evaluate by subsystem, not as one change | 0.17 contains useful features and breaking changes; individual commit SHAs are added before cherry-pick |
| 0.17.0 soft-float-x86 regression | Compiler / freestanding | Defer as default until fixed or worked around | Directly affects Zinux's `x86_64` soft-float kernel target; QEMU smoke boot is required |
| 0.17.0 maker/configurer split | Build system | Take with migration | Required for the Zinux build migration; ZLS impact is documented |

## Entry format

Use one row per upstream commit or inseparable dependency series:

```text
Upstream SHA: <full SHA>
Area: <language|stdlib|build|compiler|linker|toolchain>
Decision: take | defer | reject
Väinölang commit: <SHA, after merge>
Reason: <why this helps or why it is deferred>
Validation: <tests and target matrix>
```

Do not mark a change as taken because it applies cleanly. It is taken only
after Väinölang tests pass and the Zinux consumer impact is recorded.
