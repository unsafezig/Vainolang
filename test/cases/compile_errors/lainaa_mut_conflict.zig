export fn f() void {
    var x: u32 = 1;
    const r = lainaa x;
    const m = lainaa mut x;
    _ = r;
    _ = m;
}

// error
//
// :4:15: error: conflicting borrow of 'x'
// :3:15: note: previous borrow here
