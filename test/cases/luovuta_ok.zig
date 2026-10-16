fn take(x: u32) u32 {
    return x;
}

export fn f() void {
    var a: u32 = 1;
    var b: u32 = take(luovuta a);
    if (b != 1) unreachable;
    a = 2;
    b = take(luovuta a);
    if (b != 2) unreachable;
    const c = luovuta b;
    if (c != 2) unreachable;
}

// compile
// backend=llvm
// target=native
