var g: u8 = 7;

export fn f() void {
    const r = lainaa g;
    _ = r;
}

// error
//
// :4:22: error: cannot borrow non-local binding
