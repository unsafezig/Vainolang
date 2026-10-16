export fn f() void {
    var x: u8 = 7;
    const m = luovuta x;
    const r = lainaa x;
    _ = m;
    _ = r;
}

// error
//
// :4:15: error: cannot borrow moved-from variable 'x'
// :3:15: note: moved here
