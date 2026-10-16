fn use(p: *const u32) u32 {
    return p.*;
}

fn useMut(p: *u32) void {
    p.* += 1;
}

export fn f() void {
    var x: u32 = 10;
    {
        const r = lainaa x;
        if (use(r) != 10) unreachable;
    }
    {
        const m = lainaa mut x;
        useMut(m);
    }
    if (x != 11) unreachable;
    {
        const r2 = lainaa x;
        const r3 = lainaa x;
        if (r2.* + r3.* != 22) unreachable;
    }
}

// compile
// backend=llvm
// target=native
