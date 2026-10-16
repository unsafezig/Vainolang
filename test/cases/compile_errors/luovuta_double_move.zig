export fn f() void {
    var a: u32 = 1;
    const b = luovuta a;
    const c = luovuta a;
    _ = b;
    _ = c;
}

// error
//
// :4:15: error: double move of 'a'
// :3:15: note: already moved here
