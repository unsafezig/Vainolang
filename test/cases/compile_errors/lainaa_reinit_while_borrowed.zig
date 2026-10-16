export fn f() void {
    var x: u8 = 7;
    const r = lainaa x;
    x = 8;
    _ = r;
}

// error
//
// :4:5: error: cannot assign to borrowed variable 'x'
// :3:15: note: borrow is live here
