var g: ?*const u8 = null;

export fn f() void {
    var x: u8 = 7;
    const r = lainaa x;
    g = r;
}

// error
//
// :6:5: error: borrow escapes to non-local storage
