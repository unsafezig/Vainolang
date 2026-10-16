export fn f() *const u8 {
    var x: u8 = 7;
    const r = lainaa x;
    return r;
}

// error
//
// :4:5: error: cannot return borrowed value
