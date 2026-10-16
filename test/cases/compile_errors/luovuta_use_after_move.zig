fn take(x: u32) u32 {
    return x;
}

export fn f() void {
    var a: u32 = 1;
    const b = take(luovuta a);
    const c = take(a);
    _ = b;
    _ = c;
}

// error
//
// :8:20: error: use after move of 'a'
// :7:20: note: moved here
