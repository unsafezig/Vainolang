export fn f() void {
    var x: u32 = 1;
    const a = lainaa mut x;
    const b = lainaa mut x;
    _ = a;
    _ = b;
}

// error
//
// :4:15: error: conflicting borrow of 'x'
// :3:15: note: previous borrow here
