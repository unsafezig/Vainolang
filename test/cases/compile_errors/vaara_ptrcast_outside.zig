export fn f(p: *u8) void {
    const q: *u16 = @ptrCast(@alignCast(p));
    _ = q;
}

// error
// vaara_strict=true
//
// :2:21: error: @ptrCast outside vaara block
