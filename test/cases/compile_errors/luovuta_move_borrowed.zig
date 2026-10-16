export fn f() void {
    var x: u8 = 7;
    const r = lainaa x;
    const m = luovuta x;
    _ = r;
    _ = m;
}

// error
//
// :4:15: error: cannot move borrowed variable 'x'
// :3:15: note: borrow is live here
