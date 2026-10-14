export fn f(x: usize) void {
    vaara "syy: testi, omistaja: testi" {
        const p: [*]u8 = @ptrFromInt(x);
        const back: usize = @intFromPtr(p);
        if (back != x) unreachable;
    }
}

// compile
// backend=llvm
// target=native
// vaara_strict=true
