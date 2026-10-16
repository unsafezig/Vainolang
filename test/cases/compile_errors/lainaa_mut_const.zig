export fn f() void {
    const x: u8 = 7;
    const m = lainaa mut x;
    _ = m;
}

// error
//
// :3:15: error: cannot mutably borrow const variable 'x'
