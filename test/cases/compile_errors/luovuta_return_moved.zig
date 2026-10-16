export fn f() u32 {
    var a: u32 = 1;
    const b = luovuta a;
    _ = b;
    return a;
}

// error
//
// :5:12: error: use after move of 'a'
// :3:15: note: moved here
