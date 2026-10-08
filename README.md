# Väinölang

A Zig-based systems programming language and toolchain for building operating systems.

## Goals

Väinölang is built around one primary goal:

> **Remove unnecessary assembly and linker scripts from operating-system development.**

Operating systems need precise control over hardware. Today, that often means dropping from a systems language into architecture-specific assembly.

Väinölang explores how much of that boundary can be removed.

The long-term goal is:

```text
Less assembly
    ↓
More low-level operations expressed in Väinölang
    ↓
Better compiler and hardware abstractions
    ↓
More of the operating system written in one language
```

Assembly is not the enemy.

Unnecessary assembly is.

---

## From Zig to Väinölang

Väinölang starts from Zig 0.16.

It remains closely related to upstream Zig, but is developed independently when operating-system development requires capabilities that are missing, difficult, or unnecessarily low-level.

The project follows a simple rule:

> If the compiler can provide a safe, explicit and efficient abstraction, the operating system should not need to implement it in assembly.

Useful improvements from newer Zig releases may be incorporated selectively rather than following every upstream release wholesale.

---

## The Path

The project approaches assembly reduction step by step.

### 1. Identify the assembly

Find where Zinux currently needs architecture-specific assembly.

```text
Zinux
 │
 ├── boot
 ├── interrupts
 ├── context switching
 ├── system calls
 ├── atomics
 ├── CPU state
 └── hardware access
```

Every piece of assembly should have a reason to exist.

### 2. Ask why it is assembly

Some operations genuinely require assembly.

Others exist in assembly only because the language or compiler does not expose the required CPU functionality.

Väinölang distinguishes between the two.

```text
Assembly
   │
   ├── genuinely required
   │        ↓
   │      keep
   │
   └── compiler limitation
            ↓
       improve Väinölang
```

### 3. Add compiler support

When a low-level operation cannot be expressed properly in Väinölang, the preferred solution is to improve the toolchain.

Potential areas include:

- CPU intrinsics
- atomic operations
- memory barriers
- control registers
- interrupt primitives
- architecture-specific instructions
- CPU feature detection
- ABI operations
- linker and ELF support
- freestanding execution

The aim is not to hide the machine.

The aim is to expose the machine directly through the language.

### 4. Rewrite the operating-system code

Once the compiler can express an operation properly, Zinux can replace the corresponding assembly.

```text
Assembly
    ↓
Identify limitation
    ↓
Väinölang compiler support
    ↓
Rewrite kernel code
    ↓
Test against hardware
    ↓
Remove assembly
```

This creates a feedback loop:

```text
Zinux
  ↓
find low-level limitation
  ↓
Väinölang
  ↓
improve compiler
  ↓
Zinux
  ↓
remove assembly
```

---

## What Väinölang should become

The long-term vision is not a language that pretends hardware does not exist.

It is the opposite.

Väinölang should make low-level hardware operations first-class language and compiler capabilities.

A kernel developer should be able to write something conceptually close to the hardware without having to leave the language whenever the CPU does something unusual.

```text
Application
     ↓
Väinölang
     ↓
Compiler / intrinsics
     ↓
CPU
     ↓
Hardware
```

The machine should remain visible.

The unnecessary ceremony should disappear.

---

## Upstream Zig

Väinölang is a fork, not a rejection of Zig.

When a change is generally useful to Zig, upstreaming it should be considered.

Väinölang-specific changes are appropriate when they are:

- operating-system focused
- experimental
- architecture-specific
- not yet suitable for upstream
- or intentionally designed around Zinux

The goal is to keep the divergence understandable.

---

## Relationship with Zinux

Väinölang is developed together with Zinux, the kernel of Väinö OS.

```text
Väinölang
    │
    │ builds
    ▼
  Zinux
    │
    │ forms the kernel of
    ▼
Väinö OS
```

Zinux is the primary test environment for Väinölang.

When Zinux encounters a limitation, Väinölang can evolve.

When Väinölang evolves, Zinux should need less assembly.

---

## Current Starting Point

Väinölang currently starts from:

```text
Zig 0.16.0
```

The initial codebase is intentionally kept close to upstream Zig.

The project will selectively evaluate newer Zig improvements rather than automatically following every release.

---

## Status

Väinölang is experimental.

The compiler and language are expected to change substantially as Zinux develops.

The project is not trying to prove that an operating system can contain zero assembly.

It is trying to discover how little assembly an operating system actually needs.

---

## Philosophy

> Do not remove assembly because it is low-level.
>
> Remove it when the compiler can do the job better.

---

## License

Väinölang is based on Zig and retains the applicable licensing of the underlying project.

See [LICENSE](LICENSE) for the complete license information.
